import json
import struct
from pathlib import Path

import lldb
from lldbsuite.test.decorators import swiftTest
from lldbsuite.test.gdbclientutils import MockGDBServerResponder, escape_binary
from lldbsuite.test.lldbgdbclient import GDBRemoteTestBase


class ContextTableResponder(MockGDBServerResponder):
    core_address = 0xD0000000

    def __init__(self, base=0x4000, count=2, stride=0x80, cores=None,
                 context_info=None, table_kind=2, version=5):
        super().__init__()
        self.cores = cores or {0x44: 1, 0xA9: 0}
        self.selected = next(iter(self.cores))
        self.core_reads = []
        self.memory_reads = []
        self.short_core_read = False
        self.metadata = struct.pack("<IIQQQ", 0x06000000 | version, 0, base, count, stride)
        self.kind_data = struct.pack("<I", table_kind)
        self.context_info = context_info
        self.context_queries = []

    def other(self, packet):
        if self.context_info is not None and packet.startswith("jThreadExtendedInfo:"):
            arguments = packet.partition(":")[2]
            if not arguments:
                return "OK"
            # The client appends a binary escape byte after the final JSON brace.
            tid = json.JSONDecoder().raw_decode(arguments)[0]["thread"]
            self.context_queries.append(tid)
            return escape_binary(json.dumps(self.context_info[tid]))
        return super().other(packet)

    def qfThreadInfo(self):
        return "m" + ",".join(f"{tid:x}" for tid in self.cores)

    def qC(self):
        return f"QC{next(iter(self.cores)):x}"

    def haltReason(self):
        return f"T02thread:{next(iter(self.cores)):x};"

    def cont(self):
        return self.haltReason()

    def selectThread(self, op, thread_id):
        if op == "g":
            if thread_id not in self.cores:
                return "E01"
            self.selected = thread_id
        return "OK"

    def readMemory(self, address, length):
        self.memory_reads.append((address, length))
        if address == self.core_address:
            self.core_reads.append((self.selected, length))
            value = struct.pack("<I", self.cores[self.selected])
            return value[:2 if self.short_core_read else length].hex()
        return bytes(
            self.metadata[a - 0x2000] if 0x2000 <= a < 0x2020 else
            self.kind_data[a - 0x2030] if 0x2030 <= a < 0x2034 else 0
            for a in range(address, address + length)
        ).hex()


class TestSwiftContextTable(GDBRemoteTestBase):
    def prepare(self, configured=True, hardware_address="0xd0000000", **metadata):
        self.dbg.SetAsync(False)
        self.runCmd("settings set target.experimental.swift-tasks-plugin-enabled false")
        self.runCmd("settings set target.process.disable-memory-cache true")
        address = hardware_address if configured else '""'
        self.runCmd(
            "settings set plugin.process.gdb-remote.hardware-core-id-address " + address
        )
        self.addTearDownHook(
            lambda: self.runCmd(
                "settings clear plugin.process.gdb-remote.hardware-core-id-address"
            )
        )
        metadata.setdefault("table_kind", 2 if configured else 1)
        self.server.responder = ContextTableResponder(**metadata)
        target = self.createTarget("swift-cpu-table.yaml")
        process = self.connect(target)
        return process, self.server.responder

    def query(self, process, tid):
        self.assertTrue(process.SetSelectedThreadByID(tid))
        result = lldb.SBCommandReturnObject()
        self.dbg.GetCommandInterpreter().HandleCommand("language swift task info", result)
        return (result.GetOutput() or "") + (result.GetError() or "")

    def contains_read(self, responder, address):
        return any(a <= address < a + n for a, n in responder.memory_reads)

    def assert_table_not_read(self, responder):
        for address in (0x2008, 0x2010, 0x2018, 0x4000, 0x4080):
            self.assertFalse(self.contains_read(responder, address))

    @swiftTest
    def test_software_context_rejected_by_hardware_table_before_read(self):
        process, responder = self.prepare(
            configured=False, table_kind=2,
            context_info={0x44: {"execution_context_kind": 1, "execution_context_index": 1}})
        log_path = self.getBuildArtifact("context-kind.log")
        self.runCmd(f'log enable -f "{log_path}" lldb os')
        responder.memory_reads.clear()
        self.assertIn("could not find the task address", self.query(process, 0x44))
        self.runCmd("log disable lldb os")
        self.assertIn("kind mismatch: table expects 2, selected context has 1", Path(log_path).read_text())
        self.assert_table_not_read(responder)

    @swiftTest
    def test_hardware_context_rejected_by_software_table_before_read(self):
        process, responder = self.prepare(table_kind=1)
        responder.memory_reads.clear()
        self.assertIn("could not find the task address", self.query(process, 0x44))
        self.assert_table_not_read(responder)

    @swiftTest
    def test_unknown_table_kind_is_unavailable(self):
        process, responder = self.prepare(table_kind=3)
        responder.memory_reads.clear()
        self.assertIn("could not find the task address", self.query(process, 0x44))
        self.assert_table_not_read(responder)

    @swiftTest
    def test_missing_or_unknown_remote_kind_is_unavailable(self):
        infos = {
            1: {"execution_context_index": 0},
            2: {"execution_context_index": 0, "execution_context_kind": 0},
            3: {"execution_context_index": 0, "execution_context_kind": 3},
            4: {"execution_context_index": 0, "execution_context_kind": -1},
            5: {"execution_context_index": 0, "execution_context_kind": True},
            6: {"execution_context_index": 0, "execution_context_kind": "1"},
        }
        process, responder = self.prepare(configured=False,
            cores={tid: 0 for tid in infos}, context_info=infos)
        for tid in infos:
            responder.memory_reads.clear()
            self.assertIn("could not find the task address", self.query(process, tid))
            self.assert_table_not_read(responder)

    @swiftTest
    def test_version_four_table_is_not_used(self):
        process, responder = self.prepare(version=4)
        responder.memory_reads.clear()
        self.assertIn("could not find the task address", self.query(process, 0x44))
        self.assert_table_not_read(responder)

    @swiftTest
    def test_single_hardware_context_uses_explicit_zero_index(self):
        process, responder = self.prepare(
            configured=False, table_kind=2, count=1, cores={0x44: 99},
            context_info={0x44: {"execution_context_kind": 2, "execution_context_index": 0}})
        self.assertIn("No Swift task (null task pointer).", self.query(process, 0x44))
        self.assertTrue(self.contains_read(responder, 0x4000))
        self.assertEqual(responder.core_reads, [])

    @swiftTest
    def test_distinct_thread_contexts_on_same_cpu(self):
        process, responder = self.prepare(
            configured=False, cores={0x44: 0, 0xA9: 0},
            context_info={
                0x44: {"core": 0, "execution_context_kind": 1, "execution_context_index": 1},
                0xA9: {"core": 0, "execution_context_kind": 1, "execution_context_index": 0},
            })
        for tid, slot in [(0x44, 0x4080), (0xA9, 0x4000)]:
            responder.memory_reads.clear()
            self.assertIn("No Swift task (null task pointer).", self.query(process, tid))
            self.assertTrue(self.contains_read(responder, slot))
        self.assertEqual(responder.context_queries, [0x44, 0xA9])
        self.assertEqual(responder.core_reads, [])
        # Moving both platform threads to another CPU does not change their
        # context-local storage indexes. Metadata is fetched again at the stop.
        for info in responder.context_info.values():
            info["core"] = 7
        self.assertTrue(process.Continue().Success())
        for tid, slot in [(0xA9, 0x4000), (0x44, 0x4080)]:
            responder.memory_reads.clear()
            self.assertIn("No Swift task (null task pointer).", self.query(process, tid))
            self.assertTrue(self.contains_read(responder, slot))
        self.assertEqual(responder.context_queries, [0x44, 0xA9, 0xA9, 0x44])
        self.assertEqual(responder.core_reads, [])

    @swiftTest
    def test_cpu_metadata_is_not_context_index(self):
        process, responder = self.prepare(
            configured=False, cores={1: 0, 2: 0},
            context_info={1: {"core": 0}, 2: {"core": 0}})
        self.assertIn("could not find the task address", self.query(process, 1))
        self.assertFalse(self.contains_read(responder, 0x4000))
        self.assertFalse(self.contains_read(responder, 0x4080))

    @swiftTest
    def test_context_metadata_bounds_and_types(self):
        invalid = [2, 9, 2**32 + 1, 2**64 - 1, -1, True, "1", 1.5]
        context_info = {
            tid: {"execution_context_kind": 1, "execution_context_index": index}
            for tid, index in enumerate(invalid, start=1)
        }
        process, responder = self.prepare(
            configured=False, cores={tid: 0 for tid in context_info},
            context_info=context_info)
        for tid, info in context_info.items():
            with self.subTest(index=info["execution_context_index"]):
                responder.memory_reads.clear()
                self.assertIn("could not find the task address", self.query(process, tid))
                for slot in (0x4000, 0x4080, 0x4100, 0x4480):
                    self.assertFalse(self.contains_read(responder, slot))

    @swiftTest
    def test_failed_hardware_adapter_does_not_change_namespace(self):
        process, responder = self.prepare(context_info={
            0x44: {"execution_context_kind": 1, "execution_context_index": 0},
            0xA9: {"execution_context_kind": 1, "execution_context_index": 1}})
        responder.short_core_read = True
        self.assertIn("could not find the task address", self.query(process, 0x44))
        self.assertEqual(responder.context_queries, [])
        self.assertFalse(self.contains_read(responder, 0x4000))

    @swiftTest
    def test_invalid_hardware_setting_does_not_change_namespace(self):
        process, responder = self.prepare(hardware_address="0xd0000001", context_info={
            0x44: {"execution_context_kind": 1, "execution_context_index": 0},
            0xA9: {"execution_context_kind": 1, "execution_context_index": 1}})
        self.assertIn("could not find the task address", self.query(process, 0x44))
        self.assertEqual(responder.context_queries, [])
        self.assertEqual(responder.core_reads, [])
        self.assertFalse(self.contains_read(responder, 0x4000))

    @swiftTest
    def test_cpu_identity_is_not_thread_identity(self):
        process, responder = self.prepare()
        for index, (tid, slot) in enumerate(
            [(0x44, 0x4080), (0xA9, 0x4000), (0x44, 0x4080)]
        ):
            responder.memory_reads.clear()
            result = self.query(process, tid)
            self.assertNotIn("could not find the task address", result)
            self.assertIn("No Swift task (null task pointer).", result)
            if index < 2:
                self.assertTrue(self.contains_read(responder, slot))
        # The same MMIO address must be read in each selected context, even
        # without a resume between queries. A Process memory-cache hit is wrong.
        self.assertEqual(responder.core_reads, [(0x44, 4), (0xA9, 4), (0x44, 4)])

    @swiftTest
    def test_missing_hardware_contract(self):
        # Thread 1 would be in bounds if a backend silently used the thread ID
        # as the table index. It is still not a CPU identity contract.
        process, responder = self.prepare(configured=False, cores={1: 0, 2: 1})
        self.assertIn("could not find the task address", self.query(process, 1))
        self.assertEqual(responder.core_reads, [])
        self.assertFalse(self.contains_read(responder, 0x4000))

    @swiftTest
    def test_out_of_range_core(self):
        process, responder = self.prepare(cores={0x44: 9, 0xA9: 0})
        self.assertIn("could not find the task address", self.query(process, 0x44))
        self.assertFalse(self.contains_read(responder, 0x4480))

    @swiftTest
    def test_context_index_equals_count(self):
        process, responder = self.prepare(count=2, cores={0x44: 2, 0xA9: 0})
        responder.memory_reads.clear()
        self.assertIn("could not find the task address", self.query(process, 0x44))
        for slot in (0x4000, 0x4080, 0x4100):
            self.assertFalse(self.contains_read(responder, slot))

    @swiftTest
    def test_short_core_read(self):
        process, responder = self.prepare()
        responder.short_core_read = True
        self.assertIn("could not find the task address", self.query(process, 0x44))
        self.assertFalse(self.contains_read(responder, 0x4080))

    @swiftTest
    def test_invalid_stride(self):
        process, responder = self.prepare(stride=4)
        self.assertIn("could not find the task address", self.query(process, 0x44))
        self.assertFalse(self.contains_read(responder, 0x4000))

    @swiftTest
    def test_table_address_overflow(self):
        process, responder = self.prepare(base=0xFFFFFFFFFFFFFFF8, stride=8)
        self.assertIn("could not find the task address", self.query(process, 0x44))
        self.assertFalse(self.contains_read(responder, 0xFFFFFFFFFFFFFFF8))

    @swiftTest
    def test_empty_table(self):
        process, responder = self.prepare(count=0)
        self.assertIn("could not find the task address", self.query(process, 0x44))
        self.assertFalse(self.contains_read(responder, 0x4000))

    @swiftTest
    def test_misaligned_table(self):
        process, responder = self.prepare(base=0x4001)
        self.assertIn("could not find the task address", self.query(process, 0x44))
        self.assertFalse(self.contains_read(responder, 0x4001))

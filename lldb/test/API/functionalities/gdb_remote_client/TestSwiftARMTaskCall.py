import json
import struct
from pathlib import Path

import lldb
from lldbsuite.test.decorators import skipIfXmlSupportMissing, swiftTest
from lldbsuite.test.gdbclientutils import MockGDBServerResponder, escape_binary
from lldbsuite.test.lldbgdbclient import GDBRemoteTestBase


class ARMTaskCallResponder(MockGDBServerResponder):
    def __init__(self, status_name="xpsr", status=0xA100FC00,
                 storage_kind=7, threads=(1,), context_kind=1,
                 provide_context=True, version=5, reject=False,
                 drop_context_after_call=False):
        super().__init__()
        self.status_name = status_name
        self.storage_kind = storage_kind
        self.version = version
        self.provide_context = provide_context
        self.reject = reject
        self.drop_context_after_call = drop_context_after_call
        self.context_info = {
            tid: {"execution_context_index": tid + 7,
                  "execution_context_kind": context_kind} for tid in threads}
        self.selected = threads[0]
        self.running_thread = self.selected
        self.contexts = {}
        self.slots = {}
        for index, tid in enumerate(threads):
            registers = list(range(17))
            registers[13] = 0x4000 + index * 0x1000
            registers[14] = 0x1101
            registers[15] = 0x1120
            registers[16] = status
            self.contexts[tid] = registers
            self.slots[tid] = 0x3000 + index * 0x100
        self.originals = {tid: registers.copy() for tid, registers in self.contexts.items()}
        self.original = self.registers.copy()
        self.call_registers = []
        self.called_threads = []
        self.memory_reads = []

    @property
    def registers(self):
        return self.contexts[self.selected]

    @registers.setter
    def registers(self, value):
        self.contexts[self.selected] = value

    def qXferRead(self, obj, annex, offset, length):
        if obj != "features" or annex != "target.xml":
            return None, False
        names = [f"r{i}" for i in range(13)] + ["sp", "lr", "pc", self.status_name]
        registers = "".join(f'<reg name="{name}" bitsize="32"/>' for name in names)
        return ('<target><architecture>arm</architecture><feature name="org.gnu.gdb.arm.core">'
                + registers + '</feature></target>'), False

    def qfThreadInfo(self):
        return "m" + ",".join(f"{tid:x}" for tid in self.contexts)

    def qC(self):
        return f"QC{next(iter(self.contexts)):x}"

    def haltReason(self):
        return f"T02thread:{next(iter(self.contexts)):x};"

    def selectThread(self, op, thread_id):
        if thread_id in self.contexts:
            if op == "g":
                self.selected = thread_id
            elif op == "c":
                self.running_thread = thread_id
        return "OK"

    def readRegisters(self):
        return struct.pack("<17I", *self.registers).hex()

    def readRegister(self, register):
        return struct.pack("<I", self.registers[register]).hex()

    def writeRegisters(self, data):
        self.registers = list(struct.unpack("<17I", bytes.fromhex(data)))
        return "OK"

    def writeRegister(self, register, value):
        self.registers[register] = int.from_bytes(bytes.fromhex(value), "little")
        return "OK"

    def readMemory(self, address, length):
        self.memory_reads.append((address, length))
        version = struct.pack("<I", self.storage_kind << 24 | self.version)
        return bytes(version[a - 0x2000] if 0x2000 <= a < 0x2004 else 0
                     for a in range(address, address + length)).hex()

    def setBreakpoint(self, packet):
        return "OK"

    def other(self, packet):
        if packet.startswith("z"):
            return "OK"
        if self.provide_context and packet.startswith("jThreadExtendedInfo:"):
            arguments = packet.partition(":")[2]
            if not arguments:
                return "OK"
            tid = json.JSONDecoder().raw_decode(arguments)[0]["thread"]
            return escape_binary(json.dumps(self.context_info[tid]))
        return super().other(packet)

    def cont(self):
        if self.running_thread not in self.contexts:
            self.running_thread = next(iter(self.contexts))
        self.selected = self.running_thread
        if self.registers[15] == 0x1000:
            self.call_registers.append(self.registers.copy())
            self.called_threads.append(self.selected)
            if self.reject:
                self.registers[0] = 0 if self.storage_kind == 8 else 0xFFFFFFFF
            else:
                self.registers[0] = self.slots[self.selected] if self.storage_kind == 8 else 0
            self.registers[15] = 0x1100
            if self.drop_context_after_call:
                self.provide_context = False
        threads = ",".join(f"{tid:x}" for tid in self.contexts)
        return f"T05thread:{self.selected:x};threads:{threads};"


class TestSwiftARMTaskCall(GDBRemoteTestBase):
    def prepare(self, status_name="xpsr", status=0xA100FC00, **kwargs):
        self.dbg.SetAsync(False)
        self.runCmd("settings set target.experimental.swift-tasks-plugin-enabled false")
        self.runCmd("settings set target.experimental.swift-task-allow-inferior-calls true")
        self.addTearDownHook(lambda: self.runCmd(
            "settings set target.experimental.swift-task-allow-inferior-calls false"))
        self.runCmd("settings clear plugin.process.gdb-remote.hardware-core-id-address")
        responder = ARMTaskCallResponder(status_name, status, **kwargs)
        self.server.responder = responder
        target = self.createTarget("swift-arm-task-call.yaml")
        self.connected_process = self.connect(target)
        return responder

    def query_thread(self, tid):
        self.assertTrue(self.connected_process.SetSelectedThreadByID(tid))
        self.expect("language swift task info", substrs=["No Swift task (null task pointer)."])

    @swiftTest
    @skipIfXmlSupportMissing
    def test_software_context_slot_helper_arguments_and_cache(self):
        responder = self.prepare(status_name="cpsr", status=0xA000FC10,
                                 storage_kind=8, threads=(0x44, 0xA9))
        for tid in (0x44, 0xA9, 0x44, 0xA9):
            self.query_thread(tid)
            self.assertEqual(responder.contexts, responder.originals)
        self.assertEqual(responder.called_threads, [0x44, 0xA9])
        self.assertEqual([r[:2] for r in responder.call_registers],
                         [[0x44 + 7, 1], [0xA9 + 7, 1]])
        # A new stop must reread each context's slot, without rerunning a helper.
        self.assertTrue(self.connected_process.Continue().Success())
        responder.memory_reads.clear()
        for tid in (0xA9, 0x44):
            self.query_thread(tid)
            slot = responder.slots[tid]
            self.assertTrue(any(a <= slot < a + n for a, n in responder.memory_reads))
        self.assertEqual(responder.called_threads, [0x44, 0xA9])
        self.assertEqual(responder.contexts, responder.originals)

    @swiftTest
    @skipIfXmlSupportMissing
    def test_software_context_value_helper_arguments(self):
        responder = self.prepare(status_name="cpsr", status=0xA000FC10,
                                 storage_kind=7, threads=(0x44, 0xA9))
        for tid in (0x44, 0xA9, 0x44, 0xA9):
            self.query_thread(tid)
            self.assertEqual(responder.contexts, responder.originals)
        self.assertEqual(responder.called_threads, [0x44, 0xA9, 0x44, 0xA9])
        self.assertEqual([r[:2] for r in responder.call_registers],
                         [[tid + 7, 1] for tid in responder.called_threads])

    def check_rejected_helper(self, storage_kind):
        responder = self.prepare(storage_kind=storage_kind, context_kind=2, reject=True)
        log_path = self.getBuildArtifact("rejected-helper.log")
        self.runCmd(f'log enable -f "{log_path}" lldb os')
        for _ in range(2):
            self.expect("language swift task info", error=True,
                        substrs=["could not find the task address"])
            self.assertEqual(responder.contexts, responder.originals)
        self.runCmd("log disable lldb os")
        self.assertEqual([r[:2] for r in responder.call_registers], [[8, 2], [8, 2]])
        self.assertFalse(any(a <= 0x3000 < a + n for a, n in responder.memory_reads))
        if storage_kind == 7:
            self.assertIn("rejected execution-context index 8, kind 2", Path(log_path).read_text())

    @swiftTest
    @skipIfXmlSupportMissing
    def test_value_helper_can_reject_hardware_pair(self):
        self.check_rejected_helper(7)

    @swiftTest
    @skipIfXmlSupportMissing
    def test_slot_helper_can_reject_hardware_pair_without_caching(self):
        self.check_rejected_helper(8)

    @swiftTest
    @skipIfXmlSupportMissing
    def test_value_helper_accepts_hardware_pair_with_null_task(self):
        responder = self.prepare(context_kind=2)
        self.query_thread(1)
        self.assertEqual(responder.call_registers[0][:2], [8, 2])

    @swiftTest
    @skipIfXmlSupportMissing
    def test_slot_cache_is_invalidated_when_typed_pair_changes(self):
        responder = self.prepare(storage_kind=8)
        self.query_thread(1)
        responder.context_info[1] = {"execution_context_index": 9, "execution_context_kind": 2}
        responder.slots[1] = 0x3200
        self.assertTrue(self.connected_process.Continue().Success())
        responder.memory_reads.clear()
        self.query_thread(1)
        self.assertEqual([r[:2] for r in responder.call_registers], [[8, 1], [9, 2]])
        self.assertTrue(any(a <= 0x3200 < a + n for a, n in responder.memory_reads))

    @swiftTest
    @skipIfXmlSupportMissing
    def test_slot_cache_requires_identity_after_helper_returns(self):
        responder = self.prepare(storage_kind=8, drop_context_after_call=True)
        self.query_thread(1)
        responder.memory_reads.clear()
        self.expect("language swift task info", error=True,
                    substrs=["could not find the task address"])
        self.assertEqual(responder.called_threads, [1])
        self.assertFalse(any(a <= 0x3000 < a + n for a, n in responder.memory_reads))

    @swiftTest
    @skipIfXmlSupportMissing
    def test_value_helper_missing_identity_does_not_run(self):
        responder = self.prepare(provide_context=False)
        self.expect("language swift task info", error=True,
                    substrs=["could not find the task address"])
        self.assertEqual(responder.called_threads, [])

    @swiftTest
    @skipIfXmlSupportMissing
    def test_slot_helper_missing_identity_does_not_run(self):
        responder = self.prepare(storage_kind=8, provide_context=False)
        self.expect("language swift task info", error=True,
                    substrs=["could not find the task address"])
        self.assertEqual(responder.called_threads, [])

    @swiftTest
    @skipIfXmlSupportMissing
    def test_helper_index_is_not_truncated_to_target_pointer_size(self):
        responder = self.prepare()
        responder.context_info[1]["execution_context_index"] = 2**32 + 8
        self.expect("language swift task info", error=True,
                    substrs=["could not find the task address"])
        self.assertEqual(responder.called_threads, [])

    @swiftTest
    @skipIfXmlSupportMissing
    def test_version_four_value_helper_is_not_called(self):
        responder = self.prepare(version=4)
        self.expect("language swift task info", error=True,
                    substrs=["could not find the task address"])
        self.assertEqual(responder.called_threads, [])

    @swiftTest
    @skipIfXmlSupportMissing
    def test_version_four_slot_helper_is_not_called(self):
        responder = self.prepare(storage_kind=8, version=4)
        self.expect("language swift task info", error=True,
                    substrs=["could not find the task address"])
        self.assertEqual(responder.called_threads, [])

    @swiftTest
    @skipIfXmlSupportMissing
    def test_slot_cache_does_not_follow_reused_thread_id(self):
        responder = self.prepare(status_name="cpsr", status=0xA000FC10,
                                 storage_kind=8, threads=(0x44, 0xA9))
        self.query_thread(0x44)
        old_index = self.connected_process.GetThreadByID(0x44).GetIndexID()
        self.assertTrue(self.connected_process.SetSelectedThreadByID(0xA9))
        del responder.contexts[0x44]
        self.assertTrue(self.connected_process.Continue().Success())
        self.assertEqual(self.connected_process.GetNumThreads(), 1)
        responder.contexts[0x44] = responder.originals[0x44].copy()
        responder.slots[0x44] = 0x3200
        self.assertTrue(self.connected_process.Continue().Success())
        self.assertNotEqual(self.connected_process.GetThreadByID(0x44).GetIndexID(), old_index)
        responder.memory_reads.clear()
        self.query_thread(0x44)
        self.assertEqual(responder.called_threads, [0x44, 0x44])
        self.assertTrue(any(a <= 0x3200 < a + n for a, n in responder.memory_reads))

    @swiftTest
    @skipIfXmlSupportMissing
    def test_cortex_m_call_setup_and_restore(self):
        responder = self.prepare()
        self.expect("language swift task info", substrs=["No Swift task (null task pointer)."])
        self.assertEqual(len(responder.call_registers), 1)
        called = responder.call_registers[0]
        self.assertEqual(called[15], 0x1000)
        self.assertEqual(called[14], 0x1101)
        self.assertEqual(called[16], 0xA1000000)
        self.assertEqual(responder.registers, responder.original)

    @swiftTest
    @skipIfXmlSupportMissing
    def test_cortex_m_handler_call_is_refused(self):
        responder = self.prepare(status=0x0100000B)
        self.expect("language swift task info", error=True,
                    substrs=["could not find the task address"])
        self.assertEqual(responder.call_registers, [])
        self.assertEqual(responder.registers, responder.original)

    @swiftTest
    @skipIfXmlSupportMissing
    def test_arm_cpsr_call_setup_unchanged(self):
        responder = self.prepare(status_name="cpsr", status=0xA000FC10)
        self.expect("language swift task info", substrs=["No Swift task (null task pointer)."])
        self.assertEqual(len(responder.call_registers), 1)
        self.assertEqual(responder.call_registers[0][16], 0xA0000030)
        self.assertEqual(responder.registers, responder.original)

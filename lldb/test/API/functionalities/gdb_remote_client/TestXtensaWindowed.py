"""Exercise Xtensa window unwinding through the normal remote process path."""

import lldb
from lldbsuite.test.decorators import skipIfLLVMTargetMissing, skipIfRemote, skipIfXmlSupportMissing
from lldbsuite.test.gdbclientutils import MockGDBServerResponder
from lldbsuite.test.lldbgdbclient import GDBRemoteTestBase


def word(value):
    return value.to_bytes(4, "little").hex()


class WindowResponder(MockGDBServerResponder):
    def __init__(self, callinc, num_aregs, at_entry=False, unreadable=False):
        super().__init__()
        self.unreadable = unreadable
        self.names = [f"a{i}" for i in range(16)]
        self.names += ["pc", "windowbase", "windowstart", "ps"]
        self.names += [f"ar{i}" for i in range(num_aregs)]
        self.regs = dict.fromkeys(self.names, 0)
        windows = num_aregs // 4
        caller_wb = windows - callinc
        self.regs.update(pc=0x40000004, a0=(callinc << 30) | 0x24,
                         a1=0x1000, a7=0x1000, windowbase=0,
                         windowstart=1 | (1 << caller_wb), ps=0x40000)
        saved = [0, 0x1080] + [0x100 + i for i in range(2, 12)]
        saved[7] = 0x1080
        self.memory = {}
        for start in (0x40000000, 0x40000020, 0x40000040):
            self.memory.update({start + i: byte for i, byte in
                                enumerate(bytes.fromhex("364100") + bytes(29))})
        caller = [(callinc << 30) | 0x44, 0x1040] + [0x200 + i for i in range(2, 12)]
        caller[7] = 0x1040
        for i in range(callinc * 4):
            self.regs[f"ar{(caller_wb * 4 + i) % num_aregs}"] = caller[i]
        for i in range(4):
            self.store(0x1040 - 16 + i * 4, saved[i])
        self.store(0x1080 - 12, 0x10C0)
        for i in range(4, callinc * 4):
            self.store(0x10C0 - (callinc * 4 + 4 - i) * 4, saved[i])
        if at_entry:
            self.regs.update(pc=0x40000000, windowbase=caller_wb,
                             windowstart=1 << caller_wb,
                             ps=0x40000 | (callinc << 16))
            for i in range(callinc * 4):
                self.regs[f"a{i}"] = caller[i]
            self.regs[f"a{callinc * 4}"] = (callinc << 30) | 0x24
        if unreadable:
            self.memory = {k: v for k, v in self.memory.items() if k >= 0x40000000}

    def store(self, address, value):
        self.memory.update({address + i: b for i, b in enumerate(value.to_bytes(4, "little"))})

    def qXferRead(self, obj, annex, offset, length):
        if annex != "target.xml":
            return None, False
        registers = "".join(f'<reg name="{name}" bitsize="32" regnum="{i}"/>'
                            for i, name in enumerate(self.names))
        return ('<?xml version="1.0"?><target><architecture>xtensa</architecture>'
                '<feature name="org.gnu.gdb.xtensa.core">' + registers +
                '</feature></target>'), False

    def readRegister(self, regnum):
        return word(self.regs[self.names[regnum]])

    def readRegisters(self):
        return "".join(word(self.regs[name]) for name in self.names)

    def readMemory(self, address, length):
        if self.unreadable and address < 0x40000000:
            return "E01"
        return bytes(self.memory.get(address + i, 0) for i in range(length)).hex()

    def haltReason(self):
        return "T05thread:1;"


@skipIfRemote
@skipIfXmlSupportMissing
@skipIfLLVMTargetMissing("Xtensa")
class TestXtensaWindowed(GDBRemoteTestBase):
    def check_windows(self, callinc=2, num_aregs=64, at_entry=False, unreadable=False):
        self.server.responder = WindowResponder(callinc, num_aregs, at_entry, unreadable)
        target = self.createTarget("xtensa-windowed.yaml")
        process = self.connect(target)
        thread = process.GetSelectedThread()
        self.assertEqual(thread.GetNumFrames(), 2 if unreadable else 3)
        self.assertEqual(thread.GetFrameAtIndex(1).GetPC(), 0x40000024)
        self.assertEqual(thread.GetFrameAtIndex(1).GetSP(), 0x1040)
        self.assertEqual(thread.GetFrameAtIndex(0).GetCFA(), 0x1040)
        if not unreadable:
            self.assertEqual(thread.GetFrameAtIndex(1).GetCFA(), 0x1080)
            root = thread.GetFrameAtIndex(2)
            self.assertEqual(root.GetPC(), 0x40000044)
            self.assertEqual(root.GetSP(), 0x1080)
            self.assertEqual(root.FindRegister(f"a{callinc * 4 - 1}").GetValueAsUnsigned(),
                             0x1080 if callinc == 2 else 0x100 + callinc * 4 - 1)

    def test_call4_32_registers(self):
        self.check_windows(1, 32)

    def test_call8_32_registers(self):
        self.check_windows(2, 32)

    def test_call12_64_registers(self):
        self.check_windows(3, 64)

    def test_call8_64_registers(self):
        self.check_windows()

    def test_before_entry(self):
        self.check_windows(at_entry=True)

    def test_missing_spill_memory_stops_unwind(self):
        self.check_windows(unreadable=True)

    def test_call0_is_not_interpreted_as_a_windowed_frame(self):
        self.server.responder = WindowResponder(2, 64)
        self.server.responder.regs["a0"] = 0x40000024
        self.server.responder.memory[0x40000000] = 0
        target = self.createTarget("xtensa-windowed.yaml")
        process = self.connect(target)
        self.assertEqual(process.GetSelectedThread().GetNumFrames(), 1)

    def test_invalid_windowbase_stops_unwind(self):
        self.server.responder = WindowResponder(2, 64)
        self.server.responder.regs["windowbase"] = 16
        target = self.createTarget("xtensa-windowed.yaml")
        process = self.connect(target)
        self.assertEqual(process.GetSelectedThread().GetNumFrames(), 1)

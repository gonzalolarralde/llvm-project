"""Single-step with other threads running against an OpenOCD-like server."""

import lldb
from lldbsuite.test.decorators import skipIfXmlSupportMissing
from lldbsuite.test.gdbclientutils import MockGDBServerResponder
from lldbsuite.test.lldbgdbclient import GDBRemoteTestBase


class TestMixedVCont(GDBRemoteTestBase):
    @skipIfXmlSupportMissing
    def test_step_with_other_threads_running(self):
        class Responder(MockGDBServerResponder):
            pc = 0x1000

            def qSupported(self, client_supported):
                return "PacketSize=3fff;QStartNoAckMode+;qXfer:features:read+"

            def qfThreadInfo(self):
                return "m101,102"

            def haltReason(self):
                return (
                    "T05thread:101;threads:101,102;"
                    f"thread-pcs:{self.pc:x},1000;"
                )

            def readRegisters(self):
                return self.pc.to_bytes(8, "little").hex() + "00" * 16

            def readRegister(self, regno):
                return (self.pc if regno == 0 else 0).to_bytes(8, "little").hex()

            def readMemory(self, addr, length):
                return "90" * length  # x86 nop

            def qXferRead(self, obj, annex, offset, length):
                if annex == "target.xml":
                    return (
                        """<?xml version="1.0"?>
                        <target version="1.0">
                          <architecture>i386:x86-64</architecture>
                          <feature name="org.gnu.gdb.i386.core">
                            <reg name="rip" bitsize="64" regnum="0" type="code_ptr" generic="pc"/>
                            <reg name="rsp" bitsize="64" regnum="1" type="data_ptr" generic="sp"/>
                            <reg name="rbp" bitsize="64" regnum="2" type="data_ptr" generic="fp"/>
                          </feature>
                        </target>""",
                        False,
                    )
                return None, False

            def vCont(self, packet):
                if packet == "vCont?":
                    return "vCont;c;C;s;S"
                if packet.startswith("vCont;"):
                    # OpenOCD uses the first action to choose between resume
                    # and step, even when later actions specify other threads.
                    first_action = packet.split(";")[1]
                    if first_action == "s:101":
                        self.pc += 1
                        return self.haltReason()
                    return "W00"
                return ""

            def other(self, packet):
                return self.vCont(packet)

        self.server.responder = Responder()
        self.runCmd("platform select remote-linux")
        target = self.dbg.CreateTarget("")
        process = self.connect(target)
        self.assertEqual(process.GetNumThreads(), 2)
        self.runCmd("thread step-inst --run-mode all-threads")
        self.assertEqual(process.GetState(), lldb.eStateStopped)
        thread = process.GetThreadByID(0x101)
        self.assertStopReason(thread.GetStopReason(), lldb.eStopReasonPlanComplete)
        self.assertEqual(thread.GetFrameAtIndex(0).GetPC(), 0x1001)
        self.assertPacketLogReceived(["vCont;s:101;c:102"])

"""
Test stepping out of a function when the return location is an unsuitable
stopping point.
"""


import lldb
from lldbsuite.test.decorators import *
from lldbsuite.test.lldbtest import *
from lldbsuite.test import lldbutil


class ThreadStepOutLine0TestCase(TestBase):
    SHARED_BUILD_TESTCASE = False

    def test(self):
        self.check_step_out("main.c")

    def test_return_into_inlined_line_zero(self):
        self.check_step_out("inline.c")

    def check_step_out(self, source):
        self.build(dictionary={"C_SOURCES": source,
                               "CFLAGS_EXTRAS": "-O1" if source == "inline.c" else ""})
        target, process, thread, _ = lldbutil.run_to_source_breakpoint(
            self, "// Set breakpoint here", lldb.SBFileSpec(source)
        )
        # In inline.c, the first nonzero line after returning into after_return
        # is line 1 (the statement following its #line 0 directive).
        correct_stepped_out_line = (
            1 if source == "inline.c" else line_number(source, "// Should stop here")
        )
        return_statement_line = line_number(source, "// Ran too far")
        safety_bp = target.BreakpointCreateByLocation(
            lldb.SBFileSpec(source), return_statement_line
        )
        self.assertTrue(safety_bp.IsValid())

        error = lldb.SBError()
        thread.StepOut(error)
        self.assertTrue(error.Success())

        frame = thread.GetSelectedFrame()
        if source == "inline.c":
            self.assertTrue(frame.IsInlined())
            self.assertEqual(frame.GetFunctionName(), "after_return")
        self.assertEqual(
            frame.line_entry.GetLine(),
            correct_stepped_out_line,
            "Step-out lost control of execution, ran too far",
        )

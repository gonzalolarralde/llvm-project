; RUN: llc -mtriple=xtensa-esp32s3-none-elf -verify-machineinstrs < %s | FileCheck %s
; RUN: llc -mtriple=xtensa-esp32s3-none-elf -O0 -verify-machineinstrs < %s | FileCheck %s

; Instrumented entries cannot use the ENTRY-skipping sibling sequence.
; Check assembly only: patchable-function object emission is not supported
; by this target. This verifies fallback, not instrumentation support.
define internal i32 @instrumented(i32 %x) noinline "patchable-function-entry"="2" { ret i32 %x }
define i32 @instrumented_fallback(i32 %x) {
; CHECK-LABEL: instrumented_fallback:
; CHECK: callx8
; CHECK: retw
  %r = tail call i32 @instrumented(i32 %x)
  ret i32 %r
}


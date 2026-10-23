; RUN: llc -mtriple=xtensa -O0 -verify-machineinstrs -o /dev/null < %s
; RUN: llc -mtriple=xtensa -O1 -verify-machineinstrs -o /dev/null < %s
; RUN: llc -mtriple=xtensa -O2 -verify-machineinstrs -o /dev/null < %s
; RUN: llc -mtriple=xtensa -O3 -verify-machineinstrs -o /dev/null < %s
; RUN: llc -mtriple=xtensa-esp32s3-none-elf -O0 -verify-machineinstrs -o /dev/null < %s
; RUN: llc -mtriple=xtensa-esp32s3-none-elf -O1 -verify-machineinstrs -o /dev/null < %s
; RUN: llc -mtriple=xtensa-esp32s3-none-elf -O2 -verify-machineinstrs -o /dev/null < %s
; RUN: llc -mtriple=xtensa-esp32s3-none-elf -O3 -verify-machineinstrs -o /dev/null < %s
; RUN: llc -mtriple=xtensa-esp32s3-none-elf -O2 -stop-after=finalize-isel -verify-machineinstrs < %s | FileCheck %s

; A selected call argument may be scheduled after ADJCALLSTACKDOWN.  Expanding
; SELECT_CC creates a diamond inside that outgoing call frame: both new blocks
; must inherit the active frame size, including the block with ADJCALLSTACKUP.
; The pointer and two aligned i64 arguments leave the final i32 argument on the
; stack, making the outgoing call frame nonzero.

declare i64 @callee(ptr, i64, i64, i32)

define i64 @caller(ptr %p, i32 %x, i32 %y) {
; CHECK-LABEL: name: caller
; CHECK: ADJCALLSTACKDOWN 16, 0
; CHECK: bb.{{[0-9]+}}{{.*}}call-frame-size 16):
; CHECK: bb.{{[0-9]+}}{{.*}}call-frame-size 16):
; CHECK: ADJCALLSTACKUP 16, 0
  %condition = icmp ult i32 %x, 128
  %selected = select i1 %condition, i32 %x, i32 %y
  %wide_x = zext i32 %x to i64
  %wide_selected = zext i32 %selected to i64
  %result = call i64 @callee(ptr %p, i64 %wide_x, i64 %wide_selected, i32 %y)
  ret i64 %result
}

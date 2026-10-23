; RUN: llc -mtriple=xtensa-esp32s3-none-elf -O2 -verify-machineinstrs < %s | FileCheck %s
; RUN: llc -mtriple=xtensa-esp32s3-none-elf -O0 -verify-machineinstrs < %s | FileCheck %s
; RUN: llc -mtriple=xtensa -O2 -verify-machineinstrs -filetype=obj < %s -o /dev/null
;
; LowerImmediate can leave a wide constant for ADDMI. A larger scaled-add
; pattern may instead select ADDX2/4/8 and require that constant in a register.
; Constants that survive to selection need a literal-load fallback.

define i32 @scaled_add2(i32 %x) {
; CHECK-LABEL: scaled_add2:
; CHECK: l32r [[C:a[0-9]+]],
; CHECK: addx2 {{a[0-9]+}}, {{a[0-9]+}}, [[C]]
  %s = shl i32 %x, 1
  %r = add i32 %s, 4096
  ret i32 %r
}

define i32 @scaled_add4_min(i32 %x) {
; CHECK-LABEL: scaled_add4_min:
; CHECK: l32r [[C:a[0-9]+]],
; CHECK: addx4 {{a[0-9]+}}, {{a[0-9]+}}, [[C]]
  %s = shl i32 %x, 2
  %r = add i32 %s, -32768
  ret i32 %r
}

define i32 @scaled_add8_max(i32 %x) {
; CHECK-LABEL: scaled_add8_max:
; CHECK: l32r [[C:a[0-9]+]],
; CHECK: addx8 {{a[0-9]+}}, {{a[0-9]+}}, [[C]]
  %s = shl i32 %x, 3
  %r = add i32 %s, 32512
  ret i32 %r
}

define i32 @scaled_add_movi_boundary(i32 %x) {
; CHECK-LABEL: scaled_add_movi_boundary:
; CHECK: l32r [[C:a[0-9]+]],
; CHECK: addx2 {{a[0-9]+}}, {{a[0-9]+}}, [[C]]
  %s = shl i32 %x, 1
  %r = add i32 %s, 2048
  ret i32 %r
}

define i32 @scaled_sub(i32 %x) {
; CHECK-LABEL: scaled_sub:
; CHECK: l32r [[C:a[0-9]+]],
; CHECK: addx2 {{a[0-9]+}}, {{a[0-9]+}}, [[C]]
  %s = shl i32 %x, 1
  %r = sub i32 %s, 4096
  ret i32 %r
}

define i32 @shifted_small_add(i32 %x) {
; CHECK-LABEL: shifted_small_add:
; CHECK: l32r [[C:a[0-9]+]],
; CHECK: addx4 {{a[0-9]+}}, {{a[0-9]+}}, [[C]]
  %a = add i32 %x, 1024
  %r = shl i32 %a, 2
  ret i32 %r
}

define i32 @selected_offset(i32 %x) {
; CHECK-LABEL: selected_offset:
; CHECK: l32r
; CHECK: addx8
  %s = shl i32 %x, 3
  %a = add i32 %s, -2304
  %c = icmp slt i32 %x, 0
  %r = select i1 %c, i32 %a, i32 %x
  ret i32 %r
}

define i32 @scaled_pointer(i32 %x) {
; CHECK-LABEL: scaled_pointer:
; CHECK: l32r [[C:a[0-9]+]],
; CHECK: addx4 {{a[0-9]+}}, {{a[0-9]+}}, [[C]]
  %p = getelementptr i32, ptr inttoptr (i32 4096 to ptr), i32 %x
  %r = ptrtoint ptr %p to i32
  ret i32 %r
}

define i64 @scaled_wide(i64 %x) {
; CHECK-LABEL: scaled_wide:
; CHECK: l32r
; CHECK: addx2
  %s = shl i64 %x, 1
  %r = add i64 %s, -32768
  ret i64 %r
}

; Immediate ADDMI operands still fold directly; the fallback must not emit an
; unused literal load for constants already consumed by an immediate pattern.
define i32 @plain_addmi(i32 %x) {
; CHECK-LABEL: plain_addmi:
; CHECK-NOT: l32r
; CHECK: addmi {{a[0-9]+}}, {{a[0-9]+}}, 4096
; CHECK-NOT: l32r
; CHECK: retw
  %r = add i32 %x, 4096
  ret i32 %r
}

; MOVI's complete signed 12-bit range includes -2048.
define i32 @movi_min() {
; CHECK-LABEL: movi_min:
; CHECK-NOT: l32r
; CHECK: movi {{a[0-9]+}}, -2048
; CHECK-NOT: l32r
; CHECK: retw
  ret i32 -2048
}

define i32 @movi_max() {
; CHECK-LABEL: movi_max:
; CHECK-NOT: l32r
; CHECK: movi {{a[0-9]+}}, 2047
; CHECK-NOT: l32r
; CHECK: retw
  ret i32 2047
}

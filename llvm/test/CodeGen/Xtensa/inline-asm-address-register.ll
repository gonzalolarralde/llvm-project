; RUN: llc -mtriple=xtensa -verify-machineinstrs < %s | FileCheck %s
; RUN: llc -mtriple=xtensa -mcpu=esp32s3 -verify-machineinstrs < %s | FileCheck %s

; Clang accepts GCC's "a" constraint for Xtensa address registers. These are
; the same general-purpose registers used for "r", including integer inputs.
define i32 @add_address_registers(i32 %lhs, i32 %rhs) {
; CHECK-LABEL: add_address_registers:
; CHECK: #APP
; CHECK-NEXT: add a{{[0-9]+}}, a{{[0-9]+}}, a{{[0-9]+}}
; CHECK-NEXT: #NO_APP
  %result = call i32 asm "add $0, $1, $2", "=a,a,a"(i32 %lhs, i32 %rhs)
  ret i32 %result
}

define ptr @address_operand(ptr %p) {
; CHECK-LABEL: address_operand:
; CHECK: #APP
; CHECK-NEXT: or a[[DST:[0-9]+]], a[[SRC:[0-9]+]], a[[SRC]]
; CHECK-NEXT: #NO_APP
  %result = call ptr asm "mov $0, $1", "=a,a"(ptr %p)
  ret ptr %result
}

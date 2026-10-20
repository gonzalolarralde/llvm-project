; RUN: llc -mtriple=xtensa -mcpu=esp32s3 -verify-machineinstrs < %s | FileCheck %s
; RUN: llc -mtriple=xtensa -mcpu=esp32 -filetype=obj -verify-machineinstrs < %s -o /dev/null

; SelectionDAG lowers this select to an indexed load from a two-element
; floating-point constant pool. L32R must load its address, not its first word.
; CHECK: .section .rodata
; CHECK: .p2align 2
; CHECK: [[DATA:.LCPI[0-9]+_[0-9]+]].data:
; CHECK-NEXT: .long 0x3f9df3b6
; CHECK-NEXT: .long 0x401874d1
; CHECK: .literal [[DATA]], [[DATA]].data
; CHECK-LABEL: choose:
; CHECK: l32r [[BASE:a[0-9]+]], [[DATA]]
; CHECK: add {{a[0-9]+}}, [[BASE]], {{a[0-9]+}}
; CHECK: l32i
define float @choose(i32 %index) {
  %condition = icmp eq i32 %index, 1123
  %value = select i1 %condition, float 2.382130e+00, float 1.234000e+00
  ret float %value
}

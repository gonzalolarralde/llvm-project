; RUN: llc -mtriple=xtensa-esp32s3-none-elf -filetype=obj %s -o %t.o
; RUN: llvm-objdump --mcpu=generic -d %t.o | FileCheck %s --check-prefix=UNKNOWN
; UNKNOWN: <unknown>
; RUN: llc -mtriple=xtensa-esp32s3-none-elf -verify-machineinstrs < %s | FileCheck %s
; RUN: llc -mtriple=xtensa-none-elf -mcpu=esp32s3 -verify-machineinstrs < %s | FileCheck %s
; RUN: llc -mtriple=xtensa-esp32s3-none-elf -filetype=obj < %s | llvm-readobj --file-headers - | FileCheck %s --check-prefix=ELF

; ELF: Format: elf32-xtensa
; ELF: Machine: EM_XTENSA

; CHECK-LABEL: add:
; CHECK: entry a1,
; CHECK: add
; CHECK: retw
define i32 @add(i32 %a, i32 %b) {
  %r = add i32 %a, %b
  ret i32 %r
}

; CHECK-LABEL: add_float:
; CHECK: add.s
define float @add_float(float %a, float %b) {
  %r = fadd float %a, %b
  ret float %r
}

; CHECK-LABEL: call:
; CHECK: callx8
define i32 @call(ptr %f, i32 %a) {
  %r = call i32 %f(i32 %a)
  ret i32 %r
}

; CHECK-LABEL: compare_exchange:
; CHECK: memw
; CHECK: s32c1i
; CHECK: retw
 define i32 @compare_exchange(ptr %p, i32 %expected, i32 %value) {
  %pair = cmpxchg ptr %p, i32 %expected, i32 %value seq_cst seq_cst
  %old = extractvalue {i32, i1} %pair, 0
  ret i32 %old
}

; CHECK-LABEL: fatal:
; CHECK: ill
 define void @fatal() {
  call void @llvm.trap()
  unreachable
}
declare void @llvm.trap()

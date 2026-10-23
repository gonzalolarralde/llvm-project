; RUN: llc -mtriple=xtensa-esp32s3-none-elf -verify-machineinstrs < %s | FileCheck %s --implicit-check-not=memcpy
; RUN: llc -mtriple=xtensa-esp32s3-none-elf -O0 -verify-machineinstrs < %s | FileCheck %s --implicit-check-not=memcpy

; Byval copies happen after CALLSEQ_START. They must remain inline, even above
; the normal memcpy expansion threshold, so another call sequence is not
; nested inside the outgoing frame's adjustment.
define void @byval64(ptr %value) {
; CHECK-LABEL: byval64:
; CHECK: entry a1,
; CHECK: movsp
; CHECK: l32i
; CHECK: s32i
; CHECK: callx8
; CHECK-NOT: callx8
; CHECK: retw
  call void @consume64(ptr byval([64 x i8]) align 64 %value)
  ret void
}

; Use an explicit frame pointer for the larger dynamic call-frame adjustment.
define void @byval1200(ptr %value) "frame-pointer"="all" {
; CHECK-LABEL: byval1200:
; CHECK: entry a1,
; CHECK: or a7, a1, a1
; CHECK: movsp
; CHECK: l32i
; CHECK: s32i
; CHECK: callx8
; CHECK-NOT: callx8
; CHECK: retw
  call void @consume1200(ptr byval([1200 x i8]) align 4 %value)
  ret void
}

declare void @consume64(ptr byval([64 x i8]) align 64)
declare void @consume1200(ptr byval([1200 x i8]) align 4)

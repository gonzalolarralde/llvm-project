; RUN: llc -mtriple=xtensa-esp32s3-none-elf -verify-machineinstrs < %s | FileCheck %s

; Preserve the sixth argument register before assigning the frame pointer.
; The register-save pointer must include space for the named argument so the
; initial va_ndx of four does not skip the first unnamed argument twice.
; CHECK-LABEL: one_named:
; CHECK: entry a1,
; CHECK: or a8, a7, a7
; CHECK: or a7, a1, a1
; CHECK: s32i a8, a7,
; CHECK: addi {{a[0-9]+}}, {{a[0-9]+}}, -4
; CHECK: retw
 define void @one_named(i32 %tag, ...) "frame-pointer"="all" {
  %list = alloca {ptr, ptr, i32}, align 4
  call void @llvm.va_start(ptr %list)
  call void @consume(ptr %list)
  call void @llvm.va_end(ptr %list)
  ret void
}

; When the named arguments already occupy the stack, keep va_stk aligned and
; put the named stack-word displacement in va_ndx instead.
; CHECK-LABEL: seven_named:
; CHECK: entry a1,
; CHECK: and
; CHECK: movi [[BASE:a[0-9]+]], 32
; CHECK: or {{a[0-9]+}}, {{a[0-9]+}}, [[BASE]]
; CHECK: retw
 define void @seven_named(i32 %a, i32 %b, i32 %c, i32 %d,
                         i32 %e, i32 %f, i32 %g, ...) "frame-pointer"="all" {
  %list = alloca {ptr, ptr, i32}, align 4
  call void @llvm.va_start(ptr %list)
  call void @consume(ptr %list)
  call void @llvm.va_end(ptr %list)
  ret void
}
declare void @llvm.va_start(ptr)
declare void @llvm.va_end(ptr)
declare void @consume(ptr)

; RUN: llc -mtriple=xtensa-esp32s3-none-elf -verify-machineinstrs < %s | FileCheck %s
; RUN: llc -mtriple=xtensa-esp32s3-none-elf -O0 -verify-machineinstrs < %s -o /dev/null

; The windowed ABI promises 16-byte alignment even when only one stack argument
; is needed. Both halves of a dynamic call-frame adjustment must round up.
define i32 @dynamic_call_frame(i32 %size) {
; CHECK-LABEL: dynamic_call_frame:
; CHECK: entry a1,
; CHECK: or a7, a1, a1
; CHECK: addi [[DOWN:a[0-9]+]], a1, -16
; CHECK-NEXT: movsp a1, [[DOWN]]
; CHECK: callx8
; CHECK: addi [[UP:a[0-9]+]], a1, 16
; CHECK-NEXT: movsp a1, [[UP]]
; CHECK: retw
  %buf = alloca i8, i32 %size, align 16
  call void @consume(ptr %buf)
  %result = call i32 @seven(i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7)
  ret i32 %result
}

; Keep the pre-realignment stack base in a7. Stack arguments must not use the
; aligned SP, whose distance from the caller's frame is not a constant.
define i32 @aligned32_stack_argument(i32 %a, i32 %b, i32 %c, i32 %d,
                                     i32 %e, i32 %f, i32 %g) {
; CHECK-LABEL: aligned32_stack_argument:
; CHECK: entry a1, [[SIZE:[0-9]+]]
; CHECK: or a8, a7, a7
; CHECK: or a9, a6, a6
; CHECK: or a7, a1, a1
; CHECK: .cfi_def_cfa a7, [[SIZE]]
; CHECK: movi [[MASK:a[0-9]+]], -32
; CHECK: and [[ALIGNED:a[0-9]+]], a1, [[MASK]]
; CHECK: movsp a1, [[ALIGNED]]
; CHECK: or a6, a1, a1
; CHECK: l32i {{a[0-9]+}}, a7, [[SIZE]]
; CHECK: callx8
; CHECK: retw
  %buf = alloca [32 x i8], align 32
  call void @consume_args(ptr %buf, i32 %a, i32 %b, i32 %c, i32 %d,
                          i32 %e, i32 %f, i32 %g)
  ret i32 %f
}

; Dynamic allocation requires a stable aligned base as well as the unaligned
; frame pointer. Preserve incoming a6 and a7 before installing a6 as the base.
define i32 @aligned_dynamic_arguments(i32 %size, i32 %b, i32 %c, i32 %d,
                                       i32 %e, i32 %f, i32 %g) {
; CHECK-LABEL: aligned_dynamic_arguments:
; CHECK: entry a1,
; CHECK: or a8, a7, a7
; CHECK: or a9, a6, a6
; CHECK: or a7, a1, a1
; CHECK: .cfi_def_cfa a7,
; CHECK: movi [[MASK:a[0-9]+]], -128
; CHECK: and [[ALIGNED:a[0-9]+]], a1, [[MASK]]
; CHECK: movsp a1, [[ALIGNED]]
; CHECK: or a6, a1, a1
; CHECK: and
; CHECK: movsp
; CHECK: callx8
; CHECK: movsp
; CHECK: callx8
; CHECK: retw
  %fixed = alloca [64 x i8], align 64
  %saved = call ptr @llvm.stacksave.p0()
  %dynamic = alloca i8, i32 %size, align 128
  call void @consume_args(ptr %dynamic, i32 %size, i32 %b, i32 %c, i32 %d,
                          i32 %e, i32 %f, i32 %g)
  call void @llvm.stackrestore.p0(ptr %saved)
  call void @consume(ptr %fixed)
  %result = add i32 %e, %f
  ret i32 %result
}

; a6/a7 may also hold unnamed arguments when a base/frame pointer is needed.
define void @aligned_dynamic_varargs(i32 %size, ...) {
; CHECK-LABEL: aligned_dynamic_varargs:
; CHECK: entry a1,
; CHECK: or a8, a7, a7
; CHECK: or a9, a6, a6
; CHECK: or a7, a1, a1
; CHECK: movsp
; CHECK: or a6, a1, a1
; CHECK-DAG: s32i a9, a7,
; CHECK-DAG: s32i a8, a7,
; CHECK: retw
  %args = alloca {ptr, ptr, i32}, align 4
  %dynamic = alloca i8, i32 %size, align 64
  call void @llvm.va_start(ptr %args)
  call void @consume(ptr %dynamic)
  call void @consume(ptr %args)
  call void @llvm.va_end(ptr %args)
  ret void
}

; Large windowed frames use ENTRY plus MOVSP, retaining the same pre-alignment
; base for CFA/incoming arguments and a separate aligned base for locals.
define void @aligned_large_frame(i32 %a, i32 %b, i32 %c, i32 %d,
                                 i32 %e, i32 %f, i32 %g) {
; CHECK-LABEL: aligned_large_frame:
; CHECK: entry a1, 32
; CHECK: l32r
; CHECK: sub
; CHECK: movsp
; CHECK: or a8, a7, a7
; CHECK: or a7, a1, a1
; CHECK: .cfi_def_cfa a7,
; CHECK: movi [[MASK:a[0-9]+]], -64
; CHECK: and
; CHECK: movsp
; CHECK: callx8
; CHECK: retw
  %buf = alloca [40000 x i8], align 64
  call void @consume_args(ptr %buf, i32 %a, i32 %b, i32 %c, i32 %d,
                          i32 %e, i32 %f, i32 %g)
  ret void
}

; Outgoing byval alignment must be known before formals assign a6/a7. Neither
; of these functions has an over-aligned local from which to infer it.
define i32 @late_byval_static(i32 %a, i32 %b, i32 %c, i32 %d, i32 %e,
                             i32 %f, ptr %arg) {
; CHECK-LABEL: late_byval_static:
; CHECK: or a8, a7, a7
; CHECK: or a9, a6, a6
; CHECK: or a7, a1, a1
; CHECK: movi {{a[0-9]+}}, -64
; CHECK: movsp
; CHECK: or a6, a1, a1
; CHECK: addi [[DOWN:a[0-9]+]], a1, -64
; CHECK: movsp a1, [[DOWN]]
; CHECK: callx8
; CHECK: addi [[UP:a[0-9]+]], a1, 64
; CHECK: movsp a1, [[UP]]
; CHECK: retw
  call void @consume_byval64(ptr byval([32 x i8]) align 64 %arg)
  %result = add i32 %e, %f
  ret i32 %result
}

define i32 @late_byval_dynamic(i32 %size, ptr %arg, i32 %c, i32 %d,
                              i32 %e, i32 %f) {
; CHECK-LABEL: late_byval_dynamic:
; CHECK: or a8, a7, a7
; CHECK: or a9, a6, a6
; CHECK: or a7, a1, a1
; CHECK: movi {{a[0-9]+}}, -64
; CHECK: movsp
; CHECK: or a6, a1, a1
; CHECK: sub [[NEWSP:a[0-9]+]], a1,
; CHECK: movi [[MASK:a[0-9]+]], -64
; CHECK: and [[ALIGNED:a[0-9]+]], [[NEWSP]], [[MASK]]
; CHECK: movsp a1, [[ALIGNED]]
; CHECK: callx8
; CHECK: addi [[DOWN:a[0-9]+]], a1, -64
; CHECK: movsp a1, [[DOWN]]
; CHECK: callx8
; CHECK: addi [[UP:a[0-9]+]], a1, 64
; CHECK: movsp a1, [[UP]]
; CHECK: retw
  %buf = alloca i8, i32 %size, align 16
  call void @consume(ptr %buf)
  call void @consume_byval64(ptr byval([32 x i8]) align 64 %arg)
  %result = add i32 %e, %f
  ret i32 %result
}

declare void @consume_byval64(ptr byval([32 x i8]) align 64)

declare void @consume(ptr)
declare void @consume_args(ptr, i32, i32, i32, i32, i32, i32, i32)
declare i32 @seven(i32, i32, i32, i32, i32, i32, i32)
declare ptr @llvm.stacksave.p0()
declare void @llvm.stackrestore.p0(ptr)
declare void @llvm.va_start(ptr)
declare void @llvm.va_end(ptr)

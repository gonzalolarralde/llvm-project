; RUN: llc -mtriple=xtensa-esp32s3-none-elf -verify-machineinstrs < %s | FileCheck %s
; RUN: llc -mtriple=xtensa-esp32s3-none-elf -O0 -verify-machineinstrs < %s | FileCheck %s
; RUN: llc -mtriple=xtensa-esp32s3-none-elf -stop-after=finalize-isel -verify-machineinstrs < %s | FileCheck %s --check-prefix=ISEL

; The early FP decision must use the same register/stack assignment as actual
; call lowering. 1008 outgoing bytes keep the emergency slot directly
; addressable. 1024 bytes need a stable FP, selected before incoming a7 is read.
; Both sides test actual stack boundaries, including alignment holes, split
; promoted values, hidden/explicit sret, variadic and indirect calls.

define i32 @byval_prefix6_1007(ptr %p, i32 %b, i32 %c, i32 %d, i32 %e, i32 %f) "frame-pointer"="none" {
; CHECK-LABEL: byval_prefix6_1007:
; CHECK: entry a1,
; CHECK-NOT: or a7, a1, a1
; CHECK-NOT: movsp
; CHECK: callx8
; CHECK-NOT: movsp
; CHECK: retw
; ISEL-LABEL: name: byval_prefix6_1007
; ISEL: ADJCALLSTACKDOWN 1008, 0
; ISEL: ADJCALLSTACKUP 1008, 0
  call void @sink_byval_prefix6_1007(i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, ptr byval([1007 x i8]) align 4 %p)
  ret i32 %f
}

define i32 @byval_prefix6_1008(ptr %p, i32 %b, i32 %c, i32 %d, i32 %e, i32 %f) "frame-pointer"="none" {
; CHECK-LABEL: byval_prefix6_1008:
; CHECK: entry a1,
; CHECK-NOT: or a7, a1, a1
; CHECK-NOT: movsp
; CHECK: callx8
; CHECK-NOT: movsp
; CHECK: retw
; ISEL-LABEL: name: byval_prefix6_1008
; ISEL: ADJCALLSTACKDOWN 1008, 0
; ISEL: ADJCALLSTACKUP 1008, 0
  call void @sink_byval_prefix6_1008(i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, ptr byval([1008 x i8]) align 4 %p)
  ret i32 %f
}

define i32 @byval_prefix6_1009(ptr %p, i32 %b, i32 %c, i32 %d, i32 %e, i32 %f) "frame-pointer"="none" {
; CHECK-LABEL: byval_prefix6_1009:
; CHECK: entry a1,
; CHECK: or a8, a7, a7
; CHECK-NEXT: or a7, a1, a1
; CHECK: movsp
; CHECK: callx8
; CHECK: retw
; ISEL-LABEL: name: byval_prefix6_1009
; ISEL: ADJCALLSTACKDOWN 1024, 0
; ISEL: ADJCALLSTACKUP 1024, 0
  call void @sink_byval_prefix6_1009(i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, ptr byval([1009 x i8]) align 4 %p)
  ret i32 %f
}

define i32 @byval_prefix6_1020(ptr %p, i32 %b, i32 %c, i32 %d, i32 %e, i32 %f) "frame-pointer"="none" {
; CHECK-LABEL: byval_prefix6_1020:
; CHECK: entry a1,
; CHECK: or a8, a7, a7
; CHECK-NEXT: or a7, a1, a1
; CHECK: movsp
; CHECK: callx8
; CHECK: retw
; ISEL-LABEL: name: byval_prefix6_1020
; ISEL: ADJCALLSTACKDOWN 1024, 0
; ISEL: ADJCALLSTACKUP 1024, 0
  call void @sink_byval_prefix6_1020(i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, ptr byval([1020 x i8]) align 4 %p)
  ret i32 %f
}

define i32 @byval_prefix6_1024(ptr %p, i32 %b, i32 %c, i32 %d, i32 %e, i32 %f) "frame-pointer"="none" {
; CHECK-LABEL: byval_prefix6_1024:
; CHECK: entry a1,
; CHECK: or a8, a7, a7
; CHECK-NEXT: or a7, a1, a1
; CHECK: movsp
; CHECK: callx8
; CHECK: retw
; ISEL-LABEL: name: byval_prefix6_1024
; ISEL: ADJCALLSTACKDOWN 1024, 0
; ISEL: ADJCALLSTACKUP 1024, 0
  call void @sink_byval_prefix6_1024(i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, ptr byval([1024 x i8]) align 4 %p)
  ret i32 %f
}

define i32 @odd_byval_then_scalar(ptr %p, i32 %b, i32 %c, i32 %d, i32 %e, i32 %f) "frame-pointer"="none" {
; CHECK-LABEL: odd_byval_then_scalar:
; CHECK: entry a1,
; CHECK: or a8, a7, a7
; CHECK-NEXT: or a7, a1, a1
; CHECK: movsp
; CHECK: callx8
; CHECK: retw
; ISEL-LABEL: name: odd_byval_then_scalar
; ISEL: ADJCALLSTACKDOWN 1024, 0
; ISEL: ADJCALLSTACKUP 1024, 0
  call void @sink_odd_byval_then_scalar(ptr byval([1007 x i8]) align 4 %p, i32 1)
  ret i32 %f
}

define i32 @two_odd_byvals(ptr %p, i32 %b, i32 %c, i32 %d, i32 %e, i32 %f) "frame-pointer"="none" {
; CHECK-LABEL: two_odd_byvals:
; CHECK: entry a1,
; CHECK-NOT: or a7, a1, a1
; CHECK-NOT: movsp
; CHECK: callx8
; CHECK-NOT: movsp
; CHECK: retw
; ISEL-LABEL: name: two_odd_byvals
; ISEL: ADJCALLSTACKDOWN 1008, 0
; ISEL: ADJCALLSTACKUP 1008, 0
  call void @sink_two_odd_byvals(i32 1, i32 2, i32 3, ptr byval([499 x i8]) align 4 %p, ptr byval([499 x i8]) align 4 %p)
  ret i32 %f
}

define i32 @aligned_byval_at_limit(ptr %p, i32 %b, i32 %c, i32 %d, i32 %e, i32 %f) "frame-pointer"="none" {
; CHECK-LABEL: aligned_byval_at_limit:
; CHECK: entry a1,
; CHECK-NOT: or a7, a1, a1
; CHECK-NOT: movsp
; CHECK: callx8
; CHECK-NOT: movsp
; CHECK: retw
; ISEL-LABEL: name: aligned_byval_at_limit
; ISEL: ADJCALLSTACKDOWN 1008, 0
; ISEL: ADJCALLSTACKUP 1008, 0
  call void @sink_aligned_byval_at_limit(i32 1, i32 2, i32 3, ptr byval([503 x i8]) align 4 %p, ptr byval([504 x i8]) align 8 %p)
  ret i32 %f
}

define i32 @aligned_byval_over_limit(ptr %p, i32 %b, i32 %c, i32 %d, i32 %e, i32 %f) "frame-pointer"="none" {
; CHECK-LABEL: aligned_byval_over_limit:
; CHECK: entry a1,
; CHECK: or a8, a7, a7
; CHECK-NEXT: or a7, a1, a1
; CHECK: movsp
; CHECK: callx8
; CHECK: retw
; ISEL-LABEL: name: aligned_byval_over_limit
; ISEL: ADJCALLSTACKDOWN 1024, 0
; ISEL: ADJCALLSTACKUP 1024, 0
  call void @sink_aligned_byval_over_limit(i32 1, i32 2, i32 3, ptr byval([505 x i8]) align 4 %p, ptr byval([504 x i8]) align 8 %p)
  ret i32 %f
}

define i32 @promoted_vector_258(ptr %p, i32 %b, i32 %c, i32 %d, i32 %e, i32 %f) "frame-pointer"="none" {
; CHECK-LABEL: promoted_vector_258:
; CHECK: entry a1,
; CHECK-NOT: or a7, a1, a1
; CHECK-NOT: movsp
; CHECK: callx8
; CHECK-NOT: movsp
; CHECK: retw
; ISEL-LABEL: name: promoted_vector_258
; ISEL: ADJCALLSTACKDOWN 1008, 0
; ISEL: ADJCALLSTACKUP 1008, 0
  call void @sink_promoted_vector_258(<258 x i8> zeroinitializer)
  ret i32 %f
}

define i32 @aggregate_258(ptr %p, i32 %b, i32 %c, i32 %d, i32 %e, i32 %f) "frame-pointer"="none" {
; CHECK-LABEL: aggregate_258:
; CHECK: entry a1,
; CHECK-NOT: or a7, a1, a1
; CHECK-NOT: movsp
; CHECK: callx8
; CHECK-NOT: movsp
; CHECK: retw
; ISEL-LABEL: name: aggregate_258
; ISEL: ADJCALLSTACKDOWN 1008, 0
; ISEL: ADJCALLSTACKUP 1008, 0
  call void @sink_aggregate_258([258 x i32] zeroinitializer)
  ret i32 %f
}

define i32 @promoted_vector_259(ptr %p, i32 %b, i32 %c, i32 %d, i32 %e, i32 %f) "frame-pointer"="none" {
; CHECK-LABEL: promoted_vector_259:
; CHECK: entry a1,
; CHECK: or a8, a7, a7
; CHECK-NEXT: or a7, a1, a1
; CHECK: movsp
; CHECK: callx8
; CHECK: retw
; ISEL-LABEL: name: promoted_vector_259
; ISEL: ADJCALLSTACKDOWN 1024, 0
; ISEL: ADJCALLSTACKUP 1024, 0
  call void @sink_promoted_vector_259(<259 x i8> zeroinitializer)
  ret i32 %f
}

define i32 @aggregate_259(ptr %p, i32 %b, i32 %c, i32 %d, i32 %e, i32 %f) "frame-pointer"="none" {
; CHECK-LABEL: aggregate_259:
; CHECK: entry a1,
; CHECK: or a8, a7, a7
; CHECK-NEXT: or a7, a1, a1
; CHECK: movsp
; CHECK: callx8
; CHECK: retw
; ISEL-LABEL: name: aggregate_259
; ISEL: ADJCALLSTACKDOWN 1024, 0
; ISEL: ADJCALLSTACKUP 1024, 0
  call void @sink_aggregate_259([259 x i32] zeroinitializer)
  ret i32 %f
}

define i32 @i64_register_hole_at_limit(ptr %p, i32 %b, i32 %c, i32 %d, i32 %e, i32 %f) "frame-pointer"="none" {
; CHECK-LABEL: i64_register_hole_at_limit:
; CHECK: entry a1,
; CHECK-NOT: or a7, a1, a1
; CHECK-NOT: movsp
; CHECK: callx8
; CHECK-NOT: movsp
; CHECK: retw
; ISEL-LABEL: name: i64_register_hole_at_limit
; ISEL: ADJCALLSTACKDOWN 1008, 0
; ISEL: ADJCALLSTACKUP 1008, 0
  call void @sink_i64_register_hole_at_limit(i32 1, i32 2, i32 3, i32 4, i32 5, i64 7, [250 x i32] zeroinitializer)
  ret i32 %f
}

define i32 @i64_register_hole_over_limit(ptr %p, i32 %b, i32 %c, i32 %d, i32 %e, i32 %f) "frame-pointer"="none" {
; CHECK-LABEL: i64_register_hole_over_limit:
; CHECK: entry a1,
; CHECK: or a8, a7, a7
; CHECK-NEXT: or a7, a1, a1
; CHECK: movsp
; CHECK: callx8
; CHECK: retw
; ISEL-LABEL: name: i64_register_hole_over_limit
; ISEL: ADJCALLSTACKDOWN 1024, 0
; ISEL: ADJCALLSTACKUP 1024, 0
  call void @sink_i64_register_hole_over_limit(i32 1, i32 2, i32 3, i32 4, i32 5, i64 7, [251 x i32] zeroinitializer)
  ret i32 %f
}

define i32 @hidden_sret_257(ptr %p, i32 %b, i32 %c, i32 %d, i32 %e, i32 %f) "frame-pointer"="none" {
; CHECK-LABEL: hidden_sret_257:
; CHECK: entry a1,
; CHECK-NOT: or a7, a1, a1
; CHECK-NOT: movsp
; CHECK: callx8
; CHECK-NOT: movsp
; CHECK: retw
; ISEL-LABEL: name: hidden_sret_257
; ISEL: ADJCALLSTACKDOWN 1008, 0
; ISEL: ADJCALLSTACKUP 1008, 0
  %r = call [5 x i32] @sink_hidden_sret_257([257 x i32] zeroinitializer)
  ret i32 %f
}

define i32 @explicit_sret_257(ptr %p, i32 %b, i32 %c, i32 %d, i32 %e, i32 %f) "frame-pointer"="none" {
; CHECK-LABEL: explicit_sret_257:
; CHECK: entry a1,
; CHECK-NOT: or a7, a1, a1
; CHECK-NOT: movsp
; CHECK: callx8
; CHECK-NOT: movsp
; CHECK: retw
; ISEL-LABEL: name: explicit_sret_257
; ISEL: ADJCALLSTACKDOWN 1008, 0
; ISEL: ADJCALLSTACKUP 1008, 0
  call void @sink_explicit_sret_257(ptr sret([5 x i32]) %p, [257 x i32] zeroinitializer)
  ret i32 %f
}

define i32 @varargs_257(ptr %p, i32 %b, i32 %c, i32 %d, i32 %e, i32 %f) "frame-pointer"="none" {
; CHECK-LABEL: varargs_257:
; CHECK: entry a1,
; CHECK-NOT: or a7, a1, a1
; CHECK-NOT: movsp
; CHECK: callx8
; CHECK-NOT: movsp
; CHECK: retw
; ISEL-LABEL: name: varargs_257
; ISEL: ADJCALLSTACKDOWN 1008, 0
; ISEL: ADJCALLSTACKUP 1008, 0
  call void (i32, ...) @sink_varargs_257(i32 1, [257 x i32] zeroinitializer)
  ret i32 %f
}

define i32 @hidden_sret_258(ptr %p, i32 %b, i32 %c, i32 %d, i32 %e, i32 %f) "frame-pointer"="none" {
; CHECK-LABEL: hidden_sret_258:
; CHECK: entry a1,
; CHECK: or a8, a7, a7
; CHECK-NEXT: or a7, a1, a1
; CHECK: movsp
; CHECK: callx8
; CHECK: retw
; ISEL-LABEL: name: hidden_sret_258
; ISEL: ADJCALLSTACKDOWN 1024, 0
; ISEL: ADJCALLSTACKUP 1024, 0
  %r = call [5 x i32] @sink_hidden_sret_258([258 x i32] zeroinitializer)
  ret i32 %f
}

define i32 @explicit_sret_258(ptr %p, i32 %b, i32 %c, i32 %d, i32 %e, i32 %f) "frame-pointer"="none" {
; CHECK-LABEL: explicit_sret_258:
; CHECK: entry a1,
; CHECK: or a8, a7, a7
; CHECK-NEXT: or a7, a1, a1
; CHECK: movsp
; CHECK: callx8
; CHECK: retw
; ISEL-LABEL: name: explicit_sret_258
; ISEL: ADJCALLSTACKDOWN 1024, 0
; ISEL: ADJCALLSTACKUP 1024, 0
  call void @sink_explicit_sret_258(ptr sret([5 x i32]) %p, [258 x i32] zeroinitializer)
  ret i32 %f
}

define i32 @varargs_258(ptr %p, i32 %b, i32 %c, i32 %d, i32 %e, i32 %f) "frame-pointer"="none" {
; CHECK-LABEL: varargs_258:
; CHECK: entry a1,
; CHECK: or a8, a7, a7
; CHECK-NEXT: or a7, a1, a1
; CHECK: movsp
; CHECK: callx8
; CHECK: retw
; ISEL-LABEL: name: varargs_258
; ISEL: ADJCALLSTACKDOWN 1024, 0
; ISEL: ADJCALLSTACKUP 1024, 0
  call void (i32, ...) @sink_varargs_258(i32 1, [258 x i32] zeroinitializer)
  ret i32 %f
}

define i32 @indirect_at_limit(ptr %p, i32 %b, i32 %c, i32 %d, i32 %e, i32 %f) "frame-pointer"="none" {
; CHECK-LABEL: indirect_at_limit:
; CHECK: entry a1,
; CHECK-NOT: or a7, a1, a1
; CHECK-NOT: movsp
; CHECK: callx8
; CHECK-NOT: movsp
; CHECK: retw
; ISEL-LABEL: name: indirect_at_limit
; ISEL: ADJCALLSTACKDOWN 1008, 0
; ISEL: ADJCALLSTACKUP 1008, 0
  call void %p([258 x i32] zeroinitializer)
  ret i32 %f
}

define i32 @indirect_over_limit(ptr %p, i32 %b, i32 %c, i32 %d, i32 %e, i32 %f) "frame-pointer"="none" {
; CHECK-LABEL: indirect_over_limit:
; CHECK: entry a1,
; CHECK: or a8, a7, a7
; CHECK-NEXT: or a7, a1, a1
; CHECK: movsp
; CHECK: callx8
; CHECK: retw
; ISEL-LABEL: name: indirect_over_limit
; ISEL: ADJCALLSTACKDOWN 1024, 0
; ISEL: ADJCALLSTACKUP 1024, 0
  call void %p([259 x i32] zeroinitializer)
  ret i32 %f
}

declare void @sink_byval_prefix6_1007(i32, i32, i32, i32, i32, i32, ptr byval([1007 x i8]) align 4)
declare void @sink_byval_prefix6_1008(i32, i32, i32, i32, i32, i32, ptr byval([1008 x i8]) align 4)
declare void @sink_byval_prefix6_1009(i32, i32, i32, i32, i32, i32, ptr byval([1009 x i8]) align 4)
declare void @sink_byval_prefix6_1020(i32, i32, i32, i32, i32, i32, ptr byval([1020 x i8]) align 4)
declare void @sink_byval_prefix6_1024(i32, i32, i32, i32, i32, i32, ptr byval([1024 x i8]) align 4)
declare void @sink_odd_byval_then_scalar(ptr byval([1007 x i8]) align 4, i32)
declare void @sink_two_odd_byvals(i32, i32, i32, ptr byval([499 x i8]) align 4, ptr byval([499 x i8]) align 4)
declare void @sink_aligned_byval_at_limit(i32, i32, i32, ptr byval([503 x i8]) align 4, ptr byval([504 x i8]) align 8)
declare void @sink_aligned_byval_over_limit(i32, i32, i32, ptr byval([505 x i8]) align 4, ptr byval([504 x i8]) align 8)
declare void @sink_promoted_vector_258(<258 x i8>)
declare void @sink_aggregate_258([258 x i32])
declare void @sink_promoted_vector_259(<259 x i8>)
declare void @sink_aggregate_259([259 x i32])
declare void @sink_i64_register_hole_at_limit(i32, i32, i32, i32, i32, i64, [250 x i32])
declare void @sink_i64_register_hole_over_limit(i32, i32, i32, i32, i32, i64, [251 x i32])
declare [5 x i32] @sink_hidden_sret_257([257 x i32])
declare void @sink_explicit_sret_257(ptr sret([5 x i32]), [257 x i32])
declare void @sink_varargs_257(i32, ...)
declare [5 x i32] @sink_hidden_sret_258([258 x i32])
declare void @sink_explicit_sret_258(ptr sret([5 x i32]), [258 x i32])
declare void @sink_varargs_258(i32, ...)

; RUN: llc -mtriple=xtensa-esp32s3-none-elf -verify-machineinstrs < %s | FileCheck %s
; RUN: llc -mtriple=xtensa-esp32s3-none-elf -O0 -verify-machineinstrs < %s | FileCheck %s

; 1008 is the last 16-aligned outgoing area for which an emergency spill slot
; immediately above it remains directly addressable. Rounded 1009/1020/1024-byte
; areas require a stable FP. The early decision must preserve incoming a7.

define void @byval_1008(ptr %p) "frame-pointer"="none" {
; CHECK-LABEL: byval_1008:
; CHECK: entry a1,
; CHECK-NOT: or a7, a1, a1
; CHECK-NOT: movsp
; CHECK: callx8
; CHECK: retw
  call void @sink_1008(ptr byval([1008 x i8]) align 4 %p)
  ret void
}
declare void @sink_1008(ptr byval([1008 x i8]) align 4)

define void @byval_1009(ptr %p) "frame-pointer"="none" {
; CHECK-LABEL: byval_1009:
; CHECK: entry a1,
; CHECK: or a7, a1, a1
; CHECK: movsp
; CHECK: callx8
; CHECK: retw
  call void @sink_1009(ptr byval([1009 x i8]) align 4 %p)
  ret void
}
declare void @sink_1009(ptr byval([1009 x i8]) align 4)

define void @byval_1020(ptr %p) "frame-pointer"="none" {
; CHECK-LABEL: byval_1020:
; CHECK: entry a1,
; CHECK: or a7, a1, a1
; CHECK: movsp
; CHECK: callx8
; CHECK: retw
  call void @sink_1020(ptr byval([1020 x i8]) align 4 %p)
  ret void
}
declare void @sink_1020(ptr byval([1020 x i8]) align 4)

define void @byval_1024(ptr %p) "frame-pointer"="none" {
; CHECK-LABEL: byval_1024:
; CHECK: entry a1,
; CHECK: or a7, a1, a1
; CHECK: movsp
; CHECK: callx8
; CHECK: retw
  call void @sink_1024(ptr byval([1024 x i8]) align 4 %p)
  ret void
}
declare void @sink_1024(ptr byval([1024 x i8]) align 4)

define void @byval_1200(ptr %p) "frame-pointer"="none" {
; CHECK-LABEL: byval_1200:
; CHECK: entry a1,
; CHECK: or a7, a1, a1
; CHECK: movsp
; CHECK: callx8
; CHECK: retw
  call void @sink_1200(ptr byval([1200 x i8]) align 4 %p)
  ret void
}
declare void @sink_1200(ptr byval([1200 x i8]) align 4)

define i32 @preserve_a7(ptr %p, i32 %b, i32 %c, i32 %d, i32 %e, i32 %f) "frame-pointer"="none" {
; CHECK-LABEL: preserve_a7:
; CHECK: entry a1,
; CHECK: or a8, a7, a7
; CHECK-NEXT: or a7, a1, a1
; CHECK: movsp
; CHECK: callx8
; CHECK: retw
  call void @sink_1200(ptr byval([1200 x i8]) align 4 %p)
  ret i32 %f
}

; A narrow vector occupies far more argument slots after scalar promotion than
; its IR allocation size suggests. The same applies to aggregate leaf values.
define i32 @promoted_vector_a7(ptr %p, i32 %b, i32 %c, i32 %d, i32 %e, i32 %f) "frame-pointer"="none" {
; CHECK-LABEL: promoted_vector_a7:
; CHECK: entry a1,
; CHECK: or a8, a7, a7
; CHECK-NEXT: or a7, a1, a1
; CHECK: movsp
; CHECK: callx8
; CHECK: retw
  %v = load <264 x i8>, ptr %p, align 4
  call void @sink_vector(<264 x i8> %v)
  ret i32 %f
}
declare void @sink_vector(<264 x i8>)

define i32 @promoted_aggregate_a7(ptr %p, i32 %b, i32 %c, i32 %d, i32 %e, i32 %f) "frame-pointer"="none" {
; CHECK-LABEL: promoted_aggregate_a7:
; CHECK: entry a1,
; CHECK: or a8, a7, a7
; CHECK-NEXT: or a7, a1, a1
; CHECK: movsp
; CHECK: callx8
; CHECK: retw
  %v = load [270 x i8], ptr %p, align 4
  call void @sink_aggregate([270 x i8] %v)
  ret i32 %f
}
declare void @sink_aggregate([270 x i8])

; RUN: llc -mtriple=xtensa -mcpu=esp32s3 -verify-machineinstrs < %s | FileCheck %s
; RUN: llc -mtriple=xtensa -mcpu=esp32 -O0 -verify-machineinstrs < %s -o /dev/null

; Xtensa boolean registers cannot load/store vector masks. A v1i1 value must
; scalarize even on CPUs with the boolean instruction option.
; CHECK-LABEL: load_mask:
; CHECK: l8ui
define i1 @load_mask(ptr %p) {
  %v = load <1 x i1>, ptr %p
  %b = extractelement <1 x i1> %v, i32 0
  ret i1 %b
}

; CHECK-LABEL: store_mask:
; CHECK: s8i
define void @store_mask(ptr %p, i1 %b) {
  %v = insertelement <1 x i1> poison, i1 %b, i32 0
  store <1 x i1> %v, ptr %p
  ret void
}

; CHECK-LABEL: reduce_mask:
define i1 @reduce_mask(ptr %p) {
  %v = load <4 x i1>, ptr %p
  %r = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %v)
  ret i1 %r
}
declare i1 @llvm.vector.reduce.or.v4i1(<4 x i1>)

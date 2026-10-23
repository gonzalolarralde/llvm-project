; RUN: llc -mtriple=xtensa-esp32s3-none-elf -verify-machineinstrs < %s | FileCheck %s --implicit-check-not=s32c1i
; RUN: llc -mtriple=xtensa-esp32s3-none-elf -mattr=-s32c1i -verify-machineinstrs < %s | FileCheck %s --implicit-check-not=s32c1i
;
; Insufficient IR alignment selects the generic byte-copy helpers, including
; the halfword crossing a word boundary (align 1). This is compile-only:
; it does not authorize forming or executing a misaligned typed C pointer.
; Naturally aligned runtime placements are qualified separately.

; CHECK: .literal [[LOAD16_ALIGN1:.LCPI[0-9]+_[0-9]+]], __atomic_load
; CHECK-LABEL: load16_align1:
; CHECK: l32r {{a[0-9]+}}, [[LOAD16_ALIGN1]]
; CHECK: callx8
; CHECK: retw
define i16 @load16_align1(ptr %p) {
  %v = load atomic i16, ptr %p acquire, align 1
  ret i16 %v
}

; CHECK: .literal [[STORE16_ALIGN1:.LCPI[0-9]+_[0-9]+]], __atomic_store
; CHECK-LABEL: store16_align1:
; CHECK: l32r {{a[0-9]+}}, [[STORE16_ALIGN1]]
; CHECK: callx8
; CHECK: retw
define void @store16_align1(ptr %p, i16 %v) {
  store atomic i16 %v, ptr %p release, align 1
  ret void
}

; CHECK: .literal [[CAS16_ALIGN1:.LCPI[0-9]+_[0-9]+]], __atomic_compare_exchange
; CHECK-LABEL: cas16_align1:
; CHECK: l32r {{a[0-9]+}}, [[CAS16_ALIGN1]]
; CHECK: callx8
; CHECK: retw
define {i16, i1} @cas16_align1(ptr %p, i16 %expected, i16 %new) {
  %r = cmpxchg ptr %p, i16 %expected, i16 %new acq_rel acquire, align 1
  ret {i16, i1} %r
}

; CHECK: .literal [[LOAD32_ALIGN1:.LCPI[0-9]+_[0-9]+]], __atomic_load
; CHECK-LABEL: load32_align1:
; CHECK: l32r {{a[0-9]+}}, [[LOAD32_ALIGN1]]
; CHECK: callx8
; CHECK: retw
define i32 @load32_align1(ptr %p) {
  %v = load atomic i32, ptr %p acquire, align 1
  ret i32 %v
}

; CHECK: .literal [[STORE32_ALIGN1:.LCPI[0-9]+_[0-9]+]], __atomic_store
; CHECK-LABEL: store32_align1:
; CHECK: l32r {{a[0-9]+}}, [[STORE32_ALIGN1]]
; CHECK: callx8
; CHECK: retw
define void @store32_align1(ptr %p, i32 %v) {
  store atomic i32 %v, ptr %p release, align 1
  ret void
}

; CHECK: .literal [[CAS32_ALIGN1:.LCPI[0-9]+_[0-9]+]], __atomic_compare_exchange
; CHECK-LABEL: cas32_align1:
; CHECK: l32r {{a[0-9]+}}, [[CAS32_ALIGN1]]
; CHECK: callx8
; CHECK: retw
define {i32, i1} @cas32_align1(ptr %p, i32 %expected, i32 %new) {
  %r = cmpxchg ptr %p, i32 %expected, i32 %new acq_rel acquire, align 1
  ret {i32, i1} %r
}

; CHECK: .literal [[LOAD32_ALIGN2:.LCPI[0-9]+_[0-9]+]], __atomic_load
; CHECK-LABEL: load32_align2:
; CHECK: l32r {{a[0-9]+}}, [[LOAD32_ALIGN2]]
; CHECK: callx8
; CHECK: retw
define i32 @load32_align2(ptr %p) {
  %v = load atomic i32, ptr %p acquire, align 2
  ret i32 %v
}

; CHECK: .literal [[STORE32_ALIGN2:.LCPI[0-9]+_[0-9]+]], __atomic_store
; CHECK-LABEL: store32_align2:
; CHECK: l32r {{a[0-9]+}}, [[STORE32_ALIGN2]]
; CHECK: callx8
; CHECK: retw
define void @store32_align2(ptr %p, i32 %v) {
  store atomic i32 %v, ptr %p release, align 2
  ret void
}

; CHECK: .literal [[CAS32_ALIGN2:.LCPI[0-9]+_[0-9]+]], __atomic_compare_exchange
; CHECK-LABEL: cas32_align2:
; CHECK: l32r {{a[0-9]+}}, [[CAS32_ALIGN2]]
; CHECK: callx8
; CHECK: retw
define {i32, i1} @cas32_align2(ptr %p, i32 %expected, i32 %new) {
  %r = cmpxchg ptr %p, i32 %expected, i32 %new acq_rel acquire, align 2
  ret {i32, i1} %r
}

; CHECK: .literal [[LOAD64_ALIGN1:.LCPI[0-9]+_[0-9]+]], __atomic_load
; CHECK-LABEL: load64_align1:
; CHECK: l32r {{a[0-9]+}}, [[LOAD64_ALIGN1]]
; CHECK: callx8
; CHECK: retw
define i64 @load64_align1(ptr %p) {
  %v = load atomic i64, ptr %p acquire, align 1
  ret i64 %v
}

; CHECK: .literal [[STORE64_ALIGN1:.LCPI[0-9]+_[0-9]+]], __atomic_store
; CHECK-LABEL: store64_align1:
; CHECK: l32r {{a[0-9]+}}, [[STORE64_ALIGN1]]
; CHECK: callx8
; CHECK: retw
define void @store64_align1(ptr %p, i64 %v) {
  store atomic i64 %v, ptr %p release, align 1
  ret void
}

; CHECK: .literal [[CAS64_ALIGN1:.LCPI[0-9]+_[0-9]+]], __atomic_compare_exchange
; CHECK-LABEL: cas64_align1:
; CHECK: l32r {{a[0-9]+}}, [[CAS64_ALIGN1]]
; CHECK: callx8
; CHECK: retw
define {i64, i1} @cas64_align1(ptr %p, i64 %expected, i64 %new) {
  %r = cmpxchg ptr %p, i64 %expected, i64 %new acq_rel acquire, align 1
  ret {i64, i1} %r
}

; CHECK: .literal [[LOAD64_ALIGN2:.LCPI[0-9]+_[0-9]+]], __atomic_load
; CHECK-LABEL: load64_align2:
; CHECK: l32r {{a[0-9]+}}, [[LOAD64_ALIGN2]]
; CHECK: callx8
; CHECK: retw
define i64 @load64_align2(ptr %p) {
  %v = load atomic i64, ptr %p acquire, align 2
  ret i64 %v
}

; CHECK: .literal [[STORE64_ALIGN2:.LCPI[0-9]+_[0-9]+]], __atomic_store
; CHECK-LABEL: store64_align2:
; CHECK: l32r {{a[0-9]+}}, [[STORE64_ALIGN2]]
; CHECK: callx8
; CHECK: retw
define void @store64_align2(ptr %p, i64 %v) {
  store atomic i64 %v, ptr %p release, align 2
  ret void
}

; CHECK: .literal [[CAS64_ALIGN2:.LCPI[0-9]+_[0-9]+]], __atomic_compare_exchange
; CHECK-LABEL: cas64_align2:
; CHECK: l32r {{a[0-9]+}}, [[CAS64_ALIGN2]]
; CHECK: callx8
; CHECK: retw
define {i64, i1} @cas64_align2(ptr %p, i64 %expected, i64 %new) {
  %r = cmpxchg ptr %p, i64 %expected, i64 %new acq_rel acquire, align 2
  ret {i64, i1} %r
}

; CHECK: .literal [[LOAD64_ALIGN4:.LCPI[0-9]+_[0-9]+]], __atomic_load
; CHECK-LABEL: load64_align4:
; CHECK: l32r {{a[0-9]+}}, [[LOAD64_ALIGN4]]
; CHECK: callx8
; CHECK: retw
define i64 @load64_align4(ptr %p) {
  %v = load atomic i64, ptr %p acquire, align 4
  ret i64 %v
}

; CHECK: .literal [[STORE64_ALIGN4:.LCPI[0-9]+_[0-9]+]], __atomic_store
; CHECK-LABEL: store64_align4:
; CHECK: l32r {{a[0-9]+}}, [[STORE64_ALIGN4]]
; CHECK: callx8
; CHECK: retw
define void @store64_align4(ptr %p, i64 %v) {
  store atomic i64 %v, ptr %p release, align 4
  ret void
}

; CHECK: .literal [[CAS64_ALIGN4:.LCPI[0-9]+_[0-9]+]], __atomic_compare_exchange
; CHECK-LABEL: cas64_align4:
; CHECK: l32r {{a[0-9]+}}, [[CAS64_ALIGN4]]
; CHECK: callx8
; CHECK: retw
define {i64, i1} @cas64_align4(ptr %p, i64 %expected, i64 %new) {
  %r = cmpxchg ptr %p, i64 %expected, i64 %new acq_rel acquire, align 4
  ret {i64, i1} %r
}

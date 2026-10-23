; RUN: llc -mtriple=xtensa-esp32s3-none-elf -O0 -verify-machineinstrs < %s | FileCheck %s --check-prefix=NATIVE
; RUN: llc -mtriple=xtensa-esp32s3-none-elf -O2 -verify-machineinstrs < %s | FileCheck %s --check-prefix=NATIVE
; RUN: llc -mtriple=xtensa-esp32s3-none-elf -mattr=-s32c1i -verify-machineinstrs < %s | FileCheck %s --check-prefix=HELPER --implicit-check-not=s32c1i
;
; Every legal LLVM success/failure order pair. In particular acquire failure
; must retain a trailing barrier when CAS fails; release success needs a
; leading barrier. The C audit additionally covers consume -> acquire.

; HELPER: .literal [[CAS0:.LCPI[0-9]+_[0-9]+]], __atomic_compare_exchange_4
; NATIVE-LABEL: cas_monotonic_monotonic:
; HELPER-LABEL: cas_monotonic_monotonic:
; NATIVE-NOT: memw
; NATIVE: wsr {{a[0-9]+}}, scompare1
; NATIVE-NEXT: s32c1i
; NATIVE-NOT: memw
; HELPER: l32r {{a[0-9]+}}, [[CAS0]]
; HELPER: callx8
; NATIVE: retw
; HELPER: retw
define {i32, i1} @cas_monotonic_monotonic(ptr %p, i32 %expected, i32 %desired) {
  %r = cmpxchg ptr %p, i32 %expected, i32 %desired monotonic monotonic, align 4
  ret {i32, i1} %r
}

; HELPER: .literal [[CAS1:.LCPI[0-9]+_[0-9]+]], __atomic_compare_exchange_4
; NATIVE-LABEL: cas_acquire_monotonic:
; HELPER-LABEL: cas_acquire_monotonic:
; NATIVE-NOT: memw
; NATIVE: wsr {{a[0-9]+}}, scompare1
; NATIVE-NEXT: s32c1i
; NATIVE: memw
; HELPER: l32r {{a[0-9]+}}, [[CAS1]]
; HELPER: callx8
; NATIVE: retw
; HELPER: retw
define {i32, i1} @cas_acquire_monotonic(ptr %p, i32 %expected, i32 %desired) {
  %r = cmpxchg ptr %p, i32 %expected, i32 %desired acquire monotonic, align 4
  ret {i32, i1} %r
}

; HELPER: .literal [[CAS2:.LCPI[0-9]+_[0-9]+]], __atomic_compare_exchange_4
; NATIVE-LABEL: cas_acquire_acquire:
; HELPER-LABEL: cas_acquire_acquire:
; NATIVE-NOT: memw
; NATIVE: wsr {{a[0-9]+}}, scompare1
; NATIVE-NEXT: s32c1i
; NATIVE: memw
; HELPER: l32r {{a[0-9]+}}, [[CAS2]]
; HELPER: callx8
; NATIVE: retw
; HELPER: retw
define {i32, i1} @cas_acquire_acquire(ptr %p, i32 %expected, i32 %desired) {
  %r = cmpxchg ptr %p, i32 %expected, i32 %desired acquire acquire, align 4
  ret {i32, i1} %r
}

; HELPER: .literal [[CAS3:.LCPI[0-9]+_[0-9]+]], __atomic_compare_exchange_4
; NATIVE-LABEL: cas_release_monotonic:
; HELPER-LABEL: cas_release_monotonic:
; NATIVE: memw
; NATIVE: wsr {{a[0-9]+}}, scompare1
; NATIVE-NEXT: s32c1i
; NATIVE-NOT: memw
; HELPER: l32r {{a[0-9]+}}, [[CAS3]]
; HELPER: callx8
; NATIVE: retw
; HELPER: retw
define {i32, i1} @cas_release_monotonic(ptr %p, i32 %expected, i32 %desired) {
  %r = cmpxchg ptr %p, i32 %expected, i32 %desired release monotonic, align 4
  ret {i32, i1} %r
}

; HELPER: .literal [[CAS4:.LCPI[0-9]+_[0-9]+]], __atomic_compare_exchange_4
; NATIVE-LABEL: cas_acq_rel_monotonic:
; HELPER-LABEL: cas_acq_rel_monotonic:
; NATIVE: memw
; NATIVE: wsr {{a[0-9]+}}, scompare1
; NATIVE-NEXT: s32c1i
; NATIVE: memw
; HELPER: l32r {{a[0-9]+}}, [[CAS4]]
; HELPER: callx8
; NATIVE: retw
; HELPER: retw
define {i32, i1} @cas_acq_rel_monotonic(ptr %p, i32 %expected, i32 %desired) {
  %r = cmpxchg ptr %p, i32 %expected, i32 %desired acq_rel monotonic, align 4
  ret {i32, i1} %r
}

; HELPER: .literal [[CAS5:.LCPI[0-9]+_[0-9]+]], __atomic_compare_exchange_4
; NATIVE-LABEL: cas_acq_rel_acquire:
; HELPER-LABEL: cas_acq_rel_acquire:
; NATIVE: memw
; NATIVE: wsr {{a[0-9]+}}, scompare1
; NATIVE-NEXT: s32c1i
; NATIVE: memw
; HELPER: l32r {{a[0-9]+}}, [[CAS5]]
; HELPER: callx8
; NATIVE: retw
; HELPER: retw
define {i32, i1} @cas_acq_rel_acquire(ptr %p, i32 %expected, i32 %desired) {
  %r = cmpxchg ptr %p, i32 %expected, i32 %desired acq_rel acquire, align 4
  ret {i32, i1} %r
}

; HELPER: .literal [[CAS6:.LCPI[0-9]+_[0-9]+]], __atomic_compare_exchange_4
; NATIVE-LABEL: cas_seq_cst_monotonic:
; HELPER-LABEL: cas_seq_cst_monotonic:
; NATIVE: memw
; NATIVE: wsr {{a[0-9]+}}, scompare1
; NATIVE-NEXT: s32c1i
; NATIVE: memw
; HELPER: l32r {{a[0-9]+}}, [[CAS6]]
; HELPER: callx8
; NATIVE: retw
; HELPER: retw
define {i32, i1} @cas_seq_cst_monotonic(ptr %p, i32 %expected, i32 %desired) {
  %r = cmpxchg ptr %p, i32 %expected, i32 %desired seq_cst monotonic, align 4
  ret {i32, i1} %r
}

; HELPER: .literal [[CAS7:.LCPI[0-9]+_[0-9]+]], __atomic_compare_exchange_4
; NATIVE-LABEL: cas_seq_cst_acquire:
; HELPER-LABEL: cas_seq_cst_acquire:
; NATIVE: memw
; NATIVE: wsr {{a[0-9]+}}, scompare1
; NATIVE-NEXT: s32c1i
; NATIVE: memw
; HELPER: l32r {{a[0-9]+}}, [[CAS7]]
; HELPER: callx8
; NATIVE: retw
; HELPER: retw
define {i32, i1} @cas_seq_cst_acquire(ptr %p, i32 %expected, i32 %desired) {
  %r = cmpxchg ptr %p, i32 %expected, i32 %desired seq_cst acquire, align 4
  ret {i32, i1} %r
}

; HELPER: .literal [[CAS8:.LCPI[0-9]+_[0-9]+]], __atomic_compare_exchange_4
; NATIVE-LABEL: cas_seq_cst_seq_cst:
; HELPER-LABEL: cas_seq_cst_seq_cst:
; NATIVE: memw
; NATIVE: wsr {{a[0-9]+}}, scompare1
; NATIVE-NEXT: s32c1i
; NATIVE: memw
; HELPER: l32r {{a[0-9]+}}, [[CAS8]]
; HELPER: callx8
; NATIVE: retw
; HELPER: retw
define {i32, i1} @cas_seq_cst_seq_cst(ptr %p, i32 %expected, i32 %desired) {
  %r = cmpxchg ptr %p, i32 %expected, i32 %desired seq_cst seq_cst, align 4
  ret {i32, i1} %r
}

; NATIVE-LABEL: fence_acquire:
; HELPER-LABEL: fence_acquire:
; NATIVE: memw
; NATIVE-NEXT: retw
; HELPER: memw
; HELPER-NEXT: retw
define void @fence_acquire() {
  fence acquire
  ret void
}

; NATIVE-LABEL: fence_release:
; HELPER-LABEL: fence_release:
; NATIVE: memw
; NATIVE-NEXT: retw
; HELPER: memw
; HELPER-NEXT: retw
define void @fence_release() {
  fence release
  ret void
}

; NATIVE-LABEL: fence_acq_rel:
; HELPER-LABEL: fence_acq_rel:
; NATIVE: memw
; NATIVE-NEXT: retw
; HELPER: memw
; HELPER-NEXT: retw
define void @fence_acq_rel() {
  fence acq_rel
  ret void
}

; NATIVE-LABEL: fence_seq_cst:
; HELPER-LABEL: fence_seq_cst:
; NATIVE: memw
; NATIVE-NEXT: retw
; HELPER: memw
; HELPER-NEXT: retw
define void @fence_seq_cst() {
  fence seq_cst
  ret void
}

; A seq-cst store followed by a seq-cst load must include the interposed
; hardware fence: two cores cannot both read the initial value in SB.
; NATIVE-LABEL: seqcst_store_buffering:
; NATIVE: memw
; NATIVE: s32i
; NATIVE-NEXT: memw
; NATIVE-NEXT: l32i
; NATIVE-NEXT: memw
; NATIVE: retw
define i32 @seqcst_store_buffering(ptr %own, ptr %other) {
  store atomic i32 1, ptr %own seq_cst, align 4
  %r = load atomic i32, ptr %other seq_cst, align 4
  ret i32 %r
}

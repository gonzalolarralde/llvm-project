; RUN: llc -mtriple=xtensa-esp32s3-none-elf -verify-machineinstrs < %s | FileCheck %s --check-prefixes=COMMON,NATIVE
; RUN: llc -mtriple=xtensa-esp32s3-none-elf -mattr=-s32c1i -verify-machineinstrs < %s | FileCheck %s --check-prefixes=COMMON,HELPER --implicit-check-not=s32c1i
;
; Native-width CAS must not be used for wider or insufficiently aligned
; objects. When native atomics are disabled, even aligned 32-bit operations
; must use the runtime helper ABI. Check ordering fences on the native path.

; COMMON: .literal [[ADD64:.LCPI[0-9]+_[0-9]+]], __atomic_fetch_add_8
; COMMON-LABEL: add64:
; COMMON: l32r {{a[0-9]+}}, [[ADD64]]
; COMMON: callx8
; COMMON: retw
define i64 @add64(ptr %p, i64 %v) {
  %old = atomicrmw add ptr %p, i64 %v seq_cst, align 8
  ret i64 %old
}

; COMMON: .literal [[CAS16:.LCPI[0-9]+_[0-9]+]], __atomic_compare_exchange
; COMMON-LABEL: unaligned_cas16:
; COMMON: l32r {{a[0-9]+}}, [[CAS16]]
; COMMON: callx8
; COMMON: retw
define {i16, i1} @unaligned_cas16(ptr %p, i16 %expected, i16 %new) {
  %r = cmpxchg ptr %p, i16 %expected, i16 %new acq_rel acquire, align 1
  ret {i16, i1} %r
}

; COMMON: .literal [[CAS32:.LCPI[0-9]+_[0-9]+]], __atomic_compare_exchange
; COMMON-LABEL: unaligned_cas32:
; COMMON: l32r {{a[0-9]+}}, [[CAS32]]
; COMMON: callx8
; COMMON: retw
define {i32, i1} @unaligned_cas32(ptr %p, i32 %expected, i32 %new) {
  %r = cmpxchg ptr %p, i32 %expected, i32 %new acq_rel acquire, align 1
  ret {i32, i1} %r
}

; HELPER: .literal [[LOAD:.LCPI[0-9]+_[0-9]+]], __atomic_load_4
; COMMON-LABEL: load_acquire:
; NATIVE: l32i
; NATIVE-NEXT: memw
; HELPER: l32r {{a[0-9]+}}, [[LOAD]]
; HELPER: callx8
; COMMON: retw
define i32 @load_acquire(ptr %p) {
  %v = load atomic i32, ptr %p acquire, align 4
  ret i32 %v
}

; HELPER: .literal [[STORE:.LCPI[0-9]+_[0-9]+]], __atomic_store_4
; COMMON-LABEL: store_release:
; NATIVE: memw
; NATIVE-NEXT: s32i
; HELPER: l32r {{a[0-9]+}}, [[STORE]]
; HELPER: callx8
; COMMON: retw
define void @store_release(ptr %p, i32 %v) {
  store atomic i32 %v, ptr %p release, align 4
  ret void
}

; HELPER: .literal [[CAS:.LCPI[0-9]+_[0-9]+]], __atomic_compare_exchange_4
; COMMON-LABEL: cas_acq_rel:
; NATIVE: memw
; NATIVE: wsr {{a[0-9]+}}, scompare1
; NATIVE-NEXT: s32c1i
; NATIVE: memw
; HELPER: l32r {{a[0-9]+}}, [[CAS]]
; HELPER: callx8
; COMMON: retw
define {i32, i1} @cas_acq_rel(ptr %p, i32 %expected, i32 %new) {
  %r = cmpxchg ptr %p, i32 %expected, i32 %new acq_rel acquire, align 4
  ret {i32, i1} %r
}

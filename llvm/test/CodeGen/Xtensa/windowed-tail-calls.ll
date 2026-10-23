; RUN: llc -mtriple=xtensa-esp32-none-elf -O0 -verify-machineinstrs < %s | FileCheck %s
; RUN: llc -mtriple=xtensa-esp32-none-elf -O0 -filetype=obj -verify-machineinstrs < %s -o %t.esp32.O0.o
; RUN: llvm-dwarfdump --eh-frame %t.esp32.O0.o | FileCheck %s --check-prefix=CFI
; RUN: llc -mtriple=xtensa-esp32-none-elf -O2 -verify-machineinstrs < %s | FileCheck %s
; RUN: llc -mtriple=xtensa-esp32-none-elf -O2 -filetype=obj -verify-machineinstrs < %s -o %t.esp32.O2.o
; RUN: llvm-dwarfdump --eh-frame %t.esp32.O2.o | FileCheck %s --check-prefix=CFI
; RUN: llc -mtriple=xtensa-esp32s2-none-elf -O0 -verify-machineinstrs < %s | FileCheck %s
; RUN: llc -mtriple=xtensa-esp32s2-none-elf -O0 -filetype=obj -verify-machineinstrs < %s -o %t.esp32s2.O0.o
; RUN: llvm-dwarfdump --eh-frame %t.esp32s2.O0.o | FileCheck %s --check-prefix=CFI
; RUN: llc -mtriple=xtensa-esp32s2-none-elf -O2 -verify-machineinstrs < %s | FileCheck %s
; RUN: llc -mtriple=xtensa-esp32s2-none-elf -O2 -filetype=obj -verify-machineinstrs < %s -o %t.esp32s2.O2.o
; RUN: llvm-dwarfdump --eh-frame %t.esp32s2.O2.o | FileCheck %s --check-prefix=CFI
; RUN: llc -mtriple=xtensa-esp32s3-none-elf -O0 -verify-machineinstrs < %s | FileCheck %s
; RUN: llc -mtriple=xtensa-esp32s3-none-elf -O0 -filetype=obj -verify-machineinstrs < %s -o %t.esp32s3.O0.o
; RUN: llvm-dwarfdump --eh-frame %t.esp32s3.O0.o | FileCheck %s --check-prefix=CFI
; RUN: llc -mtriple=xtensa-esp32s3-none-elf -O2 -verify-machineinstrs < %s | FileCheck %s
; RUN: llc -mtriple=xtensa-esp32s3-none-elf -O2 -filetype=obj -verify-machineinstrs < %s -o %t.esp32s3.O2.o
; RUN: llvm-dwarfdump --eh-frame %t.esp32s3.O2.o | FileCheck %s --check-prefix=CFI

; Reuse the original window and its return address. The target's ENTRY size
; is decoded, but ENTRY's window rotation is not executed a second time.
define internal i32 @identity(i32 %x) noinline {
  ret i32 %x
}

define i32 @sibling(i32 %x) uwtable {
; CHECK-LABEL: sibling:
; CHECK: entry a1, 32
; CHECK: addi a9, a1, 32
; CHECK: .cfi_remember_state
; CHECK: .cfi_def_cfa a9, 0
; CHECK: l32i a10, a8, 0
; CHECK-NEXT: extui a10, a10, 12, 12
; CHECK-NEXT: slli a10, a10, 3
; CHECK-NEXT: sub a10, a9, a10
; CHECK-NEXT: movsp a1, a10
; CHECK-NEXT: addi a8, a8, 3
; CHECK-NEXT: jx a8
; CHECK-NEXT: .cfi_restore_state
; CHECK-NOT: callx8
; CHECK-NOT: retw
; CHECK: .size sibling,
  %r = tail call i32 @identity(i32 %x)
  ret i32 %r
}

; The CFA must survive replacement of FP (a7) by the sixth argument.
define internal i32 @six(i32 %a, i32 %b, i32 %c, i32 %d, i32 %e, i32 %f) noinline {
  ret i32 %f
}
define i32 @with_fp(i32 %a, i32 %b, i32 %c, i32 %d, i32 %e, i32 %f) uwtable "frame-pointer"="all" {
; CHECK-LABEL: with_fp:
; CHECK: or a7, a1, a1
; CHECK: .cfi_remember_state
; CHECK-NEXT: .cfi_def_cfa a9, 0
; CHECK: or a7,
; CHECK: movsp a1, a10
; CHECK: jx a8
  %r = musttail call i32 @six(i32 %f, i32 %e, i32 %d, i32 %c, i32 %b, i32 %a)
  ret i32 %r
}

define internal i32 @eight(i32 %a, i32 %b, i32 %c, i32 %d, i32 %e, i32 %f, i32 %g, i32 %h) noinline {
  %r = add i32 %g, %h
  ret i32 %r
}
define i32 @stack_swap(i32 %a, i32 %b, i32 %c, i32 %d, i32 %e, i32 %f, i32 %g, i32 %h) {
; CHECK-LABEL: stack_swap:
; CHECK: l32i
; CHECK: l32i
; CHECK: s32i
; CHECK: s32i
; CHECK: jx a8
  %r = musttail call i32 @eight(i32 %a, i32 %b, i32 %c, i32 %d, i32 %e, i32 %f, i32 %h, i32 %g)
  ret i32 %r
}

; Clang also represents scalar stack arguments as byval pointers. Read every
; source before writing any destination, including overlapping byval slots.
define internal i32 @byval_sink(ptr byval([4 x i8]) align 1 %a, ptr byval([4 x i8]) align 1 %b) noinline {
  %x = load i8, ptr %a
  %y = zext i8 %x to i32
  ret i32 %y
}
define i32 @byval_swap(ptr byval([4 x i8]) align 1 %a, ptr byval([4 x i8]) align 1 %b) {
; CHECK-LABEL: byval_swap:
; CHECK: l{{(8u|16u|32)}}i
; CHECK: s{{(8|16|32)}}i
; CHECK: jx a8
  %r = musttail call i32 @byval_sink(ptr byval([4 x i8]) align 1 %b, ptr byval([4 x i8]) align 1 %a)
  ret i32 %r
}

; An ordinary sibling call may fall back when its stack area would grow.
define i32 @more_stack(i32 %x) {
; CHECK-LABEL: more_stack:
; CHECK: callx8
; CHECK: retw
  %r = tail call i32 @eight(i32 %x, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7, i32 8)
  ret i32 %r
}

declare i32 @external(i32)
define i32 @external_fallback(i32 %x) {
; CHECK-LABEL: external_fallback:
; CHECK: callx8
; CHECK: retw
  %r = tail call i32 @external(i32 %x)
  ret i32 %r
}

define weak i32 @replaceable(i32 %x) { ret i32 %x }
define i32 @weak_fallback(i32 %x) {
; CHECK-LABEL: weak_fallback:
; CHECK: callx8
; CHECK: retw
  %r = tail call i32 @replaceable(i32 %x)
  ret i32 %r
}

define i32 @indirect_fallback(ptr %callee, i32 %x) {
; CHECK-LABEL: indirect_fallback:
; CHECK: callx8
; CHECK: retw
  %r = tail call i32 %callee(i32 %x)
  ret i32 %r
}

define i32 @disabled(i32 %x) "disable-tail-calls"="true" {
; CHECK-LABEL: disabled:
; CHECK: callx8
; CHECK: retw
  %r = tail call i32 @identity(i32 %x)
  ret i32 %r
}

; The inclusive byval bound must remain usable under register pressure.
define internal i32 @byval_limit_sink(ptr byval([256 x i8]) align 4 %a) noinline {
  %last = getelementptr i8, ptr %a, i32 255
  %x = load i8, ptr %last
  %r = zext i8 %x to i32
  ret i32 %r
}
define i32 @byval_limit(ptr byval([256 x i8]) align 4 %a) {
; CHECK-LABEL: byval_limit:
; CHECK: jx a8
; CHECK-NOT: callx8
; CHECK: .size byval_limit,
  %r = musttail call i32 @byval_limit_sink(ptr byval([256 x i8]) align 4 %a)
  ret i32 %r
}

define internal void @sret_sink(ptr sret([32 x i8]) %out) noinline {
  store i8 42, ptr %out
  ret void
}
define void @sret_fallback(ptr sret([32 x i8]) %out) {
; CHECK-LABEL: sret_fallback:
; CHECK: callx8
; CHECK: retw
  tail call void @sret_sink(ptr sret([32 x i8]) %out)
  ret void
}

define internal i32 @vararg_sink(i32 %x, ...) noinline { ret i32 %x }
define i32 @vararg_fallback(i32 %x) {
; CHECK-LABEL: vararg_fallback:
; CHECK: callx8
; CHECK: retw
  %r = tail call i32 (i32, ...) @vararg_sink(i32 %x)
  ret i32 %r
}

; CFI: DW_CFA_remember_state
; CFI: DW_CFA_def_cfa: A9 +0
; CFI: DW_CFA_restore_state

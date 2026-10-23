; RUN: split-file %s %t
; RUN: not llc -mtriple=xtensa-esp32-none-elf -O0 %t/external.ll -o /dev/null 2>&1 | FileCheck %s
; RUN: not llc -mtriple=xtensa-esp32-none-elf -O0 %t/indirect.ll -o /dev/null 2>&1 | FileCheck %s
; RUN: not llc -mtriple=xtensa-esp32-none-elf -O0 %t/large-byval.ll -o /dev/null 2>&1 | FileCheck %s
; RUN: not llc -mtriple=xtensa-esp32-none-elf -O2 %t/external.ll -o /dev/null 2>&1 | FileCheck %s
; RUN: not llc -mtriple=xtensa-esp32-none-elf -O2 %t/indirect.ll -o /dev/null 2>&1 | FileCheck %s
; RUN: not llc -mtriple=xtensa-esp32-none-elf -O2 %t/large-byval.ll -o /dev/null 2>&1 | FileCheck %s
; RUN: not llc -mtriple=xtensa-esp32s2-none-elf -O0 %t/external.ll -o /dev/null 2>&1 | FileCheck %s
; RUN: not llc -mtriple=xtensa-esp32s2-none-elf -O0 %t/indirect.ll -o /dev/null 2>&1 | FileCheck %s
; RUN: not llc -mtriple=xtensa-esp32s2-none-elf -O0 %t/large-byval.ll -o /dev/null 2>&1 | FileCheck %s
; RUN: not llc -mtriple=xtensa-esp32s2-none-elf -O2 %t/external.ll -o /dev/null 2>&1 | FileCheck %s
; RUN: not llc -mtriple=xtensa-esp32s2-none-elf -O2 %t/indirect.ll -o /dev/null 2>&1 | FileCheck %s
; RUN: not llc -mtriple=xtensa-esp32s2-none-elf -O2 %t/large-byval.ll -o /dev/null 2>&1 | FileCheck %s
; RUN: not llc -mtriple=xtensa-esp32s3-none-elf -O0 %t/external.ll -o /dev/null 2>&1 | FileCheck %s
; RUN: not llc -mtriple=xtensa-esp32s3-none-elf -O0 %t/indirect.ll -o /dev/null 2>&1 | FileCheck %s
; RUN: not llc -mtriple=xtensa-esp32s3-none-elf -O0 %t/large-byval.ll -o /dev/null 2>&1 | FileCheck %s
; RUN: not llc -mtriple=xtensa-esp32s3-none-elf -O2 %t/external.ll -o /dev/null 2>&1 | FileCheck %s
; RUN: not llc -mtriple=xtensa-esp32s3-none-elf -O2 %t/indirect.ll -o /dev/null 2>&1 | FileCheck %s
; RUN: not llc -mtriple=xtensa-esp32s3-none-elf -O2 %t/large-byval.ll -o /dev/null 2>&1 | FileCheck %s
; RUN: not llc -mtriple=xtensa-none-elf -mattr=-windowed -O0 %t/call0.ll -o /dev/null 2>&1 | FileCheck %s
; RUN: not llc -mtriple=xtensa-unknown-none-elf -mcpu=esp32 -O0 %t/call0.ll -o /dev/null 2>&1 | FileCheck %s
; RUN: not llc -mtriple=xtensa-none-elf -mattr=-windowed -O2 %t/call0.ll -o /dev/null 2>&1 | FileCheck %s
; RUN: not llc -mtriple=xtensa-unknown-none-elf -mcpu=esp32 -O2 %t/call0.ll -o /dev/null 2>&1 | FileCheck %s
; CHECK: error: {{.*}}Xtensa musttail requires a direct, non-replaceable ESP32-family windowed definition
; CHECK-NOT: LLVM ERROR
; CHECK-NOT: Stack dump

;--- external.ll
declare i32 @external(i32)
define i32 @bad(i32 %x) {
  %r = musttail call i32 @external(i32 %x)
  ret i32 %r
}
;--- indirect.ll
define i32 @bad(ptr %p, i32 %x) {
  %r = musttail call i32 %p(ptr %p, i32 %x)
  ret i32 %r
}
;--- large-byval.ll
define internal i32 @callee(ptr byval([257 x i8]) %p) { ret i32 0 }
define i32 @bad(ptr byval([257 x i8]) %p) {
  %r = musttail call i32 @callee(ptr byval([257 x i8]) %p)
  ret i32 %r
}
;--- call0.ll
define internal i32 @callee(i32 %x) { ret i32 %x }
define i32 @bad(i32 %x) {
  %r = musttail call i32 @callee(i32 %x)
  ret i32 %r
}

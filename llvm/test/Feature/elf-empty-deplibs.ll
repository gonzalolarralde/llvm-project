; RUN: llc -mtriple=x86_64-unknown-linux -filetype=obj %s -o %t
; RUN: llvm-readobj --sections %t | FileCheck %s
; RUN: llc -mtriple=xtensa-esp32s3-none-elf -filetype=obj %s -o %t.s3
; RUN: llvm-readobj --sections %t.s3 | FileCheck %s
; REQUIRES: x86-registered-target, xtensa-registered-target

; Empty autolinking metadata must not create an orphan section for a strict
; GNU ld script. Swift Embedded bitcode can carry this empty named metadata.
; CHECK: Sections [
; CHECK-NOT: Name: .deplibs
; CHECK: Name: .text
; CHECK-NOT: Name: .deplibs
!llvm.dependent-libraries = !{}

define void @entry() {
  ret void
}

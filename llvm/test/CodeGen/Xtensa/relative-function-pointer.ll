; RUN: llc -mtriple=xtensa -mcpu=esp32s3 -filetype=obj %s -o %t
; RUN: llvm-readelf -r %t | FileCheck %s
;
; Swift async descriptors hold a function address relative to their own field.
; Emitting an absolute relocation silently adds the descriptor address twice.
; CHECK: R_XTENSA_32_PCREL {{.*}} resume
@descriptor = global <{ i32, i32 }> <{
  i32 sub (i32 ptrtoint (ptr @resume to i32),
           i32 ptrtoint (ptr @descriptor to i32)), i32 16
}>, align 4
declare void @resume(ptr)

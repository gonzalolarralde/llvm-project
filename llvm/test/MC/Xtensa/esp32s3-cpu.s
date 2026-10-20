# RUN: llvm-mc -triple=xtensa-esp32s3-none-elf -filetype=obj %s -o %t.o
# RUN: llvm-objdump --triple=xtensa-esp32s3-none-elf -d %t.o | FileCheck %s

# CHECK: entry a1, 32
# CHECK: add.s f0, f1, f2
# CHECK: retw.n
entry a1, 32
add.s f0, f1, f2
retw.n

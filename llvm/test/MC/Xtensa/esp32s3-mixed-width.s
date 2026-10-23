# RUN: llvm-mc -triple=xtensa-esp32s3-none-elf -filetype=obj %s -o %t.o
# RUN: llvm-objdump --triple=xtensa-esp32s3-none-elf --no-print-imm-hex -d %t.o | FileCheck %s

# An S3 text section can freely interleave core 16/24-bit and TIE 24/32-bit
# instructions. Check the addresses and byte counts as well as the operands so
# a decoder that consumes part of a following instruction cannot pass.
# CHECK-LABEL: <mixed>:
# CHECK-NEXT: 0: 36 41 00 {{[ ]*}}entry a1, 32
# CHECK-NEXT: 3: 3d f0 {{[ ]*}}nop.n
# CHECK-NEXT: 5: c4 b8 ed {{[ ]*}}ee.andq q5, q6, q4
# CHECK-NEXT: 8: 7e 6e 05 e1 {{[ ]*}}ee.cmul.s16.ld.incp q2, a7, q5, q1, q4, 2
# CHECK-NEXT: c: 22 c2 ff {{[ ]*}}addi a2, a2, -1
# CHECK-NEXT: f: 24 27 45 {{[ ]*}}ee.ldqa.u16.128.ip a2, -1424
# CHECK-NEXT: 12: 1d f0 {{[ ]*}}retw.n
.text
mixed:
entry a1, 32
nop.n
ee.andq q5, q6, q4
ee.cmul.s16.ld.incp q2, a7, q5, q1, q4, 2
addi a2, a2, -1
ee.ldqa.u16.128.ip a2, -1424
retw.n

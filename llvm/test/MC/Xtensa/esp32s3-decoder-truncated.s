# RUN: split-file %s %t
# RUN: not llvm-mc -triple=xtensa -mcpu=esp32s3 -disassemble < %t/density.txt 2>&1 | FileCheck %s --check-prefix=INVALID
# RUN: not llvm-mc -triple=xtensa -mcpu=esp32s3 -disassemble < %t/core.txt 2>&1 | FileCheck %s --check-prefix=INVALID
# RUN: not llvm-mc -triple=xtensa -mcpu=esp32s3 -disassemble < %t/dsp24.txt 2>&1 | FileCheck %s --check-prefix=INVALID
# RUN: not llvm-mc -triple=xtensa -mcpu=esp32s3 -disassemble < %t/dsp32.txt 2>&1 | FileCheck %s --check-prefix=INVALID
# RUN: not llvm-mc -triple=xtensa -mcpu=esp32s3 -disassemble < %t/after-valid.txt > %t/out 2> %t/err
# RUN: FileCheck %s --check-prefix=INVALID < %t/err
# RUN: FileCheck %s --check-prefix=PREFIX < %t/out

# Each incomplete instruction ends the input buffer. In particular, the last
# case first decodes valid instructions of all supported widths, then hits a
# 32-bit S3 instruction with only three bytes available. It must fail without
# reading a fourth byte or reusing the previous instruction's size.
# INVALID: warning: invalid instruction encoding
# INVALID-NOT: ee.
# PREFIX: nop.n
# PREFIX-NEXT: ee.andq q5, q6, q4
# PREFIX-NEXT: ee.cmul.s16.ld.incp q2, a7, q5, q1, q4, 2
# PREFIX-NOT: ee.

#--- density.txt
[0x3d]
#--- core.txt
[0x36,0x41]
#--- dsp24.txt
[0xc4,0xb8]
#--- dsp32.txt
[0x7e,0x6e,0x05]
#--- after-valid.txt
[0x3d,0xf0,0xc4,0xb8,0xed,0x7e,0x6e,0x05,0xe1,0x7e,0x6e,0x05]

# RUN: llvm-mc -triple=xtensa -mcpu=esp32s3 -show-encoding %s | FileCheck %s
# RUN: llvm-mc -triple=xtensa -mcpu=esp32s3 -show-encoding %s \
# RUN:   | sed -n 's/.*encoding: //p' \
# RUN:   | llvm-mc -triple=xtensa -mcpu=esp32s3 -disassemble \
# RUN:   | FileCheck %s
# RUN: llvm-mc -triple=xtensa -mcpu=esp32s3 -filetype=obj %s -o %t.o
# RUN: llvm-objdump --triple=xtensa --mcpu=esp32s3 --no-print-imm-hex -d %t.o | FileCheck %s

# Cover signed minimum/maximum, zero, and offsets whose scaled representation
# has its low bits clear. Scaling is unconditional, and sign extension must
# use the encoded field width before multiplying by the alignment.
# CHECK: ee.ldf.128.ip f3, f5, f8, f0, a13, -128
ee.ldf.128.ip f3, f5, f8, f0, a13, -128

# CHECK: ee.ldf.128.ip f3, f5, f8, f0, a13, 112
ee.ldf.128.ip f3, f5, f8, f0, a13, 112

# CHECK: ee.ldf.128.ip f3, f5, f8, f0, a13, 0
ee.ldf.128.ip f3, f5, f8, f0, a13, 0

# CHECK: ee.ldf.64.ip f6, f5, a1, -1024
ee.ldf.64.ip f6, f5, a1, -1024

# CHECK: ee.ldf.64.ip f6, f5, a1, 1016
ee.ldf.64.ip f6, f5, a1, 1016

# CHECK: ee.ldf.64.ip f6, f5, a1, 128
ee.ldf.64.ip f6, f5, a1, 128

# CHECK: ee.ldqa.s16.128.ip a11, -2048
ee.ldqa.s16.128.ip a11, -2048

# CHECK: ee.ldqa.s16.128.ip a11, 2032
ee.ldqa.s16.128.ip a11, 2032

# CHECK: ee.ldqa.s16.128.ip a11, 256
ee.ldqa.s16.128.ip a11, 256

# CHECK: ee.ld.qacc_h.h.32.ip a6, -512
ee.ld.qacc_h.h.32.ip a6, -512

# CHECK: ee.ld.qacc_h.h.32.ip a6, 508
ee.ld.qacc_h.h.32.ip a6, 508

# CHECK: ee.ld.qacc_h.h.32.ip a6, 64
ee.ld.qacc_h.h.32.ip a6, 64

# CHECK: ee.vldbc.16.ip q6, a4, 0
ee.vldbc.16.ip q6, a4, 0

# CHECK: ee.vldbc.16.ip q6, a4, 254
ee.vldbc.16.ip q6, a4, 254

# CHECK: ee.vldbc.16.ip q6, a4, 32
ee.vldbc.16.ip q6, a4, 32

# CHECK: ee.vldbc.8.ip q3, a3, 0
ee.vldbc.8.ip q3, a3, 0

# CHECK: ee.vldbc.8.ip q3, a3, 127
ee.vldbc.8.ip q3, a3, 127

# CHECK: ee.vmulas.s16.accx.ld.ip.qup q5, a14, -512, q0, q2, q0, q2
ee.vmulas.s16.accx.ld.ip.qup q5, a14, -512, q0, q2, q0, q2

# CHECK: ee.vmulas.s16.accx.ld.ip.qup q5, a14, 496, q0, q2, q0, q2
ee.vmulas.s16.accx.ld.ip.qup q5, a14, 496, q0, q2, q0, q2

# CHECK: ee.vmulas.s16.accx.ld.ip.qup q5, a14, 256, q0, q2, q0, q2
ee.vmulas.s16.accx.ld.ip.qup q5, a14, 256, q0, q2, q0, q2

# CHECK: ee.slci.2q q7, q4, 0
ee.slci.2q q7, q4, 0

# CHECK: ee.slci.2q q7, q4, 15
ee.slci.2q q7, q4, 15

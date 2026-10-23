# RUN: llvm-mc -triple=xtensa -mcpu=esp32s3 -show-encoding %s | FileCheck %s --check-prefixes=CHECK,ENCODING
# RUN: llvm-mc -triple=xtensa -mcpu=esp32s3 -show-encoding %s \
# RUN:   | sed -n 's/.*encoding: //p' \
# RUN:   | llvm-mc -triple=xtensa -mcpu=esp32s3 -disassemble \
# RUN:   | FileCheck %s

# Reusing an input register as an output or as another input is legal. Only
# collisions between independent outputs are rejected, including outputs tied
# to update operands. The corresponding illegal forms are tested separately.
# Each expected S3 encoding was independently checked with Espressif GNU as.

# CHECK: ee.ldf.128.xp f5, f2, f4, f0, a7, a8
# ENCODING: encoding: [0x7e,0x48,0x09,0x8a]
ee.ldf.128.xp f5, f2, f4, f0, a7, a8

# CHECK: ee.srci.2q q6, q5, 14
# ENCODING: encoding: [0xe4,0x5a,0xfc]
ee.srci.2q q6, q5, 14

# CHECK: ee.vldhbc.16.incp q5, q4, a14
# ENCODING: encoding: [0xe4,0xc2,0xec]
ee.vldhbc.16.incp q5, q4, a14

# CHECK: ee.vmax.s32.ld.incp q2, a3, q1, q1, q0
# ENCODING: encoding: [0x3e,0x4e,0x11,0xe1]
ee.vmax.s32.ld.incp q2, a3, q1, q1, q0

# CHECK: ee.vmulas.u16.accx.ld.xp.qup q5, a3, a7, q6, q2, q4, q4
# ENCODING: encoding: [0x3f,0x97,0x4c,0xc2]
ee.vmulas.u16.accx.ld.xp.qup q5, a3, a7, q6, q2, q4, q4

# CHECK: ee.vmulas.u16.qacc.ld.ip.qup q1, a4, 0, q5, q4, q2, q6
# ENCODING: encoding: [0x4f,0x60,0x2e,0x50]
ee.vmulas.u16.qacc.ld.ip.qup q1, a4, 0, q5, q4, q2, q6

# CHECK: ee.vmulas.u8.accx.ld.ip.qup q6, a3, -32, q3, q3, q7, q5
# ENCODING: encoding: [0x3e,0xde,0xf5,0x6f]
ee.vmulas.u8.accx.ld.ip.qup q6, a3, -32, q3, q3, q7, q5

# CHECK: ee.vmulas.u8.qacc.ld.xp.qup q0, a8, a10, q3, q7, q1, q3
# ENCODING: encoding: [0x8e,0xfa,0x93,0xcc]
ee.vmulas.u8.qacc.ld.xp.qup q0, a8, a10, q3, q7, q1, q3

# CHECK: ee.vsubs.s32.ld.incp q2, a8, q1, q4, q0
# ENCODING: encoding: [0x8f,0x0d,0x51,0xe1]
ee.vsubs.s32.ld.incp q2, a8, q1, q4, q0

# Core read/modify/write instructions and outputs in different register files
# remain valid under the same check.
# CHECK: add a2, a2, a2
add a2, a2, a2
# CHECK: xsr a2, sar
xsr a2, sar
# CHECK: ldinc m0, a2
ldinc m0, a2

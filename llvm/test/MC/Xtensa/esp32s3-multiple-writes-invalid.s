# RUN: not llvm-mc %s -triple=xtensa -mcpu=esp32s3 2>&1 | FileCheck %s

ee.ldf.128.xp f5, f2, f4, f4, a7, a8
# CHECK: :[[#@LINE-1]]:1: error: multiple writes to the same register

ee.srci.2q q6, q6, 14
# CHECK: :[[#@LINE-1]]:1: error: multiple writes to the same register

ee.vldhbc.16.incp q5, q5, a14
# CHECK: :[[#@LINE-1]]:1: error: multiple writes to the same register

ee.vmax.s32.ld.incp q1, a3, q1, q1, q0
# CHECK: :[[#@LINE-1]]:1: error: multiple writes to the same register

ee.vmulas.u16.accx.ld.xp.qup q4, a3, a7, q6, q2, q4, q4
# CHECK: :[[#@LINE-1]]:1: error: multiple writes to the same register

ee.vmulas.u16.qacc.ld.ip.qup q2, a4, 0, q5, q4, q2, q6
# CHECK: :[[#@LINE-1]]:1: error: multiple writes to the same register

ee.vmulas.u8.accx.ld.ip.qup q7, a3, -32, q3, q3, q7, q5
# CHECK: :[[#@LINE-1]]:1: error: multiple writes to the same register

ee.vmulas.u8.qacc.ld.xp.qup q1, a8, a10, q3, q7, q1, q3
# CHECK: :[[#@LINE-1]]:1: error: multiple writes to the same register

ee.vsubs.s32.ld.incp q1, a8, q1, q4, q0
# CHECK: :[[#@LINE-1]]:1: error: multiple writes to the same register


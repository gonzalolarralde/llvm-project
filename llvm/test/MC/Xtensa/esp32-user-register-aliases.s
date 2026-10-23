# RUN: split-file %s %t
# RUN: llvm-mc -triple=xtensa -mcpu=esp32s2 -show-encoding %t/common.s | FileCheck %s --check-prefix=S2
# RUN: llvm-mc -triple=xtensa -mcpu=esp32s3 -show-encoding %t/common.s | FileCheck %s --check-prefix=S3
# RUN: llvm-mc -triple=xtensa -mcpu=esp32s2 -filetype=obj %t/common.s -o %t/s2.o
# RUN: llvm-objdump --triple=xtensa --mcpu=esp32s2 -d %t/s2.o | FileCheck %s --check-prefix=S2-DIS
# RUN: llvm-mc -triple=xtensa -mcpu=esp32s3 -filetype=obj %t/common.s -o %t/s3.o
# RUN: llvm-objdump --triple=xtensa --mcpu=esp32s3 -d %t/s3.o | FileCheck %s --check-prefix=S3-DIS
# RUN: not llvm-mc -triple=xtensa -mcpu=esp32s2 %t/sar-byte.s 2>&1 | FileCheck %s --check-prefix=UNAVAILABLE
# RUN: not llvm-mc -triple=xtensa %t/sar-byte.s 2>&1 | FileCheck %s --check-prefix=UNAVAILABLE
# RUN: llvm-mc -triple=xtensa -mcpu=esp32s3 -show-encoding %t/sar-byte.s | FileCheck %s --check-prefix=SAR

# Code zero names GPIO_OUT on S2 and ACCX_0 on S3. Both symbolic and numeric
# operands must select the same register when assembling and disassembling.
# S2: rur a3, gpio_out {{.*}}encoding: [0x00,0x30,0xe3]
# S2: rur a3, gpio_out {{.*}}encoding: [0x00,0x30,0xe3]
# S2: wur a3, gpio_out {{.*}}encoding: [0x30,0x00,0xf3]
# S2: rur a3, gpio_out {{.*}}encoding: [0x00,0x30,0xe3]
# S2: wur a3, gpio_out {{.*}}encoding: [0x30,0x00,0xf3]
# S3: rur a3, gpio_out {{.*}}encoding: [0xc0,0x30,0xe3]
# S3: rur a3, gpio_out {{.*}}encoding: [0xc0,0x30,0xe3]
# S3: wur a3, gpio_out {{.*}}encoding: [0x30,0x0c,0xf3]
# S3: rur a3, accx_0 {{.*}}encoding: [0x00,0x30,0xe3]
# S3: wur a3, accx_0 {{.*}}encoding: [0x30,0x00,0xf3]
# S2-DIS: rur a3, gpio_out
# S2-DIS: rur a3, gpio_out
# S2-DIS: wur a3, gpio_out
# S2-DIS: rur a3, gpio_out
# S2-DIS: wur a3, gpio_out
# S3-DIS: rur a3, gpio_out
# S3-DIS: rur a3, gpio_out
# S3-DIS: wur a3, gpio_out
# S3-DIS: rur a3, accx_0
# S3-DIS: wur a3, accx_0
# UNAVAILABLE: error: invalid operand for instruction
# SAR: rur a3, sar_byte {{.*}}encoding: [0xd0,0x30,0xe3]
# SAR: wur a3, sar_byte {{.*}}encoding: [0x30,0x0d,0xf3]

#--- common.s
rur a3, gpio_out
rur.GPIO_OUT a3
wur.gpio_out a3
rur a3, 0
wur a3, 0
#--- sar-byte.s
rur a3, sar_byte
wur a3, sar_byte

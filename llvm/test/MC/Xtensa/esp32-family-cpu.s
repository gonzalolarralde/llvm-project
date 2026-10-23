# RUN: split-file %s %t
# RUN: llvm-mc -triple=xtensa-esp32-none-elf -filetype=obj %t/windowed.s -o %t.esp32.o
# RUN: llvm-objdump --triple=xtensa-esp32-none-elf -d %t.esp32.o | FileCheck %s --check-prefix=WINDOWED
# RUN: llvm-mc -triple=xtensa-esp32s2-none-elf -filetype=obj %t/windowed.s -o %t.s2.o
# RUN: llvm-objdump --triple=xtensa-esp32s2-none-elf -d %t.s2.o | FileCheck %s --check-prefix=WINDOWED
# RUN: llvm-mc -triple=xtensa-esp32-none-elf -show-encoding %t/fp-cas.s | FileCheck %s --check-prefix=FP-CAS
# RUN: llvm-mc -triple=xtensa-esp32s3-none-elf -show-encoding %t/fp-cas.s | FileCheck %s --check-prefix=FP-CAS
# RUN: not llvm-mc -triple=xtensa-esp32s2-none-elf -filetype=obj %t/fp-cas.s -o /dev/null 2>&1 | FileCheck %s --check-prefix=NO-FP-CAS
# RUN: llvm-mc -triple=xtensa-esp32-none-elf -show-encoding %t/dfpaccel.s | FileCheck %s --check-prefix=DFP

# The triple selects the same instruction set for assembly and disassembly.
# ESP32 has FP, native CAS and the double-precision accelerator registers;
# ESP32-S2 has windowed registers but neither FP nor native CAS.
# WINDOWED: entry a1, 32
# WINDOWED: retw.n
# FP-CAS: add.s f0, f1, f2
# FP-CAS: s32c1i a2, a3, 0
# NO-FP-CAS: error: instruction use requires an option to be enabled
# NO-FP-CAS: add.s f0, f1, f2
# NO-FP-CAS: error: instruction use requires an option to be enabled
# NO-FP-CAS: s32c1i a2, a3, 0
# DFP: rur a3, f64r_lo

#--- windowed.s
entry a1, 32
retw.n

#--- fp-cas.s
add.s f0, f1, f2
s32c1i a2, a3, 0

#--- dfpaccel.s
rur a3, f64r_lo

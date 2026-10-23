; RUN: split-file %s %t
; RUN: llc -mtriple=xtensa-esp32-none-elf -verify-machineinstrs %t/default.ll -o - | FileCheck %s --check-prefix=WINDOWED
; RUN: llc -mtriple=xtensa-esp32s2-none-elf -verify-machineinstrs %t/default.ll -o - | FileCheck %s --check-prefix=WINDOWED
; RUN: llc -mtriple=xtensa-esp32-none-elf -mattr=-windowed,+windowed %t/default.ll -o - | FileCheck %s --check-prefix=WINDOWED
; RUN: llc -mtriple=xtensa-esp32s2-none-elf -mattr=-windowed,+windowed %t/default.ll -o - | FileCheck %s --check-prefix=WINDOWED
; RUN: not llc -mtriple=xtensa-esp32-none-elf -mcpu=esp8266 %t/default.ll -o /dev/null 2>&1 | FileCheck %s --check-prefix=BAD-CPU
; RUN: not llc -mtriple=xtensa-esp32s2-none-elf -mcpu=esp8266 %t/default.ll -o /dev/null 2>&1 | FileCheck %s --check-prefix=BAD-CPU
; RUN: not llc -mtriple=xtensa-esp32-none-elf %t/cpu-attribute.ll -o /dev/null 2>&1 | FileCheck %s --check-prefix=BAD-CPU
; RUN: not llc -mtriple=xtensa-esp32s2-none-elf %t/cpu-attribute.ll -o /dev/null 2>&1 | FileCheck %s --check-prefix=BAD-CPU
; RUN: not llc -mtriple=xtensa-esp32-none-elf -mattr=+windowed,-windowed %t/default.ll -o /dev/null 2>&1 | FileCheck %s --check-prefix=BAD-ABI
; RUN: not llc -mtriple=xtensa-esp32s2-none-elf %t/abi-attribute.ll -o /dev/null 2>&1 | FileCheck %s --check-prefix=BAD-ABI
; RUN: llc -mtriple=xtensa-esp32-none-elf %t/good-attribute.ll -o - | FileCheck %s --check-prefix=WINDOWED
; RUN: llc -mtriple=xtensa-esp32s2-none-elf %t/good-attribute.ll -o - | FileCheck %s --check-prefix=WINDOWED
; RUN: llc -mtriple=xtensa-unknown-none-elf -mcpu=esp8266 %t/default.ll -o - | FileCheck %s --check-prefix=CALL0
; RUN: llc -mtriple=xtensa-esp32-none-elf -verify-machineinstrs %t/float.ll -o - | FileCheck %s --check-prefix=HARD
; RUN: llc -mtriple=xtensa-esp32s2-none-elf -verify-machineinstrs %t/float.ll -o - | FileCheck %s --check-prefix=SOFT --implicit-check-not=add.s

; WINDOWED-LABEL: caller:
; WINDOWED: entry a1,
; WINDOWED: callx8
; WINDOWED: retw
; CALL0-LABEL: caller:
; CALL0-NOT: entry
; CALL0: callx0
; CALL0: ret
; BAD-CPU: error: CPU 'esp8266' is not supported for target 'xtensa-{{esp32|esp32s2}}-none-elf'
; BAD-CPU-NOT: Stack dump
; BAD-ABI: error: ABI 'call0' is not supported for target 'xtensa-{{esp32|esp32s2}}-none-elf'
; BAD-ABI-NOT: Stack dump
; HARD-LABEL: float_add:
; HARD: add.s
; HARD: retw
; SOFT: .literal [[ADD:.LCPI[0-9]+_[0-9]+]], __addsf3
; SOFT-LABEL: float_add:
; SOFT: entry a1,
; SOFT: l32r {{a[0-9]+}}, [[ADD]]
; SOFT: callx8
; SOFT: retw

;--- default.ll
declare i32 @other(i32)
define i32 @caller(i32 %x) {
  %r = call i32 @other(i32 %x)
  %s = add i32 %r, 1
  ret i32 %s
}

;--- cpu-attribute.ll
define i32 @wrong_cpu(i32 %x) "target-cpu"="esp8266" {
  ret i32 %x
}

;--- abi-attribute.ll
define i32 @wrong_abi(i32 %x) "target-features"="+windowed,-windowed" {
  ret i32 %x
}

;--- float.ll
define float @float_add(float %a, float %b) {
  %r = fadd float %a, %b
  ret float %r
}

;--- good-attribute.ll
declare i32 @other(i32)
define i32 @caller(i32 %x) "target-features"="-s32c1i,-windowed,+windowed" {
  %r = call i32 @other(i32 %x)
  %s = add i32 %r, 1
  ret i32 %s
}

; RUN: split-file %s %t
; RUN: llc %t/default.ll -o - | FileCheck %s --check-prefix=WINDOWED
; RUN: llc -mattr=-s32c1i %t/default.ll -o - | FileCheck %s --check-prefix=WINDOWED
; RUN: llc -mattr=-windowed,+windowed %t/default.ll -o - | FileCheck %s --check-prefix=WINDOWED
; RUN: not llc -mcpu=esp8266 %t/default.ll -o %t.bad-cpu.s 2>&1 | FileCheck %s --check-prefix=BAD-CPU
; RUN: not test -e %t.bad-cpu.s
; RUN: not llc -mattr=+windowed,-windowed %t/default.ll -o %t.bad-abi.o -filetype=obj 2>&1 | FileCheck %s --check-prefix=BAD-ABI
; RUN: not test -e %t.bad-abi.o
; RUN: not llc %t/cpu-attribute.ll -o /dev/null 2>&1 | FileCheck %s --check-prefix=BAD-CPU
; RUN: not llc %t/abi-attribute.ll -o /dev/null 2>&1 | FileCheck %s --check-prefix=BAD-ABI
; RUN: llc %t/good-attribute.ll -o - | FileCheck %s --check-prefix=WINDOWED
; RUN: llc -mtriple=xtensa-unknown-none-elf -mcpu=esp8266 %t/default.ll -o - | FileCheck %s --check-prefix=CALL0

; The fixed S3 target contract also applies to raw LLVM IR, including each
; function's effective CPU and features. Report errors without a fatal backend
; crash and discard output; generic Xtensa configurations retain their ABI.
; WINDOWED-LABEL: caller:
; WINDOWED: entry a1,
; WINDOWED: callx8
; WINDOWED: retw
; CALL0-LABEL: caller:
; CALL0-NOT: entry
; CALL0: callx0
; CALL0: ret
; BAD-CPU: error: CPU 'esp8266' is not supported for target 'xtensa-esp32s3-none-elf'
; BAD-CPU-NOT: Stack dump
; BAD-ABI: error: ABI 'call0' is not supported for target 'xtensa-esp32s3-none-elf'
; BAD-ABI-NOT: Stack dump

;--- default.ll
target triple = "xtensa-esp32s3-none-elf"
declare i32 @other(i32)
define i32 @caller(i32 %x) {
  %r = call i32 @other(i32 %x)
  %s = add i32 %r, 1
  ret i32 %s
}

;--- cpu-attribute.ll
target triple = "xtensa-esp32s3-none-elf"
define i32 @wrong_cpu(i32 %x) "target-cpu"="esp8266" {
  ret i32 %x
}

;--- abi-attribute.ll
target triple = "xtensa-esp32s3-none-elf"
define i32 @wrong_abi(i32 %x) "target-cpu"="esp32s3" "target-features"="+windowed,-windowed" {
  ret i32 %x
}

;--- good-attribute.ll
target triple = "xtensa-esp32s3-none-elf"
declare i32 @other(i32)
define i32 @caller(i32 %x) "target-cpu"="esp32s3" "target-features"="-s32c1i,-windowed,+windowed" {
  %r = call i32 @other(i32 %x)
  %s = add i32 %r, 1
  ret i32 %s
}

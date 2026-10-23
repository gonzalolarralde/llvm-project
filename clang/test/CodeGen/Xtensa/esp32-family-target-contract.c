// RUN: %clang --target=xtensa-esp32-none-elf -S -emit-llvm %s -o - | FileCheck %s --check-prefix=ESP32
// RUN: %clang --target=xtensa-esp32s2-none-elf -S -emit-llvm %s -o - | FileCheck %s --check-prefix=S2
// RUN: %clang_cc1 -triple xtensa-esp32-none-elf -target-feature -windowed -target-feature +windowed -emit-llvm %s -o - | FileCheck %s --check-prefix=ESP32
// RUN: %clang_cc1 -triple xtensa-esp32s2-none-elf -target-feature -windowed -target-feature +windowed -emit-llvm %s -o - | FileCheck %s --check-prefix=S2
// RUN: not %clang --target=xtensa-esp32-none-elf -mcpu=esp32s3 -fsyntax-only %s 2>&1 | FileCheck %s --check-prefix=BAD-ESP32-CPU
// RUN: not %clang_cc1 -triple xtensa-esp32s2-none-elf -target-cpu esp32 -fsyntax-only %s 2>&1 | FileCheck %s --check-prefix=BAD-S2-CPU
// RUN: not %clang_cc1 -triple xtensa-esp32-none-elf -target-feature +windowed -target-feature -windowed -fsyntax-only %s 2>&1 | FileCheck %s --check-prefix=BAD-ESP32-ABI
// RUN: not %clang_cc1 -triple xtensa-esp32s2-none-elf -target-feature +windowed -target-feature -windowed -fsyntax-only %s 2>&1 | FileCheck %s --check-prefix=BAD-S2-ABI
// RUN: not %clang_cc1 -triple xtensa-esp32-none-elf -DBAD_CPU -emit-llvm %s -o /dev/null 2>&1 | FileCheck %s --check-prefix=BAD-ESP32-CPU
// RUN: not %clang_cc1 -triple xtensa-esp32s2-none-elf -DBAD_CPU -emit-llvm %s -o /dev/null 2>&1 | FileCheck %s --check-prefix=BAD-S2-ATTR
// RUN: not %clang_cc1 -triple xtensa-esp32-none-elf -DBAD_ABI -emit-llvm %s -o /dev/null 2>&1 | FileCheck %s --check-prefix=BAD-ESP32-ABI
// RUN: not %clang_cc1 -triple xtensa-esp32s2-none-elf -DBAD_ABI -emit-llvm %s -o /dev/null 2>&1 | FileCheck %s --check-prefix=BAD-S2-ABI
// REQUIRES: xtensa-registered-target

#if !defined(__XTENSA_WINDOWED_ABI__) || defined(__XTENSA_CALL0_ABI__)
#error incorrect chip windowed ABI
#endif
_Static_assert(sizeof(void *) == 4, "32-bit pointers");
_Static_assert(_Alignof(double) == 8, "64-bit double alignment");
int identity(int x) { return x; }
__attribute__((target("no-windowed,windowed"))) int windowed(int x) { return x; }
#ifdef BAD_CPU
__attribute__((target("arch=esp32s3"))) int wrong_cpu(int x) { return x; }
#endif
#ifdef BAD_ABI
__attribute__((target("windowed,no-windowed"))) int wrong_abi(int x) { return x; }
#endif

// ESP32: target triple = "xtensa-esp32-none-elf"
// ESP32: "target-cpu"="esp32"
// ESP32-SAME: "target-features"="{{[^"]*}}+windowed
// S2: target triple = "xtensa-esp32s2-none-elf"
// S2: "target-cpu"="esp32s2"
// S2-SAME: "target-features"="{{[^"]*}}+windowed
// BAD-ESP32-CPU: error: CPU 'esp32s3' is not supported for target 'xtensa-esp32-none-elf'
// BAD-S2-CPU: error: CPU 'esp32' is not supported for target 'xtensa-esp32s2-none-elf'
// BAD-S2-ATTR: error: CPU 'esp32s3' is not supported for target 'xtensa-esp32s2-none-elf'
// BAD-ESP32-ABI: error: ABI 'call0' is not supported for 'xtensa-esp32-none-elf'
// BAD-S2-ABI: error: ABI 'call0' is not supported for 'xtensa-esp32s2-none-elf'

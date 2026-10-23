// RUN: %clang --target=xtensa-esp32s3-none-elf -S -emit-llvm %s -o - | FileCheck %s --check-prefix=S3
// RUN: %clang_cc1 -triple xtensa-esp32s3-none-elf -target-feature +windowed -emit-llvm %s -o - | FileCheck %s --check-prefix=WINDOWED
// RUN: %clang_cc1 -triple xtensa-esp32s3-none-elf -target-feature -windowed -target-feature +windowed -emit-llvm %s -o - | FileCheck %s --check-prefix=WINDOWED
// RUN: %clang_cc1 -triple xtensa-esp32s3-none-elf -target-cpu esp32s3 -target-feature -s32c1i -emit-llvm %s -o - | FileCheck %s --check-prefixes=S3,NO-CAS
// RUN: %clang_cc1 -triple xtensa-esp32s3-none-elf -target-feature -s32c1i -DEXPECT_NO_CAS -fsyntax-only %s
// RUN: not %clang --target=xtensa-esp32s3-none-elf -mcpu=esp8266 -fsyntax-only %s 2>&1 | FileCheck %s --check-prefix=BAD-CPU
// RUN: not %clang_cc1 -triple xtensa-esp32s3-none-elf -target-cpu esp8266 -fsyntax-only %s 2>&1 | FileCheck %s --check-prefix=BAD-CPU
// RUN: not %clang --target=xtensa-esp32s3-none-elf -Xclang -target-feature -Xclang -windowed -fsyntax-only %s 2>&1 | FileCheck %s --check-prefix=BAD-ABI
// RUN: not %clang_cc1 -triple xtensa-esp32s3-none-elf -target-feature +windowed -target-feature -windowed -fsyntax-only %s 2>&1 | FileCheck %s --check-prefix=BAD-ABI
// RUN: %clang --target=xtensa-unknown-none-elf -mcpu=esp8266 -DEXPECT_CALL0 -S -emit-llvm %s -o - | FileCheck %s --check-prefix=GENERIC
// REQUIRES: xtensa-registered-target

// Instruction selection overrides must not accidentally change the ABI, and
// their preprocessor view must agree with the generated IR.
#if defined(EXPECT_CALL0)
#if !defined(__XTENSA_CALL0_ABI__) || defined(__XTENSA_WINDOWED_ABI__)
#error incorrect CALL0 target macros
#endif
#else
#if !defined(__XTENSA_WINDOWED_ABI__) || defined(__XTENSA_CALL0_ABI__)
#error incorrect S3 windowed target macros
#endif
#endif
#if defined(EXPECT_NO_CAS) && __XCHAL_HAVE_S32C1I != 0
#error s32c1i override was not applied
#endif

_Static_assert(sizeof(void *) == 4, "32-bit pointers");
_Static_assert(_Alignof(double) == 8, "64-bit double alignment");

int identity(int x) { return x; }

// S3: target datalayout = "e-m:e-p:32:32-i8:8:32-i16:16:32-i64:64-n32"
// S3: target triple = "xtensa-esp32s3-none-elf"
// S3: "target-cpu"="esp32s3"
// S3-SAME: "target-features"="{{[^"]*}}+windowed
// NO-CAS-SAME: ,-s32c1i"
// WINDOWED: "target-features"="{{[^"]*}}+windowed"
// BAD-CPU: error: CPU 'esp8266' is not supported for target 'xtensa-esp32s3-none-elf'
// BAD-ABI: error: ABI 'call0' is not supported for 'xtensa-esp32s3-none-elf'
// GENERIC: "target-cpu"="esp8266"


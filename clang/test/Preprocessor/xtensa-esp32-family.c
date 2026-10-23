// RUN: %clang -target xtensa-esp32-none-elf -dM -E %s | FileCheck %s --check-prefixes=COMMON,HARD
// RUN: %clang -target xtensa-esp32s2-none-elf -dM -E %s | FileCheck %s --check-prefixes=COMMON,SOFT
// RUN: %clang_cc1 -triple xtensa-esp32-none-elf -dM -E %s | FileCheck %s --check-prefixes=COMMON,HARD
// RUN: %clang_cc1 -triple xtensa-esp32s2-none-elf -dM -E %s | FileCheck %s --check-prefixes=COMMON,SOFT
// REQUIRES: xtensa-registered-target

// COMMON: #define __ELF__ 1
// COMMON: #define __SIZEOF_POINTER__ 4
// HARD: #define __XCHAL_HAVE_FP 1
// HARD: #define __XCHAL_HAVE_LOOPS 1
// HARD: #define __XCHAL_HAVE_S32C1I 1
// SOFT: #define __XCHAL_HAVE_FP 0
// SOFT: #define __XCHAL_HAVE_LOOPS 0
// SOFT: #define __XCHAL_HAVE_S32C1I 0
// COMMON: #define __XCHAL_HAVE_WINDOWED 1
// COMMON: #define __XTENSA_EL__ 1
// SOFT: #define __XTENSA_SOFT_FLOAT__ 1
// COMMON: #define __XTENSA_WINDOWED_ABI__ 1

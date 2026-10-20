// RUN: %clang -target xtensa-esp32s3-none-elf -dM -E %s | FileCheck %s
// RUN: %clang_cc1 -triple xtensa-none-elf -target-cpu esp32s3 -dM -E %s | FileCheck %s
// RUN: %clang -target xtensa-esp32s3-none-elf -### -c %s 2>&1 | FileCheck %s --check-prefix=DRIVER
// REQUIRES: xtensa-registered-target

// DRIVER: "-target-cpu" "esp32s3"
// CHECK: #define __ELF__ 1
// CHECK: #define __SIZEOF_POINTER__ 4
// CHECK: #define __XCHAL_HAVE_FP 1
// CHECK: #define __XCHAL_HAVE_LOOPS 1
// CHECK: #define __XCHAL_HAVE_S32C1I 1
// CHECK: #define __XCHAL_HAVE_WINDOWED 1
// CHECK: #define __XTENSA_EL__ 1
// CHECK: #define __XTENSA_WINDOWED_ABI__ 1

// RUN: %clang -target xtensa-esp32s3-none-elf -c %s -o %t.o 2>&1 | FileCheck %s --check-prefix=NO-WARN --allow-empty
// NO-WARN-NOT: not a recognized feature
void s3_function(void) {}

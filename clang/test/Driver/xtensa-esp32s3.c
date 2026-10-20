// RUN: %clang -### --target=xtensa-esp32s3-none-elf --sysroot=%S/Inputs/baremetal_arm -c %s 2>&1 | FileCheck %s
// CHECK: "-triple" "xtensa-esp32s3-none-elf"
// CHECK-SAME: "-nostdsysteminc"
// CHECK-SAME: "-target-cpu" "esp32s3"
// CHECK-SAME: "-isysroot" "[[SYSROOT:[^"]*]]"
// CHECK-SAME: "-internal-isystem" "[[SYSROOT]]{{[/\\]+}}include"
// CHECK-NOT: /usr/include
// CHECK-NOT: /usr/local/include
int value;

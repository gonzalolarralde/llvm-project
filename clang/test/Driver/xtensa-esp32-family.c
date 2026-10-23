// RUN: %clang -### --target=xtensa-esp32-none-elf -c %s 2>&1 | FileCheck %s --check-prefix=ESP32
// RUN: %clang -### --target=xtensa-esp32s2-none-elf -c %s 2>&1 | FileCheck %s --check-prefix=S2
// RUN: %clang -### --target=xtensa-esp32s3-none-elf -c %s 2>&1 | FileCheck %s --check-prefix=S3
// RUN: %clang -### --target=xtensa-esp32-none-elf -mcpu=esp8266 -mcpu=esp32 -c %s 2>&1 | FileCheck %s --check-prefix=ESP32
// REQUIRES: xtensa-registered-target

// ESP32: "-triple" "xtensa-esp32-none-elf"
// ESP32-SAME: "-target-cpu" "esp32"
// S2: "-triple" "xtensa-esp32s2-none-elf"
// S2-SAME: "-target-cpu" "esp32s2"
// S3: "-triple" "xtensa-esp32s3-none-elf"
// S3-SAME: "-target-cpu" "esp32s3"

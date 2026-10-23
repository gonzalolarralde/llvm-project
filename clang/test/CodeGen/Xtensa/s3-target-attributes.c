// RUN: %clang_cc1 -triple xtensa-esp32s3-none-elf -target-cpu esp32s3 -emit-llvm %s -o - | FileCheck %s
// RUN: not %clang_cc1 -triple xtensa-esp32s3-none-elf -target-cpu esp32s3 -DBAD_CPU -emit-llvm %s -o /dev/null 2>&1 | FileCheck %s --check-prefix=BAD-CPU
// RUN: not %clang_cc1 -triple xtensa-esp32s3-none-elf -target-cpu esp32s3 -DBAD_ABI -emit-llvm %s -o /dev/null 2>&1 | FileCheck %s --check-prefix=BAD-ABI
// REQUIRES: xtensa-registered-target

// Per-function target attributes must obey the same S3 contract as the command
// line. Disabling a memory-region-dependent instruction is still valid.
__attribute__((target("no-s32c1i"))) int no_cas(int x) { return x + 1; }
__attribute__((target("no-windowed,windowed"))) int windowed(int x) { return x + 1; }

#ifdef BAD_CPU
__attribute__((target("arch=esp32"))) int wrong_cpu(int x) { return x + 1; }
#endif
#ifdef BAD_ABI
__attribute__((target("windowed,no-windowed"))) int wrong_abi(int x) { return x + 1; }
#endif

// CHECK: define {{.*}} @no_cas({{.*}}) #[[NO_CAS:[0-9]+]]
// CHECK: define {{.*}} @windowed({{.*}}) #[[WINDOWED:[0-9]+]]
// CHECK: attributes #[[NO_CAS]] = {{.*}}"target-cpu"="esp32s3" "target-features"="{{[^"]*}}+windowed,-s32c1i"
// CHECK: attributes #[[WINDOWED]] = {{.*}}"target-cpu"="esp32s3" "target-features"="{{[^"]*}}+windowed"
// BAD-CPU: error: CPU 'esp32' is not supported for target 'xtensa-esp32s3-none-elf'
// BAD-ABI: error: ABI 'call0' is not supported for 'xtensa-esp32s3-none-elf'


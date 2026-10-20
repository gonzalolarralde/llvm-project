// RUN: %clang_cc1 -triple xtensa-esp32s3-none-elf -emit-llvm -o - %s | FileCheck %s
// RUN: %clang_cc1 -triple xtensa-esp32s3-none-elf -mrelocation-model static -O2 -emit-obj -o /dev/null %s

// References must retain pointer types for the nonnull and dereferenceable
// attributes emitted by Clang, including reference return values.
extern "C" {
// CHECK-LABEL: define {{.*}}void @increment(ptr {{.*}}nonnull align 4 dereferenceable(4)
void increment(int &value) { ++value; }
// CHECK-LABEL: define {{.*}}void @consume(ptr {{.*}}nonnull align 4 dereferenceable(4)
void consume(int &&value) { ++value; }
// CHECK-LABEL: define {{.*}}nonnull align 4 dereferenceable(4) ptr @identity(ptr
int &identity(int &value) { return value; }
// CHECK-LABEL: define {{.*}}void @sixth(i32 {{.*}}, i32 {{.*}}, i32 {{.*}}, i32 {{.*}}, i32 {{.*}}, ptr {{.*}}nonnull
void sixth(int, int, int, int, int, int &value) { ++value; }
// CHECK-LABEL: define {{.*}}void @seventh(
void seventh(int, int, int, int, int, int, int &value) { ++value; }
}

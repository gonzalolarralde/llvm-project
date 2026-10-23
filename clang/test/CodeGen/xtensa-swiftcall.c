// RUN: %clang_cc1 -triple xtensa-esp32s3-none-elf -target-cpu esp32s3 -mrelocation-model static -Werror -emit-llvm -o - %s | FileCheck %s
// RUN: %clang_cc1 -triple xtensa-esp32s3-none-elf -target-cpu esp32s3 -mrelocation-model static -Werror -emit-obj -o %t %s

typedef struct { void *identity; unsigned implementation; } Executor;
__attribute__((swiftcall)) Executor get_executor(void);
__attribute__((swiftcall)) void resume(void * __attribute__((swift_async_context)) context);
__attribute__((swiftcall)) void invoke(void * __attribute__((swift_context)) context) {
  resume(context);
}
// CHECK: define {{.*}}swiftcc void @invoke(ptr {{.*}}swiftself
// CHECK: call swiftcc void @resume(ptr {{.*}}swiftasync

Executor fetch(void) { return get_executor(); }
// CHECK: call swiftcc { ptr, i32 } @get_executor()

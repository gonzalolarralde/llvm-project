// REQUIRES: xtensa-registered-target
// RUN: %clang_cc1 -triple xtensa-esp32s3-none-elf -target-cpu esp32s3 -O0 -emit-llvm %s -o - | FileCheck %s

typedef __attribute__((ext_vector_type(1))) _Bool xtbool;

#define	__malloc_like	__attribute__((__malloc__))
char *bufalloc () __malloc_like ;//__result_use_check;
extern void* malloc (unsigned size);

char *bufalloc ()
{
  char* buf = malloc(1024);

  return buf;
}

// CHECK: define dso_local noalias ptr @bufalloc() #0 {

// Keep pointer arguments as pointers in IR, including allocation/runtime hooks
// whose callers construct the C signature directly.
void *pointer_identity(void *value) { return value; }
// CHECK: define dso_local ptr @pointer_identity(ptr noundef %value)

struct S16 { int a[4]; } __attribute__ ((aligned (16)));

void callee_struct_a16b_1(struct S16 a) {}

// CHECK: define dso_local void @callee_struct_a16b_1(i128 %a.coerce)

void callee_struct_a16b_2(struct S16 a, int b) {}

// CHECK: define dso_local void @callee_struct_a16b_2(i128 %a.coerce, i32 noundef %b)

void callee_struct_a16b_3(int a, struct S16 b) {}

// CHECK: define dso_local void @callee_struct_a16b_3(i32 noundef %a, ptr noundef byval(%struct.S16) align 16 %b)

xtbool test_xtbool(xtbool a) { return a; }

// CHECK: define dso_local <1 x i1> @test_xtbool(<1 x i1> noundef %a)

struct S20 { unsigned words[5]; };
// The result pointer consumes one argument register, the prefix consumes a
// second, and the complete five-word aggregate must therefore go on the stack.
// CHECK: define dso_local void @large_prefixed(ptr {{.*}}sret(%struct.S20){{.*}}, i32 noundef %prefix, ptr noundef byval(%struct.S20) align 4 %value)
struct S20 large_prefixed(unsigned prefix, struct S20 value) {
  value.words[0] += prefix;
  return value;
}

struct S4 { unsigned word; };
// CHECK: define dso_local i32 @small_result(i32 %value.coerce)
struct S4 small_result(struct S4 value) { return value; }

// Result registers start a new register area: an aligned 16-byte result does
// not inherit the argument rule that requires six initially free registers.
// CHECK: define dso_local i128 @aligned_result(i128 %value.coerce)
struct S16 aligned_result(struct S16 value) { return value; }

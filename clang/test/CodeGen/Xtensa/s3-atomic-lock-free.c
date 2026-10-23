// RUN: %clang_cc1 -triple xtensa-esp32s3-none-elf -fsyntax-only %s
// RUN: %clang_cc1 -triple xtensa-esp32s3-none-elf -target-feature -s32c1i -DNO_CAS -fsyntax-only %s
// RUN: %clang_cc1 -triple xtensa-esp32-none-elf -fsyntax-only %s
// RUN: %clang_cc1 -triple xtensa-esp32s2-none-elf -DNO_CAS -fsyntax-only %s
// REQUIRES: xtensa-registered-target

// Disabling native CAS must also remove the frontend's compile-time guarantee
// of lock freedom. Runtime helpers may still use native CAS for internal RAM.
#ifdef NO_CAS
#define EXPECT_NATIVE 0
_Static_assert(__CLANG_ATOMIC_CHAR_LOCK_FREE != 2, "char helper path");
_Static_assert(__CLANG_ATOMIC_SHORT_LOCK_FREE != 2, "short helper path");
_Static_assert(__CLANG_ATOMIC_INT_LOCK_FREE != 2, "int helper path");
_Static_assert(__CLANG_ATOMIC_POINTER_LOCK_FREE != 2, "pointer helper path");
#else
#define EXPECT_NATIVE 1
_Static_assert(__CLANG_ATOMIC_CHAR_LOCK_FREE == 2, "native char atomics");
_Static_assert(__CLANG_ATOMIC_SHORT_LOCK_FREE == 2, "native short atomics");
_Static_assert(__CLANG_ATOMIC_INT_LOCK_FREE == 2, "native int atomics");
_Static_assert(__CLANG_ATOMIC_POINTER_LOCK_FREE == 2, "native pointer atomics");
#endif

_Static_assert(__atomic_always_lock_free(1, 0) == EXPECT_NATIVE, "8-bit guarantee");
_Static_assert(__atomic_always_lock_free(2, 0) == EXPECT_NATIVE, "16-bit guarantee");
_Static_assert(__atomic_always_lock_free(4, 0) == EXPECT_NATIVE, "32-bit guarantee");
_Static_assert(!__atomic_always_lock_free(8, 0), "64-bit helper required");
_Static_assert(__CLANG_ATOMIC_LLONG_LOCK_FREE != 2, "no 64-bit guarantee");

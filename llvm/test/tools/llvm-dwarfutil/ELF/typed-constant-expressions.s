# REQUIRES: aarch64-registered-target
# Both typed-constant encodings carry a CU-relative DIE reference and an opaque
# block. Reference growth must update entry-value lengths and bra/skip offsets,
# including patches nested more than one level deep. The second CU makes an
# accidental section-relative type reference observable.
# RUN: llvm-mc -triple=aarch64 -filetype=obj %s -o %t.o
# RUN: llvm-objcopy --change-section-address=.text=0x1000 %t.o %t.elf
# RUN: llvm-dwarfdump --verify %t.elf
# RUN: llvm-dwarfutil --no-odr --linker=classic --tombstone=bfd --verify %t.elf %t.classic
# RUN: llvm-dwarfdump --debug-info %t.classic | FileCheck %s
# RUN: llvm-dwarfutil --no-odr --linker=parallel --tombstone=bfd --verify %t.elf %t.parallel
# RUN: llvm-dwarfdump --debug-info %t.parallel | FileCheck %s
# RUN: llvm-mc -triple=aarch64 -filetype=obj --defsym=BAD_REF=1 %s -o %t.zero.o
# RUN: llvm-objcopy --change-section-address=.text=0x1000 %t.zero.o %t.zero
# RUN: not llvm-dwarfdump --verify %t.zero 2>&1 | FileCheck %s --check-prefix=BAD-TYPE
# RUN: not llvm-dwarfutil --no-odr --linker=classic --tombstone=bfd %t.zero %t.zero.classic 2>&1 | FileCheck %s --check-prefix=BAD-REF
# RUN: not llvm-dwarfutil --no-odr --linker=parallel --tombstone=bfd %t.zero %t.zero.parallel 2>&1 | FileCheck %s --check-prefix=BAD-REF
# RUN: llvm-mc -triple=aarch64 -filetype=obj --defsym=NON_BASE=1 %s -o %t.nonbase.o
# RUN: llvm-objcopy --change-section-address=.text=0x1000 %t.nonbase.o %t.nonbase
# RUN: not llvm-dwarfdump --verify %t.nonbase 2>&1 | FileCheck %s --check-prefix=BAD-TYPE
# RUN: not llvm-dwarfutil --no-odr --linker=parallel --tombstone=bfd %t.nonbase %t.nonbase.parallel 2>&1 | FileCheck %s --check-prefix=BAD-REF
# RUN: llvm-mc -triple=aarch64 -filetype=obj --defsym=TRUNCATED=1 %s -o %t.short.o
# RUN: llvm-objcopy --change-section-address=.text=0x1000 %t.short.o %t.short
# RUN: not llvm-dwarfdump --verify %t.short 2>&1 | FileCheck %s --check-prefix=TRUNCATED
# RUN: not llvm-dwarfutil --no-odr --linker=parallel --tombstone=bfd %t.short %t.short.parallel 2>&1 | FileCheck %s --check-prefix=BAD-REF
# RUN: llvm-mc -triple=aarch64 -filetype=obj --defsym=BAD_BRANCH=1 %s -o %t.branch.o
# RUN: llvm-objcopy --change-section-address=.text=0x1000 %t.branch.o %t.branch
# RUN: not llvm-dwarfutil --no-odr --linker=parallel --tombstone=bfd %t.branch %t.branch.parallel 2>&1 | FileCheck %s --check-prefix=BAD-BRANCH
# RUN: not llvm-dwarfutil --no-odr --linker=classic --tombstone=bfd %t.nonbase %t.nonbase.classic 2>&1 | FileCheck %s --check-prefix=BAD-REF
# RUN: not llvm-dwarfutil --no-odr --linker=classic --tombstone=bfd %t.short %t.short.classic 2>&1 | FileCheck %s --check-prefix=BAD-REF
# RUN: not llvm-dwarfutil --no-odr --linker=classic --tombstone=bfd %t.branch %t.branch.classic 2>&1 | FileCheck %s --check-prefix=BAD-BRANCH
# RUN: llvm-mc -triple=aarch64 -filetype=obj --defsym=OUT_OF_RANGE=1 %s -o %t.range.o
# RUN: llvm-objcopy --change-section-address=.text=0x1000 %t.range.o %t.range
# RUN: not llvm-dwarfdump --verify %t.range 2>&1 | FileCheck %s --check-prefix=BAD-TYPE
# RUN: not llvm-dwarfutil --no-odr --linker=classic --tombstone=bfd %t.range %t.range.classic 2>&1 | FileCheck %s --check-prefix=BAD-REF
# RUN: not llvm-dwarfutil --no-odr --linker=parallel --tombstone=bfd %t.range %t.range.parallel 2>&1 | FileCheck %s --check-prefix=BAD-REF
# RUN: llvm-mc -triple=aarch64 -filetype=obj --defsym=NEGATIVE_BRANCH=1 %s -o %t.negative.o
# RUN: llvm-objcopy --change-section-address=.text=0x1000 %t.negative.o %t.negative
# RUN: not llvm-dwarfutil --no-odr --linker=classic --tombstone=bfd %t.negative %t.negative.classic 2>&1 | FileCheck %s --check-prefix=BAD-BRANCH
# RUN: not llvm-dwarfutil --no-odr --linker=parallel --tombstone=bfd %t.negative %t.negative.parallel 2>&1 | FileCheck %s --check-prefix=BAD-BRANCH
# BAD-TYPE: error: DIE contains invalid DWARF expression:
# BAD-REF: could not preserve DWARF expression references
# BAD-REF-NOT: Assertion
# TRUNCATED: error: DIE contains invalid DWARF expression:
# BAD-BRANCH: expression branch does not target an operation boundary
# BAD-BRANCH: could not preserve DWARF expression references
# CHECK: DW_AT_name{{.*}}"typed_constants"
# CHECK: DW_AT_name{{.*}}"standard"
# CHECK: DW_AT_location{{.*}}DW_OP_const_type (0x[[TYPE:[0-9a-f]+]]) "unsigned long" 0x8 0xc5 0xb3 0xa2 0x91 0x00 0x00 0x00 0x00, DW_OP_stack_value
# CHECK: DW_AT_name{{.*}}"gnu"
# CHECK: DW_AT_location{{.*}}DW_OP_GNU_const_type (0x[[TYPE]]) "unsigned long" 0x8 0xf4 0xa4 0xff 0x80 0x00 0x00 0x00 0x00, DW_OP_stack_value
# CHECK: DW_AT_name{{.*}}"nested"
# CHECK: DW_AT_location{{.*}}DW_OP_lit0, DW_OP_bra +22, DW_OP_GNU_entry_value(DW_OP_entry_value(DW_OP_GNU_const_type (0x[[TYPE]]) "unsigned long" 0x8 0xc5 0xb3 0xa2 0x91 0x00 0x00 0x00 0x00)), DW_OP_skip -22, DW_OP_stack_value
# CHECK: DW_AT_name{{.*}}"generic"
# CHECK: DW_AT_location{{.*}}DW_OP_lit1, DW_OP_GNU_convert 0x0, DW_OP_stack_value
# CHECK: 0x{{0*}}[[TYPE]]:{{.*}}DW_TAG_base_type
# CHECK: DW_AT_name{{.*}}"unsigned long"

.text
.space 16
.section .debug_abbrev,"",@progbits
.byte 1, 0x11, 1 // CU, addresses
.byte 3, 8, 0x11, 1, 0x12, 6, 0, 0
.byte 2, 0x2e, 1 // subprogram
.byte 3, 8, 0x11, 1, 0x12, 6, 0, 0
.byte 3, 0x34, 0 // variable, exprloc
.byte 3, 8, 2, 0x18, 0, 0
.byte 4, 0x24, 0 // base type
.byte 3, 8, 0x3e, 0x0b, 0x0b, 0x0b, 0, 0
.byte 0

.section .debug_info,"",@progbits
.Lfirst:
.long .Lfirstend-.Lfirstheader
.Lfirstheader:
.short 5
.byte 1, 8
.long 0
.byte 1
.asciz "first_cu"
.quad 0x1000
.long 16
.byte 2
.asciz "first_function"
.quad 0x1000
.long 16
.byte 0, 0
.Lfirstend:

.Lcu:
.long .Lcuend-.Lheader
.Lheader:
.short 5
.byte 1, 8
.long 0
.byte 1
.asciz "second_cu"
.quad 0x1000
.long 16
.Lfunction:
.byte 2
.asciz "typed_constants"
.quad 0x1000
.long 16
.byte 3
.asciz "standard"
.uleb128 .Lstandardend-.Lstandard
.Lstandard:
.byte 0xa4
.ifdef BAD_REF
.uleb128 0
.else
.ifdef NON_BASE
.uleb128 .Lfunction-.Lcu
.else
.ifdef OUT_OF_RANGE
.uleb128 0xffffffffffffffff
.else
.uleb128 .Ltype-.Lcu
.endif
.endif
.endif
.ifdef TRUNCATED
.byte 10
.else
.byte 8
.endif
.byte 0xc5, 0xb3, 0xa2, 0x91, 0, 0, 0, 0
.byte 0x9f
.Lstandardend:
.byte 3
.asciz "gnu"
.uleb128 .Lgnuend-.Lgnu
.Lgnu:
.byte 0xf4
.uleb128 .Ltype-.Lcu
.byte 8, 0xf4, 0xa4, 0xff, 0x80, 0, 0, 0, 0, 0x9f
.Lgnuend:
.byte 3
.asciz "nested"
.uleb128 .Lexprend-.Lexpr
.Lexpr:
.byte 0x30, 0x28 // lit0, bra
.ifdef BAD_BRANCH
.short 1 // Not an outer operation boundary.
.else
.ifdef NEGATIVE_BRANCH
.short -5 // Target -1: must not be used as a DenseMap sentinel.
.else
.short .Lstack-.Lbranchend
.endif
.endif
.Lbranchend:
.byte 0xf3 // GNU_entry_value
.uleb128 .Lnestedend-.Lnested
.Lnested:
.byte 0xa3 // entry_value
.uleb128 .Linnerend-.Linner
.Linner:
.byte 0xf4
.uleb128 .Ltype-.Lcu
.byte 8, 0xc5, 0xb3, 0xa2, 0x91, 0, 0, 0, 0
.Linnerend:
.Lnestedend:
.byte 0x2f // skip back to the outer entry_value
.short .Lbranchend-.Lskipend
.Lskipend:
.Lstack:
.byte 0x9f
.Lexprend:
.byte 3
.asciz "generic"
.byte 4, 0x31, 0xf7, 0, 0x9f
.byte 0
.Ltype:
.byte 4
.asciz "unsigned long"
.byte 7, 8
.byte 0
.Lcuend:

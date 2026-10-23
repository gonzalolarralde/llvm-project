# Expression references must keep their targets and follow the new DIE offsets,
# including forward and cross-CU references. Growing a typed operation must also
# update nested entry-value lengths and branch displacements.
# RUN: llvm-mc -triple=x86_64 -filetype=obj %s -o %t.o
# RUN: llvm-objcopy --change-section-address=.text=0x1000 %t.o %t.elf
# RUN: llvm-dwarfutil --no-odr --tombstone=bfd --verify %t.elf %t.out
# RUN: llvm-dwarfdump --debug-info %t.out | FileCheck %s
# RUN: llvm-mc -triple=x86_64 -filetype=obj --defsym=VERSION=5 %s -o %t.5.o
# RUN: llvm-objcopy --change-section-address=.text=0x1000 %t.5.o %t.5.elf
# RUN: llvm-dwarfutil --no-odr --tombstone=bfd --verify %t.5.elf %t.5.out
# RUN: llvm-dwarfdump --debug-info %t.5.out | FileCheck %s
# RUN: llvm-mc -triple=x86_64 -filetype=obj --defsym=BAD_REF=1 %s -o %t.bad.o
# RUN: llvm-objcopy --change-section-address=.text=0x1000 %t.bad.o %t.bad.elf
# RUN: not llvm-dwarfutil --no-odr %t.bad.elf %t.bad.out 2>&1 | FileCheck %s --check-prefix=BAD-REF
# RUN: llvm-mc -triple=x86_64 -filetype=obj --defsym=BAD_BRANCH=1 %s -o %t.branch.o
# RUN: llvm-objcopy --change-section-address=.text=0x1000 %t.branch.o %t.branch.elf
# RUN: not llvm-dwarfutil --no-odr %t.branch.elf %t.branch.out 2>&1 | FileCheck %s --check-prefix=BAD-BRANCH
# BAD-REF: expression reference does not point to a retained DIE
# BAD-REF: could not preserve DWARF expression references
# BAD-REF-NOT: Assertion
# BAD-BRANCH: expression branch does not target an operation boundary
# BAD-BRANCH: could not preserve DWARF expression references
# BAD-BRANCH-NOT: Assertion
# CHECK: DW_AT_name{{.*}}"function"
# CHECK: DW_AT_name{{.*}}"nested"
# CHECK: DW_AT_location{{.*}}DW_OP_lit0, DW_OP_bra +10, DW_OP_GNU_entry_value(DW_OP_GNU_regval_type 0x80 {{.*}}"unsigned int"), DW_OP_stack_value
# CHECK: DW_AT_name{{.*}}"parameter_value"
# CHECK: DW_AT_location{{.*}}DW_OP_GNU_parameter_ref 0x[[PARAM:[0-9a-f]+]]
# CHECK: 0x{{0*}}[[PARAM]]:{{.*}}DW_TAG_formal_parameter
# CHECK: DW_AT_name{{.*}}"parameter"
# CHECK: DW_AT_name{{.*}}"implicit"
# CHECK: DW_AT_location{{.*}}DW_OP_GNU_implicit_pointer 0x[[TARGET:[0-9a-f]+]] +3
# CHECK: DW_AT_name{{.*}}"converted"
# CHECK: DW_AT_location{{.*}}DW_OP_lit1, DW_OP_GNU_convert {{.*}}"unsigned int", DW_OP_GNU_convert 0x0
# CHECK: DW_AT_name{{.*}}"unsigned int"
# CHECK: 0x{{0*}}[[TARGET]]:{{.*}}DW_TAG_variable
# CHECK: DW_AT_name{{.*}}"referenced_only"
# CHECK: DW_AT_const_value{{.*}}0x2a

.ifndef VERSION
.set VERSION, 4
.endif
.text
.space 16
.section .debug_abbrev,"",@progbits
.byte 1, 0x11, 1 # CU with direct addresses, no addr_base
.byte 0x11, 1, 0x12, 6, 0, 0
.byte 2, 0x2e, 1 # subprogram
.byte 3, 8, 0x11, 1, 0x12, 6, 0, 0
.byte 3, 0x34, 0 # variable exprloc
.byte 3, 8, 2, 0x18, 0, 0
.byte 4, 5, 0 # formal parameter, ref_udata type
.byte 3, 8, 0x49, 0x15, 0, 0
.byte 5, 0x24, 0 # base type
.byte 3, 8, 0x3e, 0x0b, 0x0b, 0x0b, 0, 0
.byte 6, 0x11, 1 # CU with no address attrs
.byte 0, 0
.byte 7, 0x34, 0 # referenced variable with a constant location
.byte 3, 8, 0x1c, 0x0b, 0, 0
.byte 0

.section .debug_info,"",@progbits
.Lsection:
.Lcu:
.long .Lcuend-.Lheader
.Lheader:
.short VERSION
.if VERSION == 5
.byte 1, 8
.long 0
.else
.long 0
.byte 8
.endif
.byte 1
.quad 0x1000
.long 16
.byte 2
.asciz "function"
.quad 0x1000
.long 16
.byte 3
.asciz "nested"
.uleb128 .Lexprend-.Lexpr
.Lexpr:
.byte 0x30, 0x28 # lit0, bra
.ifdef BAD_BRANCH
.short 1 # Inside the entry-value length operand.
.else
.short .Lexprend-1-.Lbranchend
.endif
.Lbranchend:
.byte 0xf3 # GNU_entry_value
.uleb128 .Lnestedend-.Lnested
.Lnested:
.byte 0xf5 # GNU_regval_type
.uleb128 128
.uleb128 .Ltype-.Lcu
.Lnestedend:
.byte 0x9f
.Lexprend:
.byte 3
.asciz "parameter_value"
.byte 5, 0xfa
.long .Lparam-.Lcu
.Lparam:
.byte 4
.asciz "parameter"
.uleb128 .Ltype-.Lcu
.byte 3
.asciz "implicit"
.byte 6, 0xf2 # GNU_implicit_pointer, four-byte section offset, SLEB 3
.ifdef BAD_REF
.long .Ltarget-.Lsection+1
.else
.long .Ltarget-.Lsection
.endif
.byte 3
.byte 3
.asciz "converted"
.uleb128 .Lconvertend-.Lconvert
.Lconvert:
.byte 0x31, 0xf7
.uleb128 .Ltype-.Lcu
.byte 0xf7, 0
.Lconvertend:
.byte 0
.Ltype:
.byte 5
.asciz "unsigned int"
.byte 7, 4
.byte 0
.Lcuend:
.Lcu2:
.long .Lcu2end-.Lheader2
.Lheader2:
.short VERSION
.if VERSION == 5
.byte 1, 8
.long 0
.else
.long 0
.byte 8
.endif
.byte 6
.Ltarget:
.byte 7
.asciz "referenced_only"
.byte 42
.byte 0
.Lcu2end:

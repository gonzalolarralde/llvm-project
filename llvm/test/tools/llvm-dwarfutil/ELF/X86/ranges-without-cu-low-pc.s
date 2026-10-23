# Legacy lists need an explicit base when the CU has no low_pc.
# An inferred live-function low_pc is not a declared list base.
# RUN: llvm-mc -triple=x86_64 -filetype=obj %s -o %t.o
# RUN: llvm-objcopy --change-section-address=.text=0x1000 %t.o %t.elf
# RUN: llvm-dwarfutil --no-odr --verify %t.elf %t.out
# RUN: llvm-dwarfdump --debug-info %t.out | FileCheck %s
# CHECK: DW_TAG_compile_unit
# CHECK: DW_AT_ranges
# CHECK-NEXT: [0x0000000000001000, 0x0000000000001010))
# CHECK: DW_AT_name{{.*}}"function"
# CHECK: DW_AT_location
# CHECK-NEXT: [0x0000000000001000, 0x0000000000001010): DW_OP_reg0 RAX)
.text
.space 16
.section .debug_abbrev,"",@progbits
.byte 1, 0x11, 1, 0x55, 0x17, 0, 0
.byte 2, 0x2e, 1, 3, 8, 0x11, 1, 0x12, 6, 0, 0
.byte 3, 0x34, 0, 2, 0x17, 0, 0
.byte 0
.section .debug_info,"",@progbits
.long .Lend-.Lheader
.Lheader:
.short 4
.long 0
.byte 8
.byte 1
.long 0
.byte 2
.asciz "function"
.quad 0x1000
.long 16
.byte 3
.long 0
.byte 0, 0
.Lend:
.section .debug_ranges,"",@progbits
.quad 0x1000, 0x1010, 0, 0
.section .debug_loc,"",@progbits
.quad -1, 0
.quad 0x1000, 0x1010
.short 1
.byte 0x50
.quad 0, 0

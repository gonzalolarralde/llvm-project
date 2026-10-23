# RUN: llvm-mc -triple=x86_64 -filetype=obj %s -o %t.o
# RUN: llvm-dwarfdump --debug-info %t.o | FileCheck %s
# RUN: llvm-dwarfdump --verify %t.o | FileCheck %s --check-prefix=VALID
# RUN: llvm-mc -triple=x86_64 -filetype=obj --defsym=BAD=1 %s -o %t.bad.o
# RUN: not llvm-dwarfdump --verify %t.bad.o | FileCheck %s --check-prefix=INVALID
# RUN: llvm-mc -triple=x86_64 -filetype=obj --defsym=BAD_CONVERT=1 %s -o %t.bad-convert.o
# RUN: not llvm-dwarfdump --verify %t.bad-convert.o | FileCheck %s --check-prefix=INVALID
# RUN: llvm-mc -triple=x86_64 -filetype=obj --defsym=TRUNCATED=1 %s -o %t.truncated.o
# RUN: not llvm-dwarfdump --verify %t.truncated.o | FileCheck %s --check-prefix=INVALID
# RUN: llvm-mc -triple=x86_64 -filetype=obj --defsym=UNTERMINATED=1 %s -o %t.unterminated.o
# RUN: not llvm-dwarfdump --verify %t.unterminated.o | FileCheck %s --check-prefix=INVALID

## GCC's GNU typed operators have the same operand encodings as their
## DWARF 5 successors. Conversion to type zero is valid; regval_type must
## reference a base type, even inside an entry-value expression.
# CHECK: DW_OP_GNU_entry_value(DW_OP_GNU_regval_type RDX {{.*}}"unsigned int"), DW_OP_GNU_convert {{.*}}"unsigned int", DW_OP_GNU_convert 0x0, DW_OP_stack_value
# VALID-NOT: error:
# VALID: No errors.
# INVALID: error: DIE contains invalid DWARF expression:
# INVALID: Errors detected.

.section .debug_abbrev,"",@progbits
 .uleb128 1
 .uleb128 0x11 # compile_unit
 .byte 1
 .byte 0, 0
 .uleb128 2
 .uleb128 0x24 # base_type
 .byte 0
 .uleb128 3 # name
 .uleb128 8 # string
 .uleb128 0x3e # encoding
 .uleb128 0x0b # data1
 .uleb128 0x0b # byte_size
 .uleb128 0x0b
 .byte 0, 0
 .uleb128 3
 .uleb128 0x34 # variable
 .byte 0
 .uleb128 2 # location
 .uleb128 0x18 # exprloc
 .byte 0, 0
 .byte 0

.section .debug_info,"",@progbits
.Lcu:
 .long .Lend-.Lheader
.Lheader:
 .short 4
 .long 0
 .byte 8
 .uleb128 1
.Ltype:
 .uleb128 2
 .asciz "unsigned int"
 .byte 7, 4
.Lvar:
 .uleb128 3
 .uleb128 .Lexprend-.Lexpr
.Lexpr:
 .byte 0xf3 # GNU_entry_value
 .uleb128 .Lentryend-.Lentry
.Lentry:
 .byte 0xf5 # GNU_regval_type
 .uleb128 1 # RDX
.ifdef BAD
 .uleb128 .Lvar-.Lcu # wrong tag; previously unrecognized regardless of type
.else
 .uleb128 .Ltype-.Lcu
.endif
.Lentryend:
 .byte 0xf7 # GNU_convert
.ifdef BAD_CONVERT
 .uleb128 .Lvar-.Lcu
.else
 .uleb128 .Ltype-.Lcu
.endif
 .byte 0xf7
.ifdef UNTERMINATED
 .byte 0x80 # no terminating LEB byte
.else
.ifndef TRUNCATED
 .uleb128 0
 .byte 0x9f # stack_value
.endif
.endif
.Lexprend:
 .byte 0
.Lend:

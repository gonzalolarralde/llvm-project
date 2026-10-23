# RUN: llvm-mc -triple=x86_64 -filetype=obj %s -o %t.o
# RUN: llvm-dwarfdump --debug-info %t.o | FileCheck %s
# RUN: llvm-dwarfdump --verify %t.o | FileCheck %s --check-prefix=VALID
# RUN: llvm-mc -triple=x86_64 -filetype=obj --defsym=DWARF64=1 %s -o %t.64.o
# RUN: llvm-dwarfdump --verify %t.64.o | FileCheck %s --check-prefix=VALID
# RUN: llvm-mc -triple=x86_64 -filetype=obj --defsym=BAD_PARAM=1 %s -o %t.bad.o
# RUN: not llvm-dwarfdump --verify %t.bad.o | FileCheck %s --check-prefix=INVALID
# RUN: llvm-mc -triple=x86_64 -filetype=obj --defsym=BAD_TYPE=1 %s -o %t.type.o
# RUN: not llvm-dwarfdump --verify %t.type.o | FileCheck %s --check-prefix=INVALID
# RUN: llvm-mc -triple=x86_64 -filetype=obj --defsym=TRUNCATED=1 %s -o %t.short.o
# RUN: not llvm-dwarfdump --verify %t.short.o | FileCheck %s --check-prefix=INVALID
# RUN: llvm-mc -triple=x86_64 -filetype=obj --defsym=TRUNCATED_TYPE=1 %s -o %t.short-type.o
# RUN: not llvm-dwarfdump --verify %t.short-type.o | FileCheck %s --check-prefix=INVALID

# CHECK: DW_OP_GNU_parameter_ref
# CHECK: DW_OP_GNU_deref_type 0x4 {{.*}}"unsigned int"
# CHECK: DW_OP_reg0 RAX, DW_OP_APPLE_uninit
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
 .uleb128 0x0b
 .uleb128 0x0b # byte_size
 .uleb128 0x0b
 .byte 0, 0
 .uleb128 3
 .uleb128 0x2e # subprogram
 .byte 1
 .byte 0, 0
 .uleb128 4
 .uleb128 0x05 # formal_parameter
 .byte 0
 .byte 0, 0
 .uleb128 5
 .uleb128 0x34 # variable
 .byte 0
 .uleb128 2 # location
 .uleb128 0x18 # exprloc
 .byte 0, 0
 .byte 0

.section .debug_info,"",@progbits
.Lcu:
.ifdef DWARF64
 .long 0xffffffff
 .quad .Lend-.Lheader
.else
 .long .Lend-.Lheader
.endif
.Lheader:
 .short 4
.ifdef DWARF64
 .quad 0
.else
 .long 0
.endif
 .byte 8
 .uleb128 1
.Ltype:
 .uleb128 2
 .asciz "unsigned int"
 .byte 7, 4
 .uleb128 3
.Lparam:
 .uleb128 4
.Lvar:
 .uleb128 5
 .uleb128 .Lparamend-.Lparamexpr
.Lparamexpr:
 .byte 0xfa # GNU_parameter_ref
.ifdef TRUNCATED
 .byte 0, 0, 0
.else
.ifdef BAD_PARAM
 .long .Ltype-.Lcu
.else
 .long .Lparam-.Lcu
.endif
.endif
.Lparamend:
 .uleb128 5
 .uleb128 .Lderefend-.Lderef
.Lderef:
 .byte 0x70, 0 # breg0(0)
 .byte 0xf6 # GNU_deref_type
 .byte 4
.ifndef TRUNCATED_TYPE
.ifdef BAD_TYPE
 .uleb128 .Lparam-.Lcu
.else
 .uleb128 .Ltype-.Lcu
.endif
.endif
.Lderefend:
 .uleb128 5
 .uleb128 2
 .byte 0x50, 0xf0 # reg0, GNU_uninit / APPLE_uninit
 .byte 0, 0
.Lend:

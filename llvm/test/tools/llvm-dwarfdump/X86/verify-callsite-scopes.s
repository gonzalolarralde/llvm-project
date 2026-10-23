# RUN: llvm-mc -triple=x86_64 -filetype=obj %s -o %t.standard.o
# RUN: llvm-dwarfdump --verify %t.standard.o | FileCheck %s --check-prefix=VALID
# RUN: llvm-mc -triple=x86_64 -filetype=obj --defsym=GNU=1 %s -o %t.gnu.o
# RUN: llvm-dwarfdump --verify %t.gnu.o | FileCheck %s --check-prefix=VALID
# RUN: llvm-mc -triple=x86_64 -filetype=obj --defsym=ORPHAN=1 %s -o %t.orphan.o
# RUN: not llvm-dwarfdump --verify %t.orphan.o | FileCheck %s --check-prefix=ORPHAN
# RUN: llvm-mc -triple=x86_64 -filetype=obj --defsym=GNU=1 --defsym=ORPHAN=1 %s -o %t.gnu-orphan.o
# RUN: not llvm-dwarfdump --verify %t.gnu-orphan.o | FileCheck %s --check-prefix=ORPHAN
# RUN: llvm-mc -triple=x86_64 -filetype=obj --defsym=GNU=1 --defsym=BAD_REF=1 %s -o %t.bad-ref.o
# RUN: not llvm-dwarfdump --verify %t.bad-ref.o | FileCheck %s --check-prefix=BAD_REF

## A partial set of call sites needs no all-calls attribute. A normal call
## inside an inlined function belongs to that function's innermost scope.
## GNU call-site parameters use abstract_origin for the formal parameter,
## whereas DWARF 5 uses call_parameter. Preserve checks for orphan call sites
## and incompatible abstract_origin references.
# VALID-NOT: error:
# VALID: No errors.
# ORPHAN: error: Call site entry not nested within a valid subprogram:
# ORPHAN: Errors detected.
# BAD_REF: error: DIE with tag DW_TAG_GNU_call_site_parameter has DW_AT_abstract_origin that points to DIE with incompatible tag DW_TAG_subprogram
# BAD_REF: Errors detected.

.section .debug_abbrev,"",@progbits
 .uleb128 1
 .uleb128 0x11 # compile_unit
 .byte 1
 .byte 0, 0
 .uleb128 2
 .uleb128 0x2e # subprogram
 .byte 1
 .byte 0, 0
 .uleb128 3
 .uleb128 0x05 # formal_parameter
 .byte 0
 .byte 0, 0
 .uleb128 4
 .uleb128 0x1d # inlined_subroutine
 .byte 1
 .uleb128 0x31 # abstract_origin
 .uleb128 0x13 # ref4
 .byte 0, 0
 .uleb128 5
 .uleb128 0x0b # lexical_block
 .byte 1
 .byte 0, 0
 .uleb128 6
.ifdef GNU
 .uleb128 0x4109 # GNU_call_site
.else
 .uleb128 0x48 # call_site
.endif
 .byte 1
.ifdef GNU
 .uleb128 0x31 # abstract_origin
.else
 .uleb128 0x7f # call_origin
.endif
 .uleb128 0x13 # ref4
 .byte 0, 0
 .uleb128 7
.ifdef GNU
 .uleb128 0x410a # GNU_call_site_parameter
.else
 .uleb128 0x49 # call_site_parameter
.endif
 .byte 0
.ifdef GNU
 .uleb128 0x31 # abstract_origin
.else
 .uleb128 0x80 # call_parameter
.endif
 .uleb128 0x13 # ref4
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
.Labstract:
 .uleb128 2
.Lparameter:
 .uleb128 3
 .byte 0
.ifndef ORPHAN
 .uleb128 2 # concrete subprogram, no all-calls assertion
 .uleb128 4
 .long .Labstract-.Lcu
 .uleb128 5
.endif
 .uleb128 6
 .long .Labstract-.Lcu
 .uleb128 7
.ifdef BAD_REF
 .long .Labstract-.Lcu
.else
 .long .Lparameter-.Lcu
.endif
 .byte 0 # call-site children
.ifndef ORPHAN
 .byte 0, 0, 0 # lexical block, inline scope, subprogram
.endif
 .byte 0 # CU
.Lend:

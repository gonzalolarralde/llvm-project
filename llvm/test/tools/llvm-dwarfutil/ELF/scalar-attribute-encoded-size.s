# REQUIRES: aarch64-registered-target
# A CU's linked range can shorten a ULEB high_pc from two bytes to one. Scalar
# operands may also use valid padded LEB encodings that DIEInteger canonicalizes.
# Layout must count the emitted size, or the next CU header is off by one byte.
# RUN: llvm-mc -triple=aarch64 -filetype=obj %s -o %t.o
# RUN: llvm-objcopy --change-section-address=.text=0x1000 %t.o %t.elf
# RUN: llvm-dwarfdump --verify %t.elf
# RUN: llvm-dwarfutil --linker=classic --no-odr --tombstone=bfd --verify %t.elf %t.classic
# RUN: llvm-dwarfdump --debug-info %t.classic | FileCheck %s
# RUN: llvm-dwarfutil --linker=parallel --no-odr --tombstone=bfd --verify %t.elf %t.parallel
# RUN: llvm-dwarfdump --debug-info %t.parallel | FileCheck %s
# RUN: llvm-mc -triple=aarch64 -filetype=obj --defsym=PADDED_SUBPROGRAM=1 %s -o %t.padded.o
# RUN: llvm-objcopy --change-section-address=.text=0x1000 %t.padded.o %t.padded
# RUN: llvm-dwarfdump --verify %t.padded
# RUN: llvm-dwarfutil --linker=classic --no-odr --tombstone=bfd --verify %t.padded %t.padded.classic
# RUN: llvm-dwarfdump --debug-info %t.padded.classic | FileCheck %s
# RUN: llvm-dwarfutil --linker=parallel --no-odr --tombstone=bfd --verify %t.padded %t.padded.parallel
# RUN: llvm-dwarfdump --debug-info %t.padded.parallel | FileCheck %s
# RUN: llvm-mc -triple=aarch64 -filetype=obj --defsym=PADDED_CONSTANT=1 %s -o %t.signed.o
# RUN: llvm-objcopy --change-section-address=.text=0x1000 %t.signed.o %t.signed
# RUN: llvm-dwarfdump --verify %t.signed
# RUN: llvm-dwarfutil --linker=classic --no-odr --tombstone=bfd --verify %t.signed %t.signed.classic
# RUN: llvm-dwarfdump --debug-info %t.signed.classic | FileCheck %s --check-prefixes=CHECK,SIGNED
# RUN: llvm-dwarfutil --linker=parallel --no-odr --tombstone=bfd --verify %t.signed %t.signed.parallel
# RUN: llvm-dwarfdump --debug-info %t.signed.parallel | FileCheck %s --check-prefixes=CHECK,SIGNED
# RUN: llvm-mc -triple=aarch64 -filetype=obj --defsym=BAD_UNIT_LENGTH=1 %s -o %t.bad.o
# RUN: llvm-objcopy --change-section-address=.text=0x1000 %t.bad.o %t.bad
# RUN: not llvm-dwarfdump --verify %t.bad 2>&1 | FileCheck %s --check-prefix=BAD
# CHECK: DW_AT_name{{.*}}"first"
# CHECK: DW_AT_low_pc{{.*}}0x0000000000001060
# CHECK: DW_AT_high_pc{{.*}}0x0000000000001083
# CHECK: DW_AT_name{{.*}}"live"
# CHECK: DW_AT_low_pc{{.*}}0x0000000000001060
# CHECK: DW_AT_high_pc{{.*}}0x0000000000001083
# SIGNED: DW_AT_name{{.*}}"constant"
# SIGNED: DW_AT_const_value{{.*}}35
# CHECK: Compile Unit:
# CHECK: DW_AT_name{{.*}}"second"
# CHECK: DW_AT_name{{.*}}"last"
# BAD: error: Units[1] - start offset:

.text
.space 256
.section .debug_abbrev,"",@progbits
.byte 1, 0x11, 1 // CU, children
.byte 3, 8, 0x11, 1, 0x12, 0x0f, 0, 0
.byte 2, 0x2e, 0 // subprogram, no children
.byte 3, 8, 0x11, 1, 0x12, 0x0f, 0, 0
.byte 3, 0x2e, 1 // subprogram, children
.byte 3, 8, 0x11, 1, 0x12, 0x0f, 0, 0
.byte 4, 0x34, 0 // variable, signed constant
.byte 3, 8, 0x1c, 0x0d, 0, 0
.byte 0

.ifdef PADDED_SUBPROGRAM
.set NARROW_CU, 1
.endif
.ifdef PADDED_CONSTANT
.set NARROW_CU, 1
.endif
.section .debug_info,"",@progbits
.Lcu:
.ifdef BAD_UNIT_LENGTH
.long .Lend-.Lhead+1
.else
.long .Lend-.Lhead
.endif
.Lhead:
.short 4
.long 0
.byte 8
.byte 1
.asciz "first"
.ifdef NARROW_CU
.quad 0x1060
.uleb128 0x23
.else
.quad 0x1000
.uleb128 0x83
.endif
.ifdef PADDED_CONSTANT
.byte 3
.else
.byte 2
.endif
.asciz "live"
.quad 0x1060
.ifdef PADDED_SUBPROGRAM
.byte 0xa3, 0x00 // A valid two-byte ULEB for 35 emits as one byte.
.else
.uleb128 0x23
.endif
.ifdef PADDED_CONSTANT
.byte 4
.asciz "constant"
.byte 0xa3, 0x00 // A valid two-byte SLEB for 35 emits as one byte.
.byte 0
.endif
.byte 0
.Lend:
.Lcu2:
.long .Lend2-.Lhead2
.Lhead2:
.short 4
.long 0
.byte 8
.byte 1
.asciz "second"
.quad 0x10f0
.uleb128 0x10
.byte 2
.asciz "last"
.quad 0x10f0
.uleb128 0x10
.byte 0
.Lend2:

# RUN: llvm-mc -triple=xtensa -mcpu=esp32s3 -filetype=obj %s -o %t
# RUN: llvm-dwarfdump --debug-frame %t | FileCheck %s

# The initial CFA is the incoming SP, and the return-address column is a0.
# Without these defaults the first FDE row has no CFA and debuggers reject it.
# CHECK: Return address column: 0
# CHECK: DW_CFA_def_cfa: SP +0
# CHECK: 0x0: CFA=SP
# CHECK: 0x3: CFA=SP+32

 .cfi_sections .debug_frame
 .text
 .global function
function:
 .cfi_startproc
 entry a1, 32
 .cfi_def_cfa_offset 32
 retw.n
 .cfi_endproc

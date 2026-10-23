; RUN: llc -mtriple=xtensa-esp32s3-none-elf -O0 -verify-machineinstrs -filetype=obj < %s -o %t
; RUN: llvm-dwarfdump --debug-info %t | FileCheck %s
; RUN: llvm-dwarfdump --verify %t

; An incoming byval object keeps a constant offset from the unaligned FP.
; Realigned locals must instead use the stable aligned BP while dynamic
; allocations and outgoing call frames move SP.
; Merely changing executable frame-index elimination leaves DWARF locations
; incorrectly based on FP and shows unrelated bytes in the debugger.

; CHECK: DW_AT_name ("fixed")
; CHECK: DW_TAG_formal_parameter
; CHECK: DW_AT_location (DW_OP_fbreg
; CHECK: DW_AT_name ("stack_arg")
; CHECK: DW_TAG_variable
; CHECK: DW_AT_location (DW_OP_breg6
; CHECK: DW_AT_name ("local")
define void @fixed(ptr byval([4 x i8]) align 4 %arg) !dbg !5 {
  %local = alloca [32 x i8], align 32
  #dbg_declare(ptr %arg, !9, !DIExpression(), !11)
  #dbg_declare(ptr %local, !10, !DIExpression(), !11)
  call void @consume(ptr %local), !dbg !11
  call void @consume(ptr %arg), !dbg !11
  ret void, !dbg !11
}

; CHECK: DW_AT_name ("dynamic")
; CHECK: DW_TAG_formal_parameter
; CHECK: DW_AT_location (DW_OP_fbreg
; CHECK: DW_AT_name ("stack_arg")
; CHECK: DW_TAG_variable
; CHECK: DW_AT_location (DW_OP_breg6
; CHECK: DW_AT_name ("local")
define void @dynamic(ptr byval([4 x i8]) align 4 %arg, i32 %size) !dbg !12 {
  %local = alloca [32 x i8], align 32
  %dynamic = alloca i8, i32 %size, align 64
  #dbg_declare(ptr %arg, !13, !DIExpression(), !15)
  #dbg_declare(ptr %local, !14, !DIExpression(), !15)
  call void @consume(ptr %dynamic), !dbg !15
  call void @consume(ptr %local), !dbg !15
  call void @consume(ptr %arg), !dbg !15
  ret void, !dbg !15
}

declare void @consume(ptr)

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!3, !4}
!0 = distinct !DICompileUnit(language: DW_LANG_C99, file: !1, producer: "test", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
!1 = !DIFile(filename: "frame.c", directory: "/")
!2 = !{}
!3 = !{i32 2, !"Dwarf Version", i32 4}
!4 = !{i32 2, !"Debug Info Version", i32 3}
!5 = distinct !DISubprogram(name: "fixed", scope: !1, file: !1, line: 1, type: !6, scopeLine: 1, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !2)
!6 = !DISubroutineType(types: !2)
!7 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_unsigned_char)
!8 = !DICompositeType(tag: DW_TAG_array_type, baseType: !7, size: 256, elements: !16)
!9 = !DILocalVariable(name: "stack_arg", arg: 1, scope: !5, file: !1, line: 1, type: !18)
!10 = !DILocalVariable(name: "local", scope: !5, file: !1, line: 2, type: !8)
!11 = !DILocation(line: 3, column: 1, scope: !5)
!12 = distinct !DISubprogram(name: "dynamic", scope: !1, file: !1, line: 5, type: !6, scopeLine: 5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !2)
!13 = !DILocalVariable(name: "stack_arg", arg: 1, scope: !12, file: !1, line: 5, type: !18)
!14 = !DILocalVariable(name: "local", scope: !12, file: !1, line: 6, type: !8)
!15 = !DILocation(line: 7, column: 1, scope: !12)
!16 = !{!17}
!17 = !DISubrange(count: 32)
!18 = !DICompositeType(tag: DW_TAG_array_type, baseType: !7, size: 32, elements: !19)
!19 = !{!20}
!20 = !DISubrange(count: 4)

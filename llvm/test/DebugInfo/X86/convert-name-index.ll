; RUN: llc -mtriple=x86_64-unknown-linux-gnu -filetype=obj -O0 -dwarf-op-convert=Enable %s -o %t
; RUN: llvm-dwarfdump --verify %t | FileCheck %s --check-prefix=VERIFY
; RUN: llvm-dwarfdump --debug-names %t | FileCheck %s
;
; Synthetic base types used by DW_OP_convert have names and must be indexed.
; VERIFY: No errors.
; CHECK-DAG: String: {{.*}} "DW_ATE_signed_8"
; CHECK-DAG: String: {{.*}} "DW_ATE_signed_32"

define i8 @convert(i8 %x) !dbg !4 {
  call void @llvm.dbg.value(metadata i8 %x, metadata !7, metadata !DIExpression(DW_OP_lit0, DW_OP_plus, DW_OP_LLVM_convert, 8, DW_ATE_signed, DW_OP_LLVM_convert, 32, DW_ATE_signed, DW_OP_stack_value)), !dbg !8
  ret i8 %x, !dbg !8
}

declare void @llvm.dbg.value(metadata, metadata, metadata)

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!2, !3}
!0 = distinct !DICompileUnit(language: DW_LANG_C99, file: !1, emissionKind: FullDebug, nameTableKind: Default)
!1 = !DIFile(filename: "convert.c", directory: "/")
!2 = !{i32 2, !"Dwarf Version", i32 5}
!3 = !{i32 2, !"Debug Info Version", i32 3}
!4 = distinct !DISubprogram(name: "convert", scope: !1, file: !1, line: 1, type: !5, spFlags: DISPFlagDefinition, unit: !0)
!5 = !DISubroutineType(types: !6)
!6 = !{null}
!7 = !DILocalVariable(name: "value", scope: !4, file: !1, line: 1, type: !9)
!8 = !DILocation(line: 1, column: 1, scope: !4)
!9 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)

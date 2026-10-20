; RUN: llc -mtriple=x86_64-unknown-linux-gnu -filetype=obj %s -o %t
; RUN: llvm-dwarfdump --verify %t | FileCheck %s --check-prefix=VERIFY
; RUN: llvm-dwarfdump --debug-info --debug-names %t | FileCheck %s
;
; A definition inherits its name from its specification. It must also be
; indexed under that name in .debug_names.
;
; VERIFY: No errors.
; CHECK: [[DEF:0x[0-9a-f]+]]: DW_TAG_structure_type
; CHECK-NEXT: DW_AT_specification
; CHECK: String: {{.*}} "SpecifiedType"
; CHECK: Tag: DW_TAG_structure_type
; CHECK: DW_IDX_die_offset: [[DEF]]

@value = global i32 0, !dbg !0

!llvm.dbg.cu = !{!2}
!llvm.module.flags = !{!6, !7}

!0 = !DIGlobalVariableExpression(var: !1, expr: !DIExpression())
!1 = distinct !DIGlobalVariable(name: "value", scope: !2, file: !3, line: 1, type: !8, isLocal: false, isDefinition: true)
!2 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !3, emissionKind: FullDebug, globals: !5, nameTableKind: Default)
!3 = !DIFile(filename: "specification.cpp", directory: "/")
!5 = !{!0}
!6 = !{i32 2, !"Dwarf Version", i32 5}
!7 = !{i32 2, !"Debug Info Version", i32 3}
!9 = !DICompositeType(tag: DW_TAG_structure_type, name: "SpecifiedType", file: !3, flags: DIFlagFwdDecl)
!8 = !DICompositeType(tag: DW_TAG_structure_type, file: !3, size: 32, specification: !9)

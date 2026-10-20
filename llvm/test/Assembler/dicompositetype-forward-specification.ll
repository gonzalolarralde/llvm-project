; RUN: llvm-as < %s | llvm-dis | FileCheck %s
; RUN: llvm-as < %s | llvm-dis | llvm-as | llvm-dis | FileCheck %s
;
; Uniquing a composite type must not cast an unresolved specification to DIType.
; Both metadata nodes deliberately have otherwise identical uniquing keys.

; CHECK: !types = !{!0, !1}
; CHECK: !0 = !DICompositeType(tag: DW_TAG_structure_type, specification: !1)
; CHECK: !1 = !DICompositeType(tag: DW_TAG_structure_type)

!types = !{!0, !1}
!0 = !DICompositeType(tag: DW_TAG_structure_type, specification: !1)
!1 = !DICompositeType(tag: DW_TAG_structure_type)

; RUN: llc -mtriple=xtensa -mcpu=esp32 -O0 -verify-machineinstrs %s -o /dev/null

; Reduced from an Embedded Swift frame containing by-value aggregates and
; many simultaneously live values. Stack addresses beyond ADDI range require
; a scratch register even when the total frame fits a signed 12-bit offset.
; This used to fail with no emergency spill slot during frame elimination.

target triple = "xtensa"

%TSo4Paira = type <{ %Ts6UInt32V, %Ts6UInt32V }>
%Ts6UInt32V = type <{ i32 }>
%TSo5Largea = type <{ <{ %Ts6UInt32V, %Ts6UInt32V, %Ts6UInt32V, %Ts6UInt32V, %Ts6UInt32V }> }>
%TSd = type <{ double }>

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr writeonly captures(none), i8, i64, i1 immarg) #0

; Function Attrs: nounwind
define i32 @scavenge_windowed_frame(i64 %0, i32 %1, i32 %2, i32 %3, i32 %4, i32 %5, i32 %6, i32 %7, i32 %8, i32 %9, i32 %10, i32 %11, i32 %12, i64 %13, i64 %14, i64 %15, i32 %16) #1 {
entry:
  %.coercion.coerced = alloca [2 x i32], align 4
  %pair.debug = alloca %TSo4Paira, align 4
  call void @llvm.memset.p0.i64(ptr align 4 null, i8 0, i64 8, i1 false)
  %coerced-arg.coerced2 = alloca %TSo5Largea, align 4
  %call.aggresult = alloca %TSo5Largea, align 4
  %large.debug = alloca %TSo5Largea, align 4
  %.coercion.coerced15 = alloca float, align 4
  %.coercion.coerced16 = alloca float, align 4
  %.coercion.coerced17 = alloca double, align 8
  %.coercion.coerced18 = alloca double, align 8
  %.coercion.coerced19 = alloca i64, align 8
  %indirect-temporary20 = alloca %TSo5Largea, align 4
  %call.aggresult25 = alloca %TSo5Largea, align 4
  %prefixed.debug = alloca %TSo5Largea, align 4
  %indirect-temporary34 = alloca %TSo4Paira, align 4
  %call.aggresult36 = alloca <{ %TSd, %TSd, %TSd }>, align 8
  %tuple.debug = alloca <{ %TSd, %TSd, %TSd }>, align 8
  call void @llvm.memset.p0.i64(ptr align 8 null, i8 0, i64 0, i1 false)
  br label %17

17:                                               ; preds = %entry
  %18 = phi i32 [ 1, %entry ]
  %19 = phi i32 [ 1, %entry ]
  %20 = phi i32 [ 1, %entry ]
  %21 = phi i32 [ 1, %entry ]
  %22 = phi i32 [ 1, %entry ]
  %23 = phi i32 [ 1, %entry ]
  %24 = phi i32 [ 1, %entry ]
  %25 = phi i32 [ 1, %entry ]
  %26 = phi i32 [ 0, %entry ]
  %27 = phi i32 [ 0, %entry ]
  %28 = phi i32 [ 0, %entry ]
  %29 = phi i32 [ 0, %entry ]
  %30 = phi i32 [ 0, %entry ]
  %31 = phi i32 [ 0, %entry ]
  %32 = call i64 null(i32 0, i64 0, i32 0)
  %33 = icmp ne i64 %0, 1161981758246079445
  br i1 %33, label %34, label %36

34:                                               ; preds = %17
  %35 = or i32 %31, 0
  br label %36

36:                                               ; preds = %34, %17
  %37 = phi i32 [ 0, %34 ], [ %18, %17 ]
  %38 = phi i32 [ 0, %34 ], [ %19, %17 ]
  %39 = phi i32 [ 0, %34 ], [ %20, %17 ]
  %40 = phi i32 [ 0, %34 ], [ %21, %17 ]
  %41 = phi i32 [ 0, %34 ], [ %22, %17 ]
  %42 = phi i32 [ 0, %34 ], [ %23, %17 ]
  %43 = phi i32 [ 0, %34 ], [ %24, %17 ]
  %44 = phi i32 [ 0, %34 ], [ %25, %17 ]
  %45 = phi i32 [ 0, %34 ], [ %26, %17 ]
  %46 = phi i32 [ 0, %34 ], [ %27, %17 ]
  %47 = phi i32 [ 0, %34 ], [ %28, %17 ]
  %48 = phi i32 [ 0, %34 ], [ %29, %17 ]
  %49 = phi i32 [ 0, %34 ], [ 0, %17 ]
  %50 = phi i32 [ 0, %34 ], [ %30, %17 ]
  %51 = call [2 x i32] null([2 x i32] zeroinitializer)
  store [2 x i32] zeroinitializer, ptr %.coercion.coerced, align 4
  br i1 false, label %52, label %54

52:                                               ; preds = %36
  %53 = or i32 %50, 0
  br label %54

54:                                               ; preds = %52, %36
  %55 = phi i32 [ %1, %52 ], [ %37, %36 ]
  %56 = phi i32 [ 0, %52 ], [ %38, %36 ]
  %57 = phi i32 [ %53, %52 ], [ %39, %36 ]
  %58 = phi i32 [ %1, %52 ], [ %40, %36 ]
  %59 = phi i32 [ %1, %52 ], [ %41, %36 ]
  %60 = phi i32 [ %1, %52 ], [ %42, %36 ]
  %61 = phi i32 [ %1, %52 ], [ %43, %36 ]
  %62 = phi i32 [ %1, %52 ], [ %44, %36 ]
  %63 = phi i32 [ %1, %52 ], [ %45, %36 ]
  %64 = phi i32 [ 0, %52 ], [ %46, %36 ]
  %65 = phi i32 [ 0, %52 ], [ %47, %36 ]
  %66 = phi i32 [ 0, %52 ], [ %48, %36 ]
  %67 = phi i32 [ 0, %52 ], [ %49, %36 ]
  br i1 false, label %68, label %70

68:                                               ; preds = %54
  %69 = or i32 %67, 0
  br label %70

70:                                               ; preds = %68, %54
  %71 = phi i32 [ %2, %68 ], [ %55, %54 ]
  %72 = phi i32 [ %69, %68 ], [ %56, %54 ]
  %73 = phi i32 [ 0, %68 ], [ %57, %54 ]
  %74 = phi i32 [ %2, %68 ], [ %58, %54 ]
  %75 = phi i32 [ %2, %68 ], [ %59, %54 ]
  %76 = phi i32 [ %2, %68 ], [ %60, %54 ]
  %77 = phi i32 [ %2, %68 ], [ %61, %54 ]
  %78 = phi i32 [ %2, %68 ], [ %62, %54 ]
  %79 = phi i32 [ %2, %68 ], [ %63, %54 ]
  %80 = phi i32 [ 0, %68 ], [ %64, %54 ]
  %81 = phi i32 [ 0, %68 ], [ %65, %54 ]
  %82 = phi i32 [ 0, %68 ], [ %66, %54 ]
  %83 = call float null(i32 0, i32 0)
  br i1 true, label %84, label %86

84:                                               ; preds = %70
  %85 = or i32 %82, 0
  br label %86

86:                                               ; preds = %84, %70
  %87 = phi i32 [ 0, %84 ], [ %71, %70 ]
  %88 = phi i32 [ %85, %84 ], [ %72, %70 ]
  %89 = phi i32 [ %3, %84 ], [ %4, %70 ]
  %90 = phi i32 [ %3, %84 ], [ %5, %70 ]
  %91 = phi i32 [ %3, %84 ], [ %75, %70 ]
  %92 = phi i32 [ %3, %84 ], [ %76, %70 ]
  %93 = phi i32 [ %3, %84 ], [ %77, %70 ]
  %94 = phi i32 [ %3, %84 ], [ %78, %70 ]
  %95 = phi i32 [ %3, %84 ], [ %79, %70 ]
  %96 = phi i32 [ 0, %84 ], [ %80, %70 ]
  %97 = phi i32 [ 0, %84 ], [ %81, %70 ]
  %98 = call i64 null(i64 0, i64 0)
  br i1 true, label %99, label %101

99:                                               ; preds = %86
  %100 = or i32 %97, 0
  br label %101

101:                                              ; preds = %99, %86
  %102 = phi i32 [ %6, %99 ], [ %7, %86 ]
  %103 = phi i32 [ %6, %99 ], [ %8, %86 ]
  %104 = phi i32 [ %100, %99 ], [ %89, %86 ]
  %105 = phi i32 [ %6, %99 ], [ %90, %86 ]
  %106 = phi i32 [ %6, %99 ], [ %91, %86 ]
  %107 = phi i32 [ %6, %99 ], [ %92, %86 ]
  %108 = phi i32 [ 0, %99 ], [ %93, %86 ]
  %109 = phi i32 [ %6, %99 ], [ %94, %86 ]
  %110 = phi i32 [ %6, %99 ], [ %95, %86 ]
  %111 = phi i32 [ 0, %99 ], [ %96, %86 ]
  %112 = call i32 null(ptr null, i32 0, i32 0)
  br i1 false, label %113, label %115

113:                                              ; preds = %101
  %114 = or i32 %111, 0
  br label %115

115:                                              ; preds = %113, %101
  %116 = phi i32 [ 0, %113 ], [ %102, %101 ]
  %117 = phi i32 [ %9, %113 ], [ %103, %101 ]
  %118 = phi i32 [ %114, %113 ], [ %104, %101 ]
  %119 = phi i32 [ %9, %113 ], [ %105, %101 ]
  %120 = phi i32 [ %9, %113 ], [ %106, %101 ]
  %121 = phi i32 [ %9, %113 ], [ %107, %101 ]
  %122 = phi i32 [ %9, %113 ], [ %108, %101 ]
  %123 = phi i32 [ %9, %113 ], [ %109, %101 ]
  %124 = phi i32 [ %9, %113 ], [ %110, %101 ]
  %125 = call { i32, i32, i8 } null(i32 0, i32 0, i8 1)
  br i1 false, label %126, label %128

126:                                              ; preds = %115
  %127 = or i32 %124, 0
  ret i32 0

128:                                              ; preds = %115
  %129 = phi i32 [ %10, %115 ]
  %130 = phi i32 [ %117, %115 ]
  %131 = phi i32 [ %118, %115 ]
  %132 = phi i32 [ %119, %115 ]
  %133 = phi i32 [ %120, %115 ]
  %134 = phi i32 [ %121, %115 ]
  %135 = phi i32 [ %122, %115 ]
  %136 = phi i32 [ %123, %115 ]
  %137 = call i32 null(i32 0)
  br i1 false, label %138, label %140

138:                                              ; preds = %128
  %139 = or i32 %136, 1
  store i32 %11, ptr null, align 4
  br label %140

140:                                              ; preds = %138, %128
  %141 = phi i32 [ %11, %138 ], [ %129, %128 ]
  %142 = phi i32 [ %11, %138 ], [ %130, %128 ]
  %143 = phi i32 [ %11, %138 ], [ %131, %128 ]
  %144 = phi i32 [ %11, %138 ], [ %132, %128 ]
  %145 = phi i32 [ %11, %138 ], [ %133, %128 ]
  %146 = phi i32 [ %11, %138 ], [ %134, %128 ]
  %147 = phi i32 [ %11, %138 ], [ %135, %128 ]
  %148 = call i32 null(i32 0)
  br i1 false, label %149, label %151

149:                                              ; preds = %140
  %150 = or i32 %147, 0
  store i32 %12, ptr null, align 4
  ret i32 0

151:                                              ; preds = %140
  %152 = phi i32 [ %141, %140 ]
  %153 = phi i32 [ %142, %140 ]
  %154 = phi i32 [ %143, %140 ]
  %155 = phi i32 [ %144, %140 ]
  %156 = phi i32 [ %145, %140 ]
  %157 = phi i32 [ %146, %140 ]
  %158 = call i64 null(i64 1311768467750121216, i32 17)
  %159 = call i64 null(i32 17)
  %160 = and i64 %13, 63
  %161 = lshr i64 1311768467750121216, %14
  %162 = xor i64 %161, 0
  %163 = icmp ne i64 %15, %162
  br i1 %163, label %164, label %166

164:                                              ; preds = %151
  %165 = or i32 %157, 0
  store i32 %16, ptr null, align 4
  ret i32 0

166:                                              ; preds = %151
  %167 = phi i32 [ %152, %151 ]
  %168 = phi i32 [ %153, %151 ]
  %169 = phi i32 [ %154, %151 ]
  %170 = phi i32 [ %155, %151 ]
  %171 = phi i32 [ %156, %151 ]
  br i1 false, label %172, label %173

172:                                              ; preds = %166
  ret i32 0

173:                                              ; preds = %166
  br i1 false, label %174, label %175

174:                                              ; preds = %173
  ret i32 0

175:                                              ; preds = %173
  br i1 false, label %176, label %177

176:                                              ; preds = %175
  ret i32 0

177:                                              ; preds = %175
  br i1 false, label %178, label %179

178:                                              ; preds = %177
  ret i32 0

179:                                              ; preds = %177
  br i1 false, label %180, label %181

180:                                              ; preds = %179
  ret i32 0

181:                                              ; preds = %179
  ret i32 0
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(ptr captures(none)) #2

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(ptr captures(none)) #2

attributes #0 = { nocallback nofree nosync nounwind willreturn memory(argmem: write) }
attributes #1 = { nounwind "frame-pointer"="all" "target-cpu"="esp32" }
attributes #2 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }

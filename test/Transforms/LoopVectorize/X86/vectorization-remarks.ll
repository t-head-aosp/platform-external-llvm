; RUN: opt < %s -loop-vectorize -mtriple=x86_64-unknown-linux -S -pass-remarks='loop-vectorize' 2>&1 | FileCheck -check-prefix=VECTORIZED %s
; RUN: opt < %s -loop-vectorize -force-vector-width=1 -force-vector-interleave=4 -mtriple=x86_64-unknown-linux -S -pass-remarks='loop-vectorize' 2>&1 | FileCheck -check-prefix=UNROLLED %s
; RUN: opt < %s -loop-vectorize -force-vector-width=1 -force-vector-interleave=1 -mtriple=x86_64-unknown-linux -S -pass-remarks-analysis='loop-vectorize' 2>&1 | FileCheck -check-prefix=NONE %s

; This code has all the !dbg annotations needed to track source line information,
; but is missing the llvm.dbg.cu annotation. This prevents code generation from
; emitting debug info in the final output.
; RUN: llc -mtriple x86_64-pc-linux-gnu %s -o - | FileCheck -check-prefix=DEBUG-OUTPUT %s
; DEBUG-OUTPUT-NOT: .loc
; DEBUG-OUTPUT-NOT: {{.*}}.debug_info

; VECTORIZED: remark: vectorization-remarks.c:17:8: vectorized loop (vectorization factor: 4, unrolling interleave factor: 1)
; UNROLLED: remark: vectorization-remarks.c:17:8: unrolled with interleaving factor 4 (vectorization not beneficial)
; NONE: remark: vectorization-remarks.c:17:8: loop not vectorized: vector width and interleave count are explicitly set to 1

target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"

define i32 @foo(i32 %n) #0 {
entry:
  %diff = alloca i32, align 4
  %cb = alloca [16 x i8], align 16
  %cc = alloca [16 x i8], align 16
  store i32 0, i32* %diff, align 4, !dbg !10, !tbaa !11
  br label %for.body, !dbg !15

for.body:                                         ; preds = %for.body, %entry
  %indvars.iv = phi i64 [ 0, %entry ], [ %indvars.iv.next, %for.body ]
  %add8 = phi i32 [ 0, %entry ], [ %add, %for.body ], !dbg !19
  %arrayidx = getelementptr inbounds [16 x i8]* %cb, i64 0, i64 %indvars.iv, !dbg !19
  %0 = load i8* %arrayidx, align 1, !dbg !19, !tbaa !21
  %conv = sext i8 %0 to i32, !dbg !19
  %arrayidx2 = getelementptr inbounds [16 x i8]* %cc, i64 0, i64 %indvars.iv, !dbg !19
  %1 = load i8* %arrayidx2, align 1, !dbg !19, !tbaa !21
  %conv3 = sext i8 %1 to i32, !dbg !19
  %sub = sub i32 %conv, %conv3, !dbg !19
  %add = add nsw i32 %sub, %add8, !dbg !19
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1, !dbg !15
  %exitcond = icmp eq i64 %indvars.iv.next, 16, !dbg !15
  br i1 %exitcond, label %for.end, label %for.body, !dbg !15

for.end:                                          ; preds = %for.body
  store i32 %add, i32* %diff, align 4, !dbg !19, !tbaa !11
  call void @ibar(i32* %diff) #2, !dbg !22
  ret i32 0, !dbg !23
}

declare void @ibar(i32*) #1

!llvm.module.flags = !{!7, !8}
!llvm.ident = !{!9}

!1 = metadata !{metadata !"vectorization-remarks.c", metadata !"."}
!2 = metadata !{}
!3 = metadata !{metadata !4}
!4 = metadata !{metadata !"0x2e\00foo\00foo\00\005\000\001\000\006\00256\001\006", metadata !1, metadata !5, metadata !6, null, i32 (i32)* @foo, null, null, metadata !2} ; [ DW_TAG_subprogram ] [line 5] [def] [scope 6] [foo]
!5 = metadata !{metadata !"0x29", metadata !1}          ; [ DW_TAG_file_type ] [./vectorization-remarks.c]
!6 = metadata !{metadata !"0x15\00\000\000\000\000\000\000", i32 0, null, null, metadata !2, null, null, null} ; [ DW_TAG_subroutine_type ] [line 0, size 0, align 0, offset 0] [from ]
!7 = metadata !{i32 2, metadata !"Dwarf Version", i32 4}
!8 = metadata !{i32 1, metadata !"Debug Info Version", i32 2}
!9 = metadata !{metadata !"clang version 3.5.0 "}
!10 = metadata !{i32 8, i32 3, metadata !4, null}
!11 = metadata !{metadata !12, metadata !12, i64 0}
!12 = metadata !{metadata !"int", metadata !13, i64 0}
!13 = metadata !{metadata !"omnipotent char", metadata !14, i64 0}
!14 = metadata !{metadata !"Simple C/C++ TBAA"}
!15 = metadata !{i32 17, i32 8, metadata !16, null}
!16 = metadata !{metadata !"0xb\0017\008\002", metadata !1, metadata !17} ; [ DW_TAG_lexical_block ] [./vectorization-remarks.c]
!17 = metadata !{metadata !"0xb\0017\008\001", metadata !1, metadata !18} ; [ DW_TAG_lexical_block ] [./vectorization-remarks.c]
!18 = metadata !{metadata !"0xb\0017\003\000", metadata !1, metadata !4} ; [ DW_TAG_lexical_block ] [./vectorization-remarks.c]
!19 = metadata !{i32 18, i32 5, metadata !20, null}
!20 = metadata !{metadata !"0xb\0017\0027\000", metadata !1, metadata !18} ; [ DW_TAG_lexical_block ] [./vectorization-remarks.c]
!21 = metadata !{metadata !13, metadata !13, i64 0}
!22 = metadata !{i32 20, i32 3, metadata !4, null}
!23 = metadata !{i32 21, i32 3, metadata !4, null}

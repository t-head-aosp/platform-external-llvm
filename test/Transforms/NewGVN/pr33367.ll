; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; RUN: opt -newgvn -S %s | FileCheck %s
; Verify that we don't accidentally delete intrinsics that aren't SSA copies
%DS_struct = type { [32 x i64*], i8, [32 x i16] }
%MNR_struct = type { i64, i64, %DS_struct* }

declare i64 @llvm.x86.bmi.bextr.64(i64, i64) #3

define %MNR_struct @f000316011717_2(%DS_struct* %pDS, [64 x i64]* %pCG) #2 {
; CHECK-LABEL: @f000316011717_2(
; CHECK-NEXT:  Entry:
; CHECK-NEXT:    [[RESTART:%.*]] = alloca [[MNR_STRUCT:%.*]]
; CHECK-NEXT:    [[PCARRY:%.*]] = getelementptr [[DS_STRUCT:%.*]], %DS_struct* [[PDS:%.*]], i32 0, i32 1
; CHECK-NEXT:    [[PBRBASE:%.*]] = getelementptr [[DS_STRUCT]], %DS_struct* [[PDS]], i32 0, i32 0
; CHECK-NEXT:    [[PBASE:%.*]] = getelementptr [32 x i64*], [32 x i64*]* [[PBRBASE]], i64 0, i64 0
; CHECK-NEXT:    [[BASE:%.*]] = load i64*, i64** [[PBASE]], !tbaa !14
; CHECK-NEXT:    [[ABSADDR:%.*]] = getelementptr i64, i64* [[BASE]], i64 9
; CHECK-NEXT:    [[EXTARGET:%.*]] = load i64, i64* [[ABSADDR]], align 8, !tbaa !4
; CHECK-NEXT:    [[TEMPLATE:%.*]] = icmp eq i64 [[EXTARGET]], 8593987412
; CHECK-NEXT:    br i1 [[TEMPLATE]], label %"BB3.000316011731#1", label [[BB2_000316011731_5:%.*]]
; CHECK:       "BB3.000316011731#1":
; CHECK-NEXT:    [[PBASE8:%.*]] = getelementptr [32 x i64*], [32 x i64*]* [[PBRBASE]], i64 0, i64 29
; CHECK-NEXT:    [[BASE9:%.*]] = load i64*, i64** [[PBASE8]], !tbaa !14
; CHECK-NEXT:    [[ABSADDR1:%.*]] = getelementptr i64, i64* [[BASE9]], i64 7
; CHECK-NEXT:    [[RMEM:%.*]] = load i64, i64* [[ABSADDR1]], align 8, !tbaa !4
; CHECK-NEXT:    [[PWT:%.*]] = getelementptr [[DS_STRUCT]], %DS_struct* [[PDS]], i32 0, i32 2
; CHECK-NEXT:    [[PWTE:%.*]] = getelementptr [32 x i16], [32 x i16]* [[PWT]], i64 0, i64 8593987412
; CHECK-NEXT:    [[SHIFTS:%.*]] = load i16, i16* [[PWTE]], align 2, !tbaa !18, !invariant.load !20
; CHECK-NEXT:    [[SLOWJ:%.*]] = icmp eq i16 [[SHIFTS]], 0
; CHECK-NEXT:    br i1 [[SLOWJ]], label [[BB2_000316011731_5]], label %"BB3.000316011731#1.1"
; CHECK:       BB2.000316011731.5:
; CHECK-NEXT:    [[EXTARGET1:%.*]] = and i64 [[EXTARGET]], 137438953471
; CHECK-NEXT:    switch i64 [[EXTARGET1]], label [[EXIT:%.*]] [
; CHECK-NEXT:    ]
; CHECK:       "BB3.000316011731#1.1":
; CHECK-NEXT:    [[SHIFTS1:%.*]] = zext i16 [[SHIFTS]] to i64
; CHECK-NEXT:    [[VAL:%.*]] = call i64 @llvm.x86.bmi.bextr.64(i64 [[RMEM]], i64 [[SHIFTS1]])
; CHECK-NEXT:    [[PREG:%.*]] = getelementptr [64 x i64], [64 x i64]* [[PCG:%.*]], i64 0, i64 12
; CHECK-NEXT:    store i64 [[VAL]], i64* [[PREG]], align 32, !tbaa !10
; CHECK-NEXT:    [[PREG2:%.*]] = getelementptr [64 x i64], [64 x i64]* [[PCG]], i64 0, i64 14
; CHECK-NEXT:    [[REG:%.*]] = load i64, i64* [[PREG2]], align 16, !tbaa !12
; CHECK-NEXT:    [[BASE2:%.*]] = load i64*, i64** [[PBASE8]], !tbaa !14
; CHECK-NEXT:    [[ABSADDR2:%.*]] = getelementptr i64, i64* [[BASE2]], i64 [[REG]]
; CHECK-NEXT:    [[RMEM2:%.*]] = load i64, i64* [[ABSADDR2]], align 8, !tbaa !1
; CHECK-NEXT:    [[PREG7:%.*]] = getelementptr [64 x i64], [64 x i64]* [[PCG]], i64 0, i64 9
; CHECK-NEXT:    store i64 [[RMEM2]], i64* [[PREG7]], align 8, !tbaa !8
; CHECK-NEXT:    [[ADD2C279:%.*]] = add i64 [[RMEM2]], [[VAL]]
; CHECK-NEXT:    [[CCHK:%.*]] = icmp sge i64 [[ADD2C279]], 0
; CHECK-NEXT:    [[CFL:%.*]] = zext i1 [[CCHK]] to i8
; CHECK-NEXT:    store i8 [[CFL]], i8* [[PCARRY]], align 1, !tbaa !16
; CHECK-NEXT:    br label [[EXIT]]
; CHECK:       Exit:
; CHECK-NEXT:    [[RESTART378:%.*]] = load [[MNR_STRUCT]], %MNR_struct* [[RESTART]]
; CHECK-NEXT:    ret [[MNR_STRUCT]] %restart378
;
Entry:
  %restart = alloca %MNR_struct
  %pCarry = getelementptr %DS_struct, %DS_struct* %pDS, i32 0, i32 1
  %pBRBase = getelementptr  %DS_struct, %DS_struct* %pDS, i32 0, i32 0
  %pbase = getelementptr  [32 x i64*], [32 x i64*]* %pBRBase, i64 0, i64 0
  %base = load i64*, i64** %pbase, !tbaa !142
  %absaddr = getelementptr  i64, i64* %base, i64 9
  %extarget = load i64, i64* %absaddr, align 8, !tbaa !4
  %template = icmp eq i64 %extarget, 8593987412
  br i1 %template, label %"BB3.000316011731#1", label %BB2.000316011731.5

"BB3.000316011731#1":
  %pBRBase7 = getelementptr  %DS_struct, %DS_struct* %pDS, i32 0, i32 0
  %pbase8 = getelementptr  [32 x i64*], [32 x i64*]* %pBRBase7, i64 0, i64 29
  %base9 = load i64*, i64** %pbase8, !tbaa !142
  %absaddr1 = getelementptr  i64, i64* %base9, i64 7
  %rmem = load i64, i64* %absaddr1, align 8, !tbaa !4
  %pwt = getelementptr  %DS_struct, %DS_struct* %pDS, i32 0, i32 2
  %pwte = getelementptr  [32 x i16], [32 x i16]* %pwt, i64 0, i64 %extarget
  %shifts = load i16, i16* %pwte, align 2, !tbaa !175, !invariant.load !181
  %slowj = icmp eq i16 %shifts, 0
  br i1 %slowj, label %BB2.000316011731.5, label %"BB3.000316011731#1.1"

BB2.000316011731.5:
  %extarget1 = and i64 %extarget, 137438953471
  switch i64 %extarget1, label %Exit [
  ]

"BB3.000316011731#1.1":
  %shifts1 = zext i16 %shifts to i64
  %val = call i64 @llvm.x86.bmi.bextr.64(i64 %rmem, i64 %shifts1)
  %preg = getelementptr  [64 x i64], [64 x i64]* %pCG, i64 0, i64 12
  store i64 %val, i64* %preg, align 32, !tbaa !32
  %preg2 = getelementptr  [64 x i64], [64 x i64]* %pCG, i64 0, i64 14
  %reg = load i64, i64* %preg2, align 16, !tbaa !36
  %pBRBase2 = getelementptr  %DS_struct, %DS_struct* %pDS, i32 0, i32 0
  %pbase2 = getelementptr  [32 x i64*], [32 x i64*]* %pBRBase2, i64 0, i64 29
  %base2 = load i64*, i64** %pbase2, !tbaa !142
  %absaddr2 = getelementptr  i64, i64* %base2, i64 %reg
  %rmem2 = load i64, i64* %absaddr2, align 8, !tbaa !4
  %preg7 = getelementptr  [64 x i64], [64 x i64]* %pCG, i64 0, i64 9
  store i64 %rmem2, i64* %preg7, align 8, !tbaa !26
  %reg7 = load i64, i64* %preg7, align 8, !tbaa !26
  %preg3 = getelementptr  [64 x i64], [64 x i64]* %pCG, i64 0, i64 12
  %reg4 = load i64, i64* %preg3, align 32, !tbaa !32
  %add2c279 = add i64 %reg7, %reg4
  %cchk = icmp sge i64 %add2c279, 0
  %cfl = zext i1 %cchk to i8
  store i8 %cfl, i8* %pCarry, align 1, !tbaa !156
  br label %Exit

Exit:
  %restart378 = load %MNR_struct, %MNR_struct* %restart
  ret %MNR_struct %restart378
}

attributes #2 = { nounwind }
attributes #3 = { nounwind readnone }

!tbaa = !{!0, !1, !3, !4, !6, !26, !32, !36, !142, !156, !175}

!0 = !{!"tbaa2200"}
!1 = !{!2, !2, i64 0}
!2 = !{!"data", !0}
!3 = !{!"ctrl", !0}
!4 = !{!5, !5, i64 0}
!5 = !{!"mem", !2}
!6 = !{!7, !7, i64 0}
!7 = !{!"grs", !2}
!26 = !{!27, !27, i64 0}
!27 = !{!"X9", !7}
!32 = !{!33, !33, i64 0}
!33 = !{!"A0", !7}
!36 = !{!37, !37, i64 0}
!37 = !{!"A2", !7}
!142 = !{!143, !143, i64 0}
!143 = !{!"breg", !3}
!156 = !{!157, !157, i64 0}
!157 = !{!"carry", !3}
!175 = !{!176, !176, i64 0, i32 1}
!176 = !{!"const", !3}
!181 = !{}

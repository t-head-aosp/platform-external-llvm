; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; RUN: opt -instcombine -S < %s | FileCheck %s

declare i32 @llvm.cttz.i32(i32, i1) nounwind readnone
declare i32 @llvm.ctlz.i32(i32, i1) nounwind readnone
declare i32 @llvm.ctpop.i32(i32) nounwind readnone
declare <2 x i8> @llvm.cttz.v2i8(<2 x i8>, i1) nounwind readnone
declare <2 x i8> @llvm.ctlz.v2i8(<2 x i8>, i1) nounwind readnone
declare <2 x i8> @llvm.ctpop.v2i8(<2 x i8>) nounwind readnone

define i32 @lshr_ctlz_zero_is_not_undef(i32 %x) {
; CHECK-LABEL: @lshr_ctlz_zero_is_not_undef(
; CHECK-NEXT:    [[TMP1:%.*]] = icmp eq i32 %x, 0
; CHECK-NEXT:    [[SH:%.*]] = zext i1 [[TMP1]] to i32
; CHECK-NEXT:    ret i32 [[SH]]
;
  %ct = call i32 @llvm.ctlz.i32(i32 %x, i1 false)
  %sh = lshr i32 %ct, 5
  ret i32 %sh
}

define i32 @lshr_cttz_zero_is_not_undef(i32 %x) {
; CHECK-LABEL: @lshr_cttz_zero_is_not_undef(
; CHECK-NEXT:    [[TMP1:%.*]] = icmp eq i32 %x, 0
; CHECK-NEXT:    [[SH:%.*]] = zext i1 [[TMP1]] to i32
; CHECK-NEXT:    ret i32 [[SH]]
;
  %ct = call i32 @llvm.cttz.i32(i32 %x, i1 false)
  %sh = lshr i32 %ct, 5
  ret i32 %sh
}

define i32 @lshr_ctpop(i32 %x) {
; CHECK-LABEL: @lshr_ctpop(
; CHECK-NEXT:    [[TMP1:%.*]] = icmp eq i32 %x, -1
; CHECK-NEXT:    [[SH:%.*]] = zext i1 [[TMP1]] to i32
; CHECK-NEXT:    ret i32 [[SH]]
;
  %ct = call i32 @llvm.ctpop.i32(i32 %x)
  %sh = lshr i32 %ct, 5
  ret i32 %sh
}

define <2 x i8> @lshr_ctlz_zero_is_not_undef_splat_vec(<2 x i8> %x) {
; CHECK-LABEL: @lshr_ctlz_zero_is_not_undef_splat_vec(
; CHECK-NEXT:    [[TMP1:%.*]] = icmp eq <2 x i8> %x, zeroinitializer
; CHECK-NEXT:    [[SH:%.*]] = zext <2 x i1> [[TMP1]] to <2 x i8>
; CHECK-NEXT:    ret <2 x i8> [[SH]]
;
  %ct = call <2 x i8> @llvm.ctlz.v2i8(<2 x i8> %x, i1 false)
  %sh = lshr <2 x i8> %ct, <i8 3, i8 3>
  ret <2 x i8> %sh
}

define <2 x i8> @lshr_cttz_zero_is_not_undef_splat_vec(<2 x i8> %x) {
; CHECK-LABEL: @lshr_cttz_zero_is_not_undef_splat_vec(
; CHECK-NEXT:    [[TMP1:%.*]] = icmp eq <2 x i8> %x, zeroinitializer
; CHECK-NEXT:    [[SH:%.*]] = zext <2 x i1> [[TMP1]] to <2 x i8>
; CHECK-NEXT:    ret <2 x i8> [[SH]]
;
  %ct = call <2 x i8> @llvm.cttz.v2i8(<2 x i8> %x, i1 false)
  %sh = lshr <2 x i8> %ct, <i8 3, i8 3>
  ret <2 x i8> %sh
}

define <2 x i8> @lshr_ctpop_splat_vec(<2 x i8> %x) {
; CHECK-LABEL: @lshr_ctpop_splat_vec(
; CHECK-NEXT:    [[TMP1:%.*]] = icmp eq <2 x i8> %x, <i8 -1, i8 -1>
; CHECK-NEXT:    [[SH:%.*]] = zext <2 x i1> [[TMP1]] to <2 x i8>
; CHECK-NEXT:    ret <2 x i8> [[SH]]
;
  %ct = call <2 x i8> @llvm.ctpop.v2i8(<2 x i8> %x)
  %sh = lshr <2 x i8> %ct, <i8 3, i8 3>
  ret <2 x i8> %sh
}

define i8 @lshr_exact(i8 %x) {
; CHECK-LABEL: @lshr_exact(
; CHECK-NEXT:    [[SHL:%.*]] = shl i8 %x, 2
; CHECK-NEXT:    [[ADD:%.*]] = add i8 [[SHL]], 4
; CHECK-NEXT:    [[LSHR:%.*]] = lshr exact i8 [[ADD]], 2
; CHECK-NEXT:    ret i8 [[LSHR]]
;
  %shl = shl i8 %x, 2
  %add = add i8 %shl, 4
  %lshr = lshr i8 %add, 2
  ret i8 %lshr
}

define <2 x i8> @lshr_exact_splat_vec(<2 x i8> %x) {
; CHECK-LABEL: @lshr_exact_splat_vec(
; CHECK-NEXT:    [[SHL:%.*]] = shl <2 x i8> %x, <i8 2, i8 2>
; CHECK-NEXT:    [[ADD:%.*]] = add <2 x i8> [[SHL]], <i8 4, i8 4>
; CHECK-NEXT:    [[LSHR:%.*]] = lshr exact <2 x i8> [[ADD]], <i8 2, i8 2>
; CHECK-NEXT:    ret <2 x i8> [[LSHR]]
;
  %shl = shl <2 x i8> %x, <i8 2, i8 2>
  %add = add <2 x i8> %shl, <i8 4, i8 4>
  %lshr = lshr <2 x i8> %add, <i8 2, i8 2>
  ret <2 x i8> %lshr
}


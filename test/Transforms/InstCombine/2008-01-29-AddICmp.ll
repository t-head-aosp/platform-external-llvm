; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; RUN: opt < %s -instcombine -S | FileCheck %s

; PR1949

define i1 @test1(i32 %a) {
; CHECK-LABEL: @test1(
; CHECK-NEXT:    [[C:%.*]] = icmp ugt i32 %a, -5
; CHECK-NEXT:    ret i1 [[C]]
;
  %b = add i32 %a, 4
  %c = icmp ult i32 %b, 4
  ret i1 %c
}

define <2 x i1> @test1vec(<2 x i32> %a) {
; CHECK-LABEL: @test1vec(
; CHECK-NEXT:    [[C:%.*]] = icmp ugt <2 x i32> %a, <i32 -5, i32 -5>
; CHECK-NEXT:    ret <2 x i1> [[C]]
;
  %b = add <2 x i32> %a, <i32 4, i32 4>
  %c = icmp ult <2 x i32> %b, <i32 4, i32 4>
  ret <2 x i1> %c
}

define i1 @test2(i32 %a) {
; CHECK-LABEL: @test2(
; CHECK-NEXT:    [[C:%.*]] = icmp ult i32 %a, 4
; CHECK-NEXT:    ret i1 [[C]]
;
  %b = sub i32 %a, 4
  %c = icmp ugt i32 %b, -5
  ret i1 %c
}

define <2 x i1> @test2vec(<2 x i32> %a) {
; CHECK-LABEL: @test2vec(
; CHECK-NEXT:    [[C:%.*]] = icmp ult <2 x i32> %a, <i32 4, i32 4>
; CHECK-NEXT:    ret <2 x i1> [[C]]
;
  %b = sub <2 x i32> %a, <i32 4, i32 4>
  %c = icmp ugt <2 x i32> %b, <i32 -5, i32 -5>
  ret <2 x i1> %c
}

define i1 @test3(i32 %a) {
; CHECK-LABEL: @test3(
; CHECK-NEXT:    [[C:%.*]] = icmp sgt i32 %a, 2147483643
; CHECK-NEXT:    ret i1 [[C]]
;
  %b = add i32 %a, 4
  %c = icmp slt i32 %b, 2147483652
  ret i1 %c
}

define <2 x i1> @test3vec(<2 x i32> %a) {
; CHECK-LABEL: @test3vec(
; CHECK-NEXT:    [[C:%.*]] = icmp sgt <2 x i32> %a, <i32 2147483643, i32 2147483643>
; CHECK-NEXT:    ret <2 x i1> [[C]]
;
  %b = add <2 x i32> %a, <i32 4, i32 4>
  %c = icmp slt <2 x i32> %b, <i32 2147483652, i32 2147483652>
  ret <2 x i1> %c
}

define i1 @test4(i32 %a) {
; CHECK-LABEL: @test4(
; CHECK-NEXT:    [[C:%.*]] = icmp slt i32 %a, -4
; CHECK-NEXT:    ret i1 [[C]]
;
  %b = add i32 %a, 2147483652
  %c = icmp sge i32 %b, 4
  ret i1 %c
}

define <2 x i1> @test4vec(<2 x i32> %a) {
; CHECK-LABEL: @test4vec(
; CHECK-NEXT:    [[C:%.*]] = icmp slt <2 x i32> %a, <i32 -4, i32 -4>
; CHECK-NEXT:    ret <2 x i1> [[C]]
;
  %b = add <2 x i32> %a, <i32 2147483652, i32 2147483652>
  %c = icmp sge <2 x i32> %b, <i32 4, i32 4>
  ret <2 x i1> %c
}


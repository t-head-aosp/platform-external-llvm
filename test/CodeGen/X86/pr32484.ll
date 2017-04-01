; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc -O0 -mtriple=x86_64-unknown-linux-gnu < %s | FileCheck %s

define void @foo() {
; CHECK-LABEL: foo:
; CHECK:       # BB#0:
; CHECK-NEXT:    # implicit-def: %RAX
; CHECK-NEXT:    jmpq *%rax
; CHECK-NEXT:  .LBB0_1:
; CHECK-NEXT:    # implicit-def: %RAX
; CHECK-NEXT:    xorps %xmm0, %xmm0
; CHECK-NEXT:    pcmpeqd %xmm1, %xmm1
; CHECK-NEXT:    movdqu %xmm1, (%rax)
; CHECK-NEXT:    movaps %xmm0, -{{[0-9]+}}(%rsp) # 16-byte Spill
; CHECK-NEXT:  .LBB0_2:
; CHECK-NEXT:    retq
  indirectbr i8* undef, [label %9, label %1]

; <label>:1:                                      ; preds = %0
  %2 = shufflevector <16 x i8> zeroinitializer, <16 x i8> <i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef>, <16 x i32> <i32 8, i32 9, i32 10, i32 11, i32 12, i32 13, i32 14, i32 15, i32 16, i32 17, i32 18, i32 19, i32 20, i32 21, i32 22, i32 23>
  %3 = shufflevector <16 x i8> <i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0>, <16 x i8> zeroinitializer, <16 x i32> <i32 8, i32 9, i32 10, i32 11, i32 12, i32 13, i32 14, i32 15, i32 16, i32 17, i32 18, i32 19, i32 20, i32 21, i32 22, i32 23>
  %4 = or <16 x i8> %3, %2
  %5 = shufflevector <16 x i8> %4, <16 x i8> undef, <16 x i32> <i32 8, i32 5, i32 1, i32 13, i32 15, i32 10, i32 14, i32 0, i32 3, i32 2, i32 7, i32 4, i32 6, i32 9, i32 11, i32 12>
  %6 = bitcast <16 x i8> %5 to <2 x i64>
  %7 = xor <2 x i64> %6, zeroinitializer
  %8 = xor <2 x i64> %7, <i64 -1, i64 -1>
  store <2 x i64> %8, <2 x i64>* undef, align 1
  unreachable

; <label>:9:                                      ; preds = %0
  ret void
}

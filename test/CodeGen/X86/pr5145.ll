; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc -mtriple=x86_64-- < %s | FileCheck %s
@sc8 = external global i8

define void @atomic_maxmin_i8() {
; CHECK-LABEL: atomic_maxmin_i8:
; CHECK:       # %bb.0:
; CHECK-NEXT:    movb {{.*}}(%rip), %al
; CHECK-NEXT:    .p2align 4, 0x90
; CHECK-NEXT:  .LBB0_1: # %atomicrmw.start
; CHECK-NEXT:    # =>This Inner Loop Header: Depth=1
; CHECK-NEXT:    cmpb $4, %al
; CHECK-NEXT:    movl %eax, %ecx
; CHECK-NEXT:    jg .LBB0_3
; CHECK-NEXT:  # %bb.2: # %atomicrmw.start
; CHECK-NEXT:    # in Loop: Header=BB0_1 Depth=1
; CHECK-NEXT:    movb $5, %cl
; CHECK-NEXT:  .LBB0_3: # %atomicrmw.start
; CHECK-NEXT:    # in Loop: Header=BB0_1 Depth=1
; CHECK-NEXT:    lock cmpxchgb %cl, {{.*}}(%rip)
; CHECK-NEXT:    jne .LBB0_1
; CHECK-NEXT:  # %bb.4: # %atomicrmw.end
; CHECK-NEXT:    movb {{.*}}(%rip), %al
; CHECK-NEXT:    .p2align 4, 0x90
; CHECK-NEXT:  .LBB0_5: # %atomicrmw.start2
; CHECK-NEXT:    # =>This Inner Loop Header: Depth=1
; CHECK-NEXT:    cmpb $7, %al
; CHECK-NEXT:    movl %eax, %ecx
; CHECK-NEXT:    jl .LBB0_7
; CHECK-NEXT:  # %bb.6: # %atomicrmw.start2
; CHECK-NEXT:    # in Loop: Header=BB0_5 Depth=1
; CHECK-NEXT:    movb $6, %cl
; CHECK-NEXT:  .LBB0_7: # %atomicrmw.start2
; CHECK-NEXT:    # in Loop: Header=BB0_5 Depth=1
; CHECK-NEXT:    lock cmpxchgb %cl, {{.*}}(%rip)
; CHECK-NEXT:    jne .LBB0_5
; CHECK-NEXT:  # %bb.8: # %atomicrmw.end1
; CHECK-NEXT:    movb {{.*}}(%rip), %al
; CHECK-NEXT:    .p2align 4, 0x90
; CHECK-NEXT:  .LBB0_9: # %atomicrmw.start8
; CHECK-NEXT:    # =>This Inner Loop Header: Depth=1
; CHECK-NEXT:    cmpb $7, %al
; CHECK-NEXT:    movl %eax, %ecx
; CHECK-NEXT:    ja .LBB0_11
; CHECK-NEXT:  # %bb.10: # %atomicrmw.start8
; CHECK-NEXT:    # in Loop: Header=BB0_9 Depth=1
; CHECK-NEXT:    movb $7, %cl
; CHECK-NEXT:  .LBB0_11: # %atomicrmw.start8
; CHECK-NEXT:    # in Loop: Header=BB0_9 Depth=1
; CHECK-NEXT:    lock cmpxchgb %cl, {{.*}}(%rip)
; CHECK-NEXT:    jne .LBB0_9
; CHECK-NEXT:  # %bb.12: # %atomicrmw.end7
; CHECK-NEXT:    movb {{.*}}(%rip), %al
; CHECK-NEXT:    .p2align 4, 0x90
; CHECK-NEXT:  .LBB0_13: # %atomicrmw.start14
; CHECK-NEXT:    # =>This Inner Loop Header: Depth=1
; CHECK-NEXT:    cmpb $9, %al
; CHECK-NEXT:    movl %eax, %ecx
; CHECK-NEXT:    jb .LBB0_15
; CHECK-NEXT:  # %bb.14: # %atomicrmw.start14
; CHECK-NEXT:    # in Loop: Header=BB0_13 Depth=1
; CHECK-NEXT:    movb $8, %cl
; CHECK-NEXT:  .LBB0_15: # %atomicrmw.start14
; CHECK-NEXT:    # in Loop: Header=BB0_13 Depth=1
; CHECK-NEXT:    lock cmpxchgb %cl, {{.*}}(%rip)
; CHECK-NEXT:    jne .LBB0_13
; CHECK-NEXT:  # %bb.16: # %atomicrmw.end13
; CHECK-NEXT:    retq
  %1 = atomicrmw max  i8* @sc8, i8 5 acquire
  %2 = atomicrmw min  i8* @sc8, i8 6 acquire
  %3 = atomicrmw umax i8* @sc8, i8 7 acquire
  %4 = atomicrmw umin i8* @sc8, i8 8 acquire
  ret void
}

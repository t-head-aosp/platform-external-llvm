; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc < %s -mtriple=i686-linux   -mcpu=core2 -mattr=+sse2 | FileCheck %s --check-prefix=X32
; RUN: llc < %s -mtriple=x86_64-linux -mcpu=core2 -mattr=+sse2 | FileCheck %s --check-prefix=X64
; RUN: llc < %s -mtriple=x86_64-linux-gnux32 -mcpu=core2 -mattr=+sse2  | FileCheck %s --check-prefix=X32ABI

define void @t1(i32 %x) nounwind ssp {
; X32-LABEL: t1:
; X32:       # %bb.0:
; X32-NEXT:    jmp foo # TAILCALL
;
; X64-LABEL: t1:
; X64:       # %bb.0:
; X64-NEXT:    jmp foo # TAILCALL
;
; X32ABI-LABEL: t1:
; X32ABI:       # %bb.0:
; X32ABI-NEXT:    jmp foo # TAILCALL
  tail call void @foo() nounwind
  ret void
}

declare void @foo()

define void @t2() nounwind ssp {
; X32-LABEL: t2:
; X32:       # %bb.0:
; X32-NEXT:    jmp foo2 # TAILCALL
;
; X64-LABEL: t2:
; X64:       # %bb.0:
; X64-NEXT:    jmp foo2 # TAILCALL
;
; X32ABI-LABEL: t2:
; X32ABI:       # %bb.0:
; X32ABI-NEXT:    jmp foo2 # TAILCALL
  %t0 = tail call i32 @foo2() nounwind
  ret void
}

declare i32 @foo2()

define void @t3() nounwind ssp {
; X32-LABEL: t3:
; X32:       # %bb.0:
; X32-NEXT:    jmp foo3 # TAILCALL
;
; X64-LABEL: t3:
; X64:       # %bb.0:
; X64-NEXT:    jmp foo3 # TAILCALL
;
; X32ABI-LABEL: t3:
; X32ABI:       # %bb.0:
; X32ABI-NEXT:    jmp foo3 # TAILCALL
  %t0 = tail call i32 @foo3() nounwind
  ret void
}

declare i32 @foo3()

define void @t4(void (i32)* nocapture %x) nounwind ssp {
; X32-LABEL: t4:
; X32:       # %bb.0:
; X32-NEXT:    subl $12, %esp
; X32-NEXT:    movl $0, (%esp)
; X32-NEXT:    calll *{{[0-9]+}}(%esp)
; X32-NEXT:    addl $12, %esp
; X32-NEXT:    retl
;
; X64-LABEL: t4:
; X64:       # %bb.0:
; X64-NEXT:    movq %rdi, %rax
; X64-NEXT:    xorl %edi, %edi
; X64-NEXT:    jmpq *%rax # TAILCALL
;
; X32ABI-LABEL: t4:
; X32ABI:       # %bb.0:
; X32ABI-NEXT:    movl %edi, %eax
; X32ABI-NEXT:    xorl %edi, %edi
; X32ABI-NEXT:    jmpq *%rax # TAILCALL
  tail call void %x(i32 0) nounwind
  ret void
}

; FIXME: This isn't needed since x32 psABI specifies that callers must
;        zero-extend pointers passed in registers.

define void @t5(void ()* nocapture %x) nounwind ssp {
; X32-LABEL: t5:
; X32:       # %bb.0:
; X32-NEXT:    jmpl *{{[0-9]+}}(%esp) # TAILCALL
;
; X64-LABEL: t5:
; X64:       # %bb.0:
; X64-NEXT:    jmpq *%rdi # TAILCALL
;
; X32ABI-LABEL: t5:
; X32ABI:       # %bb.0:
; X32ABI-NEXT:    movl %edi, %eax
; X32ABI-NEXT:    jmpq *%rax # TAILCALL
  tail call void %x() nounwind
  ret void
}

define i32 @t6(i32 %x) nounwind ssp {
; X32-LABEL: t6:
; X32:       # %bb.0:
; X32-NEXT:    subl $12, %esp
; X32-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X32-NEXT:    cmpl $9, %eax
; X32-NEXT:    jg .LBB5_2
; X32-NEXT:  # %bb.1: # %bb
; X32-NEXT:    decl %eax
; X32-NEXT:    movl %eax, (%esp)
; X32-NEXT:    calll t6
; X32-NEXT:    addl $12, %esp
; X32-NEXT:    retl
; X32-NEXT:  .LBB5_2: # %bb1
; X32-NEXT:    addl $12, %esp
; X32-NEXT:    jmp bar # TAILCALL
;
; X64-LABEL: t6:
; X64:       # %bb.0:
; X64-NEXT:    cmpl $9, %edi
; X64-NEXT:    jg .LBB5_2
; X64-NEXT:  # %bb.1: # %bb
; X64-NEXT:    decl %edi
; X64-NEXT:    jmp t6 # TAILCALL
; X64-NEXT:  .LBB5_2: # %bb1
; X64-NEXT:    jmp bar # TAILCALL
;
; X32ABI-LABEL: t6:
; X32ABI:       # %bb.0:
; X32ABI-NEXT:    cmpl $9, %edi
; X32ABI-NEXT:    jg .LBB5_2
; X32ABI-NEXT:  # %bb.1: # %bb
; X32ABI-NEXT:    decl %edi
; X32ABI-NEXT:    jmp t6 # TAILCALL
; X32ABI-NEXT:  .LBB5_2: # %bb1
; X32ABI-NEXT:    jmp bar # TAILCALL
  %t0 = icmp slt i32 %x, 10
  br i1 %t0, label %bb, label %bb1

bb:
  %t1 = add nsw i32 %x, -1
  %t2 = tail call i32 @t6(i32 %t1) nounwind ssp
  ret i32 %t2

bb1:
  %t3 = tail call i32 @bar(i32 %x) nounwind
  ret i32 %t3
}

declare i32 @bar(i32)

define i32 @t7(i32 %a, i32 %b, i32 %c) nounwind ssp {
; X32-LABEL: t7:
; X32:       # %bb.0:
; X32-NEXT:    jmp bar2 # TAILCALL
;
; X64-LABEL: t7:
; X64:       # %bb.0:
; X64-NEXT:    jmp bar2 # TAILCALL
;
; X32ABI-LABEL: t7:
; X32ABI:       # %bb.0:
; X32ABI-NEXT:    jmp bar2 # TAILCALL
  %t0 = tail call i32 @bar2(i32 %a, i32 %b, i32 %c) nounwind
  ret i32 %t0
}

declare i32 @bar2(i32, i32, i32)

define signext i16 @t8() nounwind ssp {
; X32-LABEL: t8:
; X32:       # %bb.0: # %entry
; X32-NEXT:    jmp bar3 # TAILCALL
;
; X64-LABEL: t8:
; X64:       # %bb.0: # %entry
; X64-NEXT:    jmp bar3 # TAILCALL
;
; X32ABI-LABEL: t8:
; X32ABI:       # %bb.0: # %entry
; X32ABI-NEXT:    jmp bar3 # TAILCALL
entry:
  %0 = tail call signext i16 @bar3() nounwind      ; <i16> [#uses=1]
  ret i16 %0
}

declare signext i16 @bar3()

define signext i16 @t9(i32 (i32)* nocapture %x) nounwind ssp {
; X32-LABEL: t9:
; X32:       # %bb.0: # %entry
; X32-NEXT:    subl $12, %esp
; X32-NEXT:    movl $0, (%esp)
; X32-NEXT:    calll *{{[0-9]+}}(%esp)
; X32-NEXT:    addl $12, %esp
; X32-NEXT:    retl
;
; X64-LABEL: t9:
; X64:       # %bb.0: # %entry
; X64-NEXT:    movq %rdi, %rax
; X64-NEXT:    xorl %edi, %edi
; X64-NEXT:    jmpq *%rax # TAILCALL
;
; X32ABI-LABEL: t9:
; X32ABI:       # %bb.0: # %entry
; X32ABI-NEXT:    movl %edi, %eax
; X32ABI-NEXT:    xorl %edi, %edi
; X32ABI-NEXT:    jmpq *%rax # TAILCALL
entry:
  %0 = bitcast i32 (i32)* %x to i16 (i32)*
  %1 = tail call signext i16 %0(i32 0) nounwind
  ret i16 %1
}

define void @t10() nounwind ssp {
; X32-LABEL: t10:
; X32:       # %bb.0: # %entry
; X32-NEXT:    subl $12, %esp
; X32-NEXT:    calll foo4
;
; X64-LABEL: t10:
; X64:       # %bb.0: # %entry
; X64-NEXT:    pushq %rax
; X64-NEXT:    callq foo4
;
; X32ABI-LABEL: t10:
; X32ABI:       # %bb.0: # %entry
; X32ABI-NEXT:    pushq %rax
; X32ABI-NEXT:    callq foo4
entry:
  %0 = tail call i32 @foo4() noreturn nounwind
  unreachable
}

declare i32 @foo4()

; In 32-bit mode, it's emitting a bunch of dead loads that are not being
; eliminated currently.

define i32 @t11(i32 %x, i32 %y, i32 %z.0, i32 %z.1, i32 %z.2) nounwind ssp {
; X32-LABEL: t11:
; X32:       # %bb.0: # %entry
; X32-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X32-NEXT:    testl %eax, %eax
; X32-NEXT:    je .LBB10_1
; X32-NEXT:  # %bb.2: # %bb
; X32-NEXT:    jmp foo5 # TAILCALL
; X32-NEXT:  .LBB10_1: # %bb6
; X32-NEXT:    xorl %eax, %eax
; X32-NEXT:    retl
;
; X64-LABEL: t11:
; X64:       # %bb.0: # %entry
; X64-NEXT:    testl %edi, %edi
; X64-NEXT:    je .LBB10_1
; X64-NEXT:  # %bb.2: # %bb
; X64-NEXT:    jmp foo5 # TAILCALL
; X64-NEXT:  .LBB10_1: # %bb6
; X64-NEXT:    xorl %eax, %eax
; X64-NEXT:    retq
;
; X32ABI-LABEL: t11:
; X32ABI:       # %bb.0: # %entry
; X32ABI-NEXT:    testl %edi, %edi
; X32ABI-NEXT:    je .LBB10_1
; X32ABI-NEXT:  # %bb.2: # %bb
; X32ABI-NEXT:    jmp foo5 # TAILCALL
; X32ABI-NEXT:  .LBB10_1: # %bb6
; X32ABI-NEXT:    xorl %eax, %eax
; X32ABI-NEXT:    retq
entry:
  %0 = icmp eq i32 %x, 0
  br i1 %0, label %bb6, label %bb

bb:
  %1 = tail call i32 @foo5(i32 %x, i32 %y, i32 %z.0, i32 %z.1, i32 %z.2) nounwind
  ret i32 %1

bb6:
  ret i32 0
}

declare i32 @foo5(i32, i32, i32, i32, i32)

%struct.t = type { i32, i32, i32, i32, i32 }

define i32 @t12(i32 %x, i32 %y, %struct.t* byval align 4 %z) nounwind ssp {
; X32-LABEL: t12:
; X32:       # %bb.0: # %entry
; X32-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X32-NEXT:    testl %eax, %eax
; X32-NEXT:    je .LBB11_1
; X32-NEXT:  # %bb.2: # %bb
; X32-NEXT:    jmp foo6 # TAILCALL
; X32-NEXT:  .LBB11_1: # %bb2
; X32-NEXT:    xorl %eax, %eax
; X32-NEXT:    retl
;
; X64-LABEL: t12:
; X64:       # %bb.0: # %entry
; X64-NEXT:    testl %edi, %edi
; X64-NEXT:    je .LBB11_1
; X64-NEXT:  # %bb.2: # %bb
; X64-NEXT:    jmp foo6 # TAILCALL
; X64-NEXT:  .LBB11_1: # %bb2
; X64-NEXT:    xorl %eax, %eax
; X64-NEXT:    retq
;
; X32ABI-LABEL: t12:
; X32ABI:       # %bb.0: # %entry
; X32ABI-NEXT:    testl %edi, %edi
; X32ABI-NEXT:    je .LBB11_1
; X32ABI-NEXT:  # %bb.2: # %bb
; X32ABI-NEXT:    jmp foo6 # TAILCALL
; X32ABI-NEXT:  .LBB11_1: # %bb2
; X32ABI-NEXT:    xorl %eax, %eax
; X32ABI-NEXT:    retq
entry:
  %0 = icmp eq i32 %x, 0
  br i1 %0, label %bb2, label %bb

bb:
  %1 = tail call i32 @foo6(i32 %x, i32 %y, %struct.t* byval align 4 %z) nounwind
  ret i32 %1

bb2:
  ret i32 0
}

declare i32 @foo6(i32, i32, %struct.t* byval align 4)

; rdar://r7717598
%struct.ns = type { i32, i32 }
%struct.cp = type { float, float, float, float, float }

define %struct.ns* @t13(%struct.cp* %yy) nounwind ssp {
; X32-LABEL: t13:
; X32:       # %bb.0: # %entry
; X32-NEXT:    subl $28, %esp
; X32-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X32-NEXT:    movl 16(%eax), %ecx
; X32-NEXT:    movl %ecx, {{[0-9]+}}(%esp)
; X32-NEXT:    movsd {{.*#+}} xmm0 = mem[0],zero
; X32-NEXT:    movsd {{.*#+}} xmm1 = mem[0],zero
; X32-NEXT:    movsd %xmm1, {{[0-9]+}}(%esp)
; X32-NEXT:    movsd %xmm0, (%esp)
; X32-NEXT:    xorl %ecx, %ecx
; X32-NEXT:    calll foo7
; X32-NEXT:    addl $28, %esp
; X32-NEXT:    retl
;
; X64-LABEL: t13:
; X64:       # %bb.0: # %entry
; X64-NEXT:    pushq %rax
; X64-NEXT:    subq $8, %rsp
; X64-NEXT:    movl 16(%rdi), %eax
; X64-NEXT:    movq (%rdi), %rcx
; X64-NEXT:    movq 8(%rdi), %rdx
; X64-NEXT:    xorl %edi, %edi
; X64-NEXT:    pushq %rax
; X64-NEXT:    pushq %rdx
; X64-NEXT:    pushq %rcx
; X64-NEXT:    callq foo7
; X64-NEXT:    addq $32, %rsp
; X64-NEXT:    popq %rcx
; X64-NEXT:    retq
;
; X32ABI-LABEL: t13:
; X32ABI:       # %bb.0: # %entry
; X32ABI-NEXT:    pushq %rax
; X32ABI-NEXT:    subl $8, %esp
; X32ABI-NEXT:    movl 16(%edi), %eax
; X32ABI-NEXT:    movq (%edi), %rcx
; X32ABI-NEXT:    movq 8(%edi), %rdx
; X32ABI-NEXT:    xorl %edi, %edi
; X32ABI-NEXT:    pushq %rax
; X32ABI-NEXT:    pushq %rdx
; X32ABI-NEXT:    pushq %rcx
; X32ABI-NEXT:    callq foo7
; X32ABI-NEXT:    addl $32, %esp
; X32ABI-NEXT:    popq %rcx
; X32ABI-NEXT:    retq
entry:
  %0 = tail call fastcc %struct.ns* @foo7(%struct.cp* byval align 4 %yy, i8 signext 0) nounwind
  ret %struct.ns* %0
}

; rdar://6195379
; llvm can't do sibcall for this in 32-bit mode (yet).
declare fastcc %struct.ns* @foo7(%struct.cp* byval align 4, i8 signext) nounwind ssp

%struct.__block_descriptor = type { i64, i64 }
%struct.__block_descriptor_withcopydispose = type { i64, i64, i8*, i8* }
%struct.__block_literal_1 = type { i8*, i32, i32, i8*, %struct.__block_descriptor* }
%struct.__block_literal_2 = type { i8*, i32, i32, i8*, %struct.__block_descriptor_withcopydispose*, void ()* }

define void @t14(%struct.__block_literal_2* nocapture %.block_descriptor) nounwind ssp {
; X32-LABEL: t14:
; X32:       # %bb.0: # %entry
; X32-NEXT:    subl $12, %esp
; X32-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X32-NEXT:    movl 20(%eax), %eax
; X32-NEXT:    movl %eax, (%esp)
; X32-NEXT:    calll *12(%eax)
; X32-NEXT:    addl $12, %esp
; X32-NEXT:    retl
;
; X64-LABEL: t14:
; X64:       # %bb.0: # %entry
; X64-NEXT:    movq 32(%rdi), %rdi
; X64-NEXT:    jmpq *16(%rdi) # TAILCALL
;
; X32ABI-LABEL: t14:
; X32ABI:       # %bb.0: # %entry
; X32ABI-NEXT:    movl 20(%edi), %edi
; X32ABI-NEXT:    movl 12(%edi), %eax
; X32ABI-NEXT:    jmpq *%rax # TAILCALL
entry:
  %0 = getelementptr inbounds %struct.__block_literal_2, %struct.__block_literal_2* %.block_descriptor, i64 0, i32 5 ; <void ()**> [#uses=1]
  %1 = load void ()*, void ()** %0, align 8                 ; <void ()*> [#uses=2]
  %2 = bitcast void ()* %1 to %struct.__block_literal_1* ; <%struct.__block_literal_1*> [#uses=1]
  %3 = getelementptr inbounds %struct.__block_literal_1, %struct.__block_literal_1* %2, i64 0, i32 3 ; <i8**> [#uses=1]
  %4 = load i8*, i8** %3, align 8                      ; <i8*> [#uses=1]
  %5 = bitcast i8* %4 to void (i8*)*              ; <void (i8*)*> [#uses=1]
  %6 = bitcast void ()* %1 to i8*                 ; <i8*> [#uses=1]
  tail call void %5(i8* %6) nounwind
  ret void
}

; rdar://7726868
%struct.foo = type { [4 x i32] }

define void @t15(%struct.foo* noalias sret %agg.result) nounwind  {
; X32-LABEL: t15:
; X32:       # %bb.0:
; X32-NEXT:    pushl %esi
; X32-NEXT:    subl $8, %esp
; X32-NEXT:    movl {{[0-9]+}}(%esp), %esi
; X32-NEXT:    movl %esi, %ecx
; X32-NEXT:    calll f
; X32-NEXT:    movl %esi, %eax
; X32-NEXT:    addl $8, %esp
; X32-NEXT:    popl %esi
; X32-NEXT:    retl $4
;
; X64-LABEL: t15:
; X64:       # %bb.0:
; X64-NEXT:    pushq %rbx
; X64-NEXT:    movq %rdi, %rbx
; X64-NEXT:    callq f
; X64-NEXT:    movq %rbx, %rax
; X64-NEXT:    popq %rbx
; X64-NEXT:    retq
;
; X32ABI-LABEL: t15:
; X32ABI:       # %bb.0:
; X32ABI-NEXT:    pushq %rbx
; X32ABI-NEXT:    movl %edi, %ebx
; X32ABI-NEXT:    callq f
; X32ABI-NEXT:    movl %ebx, %eax
; X32ABI-NEXT:    popq %rbx
; X32ABI-NEXT:    retq
  tail call fastcc void @f(%struct.foo* noalias sret %agg.result) nounwind
  ret void
}

declare void @f(%struct.foo* noalias sret) nounwind

define void @t16() nounwind ssp {
; X32-LABEL: t16:
; X32:       # %bb.0: # %entry
; X32-NEXT:    subl $12, %esp
; X32-NEXT:    calll bar4
; X32-NEXT:    fstp %st(0)
; X32-NEXT:    addl $12, %esp
; X32-NEXT:    retl
;
; X64-LABEL: t16:
; X64:       # %bb.0: # %entry
; X64-NEXT:    jmp bar4 # TAILCALL
;
; X32ABI-LABEL: t16:
; X32ABI:       # %bb.0: # %entry
; X32ABI-NEXT:    jmp bar4 # TAILCALL
entry:
  %0 = tail call double @bar4() nounwind
  ret void
}

declare double @bar4()

; rdar://6283267
define void @t17() nounwind ssp {
; X32-LABEL: t17:
; X32:       # %bb.0: # %entry
; X32-NEXT:    jmp bar5 # TAILCALL
;
; X64-LABEL: t17:
; X64:       # %bb.0: # %entry
; X64-NEXT:    xorl %eax, %eax
; X64-NEXT:    jmp bar5 # TAILCALL
;
; X32ABI-LABEL: t17:
; X32ABI:       # %bb.0: # %entry
; X32ABI-NEXT:    xorl %eax, %eax
; X32ABI-NEXT:    jmp bar5 # TAILCALL
entry:
  tail call void (...) @bar5() nounwind
  ret void
}

declare void @bar5(...)

; rdar://7774847
define void @t18() nounwind ssp {
; X32-LABEL: t18:
; X32:       # %bb.0: # %entry
; X32-NEXT:    subl $12, %esp
; X32-NEXT:    calll bar6
; X32-NEXT:    fstp %st(0)
; X32-NEXT:    addl $12, %esp
; X32-NEXT:    retl
;
; X64-LABEL: t18:
; X64:       # %bb.0: # %entry
; X64-NEXT:    xorl %eax, %eax
; X64-NEXT:    jmp bar6 # TAILCALL
;
; X32ABI-LABEL: t18:
; X32ABI:       # %bb.0: # %entry
; X32ABI-NEXT:    xorl %eax, %eax
; X32ABI-NEXT:    jmp bar6 # TAILCALL
entry:
  %0 = tail call double (...) @bar6() nounwind
  ret void
}

declare double @bar6(...)

define void @t19() alignstack(32) nounwind {
; X32-LABEL: t19:
; X32:       # %bb.0: # %entry
; X32-NEXT:    pushl %ebp
; X32-NEXT:    movl %esp, %ebp
; X32-NEXT:    andl $-32, %esp
; X32-NEXT:    subl $32, %esp
; X32-NEXT:    calll foo
; X32-NEXT:    movl %ebp, %esp
; X32-NEXT:    popl %ebp
; X32-NEXT:    retl
;
; X64-LABEL: t19:
; X64:       # %bb.0: # %entry
; X64-NEXT:    pushq %rbp
; X64-NEXT:    movq %rsp, %rbp
; X64-NEXT:    andq $-32, %rsp
; X64-NEXT:    subq $32, %rsp
; X64-NEXT:    callq foo
; X64-NEXT:    movq %rbp, %rsp
; X64-NEXT:    popq %rbp
; X64-NEXT:    retq
;
; X32ABI-LABEL: t19:
; X32ABI:       # %bb.0: # %entry
; X32ABI-NEXT:    pushq %rbp
; X32ABI-NEXT:    movl %esp, %ebp
; X32ABI-NEXT:    andl $-32, %esp
; X32ABI-NEXT:    subl $32, %esp
; X32ABI-NEXT:    callq foo
; X32ABI-NEXT:    movl %ebp, %esp
; X32ABI-NEXT:    popq %rbp
; X32ABI-NEXT:    retq
entry:
  tail call void @foo() nounwind
  ret void
}

; If caller / callee calling convention mismatch then check if the return
; values are returned in the same registers.
; rdar://7874780

define double @t20(double %x) nounwind {
; X32-LABEL: t20:
; X32:       # %bb.0: # %entry
; X32-NEXT:    subl $12, %esp
; X32-NEXT:    movsd {{.*#+}} xmm0 = mem[0],zero
; X32-NEXT:    calll foo20
; X32-NEXT:    movsd %xmm0, (%esp)
; X32-NEXT:    fldl (%esp)
; X32-NEXT:    addl $12, %esp
; X32-NEXT:    retl
;
; X64-LABEL: t20:
; X64:       # %bb.0: # %entry
; X64-NEXT:    jmp foo20 # TAILCALL
;
; X32ABI-LABEL: t20:
; X32ABI:       # %bb.0: # %entry
; X32ABI-NEXT:    jmp foo20 # TAILCALL
entry:
  %0 = tail call fastcc double @foo20(double %x) nounwind
  ret double %0
}

declare fastcc double @foo20(double) nounwind

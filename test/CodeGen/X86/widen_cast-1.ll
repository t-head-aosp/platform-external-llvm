; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc -mtriple=i686-unknown-unknown -mcpu=generic -mattr=+sse4.2 < %s | FileCheck %s
; RUN: llc -mtriple=i686-unknown-unknown -mcpu=atom < %s | FileCheck -check-prefix=ATOM %s

; Scheduler causes produce a different instruction order

; bitcast a v4i16 to v2i32

define void @convert(<2 x i32>* %dst, <4 x i16>* %src) nounwind {
; CHECK-LABEL: convert:
; CHECK:       # BB#0: # %entry
; CHECK-NEXT:    pushl %eax
; CHECK-NEXT:    movl $0, (%esp)
; CHECK-NEXT:    movdqa {{.*#+}} xmm0 = [1,1,1,1]
; CHECK-NEXT:    movdqa {{.*#+}} xmm1 = [0,1,4,5,8,9,12,13,8,9,12,13,12,13,14,15]
; CHECK-NEXT:    cmpl $3, (%esp)
; CHECK-NEXT:    jg .LBB0_3
; CHECK-NEXT:    .p2align 4, 0x90
; CHECK-NEXT:  .LBB0_2: # %forbody
; CHECK-NEXT:    # =>This Inner Loop Header: Depth=1
; CHECK-NEXT:    movl (%esp), %eax
; CHECK-NEXT:    movl {{[0-9]+}}(%esp), %ecx
; CHECK-NEXT:    movl {{[0-9]+}}(%esp), %edx
; CHECK-NEXT:    pmovzxwd {{.*#+}} xmm2 = mem[0],zero,mem[1],zero,mem[2],zero,mem[3],zero
; CHECK-NEXT:    paddw %xmm0, %xmm2
; CHECK-NEXT:    pshufb %xmm1, %xmm2
; CHECK-NEXT:    movq %xmm2, (%ecx,%eax,8)
; CHECK-NEXT:    incl (%esp)
; CHECK-NEXT:    cmpl $3, (%esp)
; CHECK-NEXT:    jle .LBB0_2
; CHECK-NEXT:  .LBB0_3: # %afterfor
; CHECK-NEXT:    popl %eax
; CHECK-NEXT:    retl
;
; ATOM-LABEL: convert:
; ATOM:       # BB#0: # %entry
; ATOM-NEXT:    pushl %eax
; ATOM-NEXT:    movdqa {{.*#+}} xmm0 = [1,1,1,1]
; ATOM-NEXT:    movdqa {{.*#+}} xmm1 = [0,1,4,5,8,9,12,13,8,9,12,13,12,13,14,15]
; ATOM-NEXT:    movl $0, (%esp)
; ATOM-NEXT:    cmpl $3, (%esp)
; ATOM-NEXT:    jg .LBB0_3
; ATOM-NEXT:    .p2align 4, 0x90
; ATOM-NEXT:  .LBB0_2: # %forbody
; ATOM-NEXT:    # =>This Inner Loop Header: Depth=1
; ATOM-NEXT:    movl (%esp), %eax
; ATOM-NEXT:    movl {{[0-9]+}}(%esp), %ecx
; ATOM-NEXT:    movq {{.*#+}} xmm2 = mem[0],zero
; ATOM-NEXT:    movl {{[0-9]+}}(%esp), %ecx
; ATOM-NEXT:    punpcklwd {{.*#+}} xmm2 = xmm2[0],xmm0[0],xmm2[1],xmm0[1],xmm2[2],xmm0[2],xmm2[3],xmm0[3]
; ATOM-NEXT:    paddw %xmm0, %xmm2
; ATOM-NEXT:    pshufb %xmm1, %xmm2
; ATOM-NEXT:    movq %xmm2, (%ecx,%eax,8)
; ATOM-NEXT:    incl (%esp)
; ATOM-NEXT:    cmpl $3, (%esp)
; ATOM-NEXT:    jle .LBB0_2
; ATOM-NEXT:  .LBB0_3: # %afterfor
; ATOM-NEXT:    popl %eax
; ATOM-NEXT:    retl
entry:
	%dst.addr = alloca <2 x i32>*
	%src.addr = alloca <4 x i16>*
	%i = alloca i32, align 4
	store <2 x i32>* %dst, <2 x i32>** %dst.addr
	store <4 x i16>* %src, <4 x i16>** %src.addr
	store i32 0, i32* %i
	br label %forcond

forcond:
	%tmp = load i32, i32* %i
	%cmp = icmp slt i32 %tmp, 4
	br i1 %cmp, label %forbody, label %afterfor

forbody:
	%tmp1 = load i32, i32* %i
	%tmp2 = load <2 x i32>*, <2 x i32>** %dst.addr
	%arrayidx = getelementptr <2 x i32>, <2 x i32>* %tmp2, i32 %tmp1
	%tmp3 = load i32, i32* %i
	%tmp4 = load <4 x i16>*, <4 x i16>** %src.addr
	%arrayidx5 = getelementptr <4 x i16>, <4 x i16>* %tmp4, i32 %tmp3
	%tmp6 = load <4 x i16>, <4 x i16>* %arrayidx5
	%add = add <4 x i16> %tmp6, < i16 1, i16 1, i16 1, i16 1 >
	%conv = bitcast <4 x i16> %add to <2 x i32>
	store <2 x i32> %conv, <2 x i32>* %arrayidx
	br label %forinc

forinc:
	%tmp7 = load i32, i32* %i
	%inc = add i32 %tmp7, 1
	store i32 %inc, i32* %i
	br label %forcond

afterfor:
	ret void
}

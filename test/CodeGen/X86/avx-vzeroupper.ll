; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc < %s -x86-use-vzeroupper -mtriple=x86_64-unknown-unknown -mattr=+avx | FileCheck %s --check-prefix=ALL --check-prefix=VZ --check-prefix=AVX
; RUN: llc < %s -x86-use-vzeroupper -mtriple=x86_64-unknown-unknown -mattr=+avx512f | FileCheck %s --check-prefix=ALL --check-prefix=VZ --check-prefix=AVX512
; RUN: llc < %s -x86-use-vzeroupper -mtriple=x86_64-unknown-unknown -mattr=+avx,+fast-partial-ymm-or-zmm-write | FileCheck %s --check-prefix=ALL --check-prefix=NO-VZ --check-prefix=FAST-YMM-ZMM
; RUN: llc < %s -x86-use-vzeroupper -mtriple=x86_64-unknown-unknown -mcpu=btver2 | FileCheck %s --check-prefix=ALL --check-prefix=NO-VZ --check-prefix=BTVER2

declare i32 @foo()
declare <4 x float> @do_sse(<4 x float>)
declare <8 x float> @do_avx(<8 x float>)
declare <4 x float> @llvm.x86.avx.vextractf128.ps.256(<8 x float>, i8) nounwind readnone
@x = common global <4 x float> zeroinitializer, align 16
@g = common global <8 x float> zeroinitializer, align 32

;; Basic checking - don't emit any vzeroupper instruction

define <4 x float> @test00(<4 x float> %a, <4 x float> %b) nounwind {
; ALL-LABEL: test00:
; ALL:       # BB#0:
; ALL-NEXT:    pushq %rax
; ALL-NEXT:    vaddps %xmm1, %xmm0, %xmm0
; ALL-NEXT:    callq do_sse
; ALL-NEXT:    popq %rax
; ALL-NEXT:    retq
  %add.i = fadd <4 x float> %a, %b
  %call3 = call <4 x float> @do_sse(<4 x float> %add.i) nounwind
  ret <4 x float> %call3
}

;; Check parameter 256-bit parameter passing

define <8 x float> @test01(<4 x float> %a, <4 x float> %b, <8 x float> %c) nounwind {
; VZ-LABEL: test01:
; VZ:       # BB#0:
; VZ-NEXT:    subq $56, %rsp
; VZ-NEXT:    vmovups %ymm2, (%rsp) # 32-byte Spill
; VZ-NEXT:    vmovaps {{.*}}(%rip), %xmm0
; VZ-NEXT:    vzeroupper
; VZ-NEXT:    callq do_sse
; VZ-NEXT:    vmovaps %xmm0, {{.*}}(%rip)
; VZ-NEXT:    callq do_sse
; VZ-NEXT:    vmovaps %xmm0, {{.*}}(%rip)
; VZ-NEXT:    vmovups (%rsp), %ymm0 # 32-byte Reload
; VZ-NEXT:    addq $56, %rsp
; VZ-NEXT:    retq
;
; FAST-YMM-ZMM-LABEL: test01:
; FAST-YMM-ZMM:       # BB#0:
; FAST-YMM-ZMM-NEXT:    subq $56, %rsp
; FAST-YMM-ZMM-NEXT:    vmovups %ymm2, (%rsp) # 32-byte Spill
; FAST-YMM-ZMM-NEXT:    vmovaps {{.*}}(%rip), %xmm0
; FAST-YMM-ZMM-NEXT:    callq do_sse
; FAST-YMM-ZMM-NEXT:    vmovaps %xmm0, {{.*}}(%rip)
; FAST-YMM-ZMM-NEXT:    callq do_sse
; FAST-YMM-ZMM-NEXT:    vmovaps %xmm0, {{.*}}(%rip)
; FAST-YMM-ZMM-NEXT:    vmovups (%rsp), %ymm0 # 32-byte Reload
; FAST-YMM-ZMM-NEXT:    addq $56, %rsp
; FAST-YMM-ZMM-NEXT:    retq
;
; BTVER2-LABEL: test01:
; BTVER2:       # BB#0:
; BTVER2-NEXT:    subq $56, %rsp
; BTVER2-NEXT:    vmovaps {{.*}}(%rip), %xmm0
; BTVER2-NEXT:    vmovups %ymm2, (%rsp) # 32-byte Spill
; BTVER2-NEXT:    callq do_sse
; BTVER2-NEXT:    vmovaps %xmm0, {{.*}}(%rip)
; BTVER2-NEXT:    callq do_sse
; BTVER2-NEXT:    vmovaps %xmm0, {{.*}}(%rip)
; BTVER2-NEXT:    vmovups (%rsp), %ymm0 # 32-byte Reload
; BTVER2-NEXT:    addq $56, %rsp
; BTVER2-NEXT:    retq
  %tmp = load <4 x float>, <4 x float>* @x, align 16
  %call = tail call <4 x float> @do_sse(<4 x float> %tmp) nounwind
  store <4 x float> %call, <4 x float>* @x, align 16
  %call2 = tail call <4 x float> @do_sse(<4 x float> %call) nounwind
  store <4 x float> %call2, <4 x float>* @x, align 16
  ret <8 x float> %c
}

;; Check that vzeroupper is emitted for tail calls.

define <4 x float> @test02(<8 x float> %a, <8 x float> %b) nounwind {
; VZ-LABEL: test02:
; VZ:       # BB#0:
; VZ-NEXT:    vaddps %ymm1, %ymm0, %ymm0
; VZ-NEXT:    # kill: %XMM0<def> %XMM0<kill> %YMM0<kill>
; VZ-NEXT:    vzeroupper
; VZ-NEXT:    jmp do_sse # TAILCALL
;
; NO-VZ-LABEL: test02:
; NO-VZ:       # BB#0:
; NO-VZ-NEXT:    vaddps %ymm1, %ymm0, %ymm0
; NO-VZ-NEXT:    # kill: %XMM0<def> %XMM0<kill> %YMM0<kill>
; NO-VZ-NEXT:    jmp do_sse # TAILCALL
  %add.i = fadd <8 x float> %a, %b
  %add.low = call <4 x float> @llvm.x86.avx.vextractf128.ps.256(<8 x float> %add.i, i8 0)
  %call3 = tail call <4 x float> @do_sse(<4 x float> %add.low) nounwind
  ret <4 x float> %call3
}

;; Test the pass convergence and also that vzeroupper is only issued when necessary,
;; for this function it should be only once

define <4 x float> @test03(<4 x float> %a, <4 x float> %b) nounwind {
; VZ-LABEL: test03:
; VZ:       # BB#0: # %entry
; VZ-NEXT:    pushq %rbx
; VZ-NEXT:    subq $16, %rsp
; VZ-NEXT:    vaddps %xmm1, %xmm0, %xmm0
; VZ-NEXT:    vmovaps %xmm0, (%rsp) # 16-byte Spill
; VZ-NEXT:    .p2align 4, 0x90
; VZ-NEXT:  .LBB3_1: # %while.cond
; VZ-NEXT:    # =>This Inner Loop Header: Depth=1
; VZ-NEXT:    callq foo
; VZ-NEXT:    testl %eax, %eax
; VZ-NEXT:    jne .LBB3_1
; VZ-NEXT:  # BB#2: # %for.body.preheader
; VZ-NEXT:    movl $4, %ebx
; VZ-NEXT:    vmovaps (%rsp), %xmm0 # 16-byte Reload
; VZ-NEXT:    .p2align 4, 0x90
; VZ-NEXT:  .LBB3_3: # %for.body
; VZ-NEXT:    # =>This Inner Loop Header: Depth=1
; VZ-NEXT:    callq do_sse
; VZ-NEXT:    callq do_sse
; VZ-NEXT:    vmovaps {{.*}}(%rip), %ymm0
; VZ-NEXT:    vextractf128 $1, %ymm0, %xmm0
; VZ-NEXT:    vzeroupper
; VZ-NEXT:    callq do_sse
; VZ-NEXT:    decl %ebx
; VZ-NEXT:    jne .LBB3_3
; VZ-NEXT:  # BB#4: # %for.end
; VZ-NEXT:    addq $16, %rsp
; VZ-NEXT:    popq %rbx
; VZ-NEXT:    retq
;
; FAST-YMM-ZMM-LABEL: test03:
; FAST-YMM-ZMM:       # BB#0: # %entry
; FAST-YMM-ZMM-NEXT:    pushq %rbx
; FAST-YMM-ZMM-NEXT:    subq $16, %rsp
; FAST-YMM-ZMM-NEXT:    vaddps %xmm1, %xmm0, %xmm0
; FAST-YMM-ZMM-NEXT:    vmovaps %xmm0, (%rsp) # 16-byte Spill
; FAST-YMM-ZMM-NEXT:    .p2align 4, 0x90
; FAST-YMM-ZMM-NEXT:  .LBB3_1: # %while.cond
; FAST-YMM-ZMM-NEXT:    # =>This Inner Loop Header: Depth=1
; FAST-YMM-ZMM-NEXT:    callq foo
; FAST-YMM-ZMM-NEXT:    testl %eax, %eax
; FAST-YMM-ZMM-NEXT:    jne .LBB3_1
; FAST-YMM-ZMM-NEXT:  # BB#2: # %for.body.preheader
; FAST-YMM-ZMM-NEXT:    movl $4, %ebx
; FAST-YMM-ZMM-NEXT:    vmovaps (%rsp), %xmm0 # 16-byte Reload
; FAST-YMM-ZMM-NEXT:    .p2align 4, 0x90
; FAST-YMM-ZMM-NEXT:  .LBB3_3: # %for.body
; FAST-YMM-ZMM-NEXT:    # =>This Inner Loop Header: Depth=1
; FAST-YMM-ZMM-NEXT:    callq do_sse
; FAST-YMM-ZMM-NEXT:    callq do_sse
; FAST-YMM-ZMM-NEXT:    vmovaps {{.*}}(%rip), %ymm0
; FAST-YMM-ZMM-NEXT:    vextractf128 $1, %ymm0, %xmm0
; FAST-YMM-ZMM-NEXT:    callq do_sse
; FAST-YMM-ZMM-NEXT:    decl %ebx
; FAST-YMM-ZMM-NEXT:    jne .LBB3_3
; FAST-YMM-ZMM-NEXT:  # BB#4: # %for.end
; FAST-YMM-ZMM-NEXT:    addq $16, %rsp
; FAST-YMM-ZMM-NEXT:    popq %rbx
; FAST-YMM-ZMM-NEXT:    retq
;
; BTVER2-LABEL: test03:
; BTVER2:       # BB#0: # %entry
; BTVER2-NEXT:    pushq %rbx
; BTVER2-NEXT:    subq $16, %rsp
; BTVER2-NEXT:    vaddps %xmm1, %xmm0, %xmm0
; BTVER2-NEXT:    vmovaps %xmm0, (%rsp) # 16-byte Spill
; BTVER2-NEXT:    .p2align 4, 0x90
; BTVER2-NEXT:  .LBB3_1: # %while.cond
; BTVER2-NEXT:    # =>This Inner Loop Header: Depth=1
; BTVER2-NEXT:    callq foo
; BTVER2-NEXT:    testl %eax, %eax
; BTVER2-NEXT:    jne .LBB3_1
; BTVER2-NEXT:  # BB#2: # %for.body.preheader
; BTVER2-NEXT:    vmovaps (%rsp), %xmm0 # 16-byte Reload
; BTVER2-NEXT:    movl $4, %ebx
; BTVER2-NEXT:    .p2align 4, 0x90
; BTVER2-NEXT:  .LBB3_3: # %for.body
; BTVER2-NEXT:    # =>This Inner Loop Header: Depth=1
; BTVER2-NEXT:    callq do_sse
; BTVER2-NEXT:    callq do_sse
; BTVER2-NEXT:    vmovaps {{.*}}(%rip), %ymm0
; BTVER2-NEXT:    vextractf128 $1, %ymm0, %xmm0
; BTVER2-NEXT:    callq do_sse
; BTVER2-NEXT:    decl %ebx
; BTVER2-NEXT:    jne .LBB3_3
; BTVER2-NEXT:  # BB#4: # %for.end
; BTVER2-NEXT:    addq $16, %rsp
; BTVER2-NEXT:    popq %rbx
; BTVER2-NEXT:    retq
entry:
  %add.i = fadd <4 x float> %a, %b
  br label %while.cond

while.cond:
  %call = tail call i32 @foo()
  %tobool = icmp eq i32 %call, 0
  br i1 %tobool, label %for.body, label %while.cond

for.body:
  %i.018 = phi i32 [ 0, %while.cond ], [ %1, %for.body ]
  %c.017 = phi <4 x float> [ %add.i, %while.cond ], [ %call14, %for.body ]
  %call5 = tail call <4 x float> @do_sse(<4 x float> %c.017) nounwind
  %call7 = tail call <4 x float> @do_sse(<4 x float> %call5) nounwind
  %tmp11 = load <8 x float>, <8 x float>* @g, align 32
  %0 = tail call <4 x float> @llvm.x86.avx.vextractf128.ps.256(<8 x float> %tmp11, i8 1) nounwind
  %call14 = tail call <4 x float> @do_sse(<4 x float> %0) nounwind
  %1 = add nsw i32 %i.018, 1
  %exitcond = icmp eq i32 %1, 4
  br i1 %exitcond, label %for.end, label %for.body

for.end:
  ret <4 x float> %call14
}

;; Check that we also perform vzeroupper when we return from a function.

define <4 x float> @test04(<4 x float> %a, <4 x float> %b) nounwind {
; VZ-LABEL: test04:
; VZ:       # BB#0:
; VZ-NEXT:    pushq %rax
; VZ-NEXT:    # kill: %XMM0<def> %XMM0<kill> %YMM0<def>
; VZ-NEXT:    vinsertf128 $1, %xmm1, %ymm0, %ymm0
; VZ-NEXT:    callq do_avx
; VZ-NEXT:    # kill: %XMM0<def> %XMM0<kill> %YMM0<kill>
; VZ-NEXT:    popq %rax
; VZ-NEXT:    vzeroupper
; VZ-NEXT:    retq
;
; NO-VZ-LABEL: test04:
; NO-VZ:       # BB#0:
; NO-VZ-NEXT:    pushq %rax
; NO-VZ-NEXT:    # kill: %XMM0<def> %XMM0<kill> %YMM0<def>
; NO-VZ-NEXT:    vinsertf128 $1, %xmm1, %ymm0, %ymm0
; NO-VZ-NEXT:    callq do_avx
; NO-VZ-NEXT:    # kill: %XMM0<def> %XMM0<kill> %YMM0<kill>
; NO-VZ-NEXT:    popq %rax
; NO-VZ-NEXT:    retq
  %shuf = shufflevector <4 x float> %a, <4 x float> %b, <8 x i32> <i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7>
  %call = call <8 x float> @do_avx(<8 x float> %shuf) nounwind
  %shuf2 = shufflevector <8 x float> %call, <8 x float> undef, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  ret <4 x float> %shuf2
}


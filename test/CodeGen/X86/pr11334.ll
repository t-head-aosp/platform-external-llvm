; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc < %s -mtriple=x86_64-pc-linux -mcpu=corei7 | FileCheck %s --check-prefix=SSE
; RUN: llc < %s -mtriple=x86_64-pc-linux -mcpu=core-avx-i | FileCheck %s --check-prefix=AVX

define <2 x double> @v2f2d_ext_vec(<2 x float> %v1) nounwind {
; SSE-LABEL: v2f2d_ext_vec:
; SSE:       # BB#0: # %entry
; SSE-NEXT:    cvtps2pd %xmm0, %xmm0
; SSE-NEXT:    retq
;
; AVX-LABEL: v2f2d_ext_vec:
; AVX:       # BB#0: # %entry
; AVX-NEXT:    vcvtps2pd %xmm0, %xmm0
; AVX-NEXT:    retq
entry:
  %f1 = fpext <2 x float> %v1 to <2 x double>
  ret <2 x double> %f1
}

define <3 x double> @v3f2d_ext_vec(<3 x float> %v1) nounwind {
; SSE-LABEL: v3f2d_ext_vec:
; SSE:       # BB#0: # %entry
; SSE-NEXT:    cvtps2pd %xmm0, %xmm2
; SSE-NEXT:    movhlps {{.*#+}} xmm0 = xmm0[1,1]
; SSE-NEXT:    cvtps2pd %xmm0, %xmm0
; SSE-NEXT:    movlps %xmm0, -{{[0-9]+}}(%rsp)
; SSE-NEXT:    movaps %xmm2, %xmm1
; SSE-NEXT:    movhlps {{.*#+}} xmm1 = xmm1[1,1]
; SSE-NEXT:    fldl -{{[0-9]+}}(%rsp)
; SSE-NEXT:    movaps %xmm2, %xmm0
; SSE-NEXT:    retq
;
; AVX-LABEL: v3f2d_ext_vec:
; AVX:       # BB#0: # %entry
; AVX-NEXT:    vcvtps2pd %xmm0, %ymm0
; AVX-NEXT:    retq
entry:
  %f1 = fpext <3 x float> %v1 to <3 x double>
  ret <3 x double> %f1
}

define <4 x double> @v4f2d_ext_vec(<4 x float> %v1) nounwind {
; SSE-LABEL: v4f2d_ext_vec:
; SSE:       # BB#0: # %entry
; SSE-NEXT:    cvtps2pd %xmm0, %xmm2
; SSE-NEXT:    movhlps {{.*#+}} xmm0 = xmm0[1,1]
; SSE-NEXT:    cvtps2pd %xmm0, %xmm1
; SSE-NEXT:    movaps %xmm2, %xmm0
; SSE-NEXT:    retq
;
; AVX-LABEL: v4f2d_ext_vec:
; AVX:       # BB#0: # %entry
; AVX-NEXT:    vcvtps2pd %xmm0, %ymm0
; AVX-NEXT:    retq
entry:
  %f1 = fpext <4 x float> %v1 to <4 x double>
  ret <4 x double> %f1
}

define <8 x double> @v8f2d_ext_vec(<8 x float> %v1) nounwind {
; SSE-LABEL: v8f2d_ext_vec:
; SSE:       # BB#0: # %entry
; SSE-NEXT:    cvtps2pd %xmm0, %xmm5
; SSE-NEXT:    cvtps2pd %xmm1, %xmm2
; SSE-NEXT:    movhlps {{.*#+}} xmm0 = xmm0[1,1]
; SSE-NEXT:    cvtps2pd %xmm0, %xmm4
; SSE-NEXT:    movhlps {{.*#+}} xmm1 = xmm1[1,1]
; SSE-NEXT:    cvtps2pd %xmm1, %xmm3
; SSE-NEXT:    movaps %xmm5, %xmm0
; SSE-NEXT:    movaps %xmm4, %xmm1
; SSE-NEXT:    retq
;
; AVX-LABEL: v8f2d_ext_vec:
; AVX:       # BB#0: # %entry
; AVX-NEXT:    vcvtps2pd %xmm0, %ymm2
; AVX-NEXT:    vextractf128 $1, %ymm0, %xmm0
; AVX-NEXT:    vcvtps2pd %xmm0, %ymm1
; AVX-NEXT:    vmovaps %ymm2, %ymm0
; AVX-NEXT:    retq
entry:
  %f1 = fpext <8 x float> %v1 to <8 x double>
  ret <8 x double> %f1
}

define void @test_vector_creation() nounwind {
; SSE-LABEL: test_vector_creation:
; SSE:       # BB#0:
; SSE-NEXT:    movq {{.*#+}} xmm0 = mem[0],zero
; SSE-NEXT:    pslldq {{.*#+}} xmm0 = zero,zero,zero,zero,zero,zero,zero,zero,xmm0[0,1,2,3,4,5,6,7]
; SSE-NEXT:    movdqa %xmm0, (%rax)
; SSE-NEXT:    retq
;
; AVX-LABEL: test_vector_creation:
; AVX:       # BB#0:
; AVX-NEXT:    vmovq {{.*#+}} xmm0 = mem[0],zero
; AVX-NEXT:    vpslldq {{.*#+}} xmm0 = zero,zero,zero,zero,zero,zero,zero,zero,xmm0[0,1,2,3,4,5,6,7]
; AVX-NEXT:    vinsertf128 $1, %xmm0, %ymm0, %ymm0
; AVX-NEXT:    vmovaps %ymm0, (%rax)
; AVX-NEXT:    vzeroupper
; AVX-NEXT:    retq
  %1 = insertelement <4 x double> undef, double 0.000000e+00, i32 2
  %2 = load double, double addrspace(1)* null
  %3 = insertelement <4 x double> %1, double %2, i32 3
  store <4 x double> %3, <4 x double>* undef
  ret void
}

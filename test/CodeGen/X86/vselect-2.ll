; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc < %s -mtriple=x86_64-unknown-unknown -mattr=+sse2 | FileCheck %s --check-prefix=SSE --check-prefix=SSE2
; RUN: llc < %s -mtriple=x86_64-unknown-unknown -mattr=+sse4.1 | FileCheck %s --check-prefix=SSE --check-prefix=SSE41
; RUN: llc < %s -mtriple=x86_64-unknown-unknown -mattr=+avx | FileCheck %s --check-prefix=AVX --check-prefix=AVX1
; RUN: llc < %s -mtriple=x86_64-unknown-unknown -mattr=+avx2 | FileCheck %s --check-prefix=AVX --check-prefix=AVX2

define <4 x i32> @test1(<4 x i32> %A, <4 x i32> %B) {
; SSE2-LABEL: test1:
; SSE2:       # BB#0:
; SSE2-NEXT:    movsd {{.*#+}} xmm1 = xmm0[0],xmm1[1]
; SSE2-NEXT:    movapd %xmm1, %xmm0
; SSE2-NEXT:    retq
;
; SSE41-LABEL: test1:
; SSE41:       # BB#0:
; SSE41-NEXT:    pblendw {{.*#+}} xmm0 = xmm0[0,1,2,3],xmm1[4,5,6,7]
; SSE41-NEXT:    retq
;
; AVX1-LABEL: test1:
; AVX1:       # BB#0:
; AVX1-NEXT:    vpblendw {{.*#+}} xmm0 = xmm0[0,1,2,3],xmm1[4,5,6,7]
; AVX1-NEXT:    retq
;
; AVX2-LABEL: test1:
; AVX2:       # BB#0:
; AVX2-NEXT:    vpblendd {{.*#+}} xmm0 = xmm0[0,1],xmm1[2,3]
; AVX2-NEXT:    retq
  %select = select <4 x i1><i1 true, i1 true, i1 false, i1 false>, <4 x i32> %A, <4 x i32> %B
  ret <4 x i32> %select
}

define <4 x i32> @test2(<4 x i32> %A, <4 x i32> %B) {
; SSE2-LABEL: test2:
; SSE2:       # BB#0:
; SSE2-NEXT:    movsd {{.*#+}} xmm0 = xmm1[0],xmm0[1]
; SSE2-NEXT:    retq
;
; SSE41-LABEL: test2:
; SSE41:       # BB#0:
; SSE41-NEXT:    pblendw {{.*#+}} xmm0 = xmm1[0,1,2,3],xmm0[4,5,6,7]
; SSE41-NEXT:    retq
;
; AVX1-LABEL: test2:
; AVX1:       # BB#0:
; AVX1-NEXT:    vpblendw {{.*#+}} xmm0 = xmm1[0,1,2,3],xmm0[4,5,6,7]
; AVX1-NEXT:    retq
;
; AVX2-LABEL: test2:
; AVX2:       # BB#0:
; AVX2-NEXT:    vpblendd {{.*#+}} xmm0 = xmm1[0,1],xmm0[2,3]
; AVX2-NEXT:    retq
  %select = select <4 x i1><i1 false, i1 false, i1 true, i1 true>, <4 x i32> %A, <4 x i32> %B
  ret <4 x i32> %select
}

define <4 x float> @test3(<4 x float> %A, <4 x float> %B) {
; SSE2-LABEL: test3:
; SSE2:       # BB#0:
; SSE2-NEXT:    movsd {{.*#+}} xmm1 = xmm0[0],xmm1[1]
; SSE2-NEXT:    movapd %xmm1, %xmm0
; SSE2-NEXT:    retq
;
; SSE41-LABEL: test3:
; SSE41:       # BB#0:
; SSE41-NEXT:    blendpd {{.*#+}} xmm0 = xmm0[0],xmm1[1]
; SSE41-NEXT:    retq
;
; AVX-LABEL: test3:
; AVX:       # BB#0:
; AVX-NEXT:    vblendpd {{.*#+}} xmm0 = xmm0[0],xmm1[1]
; AVX-NEXT:    retq
  %select = select <4 x i1><i1 true, i1 true, i1 false, i1 false>, <4 x float> %A, <4 x float> %B
  ret <4 x float> %select
}

define <4 x float> @test4(<4 x float> %A, <4 x float> %B) {
; SSE2-LABEL: test4:
; SSE2:       # BB#0:
; SSE2-NEXT:    movsd {{.*#+}} xmm0 = xmm1[0],xmm0[1]
; SSE2-NEXT:    retq
;
; SSE41-LABEL: test4:
; SSE41:       # BB#0:
; SSE41-NEXT:    blendpd {{.*#+}} xmm0 = xmm1[0],xmm0[1]
; SSE41-NEXT:    retq
;
; AVX-LABEL: test4:
; AVX:       # BB#0:
; AVX-NEXT:    vblendpd {{.*#+}} xmm0 = xmm1[0],xmm0[1]
; AVX-NEXT:    retq
  %select = select <4 x i1><i1 false, i1 false, i1 true, i1 true>, <4 x float> %A, <4 x float> %B
  ret <4 x float> %select
}

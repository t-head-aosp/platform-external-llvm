; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc < %s -mtriple=x86_64-unknown-unknown -mattr=+avx,+xop | FileCheck %s --check-prefix=XOP --check-prefix=XOP-AVX1
; RUN: llc < %s -mtriple=x86_64-unknown-unknown -mattr=+avx2,+xop | FileCheck %s --check-prefix=XOP --check-prefix=XOP-AVX2

define <8 x i16> @test_mul_v8i16_add_v8i16(<8 x i16> %a0, <8 x i16> %a1, <8 x i16> %a2) {
; XOP-LABEL: test_mul_v8i16_add_v8i16:
; XOP:       # BB#0:
; XOP-NEXT:    vpmacsww %xmm2, %xmm1, %xmm0, %xmm0
; XOP-NEXT:    retq
  %1 = mul <8 x i16> %a0, %a1
  %2 = add <8 x i16> %1, %a2
  ret <8 x i16> %2
}

define <16 x i16> @test_mul_v16i16_add_v16i16(<16 x i16> %a0, <16 x i16> %a1, <16 x i16> %a2) {
; XOP-AVX1-LABEL: test_mul_v16i16_add_v16i16:
; XOP-AVX1:       # BB#0:
; XOP-AVX1-NEXT:    vextractf128 $1, %ymm1, %xmm3
; XOP-AVX1-NEXT:    vextractf128 $1, %ymm0, %xmm4
; XOP-AVX1-NEXT:    vextractf128 $1, %ymm2, %xmm5
; XOP-AVX1-NEXT:    vpmacsww %xmm5, %xmm3, %xmm4, %xmm3
; XOP-AVX1-NEXT:    vpmacsww %xmm2, %xmm1, %xmm0, %xmm0
; XOP-AVX1-NEXT:    vinsertf128 $1, %xmm3, %ymm0, %ymm0
; XOP-AVX1-NEXT:    retq
;
; XOP-AVX2-LABEL: test_mul_v16i16_add_v16i16:
; XOP-AVX2:       # BB#0:
; XOP-AVX2-NEXT:    vpmullw %ymm1, %ymm0, %ymm0
; XOP-AVX2-NEXT:    vpaddw %ymm0, %ymm2, %ymm0
; XOP-AVX2-NEXT:    retq
  %1 = mul <16 x i16> %a0, %a1
  %2 = add <16 x i16> %a2, %1
  ret <16 x i16> %2
}

define <4 x i32> @test_mul_v4i32_add_v4i32(<4 x i32> %a0, <4 x i32> %a1, <4 x i32> %a2) {
; XOP-LABEL: test_mul_v4i32_add_v4i32:
; XOP:       # BB#0:
; XOP-NEXT:    vpmacsdd %xmm2, %xmm1, %xmm0, %xmm0
; XOP-NEXT:    retq
  %1 = mul <4 x i32> %a0, %a1
  %2 = add <4 x i32> %1, %a2
  ret <4 x i32> %2
}

define <8 x i32> @test_mul_v8i32_add_v8i32(<8 x i32> %a0, <8 x i32> %a1, <8 x i32> %a2) {
; XOP-AVX1-LABEL: test_mul_v8i32_add_v8i32:
; XOP-AVX1:       # BB#0:
; XOP-AVX1-NEXT:    vextractf128 $1, %ymm1, %xmm3
; XOP-AVX1-NEXT:    vextractf128 $1, %ymm0, %xmm4
; XOP-AVX1-NEXT:    vextractf128 $1, %ymm2, %xmm5
; XOP-AVX1-NEXT:    vpmacsdd %xmm5, %xmm3, %xmm4, %xmm3
; XOP-AVX1-NEXT:    vpmacsdd %xmm2, %xmm1, %xmm0, %xmm0
; XOP-AVX1-NEXT:    vinsertf128 $1, %xmm3, %ymm0, %ymm0
; XOP-AVX1-NEXT:    retq
;
; XOP-AVX2-LABEL: test_mul_v8i32_add_v8i32:
; XOP-AVX2:       # BB#0:
; XOP-AVX2-NEXT:    vpmulld %ymm1, %ymm0, %ymm0
; XOP-AVX2-NEXT:    vpaddd %ymm0, %ymm2, %ymm0
; XOP-AVX2-NEXT:    retq
  %1 = mul <8 x i32> %a0, %a1
  %2 = add <8 x i32> %a2, %1
  ret <8 x i32> %2
}

define <4 x i64> @test_mulx_v4i32_add_v4i64(<4 x i32> %a0, <4 x i32> %a1, <4 x i64> %a2) {
; XOP-AVX1-LABEL: test_mulx_v4i32_add_v4i64:
; XOP-AVX1:       # BB#0:
; XOP-AVX1-NEXT:    vpmovsxdq %xmm0, %xmm3
; XOP-AVX1-NEXT:    vpshufd {{.*#+}} xmm0 = xmm0[2,3,0,1]
; XOP-AVX1-NEXT:    vpmovsxdq %xmm0, %xmm0
; XOP-AVX1-NEXT:    vpmovsxdq %xmm1, %xmm4
; XOP-AVX1-NEXT:    vpshufd {{.*#+}} xmm1 = xmm1[2,3,0,1]
; XOP-AVX1-NEXT:    vpmovsxdq %xmm1, %xmm1
; XOP-AVX1-NEXT:    vextractf128 $1, %ymm2, %xmm5
; XOP-AVX1-NEXT:    vpmacsdql %xmm5, %xmm1, %xmm0, %xmm0
; XOP-AVX1-NEXT:    vpmacsdql %xmm2, %xmm4, %xmm3, %xmm1
; XOP-AVX1-NEXT:    vinsertf128 $1, %xmm0, %ymm1, %ymm0
; XOP-AVX1-NEXT:    retq
;
; XOP-AVX2-LABEL: test_mulx_v4i32_add_v4i64:
; XOP-AVX2:       # BB#0:
; XOP-AVX2-NEXT:    vpmovsxdq %xmm0, %ymm0
; XOP-AVX2-NEXT:    vpmovsxdq %xmm1, %ymm1
; XOP-AVX2-NEXT:    vpmuldq %ymm1, %ymm0, %ymm0
; XOP-AVX2-NEXT:    vpaddq %ymm2, %ymm0, %ymm0
; XOP-AVX2-NEXT:    retq
  %1 = sext <4 x i32> %a0 to <4 x i64>
  %2 = sext <4 x i32> %a1 to <4 x i64>
  %3 = mul <4 x i64> %1, %2
  %4 = add <4 x i64> %3, %a2
  ret <4 x i64> %4
}

define <2 x i64> @test_pmuldq_lo_v4i32_add_v2i64(<4 x i32> %a0, <4 x i32> %a1, <2 x i64> %a2) {
; XOP-LABEL: test_pmuldq_lo_v4i32_add_v2i64:
; XOP:       # BB#0:
; XOP-NEXT:    vpmacsdql %xmm2, %xmm1, %xmm0, %xmm0
; XOP-NEXT:    retq
  %1 = call <2 x i64> @llvm.x86.sse41.pmuldq(<4 x i32> %a0, <4 x i32> %a1)
  %2 = add <2 x i64> %1, %a2
  ret <2 x i64> %2
}

define <2 x i64> @test_pmuldq_hi_v4i32_add_v2i64(<4 x i32> %a0, <4 x i32> %a1, <2 x i64> %a2) {
; XOP-LABEL: test_pmuldq_hi_v4i32_add_v2i64:
; XOP:       # BB#0:
; XOP-NEXT:    vpmacsdqh %xmm2, %xmm1, %xmm0, %xmm0
; XOP-NEXT:    retq
  %1 = shufflevector <4 x i32> %a0, <4 x i32> undef, <4 x i32> <i32 1, i32 undef, i32 3, i32 undef>
  %2 = shufflevector <4 x i32> %a1, <4 x i32> undef, <4 x i32> <i32 1, i32 undef, i32 3, i32 undef>
  %3 = call <2 x i64> @llvm.x86.sse41.pmuldq(<4 x i32> %1, <4 x i32> %2)
  %4 = add <2 x i64> %3, %a2
  ret <2 x i64> %4
}

define <4 x i32> @test_pmaddwd_v8i16_add_v4i32(<8 x i16> %a0, <8 x i16> %a1, <4 x i32> %a2) {
; XOP-LABEL: test_pmaddwd_v8i16_add_v4i32:
; XOP:       # BB#0:
; XOP-NEXT:    vpmaddwd %xmm1, %xmm0, %xmm0
; XOP-NEXT:    vpaddd %xmm2, %xmm0, %xmm0
; XOP-NEXT:    retq
  %1 = call <4 x i32> @llvm.x86.sse2.pmadd.wd(<8 x i16> %a0, <8 x i16> %a1)
  %2 = add <4 x i32> %1, %a2
  ret <4 x i32> %2
}

declare <4 x i32> @llvm.x86.sse2.pmadd.wd(<8 x i16>, <8 x i16>) nounwind readnone
declare <2 x i64> @llvm.x86.sse41.pmuldq(<4 x i32>, <4 x i32>) nounwind readnone

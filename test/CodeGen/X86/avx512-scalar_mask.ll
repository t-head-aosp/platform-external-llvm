; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc < %s -mtriple=x86_64-apple-darwin -mcpu=knl | FileCheck %s

declare <4 x float> @llvm.x86.avx512.mask.vfmadd.ss(<4 x float>, <4 x float>, <4 x float>, i8, i32)
declare <4 x float> @llvm.x86.avx512.maskz.vfmadd.ss(<4 x float>, <4 x float>, <4 x float>, i8, i32)

define <4 x float>@test_var_mask(<4 x float> %v0, <4 x float> %v1, <4 x float> %v2, i8 %mask) {
; CHECK-LABEL: test_var_mask:
; CHECK:       ## BB#0:
; CHECK-NEXT:    andl $1, %edi
; CHECK-NEXT:    kmovw %edi, %k1
; CHECK-NEXT:    vfmadd213ss %xmm2, %xmm1, %xmm0 {%k1}
; CHECK-NEXT:    retq
  %res = call <4 x float> @llvm.x86.avx512.mask.vfmadd.ss(<4 x float> %v0,<4 x float> %v1, <4 x float> %v2,  i8 %mask, i32 4)
  ret < 4 x float> %res
}

define <4 x float>@test_var_maskz(<4 x float> %v0, <4 x float> %v1, <4 x float> %v2, i8 %mask) {
; CHECK-LABEL: test_var_maskz:
; CHECK:       ## BB#0:
; CHECK-NEXT:    andl $1, %edi
; CHECK-NEXT:    kmovw %edi, %k1
; CHECK-NEXT:    vfmadd213ss %xmm2, %xmm1, %xmm0 {%k1} {z}
; CHECK-NEXT:    retq
  %res = call <4 x float> @llvm.x86.avx512.maskz.vfmadd.ss(<4 x float> %v0,<4 x float> %v1, <4 x float> %v2,  i8 %mask, i32 4)
  ret < 4 x float> %res
}

; FIXME: we should just return %xmm0 here.
define <4 x float>@test_const0_mask(<4 x float> %v0, <4 x float> %v1, <4 x float> %v2) {
; CHECK-LABEL: test_const0_mask:
; CHECK:       ## BB#0:
; CHECK-NEXT:    kxorw %k0, %k0, %k1
; CHECK-NEXT:    vfmadd213ss %xmm2, %xmm1, %xmm0 {%k1}
; CHECK-NEXT:    retq
  %res = call <4 x float> @llvm.x86.avx512.mask.vfmadd.ss(<4 x float> %v0,<4 x float> %v1, <4 x float> %v2,  i8 0, i32 4)
  ret < 4 x float> %res
}

; FIXME: we should zero the lower element of xmm0 and return it.
define <4 x float>@test_const0_maskz(<4 x float> %v0, <4 x float> %v1, <4 x float> %v2) {
; CHECK-LABEL: test_const0_maskz:
; CHECK:       ## BB#0:
; CHECK-NEXT:    kxorw %k0, %k0, %k1
; CHECK-NEXT:    vfmadd213ss %xmm2, %xmm1, %xmm0 {%k1} {z}
; CHECK-NEXT:    retq
  %res = call <4 x float> @llvm.x86.avx512.maskz.vfmadd.ss(<4 x float> %v0,<4 x float> %v1, <4 x float> %v2,  i8 0, i32 4)
  ret < 4 x float> %res
}

; FIXME: we should just return %xmm0 here.
define <4 x float>@test_const2_mask(<4 x float> %v0, <4 x float> %v1, <4 x float> %v2) {
; CHECK-LABEL: test_const2_mask:
; CHECK:       ## BB#0:
; CHECK-NEXT:    kxorw %k0, %k0, %k1
; CHECK-NEXT:    vfmadd213ss %xmm2, %xmm1, %xmm0 {%k1}
; CHECK-NEXT:    retq
  %res = call <4 x float> @llvm.x86.avx512.mask.vfmadd.ss(<4 x float> %v0,<4 x float> %v1, <4 x float> %v2,  i8 2, i32 4)
  ret < 4 x float> %res
}

; FIXME: we should zero the lower element of xmm0 and return it.
define <4 x float>@test_const2_maskz(<4 x float> %v0, <4 x float> %v1, <4 x float> %v2) {
; CHECK-LABEL: test_const2_maskz:
; CHECK:       ## BB#0:
; CHECK-NEXT:    kxorw %k0, %k0, %k1
; CHECK-NEXT:    vfmadd213ss %xmm2, %xmm1, %xmm0 {%k1} {z}
; CHECK-NEXT:    retq
  %res = call <4 x float> @llvm.x86.avx512.maskz.vfmadd.ss(<4 x float> %v0,<4 x float> %v1, <4 x float> %v2,  i8 2, i32 4)
  ret < 4 x float> %res
}

define <4 x float>@test_const_allone_mask(<4 x float> %v0, <4 x float> %v1, <4 x float> %v2) {
; CHECK-LABEL: test_const_allone_mask:
; CHECK:       ## BB#0:
; CHECK-NEXT:    vfmadd213ss %xmm2, %xmm1, %xmm0
; CHECK-NEXT:    retq
  %res = call <4 x float> @llvm.x86.avx512.mask.vfmadd.ss(<4 x float> %v0,<4 x float> %v1, <4 x float> %v2,  i8 -1, i32 4)
  ret < 4 x float> %res
}

define <4 x float>@test_const_allone_maskz(<4 x float> %v0, <4 x float> %v1, <4 x float> %v2) {
; CHECK-LABEL: test_const_allone_maskz:
; CHECK:       ## BB#0:
; CHECK-NEXT:    vfmadd213ss %xmm2, %xmm1, %xmm0
; CHECK-NEXT:    retq
  %res = call <4 x float> @llvm.x86.avx512.maskz.vfmadd.ss(<4 x float> %v0,<4 x float> %v1, <4 x float> %v2,  i8 -1, i32 4)
  ret < 4 x float> %res
}

define <4 x float>@test_const_3_mask(<4 x float> %v0, <4 x float> %v1, <4 x float> %v2) {
; CHECK-LABEL: test_const_3_mask:
; CHECK:       ## BB#0:
; CHECK-NEXT:    vfmadd213ss %xmm2, %xmm1, %xmm0
; CHECK-NEXT:    retq
  %res = call <4 x float> @llvm.x86.avx512.mask.vfmadd.ss(<4 x float> %v0,<4 x float> %v1, <4 x float> %v2,  i8 3, i32 4)
  ret < 4 x float> %res
}

define <4 x float>@test_const_3_maskz(<4 x float> %v0, <4 x float> %v1, <4 x float> %v2) {
; CHECK-LABEL: test_const_3_maskz:
; CHECK:       ## BB#0:
; CHECK-NEXT:    vfmadd213ss %xmm2, %xmm1, %xmm0
; CHECK-NEXT:    retq
  %res = call <4 x float> @llvm.x86.avx512.maskz.vfmadd.ss(<4 x float> %v0,<4 x float> %v1, <4 x float> %v2,  i8 3, i32 4)
  ret < 4 x float> %res
}

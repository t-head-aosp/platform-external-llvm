; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc < %s -mtriple=i686-apple-darwin -mcpu=core-avx2 -mattr=+avx2 | FileCheck %s --check-prefix=X32
; RUN: llc < %s -mtriple=x86_64-apple-darwin -mcpu=core-avx2 -mattr=+avx2 | FileCheck %s --check-prefix=X64

define <8 x i32> @perm_cl_int_8x32(<8 x i32> %A) nounwind readnone {
; X32-LABEL: perm_cl_int_8x32:
; X32:       ## BB#0: ## %entry
; X32-NEXT:    vmovdqa {{.*#+}} ymm1 = [0,7,2,1,2,7,6,0]
; X32-NEXT:    vpermd %ymm0, %ymm1, %ymm0
; X32-NEXT:    retl
;
; X64-LABEL: perm_cl_int_8x32:
; X64:       ## BB#0: ## %entry
; X64-NEXT:    vmovdqa {{.*#+}} ymm1 = [0,7,2,1,2,7,6,0]
; X64-NEXT:    vpermd %ymm0, %ymm1, %ymm0
; X64-NEXT:    retq
entry:
  %B = shufflevector <8 x i32> %A, <8 x i32> undef, <8 x i32> <i32 0, i32 7, i32 2, i32 1, i32 2, i32 7, i32 6, i32 0>
  ret <8 x i32> %B
}


define <8 x float> @perm_cl_fp_8x32(<8 x float> %A) nounwind readnone {
; X32-LABEL: perm_cl_fp_8x32:
; X32:       ## BB#0: ## %entry
; X32-NEXT:    vmovaps {{.*#+}} ymm1 = <u,7,2,u,4,u,1,6>
; X32-NEXT:    vpermps %ymm0, %ymm1, %ymm0
; X32-NEXT:    retl
;
; X64-LABEL: perm_cl_fp_8x32:
; X64:       ## BB#0: ## %entry
; X64-NEXT:    vmovaps {{.*#+}} ymm1 = <u,7,2,u,4,u,1,6>
; X64-NEXT:    vpermps %ymm0, %ymm1, %ymm0
; X64-NEXT:    retq
entry:
  %B = shufflevector <8 x float> %A, <8 x float> undef, <8 x i32> <i32 undef, i32 7, i32 2, i32 undef, i32 4, i32 undef, i32 1, i32 6>
  ret <8 x float> %B
}

define <4 x i64> @perm_cl_int_4x64(<4 x i64> %A) nounwind readnone {
; X32-LABEL: perm_cl_int_4x64:
; X32:       ## BB#0: ## %entry
; X32-NEXT:    vpermq {{.*#+}} ymm0 = ymm0[0,3,2,1]
; X32-NEXT:    retl
;
; X64-LABEL: perm_cl_int_4x64:
; X64:       ## BB#0: ## %entry
; X64-NEXT:    vpermq {{.*#+}} ymm0 = ymm0[0,3,2,1]
; X64-NEXT:    retq
entry:
  %B = shufflevector <4 x i64> %A, <4 x i64> undef, <4 x i32> <i32 0, i32 3, i32 2, i32 1>
  ret <4 x i64> %B
}

define <4 x double> @perm_cl_fp_4x64(<4 x double> %A) nounwind readnone {
; X32-LABEL: perm_cl_fp_4x64:
; X32:       ## BB#0: ## %entry
; X32-NEXT:    vpermpd {{.*#+}} ymm0 = ymm0[0,3,2,1]
; X32-NEXT:    retl
;
; X64-LABEL: perm_cl_fp_4x64:
; X64:       ## BB#0: ## %entry
; X64-NEXT:    vpermpd {{.*#+}} ymm0 = ymm0[0,3,2,1]
; X64-NEXT:    retq
entry:
  %B = shufflevector <4 x double> %A, <4 x double> undef, <4 x i32> <i32 0, i32 3, i32 2, i32 1>
  ret <4 x double> %B
}

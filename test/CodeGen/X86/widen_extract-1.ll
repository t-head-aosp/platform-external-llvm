; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc < %s -mtriple=i686-unknown -mattr=+sse4.2 | FileCheck %s --check-prefix=X32
; RUN: llc < %s -mtriple=x86_64-unknown -mattr=+sse4.2 | FileCheck %s --check-prefix=X64

; widen extract subvector

define void @convert(<2 x double>* %dst.addr, <3 x double> %src)  {
; X32-LABEL: convert:
; X32:       # BB#0: # %entry
; X32-NEXT:    movups {{[0-9]+}}(%esp), %xmm0
; X32-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X32-NEXT:    movaps %xmm0, (%eax)
; X32-NEXT:    retl
;
; X64-LABEL: convert:
; X64:       # BB#0: # %entry
; X64-NEXT:    unpcklpd {{.*#+}} xmm0 = xmm0[0],xmm1[0]
; X64-NEXT:    movapd %xmm0, (%rdi)
; X64-NEXT:    retq
entry:
  %val = shufflevector <3 x double> %src, <3 x double> undef, <2 x i32> <i32 0, i32 1>
  store <2 x double> %val, <2 x double>* %dst.addr
  ret void
}

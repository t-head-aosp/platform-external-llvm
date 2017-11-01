; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc -mtriple=x86_64-unknown-unknown -mcpu=generic -mattr=+sse2 -fast-isel --fast-isel-abort=1 < %s | FileCheck %s --check-prefix=SSE2
; RUN: llc -mtriple=x86_64-unknown-unknown -mcpu=generic -mattr=+avx -fast-isel --fast-isel-abort=1 < %s | FileCheck %s --check-prefix=AVX
; RUN: llc -mtriple=i686-unknown-unknown -mcpu=generic -mattr=+sse2 -fast-isel --fast-isel-abort=1 < %s | FileCheck %s --check-prefix=SSE2_X86
; RUN: llc -mtriple=i686-unknown-unknown -mcpu=generic -mattr=+avx -fast-isel --fast-isel-abort=1 < %s | FileCheck %s --check-prefix=AVX_X86


define double @int_to_double_rr(i32 %a) {
; SSE2-LABEL: int_to_double_rr:
; SSE2:       # BB#0: # %entry
; SSE2-NEXT:    cvtsi2sdl %edi, %xmm0
; SSE2-NEXT:    retq
;
; AVX-LABEL: int_to_double_rr:
; AVX:       # BB#0: # %entry
; AVX-NEXT:    vcvtsi2sdl %edi, %xmm0, %xmm0
; AVX-NEXT:    retq
;
; SSE2_X86-LABEL: int_to_double_rr:
; SSE2_X86:       # BB#0: # %entry
; SSE2_X86-NEXT:    pushl %ebp
; SSE2_X86-NEXT:    .cfi_def_cfa_offset 8
; SSE2_X86-NEXT:    .cfi_offset %ebp, -8
; SSE2_X86-NEXT:    movl %esp, %ebp
; SSE2_X86-NEXT:    .cfi_def_cfa_register %ebp
; SSE2_X86-NEXT:    andl $-8, %esp
; SSE2_X86-NEXT:    subl $8, %esp
; SSE2_X86-NEXT:    movl 8(%ebp), %eax
; SSE2_X86-NEXT:    cvtsi2sdl %eax, %xmm0
; SSE2_X86-NEXT:    movsd %xmm0, (%esp)
; SSE2_X86-NEXT:    fldl (%esp)
; SSE2_X86-NEXT:    movl %ebp, %esp
; SSE2_X86-NEXT:    popl %ebp
; SSE2_X86-NEXT:    .cfi_def_cfa %esp, 4
; SSE2_X86-NEXT:    retl
;
; AVX_X86-LABEL: int_to_double_rr:
; AVX_X86:       # BB#0: # %entry
; AVX_X86-NEXT:    pushl %ebp
; AVX_X86-NEXT:    .cfi_def_cfa_offset 8
; AVX_X86-NEXT:    .cfi_offset %ebp, -8
; AVX_X86-NEXT:    movl %esp, %ebp
; AVX_X86-NEXT:    .cfi_def_cfa_register %ebp
; AVX_X86-NEXT:    andl $-8, %esp
; AVX_X86-NEXT:    subl $8, %esp
; AVX_X86-NEXT:    vcvtsi2sdl 8(%ebp), %xmm0, %xmm0
; AVX_X86-NEXT:    vmovsd %xmm0, (%esp)
; AVX_X86-NEXT:    fldl (%esp)
; AVX_X86-NEXT:    movl %ebp, %esp
; AVX_X86-NEXT:    popl %ebp
; AVX_X86-NEXT:    .cfi_def_cfa %esp, 4
; AVX_X86-NEXT:    retl
entry:
  %0 = sitofp i32 %a to double
  ret double %0
}

define double @int_to_double_rm(i32* %a) {
; SSE2-LABEL: int_to_double_rm:
; SSE2:       # BB#0: # %entry
; SSE2-NEXT:    movl (%rdi), %eax
; SSE2-NEXT:    cvtsi2sdl %eax, %xmm0
; SSE2-NEXT:    retq
;
; AVX-LABEL: int_to_double_rm:
; AVX:       # BB#0: # %entry
; AVX-NEXT:    vcvtsi2sdl (%rdi), %xmm0, %xmm0
; AVX-NEXT:    retq
;
; SSE2_X86-LABEL: int_to_double_rm:
; SSE2_X86:       # BB#0: # %entry
; SSE2_X86-NEXT:    pushl %ebp
; SSE2_X86-NEXT:    .cfi_def_cfa_offset 8
; SSE2_X86-NEXT:    .cfi_offset %ebp, -8
; SSE2_X86-NEXT:    movl %esp, %ebp
; SSE2_X86-NEXT:    .cfi_def_cfa_register %ebp
; SSE2_X86-NEXT:    andl $-8, %esp
; SSE2_X86-NEXT:    subl $8, %esp
; SSE2_X86-NEXT:    movl 8(%ebp), %eax
; SSE2_X86-NEXT:    cvtsi2sdl (%eax), %xmm0
; SSE2_X86-NEXT:    movsd %xmm0, (%esp)
; SSE2_X86-NEXT:    fldl (%esp)
; SSE2_X86-NEXT:    movl %ebp, %esp
; SSE2_X86-NEXT:    popl %ebp
; SSE2_X86-NEXT:    .cfi_def_cfa %esp, 4
; SSE2_X86-NEXT:    retl
;
; AVX_X86-LABEL: int_to_double_rm:
; AVX_X86:       # BB#0: # %entry
; AVX_X86-NEXT:    pushl %ebp
; AVX_X86-NEXT:    .cfi_def_cfa_offset 8
; AVX_X86-NEXT:    .cfi_offset %ebp, -8
; AVX_X86-NEXT:    movl %esp, %ebp
; AVX_X86-NEXT:    .cfi_def_cfa_register %ebp
; AVX_X86-NEXT:    andl $-8, %esp
; AVX_X86-NEXT:    subl $8, %esp
; AVX_X86-NEXT:    movl 8(%ebp), %eax
; AVX_X86-NEXT:    vcvtsi2sdl (%eax), %xmm0, %xmm0
; AVX_X86-NEXT:    vmovsd %xmm0, (%esp)
; AVX_X86-NEXT:    fldl (%esp)
; AVX_X86-NEXT:    movl %ebp, %esp
; AVX_X86-NEXT:    popl %ebp
; AVX_X86-NEXT:    .cfi_def_cfa %esp, 4
; AVX_X86-NEXT:    retl
entry:
  %0 = load i32, i32* %a
  %1 = sitofp i32 %0 to double
  ret double %1
}

define double @int_to_double_rm_optsize(i32* %a) optsize {
; SSE2-LABEL: int_to_double_rm_optsize:
; SSE2:       # BB#0: # %entry
; SSE2-NEXT:    cvtsi2sdl (%rdi), %xmm0
; SSE2-NEXT:    retq
;
; AVX-LABEL: int_to_double_rm_optsize:
; AVX:       # BB#0: # %entry
; AVX-NEXT:    vcvtsi2sdl (%rdi), %xmm0, %xmm0
; AVX-NEXT:    retq
;
; SSE2_X86-LABEL: int_to_double_rm_optsize:
; SSE2_X86:       # BB#0: # %entry
; SSE2_X86-NEXT:    pushl %ebp
; SSE2_X86-NEXT:    .cfi_def_cfa_offset 8
; SSE2_X86-NEXT:    .cfi_offset %ebp, -8
; SSE2_X86-NEXT:    movl %esp, %ebp
; SSE2_X86-NEXT:    .cfi_def_cfa_register %ebp
; SSE2_X86-NEXT:    andl $-8, %esp
; SSE2_X86-NEXT:    subl $8, %esp
; SSE2_X86-NEXT:    movl 8(%ebp), %eax
; SSE2_X86-NEXT:    cvtsi2sdl (%eax), %xmm0
; SSE2_X86-NEXT:    movsd %xmm0, (%esp)
; SSE2_X86-NEXT:    fldl (%esp)
; SSE2_X86-NEXT:    movl %ebp, %esp
; SSE2_X86-NEXT:    popl %ebp
; SSE2_X86-NEXT:    .cfi_def_cfa %esp, 4
; SSE2_X86-NEXT:    retl
;
; AVX_X86-LABEL: int_to_double_rm_optsize:
; AVX_X86:       # BB#0: # %entry
; AVX_X86-NEXT:    pushl %ebp
; AVX_X86-NEXT:    .cfi_def_cfa_offset 8
; AVX_X86-NEXT:    .cfi_offset %ebp, -8
; AVX_X86-NEXT:    movl %esp, %ebp
; AVX_X86-NEXT:    .cfi_def_cfa_register %ebp
; AVX_X86-NEXT:    andl $-8, %esp
; AVX_X86-NEXT:    subl $8, %esp
; AVX_X86-NEXT:    movl 8(%ebp), %eax
; AVX_X86-NEXT:    vcvtsi2sdl (%eax), %xmm0, %xmm0
; AVX_X86-NEXT:    vmovsd %xmm0, (%esp)
; AVX_X86-NEXT:    fldl (%esp)
; AVX_X86-NEXT:    movl %ebp, %esp
; AVX_X86-NEXT:    popl %ebp
; AVX_X86-NEXT:    .cfi_def_cfa %esp, 4
; AVX_X86-NEXT:    retl
entry:
  %0 = load i32, i32* %a
  %1 = sitofp i32 %0 to double
  ret double %1
}

define float @int_to_float_rr(i32 %a) {
; SSE2-LABEL: int_to_float_rr:
; SSE2:       # BB#0: # %entry
; SSE2-NEXT:    cvtsi2ssl %edi, %xmm0
; SSE2-NEXT:    retq
;
; AVX-LABEL: int_to_float_rr:
; AVX:       # BB#0: # %entry
; AVX-NEXT:    vcvtsi2ssl %edi, %xmm0, %xmm0
; AVX-NEXT:    retq
;
; SSE2_X86-LABEL: int_to_float_rr:
; SSE2_X86:       # BB#0: # %entry
; SSE2_X86-NEXT:    pushl %eax
; SSE2_X86-NEXT:    .cfi_def_cfa_offset 8
; SSE2_X86-NEXT:    movl {{[0-9]+}}(%esp), %eax
; SSE2_X86-NEXT:    cvtsi2ssl %eax, %xmm0
; SSE2_X86-NEXT:    movss %xmm0, (%esp)
; SSE2_X86-NEXT:    flds (%esp)
; SSE2_X86-NEXT:    popl %eax
; SSE2_X86-NEXT:    .cfi_def_cfa_offset 4
; SSE2_X86-NEXT:    retl
;
; AVX_X86-LABEL: int_to_float_rr:
; AVX_X86:       # BB#0: # %entry
; AVX_X86-NEXT:    pushl %eax
; AVX_X86-NEXT:    .cfi_def_cfa_offset 8
; AVX_X86-NEXT:    vcvtsi2ssl {{[0-9]+}}(%esp), %xmm0, %xmm0
; AVX_X86-NEXT:    vmovss %xmm0, (%esp)
; AVX_X86-NEXT:    flds (%esp)
; AVX_X86-NEXT:    popl %eax
; AVX_X86-NEXT:    .cfi_def_cfa_offset 4
; AVX_X86-NEXT:    retl
entry:
  %0 = sitofp i32 %a to float
  ret float %0
}

define float @int_to_float_rm(i32* %a) {
; SSE2-LABEL: int_to_float_rm:
; SSE2:       # BB#0: # %entry
; SSE2-NEXT:    movl (%rdi), %eax
; SSE2-NEXT:    cvtsi2ssl %eax, %xmm0
; SSE2-NEXT:    retq
;
; AVX-LABEL: int_to_float_rm:
; AVX:       # BB#0: # %entry
; AVX-NEXT:    vcvtsi2ssl (%rdi), %xmm0, %xmm0
; AVX-NEXT:    retq
;
; SSE2_X86-LABEL: int_to_float_rm:
; SSE2_X86:       # BB#0: # %entry
; SSE2_X86-NEXT:    pushl %eax
; SSE2_X86-NEXT:    .cfi_def_cfa_offset 8
; SSE2_X86-NEXT:    movl {{[0-9]+}}(%esp), %eax
; SSE2_X86-NEXT:    cvtsi2ssl (%eax), %xmm0
; SSE2_X86-NEXT:    movss %xmm0, (%esp)
; SSE2_X86-NEXT:    flds (%esp)
; SSE2_X86-NEXT:    popl %eax
; SSE2_X86-NEXT:    .cfi_def_cfa_offset 4
; SSE2_X86-NEXT:    retl
;
; AVX_X86-LABEL: int_to_float_rm:
; AVX_X86:       # BB#0: # %entry
; AVX_X86-NEXT:    pushl %eax
; AVX_X86-NEXT:    .cfi_def_cfa_offset 8
; AVX_X86-NEXT:    movl {{[0-9]+}}(%esp), %eax
; AVX_X86-NEXT:    vcvtsi2ssl (%eax), %xmm0, %xmm0
; AVX_X86-NEXT:    vmovss %xmm0, (%esp)
; AVX_X86-NEXT:    flds (%esp)
; AVX_X86-NEXT:    popl %eax
; AVX_X86-NEXT:    .cfi_def_cfa_offset 4
; AVX_X86-NEXT:    retl
entry:
  %0 = load i32, i32* %a
  %1 = sitofp i32 %0 to float
  ret float %1
}

define float @int_to_float_rm_optsize(i32* %a) optsize {
; SSE2-LABEL: int_to_float_rm_optsize:
; SSE2:       # BB#0: # %entry
; SSE2-NEXT:    cvtsi2ssl (%rdi), %xmm0
; SSE2-NEXT:    retq
;
; AVX-LABEL: int_to_float_rm_optsize:
; AVX:       # BB#0: # %entry
; AVX-NEXT:    vcvtsi2ssl (%rdi), %xmm0, %xmm0
; AVX-NEXT:    retq
;
; SSE2_X86-LABEL: int_to_float_rm_optsize:
; SSE2_X86:       # BB#0: # %entry
; SSE2_X86-NEXT:    pushl %eax
; SSE2_X86-NEXT:    .cfi_def_cfa_offset 8
; SSE2_X86-NEXT:    movl {{[0-9]+}}(%esp), %eax
; SSE2_X86-NEXT:    cvtsi2ssl (%eax), %xmm0
; SSE2_X86-NEXT:    movss %xmm0, (%esp)
; SSE2_X86-NEXT:    flds (%esp)
; SSE2_X86-NEXT:    popl %eax
; SSE2_X86-NEXT:    .cfi_def_cfa_offset 4
; SSE2_X86-NEXT:    retl
;
; AVX_X86-LABEL: int_to_float_rm_optsize:
; AVX_X86:       # BB#0: # %entry
; AVX_X86-NEXT:    pushl %eax
; AVX_X86-NEXT:    .cfi_def_cfa_offset 8
; AVX_X86-NEXT:    movl {{[0-9]+}}(%esp), %eax
; AVX_X86-NEXT:    vcvtsi2ssl (%eax), %xmm0, %xmm0
; AVX_X86-NEXT:    vmovss %xmm0, (%esp)
; AVX_X86-NEXT:    flds (%esp)
; AVX_X86-NEXT:    popl %eax
; AVX_X86-NEXT:    .cfi_def_cfa_offset 4
; AVX_X86-NEXT:    retl
entry:
  %0 = load i32, i32* %a
  %1 = sitofp i32 %0 to float
  ret float %1
}

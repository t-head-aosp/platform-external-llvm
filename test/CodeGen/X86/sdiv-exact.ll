; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc < %s -mtriple=i686-unknown -mattr=+sse2 | FileCheck %s --check-prefix=X86
; RUN: llc < %s -mtriple=x86_64-unknown -mattr=+avx2 | FileCheck %s --check-prefix=X64

define i32 @test1(i32 %x) {
; X86-LABEL: test1:
; X86:       # %bb.0:
; X86-NEXT:    imull $-1030792151, {{[0-9]+}}(%esp), %eax # imm = 0xC28F5C29
; X86-NEXT:    retl
;
; X64-LABEL: test1:
; X64:       # %bb.0:
; X64-NEXT:    imull $-1030792151, %edi, %eax # imm = 0xC28F5C29
; X64-NEXT:    retq
  %div = sdiv exact i32 %x, 25
  ret i32 %div
}

define i32 @test2(i32 %x) {
; X86-LABEL: test2:
; X86:       # %bb.0:
; X86-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-NEXT:    sarl $3, %eax
; X86-NEXT:    imull $-1431655765, %eax, %eax # imm = 0xAAAAAAAB
; X86-NEXT:    retl
;
; X64-LABEL: test2:
; X64:       # %bb.0:
; X64-NEXT:    sarl $3, %edi
; X64-NEXT:    imull $-1431655765, %edi, %eax # imm = 0xAAAAAAAB
; X64-NEXT:    retq
  %div = sdiv exact i32 %x, 24
  ret i32 %div
}

define <4 x i32> @test3(<4 x i32> %x) {
; X86-LABEL: test3:
; X86:       # %bb.0:
; X86-NEXT:    psrad $3, %xmm0
; X86-NEXT:    movdqa {{.*#+}} xmm1 = [2863311531,2863311531,2863311531,2863311531]
; X86-NEXT:    pshufd {{.*#+}} xmm2 = xmm0[1,1,3,3]
; X86-NEXT:    pmuludq %xmm1, %xmm0
; X86-NEXT:    pshufd {{.*#+}} xmm0 = xmm0[0,2,2,3]
; X86-NEXT:    pmuludq %xmm1, %xmm2
; X86-NEXT:    pshufd {{.*#+}} xmm1 = xmm2[0,2,2,3]
; X86-NEXT:    punpckldq {{.*#+}} xmm0 = xmm0[0],xmm1[0],xmm0[1],xmm1[1]
; X86-NEXT:    retl
;
; X64-LABEL: test3:
; X64:       # %bb.0:
; X64-NEXT:    vpsrad $3, %xmm0, %xmm0
; X64-NEXT:    vpbroadcastd {{.*#+}} xmm1 = [2863311531,2863311531,2863311531,2863311531]
; X64-NEXT:    vpmulld %xmm1, %xmm0, %xmm0
; X64-NEXT:    retq
  %div = sdiv exact <4 x i32> %x, <i32 24, i32 24, i32 24, i32 24>
  ret <4 x i32> %div
}

define <4 x i32> @test4(<4 x i32> %x) {
; X86-LABEL: test4:
; X86:       # %bb.0:
; X86-NEXT:    movdqa {{.*#+}} xmm1 = [3264175145,3264175145,3264175145,3264175145]
; X86-NEXT:    pshufd {{.*#+}} xmm2 = xmm0[1,1,3,3]
; X86-NEXT:    pmuludq %xmm1, %xmm0
; X86-NEXT:    pshufd {{.*#+}} xmm0 = xmm0[0,2,2,3]
; X86-NEXT:    pmuludq %xmm1, %xmm2
; X86-NEXT:    pshufd {{.*#+}} xmm1 = xmm2[0,2,2,3]
; X86-NEXT:    punpckldq {{.*#+}} xmm0 = xmm0[0],xmm1[0],xmm0[1],xmm1[1]
; X86-NEXT:    retl
;
; X64-LABEL: test4:
; X64:       # %bb.0:
; X64-NEXT:    vpbroadcastd {{.*#+}} xmm1 = [3264175145,3264175145,3264175145,3264175145]
; X64-NEXT:    vpmulld %xmm1, %xmm0, %xmm0
; X64-NEXT:    retq
  %div = sdiv exact <4 x i32> %x, <i32 25, i32 25, i32 25, i32 25>
  ret <4 x i32> %div
}

define <4 x i32> @test5(<4 x i32> %x) {
; X86-LABEL: test5:
; X86:       # %bb.0:
; X86-NEXT:    pshufd {{.*#+}} xmm1 = xmm0[3,1,2,3]
; X86-NEXT:    movd %xmm1, %eax
; X86-NEXT:    imull $-1030792151, %eax, %eax # imm = 0xC28F5C29
; X86-NEXT:    movd %eax, %xmm1
; X86-NEXT:    pshufd {{.*#+}} xmm2 = xmm0[2,3,0,1]
; X86-NEXT:    movd %xmm2, %eax
; X86-NEXT:    imull $-1030792151, %eax, %eax # imm = 0xC28F5C29
; X86-NEXT:    movd %eax, %xmm2
; X86-NEXT:    punpckldq {{.*#+}} xmm2 = xmm2[0],xmm1[0],xmm2[1],xmm1[1]
; X86-NEXT:    movd %xmm0, %eax
; X86-NEXT:    sarl $3, %eax
; X86-NEXT:    imull $-1431655765, %eax, %eax # imm = 0xAAAAAAAB
; X86-NEXT:    movd %eax, %xmm1
; X86-NEXT:    pshufd {{.*#+}} xmm0 = xmm0[1,1,2,3]
; X86-NEXT:    movd %xmm0, %eax
; X86-NEXT:    sarl $3, %eax
; X86-NEXT:    imull $-1431655765, %eax, %eax # imm = 0xAAAAAAAB
; X86-NEXT:    movd %eax, %xmm0
; X86-NEXT:    punpckldq {{.*#+}} xmm1 = xmm1[0],xmm0[0],xmm1[1],xmm0[1]
; X86-NEXT:    punpcklqdq {{.*#+}} xmm1 = xmm1[0],xmm2[0]
; X86-NEXT:    movdqa %xmm1, %xmm0
; X86-NEXT:    retl
;
; X64-LABEL: test5:
; X64:       # %bb.0:
; X64-NEXT:    vpextrd $1, %xmm0, %eax
; X64-NEXT:    sarl $3, %eax
; X64-NEXT:    imull $-1431655765, %eax, %eax # imm = 0xAAAAAAAB
; X64-NEXT:    vmovd %xmm0, %ecx
; X64-NEXT:    sarl $3, %ecx
; X64-NEXT:    imull $-1431655765, %ecx, %ecx # imm = 0xAAAAAAAB
; X64-NEXT:    vmovd %ecx, %xmm1
; X64-NEXT:    vpinsrd $1, %eax, %xmm1, %xmm1
; X64-NEXT:    vpextrd $2, %xmm0, %eax
; X64-NEXT:    imull $-1030792151, %eax, %eax # imm = 0xC28F5C29
; X64-NEXT:    vpinsrd $2, %eax, %xmm1, %xmm1
; X64-NEXT:    vpextrd $3, %xmm0, %eax
; X64-NEXT:    imull $-1030792151, %eax, %eax # imm = 0xC28F5C29
; X64-NEXT:    vpinsrd $3, %eax, %xmm1, %xmm0
; X64-NEXT:    retq
  %div = sdiv exact <4 x i32> %x, <i32 24, i32 24, i32 25, i32 25>
  ret <4 x i32> %div
}

define <4 x i32> @test6(<4 x i32> %x) {
; X86-LABEL: test6:
; X86:       # %bb.0:
; X86-NEXT:    pshufd {{.*#+}} xmm1 = xmm0[3,1,2,3]
; X86-NEXT:    movd %xmm1, %eax
; X86-NEXT:    sarl %eax
; X86-NEXT:    imull $-991146299, %eax, %eax # imm = 0xC4EC4EC5
; X86-NEXT:    movd %eax, %xmm1
; X86-NEXT:    pshufd {{.*#+}} xmm2 = xmm0[2,3,0,1]
; X86-NEXT:    movd %xmm2, %eax
; X86-NEXT:    sarl %eax
; X86-NEXT:    imull $-991146299, %eax, %eax # imm = 0xC4EC4EC5
; X86-NEXT:    movd %eax, %xmm2
; X86-NEXT:    punpckldq {{.*#+}} xmm2 = xmm2[0],xmm1[0],xmm2[1],xmm1[1]
; X86-NEXT:    movd %xmm0, %eax
; X86-NEXT:    sarl $3, %eax
; X86-NEXT:    imull $-1431655765, %eax, %eax # imm = 0xAAAAAAAB
; X86-NEXT:    movd %eax, %xmm1
; X86-NEXT:    pshufd {{.*#+}} xmm0 = xmm0[1,1,2,3]
; X86-NEXT:    movd %xmm0, %eax
; X86-NEXT:    sarl $3, %eax
; X86-NEXT:    imull $-1431655765, %eax, %eax # imm = 0xAAAAAAAB
; X86-NEXT:    movd %eax, %xmm0
; X86-NEXT:    punpckldq {{.*#+}} xmm1 = xmm1[0],xmm0[0],xmm1[1],xmm0[1]
; X86-NEXT:    punpcklqdq {{.*#+}} xmm1 = xmm1[0],xmm2[0]
; X86-NEXT:    movdqa %xmm1, %xmm0
; X86-NEXT:    retl
;
; X64-LABEL: test6:
; X64:       # %bb.0:
; X64-NEXT:    vpextrd $1, %xmm0, %eax
; X64-NEXT:    sarl $3, %eax
; X64-NEXT:    imull $-1431655765, %eax, %eax # imm = 0xAAAAAAAB
; X64-NEXT:    vmovd %xmm0, %ecx
; X64-NEXT:    sarl $3, %ecx
; X64-NEXT:    imull $-1431655765, %ecx, %ecx # imm = 0xAAAAAAAB
; X64-NEXT:    vmovd %ecx, %xmm1
; X64-NEXT:    vpinsrd $1, %eax, %xmm1, %xmm1
; X64-NEXT:    vpextrd $2, %xmm0, %eax
; X64-NEXT:    sarl %eax
; X64-NEXT:    imull $-991146299, %eax, %eax # imm = 0xC4EC4EC5
; X64-NEXT:    vpinsrd $2, %eax, %xmm1, %xmm1
; X64-NEXT:    vpextrd $3, %xmm0, %eax
; X64-NEXT:    sarl %eax
; X64-NEXT:    imull $-991146299, %eax, %eax # imm = 0xC4EC4EC5
; X64-NEXT:    vpinsrd $3, %eax, %xmm1, %xmm0
; X64-NEXT:    retq
  %div = sdiv exact <4 x i32> %x, <i32 24, i32 24, i32 26, i32 26>
  ret <4 x i32> %div
}

define <4 x i32> @test7(<4 x i32> %x) {
; X86-LABEL: test7:
; X86:       # %bb.0:
; X86-NEXT:    pshufd {{.*#+}} xmm1 = xmm0[3,1,2,3]
; X86-NEXT:    movd %xmm1, %eax
; X86-NEXT:    imull $1749801491, %eax, %eax # imm = 0x684BDA13
; X86-NEXT:    movd %eax, %xmm1
; X86-NEXT:    pshufd {{.*#+}} xmm2 = xmm0[2,3,0,1]
; X86-NEXT:    movd %xmm2, %eax
; X86-NEXT:    imull $1749801491, %eax, %eax # imm = 0x684BDA13
; X86-NEXT:    movd %eax, %xmm2
; X86-NEXT:    punpckldq {{.*#+}} xmm2 = xmm2[0],xmm1[0],xmm2[1],xmm1[1]
; X86-NEXT:    movd %xmm0, %eax
; X86-NEXT:    imull $-1030792151, %eax, %eax # imm = 0xC28F5C29
; X86-NEXT:    movd %eax, %xmm1
; X86-NEXT:    pshufd {{.*#+}} xmm0 = xmm0[1,1,2,3]
; X86-NEXT:    movd %xmm0, %eax
; X86-NEXT:    imull $-1030792151, %eax, %eax # imm = 0xC28F5C29
; X86-NEXT:    movd %eax, %xmm0
; X86-NEXT:    punpckldq {{.*#+}} xmm1 = xmm1[0],xmm0[0],xmm1[1],xmm0[1]
; X86-NEXT:    punpcklqdq {{.*#+}} xmm1 = xmm1[0],xmm2[0]
; X86-NEXT:    movdqa %xmm1, %xmm0
; X86-NEXT:    retl
;
; X64-LABEL: test7:
; X64:       # %bb.0:
; X64-NEXT:    vpextrd $1, %xmm0, %eax
; X64-NEXT:    imull $-1030792151, %eax, %eax # imm = 0xC28F5C29
; X64-NEXT:    vmovd %xmm0, %ecx
; X64-NEXT:    imull $-1030792151, %ecx, %ecx # imm = 0xC28F5C29
; X64-NEXT:    vmovd %ecx, %xmm1
; X64-NEXT:    vpinsrd $1, %eax, %xmm1, %xmm1
; X64-NEXT:    vpextrd $2, %xmm0, %eax
; X64-NEXT:    imull $1749801491, %eax, %eax # imm = 0x684BDA13
; X64-NEXT:    vpinsrd $2, %eax, %xmm1, %xmm1
; X64-NEXT:    vpextrd $3, %xmm0, %eax
; X64-NEXT:    imull $1749801491, %eax, %eax # imm = 0x684BDA13
; X64-NEXT:    vpinsrd $3, %eax, %xmm1, %xmm0
; X64-NEXT:    retq
  %div = sdiv exact <4 x i32> %x, <i32 25, i32 25, i32 27, i32 27>
  ret <4 x i32> %div
}

define <4 x i32> @test8(<4 x i32> %x) {
; X86-LABEL: test8:
; X86:       # %bb.0:
; X86-NEXT:    pshufd {{.*#+}} xmm1 = xmm0[2,3,0,1]
; X86-NEXT:    movd %xmm1, %eax
; X86-NEXT:    sarl $3, %eax
; X86-NEXT:    imull $-1431655765, %eax, %eax # imm = 0xAAAAAAAB
; X86-NEXT:    movd %eax, %xmm1
; X86-NEXT:    shufps {{.*#+}} xmm1 = xmm1[0,0],xmm0[3,0]
; X86-NEXT:    pshufd {{.*#+}} xmm2 = xmm0[3,1,2,3]
; X86-NEXT:    shufps {{.*#+}} xmm0 = xmm0[0,1],xmm1[0,2]
; X86-NEXT:    movd %xmm2, %eax
; X86-NEXT:    sarl $3, %eax
; X86-NEXT:    imull $-1431655765, %eax, %eax # imm = 0xAAAAAAAB
; X86-NEXT:    movd %eax, %xmm1
; X86-NEXT:    shufps {{.*#+}} xmm1 = xmm1[0,0],xmm0[2,0]
; X86-NEXT:    shufps {{.*#+}} xmm0 = xmm0[0,1],xmm1[2,0]
; X86-NEXT:    retl
;
; X64-LABEL: test8:
; X64:       # %bb.0:
; X64-NEXT:    vpextrd $2, %xmm0, %eax
; X64-NEXT:    sarl $3, %eax
; X64-NEXT:    imull $-1431655765, %eax, %eax # imm = 0xAAAAAAAB
; X64-NEXT:    vpinsrd $2, %eax, %xmm0, %xmm1
; X64-NEXT:    vpextrd $3, %xmm0, %eax
; X64-NEXT:    sarl $3, %eax
; X64-NEXT:    imull $-1431655765, %eax, %eax # imm = 0xAAAAAAAB
; X64-NEXT:    vpinsrd $3, %eax, %xmm1, %xmm0
; X64-NEXT:    retq
  %div = sdiv exact <4 x i32> %x, <i32 1, i32 1, i32 24, i32 24>
  ret <4 x i32> %div
}

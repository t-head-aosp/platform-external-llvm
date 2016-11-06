; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc < %s -mtriple=i386-apple-darwin -mattr=-avx,+sse4.2 -show-mc-encoding | FileCheck %s --check-prefix=SSE42
; RUN: llc < %s -mtriple=i386-apple-darwin -mattr=+avx2 -show-mc-encoding | FileCheck %s --check-prefix=VCHECK --check-prefix=AVX2
; RUN: llc < %s -mtriple=i386-apple-darwin -mcpu=skx -show-mc-encoding | FileCheck %s --check-prefix=VCHECK --check-prefix=SKX

define i32 @test_x86_sse42_pcmpestri128(<16 x i8> %a0, <16 x i8> %a2) {
; SSE42-LABEL: test_x86_sse42_pcmpestri128:
; SSE42:       ## BB#0:
; SSE42-NEXT:    movl $7, %eax ## encoding: [0xb8,0x07,0x00,0x00,0x00]
; SSE42-NEXT:    movl $7, %edx ## encoding: [0xba,0x07,0x00,0x00,0x00]
; SSE42-NEXT:    pcmpestri $7, %xmm1, %xmm0 ## encoding: [0x66,0x0f,0x3a,0x61,0xc1,0x07]
; SSE42-NEXT:    movl %ecx, %eax ## encoding: [0x89,0xc8]
; SSE42-NEXT:    retl ## encoding: [0xc3]
;
; VCHECK-LABEL: test_x86_sse42_pcmpestri128:
; VCHECK:       ## BB#0:
; VCHECK-NEXT:    movl $7, %eax ## encoding: [0xb8,0x07,0x00,0x00,0x00]
; VCHECK-NEXT:    movl $7, %edx ## encoding: [0xba,0x07,0x00,0x00,0x00]
; VCHECK-NEXT:    vpcmpestri $7, %xmm1, %xmm0 ## encoding: [0xc4,0xe3,0x79,0x61,0xc1,0x07]
; VCHECK-NEXT:    movl %ecx, %eax ## encoding: [0x89,0xc8]
; VCHECK-NEXT:    retl ## encoding: [0xc3]
  %res = call i32 @llvm.x86.sse42.pcmpestri128(<16 x i8> %a0, i32 7, <16 x i8> %a2, i32 7, i8 7) ; <i32> [#uses=1]
  ret i32 %res
}
declare i32 @llvm.x86.sse42.pcmpestri128(<16 x i8>, i32, <16 x i8>, i32, i8) nounwind readnone


define i32 @test_x86_sse42_pcmpestri128_load(<16 x i8>* %a0, <16 x i8>* %a2) {
; SSE42-LABEL: test_x86_sse42_pcmpestri128_load:
; SSE42:       ## BB#0:
; SSE42-NEXT:    movl {{[0-9]+}}(%esp), %ecx ## encoding: [0x8b,0x4c,0x24,0x08]
; SSE42-NEXT:    movl {{[0-9]+}}(%esp), %eax ## encoding: [0x8b,0x44,0x24,0x04]
; SSE42-NEXT:    movdqa (%eax), %xmm0 ## encoding: [0x66,0x0f,0x6f,0x00]
; SSE42-NEXT:    movl $7, %eax ## encoding: [0xb8,0x07,0x00,0x00,0x00]
; SSE42-NEXT:    movl $7, %edx ## encoding: [0xba,0x07,0x00,0x00,0x00]
; SSE42-NEXT:    pcmpestri $7, (%ecx), %xmm0 ## encoding: [0x66,0x0f,0x3a,0x61,0x01,0x07]
; SSE42-NEXT:    movl %ecx, %eax ## encoding: [0x89,0xc8]
; SSE42-NEXT:    retl ## encoding: [0xc3]
;
; AVX2-LABEL: test_x86_sse42_pcmpestri128_load:
; AVX2:       ## BB#0:
; AVX2-NEXT:    movl {{[0-9]+}}(%esp), %ecx ## encoding: [0x8b,0x4c,0x24,0x08]
; AVX2-NEXT:    movl {{[0-9]+}}(%esp), %eax ## encoding: [0x8b,0x44,0x24,0x04]
; AVX2-NEXT:    vmovdqa (%eax), %xmm0 ## encoding: [0xc5,0xf9,0x6f,0x00]
; AVX2-NEXT:    movl $7, %eax ## encoding: [0xb8,0x07,0x00,0x00,0x00]
; AVX2-NEXT:    movl $7, %edx ## encoding: [0xba,0x07,0x00,0x00,0x00]
; AVX2-NEXT:    vpcmpestri $7, (%ecx), %xmm0 ## encoding: [0xc4,0xe3,0x79,0x61,0x01,0x07]
; AVX2-NEXT:    movl %ecx, %eax ## encoding: [0x89,0xc8]
; AVX2-NEXT:    retl ## encoding: [0xc3]
;
; SKX-LABEL: test_x86_sse42_pcmpestri128_load:
; SKX:       ## BB#0:
; SKX-NEXT:    movl {{[0-9]+}}(%esp), %ecx ## encoding: [0x8b,0x4c,0x24,0x08]
; SKX-NEXT:    movl {{[0-9]+}}(%esp), %eax ## encoding: [0x8b,0x44,0x24,0x04]
; SKX-NEXT:    vmovdqu8 (%eax), %xmm0 ## encoding: [0x62,0xf1,0x7f,0x08,0x6f,0x00]
; SKX-NEXT:    movl $7, %eax ## encoding: [0xb8,0x07,0x00,0x00,0x00]
; SKX-NEXT:    movl $7, %edx ## encoding: [0xba,0x07,0x00,0x00,0x00]
; SKX-NEXT:    vpcmpestri $7, (%ecx), %xmm0 ## encoding: [0xc4,0xe3,0x79,0x61,0x01,0x07]
; SKX-NEXT:    movl %ecx, %eax ## encoding: [0x89,0xc8]
; SKX-NEXT:    retl ## encoding: [0xc3]
  %1 = load <16 x i8>, <16 x i8>* %a0
  %2 = load <16 x i8>, <16 x i8>* %a2
  %res = call i32 @llvm.x86.sse42.pcmpestri128(<16 x i8> %1, i32 7, <16 x i8> %2, i32 7, i8 7) ; <i32> [#uses=1]
  ret i32 %res
}


define i32 @test_x86_sse42_pcmpestria128(<16 x i8> %a0, <16 x i8> %a2) nounwind {
; SSE42-LABEL: test_x86_sse42_pcmpestria128:
; SSE42:       ## BB#0:
; SSE42-NEXT:    pushl %ebx ## encoding: [0x53]
; SSE42-NEXT:    movl $7, %eax ## encoding: [0xb8,0x07,0x00,0x00,0x00]
; SSE42-NEXT:    movl $7, %edx ## encoding: [0xba,0x07,0x00,0x00,0x00]
; SSE42-NEXT:    xorl %ebx, %ebx ## encoding: [0x31,0xdb]
; SSE42-NEXT:    pcmpestri $7, %xmm1, %xmm0 ## encoding: [0x66,0x0f,0x3a,0x61,0xc1,0x07]
; SSE42-NEXT:    seta %bl ## encoding: [0x0f,0x97,0xc3]
; SSE42-NEXT:    movl %ebx, %eax ## encoding: [0x89,0xd8]
; SSE42-NEXT:    popl %ebx ## encoding: [0x5b]
; SSE42-NEXT:    retl ## encoding: [0xc3]
;
; VCHECK-LABEL: test_x86_sse42_pcmpestria128:
; VCHECK:       ## BB#0:
; VCHECK-NEXT:    pushl %ebx ## encoding: [0x53]
; VCHECK-NEXT:    movl $7, %eax ## encoding: [0xb8,0x07,0x00,0x00,0x00]
; VCHECK-NEXT:    movl $7, %edx ## encoding: [0xba,0x07,0x00,0x00,0x00]
; VCHECK-NEXT:    xorl %ebx, %ebx ## encoding: [0x31,0xdb]
; VCHECK-NEXT:    vpcmpestri $7, %xmm1, %xmm0 ## encoding: [0xc4,0xe3,0x79,0x61,0xc1,0x07]
; VCHECK-NEXT:    seta %bl ## encoding: [0x0f,0x97,0xc3]
; VCHECK-NEXT:    movl %ebx, %eax ## encoding: [0x89,0xd8]
; VCHECK-NEXT:    popl %ebx ## encoding: [0x5b]
; VCHECK-NEXT:    retl ## encoding: [0xc3]
  %res = call i32 @llvm.x86.sse42.pcmpestria128(<16 x i8> %a0, i32 7, <16 x i8> %a2, i32 7, i8 7) ; <i32> [#uses=1]
  ret i32 %res
}
declare i32 @llvm.x86.sse42.pcmpestria128(<16 x i8>, i32, <16 x i8>, i32, i8) nounwind readnone


define i32 @test_x86_sse42_pcmpestric128(<16 x i8> %a0, <16 x i8> %a2) {
; SSE42-LABEL: test_x86_sse42_pcmpestric128:
; SSE42:       ## BB#0:
; SSE42-NEXT:    movl $7, %eax ## encoding: [0xb8,0x07,0x00,0x00,0x00]
; SSE42-NEXT:    movl $7, %edx ## encoding: [0xba,0x07,0x00,0x00,0x00]
; SSE42-NEXT:    pcmpestri $7, %xmm1, %xmm0 ## encoding: [0x66,0x0f,0x3a,0x61,0xc1,0x07]
; SSE42-NEXT:    sbbl %eax, %eax ## encoding: [0x19,0xc0]
; SSE42-NEXT:    andl $1, %eax ## encoding: [0x83,0xe0,0x01]
; SSE42-NEXT:    retl ## encoding: [0xc3]
;
; VCHECK-LABEL: test_x86_sse42_pcmpestric128:
; VCHECK:       ## BB#0:
; VCHECK-NEXT:    movl $7, %eax ## encoding: [0xb8,0x07,0x00,0x00,0x00]
; VCHECK-NEXT:    movl $7, %edx ## encoding: [0xba,0x07,0x00,0x00,0x00]
; VCHECK-NEXT:    vpcmpestri $7, %xmm1, %xmm0 ## encoding: [0xc4,0xe3,0x79,0x61,0xc1,0x07]
; VCHECK-NEXT:    sbbl %eax, %eax ## encoding: [0x19,0xc0]
; VCHECK-NEXT:    andl $1, %eax ## encoding: [0x83,0xe0,0x01]
; VCHECK-NEXT:    retl ## encoding: [0xc3]
  %res = call i32 @llvm.x86.sse42.pcmpestric128(<16 x i8> %a0, i32 7, <16 x i8> %a2, i32 7, i8 7) ; <i32> [#uses=1]
  ret i32 %res
}
declare i32 @llvm.x86.sse42.pcmpestric128(<16 x i8>, i32, <16 x i8>, i32, i8) nounwind readnone


define i32 @test_x86_sse42_pcmpestrio128(<16 x i8> %a0, <16 x i8> %a2) nounwind {
; SSE42-LABEL: test_x86_sse42_pcmpestrio128:
; SSE42:       ## BB#0:
; SSE42-NEXT:    pushl %ebx ## encoding: [0x53]
; SSE42-NEXT:    movl $7, %eax ## encoding: [0xb8,0x07,0x00,0x00,0x00]
; SSE42-NEXT:    movl $7, %edx ## encoding: [0xba,0x07,0x00,0x00,0x00]
; SSE42-NEXT:    xorl %ebx, %ebx ## encoding: [0x31,0xdb]
; SSE42-NEXT:    pcmpestri $7, %xmm1, %xmm0 ## encoding: [0x66,0x0f,0x3a,0x61,0xc1,0x07]
; SSE42-NEXT:    seto %bl ## encoding: [0x0f,0x90,0xc3]
; SSE42-NEXT:    movl %ebx, %eax ## encoding: [0x89,0xd8]
; SSE42-NEXT:    popl %ebx ## encoding: [0x5b]
; SSE42-NEXT:    retl ## encoding: [0xc3]
;
; VCHECK-LABEL: test_x86_sse42_pcmpestrio128:
; VCHECK:       ## BB#0:
; VCHECK-NEXT:    pushl %ebx ## encoding: [0x53]
; VCHECK-NEXT:    movl $7, %eax ## encoding: [0xb8,0x07,0x00,0x00,0x00]
; VCHECK-NEXT:    movl $7, %edx ## encoding: [0xba,0x07,0x00,0x00,0x00]
; VCHECK-NEXT:    xorl %ebx, %ebx ## encoding: [0x31,0xdb]
; VCHECK-NEXT:    vpcmpestri $7, %xmm1, %xmm0 ## encoding: [0xc4,0xe3,0x79,0x61,0xc1,0x07]
; VCHECK-NEXT:    seto %bl ## encoding: [0x0f,0x90,0xc3]
; VCHECK-NEXT:    movl %ebx, %eax ## encoding: [0x89,0xd8]
; VCHECK-NEXT:    popl %ebx ## encoding: [0x5b]
; VCHECK-NEXT:    retl ## encoding: [0xc3]
  %res = call i32 @llvm.x86.sse42.pcmpestrio128(<16 x i8> %a0, i32 7, <16 x i8> %a2, i32 7, i8 7) ; <i32> [#uses=1]
  ret i32 %res
}
declare i32 @llvm.x86.sse42.pcmpestrio128(<16 x i8>, i32, <16 x i8>, i32, i8) nounwind readnone


define i32 @test_x86_sse42_pcmpestris128(<16 x i8> %a0, <16 x i8> %a2) nounwind {
; SSE42-LABEL: test_x86_sse42_pcmpestris128:
; SSE42:       ## BB#0:
; SSE42-NEXT:    pushl %ebx ## encoding: [0x53]
; SSE42-NEXT:    movl $7, %eax ## encoding: [0xb8,0x07,0x00,0x00,0x00]
; SSE42-NEXT:    movl $7, %edx ## encoding: [0xba,0x07,0x00,0x00,0x00]
; SSE42-NEXT:    xorl %ebx, %ebx ## encoding: [0x31,0xdb]
; SSE42-NEXT:    pcmpestri $7, %xmm1, %xmm0 ## encoding: [0x66,0x0f,0x3a,0x61,0xc1,0x07]
; SSE42-NEXT:    sets %bl ## encoding: [0x0f,0x98,0xc3]
; SSE42-NEXT:    movl %ebx, %eax ## encoding: [0x89,0xd8]
; SSE42-NEXT:    popl %ebx ## encoding: [0x5b]
; SSE42-NEXT:    retl ## encoding: [0xc3]
;
; VCHECK-LABEL: test_x86_sse42_pcmpestris128:
; VCHECK:       ## BB#0:
; VCHECK-NEXT:    pushl %ebx ## encoding: [0x53]
; VCHECK-NEXT:    movl $7, %eax ## encoding: [0xb8,0x07,0x00,0x00,0x00]
; VCHECK-NEXT:    movl $7, %edx ## encoding: [0xba,0x07,0x00,0x00,0x00]
; VCHECK-NEXT:    xorl %ebx, %ebx ## encoding: [0x31,0xdb]
; VCHECK-NEXT:    vpcmpestri $7, %xmm1, %xmm0 ## encoding: [0xc4,0xe3,0x79,0x61,0xc1,0x07]
; VCHECK-NEXT:    sets %bl ## encoding: [0x0f,0x98,0xc3]
; VCHECK-NEXT:    movl %ebx, %eax ## encoding: [0x89,0xd8]
; VCHECK-NEXT:    popl %ebx ## encoding: [0x5b]
; VCHECK-NEXT:    retl ## encoding: [0xc3]
  %res = call i32 @llvm.x86.sse42.pcmpestris128(<16 x i8> %a0, i32 7, <16 x i8> %a2, i32 7, i8 7) ; <i32> [#uses=1]
  ret i32 %res
}
declare i32 @llvm.x86.sse42.pcmpestris128(<16 x i8>, i32, <16 x i8>, i32, i8) nounwind readnone


define i32 @test_x86_sse42_pcmpestriz128(<16 x i8> %a0, <16 x i8> %a2) nounwind {
; SSE42-LABEL: test_x86_sse42_pcmpestriz128:
; SSE42:       ## BB#0:
; SSE42-NEXT:    pushl %ebx ## encoding: [0x53]
; SSE42-NEXT:    movl $7, %eax ## encoding: [0xb8,0x07,0x00,0x00,0x00]
; SSE42-NEXT:    movl $7, %edx ## encoding: [0xba,0x07,0x00,0x00,0x00]
; SSE42-NEXT:    xorl %ebx, %ebx ## encoding: [0x31,0xdb]
; SSE42-NEXT:    pcmpestri $7, %xmm1, %xmm0 ## encoding: [0x66,0x0f,0x3a,0x61,0xc1,0x07]
; SSE42-NEXT:    sete %bl ## encoding: [0x0f,0x94,0xc3]
; SSE42-NEXT:    movl %ebx, %eax ## encoding: [0x89,0xd8]
; SSE42-NEXT:    popl %ebx ## encoding: [0x5b]
; SSE42-NEXT:    retl ## encoding: [0xc3]
;
; VCHECK-LABEL: test_x86_sse42_pcmpestriz128:
; VCHECK:       ## BB#0:
; VCHECK-NEXT:    pushl %ebx ## encoding: [0x53]
; VCHECK-NEXT:    movl $7, %eax ## encoding: [0xb8,0x07,0x00,0x00,0x00]
; VCHECK-NEXT:    movl $7, %edx ## encoding: [0xba,0x07,0x00,0x00,0x00]
; VCHECK-NEXT:    xorl %ebx, %ebx ## encoding: [0x31,0xdb]
; VCHECK-NEXT:    vpcmpestri $7, %xmm1, %xmm0 ## encoding: [0xc4,0xe3,0x79,0x61,0xc1,0x07]
; VCHECK-NEXT:    sete %bl ## encoding: [0x0f,0x94,0xc3]
; VCHECK-NEXT:    movl %ebx, %eax ## encoding: [0x89,0xd8]
; VCHECK-NEXT:    popl %ebx ## encoding: [0x5b]
; VCHECK-NEXT:    retl ## encoding: [0xc3]
  %res = call i32 @llvm.x86.sse42.pcmpestriz128(<16 x i8> %a0, i32 7, <16 x i8> %a2, i32 7, i8 7) ; <i32> [#uses=1]
  ret i32 %res
}
declare i32 @llvm.x86.sse42.pcmpestriz128(<16 x i8>, i32, <16 x i8>, i32, i8) nounwind readnone


define <16 x i8> @test_x86_sse42_pcmpestrm128(<16 x i8> %a0, <16 x i8> %a2) {
; SSE42-LABEL: test_x86_sse42_pcmpestrm128:
; SSE42:       ## BB#0:
; SSE42-NEXT:    movl $7, %eax ## encoding: [0xb8,0x07,0x00,0x00,0x00]
; SSE42-NEXT:    movl $7, %edx ## encoding: [0xba,0x07,0x00,0x00,0x00]
; SSE42-NEXT:    pcmpestrm $7, %xmm1, %xmm0 ## encoding: [0x66,0x0f,0x3a,0x60,0xc1,0x07]
; SSE42-NEXT:    retl ## encoding: [0xc3]
;
; VCHECK-LABEL: test_x86_sse42_pcmpestrm128:
; VCHECK:       ## BB#0:
; VCHECK-NEXT:    movl $7, %eax ## encoding: [0xb8,0x07,0x00,0x00,0x00]
; VCHECK-NEXT:    movl $7, %edx ## encoding: [0xba,0x07,0x00,0x00,0x00]
; VCHECK-NEXT:    vpcmpestrm $7, %xmm1, %xmm0 ## encoding: [0xc4,0xe3,0x79,0x60,0xc1,0x07]
; VCHECK-NEXT:    retl ## encoding: [0xc3]
  %res = call <16 x i8> @llvm.x86.sse42.pcmpestrm128(<16 x i8> %a0, i32 7, <16 x i8> %a2, i32 7, i8 7) ; <<16 x i8>> [#uses=1]
  ret <16 x i8> %res
}
declare <16 x i8> @llvm.x86.sse42.pcmpestrm128(<16 x i8>, i32, <16 x i8>, i32, i8) nounwind readnone


define <16 x i8> @test_x86_sse42_pcmpestrm128_load(<16 x i8> %a0, <16 x i8>* %a2) {
; SSE42-LABEL: test_x86_sse42_pcmpestrm128_load:
; SSE42:       ## BB#0:
; SSE42-NEXT:    movl {{[0-9]+}}(%esp), %ecx ## encoding: [0x8b,0x4c,0x24,0x04]
; SSE42-NEXT:    movl $7, %eax ## encoding: [0xb8,0x07,0x00,0x00,0x00]
; SSE42-NEXT:    movl $7, %edx ## encoding: [0xba,0x07,0x00,0x00,0x00]
; SSE42-NEXT:    pcmpestrm $7, (%ecx), %xmm0 ## encoding: [0x66,0x0f,0x3a,0x60,0x01,0x07]
; SSE42-NEXT:    retl ## encoding: [0xc3]
;
; VCHECK-LABEL: test_x86_sse42_pcmpestrm128_load:
; VCHECK:       ## BB#0:
; VCHECK-NEXT:    movl {{[0-9]+}}(%esp), %ecx ## encoding: [0x8b,0x4c,0x24,0x04]
; VCHECK-NEXT:    movl $7, %eax ## encoding: [0xb8,0x07,0x00,0x00,0x00]
; VCHECK-NEXT:    movl $7, %edx ## encoding: [0xba,0x07,0x00,0x00,0x00]
; VCHECK-NEXT:    vpcmpestrm $7, (%ecx), %xmm0 ## encoding: [0xc4,0xe3,0x79,0x60,0x01,0x07]
; VCHECK-NEXT:    retl ## encoding: [0xc3]
  %1 = load <16 x i8>, <16 x i8>* %a2
  %res = call <16 x i8> @llvm.x86.sse42.pcmpestrm128(<16 x i8> %a0, i32 7, <16 x i8> %1, i32 7, i8 7) ; <<16 x i8>> [#uses=1]
  ret <16 x i8> %res
}


define i32 @test_x86_sse42_pcmpistri128(<16 x i8> %a0, <16 x i8> %a1) {
; SSE42-LABEL: test_x86_sse42_pcmpistri128:
; SSE42:       ## BB#0:
; SSE42-NEXT:    pcmpistri $7, %xmm1, %xmm0 ## encoding: [0x66,0x0f,0x3a,0x63,0xc1,0x07]
; SSE42-NEXT:    movl %ecx, %eax ## encoding: [0x89,0xc8]
; SSE42-NEXT:    retl ## encoding: [0xc3]
;
; VCHECK-LABEL: test_x86_sse42_pcmpistri128:
; VCHECK:       ## BB#0:
; VCHECK-NEXT:    vpcmpistri $7, %xmm1, %xmm0 ## encoding: [0xc4,0xe3,0x79,0x63,0xc1,0x07]
; VCHECK-NEXT:    movl %ecx, %eax ## encoding: [0x89,0xc8]
; VCHECK-NEXT:    retl ## encoding: [0xc3]
  %res = call i32 @llvm.x86.sse42.pcmpistri128(<16 x i8> %a0, <16 x i8> %a1, i8 7) ; <i32> [#uses=1]
  ret i32 %res
}
declare i32 @llvm.x86.sse42.pcmpistri128(<16 x i8>, <16 x i8>, i8) nounwind readnone


define i32 @test_x86_sse42_pcmpistri128_load(<16 x i8>* %a0, <16 x i8>* %a1) {
; SSE42-LABEL: test_x86_sse42_pcmpistri128_load:
; SSE42:       ## BB#0:
; SSE42-NEXT:    movl {{[0-9]+}}(%esp), %eax ## encoding: [0x8b,0x44,0x24,0x08]
; SSE42-NEXT:    movl {{[0-9]+}}(%esp), %ecx ## encoding: [0x8b,0x4c,0x24,0x04]
; SSE42-NEXT:    movdqa (%ecx), %xmm0 ## encoding: [0x66,0x0f,0x6f,0x01]
; SSE42-NEXT:    pcmpistri $7, (%eax), %xmm0 ## encoding: [0x66,0x0f,0x3a,0x63,0x00,0x07]
; SSE42-NEXT:    movl %ecx, %eax ## encoding: [0x89,0xc8]
; SSE42-NEXT:    retl ## encoding: [0xc3]
;
; AVX2-LABEL: test_x86_sse42_pcmpistri128_load:
; AVX2:       ## BB#0:
; AVX2-NEXT:    movl {{[0-9]+}}(%esp), %eax ## encoding: [0x8b,0x44,0x24,0x08]
; AVX2-NEXT:    movl {{[0-9]+}}(%esp), %ecx ## encoding: [0x8b,0x4c,0x24,0x04]
; AVX2-NEXT:    vmovdqa (%ecx), %xmm0 ## encoding: [0xc5,0xf9,0x6f,0x01]
; AVX2-NEXT:    vpcmpistri $7, (%eax), %xmm0 ## encoding: [0xc4,0xe3,0x79,0x63,0x00,0x07]
; AVX2-NEXT:    movl %ecx, %eax ## encoding: [0x89,0xc8]
; AVX2-NEXT:    retl ## encoding: [0xc3]
;
; SKX-LABEL: test_x86_sse42_pcmpistri128_load:
; SKX:       ## BB#0:
; SKX-NEXT:    movl {{[0-9]+}}(%esp), %eax ## encoding: [0x8b,0x44,0x24,0x08]
; SKX-NEXT:    movl {{[0-9]+}}(%esp), %ecx ## encoding: [0x8b,0x4c,0x24,0x04]
; SKX-NEXT:    vmovdqu8 (%ecx), %xmm0 ## encoding: [0x62,0xf1,0x7f,0x08,0x6f,0x01]
; SKX-NEXT:    vpcmpistri $7, (%eax), %xmm0 ## encoding: [0xc4,0xe3,0x79,0x63,0x00,0x07]
; SKX-NEXT:    movl %ecx, %eax ## encoding: [0x89,0xc8]
; SKX-NEXT:    retl ## encoding: [0xc3]
  %1 = load <16 x i8>, <16 x i8>* %a0
  %2 = load <16 x i8>, <16 x i8>* %a1
  %res = call i32 @llvm.x86.sse42.pcmpistri128(<16 x i8> %1, <16 x i8> %2, i8 7) ; <i32> [#uses=1]
  ret i32 %res
}


define i32 @test_x86_sse42_pcmpistria128(<16 x i8> %a0, <16 x i8> %a1) {
; SSE42-LABEL: test_x86_sse42_pcmpistria128:
; SSE42:       ## BB#0:
; SSE42-NEXT:    xorl %eax, %eax ## encoding: [0x31,0xc0]
; SSE42-NEXT:    pcmpistri $7, %xmm1, %xmm0 ## encoding: [0x66,0x0f,0x3a,0x63,0xc1,0x07]
; SSE42-NEXT:    seta %al ## encoding: [0x0f,0x97,0xc0]
; SSE42-NEXT:    retl ## encoding: [0xc3]
;
; VCHECK-LABEL: test_x86_sse42_pcmpistria128:
; VCHECK:       ## BB#0:
; VCHECK-NEXT:    xorl %eax, %eax ## encoding: [0x31,0xc0]
; VCHECK-NEXT:    vpcmpistri $7, %xmm1, %xmm0 ## encoding: [0xc4,0xe3,0x79,0x63,0xc1,0x07]
; VCHECK-NEXT:    seta %al ## encoding: [0x0f,0x97,0xc0]
; VCHECK-NEXT:    retl ## encoding: [0xc3]
  %res = call i32 @llvm.x86.sse42.pcmpistria128(<16 x i8> %a0, <16 x i8> %a1, i8 7) ; <i32> [#uses=1]
  ret i32 %res
}
declare i32 @llvm.x86.sse42.pcmpistria128(<16 x i8>, <16 x i8>, i8) nounwind readnone


define i32 @test_x86_sse42_pcmpistric128(<16 x i8> %a0, <16 x i8> %a1) {
; SSE42-LABEL: test_x86_sse42_pcmpistric128:
; SSE42:       ## BB#0:
; SSE42-NEXT:    pcmpistri $7, %xmm1, %xmm0 ## encoding: [0x66,0x0f,0x3a,0x63,0xc1,0x07]
; SSE42-NEXT:    sbbl %eax, %eax ## encoding: [0x19,0xc0]
; SSE42-NEXT:    andl $1, %eax ## encoding: [0x83,0xe0,0x01]
; SSE42-NEXT:    retl ## encoding: [0xc3]
;
; VCHECK-LABEL: test_x86_sse42_pcmpistric128:
; VCHECK:       ## BB#0:
; VCHECK-NEXT:    vpcmpistri $7, %xmm1, %xmm0 ## encoding: [0xc4,0xe3,0x79,0x63,0xc1,0x07]
; VCHECK-NEXT:    sbbl %eax, %eax ## encoding: [0x19,0xc0]
; VCHECK-NEXT:    andl $1, %eax ## encoding: [0x83,0xe0,0x01]
; VCHECK-NEXT:    retl ## encoding: [0xc3]
  %res = call i32 @llvm.x86.sse42.pcmpistric128(<16 x i8> %a0, <16 x i8> %a1, i8 7) ; <i32> [#uses=1]
  ret i32 %res
}
declare i32 @llvm.x86.sse42.pcmpistric128(<16 x i8>, <16 x i8>, i8) nounwind readnone


define i32 @test_x86_sse42_pcmpistrio128(<16 x i8> %a0, <16 x i8> %a1) {
; SSE42-LABEL: test_x86_sse42_pcmpistrio128:
; SSE42:       ## BB#0:
; SSE42-NEXT:    xorl %eax, %eax ## encoding: [0x31,0xc0]
; SSE42-NEXT:    pcmpistri $7, %xmm1, %xmm0 ## encoding: [0x66,0x0f,0x3a,0x63,0xc1,0x07]
; SSE42-NEXT:    seto %al ## encoding: [0x0f,0x90,0xc0]
; SSE42-NEXT:    retl ## encoding: [0xc3]
;
; VCHECK-LABEL: test_x86_sse42_pcmpistrio128:
; VCHECK:       ## BB#0:
; VCHECK-NEXT:    xorl %eax, %eax ## encoding: [0x31,0xc0]
; VCHECK-NEXT:    vpcmpistri $7, %xmm1, %xmm0 ## encoding: [0xc4,0xe3,0x79,0x63,0xc1,0x07]
; VCHECK-NEXT:    seto %al ## encoding: [0x0f,0x90,0xc0]
; VCHECK-NEXT:    retl ## encoding: [0xc3]
  %res = call i32 @llvm.x86.sse42.pcmpistrio128(<16 x i8> %a0, <16 x i8> %a1, i8 7) ; <i32> [#uses=1]
  ret i32 %res
}
declare i32 @llvm.x86.sse42.pcmpistrio128(<16 x i8>, <16 x i8>, i8) nounwind readnone


define i32 @test_x86_sse42_pcmpistris128(<16 x i8> %a0, <16 x i8> %a1) {
; SSE42-LABEL: test_x86_sse42_pcmpistris128:
; SSE42:       ## BB#0:
; SSE42-NEXT:    xorl %eax, %eax ## encoding: [0x31,0xc0]
; SSE42-NEXT:    pcmpistri $7, %xmm1, %xmm0 ## encoding: [0x66,0x0f,0x3a,0x63,0xc1,0x07]
; SSE42-NEXT:    sets %al ## encoding: [0x0f,0x98,0xc0]
; SSE42-NEXT:    retl ## encoding: [0xc3]
;
; VCHECK-LABEL: test_x86_sse42_pcmpistris128:
; VCHECK:       ## BB#0:
; VCHECK-NEXT:    xorl %eax, %eax ## encoding: [0x31,0xc0]
; VCHECK-NEXT:    vpcmpistri $7, %xmm1, %xmm0 ## encoding: [0xc4,0xe3,0x79,0x63,0xc1,0x07]
; VCHECK-NEXT:    sets %al ## encoding: [0x0f,0x98,0xc0]
; VCHECK-NEXT:    retl ## encoding: [0xc3]
  %res = call i32 @llvm.x86.sse42.pcmpistris128(<16 x i8> %a0, <16 x i8> %a1, i8 7) ; <i32> [#uses=1]
  ret i32 %res
}
declare i32 @llvm.x86.sse42.pcmpistris128(<16 x i8>, <16 x i8>, i8) nounwind readnone


define i32 @test_x86_sse42_pcmpistriz128(<16 x i8> %a0, <16 x i8> %a1) {
; SSE42-LABEL: test_x86_sse42_pcmpistriz128:
; SSE42:       ## BB#0:
; SSE42-NEXT:    xorl %eax, %eax ## encoding: [0x31,0xc0]
; SSE42-NEXT:    pcmpistri $7, %xmm1, %xmm0 ## encoding: [0x66,0x0f,0x3a,0x63,0xc1,0x07]
; SSE42-NEXT:    sete %al ## encoding: [0x0f,0x94,0xc0]
; SSE42-NEXT:    retl ## encoding: [0xc3]
;
; VCHECK-LABEL: test_x86_sse42_pcmpistriz128:
; VCHECK:       ## BB#0:
; VCHECK-NEXT:    xorl %eax, %eax ## encoding: [0x31,0xc0]
; VCHECK-NEXT:    vpcmpistri $7, %xmm1, %xmm0 ## encoding: [0xc4,0xe3,0x79,0x63,0xc1,0x07]
; VCHECK-NEXT:    sete %al ## encoding: [0x0f,0x94,0xc0]
; VCHECK-NEXT:    retl ## encoding: [0xc3]
  %res = call i32 @llvm.x86.sse42.pcmpistriz128(<16 x i8> %a0, <16 x i8> %a1, i8 7) ; <i32> [#uses=1]
  ret i32 %res
}
declare i32 @llvm.x86.sse42.pcmpistriz128(<16 x i8>, <16 x i8>, i8) nounwind readnone


define <16 x i8> @test_x86_sse42_pcmpistrm128(<16 x i8> %a0, <16 x i8> %a1) {
; SSE42-LABEL: test_x86_sse42_pcmpistrm128:
; SSE42:       ## BB#0:
; SSE42-NEXT:    pcmpistrm $7, %xmm1, %xmm0 ## encoding: [0x66,0x0f,0x3a,0x62,0xc1,0x07]
; SSE42-NEXT:    retl ## encoding: [0xc3]
;
; VCHECK-LABEL: test_x86_sse42_pcmpistrm128:
; VCHECK:       ## BB#0:
; VCHECK-NEXT:    vpcmpistrm $7, %xmm1, %xmm0 ## encoding: [0xc4,0xe3,0x79,0x62,0xc1,0x07]
; VCHECK-NEXT:    retl ## encoding: [0xc3]
  %res = call <16 x i8> @llvm.x86.sse42.pcmpistrm128(<16 x i8> %a0, <16 x i8> %a1, i8 7) ; <<16 x i8>> [#uses=1]
  ret <16 x i8> %res
}
declare <16 x i8> @llvm.x86.sse42.pcmpistrm128(<16 x i8>, <16 x i8>, i8) nounwind readnone


define <16 x i8> @test_x86_sse42_pcmpistrm128_load(<16 x i8> %a0, <16 x i8>* %a1) {
; SSE42-LABEL: test_x86_sse42_pcmpistrm128_load:
; SSE42:       ## BB#0:
; SSE42-NEXT:    movl {{[0-9]+}}(%esp), %eax ## encoding: [0x8b,0x44,0x24,0x04]
; SSE42-NEXT:    pcmpistrm $7, (%eax), %xmm0 ## encoding: [0x66,0x0f,0x3a,0x62,0x00,0x07]
; SSE42-NEXT:    retl ## encoding: [0xc3]
;
; VCHECK-LABEL: test_x86_sse42_pcmpistrm128_load:
; VCHECK:       ## BB#0:
; VCHECK-NEXT:    movl {{[0-9]+}}(%esp), %eax ## encoding: [0x8b,0x44,0x24,0x04]
; VCHECK-NEXT:    vpcmpistrm $7, (%eax), %xmm0 ## encoding: [0xc4,0xe3,0x79,0x62,0x00,0x07]
; VCHECK-NEXT:    retl ## encoding: [0xc3]
  %1 = load <16 x i8>, <16 x i8>* %a1
  %res = call <16 x i8> @llvm.x86.sse42.pcmpistrm128(<16 x i8> %a0, <16 x i8> %1, i8 7) ; <<16 x i8>> [#uses=1]
  ret <16 x i8> %res
}

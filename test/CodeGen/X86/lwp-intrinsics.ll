; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc < %s -mtriple=i686-unknown -mattr=+lwp | FileCheck %s --check-prefix=X86
; RUN: llc < %s -mtriple=i686-unknown -mcpu=bdver1 | FileCheck %s --check-prefix=X86
; RUN: llc < %s -mtriple=i686-unknown -mcpu=bdver2 | FileCheck %s --check-prefix=X86
; RUN: llc < %s -mtriple=i686-unknown -mcpu=bdver3 | FileCheck %s --check-prefix=X86
; RUN: llc < %s -mtriple=i686-unknown -mcpu=bdver4 | FileCheck %s --check-prefix=X86
; RUN: llc < %s -mtriple=x86_64-unknown -mattr=+lwp | FileCheck %s --check-prefix=X64
; RUN: llc < %s -mtriple=x86_64-unknown -mcpu=bdver1 | FileCheck %s --check-prefix=X64
; RUN: llc < %s -mtriple=x86_64-unknown -mcpu=bdver2 | FileCheck %s --check-prefix=X64
; RUN: llc < %s -mtriple=x86_64-unknown -mcpu=bdver3 | FileCheck %s --check-prefix=X64
; RUN: llc < %s -mtriple=x86_64-unknown -mcpu=bdver4 | FileCheck %s --check-prefix=X64

define void @test_llwpcb(i8 *%a0) nounwind {
; X86-LABEL: test_llwpcb:
; X86:       # BB#0:
; X86-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-NEXT:    llwpcb %eax
; X86-NEXT:    retl
;
; X64-LABEL: test_llwpcb:
; X64:       # BB#0:
; X64-NEXT:    llwpcb %rdi
; X64-NEXT:    retq
  tail call void @llvm.x86.llwpcb(i8 *%a0)
  ret void
}

define i8* @test_slwpcb(i8 *%a0) nounwind {
; X86-LABEL: test_slwpcb:
; X86:       # BB#0:
; X86-NEXT:    slwpcb %eax
; X86-NEXT:    retl
;
; X64-LABEL: test_slwpcb:
; X64:       # BB#0:
; X64-NEXT:    slwpcb %rax
; X64-NEXT:    retq
  %1 = tail call i8* @llvm.x86.slwpcb()
  ret i8 *%1
}

define i8 @test_lwpins32_rri(i32 %a0, i32 %a1) nounwind {
; X86-LABEL: test_lwpins32_rri:
; X86:       # BB#0:
; X86-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-NEXT:    movl {{[0-9]+}}(%esp), %ecx
; X86-NEXT:    addl %ecx, %ecx
; X86-NEXT:    lwpins $-1985229329, %ecx, %eax # imm = 0x89ABCDEF
; X86-NEXT:    setb %al
; X86-NEXT:    retl
;
; X64-LABEL: test_lwpins32_rri:
; X64:       # BB#0:
; X64-NEXT:    addl %esi, %esi
; X64-NEXT:    lwpins $-1985229329, %esi, %edi # imm = 0x89ABCDEF
; X64-NEXT:    setb %al
; X64-NEXT:    retq
  %1 = add i32 %a1, %a1
  %2 = tail call i8 @llvm.x86.lwpins32(i32 %a0, i32 %1, i32 2309737967)
  ret i8 %2
}

define i8 @test_lwpins32_rmi(i32 %a0, i32 *%p1) nounwind {
; X86-LABEL: test_lwpins32_rmi:
; X86:       # BB#0:
; X86-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-NEXT:    movl {{[0-9]+}}(%esp), %ecx
; X86-NEXT:    lwpins $1985229328, (%eax), %ecx # imm = 0x76543210
; X86-NEXT:    setb %al
; X86-NEXT:    retl
;
; X64-LABEL: test_lwpins32_rmi:
; X64:       # BB#0:
; X64-NEXT:    lwpins $1985229328, (%rsi), %edi # imm = 0x76543210
; X64-NEXT:    setb %al
; X64-NEXT:    retq
  %a1 = load i32, i32 *%p1
  %1 = tail call i8 @llvm.x86.lwpins32(i32 %a0, i32 %a1, i32 1985229328)
  ret i8 %1
}

define void @test_lwpval32_rri(i32 %a0, i32 %a1) nounwind {
; X86-LABEL: test_lwpval32_rri:
; X86:       # BB#0:
; X86-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-NEXT:    movl {{[0-9]+}}(%esp), %ecx
; X86-NEXT:    addl %ecx, %ecx
; X86-NEXT:    lwpval $-19088744, %ecx, %eax # imm = 0xFEDCBA98
; X86-NEXT:    retl
;
; X64-LABEL: test_lwpval32_rri:
; X64:       # BB#0:
; X64-NEXT:    addl %esi, %esi
; X64-NEXT:    lwpval $-19088744, %esi, %edi # imm = 0xFEDCBA98
; X64-NEXT:    retq
  %1 = add i32 %a1, %a1
  tail call void @llvm.x86.lwpval32(i32 %a0, i32 %1, i32 4275878552)
  ret void
}

define void @test_lwpval32_rmi(i32 %a0, i32 *%p1) nounwind {
; X86-LABEL: test_lwpval32_rmi:
; X86:       # BB#0:
; X86-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-NEXT:    movl {{[0-9]+}}(%esp), %ecx
; X86-NEXT:    lwpval $305419896, (%eax), %ecx # imm = 0x12345678
; X86-NEXT:    retl
;
; X64-LABEL: test_lwpval32_rmi:
; X64:       # BB#0:
; X64-NEXT:    lwpval $305419896, (%rsi), %edi # imm = 0x12345678
; X64-NEXT:    retq
  %a1 = load i32, i32 *%p1
  tail call void @llvm.x86.lwpval32(i32 %a0, i32 %a1, i32 305419896)
  ret void
}

declare void @llvm.x86.llwpcb(i8*) nounwind
declare i8* @llvm.x86.slwpcb() nounwind
declare i8 @llvm.x86.lwpins32(i32, i32, i32) nounwind
declare void @llvm.x86.lwpval32(i32, i32, i32) nounwind

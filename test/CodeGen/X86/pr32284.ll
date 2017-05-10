; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc < %s -mtriple=i686-unknown -mcpu=skx | FileCheck %s --check-prefix=X86
; RUN: llc < %s -mtriple=i686-unknown -mcpu=skx -O0 | FileCheck %s --check-prefix=X86-O0
; RUN: llc < %s -mtriple=x86_64-unknown -mcpu=skx | FileCheck %s --check-prefix=X64
; RUN: llc < %s -mtriple=x86_64-unknown -mcpu=skx -O0 | FileCheck %s --check-prefix=X64-O0

@c = external constant i8, align 1

define void @foo() {
; X86-LABEL: foo:
; X86:       # BB#0: # %entry
; X86-NEXT:    subl $8, %esp
; X86-NEXT:  .Lcfi0:
; X86-NEXT:    .cfi_def_cfa_offset 12
; X86-NEXT:    movzbl c, %eax
; X86-NEXT:    xorl %ecx, %ecx
; X86-NEXT:    testl %eax, %eax
; X86-NEXT:    setne %cl
; X86-NEXT:    testb %al, %al
; X86-NEXT:    setne {{[0-9]+}}(%esp)
; X86-NEXT:    xorl %edx, %edx
; X86-NEXT:    cmpl %eax, %ecx
; X86-NEXT:    setle %dl
; X86-NEXT:    movl %edx, {{[0-9]+}}(%esp)
; X86-NEXT:    addl $8, %esp
; X86-NEXT:    retl
;
; X86-O0-LABEL: foo:
; X86-O0:       # BB#0: # %entry
; X86-O0-NEXT:    subl $12, %esp
; X86-O0-NEXT:  .Lcfi0:
; X86-O0-NEXT:    .cfi_def_cfa_offset 16
; X86-O0-NEXT:    movb c, %al
; X86-O0-NEXT:    testb %al, %al
; X86-O0-NEXT:    setne {{[0-9]+}}(%esp)
; X86-O0-NEXT:    movzbl c, %ecx
; X86-O0-NEXT:    testl %ecx, %ecx
; X86-O0-NEXT:    setne %al
; X86-O0-NEXT:    movzbl %al, %edx
; X86-O0-NEXT:    subl %ecx, %edx
; X86-O0-NEXT:    setle %al
; X86-O0-NEXT:    # implicit-def: %ECX
; X86-O0-NEXT:    movb %al, %cl
; X86-O0-NEXT:    andl $1, %ecx
; X86-O0-NEXT:    kmovd %ecx, %k0
; X86-O0-NEXT:    kmovd %k0, %ecx
; X86-O0-NEXT:    movb %cl, %al
; X86-O0-NEXT:    andb $1, %al
; X86-O0-NEXT:    movzbl %al, %ecx
; X86-O0-NEXT:    movl %ecx, {{[0-9]+}}(%esp)
; X86-O0-NEXT:    movl %edx, (%esp) # 4-byte Spill
; X86-O0-NEXT:    addl $12, %esp
; X86-O0-NEXT:    retl
;
; X64-LABEL: foo:
; X64:       # BB#0: # %entry
; X64-NEXT:    movzbl {{.*}}(%rip), %eax
; X64-NEXT:    testb %al, %al
; X64-NEXT:    setne -{{[0-9]+}}(%rsp)
; X64-NEXT:    xorl %ecx, %ecx
; X64-NEXT:    testl %eax, %eax
; X64-NEXT:    setne %cl
; X64-NEXT:    xorl %edx, %edx
; X64-NEXT:    cmpl %eax, %ecx
; X64-NEXT:    setle %dl
; X64-NEXT:    movl %edx, -{{[0-9]+}}(%rsp)
; X64-NEXT:    retq
;
; X64-O0-LABEL: foo:
; X64-O0:       # BB#0: # %entry
; X64-O0-NEXT:    movb {{.*}}(%rip), %al
; X64-O0-NEXT:    testb %al, %al
; X64-O0-NEXT:    setne -{{[0-9]+}}(%rsp)
; X64-O0-NEXT:    movzbl {{.*}}(%rip), %ecx
; X64-O0-NEXT:    testl %ecx, %ecx
; X64-O0-NEXT:    setne %al
; X64-O0-NEXT:    movzbl %al, %edx
; X64-O0-NEXT:    subl %ecx, %edx
; X64-O0-NEXT:    setle %al
; X64-O0-NEXT:    # implicit-def: %ECX
; X64-O0-NEXT:    movb %al, %cl
; X64-O0-NEXT:    andl $1, %ecx
; X64-O0-NEXT:    kmovd %ecx, %k0
; X64-O0-NEXT:    kmovd %k0, %ecx
; X64-O0-NEXT:    movb %cl, %al
; X64-O0-NEXT:    andb $1, %al
; X64-O0-NEXT:    movzbl %al, %ecx
; X64-O0-NEXT:    movl %ecx, -{{[0-9]+}}(%rsp)
; X64-O0-NEXT:    movl %edx, -{{[0-9]+}}(%rsp) # 4-byte Spill
; X64-O0-NEXT:    retq
entry:
  %a = alloca i8, align 1
  %b = alloca i32, align 4
  %0 = load i8, i8* @c, align 1
  %conv = zext i8 %0 to i32
  %sub = sub nsw i32 0, %conv
  %conv1 = sext i32 %sub to i64
  %sub2 = sub nsw i64 0, %conv1
  %conv3 = trunc i64 %sub2 to i8
  %tobool = icmp ne i8 %conv3, 0
  %frombool = zext i1 %tobool to i8
  store i8 %frombool, i8* %a, align 1
  %1 = load i8, i8* @c, align 1
  %tobool4 = icmp ne i8 %1, 0
  %lnot = xor i1 %tobool4, true
  %lnot5 = xor i1 %lnot, true
  %conv6 = zext i1 %lnot5 to i32
  %2 = load i8, i8* @c, align 1
  %conv7 = zext i8 %2 to i32
  %cmp = icmp sle i32 %conv6, %conv7
  %conv8 = zext i1 %cmp to i32
  store i32 %conv8, i32* %b, align 4
  ret void
}

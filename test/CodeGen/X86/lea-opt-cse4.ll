; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc < %s -mtriple=x86_64-unknown | FileCheck %s -check-prefix=X64
; RUN: llc < %s -mtriple=i686-unknown   | FileCheck %s -check-prefix=X86

%struct.SA = type { i32 , i32 , i32 , i32 , i32};

define void @foo(%struct.SA* nocapture %ctx, i32 %n) local_unnamed_addr #0 {
; X64-LABEL: foo:
; X64:       # BB#0: # %entry
; X64-NEXT:    movl 16(%rdi), %eax
; X64-NEXT:    movl (%rdi), %ecx
; X64-NEXT:    addl %eax, %ecx
; X64-NEXT:    addl %eax, %ecx
; X64-NEXT:    addl %eax, %ecx
; X64-NEXT:    leal (%rcx,%rax), %edx
; X64-NEXT:    leal 1(%rax,%rcx), %ecx
; X64-NEXT:    movl %ecx, 12(%rdi)
; X64-NEXT:    leal 1(%rax,%rdx), %eax
; X64-NEXT:    movl %eax, 16(%rdi)
; X64-NEXT:    retq
;
; X86-LABEL: foo:
; X86:       # BB#0: # %entry
; X86-NEXT:    pushl %esi
; X86-NEXT:    .cfi_def_cfa_offset 8
; X86-NEXT:    .cfi_offset %esi, -8
; X86-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-NEXT:    movl 16(%eax), %ecx
; X86-NEXT:    movl (%eax), %edx
; X86-NEXT:    addl %ecx, %edx
; X86-NEXT:    addl %ecx, %edx
; X86-NEXT:    addl %ecx, %edx
; X86-NEXT:    leal 1(%ecx,%edx), %esi
; X86-NEXT:    addl %ecx, %edx
; X86-NEXT:    movl %esi, 12(%eax)
; X86-NEXT:    leal 1(%ecx,%edx), %ecx
; X86-NEXT:    movl %ecx, 16(%eax)
; X86-NEXT:    popl %esi
; X86-NEXT:   .cfi_def_cfa_offset 4
; X86-NEXT:    retl
 entry:
   %h0 = getelementptr inbounds %struct.SA, %struct.SA* %ctx, i64 0, i32 0
   %0 = load i32, i32* %h0, align 8
   %h3 = getelementptr inbounds %struct.SA, %struct.SA* %ctx, i64 0, i32 3
   %h4 = getelementptr inbounds %struct.SA, %struct.SA* %ctx, i64 0, i32 4
   %1 = load i32, i32* %h4, align 8
   %add  = add i32 %0  , 1
   %add1 = add i32 %add, %1
   %add2 = add i32 %add1, %1
   %add3 = add i32 %add2, %1
   %add4 = add i32 %add3, %1
   store i32 %add4, i32* %h3, align 4
   %add29 = add i32 %add4, %1
   store i32 %add29, i32* %h4, align 8
   ret void
}



define void @foo_loop(%struct.SA* nocapture %ctx, i32 %n) local_unnamed_addr #0 {
; X64-LABEL: foo_loop:
; X64:       # BB#0: # %entry
; X64-NEXT:    .p2align 4, 0x90
; X64-NEXT:  .LBB1_1: # %loop
; X64-NEXT:    # =>This Inner Loop Header: Depth=1
; X64-NEXT:    movl (%rdi), %ecx
; X64-NEXT:    movl 16(%rdi), %eax
; X64-NEXT:    leal 1(%rcx,%rax), %edx
; X64-NEXT:    movl %edx, 12(%rdi)
; X64-NEXT:    decl %esi
; X64-NEXT:    jne .LBB1_1
; X64-NEXT:  # BB#2: # %exit
; X64-NEXT:    addl %eax, %ecx
; X64-NEXT:    leal 1(%rax,%rcx), %ecx
; X64-NEXT:    addl %eax, %ecx
; X64-NEXT:    addl %eax, %ecx
; X64-NEXT:    addl %eax, %ecx
; X64-NEXT:    addl %eax, %ecx
; X64-NEXT:    addl %eax, %ecx
; X64-NEXT:    addl %eax, %ecx
; X64-NEXT:    movl %ecx, 16(%rdi)
; X64-NEXT:    retq
;
; X86-LABEL: foo_loop:
; X86:       # BB#0: # %entry
; X86-NEXT:    pushl %edi
; X86-NEXT:    .cfi_def_cfa_offset 8
; X86-NEXT:    pushl %esi
; X86-NEXT:    .cfi_def_cfa_offset 12
; X86-NEXT:    .cfi_offset %esi, -12
; X86-NEXT:    .cfi_offset %edi, -8
; X86-NEXT:    movl {{[0-9]+}}(%esp), %edx
; X86-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-NEXT:    .p2align 4, 0x90
; X86-NEXT:  .LBB1_1: # %loop
; X86-NEXT:    # =>This Inner Loop Header: Depth=1
; X86-NEXT:    movl (%eax), %esi
; X86-NEXT:    movl 16(%eax), %ecx
; X86-NEXT:    leal 1(%esi,%ecx), %edi
; X86-NEXT:    movl %edi, 12(%eax)
; X86-NEXT:    decl %edx
; X86-NEXT:    jne .LBB1_1
; X86-NEXT:  # BB#2: # %exit
; X86-NEXT:    addl %ecx, %esi
; X86-NEXT:    leal 1(%ecx,%esi), %edx
; X86-NEXT:    addl %ecx, %edx
; X86-NEXT:    addl %ecx, %edx
; X86-NEXT:    addl %ecx, %edx
; X86-NEXT:    addl %ecx, %edx
; X86-NEXT:    addl %ecx, %edx
; X86-NEXT:    addl %ecx, %edx
; X86-NEXT:    movl %edx, 16(%eax)
; X86-NEXT:    popl %esi
; X86-NEXT:   .cfi_def_cfa_offset 8
; X86-NEXT:    popl %edi
; X86-NEXT:   .cfi_def_cfa_offset 4
; X86-NEXT:    retl
 entry:
   br label %loop

 loop:
   %iter = phi i32 [%n ,%entry ] ,[ %iter.ctr ,%loop]
   %h0 = getelementptr inbounds %struct.SA, %struct.SA* %ctx, i64 0, i32 0
   %0 = load i32, i32* %h0, align 8
   %h3 = getelementptr inbounds %struct.SA, %struct.SA* %ctx, i64 0, i32 3
   %h4 = getelementptr inbounds %struct.SA, %struct.SA* %ctx, i64 0, i32 4
   %1 = load i32, i32* %h4, align 8
   %add = add i32 %0, 1
   %add4 = add i32 %add, %1
   store i32 %add4, i32* %h3, align 4
   %add291 = add i32 %add4, %1
   %add292 = add i32 %add291, %1
   %add293 = add i32 %add292, %1
   %add294 = add i32 %add293, %1
   %add295 = add i32 %add294, %1
   %add296 = add i32 %add295, %1
   %add29 = add i32 %add296, %1
   %iter.ctr = sub i32 %iter , 1
   %res = icmp ne i32 %iter.ctr , 0
   br i1 %res , label %loop , label %exit

 exit:
   store i32 %add29, i32* %h4, align 8
   ret void
}

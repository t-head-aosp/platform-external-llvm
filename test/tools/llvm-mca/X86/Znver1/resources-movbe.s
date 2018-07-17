# NOTE: Assertions have been autogenerated by utils/update_mca_test_checks.py
# RUN: llvm-mca -mtriple=x86_64-unknown-unknown -mcpu=znver1 -instruction-tables < %s | FileCheck %s

movbe  %cx, (%rax)
movbe  (%rax), %cx

movbe  %ecx, (%rax)
movbe  (%rax), %ecx

movbe  %rcx, (%rax)
movbe  (%rax), %rcx

# CHECK:      Instruction Info:
# CHECK-NEXT: [1]: #uOps
# CHECK-NEXT: [2]: Latency
# CHECK-NEXT: [3]: RThroughput
# CHECK-NEXT: [4]: MayLoad
# CHECK-NEXT: [5]: MayStore
# CHECK-NEXT: [6]: HasSideEffects (U)

# CHECK:      [1]    [2]    [3]    [4]    [5]    [6]    Instructions:
# CHECK-NEXT:  1      5     0.50           *            movbew	%cx, (%rax)
# CHECK-NEXT:  1      5     0.50    *                   movbew	(%rax), %cx
# CHECK-NEXT:  1      5     0.50           *            movbel	%ecx, (%rax)
# CHECK-NEXT:  1      5     0.50    *                   movbel	(%rax), %ecx
# CHECK-NEXT:  1      5     0.50           *            movbeq	%rcx, (%rax)
# CHECK-NEXT:  1      5     0.50    *                   movbeq	(%rax), %rcx

# CHECK:      Resources:
# CHECK-NEXT: [0]   - ZnAGU0
# CHECK-NEXT: [1]   - ZnAGU1
# CHECK-NEXT: [2]   - ZnALU0
# CHECK-NEXT: [3]   - ZnALU1
# CHECK-NEXT: [4]   - ZnALU2
# CHECK-NEXT: [5]   - ZnALU3
# CHECK-NEXT: [6]   - ZnDivider
# CHECK-NEXT: [7]   - ZnFPU0
# CHECK-NEXT: [8]   - ZnFPU1
# CHECK-NEXT: [9]   - ZnFPU2
# CHECK-NEXT: [10]  - ZnFPU3
# CHECK-NEXT: [11]  - ZnMultiplier

# CHECK:      Resource pressure per iteration:
# CHECK-NEXT: [0]    [1]    [2]    [3]    [4]    [5]    [6]    [7]    [8]    [9]    [10]   [11]
# CHECK-NEXT: 3.00   3.00   1.50   1.50   1.50   1.50    -      -      -      -      -      -

# CHECK:      Resource pressure by instruction:
# CHECK-NEXT: [0]    [1]    [2]    [3]    [4]    [5]    [6]    [7]    [8]    [9]    [10]   [11]   Instructions:
# CHECK-NEXT: 0.50   0.50   0.25   0.25   0.25   0.25    -      -      -      -      -      -     movbew	%cx, (%rax)
# CHECK-NEXT: 0.50   0.50   0.25   0.25   0.25   0.25    -      -      -      -      -      -     movbew	(%rax), %cx
# CHECK-NEXT: 0.50   0.50   0.25   0.25   0.25   0.25    -      -      -      -      -      -     movbel	%ecx, (%rax)
# CHECK-NEXT: 0.50   0.50   0.25   0.25   0.25   0.25    -      -      -      -      -      -     movbel	(%rax), %ecx
# CHECK-NEXT: 0.50   0.50   0.25   0.25   0.25   0.25    -      -      -      -      -      -     movbeq	%rcx, (%rax)
# CHECK-NEXT: 0.50   0.50   0.25   0.25   0.25   0.25    -      -      -      -      -      -     movbeq	(%rax), %rcx

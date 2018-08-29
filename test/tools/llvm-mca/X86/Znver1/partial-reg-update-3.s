# NOTE: Assertions have been autogenerated by utils/update_mca_test_checks.py
# RUN: llvm-mca -mtriple=x86_64-unknown-unknown -mcpu=znver1 -iterations=1500 -timeline -timeline-max-iterations=6 < %s | FileCheck %s

# The ILP is limited by the false dependency on %dx. So, the mov cannot execute
# in parallel with the add.

add %cx, %dx
mov %ax, %dx
xor %bx, %dx

# CHECK:      Iterations:        1500
# CHECK-NEXT: Instructions:      4500
# CHECK-NEXT: Total Cycles:      4503
# CHECK-NEXT: Total uOps:        4500

# CHECK:      Dispatch Width:    4
# CHECK-NEXT: uOps Per Cycle:    1.00
# CHECK-NEXT: IPC:               1.00
# CHECK-NEXT: Block RThroughput: 0.8

# CHECK:      Instruction Info:
# CHECK-NEXT: [1]: #uOps
# CHECK-NEXT: [2]: Latency
# CHECK-NEXT: [3]: RThroughput
# CHECK-NEXT: [4]: MayLoad
# CHECK-NEXT: [5]: MayStore
# CHECK-NEXT: [6]: HasSideEffects (U)

# CHECK:      [1]    [2]    [3]    [4]    [5]    [6]    Instructions:
# CHECK-NEXT:  1      1     0.25                        addw	%cx, %dx
# CHECK-NEXT:  1      1     0.25                        movw	%ax, %dx
# CHECK-NEXT:  1      1     0.25                        xorw	%bx, %dx

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
# CHECK-NEXT:  -      -     0.75   0.75   0.75   0.75    -      -      -      -      -      -

# CHECK:      Resource pressure by instruction:
# CHECK-NEXT: [0]    [1]    [2]    [3]    [4]    [5]    [6]    [7]    [8]    [9]    [10]   [11]   Instructions:
# CHECK-NEXT:  -      -     0.25   0.25   0.25   0.25    -      -      -      -      -      -     addw	%cx, %dx
# CHECK-NEXT:  -      -     0.25   0.25   0.25   0.25    -      -      -      -      -      -     movw	%ax, %dx
# CHECK-NEXT:  -      -     0.25   0.25   0.25   0.25    -      -      -      -      -      -     xorw	%bx, %dx

# CHECK:      Timeline view:
# CHECK-NEXT:                     0123456789
# CHECK-NEXT: Index     0123456789          0

# CHECK:      [0,0]     DeER .    .    .    .   addw	%cx, %dx
# CHECK-NEXT: [0,1]     D=eER.    .    .    .   movw	%ax, %dx
# CHECK-NEXT: [0,2]     D==eER    .    .    .   xorw	%bx, %dx
# CHECK-NEXT: [1,0]     D===eER   .    .    .   addw	%cx, %dx
# CHECK-NEXT: [1,1]     .D===eER  .    .    .   movw	%ax, %dx
# CHECK-NEXT: [1,2]     .D====eER .    .    .   xorw	%bx, %dx
# CHECK-NEXT: [2,0]     .D=====eER.    .    .   addw	%cx, %dx
# CHECK-NEXT: [2,1]     .D======eER    .    .   movw	%ax, %dx
# CHECK-NEXT: [2,2]     . D======eER   .    .   xorw	%bx, %dx
# CHECK-NEXT: [3,0]     . D=======eER  .    .   addw	%cx, %dx
# CHECK-NEXT: [3,1]     . D========eER .    .   movw	%ax, %dx
# CHECK-NEXT: [3,2]     . D=========eER.    .   xorw	%bx, %dx
# CHECK-NEXT: [4,0]     .  D=========eER    .   addw	%cx, %dx
# CHECK-NEXT: [4,1]     .  D==========eER   .   movw	%ax, %dx
# CHECK-NEXT: [4,2]     .  D===========eER  .   xorw	%bx, %dx
# CHECK-NEXT: [5,0]     .  D============eER .   addw	%cx, %dx
# CHECK-NEXT: [5,1]     .   D============eER.   movw	%ax, %dx
# CHECK-NEXT: [5,2]     .   D=============eER   xorw	%bx, %dx

# CHECK:      Average Wait times (based on the timeline view):
# CHECK-NEXT: [0]: Executions
# CHECK-NEXT: [1]: Average time spent waiting in a scheduler's queue
# CHECK-NEXT: [2]: Average time spent waiting in a scheduler's queue while ready
# CHECK-NEXT: [3]: Average time elapsed from WB until retire stage

# CHECK:            [0]    [1]    [2]    [3]
# CHECK-NEXT: 0.     6     7.0    0.2    0.0       addw	%cx, %dx
# CHECK-NEXT: 1.     6     7.7    0.0    0.0       movw	%ax, %dx
# CHECK-NEXT: 2.     6     8.5    0.0    0.0       xorw	%bx, %dx

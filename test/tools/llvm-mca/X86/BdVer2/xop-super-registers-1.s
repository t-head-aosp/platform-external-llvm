# NOTE: Assertions have been autogenerated by utils/update_mca_test_checks.py
# RUN: llvm-mca -mtriple=x86_64-unknown-unknown -mcpu=bdver2 -timeline -timeline-max-iterations=2 < %s | FileCheck %s

  vmulps  %ymm0, %ymm1, %ymm2
  vfrczpd %xmm1, %xmm2
  vmulps  %ymm2, %ymm3, %ymm4
  vaddps  %ymm4, %ymm5, %ymm6
  vmulps  %ymm6, %ymm3, %ymm4
  vaddps  %ymm4, %ymm5, %ymm0

# CHECK:      Iterations:        100
# CHECK-NEXT: Instructions:      600
# CHECK-NEXT: Total Cycles:      717
# CHECK-NEXT: Total uOps:        1200

# CHECK:      Dispatch Width:    4
# CHECK-NEXT: uOps Per Cycle:    1.67
# CHECK-NEXT: IPC:               0.84
# CHECK-NEXT: Block RThroughput: 7.0

# CHECK:      Instruction Info:
# CHECK-NEXT: [1]: #uOps
# CHECK-NEXT: [2]: Latency
# CHECK-NEXT: [3]: RThroughput
# CHECK-NEXT: [4]: MayLoad
# CHECK-NEXT: [5]: MayStore
# CHECK-NEXT: [6]: HasSideEffects (U)

# CHECK:      [1]    [2]    [3]    [4]    [5]    [6]    Instructions:
# CHECK-NEXT:  2      5     2.00                        vmulps	%ymm0, %ymm1, %ymm2
# CHECK-NEXT:  2      10    1.00                        vfrczpd	%xmm1, %xmm2
# CHECK-NEXT:  2      5     2.00                        vmulps	%ymm2, %ymm3, %ymm4
# CHECK-NEXT:  2      5     2.00                        vaddps	%ymm4, %ymm5, %ymm6
# CHECK-NEXT:  2      5     2.00                        vmulps	%ymm6, %ymm3, %ymm4
# CHECK-NEXT:  2      5     2.00                        vaddps	%ymm4, %ymm5, %ymm0

# CHECK:      Resources:
# CHECK-NEXT: [0.0] - PdAGLU01
# CHECK-NEXT: [0.1] - PdAGLU01
# CHECK-NEXT: [1]   - PdBranch
# CHECK-NEXT: [2]   - PdCount
# CHECK-NEXT: [3]   - PdDiv
# CHECK-NEXT: [4]   - PdEX0
# CHECK-NEXT: [5]   - PdEX1
# CHECK-NEXT: [6]   - PdFPCVT
# CHECK-NEXT: [7.0] - PdFPFMA
# CHECK-NEXT: [7.1] - PdFPFMA
# CHECK-NEXT: [8.0] - PdFPMAL
# CHECK-NEXT: [8.1] - PdFPMAL
# CHECK-NEXT: [9]   - PdFPMMA
# CHECK-NEXT: [10]  - PdFPSTO
# CHECK-NEXT: [11]  - PdFPU0
# CHECK-NEXT: [12]  - PdFPU1
# CHECK-NEXT: [13]  - PdFPU2
# CHECK-NEXT: [14]  - PdFPU3
# CHECK-NEXT: [15]  - PdFPXBR
# CHECK-NEXT: [16]  - PdMul

# CHECK:      Resource pressure per iteration:
# CHECK-NEXT: [0.0]  [0.1]  [1]    [2]    [3]    [4]    [5]    [6]    [7.0]  [7.1]  [8.0]  [8.1]  [9]    [10]   [11]   [12]   [13]   [14]   [15]   [16]
# CHECK-NEXT:  -      -      -      -      -      -      -      -     0.04   4.96    -      -      -     1.00   4.00   7.00    -      -      -      -

# CHECK:      Resource pressure by instruction:
# CHECK-NEXT: [0.0]  [0.1]  [1]    [2]    [3]    [4]    [5]    [6]    [7.0]  [7.1]  [8.0]  [8.1]  [9]    [10]   [11]   [12]   [13]   [14]   [15]   [16]   Instructions:
# CHECK-NEXT:  -      -      -      -      -      -      -      -      -     1.00    -      -      -      -      -     2.00    -      -      -      -     vmulps	%ymm0, %ymm1, %ymm2
# CHECK-NEXT:  -      -      -      -      -      -      -      -      -      -      -      -      -     1.00    -     1.00    -      -      -      -     vfrczpd	%xmm1, %xmm2
# CHECK-NEXT:  -      -      -      -      -      -      -      -     0.01   0.99    -      -      -      -      -     2.00    -      -      -      -     vmulps	%ymm2, %ymm3, %ymm4
# CHECK-NEXT:  -      -      -      -      -      -      -      -     0.01   0.99    -      -      -      -     2.00    -      -      -      -      -     vaddps	%ymm4, %ymm5, %ymm6
# CHECK-NEXT:  -      -      -      -      -      -      -      -     0.02   0.98    -      -      -      -      -     2.00    -      -      -      -     vmulps	%ymm6, %ymm3, %ymm4
# CHECK-NEXT:  -      -      -      -      -      -      -      -      -     1.00    -      -      -      -     2.00    -      -      -      -      -     vaddps	%ymm4, %ymm5, %ymm0

# CHECK:      Timeline view:
# CHECK-NEXT:                     0123456789          0123456789
# CHECK-NEXT: Index     0123456789          0123456789          0

# CHECK:      [0,0]     DeeeeeER  .    .    .    .    .    .    .   vmulps	%ymm0, %ymm1, %ymm2
# CHECK-NEXT: [0,1]     D==eeeeeeeeeeER.    .    .    .    .    .   vfrczpd	%xmm1, %xmm2
# CHECK-NEXT: [0,2]     .D===========eeeeeER.    .    .    .    .   vmulps	%ymm2, %ymm3, %ymm4
# CHECK-NEXT: [0,3]     .D================eeeeeER.    .    .    .   vaddps	%ymm4, %ymm5, %ymm6
# CHECK-NEXT: [0,4]     . D====================eeeeeER.    .    .   vmulps	%ymm6, %ymm3, %ymm4
# CHECK-NEXT: [0,5]     . D=========================eeeeeER.    .   vaddps	%ymm4, %ymm5, %ymm0
# CHECK-NEXT: [1,0]     .  D=============================eeeeeER.   vmulps	%ymm0, %ymm1, %ymm2
# CHECK-NEXT: [1,1]     .  DeeeeeeeeeeE------------------------R.   vfrczpd	%xmm1, %xmm2
# CHECK-NEXT: [1,2]     .   D==========eeeeeE------------------R.   vmulps	%ymm2, %ymm3, %ymm4
# CHECK-NEXT: [1,3]     .   D===============eeeeeE-------------R.   vaddps	%ymm4, %ymm5, %ymm6
# CHECK-NEXT: [1,4]     .    D===================eeeeeE---------R   vmulps	%ymm6, %ymm3, %ymm4
# CHECK-NEXT: [1,5]     .    D========================eeeeeE----R   vaddps	%ymm4, %ymm5, %ymm0

# CHECK:      Average Wait times (based on the timeline view):
# CHECK-NEXT: [0]: Executions
# CHECK-NEXT: [1]: Average time spent waiting in a scheduler's queue
# CHECK-NEXT: [2]: Average time spent waiting in a scheduler's queue while ready
# CHECK-NEXT: [3]: Average time elapsed from WB until retire stage

# CHECK:            [0]    [1]    [2]    [3]
# CHECK-NEXT: 0.     2     15.5   0.5    0.0       vmulps	%ymm0, %ymm1, %ymm2
# CHECK-NEXT: 1.     2     2.0    2.0    12.0      vfrczpd	%xmm1, %xmm2
# CHECK-NEXT: 2.     2     11.5   0.5    9.0       vmulps	%ymm2, %ymm3, %ymm4
# CHECK-NEXT: 3.     2     16.5   0.0    6.5       vaddps	%ymm4, %ymm5, %ymm6
# CHECK-NEXT: 4.     2     20.5   0.0    4.5       vmulps	%ymm6, %ymm3, %ymm4
# CHECK-NEXT: 5.     2     25.5   0.0    2.0       vaddps	%ymm4, %ymm5, %ymm0

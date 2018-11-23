# NOTE: Assertions have been autogenerated by utils/update_mca_test_checks.py
# RUN: llvm-mca -march=aarch64 -mcpu=cortex-a57 -resource-pressure=false < %s | FileCheck %s

  add	x0, x1, x2, lsl #3

# CHECK:      Iterations:        100
# CHECK-NEXT: Instructions:      100
# CHECK-NEXT: Total Cycles:      53
# CHECK-NEXT: Total uOps:        100

# CHECK:      Dispatch Width:    3
# CHECK-NEXT: uOps Per Cycle:    1.89
# CHECK-NEXT: IPC:               1.89
# CHECK-NEXT: Block RThroughput: 0.5

# CHECK:      Instruction Info:
# CHECK-NEXT: [1]: #uOps
# CHECK-NEXT: [2]: Latency
# CHECK-NEXT: [3]: RThroughput
# CHECK-NEXT: [4]: MayLoad
# CHECK-NEXT: [5]: MayStore
# CHECK-NEXT: [6]: HasSideEffects (U)

# CHECK:      [1]    [2]    [3]    [4]    [5]    [6]    Instructions:
# CHECK-NEXT:  1      1     0.50                        add	x0, x1, x2, lsl #3

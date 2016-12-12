// XFAIL: *
// RUN: not llvm-mc -arch=amdgcn -mcpu=tonga -show-encoding %s 2>&1 | FileCheck -check-prefix=NOVI %s

v_add_f16 v1, 0xfffff, v2
// NOVI: 19: error: invalid operand for instruction

v_add_f16 v1, 0x10000, v2
// NOVI: 19: error: invalid operand for instruction

v_add_f16 v1, v2, -0.0
v_add_f16 v1, v2, 1



// FIXME: Should give truncate error
v_add_f16 v1, -32769, v2
v_add_f16 v1, 65536, v2

v_add_f32 v1, 4294967296, v2
v_add_f32 v1, 0x0000000100000000, v2
v_and_b32 v1, 0x0000000100000000, v2

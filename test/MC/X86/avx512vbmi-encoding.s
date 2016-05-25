// RUN: llvm-mc -triple x86_64-unknown-unknown -mcpu=skx -mattr=+avx512vl -mattr=+avx512vbmi --show-encoding %s | FileCheck %s

     vpermb %xmm28, %xmm29, %xmm30 {%k7}
//CHECK: vpermb %xmm28, %xmm29, %xmm30 {%k7}
//CHECK: encoding: [0x62,0x02,0x15,0x07,0x8d,0xf4]

     vpermb %xmm28, %xmm29, %xmm30 {%k7} {z}
//CHECK: vpermb %xmm28, %xmm29, %xmm30 {%k7} {z}
//CHECK: encoding: [0x62,0x02,0x15,0x87,0x8d,0xf4]

     vpermb (%rcx), %xmm29, %xmm30
//CHECK: vpermb (%rcx), %xmm29, %xmm30
//CHECK: encoding: [0x62,0x62,0x15,0x00,0x8d,0x31]

     vpermb 0x123(%rax,%r14,8), %xmm29, %xmm30
//CHECK: vpermb 291(%rax,%r14,8), %xmm29, %xmm30
//CHECK: encoding: [0x62,0x22,0x15,0x00,0x8d,0xb4,0xf0,0x23,0x01,0x00,0x00]

     vpermb 0x7f0(%rdx), %xmm29, %xmm30
//CHECK: vpermb 2032(%rdx), %xmm29, %xmm30
//CHECK: encoding: [0x62,0x62,0x15,0x00,0x8d,0x72,0x7f]

     vpermb 0x800(%rdx), %xmm29, %xmm30
//CHECK: vpermb 2048(%rdx), %xmm29, %xmm30
//CHECK: encoding: [0x62,0x62,0x15,0x00,0x8d,0xb2,0x00,0x08,0x00,0x00]

     vpermb -0x800(%rdx), %xmm29, %xmm30
//CHECK: vpermb -2048(%rdx), %xmm29, %xmm30
//CHECK: encoding: [0x62,0x62,0x15,0x00,0x8d,0x72,0x80]

     vpermb -0x810(%rdx), %xmm29, %xmm30
//CHECK: vpermb -2064(%rdx), %xmm29, %xmm30
//CHECK: encoding: [0x62,0x62,0x15,0x00,0x8d,0xb2,0xf0,0xf7,0xff,0xff]

     vpermb %ymm28, %ymm29, %ymm30
//CHECK: vpermb %ymm28, %ymm29, %ymm30
//CHECK: encoding: [0x62,0x02,0x15,0x20,0x8d,0xf4]

     vpermb %ymm28, %ymm29, %ymm30 {%k7}
//CHECK: vpermb %ymm28, %ymm29, %ymm30 {%k7}
//CHECK: encoding: [0x62,0x02,0x15,0x27,0x8d,0xf4]

     vpermb %ymm28, %ymm29, %ymm30 {%k7} {z}
//CHECK: vpermb %ymm28, %ymm29, %ymm30 {%k7} {z}
//CHECK: encoding: [0x62,0x02,0x15,0xa7,0x8d,0xf4]

     vpermb (%rcx), %ymm29, %ymm30
//CHECK: vpermb (%rcx), %ymm29, %ymm30
//CHECK: encoding: [0x62,0x62,0x15,0x20,0x8d,0x31]

     vpermb 0x123(%rax,%r14,8), %ymm29, %ymm30
//CHECK: vpermb 291(%rax,%r14,8), %ymm29, %ymm30
//CHECK: encoding: [0x62,0x22,0x15,0x20,0x8d,0xb4,0xf0,0x23,0x01,0x00,0x00]

     vpermb 0xfe0(%rdx), %ymm29, %ymm30
//CHECK: vpermb 4064(%rdx), %ymm29, %ymm30
//CHECK: encoding: [0x62,0x62,0x15,0x20,0x8d,0x72,0x7f]

     vpermb 0x1000(%rdx), %ymm29, %ymm30
//CHECK: vpermb 4096(%rdx), %ymm29, %ymm30
//CHECK: encoding: [0x62,0x62,0x15,0x20,0x8d,0xb2,0x00,0x10,0x00,0x00]

     vpermb -0x1000(%rdx), %ymm29, %ymm30
//CHECK: vpermb -4096(%rdx), %ymm29, %ymm30
//CHECK: encoding: [0x62,0x62,0x15,0x20,0x8d,0x72,0x80]

     vpermb -0x1020(%rdx), %ymm29, %ymm30
//CHECK: vpermb -4128(%rdx), %ymm29, %ymm30
//CHECK: encoding: [0x62,0x62,0x15,0x20,0x8d,0xb2,0xe0,0xef,0xff,0xff]

     vpermb %xmm28, %xmm29, %xmm30
//CHECK: vpermb %xmm28, %xmm29, %xmm30
//CHECK: encoding: [0x62,0x02,0x15,0x00,0x8d,0xf4]

     vpermb 0x1234(%rax,%r14,8), %xmm29, %xmm30
//CHECK: vpermb 4660(%rax,%r14,8), %xmm29, %xmm30
//CHECK: encoding: [0x62,0x22,0x15,0x00,0x8d,0xb4,0xf0,0x34,0x12,0x00,0x00]

     vpermb 0x1234(%rax,%r14,8), %ymm29, %ymm30
//CHECK: vpermb 4660(%rax,%r14,8), %ymm29, %ymm30
//CHECK: encoding: [0x62,0x22,0x15,0x20,0x8d,0xb4,0xf0,0x34,0x12,0x00,0x00]

     vpermb %zmm28, %zmm29, %zmm30
//CHECK: vpermb %zmm28, %zmm29, %zmm30
//CHECK: encoding: [0x62,0x02,0x15,0x40,0x8d,0xf4]

     vpermb %zmm28, %zmm29, %zmm30 {%k7}
//CHECK: vpermb %zmm28, %zmm29, %zmm30 {%k7}
//CHECK: encoding: [0x62,0x02,0x15,0x47,0x8d,0xf4]

     vpermb %zmm28, %zmm29, %zmm30 {%k7} {z}
//CHECK: vpermb %zmm28, %zmm29, %zmm30 {%k7} {z}
//CHECK: encoding: [0x62,0x02,0x15,0xc7,0x8d,0xf4]

     vpermb (%rcx), %zmm29, %zmm30
//CHECK: vpermb (%rcx), %zmm29, %zmm30
//CHECK: encoding: [0x62,0x62,0x15,0x40,0x8d,0x31]

     vpermb 0x123(%rax,%r14,8), %zmm29, %zmm30
//CHECK: vpermb 291(%rax,%r14,8), %zmm29, %zmm30
//CHECK: encoding: [0x62,0x22,0x15,0x40,0x8d,0xb4,0xf0,0x23,0x01,0x00,0x00]

     vpermb 0x1fc0(%rdx), %zmm29, %zmm30
//CHECK: vpermb 8128(%rdx), %zmm29, %zmm30
//CHECK: encoding: [0x62,0x62,0x15,0x40,0x8d,0x72,0x7f]

     vpermb 0x2000(%rdx), %zmm29, %zmm30
//CHECK: vpermb 8192(%rdx), %zmm29, %zmm30
//CHECK: encoding: [0x62,0x62,0x15,0x40,0x8d,0xb2,0x00,0x20,0x00,0x00]

     vpermb -0x2000(%rdx), %zmm29, %zmm30
//CHECK: vpermb -8192(%rdx), %zmm29, %zmm30
//CHECK: encoding: [0x62,0x62,0x15,0x40,0x8d,0x72,0x80]

     vpermb -0x2040(%rdx), %zmm29, %zmm30
//CHECK: vpermb -8256(%rdx), %zmm29, %zmm30
//CHECK: encoding: [0x62,0x62,0x15,0x40,0x8d,0xb2,0xc0,0xdf,0xff,0xff]

     vpermb 0x1234(%rax,%r14,8), %zmm29, %zmm30
//CHECK: vpermb 4660(%rax,%r14,8), %zmm29, %zmm30
//CHECK: encoding: [0x62,0x22,0x15,0x40,0x8d,0xb4,0xf0,0x34,0x12,0x00,0x00]

     vpermt2b %xmm28, %xmm29, %xmm30
//CHECK: vpermt2b %xmm28, %xmm29, %xmm30
//CHECK: encoding: [0x62,0x02,0x15,0x00,0x7d,0xf4]

     vpermt2b %xmm28, %xmm29, %xmm30 {%k7}
//CHECK: vpermt2b %xmm28, %xmm29, %xmm30 {%k7}
//CHECK: encoding: [0x62,0x02,0x15,0x07,0x7d,0xf4]

     vpermt2b %xmm28, %xmm29, %xmm30 {%k7} {z}
//CHECK: vpermt2b %xmm28, %xmm29, %xmm30 {%k7} {z}
//CHECK: encoding: [0x62,0x02,0x15,0x87,0x7d,0xf4]

     vpermt2b (%rcx), %xmm29, %xmm30
//CHECK: vpermt2b (%rcx), %xmm29, %xmm30
//CHECK: encoding: [0x62,0x62,0x15,0x00,0x7d,0x31]

     vpermt2b 0x123(%rax,%r14,8), %xmm29, %xmm30
//CHECK: vpermt2b 291(%rax,%r14,8), %xmm29, %xmm30
//CHECK: encoding: [0x62,0x22,0x15,0x00,0x7d,0xb4,0xf0,0x23,0x01,0x00,0x00]

     vpermt2b 0x7f0(%rdx), %xmm29, %xmm30
//CHECK: vpermt2b 2032(%rdx), %xmm29, %xmm30
//CHECK: encoding: [0x62,0x62,0x15,0x00,0x7d,0x72,0x7f]

     vpermt2b 0x800(%rdx), %xmm29, %xmm30
//CHECK: vpermt2b 2048(%rdx), %xmm29, %xmm30
//CHECK: encoding: [0x62,0x62,0x15,0x00,0x7d,0xb2,0x00,0x08,0x00,0x00]

     vpermt2b -0x800(%rdx), %xmm29, %xmm30
//CHECK: vpermt2b -2048(%rdx), %xmm29, %xmm30
//CHECK: encoding: [0x62,0x62,0x15,0x00,0x7d,0x72,0x80]

     vpermt2b -0x810(%rdx), %xmm29, %xmm30
//CHECK: vpermt2b -2064(%rdx), %xmm29, %xmm30
//CHECK: encoding: [0x62,0x62,0x15,0x00,0x7d,0xb2,0xf0,0xf7,0xff,0xff]

     vpermt2b %ymm28, %ymm29, %ymm30
//CHECK: vpermt2b %ymm28, %ymm29, %ymm30
//CHECK: encoding: [0x62,0x02,0x15,0x20,0x7d,0xf4]

     vpermt2b %ymm28, %ymm29, %ymm30 {%k7}
//CHECK: vpermt2b %ymm28, %ymm29, %ymm30 {%k7}
//CHECK: encoding: [0x62,0x02,0x15,0x27,0x7d,0xf4]

     vpermt2b %ymm28, %ymm29, %ymm30 {%k7} {z}
//CHECK: vpermt2b %ymm28, %ymm29, %ymm30 {%k7} {z}
//CHECK: encoding: [0x62,0x02,0x15,0xa7,0x7d,0xf4]

     vpermt2b (%rcx), %ymm29, %ymm30
//CHECK: vpermt2b (%rcx), %ymm29, %ymm30
//CHECK: encoding: [0x62,0x62,0x15,0x20,0x7d,0x31]

     vpermt2b 0x123(%rax,%r14,8), %ymm29, %ymm30
//CHECK: vpermt2b 291(%rax,%r14,8), %ymm29, %ymm30
//CHECK: encoding: [0x62,0x22,0x15,0x20,0x7d,0xb4,0xf0,0x23,0x01,0x00,0x00]

     vpermt2b 0xfe0(%rdx), %ymm29, %ymm30
//CHECK: vpermt2b 4064(%rdx), %ymm29, %ymm30
//CHECK: encoding: [0x62,0x62,0x15,0x20,0x7d,0x72,0x7f]

     vpermt2b 0x1000(%rdx), %ymm29, %ymm30
//CHECK: vpermt2b 4096(%rdx), %ymm29, %ymm30
//CHECK: encoding: [0x62,0x62,0x15,0x20,0x7d,0xb2,0x00,0x10,0x00,0x00]

     vpermt2b -0x1000(%rdx), %ymm29, %ymm30
//CHECK: vpermt2b -4096(%rdx), %ymm29, %ymm30
//CHECK: encoding: [0x62,0x62,0x15,0x20,0x7d,0x72,0x80]

     vpermt2b -0x1020(%rdx), %ymm29, %ymm30
//CHECK: vpermt2b -4128(%rdx), %ymm29, %ymm30
//CHECK: encoding: [0x62,0x62,0x15,0x20,0x7d,0xb2,0xe0,0xef,0xff,0xff]

     vpermt2b 0x1234(%rax,%r14,8), %xmm29, %xmm30
//CHECK: vpermt2b 4660(%rax,%r14,8), %xmm29, %xmm30
//CHECK: encoding: [0x62,0x22,0x15,0x00,0x7d,0xb4,0xf0,0x34,0x12,0x00,0x00]

     vpermt2b 0x1234(%rax,%r14,8), %ymm29, %ymm30
//CHECK: vpermt2b 4660(%rax,%r14,8), %ymm29, %ymm30
//CHECK: encoding: [0x62,0x22,0x15,0x20,0x7d,0xb4,0xf0,0x34,0x12,0x00,0x00]

     vpermt2b %zmm28, %zmm29, %zmm30
//CHECK: vpermt2b %zmm28, %zmm29, %zmm30
//CHECK: encoding: [0x62,0x02,0x15,0x40,0x7d,0xf4]

     vpermt2b %zmm28, %zmm29, %zmm30 {%k7}
//CHECK: vpermt2b %zmm28, %zmm29, %zmm30 {%k7}
//CHECK: encoding: [0x62,0x02,0x15,0x47,0x7d,0xf4]

     vpermt2b %zmm28, %zmm29, %zmm30 {%k7} {z}
//CHECK: vpermt2b %zmm28, %zmm29, %zmm30 {%k7} {z}
//CHECK: encoding: [0x62,0x02,0x15,0xc7,0x7d,0xf4]

     vpermt2b (%rcx), %zmm29, %zmm30
//CHECK: vpermt2b (%rcx), %zmm29, %zmm30
//CHECK: encoding: [0x62,0x62,0x15,0x40,0x7d,0x31]

     vpermt2b 0x123(%rax,%r14,8), %zmm29, %zmm30
//CHECK: vpermt2b 291(%rax,%r14,8), %zmm29, %zmm30
//CHECK: encoding: [0x62,0x22,0x15,0x40,0x7d,0xb4,0xf0,0x23,0x01,0x00,0x00]

     vpermt2b 0x1fc0(%rdx), %zmm29, %zmm30
//CHECK: vpermt2b 8128(%rdx), %zmm29, %zmm30
//CHECK: encoding: [0x62,0x62,0x15,0x40,0x7d,0x72,0x7f]

     vpermt2b 0x2000(%rdx), %zmm29, %zmm30
//CHECK: vpermt2b 8192(%rdx), %zmm29, %zmm30
//CHECK: encoding: [0x62,0x62,0x15,0x40,0x7d,0xb2,0x00,0x20,0x00,0x00]

     vpermt2b -0x2000(%rdx), %zmm29, %zmm30
//CHECK: vpermt2b -8192(%rdx), %zmm29, %zmm30
//CHECK: encoding: [0x62,0x62,0x15,0x40,0x7d,0x72,0x80]

     vpermt2b -0x2040(%rdx), %zmm29, %zmm30
//CHECK: vpermt2b -8256(%rdx), %zmm29, %zmm30
//CHECK: encoding: [0x62,0x62,0x15,0x40,0x7d,0xb2,0xc0,0xdf,0xff,0xff]

     vpermt2b 0x1234(%rax,%r14,8), %zmm29, %zmm30
//CHECK: vpermt2b 4660(%rax,%r14,8), %zmm29, %zmm30
//CHECK: encoding: [0x62,0x22,0x15,0x40,0x7d,0xb4,0xf0,0x34,0x12,0x00,0x00]

     vpermi2b %xmm28, %xmm29, %xmm30
//CHECK: vpermi2b %xmm28, %xmm29, %xmm30
//CHECK: encoding: [0x62,0x02,0x15,0x00,0x75,0xf4]

     vpermi2b %xmm28, %xmm29, %xmm30 {%k7}
//CHECK: vpermi2b %xmm28, %xmm29, %xmm30 {%k7}
//CHECK: encoding: [0x62,0x02,0x15,0x07,0x75,0xf4]

     vpermi2b %xmm28, %xmm29, %xmm30 {%k7} {z}
//CHECK: vpermi2b %xmm28, %xmm29, %xmm30 {%k7} {z}
//CHECK: encoding: [0x62,0x02,0x15,0x87,0x75,0xf4]

     vpermi2b (%rcx), %xmm29, %xmm30
//CHECK: vpermi2b (%rcx), %xmm29, %xmm30
//CHECK: encoding: [0x62,0x62,0x15,0x00,0x75,0x31]

     vpermi2b 0x123(%rax,%r14,8), %xmm29, %xmm30
//CHECK: vpermi2b 291(%rax,%r14,8), %xmm29, %xmm30
//CHECK: encoding: [0x62,0x22,0x15,0x00,0x75,0xb4,0xf0,0x23,0x01,0x00,0x00]

     vpermi2b 0x7f0(%rdx), %xmm29, %xmm30
//CHECK: vpermi2b 2032(%rdx), %xmm29, %xmm30
//CHECK: encoding: [0x62,0x62,0x15,0x00,0x75,0x72,0x7f]

     vpermi2b 0x800(%rdx), %xmm29, %xmm30
//CHECK: vpermi2b 2048(%rdx), %xmm29, %xmm30
//CHECK: encoding: [0x62,0x62,0x15,0x00,0x75,0xb2,0x00,0x08,0x00,0x00]

     vpermi2b -0x800(%rdx), %xmm29, %xmm30
//CHECK: vpermi2b -2048(%rdx), %xmm29, %xmm30
//CHECK: encoding: [0x62,0x62,0x15,0x00,0x75,0x72,0x80]

     vpermi2b -0x810(%rdx), %xmm29, %xmm30
//CHECK: vpermi2b -2064(%rdx), %xmm29, %xmm30
//CHECK: encoding: [0x62,0x62,0x15,0x00,0x75,0xb2,0xf0,0xf7,0xff,0xff]

     vpermi2b %ymm28, %ymm29, %ymm30
//CHECK: vpermi2b %ymm28, %ymm29, %ymm30
//CHECK: encoding: [0x62,0x02,0x15,0x20,0x75,0xf4]

     vpermi2b %ymm28, %ymm29, %ymm30 {%k7}
//CHECK: vpermi2b %ymm28, %ymm29, %ymm30 {%k7}
//CHECK: encoding: [0x62,0x02,0x15,0x27,0x75,0xf4]

     vpermi2b %ymm28, %ymm29, %ymm30 {%k7} {z}
//CHECK: vpermi2b %ymm28, %ymm29, %ymm30 {%k7} {z}
//CHECK: encoding: [0x62,0x02,0x15,0xa7,0x75,0xf4]

     vpermi2b (%rcx), %ymm29, %ymm30
//CHECK: vpermi2b (%rcx), %ymm29, %ymm30
//CHECK: encoding: [0x62,0x62,0x15,0x20,0x75,0x31]

     vpermi2b 0x123(%rax,%r14,8), %ymm29, %ymm30
//CHECK: vpermi2b 291(%rax,%r14,8), %ymm29, %ymm30
//CHECK: encoding: [0x62,0x22,0x15,0x20,0x75,0xb4,0xf0,0x23,0x01,0x00,0x00]

     vpermi2b 0xfe0(%rdx), %ymm29, %ymm30
//CHECK: vpermi2b 4064(%rdx), %ymm29, %ymm30
//CHECK: encoding: [0x62,0x62,0x15,0x20,0x75,0x72,0x7f]

     vpermi2b 0x1000(%rdx), %ymm29, %ymm30
//CHECK: vpermi2b 4096(%rdx), %ymm29, %ymm30
//CHECK: encoding: [0x62,0x62,0x15,0x20,0x75,0xb2,0x00,0x10,0x00,0x00]

     vpermi2b -0x1000(%rdx), %ymm29, %ymm30
//CHECK: vpermi2b -4096(%rdx), %ymm29, %ymm30
//CHECK: encoding: [0x62,0x62,0x15,0x20,0x75,0x72,0x80]

     vpermi2b -0x1020(%rdx), %ymm29, %ymm30
//CHECK: vpermi2b -4128(%rdx), %ymm29, %ymm30
//CHECK: encoding: [0x62,0x62,0x15,0x20,0x75,0xb2,0xe0,0xef,0xff,0xff]

     vpermi2b 0x1234(%rax,%r14,8), %xmm29, %xmm30
//CHECK: vpermi2b 4660(%rax,%r14,8), %xmm29, %xmm30
//CHECK: encoding: [0x62,0x22,0x15,0x00,0x75,0xb4,0xf0,0x34,0x12,0x00,0x00]

     vpermi2b 0x1234(%rax,%r14,8), %ymm29, %ymm30
//CHECK: vpermi2b 4660(%rax,%r14,8), %ymm29, %ymm30
//CHECK: encoding: [0x62,0x22,0x15,0x20,0x75,0xb4,0xf0,0x34,0x12,0x00,0x00]

     vpermi2b %zmm28, %zmm29, %zmm30
//CHECK: vpermi2b %zmm28, %zmm29, %zmm30
//CHECK: encoding: [0x62,0x02,0x15,0x40,0x75,0xf4]

     vpermi2b %zmm28, %zmm29, %zmm30 {%k7}
//CHECK: vpermi2b %zmm28, %zmm29, %zmm30 {%k7}
//CHECK: encoding: [0x62,0x02,0x15,0x47,0x75,0xf4]

     vpermi2b %zmm28, %zmm29, %zmm30 {%k7} {z}
//CHECK: vpermi2b %zmm28, %zmm29, %zmm30 {%k7} {z}
//CHECK: encoding: [0x62,0x02,0x15,0xc7,0x75,0xf4]

     vpermi2b (%rcx), %zmm29, %zmm30
//CHECK: vpermi2b (%rcx), %zmm29, %zmm30
//CHECK: encoding: [0x62,0x62,0x15,0x40,0x75,0x31]

     vpermi2b 0x123(%rax,%r14,8), %zmm29, %zmm30
//CHECK: vpermi2b 291(%rax,%r14,8), %zmm29, %zmm30
//CHECK: encoding: [0x62,0x22,0x15,0x40,0x75,0xb4,0xf0,0x23,0x01,0x00,0x00]

     vpermi2b 0x1fc0(%rdx), %zmm29, %zmm30
//CHECK: vpermi2b 8128(%rdx), %zmm29, %zmm30
//CHECK: encoding: [0x62,0x62,0x15,0x40,0x75,0x72,0x7f]

     vpermi2b 0x2000(%rdx), %zmm29, %zmm30
//CHECK: vpermi2b 8192(%rdx), %zmm29, %zmm30
//CHECK: encoding: [0x62,0x62,0x15,0x40,0x75,0xb2,0x00,0x20,0x00,0x00]

     vpermi2b -0x2000(%rdx), %zmm29, %zmm30
//CHECK: vpermi2b -8192(%rdx), %zmm29, %zmm30
//CHECK: encoding: [0x62,0x62,0x15,0x40,0x75,0x72,0x80]

     vpermi2b -0x2040(%rdx), %zmm29, %zmm30
//CHECK: vpermi2b -8256(%rdx), %zmm29, %zmm30
//CHECK: encoding: [0x62,0x62,0x15,0x40,0x75,0xb2,0xc0,0xdf,0xff,0xff]

     vpermi2b 0x1234(%rax,%r14,8), %zmm29, %zmm30
//CHECK: vpermi2b 4660(%rax,%r14,8), %zmm29, %zmm30
//CHECK: encoding: [0x62,0x22,0x15,0x40,0x75,0xb4,0xf0,0x34,0x12,0x00,0x00]

  vpmultishiftqb %xmm28, %xmm29, %xmm30
//CHECK: vpmultishiftqb %xmm28, %xmm29, %xmm30
//CHECK: encoding: [0x62,0x02,0x95,0x00,0x83,0xf4]

  vpmultishiftqb %xmm28, %xmm29, %xmm30 {%k7}
//CHECK: vpmultishiftqb %xmm28, %xmm29, %xmm30 {%k7}
//CHECK: encoding: [0x62,0x02,0x95,0x07,0x83,0xf4]

  vpmultishiftqb %xmm28, %xmm29, %xmm30 {%k7} {z}
//CHECK: vpmultishiftqb %xmm28, %xmm29, %xmm30 {%k7} {z}
//CHECK: encoding: [0x62,0x02,0x95,0x87,0x83,0xf4]

  vpmultishiftqb (%rcx), %xmm29, %xmm30
//CHECK: vpmultishiftqb (%rcx), %xmm29, %xmm30
//CHECK: encoding: [0x62,0x62,0x95,0x00,0x83,0x31]

  vpmultishiftqb 0x123(%rax,%r14,8), %xmm29, %xmm30
//CHECK: vpmultishiftqb 291(%rax,%r14,8), %xmm29, %xmm30
//CHECK: encoding: [0x62,0x22,0x95,0x00,0x83,0xb4,0xf0,0x23,0x01,0x00,0x00]

  vpmultishiftqb (%rcx){1to2}, %xmm29, %xmm30
//CHECK: vpmultishiftqb (%rcx){1to2}, %xmm29, %xmm30

//CHECK: encoding: [0x62,0x62,0x95,0x10,0x83,0x31]

  vpmultishiftqb 0x7f0(%rdx), %xmm29, %xmm30
//CHECK: vpmultishiftqb 2032(%rdx), %xmm29, %xmm30
//CHECK: encoding: [0x62,0x62,0x95,0x00,0x83,0x72,0x7f]

  vpmultishiftqb 0x800(%rdx), %xmm29, %xmm30
//CHECK: vpmultishiftqb 2048(%rdx), %xmm29, %xmm30
//CHECK: encoding: [0x62,0x62,0x95,0x00,0x83,0xb2,0x00,0x08,0x00,0x00]

  vpmultishiftqb -0x800(%rdx), %xmm29, %xmm30
//CHECK: vpmultishiftqb -2048(%rdx), %xmm29, %xmm30
//CHECK: encoding: [0x62,0x62,0x95,0x00,0x83,0x72,0x80]

  vpmultishiftqb -0x810(%rdx), %xmm29, %xmm30
//CHECK: vpmultishiftqb -2064(%rdx), %xmm29, %xmm30
//CHECK: encoding: [0x62,0x62,0x95,0x00,0x83,0xb2,0xf0,0xf7,0xff,0xff]

  vpmultishiftqb 0x3f8(%rdx){1to2}, %xmm29, %xmm30
//CHECK: vpmultishiftqb 1016(%rdx){1to2}, %xmm29, %xmm30
//CHECK: encoding: [0x62,0x62,0x95,0x10,0x83,0x72,0x7f]

  vpmultishiftqb 0x400(%rdx){1to2}, %xmm29, %xmm30
//CHECK: vpmultishiftqb 1024(%rdx){1to2}, %xmm29, %xmm30
//CHECK: encoding: [0x62,0x62,0x95,0x10,0x83,0xb2,0x00,0x04,0x00,0x00]

  vpmultishiftqb -0x400(%rdx){1to2}, %xmm29, %xmm30
//CHECK: vpmultishiftqb -1024(%rdx){1to2}, %xmm29, %xmm30
//CHECK: encoding: [0x62,0x62,0x95,0x10,0x83,0x72,0x80]

  vpmultishiftqb -0x408(%rdx){1to2}, %xmm29, %xmm30
//CHECK: vpmultishiftqb -1032(%rdx){1to2}, %xmm29, %xmm30
//CHECK: encoding: [0x62,0x62,0x95,0x10,0x83,0xb2,0xf8,0xfb,0xff,0xff]

  vpmultishiftqb %ymm28, %ymm29, %ymm30
//CHECK: vpmultishiftqb %ymm28, %ymm29, %ymm30
//CHECK: encoding: [0x62,0x02,0x95,0x20,0x83,0xf4]

  vpmultishiftqb %ymm28, %ymm29, %ymm30 {%k7}
//CHECK: vpmultishiftqb %ymm28, %ymm29, %ymm30 {%k7}
//CHECK: encoding: [0x62,0x02,0x95,0x27,0x83,0xf4]

  vpmultishiftqb %ymm28, %ymm29, %ymm30 {%k7} {z}
//CHECK: vpmultishiftqb %ymm28, %ymm29, %ymm30 {%k7} {z}
//CHECK: encoding: [0x62,0x02,0x95,0xa7,0x83,0xf4]

  vpmultishiftqb (%rcx), %ymm29, %ymm30
//CHECK: vpmultishiftqb (%rcx), %ymm29, %ymm30
//CHECK: encoding: [0x62,0x62,0x95,0x20,0x83,0x31]

  vpmultishiftqb 0x123(%rax,%r14,8), %ymm29, %ymm30
//CHECK: vpmultishiftqb 291(%rax,%r14,8), %ymm29, %ymm30
//CHECK: encoding: [0x62,0x22,0x95,0x20,0x83,0xb4,0xf0,0x23,0x01,0x00,0x00]

  vpmultishiftqb (%rcx){1to4}, %ymm29, %ymm30
//CHECK: vpmultishiftqb (%rcx){1to4}, %ymm29, %ymm30
//CHECK: encoding: [0x62,0x62,0x95,0x30,0x83,0x31]

  vpmultishiftqb 0xfe0(%rdx), %ymm29, %ymm30
//CHECK: vpmultishiftqb 4064(%rdx), %ymm29, %ymm30
//CHECK: encoding: [0x62,0x62,0x95,0x20,0x83,0x72,0x7f]

  vpmultishiftqb 0x1000(%rdx), %ymm29, %ymm30
//CHECK: vpmultishiftqb 4096(%rdx), %ymm29, %ymm30
//CHECK: encoding: [0x62,0x62,0x95,0x20,0x83,0xb2,0x00,0x10,0x00,0x00]

  vpmultishiftqb -0x1000(%rdx), %ymm29, %ymm30
//CHECK: vpmultishiftqb -4096(%rdx), %ymm29, %ymm30
//CHECK: encoding: [0x62,0x62,0x95,0x20,0x83,0x72,0x80]

  vpmultishiftqb -0x1020(%rdx), %ymm29, %ymm30
//CHECK: vpmultishiftqb -4128(%rdx), %ymm29, %ymm30
//CHECK: encoding: [0x62,0x62,0x95,0x20,0x83,0xb2,0xe0,0xef,0xff,0xff]

  vpmultishiftqb 0x3f8(%rdx){1to4}, %ymm29, %ymm30
//CHECK: vpmultishiftqb 1016(%rdx){1to4}, %ymm29, %ymm30
//CHECK: encoding: [0x62,0x62,0x95,0x30,0x83,0x72,0x7f]

  vpmultishiftqb 0x400(%rdx){1to4}, %ymm29, %ymm30
//CHECK: vpmultishiftqb 1024(%rdx){1to4}, %ymm29, %ymm30
//CHECK: encoding: [0x62,0x62,0x95,0x30,0x83,0xb2,0x00,0x04,0x00,0x00]

  vpmultishiftqb -0x400(%rdx){1to4}, %ymm29, %ymm30
//CHECK: vpmultishiftqb -1024(%rdx){1to4}, %ymm29, %ymm30
//CHECK: encoding: [0x62,0x62,0x95,0x30,0x83,0x72,0x80]

  vpmultishiftqb -0x408(%rdx){1to4}, %ymm29, %ymm30
//CHECK: vpmultishiftqb -1032(%rdx){1to4}, %ymm29, %ymm30
//CHECK: encoding: [0x62,0x62,0x95,0x30,0x83,0xb2,0xf8,0xfb,0xff,0xff]

  vpmultishiftqb 0x1234(%rax,%r14,8), %xmm29, %xmm30
//CHECK: vpmultishiftqb 4660(%rax,%r14,8), %xmm29, %xmm30
//CHECK: encoding: [0x62,0x22,0x95,0x00,0x83,0xb4,0xf0,0x34,0x12,0x00,0x00]

  vpmultishiftqb 0x1234(%rax,%r14,8), %ymm29, %ymm30
//CHECK: vpmultishiftqb 4660(%rax,%r14,8), %ymm29, %ymm30
//CHECK: encoding: [0x62,0x22,0x95,0x20,0x83,0xb4,0xf0,0x34,0x12,0x00,0x00]

  vpmultishiftqb %zmm28, %zmm29, %zmm30
//CHECK: vpmultishiftqb %zmm28, %zmm29, %zmm30
//CHECK: encoding: [0x62,0x02,0x95,0x40,0x83,0xf4]

  vpmultishiftqb %zmm28, %zmm29, %zmm30 {%k7}
//CHECK: vpmultishiftqb %zmm28, %zmm29, %zmm30 {%k7}
//CHECK: encoding: [0x62,0x02,0x95,0x47,0x83,0xf4]

  vpmultishiftqb %zmm28, %zmm29, %zmm30 {%k7} {z}
//CHECK: vpmultishiftqb %zmm28, %zmm29, %zmm30 {%k7} {z}
//CHECK: encoding: [0x62,0x02,0x95,0xc7,0x83,0xf4]

  vpmultishiftqb (%rcx), %zmm29, %zmm30
//CHECK: vpmultishiftqb (%rcx), %zmm29, %zmm30
//CHECK: encoding: [0x62,0x62,0x95,0x40,0x83,0x31]

  vpmultishiftqb 0x123(%rax,%r14,8), %zmm29, %zmm30
//CHECK: vpmultishiftqb 291(%rax,%r14,8), %zmm29, %zmm30
//CHECK: encoding: [0x62,0x22,0x95,0x40,0x83,0xb4,0xf0,0x23,0x01,0x00,0x00]

  vpmultishiftqb (%rcx){1to8}, %zmm29, %zmm30
//CHECK: vpmultishiftqb (%rcx){1to8}, %zmm29, %zmm30
//CHECK: encoding: [0x62,0x62,0x95,0x50,0x83,0x31]

  vpmultishiftqb 0x1fc0(%rdx), %zmm29, %zmm30
//CHECK: vpmultishiftqb 8128(%rdx), %zmm29, %zmm30
//CHECK: encoding: [0x62,0x62,0x95,0x40,0x83,0x72,0x7f]

  vpmultishiftqb 0x2000(%rdx), %zmm29, %zmm30
//CHECK: vpmultishiftqb 8192(%rdx), %zmm29, %zmm30
//CHECK: encoding: [0x62,0x62,0x95,0x40,0x83,0xb2,0x00,0x20,0x00,0x00]

  vpmultishiftqb -0x2000(%rdx), %zmm29, %zmm30
//CHECK: vpmultishiftqb -8192(%rdx), %zmm29, %zmm30
//CHECK: encoding: [0x62,0x62,0x95,0x40,0x83,0x72,0x80]

  vpmultishiftqb -0x2040(%rdx), %zmm29, %zmm30
//CHECK: vpmultishiftqb -8256(%rdx), %zmm29, %zmm30
//CHECK: encoding: [0x62,0x62,0x95,0x40,0x83,0xb2,0xc0,0xdf,0xff,0xff]

  vpmultishiftqb 0x3f8(%rdx){1to8}, %zmm29, %zmm30
//CHECK: vpmultishiftqb 1016(%rdx){1to8}, %zmm29, %zmm30
//CHECK: encoding: [0x62,0x62,0x95,0x50,0x83,0x72,0x7f]

  vpmultishiftqb 0x400(%rdx){1to8}, %zmm29, %zmm30
//CHECK: vpmultishiftqb 1024(%rdx){1to8}, %zmm29, %zmm30
//CHECK: encoding: [0x62,0x62,0x95,0x50,0x83,0xb2,0x00,0x04,0x00,0x00]

  vpmultishiftqb -0x400(%rdx){1to8}, %zmm29, %zmm30
//CHECK: vpmultishiftqb -1024(%rdx){1to8}, %zmm29, %zmm30
//CHECK: encoding: [0x62,0x62,0x95,0x50,0x83,0x72,0x80]

  vpmultishiftqb -0x408(%rdx){1to8}, %zmm29, %zmm30
//CHECK: vpmultishiftqb -1032(%rdx){1to8}, %zmm29, %zmm30
//CHECK: encoding: [0x62,0x62,0x95,0x50,0x83,0xb2,0xf8,0xfb,0xff,0xff]

  vpmultishiftqb 0x1234(%rax,%r14,8), %zmm29, %zmm30
//CHECK: vpmultishiftqb 4660(%rax,%r14,8), %zmm29, %zmm30
//CHECK: encoding: [0x62,0x22,0x95,0x40,0x83,0xb4,0xf0,0x34,0x12,0x00,0x00]


@ RUN: not llvm-mc -triple thumbv7m-none-eabi      -filetype=obj -o /dev/null %s 2>&1 | FileCheck %s
@ RUN: not llvm-mc -triple thumbv8m.base-none-eabi -filetype=obj -o /dev/null %s 2>&1 | FileCheck %s

label0:
  .word 4

@ CHECK: out of range pc-relative fixup value
  cbz r0, label0
@ CHECK: out of range pc-relative fixup value
  cbnz r0, label0

@ CHECK: out of range pc-relative fixup value
  cbz r0, label1
@ CHECK: out of range pc-relative fixup value
  cbnz r0, label1

  .space 1000
label1:
  .word 4

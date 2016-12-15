; RUN: llc < %s | FileCheck %s

target datalayout = "e-m:e-p:32:32-f64:32:64-f80:32-n8:16:32-S128"
target triple = "i386-unknown-linux-gnu"

@b = global i16 0, align 4

; CHECK-LABEL: @main
; CHECK: cmpl
; CHECK: sbbl
define i32 @main() {
entry:
  %true = icmp eq i32 0, 0
  %const = bitcast i64 -4294967296 to i64
  br i1 %true, label %go, label %if.else

go:
  %b = load i16, i16* @b, align 4
  %sext = shl i16 %b, 8
  %conv = ashr i16 %sext, 8
  %neg4 = xor i64 %const, -1
  %conv5 = zext i16 %conv to i64
  %cmp = icmp slt i64 %conv5, %neg4
  br i1 %cmp, label %if.then, label %if.else

if.then:
  ret i32 42

if.else:
  ret i32 0
}


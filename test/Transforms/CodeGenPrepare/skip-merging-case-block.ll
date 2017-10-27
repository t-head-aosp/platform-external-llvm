; RUN: opt -codegenprepare  < %s  -mtriple=aarch64-none-linux-gnu -S  | FileCheck %s

target datalayout = "e-m:e-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128"
target triple = "aarch64--linux-gnu"

; Expect to skip merging two empty blocks (sw.bb and sw.bb2) into sw.epilog
; as both of them are unlikely executed.
define i32 @f_switch(i32 %c)  {
; CHECK-LABEL: @f_switch
; CHECK-LABEL: entry:
; CHECK: i32 10, label %sw.bb
; CHECK: i32 20, label %sw.bb2
entry:
  switch i32 %c, label %sw.default [
    i32 10, label %sw.bb
    i32 20, label %sw.bb2
    i32 30, label %sw.bb3
    i32 40, label %sw.bb4
  ], !prof !0

sw.bb:                                            ; preds = %entry
  br label %sw.epilog

sw.bb2:                                           ; preds = %entry
  br label %sw.epilog

sw.bb3:                                           ; preds = %entry
  call void bitcast (void (...)* @callcase3 to void ()*)()
  br label %sw.epilog

sw.bb4:                                           ; preds = %entry
  call void bitcast (void (...)* @callcase4 to void ()*)()
  br label %sw.epilog

sw.default:                                       ; preds = %entry
  call void bitcast (void (...)* @calldefault to void ()*)()
  br label %sw.epilog

; CHECK-LABEL: sw.epilog:
; CHECK: %fp.0 = phi void (...)* [ @FD, %sw.default ], [ @F4, %sw.bb4 ], [ @F3, %sw.bb3 ], [ @F2, %sw.bb2 ], [ @F1, %sw.bb ]
sw.epilog:                                        ; preds = %sw.default, %sw.bb3, %sw.bb2, %sw.bb
  %fp.0 = phi void (...)* [ @FD, %sw.default ], [ @F4, %sw.bb4 ], [ @F3, %sw.bb3 ], [ @F2, %sw.bb2 ], [ @F1, %sw.bb ]
  %callee.knr.cast = bitcast void (...)* %fp.0 to void ()*
  call void %callee.knr.cast()
  ret i32 0
}

; Expect not to merge sw.bb2 because of the conflict in the incoming value from
; sw.bb which is already merged.
define i32 @f_switch2(i32 %c)  {
; CHECK-LABEL: @f_switch2
; CHECK-LABEL: entry:
; CHECK: i32 10, label %sw.epilog
; CHECK: i32 20, label %sw.bb2
entry:
  switch i32 %c, label %sw.default [
    i32 10, label %sw.bb
    i32 20, label %sw.bb2
    i32 30, label %sw.bb3
    i32 40, label %sw.bb4
  ], !prof !1

sw.bb:                                            ; preds = %entry
  br label %sw.epilog

sw.bb2:                                           ; preds = %entry
  br label %sw.epilog

sw.bb3:                                           ; preds = %entry
  call void bitcast (void (...)* @callcase3 to void ()*)()
  br label %sw.epilog

sw.bb4:                                           ; preds = %entry
  call void bitcast (void (...)* @callcase4 to void ()*)()
  br label %sw.epilog

sw.default:                                       ; preds = %entry
  call void bitcast (void (...)* @calldefault to void ()*)()
  br label %sw.epilog

; CHECK-LABEL: sw.epilog:
; CHECK: %fp.0 = phi void (...)* [ @FD, %sw.default ], [ @F4, %sw.bb4 ], [ @F3, %sw.bb3 ], [ @F2, %sw.bb2 ], [ @F1, %entry ]
sw.epilog:                                        ; preds = %sw.default, %sw.bb3, %sw.bb2, %sw.bb
  %fp.0 = phi void (...)* [ @FD, %sw.default ], [ @F4, %sw.bb4 ], [ @F3, %sw.bb3 ], [ @F2, %sw.bb2 ], [ @F1, %sw.bb ]
  %callee.knr.cast = bitcast void (...)* %fp.0 to void ()*
  call void %callee.knr.cast()
  ret i32 0
}

; Multiple empty blocks should be considered together if all incoming values
; from them are same.  We expect to merge both empty blocks (sw.bb and sw.bb2)
; because the sum of frequencies are higer than the threshold.
define i32 @f_switch3(i32 %c)  {
; CHECK-LABEL: @f_switch3
; CHECK-LABEL: entry:
; CHECK: i32 10, label %sw.epilog
; CHECK: i32 20, label %sw.epilog
entry:
  switch i32 %c, label %sw.default [
    i32 10, label %sw.bb
    i32 20, label %sw.bb2
    i32 30, label %sw.bb3
    i32 40, label %sw.bb4
  ], !prof !2

sw.bb:                                            ; preds = %entry
  br label %sw.epilog

sw.bb2:                                           ; preds = %entry
  br label %sw.epilog

sw.bb3:                                           ; preds = %entry
  call void bitcast (void (...)* @callcase3 to void ()*)()
  br label %sw.epilog

sw.bb4:                                           ; preds = %entry
  call void bitcast (void (...)* @callcase4 to void ()*)()
  br label %sw.epilog

sw.default:                                       ; preds = %entry
  call void bitcast (void (...)* @calldefault to void ()*)()
  br label %sw.epilog

; CHECK-LABEL: sw.epilog:
; CHECK: %fp.0 = phi void (...)* [ @FD, %sw.default ], [ @F4, %sw.bb4 ], [ @F3, %sw.bb3 ], [ @F1, %entry ], [ @F1, %entry ]
sw.epilog:                                        ; preds = %sw.default, %sw.bb3, %sw.bb2, %sw.bb
  %fp.0 = phi void (...)* [ @FD, %sw.default ], [ @F4, %sw.bb4 ], [ @F3, %sw.bb3 ], [ @F1, %sw.bb2 ], [ @F1, %sw.bb ]
  %callee.knr.cast = bitcast void (...)* %fp.0 to void ()*
  call void %callee.knr.cast()
  ret i32 0
}

declare void @F1(...) local_unnamed_addr
declare void @F2(...) local_unnamed_addr
declare void @F3(...) local_unnamed_addr
declare void @F4(...) local_unnamed_addr
declare void @FD(...) local_unnamed_addr
declare void @callcase3(...) local_unnamed_addr
declare void @callcase4(...) local_unnamed_addr
declare void @calldefault(...) local_unnamed_addr

!0 = !{!"branch_weights", i32 5, i32 1, i32 1,i32 5, i32 5}
!1 = !{!"branch_weights", i32 1 , i32 5, i32 1,i32 1, i32 1}
!2 = !{!"branch_weights", i32 1 , i32 4, i32 1,i32 1, i32 1}

; while.cond does not dominate return, expect to skip merging empty block
; return.loopexit into return.
@b = external global i32, align 4
@a = external global i32*, align 8

define void @f_switch4(i32 %i) local_unnamed_addr personality i8* bitcast (i32 (...)* @__gxx_personality_v0 to i8*) {
; CHECK-LABEL: @f_switch4
entry:
  %0 = load i32, i32* @b, align 4
  %cond = icmp eq i32 %0, 6
  br i1 %cond, label %return, label %if.end

if.end:                                           ; preds = %entry
  %add = add i32 %i, 2
  %1 = load i32*, i32** @a, align 8
  %magicptr = ptrtoint i32* %1 to i32
  br label %while.cond

; CHECK-LABEL: while.cond:
; CHECK: i32 0, label %return.loopexit
; CHECK: i32 47, label %return.loopexit
while.cond:                                       ; preds = %while.cond.backedge, %if.end
  switch i32 %magicptr, label %while.cond.if.end10_crit_edge [
    i32 0, label %return.loopexit
    i32 47, label %return.loopexit
  ]

while.cond.if.end10_crit_edge:                    ; preds = %while.cond
  br label %while.cond.backedge

while.cond.backedge:                              ; preds = %while.cond.if.end10_crit_edge, %if.then9
  br label %while.cond

return.loopexit:                                  ; preds = %while.cond
  br label %return

; CHECK_LABEL: return:
; CHECK: %{{.*}} = phi i32 [ 0, %entry ], [ %add, %return.loopexit ]
return:                                           ; preds = %return.loopexit, %entry
  %retval.4 = phi i32 [ 0, %entry ], [ %add, %return.loopexit ]
  ret void
}
declare i32 @__gxx_personality_v0(...)

; Expect to merge empty block while.cond2.loopexit into while.cond2
define i32 @f_switch5(i32 %i) local_unnamed_addr {
; CHECK-LABEL: @f_switch5
entry:
  %0 = load i32, i32* @b, align 4
  %cond = icmp eq i32 %0, 6
  br i1 %cond, label %while.cond.preheader, label %sw.epilog

while.cond.preheader:                             ; preds = %entry
  %1 = load i32*, i32** @a, align 8
  %magicptr = ptrtoint i32* %1 to i64
  %arrayidx = getelementptr inbounds i32, i32* %1, i64 1
  br label %while.cond

; CHECK-LABEL: while.cond:
; CHECK: i64 32, label %while.cond2
; CHECK: i64 0, label %while.cond2
while.cond:                                       ; preds = %land.rhs, %while.cond.preheader
  switch i64 %magicptr, label %land.rhs [
    i64 32, label %while.cond2.loopexit
    i64 0, label %while.cond2.loopexit
  ]

land.rhs:                                         ; preds = %while.cond
  %2 = load i32, i32* %arrayidx, align 4
  %tobool1 = icmp eq i32 %2, 0
  br i1 %tobool1, label %while.cond2thread-pre-split.loopexit, label %while.cond

while.cond2thread-pre-split.loopexit:             ; preds = %land.rhs
  br label %while.cond2thread-pre-split

while.cond2thread-pre-split:                      ; preds = %while.body4, %while.cond2thread-pre-split.loopexit
  %.pr = phi i32* [ %.pr.pre, %while.body4 ], [ %1, %while.cond2thread-pre-split.loopexit ]
  br label %while.cond2

while.cond2.loopexit:                             ; preds = %while.cond, %while.cond
  br label %while.cond2

; CHECK-LABEL: while.cond2:
; CHECK: %{{.*}} = phi i32* [ %.pr.pre, %while.body4 ], [ %1, %land.rhs ], [ %1, %while.cond ], [ %1, %while.cond ]
while.cond2:                                      ; preds = %while.cond2.loopexit, %while.cond2thread-pre-split
  %3 = phi i32* [ %.pr, %while.cond2thread-pre-split ], [ %1, %while.cond2.loopexit ]
  %tobool3 = icmp eq i32* %3, null
  br i1 %tobool3, label %sw.epilog, label %while.body4

while.body4:                                      ; preds = %while.cond2
  tail call void bitcast (void (...)* @fn2 to void ()*)()
  %.pr.pre = load i32*, i32** @a, align 8
  br label %while.cond2thread-pre-split

sw.epilog:                                        ; preds = %while.cond2, %entry
  ret i32 undef
}


; This test that BFI/BPI is created without any assertion in isMergingEmptyBlockProfitable()
; in the case where empty blocks are removed before creating BFI/BPI.
define i32 @should_not_assert(i32 %i) local_unnamed_addr {
entry:
  %0 = load i32, i32* @b, align 4
  %cond = icmp eq i32 %0, 6
  br i1 %cond, label %while.cond.preheader, label %sw.epilog

while.cond.preheader:                             ; preds = %entry
  %1 = load i32*, i32** @a, align 8
  %magicptr = ptrtoint i32* %1 to i64
  %arrayidx = getelementptr inbounds i32, i32* %1, i64 1
  br label %while.cond

while.cond:                                       ; preds = %while.cond.preheader, %land.rhs
  switch i64 %magicptr, label %land.rhs [
    i64 32, label %while.cond2.loopexit
    i64 0, label %while.cond2.loopexit
  ]

land.rhs:                                         ; preds = %while.cond
  %2 = load i32, i32* %arrayidx, align 4
  %tobool1 = icmp eq i32 %2, 0
  br i1 %tobool1, label %while.cond2thread-pre-split.loopexit, label %while.cond

while.cond2thread-pre-split.loopexit:             ; preds = %land.rhs
  br label %while.cond2thread-pre-split

while.cond2thread-pre-split:                      ; preds = %while.cond2thread-pre-split.loopexit, %while.body4
  %.pr = phi i32* [ %.pr.pre, %while.body4 ], [ %1, %while.cond2thread-pre-split.loopexit ]
  br label %while.cond2

while.cond2.loopexit:                             ; preds = %while.cond, %while.cond
  br label %while.cond2

while.cond2:                                      ; preds = %while.cond2.loopexit, %while.cond2thread-pre-split
  %3 = phi i32* [ %.pr, %while.cond2thread-pre-split ], [ %1, %while.cond2.loopexit ]
  %tobool3 = icmp eq i32* %3, null
  br i1 %tobool3, label %sw.epilog, label %while.body4

while.body4:                                      ; preds = %while.cond2
  tail call void bitcast (void (...)* @fn2 to void ()*)()
  %.pr.pre = load i32*, i32** @a, align 8
  br label %while.cond2thread-pre-split

sw.epilog:                                        ; preds = %while.cond2, %entry
  ret i32 undef
}


declare void @fn2(...) local_unnamed_addr


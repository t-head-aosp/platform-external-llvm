; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc < %s -mtriple=x86_64-unknown-unknown | FileCheck %s

%structTy = type { i8, i32, i32 }

@e = common global %structTy zeroinitializer, align 4

;; Ensure that MergeConsecutiveStores doesn't incorrectly reorder
;; store operations.  The first test stores in increasing address
;; order, the second in decreasing -- but in both cases should have
;; the same result in memory in the end.

define void @redundant_stores_merging() {
; CHECK-LABEL: redundant_stores_merging:
; CHECK:       # BB#0:
; CHECK-NEXT:    movabsq $1958505086977, %rax # imm = 0x1C800000001
; CHECK-NEXT:    movq %rax, e+{{.*}}(%rip)
; CHECK-NEXT:    retq
  store i32 1, i32* getelementptr inbounds (%structTy, %structTy* @e, i64 0, i32 1), align 4
  store i32 123, i32* getelementptr inbounds (%structTy, %structTy* @e, i64 0, i32 2), align 4
  store i32 456, i32* getelementptr inbounds (%structTy, %structTy* @e, i64 0, i32 2), align 4
  ret void
}

;; This variant tests PR25154.
define void @redundant_stores_merging_reverse() {
; CHECK-LABEL: redundant_stores_merging_reverse:
; CHECK:       # BB#0:
; CHECK-NEXT:    movabsq $1958505086977, %rax # imm = 0x1C800000001
; CHECK-NEXT:    movq %rax, e+{{.*}}(%rip)
; CHECK-NEXT:    retq
  store i32 123, i32* getelementptr inbounds (%structTy, %structTy* @e, i64 0, i32 2), align 4
  store i32 456, i32* getelementptr inbounds (%structTy, %structTy* @e, i64 0, i32 2), align 4
  store i32 1, i32* getelementptr inbounds (%structTy, %structTy* @e, i64 0, i32 1), align 4
  ret void
}

@b = common global [8 x i8] zeroinitializer, align 2

;; The 2-byte store to offset 3 overlaps the 2-byte store to offset 2;
;; these must not be reordered in MergeConsecutiveStores such that the
;; store to 3 comes first (e.g. by merging the stores to 0 and 2 into
;; a movl, after the store to 3).

define void @overlapping_stores_merging() {
; CHECK-LABEL: overlapping_stores_merging:
; CHECK:       # BB#0:
; CHECK-NEXT:    movl $1, {{.*}}(%rip)
; CHECK-NEXT:    movw $2, b+{{.*}}(%rip)
; CHECK-NEXT:    retq
  store i16 0, i16* bitcast (i8* getelementptr inbounds ([8 x i8], [8 x i8]* @b, i64 0, i64 2) to i16*), align 2
  store i16 2, i16* bitcast (i8* getelementptr inbounds ([8 x i8], [8 x i8]* @b, i64 0, i64 3) to i16*), align 1
  store i16 1, i16* bitcast (i8* getelementptr inbounds ([8 x i8], [8 x i8]* @b, i64 0, i64 0) to i16*), align 2
  ret void
}

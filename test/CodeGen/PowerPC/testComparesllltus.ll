; RUN: llc -verify-machineinstrs -mtriple=powerpc64-unknown-linux-gnu -O2 \
; RUN:   -ppc-asm-full-reg-names -mcpu=pwr8 < %s | FileCheck %s \
; RUN:  --implicit-check-not cmpw --implicit-check-not cmpd --implicit-check-not cmpl
; RUN: llc -verify-machineinstrs -mtriple=powerpc64le-unknown-linux-gnu -O2 \
; RUN:   -ppc-asm-full-reg-names -mcpu=pwr8 < %s | FileCheck %s \
; RUN:  --implicit-check-not cmpw --implicit-check-not cmpd --implicit-check-not cmpl

@glob = common local_unnamed_addr global i16 0, align 2

; Function Attrs: norecurse nounwind readnone
define i64 @test_llltus(i16 zeroext %a, i16 zeroext %b) {
; CHECK-LABEL: test_llltus:
; CHECK:       # BB#0: # %entry
; CHECK-NEXT:    sub [[REG:r[0-9]+]], r3, r4
; CHECK-NEXT:    rldicl r3, [[REG]], 1, 63
; CHECK-NEXT:    blr
entry:
  %cmp = icmp ult i16 %a, %b
  %conv3 = zext i1 %cmp to i64
  ret i64 %conv3
}

; Function Attrs: norecurse nounwind readnone
define i64 @test_llltus_sext(i16 zeroext %a, i16 zeroext %b) {
; CHECK-LABEL: test_llltus_sext:
; CHECK:       # BB#0: # %entry
; CHECK-NEXT:    sub [[REG:r[0-9]+]], r3, r4
; CHECK-NEXT:    sradi r3, [[REG]], 63
; CHECK-NEXT:    blr
entry:
  %cmp = icmp ult i16 %a, %b
  %conv3 = sext i1 %cmp to i64
  ret i64 %conv3
}

; Function Attrs: norecurse nounwind
define void @test_llltus_store(i16 zeroext %a, i16 zeroext %b) {
; CHECK-LABEL: test_llltus_store:
; CHECK:         sub [[REG:r[2-9]+]], r3, r4
; CHECK:         rldicl {{r[0-9]+}}, [[REG]], 1, 63
entry:
  %cmp = icmp ult i16 %a, %b
  %conv3 = zext i1 %cmp to i16
  store i16 %conv3, i16* @glob, align 2
  ret void
}

; Function Attrs: norecurse nounwind
define void @test_llltus_sext_store(i16 zeroext %a, i16 zeroext %b) {
; CHECK-LABEL: test_llltus_sext_store:
; CHECK:       # BB#0: # %entry
; CHECK:         sub [[REG:r[0-9]+]], r3, r4
; CHECK:         sradi {{r[0-9]+}}, [[REG]], 63
entry:
  %cmp = icmp ult i16 %a, %b
  %conv3 = sext i1 %cmp to i16
  store i16 %conv3, i16* @glob, align 2
  ret void
}

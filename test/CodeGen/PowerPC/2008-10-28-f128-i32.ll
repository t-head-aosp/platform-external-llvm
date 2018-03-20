; RUN: llc -verify-machineinstrs < %s -mtriple=ppc32-- -o - | FileCheck %s

define i64 @__fixunstfdi(ppc_fp128 %a) nounwind readnone {
; CHECK-LABEL: __fixunstfdi:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    mflr 0
; CHECK-NEXT:    stw 0, 4(1)
; CHECK-NEXT:    stwu 1, -464(1)
; CHECK-NEXT:    lis 3, .LCPI0_0@ha
; CHECK-NEXT:    stfd 27, 424(1) # 8-byte Folded Spill
; CHECK-NEXT:    stw 29, 412(1) # 4-byte Folded Spill
; CHECK-NEXT:    stw 30, 416(1) # 4-byte Folded Spill
; CHECK-NEXT:    lfs 27, .LCPI0_0@l(3)
; CHECK-NEXT:    mfcr 12
; CHECK-NEXT:    stfd 28, 432(1) # 8-byte Folded Spill
; CHECK-NEXT:    stfd 29, 440(1) # 8-byte Folded Spill
; CHECK-NEXT:    stfd 30, 448(1) # 8-byte Folded Spill
; CHECK-NEXT:    stfd 31, 456(1) # 8-byte Folded Spill
; CHECK-NEXT:    stw 12, 408(1)
; CHECK-NEXT:    stfd 2, 376(1)
; CHECK-NEXT:    stfd 1, 384(1)
; CHECK-NEXT:    nop
; CHECK-NEXT:    fcmpu 0, 2, 27
; CHECK-NEXT:    lwz 3, 380(1)
; CHECK-NEXT:    lwz 4, 376(1)
; CHECK-NEXT:    lwz 5, 388(1)
; CHECK-NEXT:    lwz 6, 384(1)
; CHECK-NEXT:    fcmpu 1, 1, 27
; CHECK-NEXT:    crand 20, 6, 0
; CHECK-NEXT:    cror 20, 4, 20
; CHECK-NEXT:    stw 3, 396(1)
; CHECK-NEXT:    stw 4, 392(1)
; CHECK-NEXT:    stw 5, 404(1)
; CHECK-NEXT:    stw 6, 400(1)
; CHECK-NEXT:    bc 4, 20, .LBB0_2
; CHECK-NEXT:  # %bb.1: # %bb5
; CHECK-NEXT:    li 3, 0
; CHECK-NEXT:    li 4, 0
; CHECK-NEXT:    b .LBB0_16
; CHECK-NEXT:  .LBB0_2: # %bb1
; CHECK-NEXT:    lfd 0, 392(1)
; CHECK-NEXT:    lfd 1, 400(1)
; CHECK-NEXT:    li 29, 0
; CHECK-NEXT:    lis 3, 15856
; CHECK-NEXT:    stfd 1, 304(1)
; CHECK-NEXT:    stfd 0, 296(1)
; CHECK-NEXT:    nop
; CHECK-NEXT:    nop
; CHECK-NEXT:    lwz 4, 308(1)
; CHECK-NEXT:    lwz 5, 304(1)
; CHECK-NEXT:    lwz 6, 300(1)
; CHECK-NEXT:    lwz 7, 296(1)
; CHECK-NEXT:    stw 29, 340(1)
; CHECK-NEXT:    stw 3, 336(1)
; CHECK-NEXT:    stw 29, 332(1)
; CHECK-NEXT:    stw 29, 328(1)
; CHECK-NEXT:    stw 4, 324(1)
; CHECK-NEXT:    stw 5, 320(1)
; CHECK-NEXT:    stw 6, 316(1)
; CHECK-NEXT:    stw 7, 312(1)
; CHECK-NEXT:    nop
; CHECK-NEXT:    lfd 31, 320(1)
; CHECK-NEXT:    lfd 30, 312(1)
; CHECK-NEXT:    lfd 3, 336(1)
; CHECK-NEXT:    lfd 4, 328(1)
; CHECK-NEXT:    fmr 1, 31
; CHECK-NEXT:    fmr 2, 30
; CHECK-NEXT:    bl __gcc_qmul@PLT
; CHECK-NEXT:    stfd 1, 280(1)
; CHECK-NEXT:    stfd 2, 288(1)
; CHECK-NEXT:    lis 3, .LCPI0_1@ha
; CHECK-NEXT:    fmr 29, 1
; CHECK-NEXT:    fmr 28, 2
; CHECK-NEXT:    fcmpu 0, 2, 27
; CHECK-NEXT:    lwz 4, 284(1)
; CHECK-NEXT:    lwz 5, 280(1)
; CHECK-NEXT:    lwz 6, 292(1)
; CHECK-NEXT:    lwz 7, 288(1)
; CHECK-NEXT:    lfs 0, .LCPI0_1@l(3)
; CHECK-NEXT:    lis 3, 16864
; CHECK-NEXT:    stw 29, 372(1)
; CHECK-NEXT:    stw 3, 368(1)
; CHECK-NEXT:    stw 29, 364(1)
; CHECK-NEXT:    stw 29, 360(1)
; CHECK-NEXT:    stw 4, 356(1)
; CHECK-NEXT:    stw 5, 352(1)
; CHECK-NEXT:    stw 6, 348(1)
; CHECK-NEXT:    stw 7, 344(1)
; CHECK-NEXT:    fcmpu 1, 1, 0
; CHECK-NEXT:    lfd 3, 368(1)
; CHECK-NEXT:    lfd 4, 360(1)
; CHECK-NEXT:    lfd 1, 352(1)
; CHECK-NEXT:    lfd 2, 344(1)
; CHECK-NEXT:    crandc 20, 6, 0
; CHECK-NEXT:    cror 8, 5, 20
; CHECK-NEXT:    bl __gcc_qsub@PLT
; CHECK-NEXT:    mffs 0
; CHECK-NEXT:    mtfsb1 31
; CHECK-NEXT:    mtfsb0 30
; CHECK-NEXT:    fadd 1, 2, 1
; CHECK-NEXT:    mtfsf 1, 0
; CHECK-NEXT:    mffs 0
; CHECK-NEXT:    mtfsb1 31
; CHECK-NEXT:    mtfsb0 30
; CHECK-NEXT:    fadd 2, 28, 29
; CHECK-NEXT:    mtfsf 1, 0
; CHECK-NEXT:    fctiwz 0, 1
; CHECK-NEXT:    fctiwz 1, 2
; CHECK-NEXT:    stfd 0, 160(1)
; CHECK-NEXT:    stfd 1, 152(1)
; CHECK-NEXT:    nop
; CHECK-NEXT:    lwz 3, 164(1)
; CHECK-NEXT:    lwz 4, 156(1)
; CHECK-NEXT:    addis 3, 3, -32768
; CHECK-NEXT:    bc 12, 8, .LBB0_4
; CHECK-NEXT:  # %bb.3: # %bb1
; CHECK-NEXT:    ori 30, 4, 0
; CHECK-NEXT:    b .LBB0_5
; CHECK-NEXT:  .LBB0_4: # %bb1
; CHECK-NEXT:    addi 30, 3, 0
; CHECK-NEXT:  .LBB0_5: # %bb1
; CHECK-NEXT:    mr 3, 30
; CHECK-NEXT:    li 4, 0
; CHECK-NEXT:    bl __floatditf@PLT
; CHECK-NEXT:    stfd 1, 208(1)
; CHECK-NEXT:    stfd 2, 200(1)
; CHECK-NEXT:    lis 3, 17392
; CHECK-NEXT:    fmr 28, 1
; CHECK-NEXT:    fmr 29, 2
; CHECK-NEXT:    cmpwi 2, 30, 0
; CHECK-NEXT:    lwz 4, 212(1)
; CHECK-NEXT:    lwz 5, 208(1)
; CHECK-NEXT:    lwz 6, 204(1)
; CHECK-NEXT:    lwz 7, 200(1)
; CHECK-NEXT:    stw 29, 244(1)
; CHECK-NEXT:    stw 3, 240(1)
; CHECK-NEXT:    stw 29, 236(1)
; CHECK-NEXT:    stw 29, 232(1)
; CHECK-NEXT:    stw 4, 228(1)
; CHECK-NEXT:    stw 5, 224(1)
; CHECK-NEXT:    stw 6, 220(1)
; CHECK-NEXT:    stw 7, 216(1)
; CHECK-NEXT:    nop
; CHECK-NEXT:    lfd 3, 240(1)
; CHECK-NEXT:    lfd 4, 232(1)
; CHECK-NEXT:    lfd 1, 224(1)
; CHECK-NEXT:    lfd 2, 216(1)
; CHECK-NEXT:    bl __gcc_qadd@PLT
; CHECK-NEXT:    blt 2, .LBB0_7
; CHECK-NEXT:  # %bb.6: # %bb1
; CHECK-NEXT:    fmr 1, 28
; CHECK-NEXT:  .LBB0_7: # %bb1
; CHECK-NEXT:    stfd 1, 184(1)
; CHECK-NEXT:    blt 2, .LBB0_9
; CHECK-NEXT:  # %bb.8: # %bb1
; CHECK-NEXT:    fmr 2, 29
; CHECK-NEXT:  .LBB0_9: # %bb1
; CHECK-NEXT:    stfd 2, 192(1)
; CHECK-NEXT:    fmr 1, 31
; CHECK-NEXT:    fmr 2, 30
; CHECK-NEXT:    nop
; CHECK-NEXT:    nop
; CHECK-NEXT:    lwz 3, 188(1)
; CHECK-NEXT:    lwz 4, 184(1)
; CHECK-NEXT:    lwz 5, 196(1)
; CHECK-NEXT:    lwz 6, 192(1)
; CHECK-NEXT:    stw 3, 260(1)
; CHECK-NEXT:    stw 4, 256(1)
; CHECK-NEXT:    stw 5, 252(1)
; CHECK-NEXT:    stw 6, 248(1)
; CHECK-NEXT:    lfd 3, 256(1)
; CHECK-NEXT:    lfd 4, 248(1)
; CHECK-NEXT:    bl __gcc_qsub@PLT
; CHECK-NEXT:    stfd 2, 176(1)
; CHECK-NEXT:    stfd 1, 168(1)
; CHECK-NEXT:    fcmpu 1, 1, 27
; CHECK-NEXT:    fcmpu 0, 2, 27
; CHECK-NEXT:    lwz 3, 180(1)
; CHECK-NEXT:    lwz 4, 176(1)
; CHECK-NEXT:    lwz 5, 172(1)
; CHECK-NEXT:    lwz 6, 168(1)
; CHECK-NEXT:    crandc 20, 6, 0
; CHECK-NEXT:    cror 21, 5, 7
; CHECK-NEXT:    cror 20, 21, 20
; CHECK-NEXT:    stw 3, 268(1)
; CHECK-NEXT:    stw 4, 264(1)
; CHECK-NEXT:    stw 5, 276(1)
; CHECK-NEXT:    stw 6, 272(1)
; CHECK-NEXT:    lfd 30, 264(1)
; CHECK-NEXT:    lfd 31, 272(1)
; CHECK-NEXT:    bc 12, 20, .LBB0_13
; CHECK-NEXT:  # %bb.10: # %bb2
; CHECK-NEXT:    fneg 29, 31
; CHECK-NEXT:    fneg 28, 30
; CHECK-NEXT:    li 29, 0
; CHECK-NEXT:    lis 3, 16864
; CHECK-NEXT:    stfd 29, 48(1)
; CHECK-NEXT:    stfd 28, 40(1)
; CHECK-NEXT:    nop
; CHECK-NEXT:    lwz 4, 52(1)
; CHECK-NEXT:    lwz 5, 48(1)
; CHECK-NEXT:    lwz 6, 44(1)
; CHECK-NEXT:    lwz 7, 40(1)
; CHECK-NEXT:    stw 29, 84(1)
; CHECK-NEXT:    stw 3, 80(1)
; CHECK-NEXT:    stw 29, 76(1)
; CHECK-NEXT:    stw 29, 72(1)
; CHECK-NEXT:    stw 4, 68(1)
; CHECK-NEXT:    stw 5, 64(1)
; CHECK-NEXT:    stw 6, 60(1)
; CHECK-NEXT:    stw 7, 56(1)
; CHECK-NEXT:    nop
; CHECK-NEXT:    lfd 3, 80(1)
; CHECK-NEXT:    lfd 4, 72(1)
; CHECK-NEXT:    lfd 1, 64(1)
; CHECK-NEXT:    lfd 2, 56(1)
; CHECK-NEXT:    bl __gcc_qsub@PLT
; CHECK-NEXT:    lis 3, .LCPI0_2@ha
; CHECK-NEXT:    lis 4, .LCPI0_3@ha
; CHECK-NEXT:    lfs 0, .LCPI0_2@l(3)
; CHECK-NEXT:    mffs 11
; CHECK-NEXT:    mtfsb1 31
; CHECK-NEXT:    lfs 3, .LCPI0_3@l(4)
; CHECK-NEXT:    mtfsb0 30
; CHECK-NEXT:    fcmpu 0, 30, 0
; CHECK-NEXT:    fcmpu 1, 31, 3
; CHECK-NEXT:    fadd 1, 2, 1
; CHECK-NEXT:    crandc 20, 6, 1
; CHECK-NEXT:    mtfsf 1, 11
; CHECK-NEXT:    cror 20, 4, 20
; CHECK-NEXT:    mffs 0
; CHECK-NEXT:    mtfsb1 31
; CHECK-NEXT:    mtfsb0 30
; CHECK-NEXT:    fadd 12, 28, 29
; CHECK-NEXT:    mtfsf 1, 0
; CHECK-NEXT:    fctiwz 0, 1
; CHECK-NEXT:    fctiwz 13, 12
; CHECK-NEXT:    stfd 0, 32(1)
; CHECK-NEXT:    stfd 13, 24(1)
; CHECK-NEXT:    nop
; CHECK-NEXT:    lwz 3, 36(1)
; CHECK-NEXT:    lwz 4, 28(1)
; CHECK-NEXT:    addis 3, 3, -32768
; CHECK-NEXT:    bc 12, 20, .LBB0_12
; CHECK-NEXT:  # %bb.11: # %bb2
; CHECK-NEXT:    ori 3, 4, 0
; CHECK-NEXT:    b .LBB0_12
; CHECK-NEXT:  .LBB0_12: # %bb2
; CHECK-NEXT:    subfic 4, 3, 0
; CHECK-NEXT:    subfe 3, 29, 30
; CHECK-NEXT:    b .LBB0_16
; CHECK-NEXT:  .LBB0_13: # %bb3
; CHECK-NEXT:    stfd 31, 112(1)
; CHECK-NEXT:    stfd 30, 104(1)
; CHECK-NEXT:    li 3, 0
; CHECK-NEXT:    lis 4, 16864
; CHECK-NEXT:    lwz 5, 116(1)
; CHECK-NEXT:    lwz 6, 112(1)
; CHECK-NEXT:    lwz 7, 108(1)
; CHECK-NEXT:    lwz 8, 104(1)
; CHECK-NEXT:    stw 3, 148(1)
; CHECK-NEXT:    stw 4, 144(1)
; CHECK-NEXT:    stw 3, 140(1)
; CHECK-NEXT:    stw 3, 136(1)
; CHECK-NEXT:    stw 5, 132(1)
; CHECK-NEXT:    stw 6, 128(1)
; CHECK-NEXT:    stw 7, 124(1)
; CHECK-NEXT:    stw 8, 120(1)
; CHECK-NEXT:    nop
; CHECK-NEXT:    lfd 3, 144(1)
; CHECK-NEXT:    lfd 4, 136(1)
; CHECK-NEXT:    lfd 1, 128(1)
; CHECK-NEXT:    lfd 2, 120(1)
; CHECK-NEXT:    bl __gcc_qsub@PLT
; CHECK-NEXT:    lis 3, .LCPI0_0@ha
; CHECK-NEXT:    lis 4, .LCPI0_1@ha
; CHECK-NEXT:    lfs 0, .LCPI0_0@l(3)
; CHECK-NEXT:    mffs 11
; CHECK-NEXT:    mtfsb1 31
; CHECK-NEXT:    lfs 3, .LCPI0_1@l(4)
; CHECK-NEXT:    mtfsb0 30
; CHECK-NEXT:    fcmpu 0, 30, 0
; CHECK-NEXT:    fcmpu 1, 31, 3
; CHECK-NEXT:    fadd 1, 2, 1
; CHECK-NEXT:    crandc 20, 6, 0
; CHECK-NEXT:    mtfsf 1, 11
; CHECK-NEXT:    cror 20, 5, 20
; CHECK-NEXT:    mffs 0
; CHECK-NEXT:    mtfsb1 31
; CHECK-NEXT:    mtfsb0 30
; CHECK-NEXT:    fadd 12, 30, 31
; CHECK-NEXT:    mtfsf 1, 0
; CHECK-NEXT:    fctiwz 0, 1
; CHECK-NEXT:    fctiwz 13, 12
; CHECK-NEXT:    stfd 0, 96(1)
; CHECK-NEXT:    stfd 13, 88(1)
; CHECK-NEXT:    nop
; CHECK-NEXT:    lwz 3, 100(1)
; CHECK-NEXT:    lwz 4, 92(1)
; CHECK-NEXT:    addis 3, 3, -32768
; CHECK-NEXT:    bc 12, 20, .LBB0_14
; CHECK-NEXT:    b .LBB0_15
; CHECK-NEXT:  .LBB0_14: # %bb3
; CHECK-NEXT:    addi 4, 3, 0
; CHECK-NEXT:  .LBB0_15: # %bb3
; CHECK-NEXT:    mr 3, 30
; CHECK-NEXT:  .LBB0_16: # %bb5
; CHECK-NEXT:    lwz 12, 408(1)
; CHECK-NEXT:    lfd 31, 456(1) # 8-byte Folded Reload
; CHECK-NEXT:    lfd 30, 448(1) # 8-byte Folded Reload
; CHECK-NEXT:    lfd 29, 440(1) # 8-byte Folded Reload
; CHECK-NEXT:    lfd 28, 432(1) # 8-byte Folded Reload
; CHECK-NEXT:    lfd 27, 424(1) # 8-byte Folded Reload
; CHECK-NEXT:    lwz 30, 416(1) # 4-byte Folded Reload
; CHECK-NEXT:    lwz 29, 412(1) # 4-byte Folded Reload
; CHECK-NEXT:    lwz 0, 468(1)
; CHECK-NEXT:    mtcrf 32, 12 # cr2
; CHECK-NEXT:    addi 1, 1, 464
; CHECK-NEXT:    mtlr 0
; CHECK-NEXT:    blr
entry:
	%0 = fcmp olt ppc_fp128 %a, 0xM00000000000000000000000000000000		; <i1> [#uses=1]
	br i1 %0, label %bb5, label %bb1

bb1:		; preds = %entry
	%1 = fmul ppc_fp128 %a, 0xM3DF00000000000000000000000000000		; <ppc_fp128> [#uses=1]
	%2 = fptoui ppc_fp128 %1 to i32		; <i32> [#uses=1]
	%3 = zext i32 %2 to i64		; <i64> [#uses=1]
	%4 = shl i64 %3, 32		; <i64> [#uses=3]
	%5 = uitofp i64 %4 to ppc_fp128		; <ppc_fp128> [#uses=1]
	%6 = fsub ppc_fp128 %a, %5		; <ppc_fp128> [#uses=3]
	%7 = fcmp olt ppc_fp128 %6, 0xM00000000000000000000000000000000		; <i1> [#uses=1]
	br i1 %7, label %bb2, label %bb3

bb2:		; preds = %bb1
	%8 = fsub ppc_fp128 0xM80000000000000000000000000000000, %6		; <ppc_fp128> [#uses=1]
	%9 = fptoui ppc_fp128 %8 to i32		; <i32> [#uses=1]
	%10 = zext i32 %9 to i64		; <i64> [#uses=1]
	%11 = sub i64 %4, %10		; <i64> [#uses=1]
	ret i64 %11

bb3:		; preds = %bb1
	%12 = fptoui ppc_fp128 %6 to i32		; <i32> [#uses=1]
	%13 = zext i32 %12 to i64		; <i64> [#uses=1]
	%14 = or i64 %13, %4		; <i64> [#uses=1]
	ret i64 %14

bb5:		; preds = %entry
	ret i64 0
}

//===- X86InstructionSelector.cpp ----------------------------*- C++ -*-==//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
/// \file
/// This file implements the targeting of the InstructionSelector class for
/// X86.
/// \todo This should be generated by TableGen.
//===----------------------------------------------------------------------===//

#include "X86InstrBuilder.h"
#include "X86InstrInfo.h"
#include "X86RegisterBankInfo.h"
#include "X86RegisterInfo.h"
#include "X86Subtarget.h"
#include "X86TargetMachine.h"
#include "llvm/CodeGen/GlobalISel/InstructionSelector.h"
#include "llvm/CodeGen/MachineBasicBlock.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineInstr.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineOperand.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/IR/Type.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/raw_ostream.h"

#define DEBUG_TYPE "X86-isel"

using namespace llvm;

#ifndef LLVM_BUILD_GLOBAL_ISEL
#error "You shouldn't build this"
#endif

namespace {

#define GET_GLOBALISEL_PREDICATE_BITSET
#include "X86GenGlobalISel.inc"
#undef GET_GLOBALISEL_PREDICATE_BITSET

class X86InstructionSelector : public InstructionSelector {
public:
  X86InstructionSelector(const X86TargetMachine &TM, const X86Subtarget &STI,
                         const X86RegisterBankInfo &RBI);

  bool select(MachineInstr &I) const override;

private:
  /// tblgen-erated 'select' implementation, used as the initial selector for
  /// the patterns that don't require complex C++.
  bool selectImpl(MachineInstr &I) const;

  // TODO: remove after selectImpl support pattern with a predicate.
  unsigned getFAddOp(LLT &Ty, const RegisterBank &RB) const;
  unsigned getFSubOp(LLT &Ty, const RegisterBank &RB) const;
  unsigned getAddOp(LLT &Ty, const RegisterBank &RB) const;
  unsigned getSubOp(LLT &Ty, const RegisterBank &RB) const;
  unsigned getLoadStoreOp(LLT &Ty, const RegisterBank &RB, unsigned Opc,
                          uint64_t Alignment) const;

  bool selectBinaryOp(MachineInstr &I, MachineRegisterInfo &MRI,
                      MachineFunction &MF) const;
  bool selectLoadStoreOp(MachineInstr &I, MachineRegisterInfo &MRI,
                         MachineFunction &MF) const;
  bool selectFrameIndex(MachineInstr &I, MachineRegisterInfo &MRI,
                        MachineFunction &MF) const;
  bool selectConstant(MachineInstr &I, MachineRegisterInfo &MRI,
                      MachineFunction &MF) const;
  bool selectTrunc(MachineInstr &I, MachineRegisterInfo &MRI,
                   MachineFunction &MF) const;

  const X86TargetMachine &TM;
  const X86Subtarget &STI;
  const X86InstrInfo &TII;
  const X86RegisterInfo &TRI;
  const X86RegisterBankInfo &RBI;

#define GET_GLOBALISEL_PREDICATES_DECL
#include "X86GenGlobalISel.inc"
#undef GET_GLOBALISEL_PREDICATES_DECL

#define GET_GLOBALISEL_TEMPORARIES_DECL
#include "X86GenGlobalISel.inc"
#undef GET_GLOBALISEL_TEMPORARIES_DECL
};

} // end anonymous namespace

#define GET_GLOBALISEL_IMPL
#include "X86GenGlobalISel.inc"
#undef GET_GLOBALISEL_IMPL

X86InstructionSelector::X86InstructionSelector(const X86TargetMachine &TM,
                                               const X86Subtarget &STI,
                                               const X86RegisterBankInfo &RBI)
    : InstructionSelector(), TM(TM), STI(STI), TII(*STI.getInstrInfo()),
      TRI(*STI.getRegisterInfo()), RBI(RBI),
#define GET_GLOBALISEL_PREDICATES_INIT
#include "X86GenGlobalISel.inc"
#undef GET_GLOBALISEL_PREDICATES_INIT
#define GET_GLOBALISEL_TEMPORARIES_INIT
#include "X86GenGlobalISel.inc"
#undef GET_GLOBALISEL_TEMPORARIES_INIT
{
}

// FIXME: This should be target-independent, inferred from the types declared
// for each class in the bank.
static const TargetRegisterClass *
getRegClassForTypeOnBank(LLT Ty, const RegisterBank &RB) {
  if (RB.getID() == X86::GPRRegBankID) {
    if (Ty.getSizeInBits() <= 8)
      return &X86::GR8RegClass;
    if (Ty.getSizeInBits() == 16)
      return &X86::GR16RegClass;
    if (Ty.getSizeInBits() == 32)
      return &X86::GR32RegClass;
    if (Ty.getSizeInBits() == 64)
      return &X86::GR64RegClass;
  }
  if (RB.getID() == X86::VECRRegBankID) {
    if (Ty.getSizeInBits() == 32)
      return &X86::FR32XRegClass;
    if (Ty.getSizeInBits() == 64)
      return &X86::FR64XRegClass;
    if (Ty.getSizeInBits() == 128)
      return &X86::VR128XRegClass;
    if (Ty.getSizeInBits() == 256)
      return &X86::VR256XRegClass;
    if (Ty.getSizeInBits() == 512)
      return &X86::VR512RegClass;
  }

  llvm_unreachable("Unknown RegBank!");
}

// Set X86 Opcode and constrain DestReg.
static bool selectCopy(MachineInstr &I, const TargetInstrInfo &TII,
                       MachineRegisterInfo &MRI, const TargetRegisterInfo &TRI,
                       const RegisterBankInfo &RBI) {

  unsigned DstReg = I.getOperand(0).getReg();
  if (TargetRegisterInfo::isPhysicalRegister(DstReg)) {
    assert(I.isCopy() && "Generic operators do not allow physical registers");
    return true;
  }

  const RegisterBank &RegBank = *RBI.getRegBank(DstReg, MRI, TRI);
  const unsigned DstSize = MRI.getType(DstReg).getSizeInBits();
  unsigned SrcReg = I.getOperand(1).getReg();
  const unsigned SrcSize = RBI.getSizeInBits(SrcReg, MRI, TRI);

  assert((!TargetRegisterInfo::isPhysicalRegister(SrcReg) || I.isCopy()) &&
         "No phys reg on generic operators");
  assert((DstSize == SrcSize ||
          // Copies are a mean to setup initial types, the number of
          // bits may not exactly match.
          (TargetRegisterInfo::isPhysicalRegister(SrcReg) &&
           DstSize <= RBI.getSizeInBits(SrcReg, MRI, TRI))) &&
         "Copy with different width?!");

  const TargetRegisterClass *RC = nullptr;

  switch (RegBank.getID()) {
  case X86::GPRRegBankID:
    assert((DstSize <= 64) && "GPRs cannot get more than 64-bit width values.");
    RC = getRegClassForTypeOnBank(MRI.getType(DstReg), RegBank);

    // Change the physical register
    if (SrcSize > DstSize && TargetRegisterInfo::isPhysicalRegister(SrcReg)) {
      if (RC == &X86::GR32RegClass)
        I.getOperand(1).setSubReg(X86::sub_32bit);
      else if (RC == &X86::GR16RegClass)
        I.getOperand(1).setSubReg(X86::sub_16bit);
      else if (RC == &X86::GR8RegClass)
        I.getOperand(1).setSubReg(X86::sub_8bit);

      I.getOperand(1).substPhysReg(SrcReg, TRI);
    }
    break;
  case X86::VECRRegBankID:
    RC = getRegClassForTypeOnBank(MRI.getType(DstReg), RegBank);
    break;
  default:
    llvm_unreachable("Unknown RegBank!");
  }

  // No need to constrain SrcReg. It will get constrained when
  // we hit another of its use or its defs.
  // Copies do not have constraints.
  const TargetRegisterClass *OldRC = MRI.getRegClassOrNull(DstReg);
  if (!OldRC || !RC->hasSubClassEq(OldRC)) {
    if (!RBI.constrainGenericRegister(DstReg, *RC, MRI)) {
      DEBUG(dbgs() << "Failed to constrain " << TII.getName(I.getOpcode())
                   << " operand\n");
      return false;
    }
  }
  I.setDesc(TII.get(X86::COPY));
  return true;
}

bool X86InstructionSelector::select(MachineInstr &I) const {
  assert(I.getParent() && "Instruction should be in a basic block!");
  assert(I.getParent()->getParent() && "Instruction should be in a function!");

  MachineBasicBlock &MBB = *I.getParent();
  MachineFunction &MF = *MBB.getParent();
  MachineRegisterInfo &MRI = MF.getRegInfo();

  unsigned Opcode = I.getOpcode();
  if (!isPreISelGenericOpcode(Opcode)) {
    // Certain non-generic instructions also need some special handling.

    if (I.isCopy())
      return selectCopy(I, TII, MRI, TRI, RBI);

    // TODO: handle more cases - LOAD_STACK_GUARD, PHI
    return true;
  }

  assert(I.getNumOperands() == I.getNumExplicitOperands() &&
         "Generic instruction has unexpected implicit operands\n");

  // TODO: This should be implemented by tblgen, pattern with predicate not
  // supported yet.
  if (selectBinaryOp(I, MRI, MF))
    return true;
  if (selectLoadStoreOp(I, MRI, MF))
    return true;
  if (selectFrameIndex(I, MRI, MF))
    return true;
  if (selectConstant(I, MRI, MF))
    return true;
  if (selectTrunc(I, MRI, MF))
    return true;

  return selectImpl(I);
}

unsigned X86InstructionSelector::getFAddOp(LLT &Ty,
                                           const RegisterBank &RB) const {

  if (X86::VECRRegBankID != RB.getID())
    return TargetOpcode::G_FADD;

  if (Ty == LLT::scalar(32)) {
    if (STI.hasAVX512()) {
      return X86::VADDSSZrr;
    } else if (STI.hasAVX()) {
      return X86::VADDSSrr;
    } else if (STI.hasSSE1()) {
      return X86::ADDSSrr;
    }
  } else if (Ty == LLT::scalar(64)) {
    if (STI.hasAVX512()) {
      return X86::VADDSDZrr;
    } else if (STI.hasAVX()) {
      return X86::VADDSDrr;
    } else if (STI.hasSSE2()) {
      return X86::ADDSDrr;
    }
  } else if (Ty == LLT::vector(4, 32)) {
    if ((STI.hasAVX512()) && (STI.hasVLX())) {
      return X86::VADDPSZ128rr;
    } else if (STI.hasAVX()) {
      return X86::VADDPSrr;
    } else if (STI.hasSSE1()) {
      return X86::ADDPSrr;
    }
  }

  return TargetOpcode::G_FADD;
}

unsigned X86InstructionSelector::getFSubOp(LLT &Ty,
                                           const RegisterBank &RB) const {

  if (X86::VECRRegBankID != RB.getID())
    return TargetOpcode::G_FSUB;

  if (Ty == LLT::scalar(32)) {
    if (STI.hasAVX512()) {
      return X86::VSUBSSZrr;
    } else if (STI.hasAVX()) {
      return X86::VSUBSSrr;
    } else if (STI.hasSSE1()) {
      return X86::SUBSSrr;
    }
  } else if (Ty == LLT::scalar(64)) {
    if (STI.hasAVX512()) {
      return X86::VSUBSDZrr;
    } else if (STI.hasAVX()) {
      return X86::VSUBSDrr;
    } else if (STI.hasSSE2()) {
      return X86::SUBSDrr;
    }
  } else if (Ty == LLT::vector(4, 32)) {
    if ((STI.hasAVX512()) && (STI.hasVLX())) {
      return X86::VSUBPSZ128rr;
    } else if (STI.hasAVX()) {
      return X86::VSUBPSrr;
    } else if (STI.hasSSE1()) {
      return X86::SUBPSrr;
    }
  }

  return TargetOpcode::G_FSUB;
}

unsigned X86InstructionSelector::getAddOp(LLT &Ty,
                                          const RegisterBank &RB) const {

  if (X86::VECRRegBankID != RB.getID())
    return TargetOpcode::G_ADD;

  if (Ty == LLT::vector(4, 32)) {
    if (STI.hasAVX512() && STI.hasVLX()) {
      return X86::VPADDDZ128rr;
    } else if (STI.hasAVX()) {
      return X86::VPADDDrr;
    } else if (STI.hasSSE2()) {
      return X86::PADDDrr;
    }
  }

  return TargetOpcode::G_ADD;
}

unsigned X86InstructionSelector::getSubOp(LLT &Ty,
                                          const RegisterBank &RB) const {

  if (X86::VECRRegBankID != RB.getID())
    return TargetOpcode::G_SUB;

  if (Ty == LLT::vector(4, 32)) {
    if (STI.hasAVX512() && STI.hasVLX()) {
      return X86::VPSUBDZ128rr;
    } else if (STI.hasAVX()) {
      return X86::VPSUBDrr;
    } else if (STI.hasSSE2()) {
      return X86::PSUBDrr;
    }
  }

  return TargetOpcode::G_SUB;
}

bool X86InstructionSelector::selectBinaryOp(MachineInstr &I,
                                            MachineRegisterInfo &MRI,
                                            MachineFunction &MF) const {

  const unsigned DefReg = I.getOperand(0).getReg();
  LLT Ty = MRI.getType(DefReg);
  const RegisterBank &RB = *RBI.getRegBank(DefReg, MRI, TRI);

  unsigned NewOpc = I.getOpcode();

  switch (NewOpc) {
  case TargetOpcode::G_FADD:
    NewOpc = getFAddOp(Ty, RB);
    break;
  case TargetOpcode::G_FSUB:
    NewOpc = getFSubOp(Ty, RB);
    break;
  case TargetOpcode::G_ADD:
    NewOpc = getAddOp(Ty, RB);
    break;
  case TargetOpcode::G_SUB:
    NewOpc = getSubOp(Ty, RB);
    break;
  default:
    break;
  }

  if (NewOpc == I.getOpcode())
    return false;

  I.setDesc(TII.get(NewOpc));

  return constrainSelectedInstRegOperands(I, TII, TRI, RBI);
}

unsigned X86InstructionSelector::getLoadStoreOp(LLT &Ty, const RegisterBank &RB,
                                                unsigned Opc,
                                                uint64_t Alignment) const {
  bool Isload = (Opc == TargetOpcode::G_LOAD);
  bool HasAVX = STI.hasAVX();
  bool HasAVX512 = STI.hasAVX512();
  bool HasVLX = STI.hasVLX();

  if (Ty == LLT::scalar(8)) {
    if (X86::GPRRegBankID == RB.getID())
      return Isload ? X86::MOV8rm : X86::MOV8mr;
  } else if (Ty == LLT::scalar(16)) {
    if (X86::GPRRegBankID == RB.getID())
      return Isload ? X86::MOV16rm : X86::MOV16mr;
  } else if (Ty == LLT::scalar(32) || Ty == LLT::pointer(0, 32)) {
    if (X86::GPRRegBankID == RB.getID())
      return Isload ? X86::MOV32rm : X86::MOV32mr;
    if (X86::VECRRegBankID == RB.getID())
      return Isload ? (HasAVX512 ? X86::VMOVSSZrm
                                 : HasAVX ? X86::VMOVSSrm : X86::MOVSSrm)
                    : (HasAVX512 ? X86::VMOVSSZmr
                                 : HasAVX ? X86::VMOVSSmr : X86::MOVSSmr);
  } else if (Ty == LLT::scalar(64) || Ty == LLT::pointer(0, 64)) {
    if (X86::GPRRegBankID == RB.getID())
      return Isload ? X86::MOV64rm : X86::MOV64mr;
    if (X86::VECRRegBankID == RB.getID())
      return Isload ? (HasAVX512 ? X86::VMOVSDZrm
                                 : HasAVX ? X86::VMOVSDrm : X86::MOVSDrm)
                    : (HasAVX512 ? X86::VMOVSDZmr
                                 : HasAVX ? X86::VMOVSDmr : X86::MOVSDmr);
  } else if (Ty.isVector() && Ty.getSizeInBits() == 128) {
    if (Alignment >= 16)
      return Isload ? (HasVLX ? X86::VMOVAPSZ128rm
                              : HasAVX512
                                    ? X86::VMOVAPSZ128rm_NOVLX
                                    : HasAVX ? X86::VMOVAPSrm : X86::MOVAPSrm)
                    : (HasVLX ? X86::VMOVAPSZ128mr
                              : HasAVX512
                                    ? X86::VMOVAPSZ128mr_NOVLX
                                    : HasAVX ? X86::VMOVAPSmr : X86::MOVAPSmr);
    else
      return Isload ? (HasVLX ? X86::VMOVUPSZ128rm
                              : HasAVX512
                                    ? X86::VMOVUPSZ128rm_NOVLX
                                    : HasAVX ? X86::VMOVUPSrm : X86::MOVUPSrm)
                    : (HasVLX ? X86::VMOVUPSZ128mr
                              : HasAVX512
                                    ? X86::VMOVUPSZ128mr_NOVLX
                                    : HasAVX ? X86::VMOVUPSmr : X86::MOVUPSmr);
  }
  return Opc;
}

bool X86InstructionSelector::selectLoadStoreOp(MachineInstr &I,
                                               MachineRegisterInfo &MRI,
                                               MachineFunction &MF) const {

  unsigned Opc = I.getOpcode();

  if (Opc != TargetOpcode::G_STORE && Opc != TargetOpcode::G_LOAD)
    return false;

  const unsigned DefReg = I.getOperand(0).getReg();
  LLT Ty = MRI.getType(DefReg);
  const RegisterBank &RB = *RBI.getRegBank(DefReg, MRI, TRI);

  auto &MemOp = **I.memoperands_begin();
  unsigned NewOpc = getLoadStoreOp(Ty, RB, Opc, MemOp.getAlignment());
  if (NewOpc == Opc)
    return false;

  I.setDesc(TII.get(NewOpc));
  MachineInstrBuilder MIB(MF, I);
  if (Opc == TargetOpcode::G_LOAD)
    addOffset(MIB, 0);
  else {
    // G_STORE (VAL, Addr), X86Store instruction (Addr, VAL)
    I.RemoveOperand(0);
    addOffset(MIB, 0).addUse(DefReg);
  }
  return constrainSelectedInstRegOperands(I, TII, TRI, RBI);
}

bool X86InstructionSelector::selectFrameIndex(MachineInstr &I,
                                              MachineRegisterInfo &MRI,
                                              MachineFunction &MF) const {
  if (I.getOpcode() != TargetOpcode::G_FRAME_INDEX)
    return false;

  const unsigned DefReg = I.getOperand(0).getReg();
  LLT Ty = MRI.getType(DefReg);

  // Use LEA to calculate frame index.
  unsigned NewOpc;
  if (Ty == LLT::pointer(0, 64))
    NewOpc = X86::LEA64r;
  else if (Ty == LLT::pointer(0, 32))
    NewOpc = STI.isTarget64BitILP32() ? X86::LEA64_32r : X86::LEA32r;
  else
    llvm_unreachable("Can't select G_FRAME_INDEX, unsupported type.");

  I.setDesc(TII.get(NewOpc));
  MachineInstrBuilder MIB(MF, I);
  addOffset(MIB, 0);

  return constrainSelectedInstRegOperands(I, TII, TRI, RBI);
}

bool X86InstructionSelector::selectConstant(MachineInstr &I,
                                            MachineRegisterInfo &MRI,
                                            MachineFunction &MF) const {
  if (I.getOpcode() != TargetOpcode::G_CONSTANT)
    return false;

  const unsigned DefReg = I.getOperand(0).getReg();
  LLT Ty = MRI.getType(DefReg);

  assert(Ty.isScalar() && "invalid element type.");

  uint64_t Val = 0;
  if (I.getOperand(1).isCImm()) {
    Val = I.getOperand(1).getCImm()->getZExtValue();
    I.getOperand(1).ChangeToImmediate(Val);
  } else if (I.getOperand(1).isImm()) {
    Val = I.getOperand(1).getImm();
  } else
    llvm_unreachable("Unsupported operand type.");

  unsigned NewOpc;
  switch (Ty.getSizeInBits()) {
  case 8:
    NewOpc = X86::MOV8ri;
    break;
  case 16:
    NewOpc = X86::MOV16ri;
    break;
  case 32:
    NewOpc = X86::MOV32ri;
    break;
  case 64: {
    // TODO: in case isUInt<32>(Val), X86::MOV32ri can be used
    if (isInt<32>(Val))
      NewOpc = X86::MOV64ri32;
    else
      NewOpc = X86::MOV64ri;
    break;
  }
  default:
    llvm_unreachable("Can't select G_CONSTANT, unsupported type.");
  }

  I.setDesc(TII.get(NewOpc));
  return constrainSelectedInstRegOperands(I, TII, TRI, RBI);
}

bool X86InstructionSelector::selectTrunc(MachineInstr &I,
                                         MachineRegisterInfo &MRI,
                                         MachineFunction &MF) const {
  if (I.getOpcode() != TargetOpcode::G_TRUNC)
    return false;

  const unsigned DstReg = I.getOperand(0).getReg();
  const unsigned SrcReg = I.getOperand(1).getReg();

  const LLT DstTy = MRI.getType(DstReg);
  const LLT SrcTy = MRI.getType(SrcReg);

  const RegisterBank &DstRB = *RBI.getRegBank(DstReg, MRI, TRI);
  const RegisterBank &SrcRB = *RBI.getRegBank(SrcReg, MRI, TRI);

  if (DstRB.getID() != SrcRB.getID()) {
    DEBUG(dbgs() << "G_TRUNC input/output on different banks\n");
    return false;
  }

  if (DstRB.getID() != X86::GPRRegBankID)
    return false;

  const TargetRegisterClass *DstRC = getRegClassForTypeOnBank(DstTy, DstRB);
  if (!DstRC)
    return false;

  const TargetRegisterClass *SrcRC = getRegClassForTypeOnBank(SrcTy, SrcRB);
  if (!SrcRC)
    return false;

  if (!RBI.constrainGenericRegister(SrcReg, *SrcRC, MRI) ||
      !RBI.constrainGenericRegister(DstReg, *DstRC, MRI)) {
    DEBUG(dbgs() << "Failed to constrain G_TRUNC\n");
    return false;
  }

  if (DstRC == SrcRC) {
    // Nothing to be done
  } else if (DstRC == &X86::GR32RegClass) {
    I.getOperand(1).setSubReg(X86::sub_32bit);
  } else if (DstRC == &X86::GR16RegClass) {
    I.getOperand(1).setSubReg(X86::sub_16bit);
  } else if (DstRC == &X86::GR8RegClass) {
    I.getOperand(1).setSubReg(X86::sub_8bit);
  } else {
    return false;
  }

  I.setDesc(TII.get(X86::COPY));
  return true;
}

InstructionSelector *
llvm::createX86InstructionSelector(const X86TargetMachine &TM,
                                   X86Subtarget &Subtarget,
                                   X86RegisterBankInfo &RBI) {
  return new X86InstructionSelector(TM, Subtarget, RBI);
}

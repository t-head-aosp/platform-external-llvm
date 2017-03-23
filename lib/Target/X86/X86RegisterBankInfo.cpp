//===- X86RegisterBankInfo.cpp -----------------------------------*- C++ -*-==//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
/// \file
/// This file implements the targeting of the RegisterBankInfo class for X86.
/// \todo This should be generated by TableGen.
//===----------------------------------------------------------------------===//

#include "X86RegisterBankInfo.h"
#include "X86InstrInfo.h"
#include "llvm/CodeGen/GlobalISel/RegisterBank.h"
#include "llvm/CodeGen/GlobalISel/RegisterBankInfo.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/Target/TargetRegisterInfo.h"

#define GET_TARGET_REGBANK_IMPL
#include "X86GenRegisterBank.inc"

using namespace llvm;
// This file will be TableGen'ed at some point.
#define GET_TARGET_REGBANK_INFO_IMPL
#include "X86GenRegisterBankInfo.def"

#ifndef LLVM_BUILD_GLOBAL_ISEL
#error "You shouldn't build this"
#endif

X86RegisterBankInfo::X86RegisterBankInfo(const TargetRegisterInfo &TRI)
    : X86GenRegisterBankInfo() {

  // validate RegBank initialization.
  const RegisterBank &RBGPR = getRegBank(X86::GPRRegBankID);
  (void)RBGPR;
  assert(&X86::GPRRegBank == &RBGPR && "Incorrect RegBanks inizalization.");

  // The GPR register bank is fully defined by all the registers in
  // GR64 + its subclasses.
  assert(RBGPR.covers(*TRI.getRegClass(X86::GR64RegClassID)) &&
         "Subclass not added?");
  assert(RBGPR.getSize() == 64 && "GPRs should hold up to 64-bit");
}

const RegisterBank &X86RegisterBankInfo::getRegBankFromRegClass(
    const TargetRegisterClass &RC) const {

  if (X86::GR8RegClass.hasSubClassEq(&RC) ||
      X86::GR16RegClass.hasSubClassEq(&RC) ||
      X86::GR32RegClass.hasSubClassEq(&RC) ||
      X86::GR64RegClass.hasSubClassEq(&RC))
    return getRegBank(X86::GPRRegBankID);

  if (X86::FR32XRegClass.hasSubClassEq(&RC) ||
      X86::FR64XRegClass.hasSubClassEq(&RC) ||
      X86::VR128XRegClass.hasSubClassEq(&RC) ||
      X86::VR256XRegClass.hasSubClassEq(&RC) ||
      X86::VR512RegClass.hasSubClassEq(&RC))
    return getRegBank(X86::VECRRegBankID);

  llvm_unreachable("Unsupported register kind yet.");
}

X86GenRegisterBankInfo::PartialMappingIdx
X86GenRegisterBankInfo::getPartialMappingIdx(const LLT &Ty, bool isFP) {
  if ((Ty.isScalar() && !isFP) || Ty.isPointer()) {
    switch (Ty.getSizeInBits()) {
    case 8:
      return PMI_GPR8;
    case 16:
      return PMI_GPR16;
    case 32:
      return PMI_GPR32;
    case 64:
      return PMI_GPR64;
      break;
    default:
      llvm_unreachable("Unsupported register size.");
    }
  } else if (Ty.isScalar()) {
    switch (Ty.getSizeInBits()) {
    case 32:
      return PMI_FP32;
    case 64:
      return PMI_FP64;
    default:
      llvm_unreachable("Unsupported register size.");
    }
  } else {
    switch (Ty.getSizeInBits()) {
    case 128:
      return PMI_VEC128;
    case 256:
      return PMI_VEC256;
    case 512:
      return PMI_VEC512;
    default:
      llvm_unreachable("Unsupported register size.");
    }
  }

  return PMI_None;
}

RegisterBankInfo::InstructionMapping
X86RegisterBankInfo::getSameOperandsMapping(const MachineInstr &MI, bool isFP) {
  const MachineFunction &MF = *MI.getParent()->getParent();
  const MachineRegisterInfo &MRI = MF.getRegInfo();

  unsigned NumOperands = MI.getNumOperands();
  LLT Ty = MRI.getType(MI.getOperand(0).getReg());

  if (NumOperands != 3 || (Ty != MRI.getType(MI.getOperand(1).getReg())) ||
      (Ty != MRI.getType(MI.getOperand(2).getReg())))
    llvm_unreachable("Unsupported operand mapping yet.");

  auto Mapping = getValueMapping(getPartialMappingIdx(Ty, isFP), 3);
  return InstructionMapping{DefaultMappingID, 1, Mapping, NumOperands};
}

RegisterBankInfo::InstructionMapping
X86RegisterBankInfo::getInstrMapping(const MachineInstr &MI) const {
  const MachineFunction &MF = *MI.getParent()->getParent();
  const MachineRegisterInfo &MRI = MF.getRegInfo();
  auto Opc = MI.getOpcode();

  // Try the default logic for non-generic instructions that are either copies
  // or already have some operands assigned to banks.
  if (!isPreISelGenericOpcode(Opc)) {
    InstructionMapping Mapping = getInstrMappingImpl(MI);
    if (Mapping.isValid())
      return Mapping;
  }

  switch (Opc) {
  case TargetOpcode::G_ADD:
  case TargetOpcode::G_SUB:
    return getSameOperandsMapping(MI, false);
    break;
  case TargetOpcode::G_FADD:
  case TargetOpcode::G_FSUB:
  case TargetOpcode::G_FMUL:
  case TargetOpcode::G_FDIV:
    return getSameOperandsMapping(MI, true);
    break;
  default:
    break;
  }

  unsigned NumOperands = MI.getNumOperands();
  unsigned Cost = 1; // set dafault cost

  // Track the bank of each register.
  SmallVector<PartialMappingIdx, 4> OpRegBankIdx(NumOperands);
  for (unsigned Idx = 0; Idx < NumOperands; ++Idx) {
    auto &MO = MI.getOperand(Idx);
    if (!MO.isReg())
      continue;

    // As a top-level guess, use NotFP mapping (all scalars in GPRs)
    OpRegBankIdx[Idx] = getPartialMappingIdx(MRI.getType(MO.getReg()), false);
  }

  // Finally construct the computed mapping.
  RegisterBankInfo::InstructionMapping Mapping =
      InstructionMapping{DefaultMappingID, Cost, nullptr, NumOperands};
  SmallVector<const ValueMapping *, 8> OpdsMapping(NumOperands);
  for (unsigned Idx = 0; Idx < NumOperands; ++Idx) {
    if (MI.getOperand(Idx).isReg()) {
      auto Mapping = getValueMapping(OpRegBankIdx[Idx], 1);
      if (!Mapping->isValid())
        return InstructionMapping();

      OpdsMapping[Idx] = Mapping;
    }
  }

  Mapping.setOperandsMapping(getOperandsMapping(OpdsMapping));
  return Mapping;
}

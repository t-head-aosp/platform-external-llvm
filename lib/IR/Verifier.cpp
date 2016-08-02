//===-- Verifier.cpp - Implement the Module Verifier -----------------------==//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file defines the function verifier interface, that can be used for some
// sanity checking of input to the system.
//
// Note that this does not provide full `Java style' security and verifications,
// instead it just tries to ensure that code is well-formed.
//
//  * Both of a binary operator's parameters are of the same type
//  * Verify that the indices of mem access instructions match other operands
//  * Verify that arithmetic and other things are only performed on first-class
//    types.  Verify that shifts & logicals only happen on integrals f.e.
//  * All of the constants in a switch statement are of the correct type
//  * The code is in valid SSA form
//  * It should be illegal to put a label into any other type (like a structure)
//    or to return one. [except constant arrays!]
//  * Only phi nodes can be self referential: 'add i32 %0, %0 ; <int>:0' is bad
//  * PHI nodes must have an entry for each predecessor, with no extras.
//  * PHI nodes must be the first thing in a basic block, all grouped together
//  * PHI nodes must have at least one entry
//  * All basic blocks should only end with terminator insts, not contain them
//  * The entry node to a function must not have predecessors
//  * All Instructions must be embedded into a basic block
//  * Functions cannot take a void-typed parameter
//  * Verify that a function's argument list agrees with it's declared type.
//  * It is illegal to specify a name for a void value.
//  * It is illegal to have a internal global value with no initializer
//  * It is illegal to have a ret instruction that returns a value that does not
//    agree with the function return value type.
//  * Function call argument types match the function prototype
//  * A landing pad is defined by a landingpad instruction, and can be jumped to
//    only by the unwind edge of an invoke instruction.
//  * A landingpad instruction must be the first non-PHI instruction in the
//    block.
//  * Landingpad instructions must be in a function with a personality function.
//  * All other things that are tested by asserts spread about the code...
//
//===----------------------------------------------------------------------===//

#include "llvm/IR/Verifier.h"
#include "llvm/ADT/MapVector.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SetVector.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringExtras.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/CallSite.h"
#include "llvm/IR/CallingConv.h"
#include "llvm/IR/ConstantRange.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/DebugInfo.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/InlineAsm.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/InstVisitor.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Metadata.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/ModuleSlotTracker.h"
#include "llvm/IR/PassManager.h"
#include "llvm/IR/Statepoint.h"
#include "llvm/Pass.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"
#include <algorithm>
#include <cstdarg>
using namespace llvm;

static cl::opt<bool> VerifyDebugInfo("verify-debug-info", cl::init(true));

namespace {
struct VerifierSupport {
  raw_ostream *OS;
  const Module *M = nullptr;
  Optional<ModuleSlotTracker> MST;

  /// Track the brokenness of the module while recursively visiting.
  bool Broken = false;
  /// Broken debug info can be "recovered" from by stripping the debug info.
  bool BrokenDebugInfo = false;
  /// Whether to treat broken debug info as an error.
  bool TreatBrokenDebugInfoAsError = true;

  explicit VerifierSupport(raw_ostream *OS) : OS(OS) {}

private:
  template <class NodeTy> void Write(const ilist_iterator<NodeTy> &I) {
    Write(&*I);
  }

  void Write(const Module *M) {
    if (!M)
      return;
    *OS << "; ModuleID = '" << M->getModuleIdentifier() << "'\n";
  }

  void Write(const Value *V) {
    if (!V)
      return;
    if (isa<Instruction>(V)) {
      V->print(*OS, *MST);
      *OS << '\n';
    } else {
      V->printAsOperand(*OS, true, *MST);
      *OS << '\n';
    }
  }
  void Write(ImmutableCallSite CS) {
    Write(CS.getInstruction());
  }

  void Write(const Metadata *MD) {
    if (!MD)
      return;
    MD->print(*OS, *MST, M);
    *OS << '\n';
  }

  template <class T> void Write(const MDTupleTypedArrayWrapper<T> &MD) {
    Write(MD.get());
  }

  void Write(const NamedMDNode *NMD) {
    if (!NMD)
      return;
    NMD->print(*OS, *MST);
    *OS << '\n';
  }

  void Write(Type *T) {
    if (!T)
      return;
    *OS << ' ' << *T;
  }

  void Write(const Comdat *C) {
    if (!C)
      return;
    *OS << *C;
  }

  template <typename T> void Write(ArrayRef<T> Vs) {
    for (const T &V : Vs)
      Write(V);
  }

  template <typename T1, typename... Ts>
  void WriteTs(const T1 &V1, const Ts &... Vs) {
    Write(V1);
    WriteTs(Vs...);
  }

  template <typename... Ts> void WriteTs() {}

public:
  /// \brief A check failed, so printout out the condition and the message.
  ///
  /// This provides a nice place to put a breakpoint if you want to see why
  /// something is not correct.
  void CheckFailed(const Twine &Message) {
    if (OS)
      *OS << Message << '\n';
    Broken = true;
  }

  /// \brief A check failed (with values to print).
  ///
  /// This calls the Message-only version so that the above is easier to set a
  /// breakpoint on.
  template <typename T1, typename... Ts>
  void CheckFailed(const Twine &Message, const T1 &V1, const Ts &... Vs) {
    CheckFailed(Message);
    if (OS)
      WriteTs(V1, Vs...);
  }

  /// A debug info check failed.
  void DebugInfoCheckFailed(const Twine &Message) {
    if (OS)
      *OS << Message << '\n';
    Broken |= TreatBrokenDebugInfoAsError;
    BrokenDebugInfo = true;
  }

  /// A debug info check failed (with values to print).
  template <typename T1, typename... Ts>
  void DebugInfoCheckFailed(const Twine &Message, const T1 &V1,
                            const Ts &... Vs) {
    DebugInfoCheckFailed(Message);
    if (OS)
      WriteTs(V1, Vs...);
  }
};

class Verifier : public InstVisitor<Verifier>, VerifierSupport {
  friend class InstVisitor<Verifier>;

  LLVMContext *Context;
  DominatorTree DT;

  /// \brief When verifying a basic block, keep track of all of the
  /// instructions we have seen so far.
  ///
  /// This allows us to do efficient dominance checks for the case when an
  /// instruction has an operand that is an instruction in the same block.
  SmallPtrSet<Instruction *, 16> InstsInThisBlock;

  /// \brief Keep track of the metadata nodes that have been checked already.
  SmallPtrSet<const Metadata *, 32> MDNodes;

  /// Track all DICompileUnits visited.
  SmallPtrSet<const Metadata *, 2> CUVisited;

  /// \brief The result type for a landingpad.
  Type *LandingPadResultTy;

  /// \brief Whether we've seen a call to @llvm.localescape in this function
  /// already.
  bool SawFrameEscape;

  /// Stores the count of how many objects were passed to llvm.localescape for a
  /// given function and the largest index passed to llvm.localrecover.
  DenseMap<Function *, std::pair<unsigned, unsigned>> FrameEscapeInfo;

  // Maps catchswitches and cleanuppads that unwind to siblings to the
  // terminators that indicate the unwind, used to detect cycles therein.
  MapVector<Instruction *, TerminatorInst *> SiblingFuncletInfo;

  /// Cache of constants visited in search of ConstantExprs.
  SmallPtrSet<const Constant *, 32> ConstantExprVisited;

  /// Cache of declarations of the llvm.experimental.deoptimize.<ty> intrinsic.
  SmallVector<const Function *, 4> DeoptimizeDeclarations;

  // Verify that this GlobalValue is only used in this module.
  // This map is used to avoid visiting uses twice. We can arrive at a user
  // twice, if they have multiple operands. In particular for very large
  // constant expressions, we can arrive at a particular user many times.
  SmallPtrSet<const Value *, 32> GlobalValueVisited;

  void checkAtomicMemAccessSize(const Module *M, Type *Ty,
                                const Instruction *I);

  void updateModule(const Module *NewM) {
    if (M == NewM)
      return;
    MST.emplace(NewM);
    M = NewM;
  }

public:
  explicit Verifier(raw_ostream *OS, bool ShouldTreatBrokenDebugInfoAsError)
      : VerifierSupport(OS), Context(nullptr), LandingPadResultTy(nullptr),
        SawFrameEscape(false) {
    TreatBrokenDebugInfoAsError = ShouldTreatBrokenDebugInfoAsError;
  }

  bool hasBrokenDebugInfo() const { return BrokenDebugInfo; }

  bool verify(const Function &F) {
    updateModule(F.getParent());
    Context = &M->getContext();

    // First ensure the function is well-enough formed to compute dominance
    // information, and directly compute a dominance tree. We don't rely on the
    // pass manager to provide this as it isolates us from a potentially
    // out-of-date dominator tree and makes it significantly more complex to run
    // this code outside of a pass manager.
    // FIXME: It's really gross that we have to cast away constness here.
    if (!F.empty())
      DT.recalculate(const_cast<Function &>(F));

    for (const BasicBlock &BB : F) {
      if (!BB.empty() && BB.back().isTerminator())
        continue;

      if (OS) {
        *OS << "Basic Block in function '" << F.getName()
            << "' does not have terminator!\n";
        BB.printAsOperand(*OS, true, *MST);
        *OS << "\n";
      }
      return false;
    }

    Broken = false;
    // FIXME: We strip const here because the inst visitor strips const.
    visit(const_cast<Function &>(F));
    verifySiblingFuncletUnwinds();
    InstsInThisBlock.clear();
    LandingPadResultTy = nullptr;
    SawFrameEscape = false;
    SiblingFuncletInfo.clear();

    return !Broken;
  }

  bool verify(const Module &M) {
    updateModule(&M);
    Context = &M.getContext();
    Broken = false;

    // Collect all declarations of the llvm.experimental.deoptimize intrinsic.
    for (const Function &F : M)
      if (F.getIntrinsicID() == Intrinsic::experimental_deoptimize)
        DeoptimizeDeclarations.push_back(&F);

    // Now that we've visited every function, verify that we never asked to
    // recover a frame index that wasn't escaped.
    verifyFrameRecoverIndices();
    for (const GlobalVariable &GV : M.globals())
      visitGlobalVariable(GV);

    for (const GlobalAlias &GA : M.aliases())
      visitGlobalAlias(GA);

    for (const NamedMDNode &NMD : M.named_metadata())
      visitNamedMDNode(NMD);

    for (const StringMapEntry<Comdat> &SMEC : M.getComdatSymbolTable())
      visitComdat(SMEC.getValue());

    visitModuleFlags(M);
    visitModuleIdents(M);

    verifyCompileUnits();

    verifyDeoptimizeCallingConvs();

    return !Broken;
  }

private:
  // Verification methods...
  void visitGlobalValue(const GlobalValue &GV);
  void visitGlobalVariable(const GlobalVariable &GV);
  void visitGlobalAlias(const GlobalAlias &GA);
  void visitAliaseeSubExpr(const GlobalAlias &A, const Constant &C);
  void visitAliaseeSubExpr(SmallPtrSetImpl<const GlobalAlias *> &Visited,
                           const GlobalAlias &A, const Constant &C);
  void visitNamedMDNode(const NamedMDNode &NMD);
  void visitMDNode(const MDNode &MD);
  void visitMetadataAsValue(const MetadataAsValue &MD, Function *F);
  void visitValueAsMetadata(const ValueAsMetadata &MD, Function *F);
  void visitComdat(const Comdat &C);
  void visitModuleIdents(const Module &M);
  void visitModuleFlags(const Module &M);
  void visitModuleFlag(const MDNode *Op,
                       DenseMap<const MDString *, const MDNode *> &SeenIDs,
                       SmallVectorImpl<const MDNode *> &Requirements);
  void visitFunction(const Function &F);
  void visitBasicBlock(BasicBlock &BB);
  void visitRangeMetadata(Instruction& I, MDNode* Range, Type* Ty);
  void visitDereferenceableMetadata(Instruction& I, MDNode* MD);

  template <class Ty> bool isValidMetadataArray(const MDTuple &N);
#define HANDLE_SPECIALIZED_MDNODE_LEAF(CLASS) void visit##CLASS(const CLASS &N);
#include "llvm/IR/Metadata.def"
  void visitDIScope(const DIScope &N);
  void visitDIVariable(const DIVariable &N);
  void visitDILexicalBlockBase(const DILexicalBlockBase &N);
  void visitDITemplateParameter(const DITemplateParameter &N);

  void visitTemplateParams(const MDNode &N, const Metadata &RawParams);

  // InstVisitor overrides...
  using InstVisitor<Verifier>::visit;
  void visit(Instruction &I);

  void visitTruncInst(TruncInst &I);
  void visitZExtInst(ZExtInst &I);
  void visitSExtInst(SExtInst &I);
  void visitFPTruncInst(FPTruncInst &I);
  void visitFPExtInst(FPExtInst &I);
  void visitFPToUIInst(FPToUIInst &I);
  void visitFPToSIInst(FPToSIInst &I);
  void visitUIToFPInst(UIToFPInst &I);
  void visitSIToFPInst(SIToFPInst &I);
  void visitIntToPtrInst(IntToPtrInst &I);
  void visitPtrToIntInst(PtrToIntInst &I);
  void visitBitCastInst(BitCastInst &I);
  void visitAddrSpaceCastInst(AddrSpaceCastInst &I);
  void visitPHINode(PHINode &PN);
  void visitBinaryOperator(BinaryOperator &B);
  void visitICmpInst(ICmpInst &IC);
  void visitFCmpInst(FCmpInst &FC);
  void visitExtractElementInst(ExtractElementInst &EI);
  void visitInsertElementInst(InsertElementInst &EI);
  void visitShuffleVectorInst(ShuffleVectorInst &EI);
  void visitVAArgInst(VAArgInst &VAA) { visitInstruction(VAA); }
  void visitCallInst(CallInst &CI);
  void visitInvokeInst(InvokeInst &II);
  void visitGetElementPtrInst(GetElementPtrInst &GEP);
  void visitLoadInst(LoadInst &LI);
  void visitStoreInst(StoreInst &SI);
  void verifyDominatesUse(Instruction &I, unsigned i);
  void visitInstruction(Instruction &I);
  void visitTerminatorInst(TerminatorInst &I);
  void visitBranchInst(BranchInst &BI);
  void visitReturnInst(ReturnInst &RI);
  void visitSwitchInst(SwitchInst &SI);
  void visitIndirectBrInst(IndirectBrInst &BI);
  void visitSelectInst(SelectInst &SI);
  void visitUserOp1(Instruction &I);
  void visitUserOp2(Instruction &I) { visitUserOp1(I); }
  void visitIntrinsicCallSite(Intrinsic::ID ID, CallSite CS);
  template <class DbgIntrinsicTy>
  void visitDbgIntrinsic(StringRef Kind, DbgIntrinsicTy &DII);
  void visitAtomicCmpXchgInst(AtomicCmpXchgInst &CXI);
  void visitAtomicRMWInst(AtomicRMWInst &RMWI);
  void visitFenceInst(FenceInst &FI);
  void visitAllocaInst(AllocaInst &AI);
  void visitExtractValueInst(ExtractValueInst &EVI);
  void visitInsertValueInst(InsertValueInst &IVI);
  void visitEHPadPredecessors(Instruction &I);
  void visitLandingPadInst(LandingPadInst &LPI);
  void visitResumeInst(ResumeInst &RI);
  void visitCatchPadInst(CatchPadInst &CPI);
  void visitCatchReturnInst(CatchReturnInst &CatchReturn);
  void visitCleanupPadInst(CleanupPadInst &CPI);
  void visitFuncletPadInst(FuncletPadInst &FPI);
  void visitCatchSwitchInst(CatchSwitchInst &CatchSwitch);
  void visitCleanupReturnInst(CleanupReturnInst &CRI);

  void verifyCallSite(CallSite CS);
  void verifySwiftErrorCallSite(CallSite CS, const Value *SwiftErrorVal);
  void verifySwiftErrorValue(const Value *SwiftErrorVal);
  void verifyMustTailCall(CallInst &CI);
  bool performTypeCheck(Intrinsic::ID ID, Function *F, Type *Ty, int VT,
                        unsigned ArgNo, std::string &Suffix);
  bool verifyAttributeCount(AttributeSet Attrs, unsigned Params);
  void verifyAttributeTypes(AttributeSet Attrs, unsigned Idx, bool isFunction,
                            const Value *V);
  void verifyParameterAttrs(AttributeSet Attrs, unsigned Idx, Type *Ty,
                            bool isReturnValue, const Value *V);
  void verifyFunctionAttrs(FunctionType *FT, AttributeSet Attrs,
                           const Value *V);
  void verifyFunctionMetadata(ArrayRef<std::pair<unsigned, MDNode *>> MDs);

  void visitConstantExprsRecursively(const Constant *EntryC);
  void visitConstantExpr(const ConstantExpr *CE);
  void verifyStatepoint(ImmutableCallSite CS);
  void verifyFrameRecoverIndices();
  void verifySiblingFuncletUnwinds();

  void verifyBitPieceExpression(const DbgInfoIntrinsic &I);

  /// Module-level debug info verification...
  void verifyCompileUnits();

  /// Module-level verification that all @llvm.experimental.deoptimize
  /// declarations share the same calling convention.
  void verifyDeoptimizeCallingConvs();
};
} // End anonymous namespace

/// We know that cond should be true, if not print an error message.
#define Assert(C, ...) \
  do { if (!(C)) { CheckFailed(__VA_ARGS__); return; } } while (0)

/// We know that a debug info condition should be true, if not print
/// an error message.
#define AssertDI(C, ...) \
  do { if (!(C)) { DebugInfoCheckFailed(__VA_ARGS__); return; } } while (0)


void Verifier::visit(Instruction &I) {
  for (unsigned i = 0, e = I.getNumOperands(); i != e; ++i)
    Assert(I.getOperand(i) != nullptr, "Operand is null", &I);
  InstVisitor<Verifier>::visit(I);
}

// Helper to recursively iterate over indirect users. By
// returning false, the callback can ask to stop recursing
// further.
static void forEachUser(const Value *User,
                        SmallPtrSet<const Value *, 32> &Visited,
                        llvm::function_ref<bool(const Value *)> Callback) {
  if (!Visited.insert(User).second)
    return;
  for (const Value *TheNextUser : User->materialized_users())
    if (Callback(TheNextUser))
      forEachUser(TheNextUser, Visited, Callback);
}

void Verifier::visitGlobalValue(const GlobalValue &GV) {
  Assert(!GV.isDeclaration() || GV.hasValidDeclarationLinkage(),
         "Global is external, but doesn't have external or weak linkage!", &GV);

  Assert(GV.getAlignment() <= Value::MaximumAlignment,
         "huge alignment values are unsupported", &GV);
  Assert(!GV.hasAppendingLinkage() || isa<GlobalVariable>(GV),
         "Only global variables can have appending linkage!", &GV);

  if (GV.hasAppendingLinkage()) {
    const GlobalVariable *GVar = dyn_cast<GlobalVariable>(&GV);
    Assert(GVar && GVar->getValueType()->isArrayTy(),
           "Only global arrays can have appending linkage!", GVar);
  }

  if (GV.isDeclarationForLinker())
    Assert(!GV.hasComdat(), "Declaration may not be in a Comdat!", &GV);

  forEachUser(&GV, GlobalValueVisited, [&](const Value *V) -> bool {
    if (const Instruction *I = dyn_cast<Instruction>(V)) {
      if (!I->getParent() || !I->getParent()->getParent())
        CheckFailed("Global is referenced by parentless instruction!", &GV,
                    M, I);
      else if (I->getParent()->getParent()->getParent() != M)
        CheckFailed("Global is referenced in a different module!", &GV,
                    M, I, I->getParent()->getParent(),
                    I->getParent()->getParent()->getParent());
      return false;
    } else if (const Function *F = dyn_cast<Function>(V)) {
      if (F->getParent() != M)
        CheckFailed("Global is used by function in a different module", &GV,
                    M, F, F->getParent());
      return false;
    }
    return true;
  });
}

void Verifier::visitGlobalVariable(const GlobalVariable &GV) {
  if (GV.hasInitializer()) {
    Assert(GV.getInitializer()->getType() == GV.getValueType(),
           "Global variable initializer type does not match global "
           "variable type!",
           &GV);

    // If the global has common linkage, it must have a zero initializer and
    // cannot be constant.
    if (GV.hasCommonLinkage()) {
      Assert(GV.getInitializer()->isNullValue(),
             "'common' global must have a zero initializer!", &GV);
      Assert(!GV.isConstant(), "'common' global may not be marked constant!",
             &GV);
      Assert(!GV.hasComdat(), "'common' global may not be in a Comdat!", &GV);
    }
  }

  if (GV.hasName() && (GV.getName() == "llvm.global_ctors" ||
                       GV.getName() == "llvm.global_dtors")) {
    Assert(!GV.hasInitializer() || GV.hasAppendingLinkage(),
           "invalid linkage for intrinsic global variable", &GV);
    // Don't worry about emitting an error for it not being an array,
    // visitGlobalValue will complain on appending non-array.
    if (ArrayType *ATy = dyn_cast<ArrayType>(GV.getValueType())) {
      StructType *STy = dyn_cast<StructType>(ATy->getElementType());
      PointerType *FuncPtrTy =
          FunctionType::get(Type::getVoidTy(*Context), false)->getPointerTo();
      // FIXME: Reject the 2-field form in LLVM 4.0.
      Assert(STy &&
                 (STy->getNumElements() == 2 || STy->getNumElements() == 3) &&
                 STy->getTypeAtIndex(0u)->isIntegerTy(32) &&
                 STy->getTypeAtIndex(1) == FuncPtrTy,
             "wrong type for intrinsic global variable", &GV);
      if (STy->getNumElements() == 3) {
        Type *ETy = STy->getTypeAtIndex(2);
        Assert(ETy->isPointerTy() &&
                   cast<PointerType>(ETy)->getElementType()->isIntegerTy(8),
               "wrong type for intrinsic global variable", &GV);
      }
    }
  }

  if (GV.hasName() && (GV.getName() == "llvm.used" ||
                       GV.getName() == "llvm.compiler.used")) {
    Assert(!GV.hasInitializer() || GV.hasAppendingLinkage(),
           "invalid linkage for intrinsic global variable", &GV);
    Type *GVType = GV.getValueType();
    if (ArrayType *ATy = dyn_cast<ArrayType>(GVType)) {
      PointerType *PTy = dyn_cast<PointerType>(ATy->getElementType());
      Assert(PTy, "wrong type for intrinsic global variable", &GV);
      if (GV.hasInitializer()) {
        const Constant *Init = GV.getInitializer();
        const ConstantArray *InitArray = dyn_cast<ConstantArray>(Init);
        Assert(InitArray, "wrong initalizer for intrinsic global variable",
               Init);
        for (Value *Op : InitArray->operands()) {
          Value *V = Op->stripPointerCastsNoFollowAliases();
          Assert(isa<GlobalVariable>(V) || isa<Function>(V) ||
                     isa<GlobalAlias>(V),
                 "invalid llvm.used member", V);
          Assert(V->hasName(), "members of llvm.used must be named", V);
        }
      }
    }
  }

  Assert(!GV.hasDLLImportStorageClass() ||
             (GV.isDeclaration() && GV.hasExternalLinkage()) ||
             GV.hasAvailableExternallyLinkage(),
         "Global is marked as dllimport, but not external", &GV);

  if (!GV.hasInitializer()) {
    visitGlobalValue(GV);
    return;
  }

  // Walk any aggregate initializers looking for bitcasts between address spaces
  visitConstantExprsRecursively(GV.getInitializer());

  visitGlobalValue(GV);
}

void Verifier::visitAliaseeSubExpr(const GlobalAlias &GA, const Constant &C) {
  SmallPtrSet<const GlobalAlias*, 4> Visited;
  Visited.insert(&GA);
  visitAliaseeSubExpr(Visited, GA, C);
}

void Verifier::visitAliaseeSubExpr(SmallPtrSetImpl<const GlobalAlias*> &Visited,
                                   const GlobalAlias &GA, const Constant &C) {
  if (const auto *GV = dyn_cast<GlobalValue>(&C)) {
    Assert(!GV->isDeclarationForLinker(), "Alias must point to a definition",
           &GA);

    if (const auto *GA2 = dyn_cast<GlobalAlias>(GV)) {
      Assert(Visited.insert(GA2).second, "Aliases cannot form a cycle", &GA);

      Assert(!GA2->isInterposable(), "Alias cannot point to an interposable alias",
             &GA);
    } else {
      // Only continue verifying subexpressions of GlobalAliases.
      // Do not recurse into global initializers.
      return;
    }
  }

  if (const auto *CE = dyn_cast<ConstantExpr>(&C))
    visitConstantExprsRecursively(CE);

  for (const Use &U : C.operands()) {
    Value *V = &*U;
    if (const auto *GA2 = dyn_cast<GlobalAlias>(V))
      visitAliaseeSubExpr(Visited, GA, *GA2->getAliasee());
    else if (const auto *C2 = dyn_cast<Constant>(V))
      visitAliaseeSubExpr(Visited, GA, *C2);
  }
}

void Verifier::visitGlobalAlias(const GlobalAlias &GA) {
  Assert(GlobalAlias::isValidLinkage(GA.getLinkage()),
         "Alias should have private, internal, linkonce, weak, linkonce_odr, "
         "weak_odr, or external linkage!",
         &GA);
  const Constant *Aliasee = GA.getAliasee();
  Assert(Aliasee, "Aliasee cannot be NULL!", &GA);
  Assert(GA.getType() == Aliasee->getType(),
         "Alias and aliasee types should match!", &GA);

  Assert(isa<GlobalValue>(Aliasee) || isa<ConstantExpr>(Aliasee),
         "Aliasee should be either GlobalValue or ConstantExpr", &GA);

  visitAliaseeSubExpr(GA, *Aliasee);

  visitGlobalValue(GA);
}

void Verifier::visitNamedMDNode(const NamedMDNode &NMD) {
  for (const MDNode *MD : NMD.operands()) {
    if (NMD.getName() == "llvm.dbg.cu") {
      AssertDI(MD && isa<DICompileUnit>(MD), "invalid compile unit", &NMD, MD);
    }

    if (!MD)
      continue;

    visitMDNode(*MD);
  }
}

void Verifier::visitMDNode(const MDNode &MD) {
  // Only visit each node once.  Metadata can be mutually recursive, so this
  // avoids infinite recursion here, as well as being an optimization.
  if (!MDNodes.insert(&MD).second)
    return;

  switch (MD.getMetadataID()) {
  default:
    llvm_unreachable("Invalid MDNode subclass");
  case Metadata::MDTupleKind:
    break;
#define HANDLE_SPECIALIZED_MDNODE_LEAF(CLASS)                                  \
  case Metadata::CLASS##Kind:                                                  \
    visit##CLASS(cast<CLASS>(MD));                                             \
    break;
#include "llvm/IR/Metadata.def"
  }

  for (const Metadata *Op : MD.operands()) {
    if (!Op)
      continue;
    Assert(!isa<LocalAsMetadata>(Op), "Invalid operand for global metadata!",
           &MD, Op);
    if (auto *N = dyn_cast<MDNode>(Op)) {
      visitMDNode(*N);
      continue;
    }
    if (auto *V = dyn_cast<ValueAsMetadata>(Op)) {
      visitValueAsMetadata(*V, nullptr);
      continue;
    }
  }

  // Check these last, so we diagnose problems in operands first.
  Assert(!MD.isTemporary(), "Expected no forward declarations!", &MD);
  Assert(MD.isResolved(), "All nodes should be resolved!", &MD);
}

void Verifier::visitValueAsMetadata(const ValueAsMetadata &MD, Function *F) {
  Assert(MD.getValue(), "Expected valid value", &MD);
  Assert(!MD.getValue()->getType()->isMetadataTy(),
         "Unexpected metadata round-trip through values", &MD, MD.getValue());

  auto *L = dyn_cast<LocalAsMetadata>(&MD);
  if (!L)
    return;

  Assert(F, "function-local metadata used outside a function", L);

  // If this was an instruction, bb, or argument, verify that it is in the
  // function that we expect.
  Function *ActualF = nullptr;
  if (Instruction *I = dyn_cast<Instruction>(L->getValue())) {
    Assert(I->getParent(), "function-local metadata not in basic block", L, I);
    ActualF = I->getParent()->getParent();
  } else if (BasicBlock *BB = dyn_cast<BasicBlock>(L->getValue()))
    ActualF = BB->getParent();
  else if (Argument *A = dyn_cast<Argument>(L->getValue()))
    ActualF = A->getParent();
  assert(ActualF && "Unimplemented function local metadata case!");

  Assert(ActualF == F, "function-local metadata used in wrong function", L);
}

void Verifier::visitMetadataAsValue(const MetadataAsValue &MDV, Function *F) {
  Metadata *MD = MDV.getMetadata();
  if (auto *N = dyn_cast<MDNode>(MD)) {
    visitMDNode(*N);
    return;
  }

  // Only visit each node once.  Metadata can be mutually recursive, so this
  // avoids infinite recursion here, as well as being an optimization.
  if (!MDNodes.insert(MD).second)
    return;

  if (auto *V = dyn_cast<ValueAsMetadata>(MD))
    visitValueAsMetadata(*V, F);
}

static bool isType(const Metadata *MD) { return !MD || isa<DIType>(MD); }
static bool isScope(const Metadata *MD) { return !MD || isa<DIScope>(MD); }
static bool isDINode(const Metadata *MD) { return !MD || isa<DINode>(MD); }

template <class Ty>
bool isValidMetadataArrayImpl(const MDTuple &N, bool AllowNull) {
  for (Metadata *MD : N.operands()) {
    if (MD) {
      if (!isa<Ty>(MD))
        return false;
    } else {
      if (!AllowNull)
        return false;
    }
  }
  return true;
}

template <class Ty>
bool isValidMetadataArray(const MDTuple &N) {
  return isValidMetadataArrayImpl<Ty>(N, /* AllowNull */ false);
}

template <class Ty>
bool isValidMetadataNullArray(const MDTuple &N) {
  return isValidMetadataArrayImpl<Ty>(N, /* AllowNull */ true);
}

void Verifier::visitDILocation(const DILocation &N) {
  AssertDI(N.getRawScope() && isa<DILocalScope>(N.getRawScope()),
           "location requires a valid scope", &N, N.getRawScope());
  if (auto *IA = N.getRawInlinedAt())
    AssertDI(isa<DILocation>(IA), "inlined-at should be a location", &N, IA);
}

void Verifier::visitGenericDINode(const GenericDINode &N) {
  AssertDI(N.getTag(), "invalid tag", &N);
}

void Verifier::visitDIScope(const DIScope &N) {
  if (auto *F = N.getRawFile())
    AssertDI(isa<DIFile>(F), "invalid file", &N, F);
}

void Verifier::visitDISubrange(const DISubrange &N) {
  AssertDI(N.getTag() == dwarf::DW_TAG_subrange_type, "invalid tag", &N);
  AssertDI(N.getCount() >= -1, "invalid subrange count", &N);
}

void Verifier::visitDIEnumerator(const DIEnumerator &N) {
  AssertDI(N.getTag() == dwarf::DW_TAG_enumerator, "invalid tag", &N);
}

void Verifier::visitDIBasicType(const DIBasicType &N) {
  AssertDI(N.getTag() == dwarf::DW_TAG_base_type ||
               N.getTag() == dwarf::DW_TAG_unspecified_type,
           "invalid tag", &N);
}

void Verifier::visitDIDerivedType(const DIDerivedType &N) {
  // Common scope checks.
  visitDIScope(N);

  AssertDI(N.getTag() == dwarf::DW_TAG_typedef ||
               N.getTag() == dwarf::DW_TAG_pointer_type ||
               N.getTag() == dwarf::DW_TAG_ptr_to_member_type ||
               N.getTag() == dwarf::DW_TAG_reference_type ||
               N.getTag() == dwarf::DW_TAG_rvalue_reference_type ||
               N.getTag() == dwarf::DW_TAG_const_type ||
               N.getTag() == dwarf::DW_TAG_volatile_type ||
               N.getTag() == dwarf::DW_TAG_restrict_type ||
               N.getTag() == dwarf::DW_TAG_member ||
               N.getTag() == dwarf::DW_TAG_inheritance ||
               N.getTag() == dwarf::DW_TAG_friend,
           "invalid tag", &N);
  if (N.getTag() == dwarf::DW_TAG_ptr_to_member_type) {
    AssertDI(isType(N.getRawExtraData()), "invalid pointer to member type", &N,
             N.getRawExtraData());
  }

  AssertDI(isScope(N.getRawScope()), "invalid scope", &N, N.getRawScope());
  AssertDI(isType(N.getRawBaseType()), "invalid base type", &N,
           N.getRawBaseType());
}

static bool hasConflictingReferenceFlags(unsigned Flags) {
  return (Flags & DINode::FlagLValueReference) &&
         (Flags & DINode::FlagRValueReference);
}

void Verifier::visitTemplateParams(const MDNode &N, const Metadata &RawParams) {
  auto *Params = dyn_cast<MDTuple>(&RawParams);
  AssertDI(Params, "invalid template params", &N, &RawParams);
  for (Metadata *Op : Params->operands()) {
    AssertDI(Op && isa<DITemplateParameter>(Op), "invalid template parameter",
             &N, Params, Op);
  }
}

void Verifier::visitDICompositeType(const DICompositeType &N) {
  // Common scope checks.
  visitDIScope(N);

  AssertDI(N.getTag() == dwarf::DW_TAG_array_type ||
               N.getTag() == dwarf::DW_TAG_structure_type ||
               N.getTag() == dwarf::DW_TAG_union_type ||
               N.getTag() == dwarf::DW_TAG_enumeration_type ||
               N.getTag() == dwarf::DW_TAG_class_type,
           "invalid tag", &N);

  AssertDI(isScope(N.getRawScope()), "invalid scope", &N, N.getRawScope());
  AssertDI(isType(N.getRawBaseType()), "invalid base type", &N,
           N.getRawBaseType());

  AssertDI(!N.getRawElements() || isa<MDTuple>(N.getRawElements()),
           "invalid composite elements", &N, N.getRawElements());
  AssertDI(isType(N.getRawVTableHolder()), "invalid vtable holder", &N,
           N.getRawVTableHolder());
  AssertDI(!hasConflictingReferenceFlags(N.getFlags()),
           "invalid reference flags", &N);
  if (auto *Params = N.getRawTemplateParams())
    visitTemplateParams(N, *Params);

  if (N.getTag() == dwarf::DW_TAG_class_type ||
      N.getTag() == dwarf::DW_TAG_union_type) {
    AssertDI(N.getFile() && !N.getFile()->getFilename().empty(),
             "class/union requires a filename", &N, N.getFile());
  }
}

void Verifier::visitDISubroutineType(const DISubroutineType &N) {
  AssertDI(N.getTag() == dwarf::DW_TAG_subroutine_type, "invalid tag", &N);
  if (auto *Types = N.getRawTypeArray()) {
    AssertDI(isa<MDTuple>(Types), "invalid composite elements", &N, Types);
    for (Metadata *Ty : N.getTypeArray()->operands()) {
      AssertDI(isType(Ty), "invalid subroutine type ref", &N, Types, Ty);
    }
  }
  AssertDI(!hasConflictingReferenceFlags(N.getFlags()),
           "invalid reference flags", &N);
}

void Verifier::visitDIFile(const DIFile &N) {
  AssertDI(N.getTag() == dwarf::DW_TAG_file_type, "invalid tag", &N);
}

void Verifier::visitDICompileUnit(const DICompileUnit &N) {
  AssertDI(N.isDistinct(), "compile units must be distinct", &N);
  AssertDI(N.getTag() == dwarf::DW_TAG_compile_unit, "invalid tag", &N);

  // Don't bother verifying the compilation directory or producer string
  // as those could be empty.
  AssertDI(N.getRawFile() && isa<DIFile>(N.getRawFile()), "invalid file", &N,
           N.getRawFile());
  AssertDI(!N.getFile()->getFilename().empty(), "invalid filename", &N,
           N.getFile());

  AssertDI((N.getEmissionKind() <= DICompileUnit::LastEmissionKind),
           "invalid emission kind", &N);

  if (auto *Array = N.getRawEnumTypes()) {
    AssertDI(isa<MDTuple>(Array), "invalid enum list", &N, Array);
    for (Metadata *Op : N.getEnumTypes()->operands()) {
      auto *Enum = dyn_cast_or_null<DICompositeType>(Op);
      AssertDI(Enum && Enum->getTag() == dwarf::DW_TAG_enumeration_type,
               "invalid enum type", &N, N.getEnumTypes(), Op);
    }
  }
  if (auto *Array = N.getRawRetainedTypes()) {
    AssertDI(isa<MDTuple>(Array), "invalid retained type list", &N, Array);
    for (Metadata *Op : N.getRetainedTypes()->operands()) {
      AssertDI(Op && (isa<DIType>(Op) ||
                      (isa<DISubprogram>(Op) &&
                       cast<DISubprogram>(Op)->isDefinition() == false)),
               "invalid retained type", &N, Op);
    }
  }
  if (auto *Array = N.getRawGlobalVariables()) {
    AssertDI(isa<MDTuple>(Array), "invalid global variable list", &N, Array);
    for (Metadata *Op : N.getGlobalVariables()->operands()) {
      AssertDI(Op && isa<DIGlobalVariable>(Op), "invalid global variable ref",
               &N, Op);
    }
  }
  if (auto *Array = N.getRawImportedEntities()) {
    AssertDI(isa<MDTuple>(Array), "invalid imported entity list", &N, Array);
    for (Metadata *Op : N.getImportedEntities()->operands()) {
      AssertDI(Op && isa<DIImportedEntity>(Op), "invalid imported entity ref",
               &N, Op);
    }
  }
  if (auto *Array = N.getRawMacros()) {
    AssertDI(isa<MDTuple>(Array), "invalid macro list", &N, Array);
    for (Metadata *Op : N.getMacros()->operands()) {
      AssertDI(Op && isa<DIMacroNode>(Op), "invalid macro ref", &N, Op);
    }
  }
  CUVisited.insert(&N);
}

void Verifier::visitDISubprogram(const DISubprogram &N) {
  AssertDI(N.getTag() == dwarf::DW_TAG_subprogram, "invalid tag", &N);
  AssertDI(isScope(N.getRawScope()), "invalid scope", &N, N.getRawScope());
  if (auto *F = N.getRawFile())
    AssertDI(isa<DIFile>(F), "invalid file", &N, F);
  if (auto *T = N.getRawType())
    AssertDI(isa<DISubroutineType>(T), "invalid subroutine type", &N, T);
  AssertDI(isType(N.getRawContainingType()), "invalid containing type", &N,
           N.getRawContainingType());
  if (auto *Params = N.getRawTemplateParams())
    visitTemplateParams(N, *Params);
  if (auto *S = N.getRawDeclaration())
    AssertDI(isa<DISubprogram>(S) && !cast<DISubprogram>(S)->isDefinition(),
             "invalid subprogram declaration", &N, S);
  if (auto *RawVars = N.getRawVariables()) {
    auto *Vars = dyn_cast<MDTuple>(RawVars);
    AssertDI(Vars, "invalid variable list", &N, RawVars);
    for (Metadata *Op : Vars->operands()) {
      AssertDI(Op && isa<DILocalVariable>(Op), "invalid local variable", &N,
               Vars, Op);
    }
  }
  AssertDI(!hasConflictingReferenceFlags(N.getFlags()),
           "invalid reference flags", &N);

  auto *Unit = N.getRawUnit();
  if (N.isDefinition()) {
    // Subprogram definitions (not part of the type hierarchy).
    AssertDI(N.isDistinct(), "subprogram definitions must be distinct", &N);
    AssertDI(Unit, "subprogram definitions must have a compile unit", &N);
    AssertDI(isa<DICompileUnit>(Unit), "invalid unit type", &N, Unit);
  } else {
    // Subprogram declarations (part of the type hierarchy).
    AssertDI(!Unit, "subprogram declarations must not have a compile unit", &N);
  }
}

void Verifier::visitDILexicalBlockBase(const DILexicalBlockBase &N) {
  AssertDI(N.getTag() == dwarf::DW_TAG_lexical_block, "invalid tag", &N);
  AssertDI(N.getRawScope() && isa<DILocalScope>(N.getRawScope()),
           "invalid local scope", &N, N.getRawScope());
}

void Verifier::visitDILexicalBlock(const DILexicalBlock &N) {
  visitDILexicalBlockBase(N);

  AssertDI(N.getLine() || !N.getColumn(),
           "cannot have column info without line info", &N);
}

void Verifier::visitDILexicalBlockFile(const DILexicalBlockFile &N) {
  visitDILexicalBlockBase(N);
}

void Verifier::visitDINamespace(const DINamespace &N) {
  AssertDI(N.getTag() == dwarf::DW_TAG_namespace, "invalid tag", &N);
  if (auto *S = N.getRawScope())
    AssertDI(isa<DIScope>(S), "invalid scope ref", &N, S);
}

void Verifier::visitDIMacro(const DIMacro &N) {
  AssertDI(N.getMacinfoType() == dwarf::DW_MACINFO_define ||
               N.getMacinfoType() == dwarf::DW_MACINFO_undef,
           "invalid macinfo type", &N);
  AssertDI(!N.getName().empty(), "anonymous macro", &N);
  if (!N.getValue().empty()) {
    assert(N.getValue().data()[0] != ' ' && "Macro value has a space prefix");
  }
}

void Verifier::visitDIMacroFile(const DIMacroFile &N) {
  AssertDI(N.getMacinfoType() == dwarf::DW_MACINFO_start_file,
           "invalid macinfo type", &N);
  if (auto *F = N.getRawFile())
    AssertDI(isa<DIFile>(F), "invalid file", &N, F);

  if (auto *Array = N.getRawElements()) {
    AssertDI(isa<MDTuple>(Array), "invalid macro list", &N, Array);
    for (Metadata *Op : N.getElements()->operands()) {
      AssertDI(Op && isa<DIMacroNode>(Op), "invalid macro ref", &N, Op);
    }
  }
}

void Verifier::visitDIModule(const DIModule &N) {
  AssertDI(N.getTag() == dwarf::DW_TAG_module, "invalid tag", &N);
  AssertDI(!N.getName().empty(), "anonymous module", &N);
}

void Verifier::visitDITemplateParameter(const DITemplateParameter &N) {
  AssertDI(isType(N.getRawType()), "invalid type ref", &N, N.getRawType());
}

void Verifier::visitDITemplateTypeParameter(const DITemplateTypeParameter &N) {
  visitDITemplateParameter(N);

  AssertDI(N.getTag() == dwarf::DW_TAG_template_type_parameter, "invalid tag",
           &N);
}

void Verifier::visitDITemplateValueParameter(
    const DITemplateValueParameter &N) {
  visitDITemplateParameter(N);

  AssertDI(N.getTag() == dwarf::DW_TAG_template_value_parameter ||
               N.getTag() == dwarf::DW_TAG_GNU_template_template_param ||
               N.getTag() == dwarf::DW_TAG_GNU_template_parameter_pack,
           "invalid tag", &N);
}

void Verifier::visitDIVariable(const DIVariable &N) {
  if (auto *S = N.getRawScope())
    AssertDI(isa<DIScope>(S), "invalid scope", &N, S);
  AssertDI(isType(N.getRawType()), "invalid type ref", &N, N.getRawType());
  if (auto *F = N.getRawFile())
    AssertDI(isa<DIFile>(F), "invalid file", &N, F);
}

void Verifier::visitDIGlobalVariable(const DIGlobalVariable &N) {
  // Checks common to all variables.
  visitDIVariable(N);

  AssertDI(N.getTag() == dwarf::DW_TAG_variable, "invalid tag", &N);
  AssertDI(!N.getName().empty(), "missing global variable name", &N);
  if (auto *V = N.getRawVariable()) {
    AssertDI(isa<ConstantAsMetadata>(V) &&
                 !isa<Function>(cast<ConstantAsMetadata>(V)->getValue()),
             "invalid global varaible ref", &N, V);
    visitConstantExprsRecursively(cast<ConstantAsMetadata>(V)->getValue());
  }
  if (auto *Member = N.getRawStaticDataMemberDeclaration()) {
    AssertDI(isa<DIDerivedType>(Member),
             "invalid static data member declaration", &N, Member);
  }
}

void Verifier::visitDILocalVariable(const DILocalVariable &N) {
  // Checks common to all variables.
  visitDIVariable(N);

  AssertDI(N.getTag() == dwarf::DW_TAG_variable, "invalid tag", &N);
  AssertDI(N.getRawScope() && isa<DILocalScope>(N.getRawScope()),
           "local variable requires a valid scope", &N, N.getRawScope());
}

void Verifier::visitDIExpression(const DIExpression &N) {
  AssertDI(N.isValid(), "invalid expression", &N);
}

void Verifier::visitDIObjCProperty(const DIObjCProperty &N) {
  AssertDI(N.getTag() == dwarf::DW_TAG_APPLE_property, "invalid tag", &N);
  if (auto *T = N.getRawType())
    AssertDI(isType(T), "invalid type ref", &N, T);
  if (auto *F = N.getRawFile())
    AssertDI(isa<DIFile>(F), "invalid file", &N, F);
}

void Verifier::visitDIImportedEntity(const DIImportedEntity &N) {
  AssertDI(N.getTag() == dwarf::DW_TAG_imported_module ||
               N.getTag() == dwarf::DW_TAG_imported_declaration,
           "invalid tag", &N);
  if (auto *S = N.getRawScope())
    AssertDI(isa<DIScope>(S), "invalid scope for imported entity", &N, S);
  AssertDI(isDINode(N.getRawEntity()), "invalid imported entity", &N,
           N.getRawEntity());
}

void Verifier::visitComdat(const Comdat &C) {
  // The Module is invalid if the GlobalValue has private linkage.  Entities
  // with private linkage don't have entries in the symbol table.
  if (const GlobalValue *GV = M->getNamedValue(C.getName()))
    Assert(!GV->hasPrivateLinkage(), "comdat global value has private linkage",
           GV);
}

void Verifier::visitModuleIdents(const Module &M) {
  const NamedMDNode *Idents = M.getNamedMetadata("llvm.ident");
  if (!Idents) 
    return;
  
  // llvm.ident takes a list of metadata entry. Each entry has only one string.
  // Scan each llvm.ident entry and make sure that this requirement is met.
  for (const MDNode *N : Idents->operands()) {
    Assert(N->getNumOperands() == 1,
           "incorrect number of operands in llvm.ident metadata", N);
    Assert(dyn_cast_or_null<MDString>(N->getOperand(0)),
           ("invalid value for llvm.ident metadata entry operand"
            "(the operand should be a string)"),
           N->getOperand(0));
  } 
}

void Verifier::visitModuleFlags(const Module &M) {
  const NamedMDNode *Flags = M.getModuleFlagsMetadata();
  if (!Flags) return;

  // Scan each flag, and track the flags and requirements.
  DenseMap<const MDString*, const MDNode*> SeenIDs;
  SmallVector<const MDNode*, 16> Requirements;
  for (const MDNode *MDN : Flags->operands())
    visitModuleFlag(MDN, SeenIDs, Requirements);

  // Validate that the requirements in the module are valid.
  for (const MDNode *Requirement : Requirements) {
    const MDString *Flag = cast<MDString>(Requirement->getOperand(0));
    const Metadata *ReqValue = Requirement->getOperand(1);

    const MDNode *Op = SeenIDs.lookup(Flag);
    if (!Op) {
      CheckFailed("invalid requirement on flag, flag is not present in module",
                  Flag);
      continue;
    }

    if (Op->getOperand(2) != ReqValue) {
      CheckFailed(("invalid requirement on flag, "
                   "flag does not have the required value"),
                  Flag);
      continue;
    }
  }
}

void
Verifier::visitModuleFlag(const MDNode *Op,
                          DenseMap<const MDString *, const MDNode *> &SeenIDs,
                          SmallVectorImpl<const MDNode *> &Requirements) {
  // Each module flag should have three arguments, the merge behavior (a
  // constant int), the flag ID (an MDString), and the value.
  Assert(Op->getNumOperands() == 3,
         "incorrect number of operands in module flag", Op);
  Module::ModFlagBehavior MFB;
  if (!Module::isValidModFlagBehavior(Op->getOperand(0), MFB)) {
    Assert(
        mdconst::dyn_extract_or_null<ConstantInt>(Op->getOperand(0)),
        "invalid behavior operand in module flag (expected constant integer)",
        Op->getOperand(0));
    Assert(false,
           "invalid behavior operand in module flag (unexpected constant)",
           Op->getOperand(0));
  }
  MDString *ID = dyn_cast_or_null<MDString>(Op->getOperand(1));
  Assert(ID, "invalid ID operand in module flag (expected metadata string)",
         Op->getOperand(1));

  // Sanity check the values for behaviors with additional requirements.
  switch (MFB) {
  case Module::Error:
  case Module::Warning:
  case Module::Override:
    // These behavior types accept any value.
    break;

  case Module::Require: {
    // The value should itself be an MDNode with two operands, a flag ID (an
    // MDString), and a value.
    MDNode *Value = dyn_cast<MDNode>(Op->getOperand(2));
    Assert(Value && Value->getNumOperands() == 2,
           "invalid value for 'require' module flag (expected metadata pair)",
           Op->getOperand(2));
    Assert(isa<MDString>(Value->getOperand(0)),
           ("invalid value for 'require' module flag "
            "(first value operand should be a string)"),
           Value->getOperand(0));

    // Append it to the list of requirements, to check once all module flags are
    // scanned.
    Requirements.push_back(Value);
    break;
  }

  case Module::Append:
  case Module::AppendUnique: {
    // These behavior types require the operand be an MDNode.
    Assert(isa<MDNode>(Op->getOperand(2)),
           "invalid value for 'append'-type module flag "
           "(expected a metadata node)",
           Op->getOperand(2));
    break;
  }
  }

  // Unless this is a "requires" flag, check the ID is unique.
  if (MFB != Module::Require) {
    bool Inserted = SeenIDs.insert(std::make_pair(ID, Op)).second;
    Assert(Inserted,
           "module flag identifiers must be unique (or of 'require' type)", ID);
  }
}

void Verifier::verifyAttributeTypes(AttributeSet Attrs, unsigned Idx,
                                    bool isFunction, const Value *V) {
  unsigned Slot = ~0U;
  for (unsigned I = 0, E = Attrs.getNumSlots(); I != E; ++I)
    if (Attrs.getSlotIndex(I) == Idx) {
      Slot = I;
      break;
    }

  assert(Slot != ~0U && "Attribute set inconsistency!");

  for (AttributeSet::iterator I = Attrs.begin(Slot), E = Attrs.end(Slot);
         I != E; ++I) {
    if (I->isStringAttribute())
      continue;

    if (I->getKindAsEnum() == Attribute::NoReturn ||
        I->getKindAsEnum() == Attribute::NoUnwind ||
        I->getKindAsEnum() == Attribute::NoInline ||
        I->getKindAsEnum() == Attribute::AlwaysInline ||
        I->getKindAsEnum() == Attribute::OptimizeForSize ||
        I->getKindAsEnum() == Attribute::StackProtect ||
        I->getKindAsEnum() == Attribute::StackProtectReq ||
        I->getKindAsEnum() == Attribute::StackProtectStrong ||
        I->getKindAsEnum() == Attribute::SafeStack ||
        I->getKindAsEnum() == Attribute::NoRedZone ||
        I->getKindAsEnum() == Attribute::NoImplicitFloat ||
        I->getKindAsEnum() == Attribute::Naked ||
        I->getKindAsEnum() == Attribute::InlineHint ||
        I->getKindAsEnum() == Attribute::StackAlignment ||
        I->getKindAsEnum() == Attribute::UWTable ||
        I->getKindAsEnum() == Attribute::NonLazyBind ||
        I->getKindAsEnum() == Attribute::ReturnsTwice ||
        I->getKindAsEnum() == Attribute::SanitizeAddress ||
        I->getKindAsEnum() == Attribute::SanitizeThread ||
        I->getKindAsEnum() == Attribute::SanitizeMemory ||
        I->getKindAsEnum() == Attribute::MinSize ||
        I->getKindAsEnum() == Attribute::NoDuplicate ||
        I->getKindAsEnum() == Attribute::Builtin ||
        I->getKindAsEnum() == Attribute::NoBuiltin ||
        I->getKindAsEnum() == Attribute::Cold ||
        I->getKindAsEnum() == Attribute::OptimizeNone ||
        I->getKindAsEnum() == Attribute::JumpTable ||
        I->getKindAsEnum() == Attribute::Convergent ||
        I->getKindAsEnum() == Attribute::ArgMemOnly ||
        I->getKindAsEnum() == Attribute::NoRecurse ||
        I->getKindAsEnum() == Attribute::InaccessibleMemOnly ||
        I->getKindAsEnum() == Attribute::InaccessibleMemOrArgMemOnly ||
        I->getKindAsEnum() == Attribute::AllocSize) {
      if (!isFunction) {
        CheckFailed("Attribute '" + I->getAsString() +
                    "' only applies to functions!", V);
        return;
      }
    } else if (I->getKindAsEnum() == Attribute::ReadOnly ||
               I->getKindAsEnum() == Attribute::WriteOnly ||
               I->getKindAsEnum() == Attribute::ReadNone) {
      if (Idx == 0) {
        CheckFailed("Attribute '" + I->getAsString() +
                    "' does not apply to function returns");
        return;
      }
    } else if (isFunction) {
      CheckFailed("Attribute '" + I->getAsString() +
                  "' does not apply to functions!", V);
      return;
    }
  }
}

// VerifyParameterAttrs - Check the given attributes for an argument or return
// value of the specified type.  The value V is printed in error messages.
void Verifier::verifyParameterAttrs(AttributeSet Attrs, unsigned Idx, Type *Ty,
                                    bool isReturnValue, const Value *V) {
  if (!Attrs.hasAttributes(Idx))
    return;

  verifyAttributeTypes(Attrs, Idx, false, V);

  if (isReturnValue)
    Assert(!Attrs.hasAttribute(Idx, Attribute::ByVal) &&
               !Attrs.hasAttribute(Idx, Attribute::Nest) &&
               !Attrs.hasAttribute(Idx, Attribute::StructRet) &&
               !Attrs.hasAttribute(Idx, Attribute::NoCapture) &&
               !Attrs.hasAttribute(Idx, Attribute::Returned) &&
               !Attrs.hasAttribute(Idx, Attribute::InAlloca) &&
               !Attrs.hasAttribute(Idx, Attribute::SwiftSelf) &&
               !Attrs.hasAttribute(Idx, Attribute::SwiftError),
           "Attributes 'byval', 'inalloca', 'nest', 'sret', 'nocapture', "
           "'returned', 'swiftself', and 'swifterror' do not apply to return "
           "values!",
           V);

  // Check for mutually incompatible attributes.  Only inreg is compatible with
  // sret.
  unsigned AttrCount = 0;
  AttrCount += Attrs.hasAttribute(Idx, Attribute::ByVal);
  AttrCount += Attrs.hasAttribute(Idx, Attribute::InAlloca);
  AttrCount += Attrs.hasAttribute(Idx, Attribute::StructRet) ||
               Attrs.hasAttribute(Idx, Attribute::InReg);
  AttrCount += Attrs.hasAttribute(Idx, Attribute::Nest);
  Assert(AttrCount <= 1, "Attributes 'byval', 'inalloca', 'inreg', 'nest', "
                         "and 'sret' are incompatible!",
         V);

  Assert(!(Attrs.hasAttribute(Idx, Attribute::InAlloca) &&
           Attrs.hasAttribute(Idx, Attribute::ReadOnly)),
         "Attributes "
         "'inalloca and readonly' are incompatible!",
         V);

  Assert(!(Attrs.hasAttribute(Idx, Attribute::StructRet) &&
           Attrs.hasAttribute(Idx, Attribute::Returned)),
         "Attributes "
         "'sret and returned' are incompatible!",
         V);

  Assert(!(Attrs.hasAttribute(Idx, Attribute::ZExt) &&
           Attrs.hasAttribute(Idx, Attribute::SExt)),
         "Attributes "
         "'zeroext and signext' are incompatible!",
         V);

  Assert(!(Attrs.hasAttribute(Idx, Attribute::ReadNone) &&
           Attrs.hasAttribute(Idx, Attribute::ReadOnly)),
         "Attributes "
         "'readnone and readonly' are incompatible!",
         V);

  Assert(!(Attrs.hasAttribute(Idx, Attribute::ReadNone) &&
           Attrs.hasAttribute(Idx, Attribute::WriteOnly)),
         "Attributes "
         "'readnone and writeonly' are incompatible!",
         V);

  Assert(!(Attrs.hasAttribute(Idx, Attribute::ReadOnly) &&
           Attrs.hasAttribute(Idx, Attribute::WriteOnly)),
         "Attributes "
         "'readonly and writeonly' are incompatible!",
         V);

  Assert(!(Attrs.hasAttribute(Idx, Attribute::NoInline) &&
           Attrs.hasAttribute(Idx, Attribute::AlwaysInline)),
         "Attributes "
         "'noinline and alwaysinline' are incompatible!",
         V);

  Assert(!AttrBuilder(Attrs, Idx)
              .overlaps(AttributeFuncs::typeIncompatible(Ty)),
         "Wrong types for attribute: " +
         AttributeSet::get(*Context, Idx,
                        AttributeFuncs::typeIncompatible(Ty)).getAsString(Idx),
         V);

  if (PointerType *PTy = dyn_cast<PointerType>(Ty)) {
    SmallPtrSet<Type*, 4> Visited;
    if (!PTy->getElementType()->isSized(&Visited)) {
      Assert(!Attrs.hasAttribute(Idx, Attribute::ByVal) &&
                 !Attrs.hasAttribute(Idx, Attribute::InAlloca),
             "Attributes 'byval' and 'inalloca' do not support unsized types!",
             V);
    }
    if (!isa<PointerType>(PTy->getElementType()))
      Assert(!Attrs.hasAttribute(Idx, Attribute::SwiftError),
             "Attribute 'swifterror' only applies to parameters "
             "with pointer to pointer type!",
             V);
  } else {
    Assert(!Attrs.hasAttribute(Idx, Attribute::ByVal),
           "Attribute 'byval' only applies to parameters with pointer type!",
           V);
    Assert(!Attrs.hasAttribute(Idx, Attribute::SwiftError),
           "Attribute 'swifterror' only applies to parameters "
           "with pointer type!",
           V);
  }
}

// Check parameter attributes against a function type.
// The value V is printed in error messages.
void Verifier::verifyFunctionAttrs(FunctionType *FT, AttributeSet Attrs,
                                   const Value *V) {
  if (Attrs.isEmpty())
    return;

  bool SawNest = false;
  bool SawReturned = false;
  bool SawSRet = false;
  bool SawSwiftSelf = false;
  bool SawSwiftError = false;

  for (unsigned i = 0, e = Attrs.getNumSlots(); i != e; ++i) {
    unsigned Idx = Attrs.getSlotIndex(i);

    Type *Ty;
    if (Idx == 0)
      Ty = FT->getReturnType();
    else if (Idx-1 < FT->getNumParams())
      Ty = FT->getParamType(Idx-1);
    else
      break;  // VarArgs attributes, verified elsewhere.

    verifyParameterAttrs(Attrs, Idx, Ty, Idx == 0, V);

    if (Idx == 0)
      continue;

    if (Attrs.hasAttribute(Idx, Attribute::Nest)) {
      Assert(!SawNest, "More than one parameter has attribute nest!", V);
      SawNest = true;
    }

    if (Attrs.hasAttribute(Idx, Attribute::Returned)) {
      Assert(!SawReturned, "More than one parameter has attribute returned!",
             V);
      Assert(Ty->canLosslesslyBitCastTo(FT->getReturnType()),
             "Incompatible "
             "argument and return types for 'returned' attribute",
             V);
      SawReturned = true;
    }

    if (Attrs.hasAttribute(Idx, Attribute::StructRet)) {
      Assert(!SawSRet, "Cannot have multiple 'sret' parameters!", V);
      Assert(Idx == 1 || Idx == 2,
             "Attribute 'sret' is not on first or second parameter!", V);
      SawSRet = true;
    }

    if (Attrs.hasAttribute(Idx, Attribute::SwiftSelf)) {
      Assert(!SawSwiftSelf, "Cannot have multiple 'swiftself' parameters!", V);
      SawSwiftSelf = true;
    }

    if (Attrs.hasAttribute(Idx, Attribute::SwiftError)) {
      Assert(!SawSwiftError, "Cannot have multiple 'swifterror' parameters!",
             V);
      SawSwiftError = true;
    }

    if (Attrs.hasAttribute(Idx, Attribute::InAlloca)) {
      Assert(Idx == FT->getNumParams(), "inalloca isn't on the last parameter!",
             V);
    }
  }

  if (!Attrs.hasAttributes(AttributeSet::FunctionIndex))
    return;

  verifyAttributeTypes(Attrs, AttributeSet::FunctionIndex, true, V);

  Assert(
      !(Attrs.hasAttribute(AttributeSet::FunctionIndex, Attribute::ReadNone) &&
        Attrs.hasAttribute(AttributeSet::FunctionIndex, Attribute::ReadOnly)),
      "Attributes 'readnone and readonly' are incompatible!", V);

  Assert(
      !(Attrs.hasAttribute(AttributeSet::FunctionIndex, Attribute::ReadNone) &&
        Attrs.hasAttribute(AttributeSet::FunctionIndex, Attribute::WriteOnly)),
      "Attributes 'readnone and writeonly' are incompatible!", V);

  Assert(
      !(Attrs.hasAttribute(AttributeSet::FunctionIndex, Attribute::ReadOnly) &&
        Attrs.hasAttribute(AttributeSet::FunctionIndex, Attribute::WriteOnly)),
      "Attributes 'readonly and writeonly' are incompatible!", V);

  Assert(
      !(Attrs.hasAttribute(AttributeSet::FunctionIndex, Attribute::ReadNone) &&
        Attrs.hasAttribute(AttributeSet::FunctionIndex, 
                           Attribute::InaccessibleMemOrArgMemOnly)),
      "Attributes 'readnone and inaccessiblemem_or_argmemonly' are incompatible!", V);

  Assert(
      !(Attrs.hasAttribute(AttributeSet::FunctionIndex, Attribute::ReadNone) &&
        Attrs.hasAttribute(AttributeSet::FunctionIndex, 
                           Attribute::InaccessibleMemOnly)),
      "Attributes 'readnone and inaccessiblememonly' are incompatible!", V);

  Assert(
      !(Attrs.hasAttribute(AttributeSet::FunctionIndex, Attribute::NoInline) &&
        Attrs.hasAttribute(AttributeSet::FunctionIndex,
                           Attribute::AlwaysInline)),
      "Attributes 'noinline and alwaysinline' are incompatible!", V);

  if (Attrs.hasAttribute(AttributeSet::FunctionIndex, 
                         Attribute::OptimizeNone)) {
    Assert(Attrs.hasAttribute(AttributeSet::FunctionIndex, Attribute::NoInline),
           "Attribute 'optnone' requires 'noinline'!", V);

    Assert(!Attrs.hasAttribute(AttributeSet::FunctionIndex,
                               Attribute::OptimizeForSize),
           "Attributes 'optsize and optnone' are incompatible!", V);

    Assert(!Attrs.hasAttribute(AttributeSet::FunctionIndex, Attribute::MinSize),
           "Attributes 'minsize and optnone' are incompatible!", V);
  }

  if (Attrs.hasAttribute(AttributeSet::FunctionIndex,
                         Attribute::JumpTable)) {
    const GlobalValue *GV = cast<GlobalValue>(V);
    Assert(GV->hasGlobalUnnamedAddr(),
           "Attribute 'jumptable' requires 'unnamed_addr'", V);
  }

  if (Attrs.hasAttribute(AttributeSet::FunctionIndex, Attribute::AllocSize)) {
    std::pair<unsigned, Optional<unsigned>> Args =
        Attrs.getAllocSizeArgs(AttributeSet::FunctionIndex);

    auto CheckParam = [&](StringRef Name, unsigned ParamNo) {
      if (ParamNo >= FT->getNumParams()) {
        CheckFailed("'allocsize' " + Name + " argument is out of bounds", V);
        return false;
      }

      if (!FT->getParamType(ParamNo)->isIntegerTy()) {
        CheckFailed("'allocsize' " + Name +
                        " argument must refer to an integer parameter",
                    V);
        return false;
      }

      return true;
    };

    if (!CheckParam("element size", Args.first))
      return;

    if (Args.second && !CheckParam("number of elements", *Args.second))
      return;
  }
}

void Verifier::verifyFunctionMetadata(
    ArrayRef<std::pair<unsigned, MDNode *>> MDs) {
  for (const auto &Pair : MDs) {
    if (Pair.first == LLVMContext::MD_prof) {
      MDNode *MD = Pair.second;
      Assert(MD->getNumOperands() == 2,
             "!prof annotations should have exactly 2 operands", MD);

      // Check first operand.
      Assert(MD->getOperand(0) != nullptr, "first operand should not be null",
             MD);
      Assert(isa<MDString>(MD->getOperand(0)),
             "expected string with name of the !prof annotation", MD);
      MDString *MDS = cast<MDString>(MD->getOperand(0));
      StringRef ProfName = MDS->getString();
      Assert(ProfName.equals("function_entry_count"),
             "first operand should be 'function_entry_count'", MD);

      // Check second operand.
      Assert(MD->getOperand(1) != nullptr, "second operand should not be null",
             MD);
      Assert(isa<ConstantAsMetadata>(MD->getOperand(1)),
             "expected integer argument to function_entry_count", MD);
    }
  }
}

void Verifier::visitConstantExprsRecursively(const Constant *EntryC) {
  if (!ConstantExprVisited.insert(EntryC).second)
    return;

  SmallVector<const Constant *, 16> Stack;
  Stack.push_back(EntryC);

  while (!Stack.empty()) {
    const Constant *C = Stack.pop_back_val();

    // Check this constant expression.
    if (const auto *CE = dyn_cast<ConstantExpr>(C))
      visitConstantExpr(CE);

    if (const auto *GV = dyn_cast<GlobalValue>(C)) {
      // Global Values get visited separately, but we do need to make sure
      // that the global value is in the correct module
      Assert(GV->getParent() == M, "Referencing global in another module!",
             EntryC, M, GV, GV->getParent());
      continue;
    }

    // Visit all sub-expressions.
    for (const Use &U : C->operands()) {
      const auto *OpC = dyn_cast<Constant>(U);
      if (!OpC)
        continue;
      if (!ConstantExprVisited.insert(OpC).second)
        continue;
      Stack.push_back(OpC);
    }
  }
}

void Verifier::visitConstantExpr(const ConstantExpr *CE) {
  if (CE->getOpcode() != Instruction::BitCast)
    return;

  Assert(CastInst::castIsValid(Instruction::BitCast, CE->getOperand(0),
                               CE->getType()),
         "Invalid bitcast", CE);
}

bool Verifier::verifyAttributeCount(AttributeSet Attrs, unsigned Params) {
  if (Attrs.getNumSlots() == 0)
    return true;

  unsigned LastSlot = Attrs.getNumSlots() - 1;
  unsigned LastIndex = Attrs.getSlotIndex(LastSlot);
  if (LastIndex <= Params
      || (LastIndex == AttributeSet::FunctionIndex
          && (LastSlot == 0 || Attrs.getSlotIndex(LastSlot - 1) <= Params)))
    return true;

  return false;
}

/// Verify that statepoint intrinsic is well formed.
void Verifier::verifyStatepoint(ImmutableCallSite CS) {
  assert(CS.getCalledFunction() &&
         CS.getCalledFunction()->getIntrinsicID() ==
           Intrinsic::experimental_gc_statepoint);

  const Instruction &CI = *CS.getInstruction();

  Assert(!CS.doesNotAccessMemory() && !CS.onlyReadsMemory() &&
         !CS.onlyAccessesArgMemory(),
         "gc.statepoint must read and write all memory to preserve "
         "reordering restrictions required by safepoint semantics",
         &CI);

  const Value *IDV = CS.getArgument(0);
  Assert(isa<ConstantInt>(IDV), "gc.statepoint ID must be a constant integer",
         &CI);

  const Value *NumPatchBytesV = CS.getArgument(1);
  Assert(isa<ConstantInt>(NumPatchBytesV),
         "gc.statepoint number of patchable bytes must be a constant integer",
         &CI);
  const int64_t NumPatchBytes =
      cast<ConstantInt>(NumPatchBytesV)->getSExtValue();
  assert(isInt<32>(NumPatchBytes) && "NumPatchBytesV is an i32!");
  Assert(NumPatchBytes >= 0, "gc.statepoint number of patchable bytes must be "
                             "positive",
         &CI);

  const Value *Target = CS.getArgument(2);
  auto *PT = dyn_cast<PointerType>(Target->getType());
  Assert(PT && PT->getElementType()->isFunctionTy(),
         "gc.statepoint callee must be of function pointer type", &CI, Target);
  FunctionType *TargetFuncType = cast<FunctionType>(PT->getElementType());

  const Value *NumCallArgsV = CS.getArgument(3);
  Assert(isa<ConstantInt>(NumCallArgsV),
         "gc.statepoint number of arguments to underlying call "
         "must be constant integer",
         &CI);
  const int NumCallArgs = cast<ConstantInt>(NumCallArgsV)->getZExtValue();
  Assert(NumCallArgs >= 0,
         "gc.statepoint number of arguments to underlying call "
         "must be positive",
         &CI);
  const int NumParams = (int)TargetFuncType->getNumParams();
  if (TargetFuncType->isVarArg()) {
    Assert(NumCallArgs >= NumParams,
           "gc.statepoint mismatch in number of vararg call args", &CI);

    // TODO: Remove this limitation
    Assert(TargetFuncType->getReturnType()->isVoidTy(),
           "gc.statepoint doesn't support wrapping non-void "
           "vararg functions yet",
           &CI);
  } else
    Assert(NumCallArgs == NumParams,
           "gc.statepoint mismatch in number of call args", &CI);

  const Value *FlagsV = CS.getArgument(4);
  Assert(isa<ConstantInt>(FlagsV),
         "gc.statepoint flags must be constant integer", &CI);
  const uint64_t Flags = cast<ConstantInt>(FlagsV)->getZExtValue();
  Assert((Flags & ~(uint64_t)StatepointFlags::MaskAll) == 0,
         "unknown flag used in gc.statepoint flags argument", &CI);

  // Verify that the types of the call parameter arguments match
  // the type of the wrapped callee.
  for (int i = 0; i < NumParams; i++) {
    Type *ParamType = TargetFuncType->getParamType(i);
    Type *ArgType = CS.getArgument(5 + i)->getType();
    Assert(ArgType == ParamType,
           "gc.statepoint call argument does not match wrapped "
           "function type",
           &CI);
  }

  const int EndCallArgsInx = 4 + NumCallArgs;

  const Value *NumTransitionArgsV = CS.getArgument(EndCallArgsInx+1);
  Assert(isa<ConstantInt>(NumTransitionArgsV),
         "gc.statepoint number of transition arguments "
         "must be constant integer",
         &CI);
  const int NumTransitionArgs =
      cast<ConstantInt>(NumTransitionArgsV)->getZExtValue();
  Assert(NumTransitionArgs >= 0,
         "gc.statepoint number of transition arguments must be positive", &CI);
  const int EndTransitionArgsInx = EndCallArgsInx + 1 + NumTransitionArgs;

  const Value *NumDeoptArgsV = CS.getArgument(EndTransitionArgsInx+1);
  Assert(isa<ConstantInt>(NumDeoptArgsV),
         "gc.statepoint number of deoptimization arguments "
         "must be constant integer",
         &CI);
  const int NumDeoptArgs = cast<ConstantInt>(NumDeoptArgsV)->getZExtValue();
  Assert(NumDeoptArgs >= 0, "gc.statepoint number of deoptimization arguments "
                            "must be positive",
         &CI);

  const int ExpectedNumArgs =
      7 + NumCallArgs + NumTransitionArgs + NumDeoptArgs;
  Assert(ExpectedNumArgs <= (int)CS.arg_size(),
         "gc.statepoint too few arguments according to length fields", &CI);

  // Check that the only uses of this gc.statepoint are gc.result or 
  // gc.relocate calls which are tied to this statepoint and thus part
  // of the same statepoint sequence
  for (const User *U : CI.users()) {
    const CallInst *Call = dyn_cast<const CallInst>(U);
    Assert(Call, "illegal use of statepoint token", &CI, U);
    if (!Call) continue;
    Assert(isa<GCRelocateInst>(Call) || isa<GCResultInst>(Call),
           "gc.result or gc.relocate are the only value uses"
           "of a gc.statepoint",
           &CI, U);
    if (isa<GCResultInst>(Call)) {
      Assert(Call->getArgOperand(0) == &CI,
             "gc.result connected to wrong gc.statepoint", &CI, Call);
    } else if (isa<GCRelocateInst>(Call)) {
      Assert(Call->getArgOperand(0) == &CI,
             "gc.relocate connected to wrong gc.statepoint", &CI, Call);
    }
  }

  // Note: It is legal for a single derived pointer to be listed multiple
  // times.  It's non-optimal, but it is legal.  It can also happen after
  // insertion if we strip a bitcast away.
  // Note: It is really tempting to check that each base is relocated and
  // that a derived pointer is never reused as a base pointer.  This turns
  // out to be problematic since optimizations run after safepoint insertion
  // can recognize equality properties that the insertion logic doesn't know
  // about.  See example statepoint.ll in the verifier subdirectory
}

void Verifier::verifyFrameRecoverIndices() {
  for (auto &Counts : FrameEscapeInfo) {
    Function *F = Counts.first;
    unsigned EscapedObjectCount = Counts.second.first;
    unsigned MaxRecoveredIndex = Counts.second.second;
    Assert(MaxRecoveredIndex <= EscapedObjectCount,
           "all indices passed to llvm.localrecover must be less than the "
           "number of arguments passed ot llvm.localescape in the parent "
           "function",
           F);
  }
}

static Instruction *getSuccPad(TerminatorInst *Terminator) {
  BasicBlock *UnwindDest;
  if (auto *II = dyn_cast<InvokeInst>(Terminator))
    UnwindDest = II->getUnwindDest();
  else if (auto *CSI = dyn_cast<CatchSwitchInst>(Terminator))
    UnwindDest = CSI->getUnwindDest();
  else
    UnwindDest = cast<CleanupReturnInst>(Terminator)->getUnwindDest();
  return UnwindDest->getFirstNonPHI();
}

void Verifier::verifySiblingFuncletUnwinds() {
  SmallPtrSet<Instruction *, 8> Visited;
  SmallPtrSet<Instruction *, 8> Active;
  for (const auto &Pair : SiblingFuncletInfo) {
    Instruction *PredPad = Pair.first;
    if (Visited.count(PredPad))
      continue;
    Active.insert(PredPad);
    TerminatorInst *Terminator = Pair.second;
    do {
      Instruction *SuccPad = getSuccPad(Terminator);
      if (Active.count(SuccPad)) {
        // Found a cycle; report error
        Instruction *CyclePad = SuccPad;
        SmallVector<Instruction *, 8> CycleNodes;
        do {
          CycleNodes.push_back(CyclePad);
          TerminatorInst *CycleTerminator = SiblingFuncletInfo[CyclePad];
          if (CycleTerminator != CyclePad)
            CycleNodes.push_back(CycleTerminator);
          CyclePad = getSuccPad(CycleTerminator);
        } while (CyclePad != SuccPad);
        Assert(false, "EH pads can't handle each other's exceptions",
               ArrayRef<Instruction *>(CycleNodes));
      }
      // Don't re-walk a node we've already checked
      if (!Visited.insert(SuccPad).second)
        break;
      // Walk to this successor if it has a map entry.
      PredPad = SuccPad;
      auto TermI = SiblingFuncletInfo.find(PredPad);
      if (TermI == SiblingFuncletInfo.end())
        break;
      Terminator = TermI->second;
      Active.insert(PredPad);
    } while (true);
    // Each node only has one successor, so we've walked all the active
    // nodes' successors.
    Active.clear();
  }
}

// visitFunction - Verify that a function is ok.
//
void Verifier::visitFunction(const Function &F) {
  visitGlobalValue(F);

  // Check function arguments.
  FunctionType *FT = F.getFunctionType();
  unsigned NumArgs = F.arg_size();

  Assert(Context == &F.getContext(),
         "Function context does not match Module context!", &F);

  Assert(!F.hasCommonLinkage(), "Functions may not have common linkage", &F);
  Assert(FT->getNumParams() == NumArgs,
         "# formal arguments must match # of arguments for function type!", &F,
         FT);
  Assert(F.getReturnType()->isFirstClassType() ||
             F.getReturnType()->isVoidTy() || F.getReturnType()->isStructTy(),
         "Functions cannot return aggregate values!", &F);

  Assert(!F.hasStructRetAttr() || F.getReturnType()->isVoidTy(),
         "Invalid struct return type!", &F);

  AttributeSet Attrs = F.getAttributes();

  Assert(verifyAttributeCount(Attrs, FT->getNumParams()),
         "Attribute after last parameter!", &F);

  // Check function attributes.
  verifyFunctionAttrs(FT, Attrs, &F);

  // On function declarations/definitions, we do not support the builtin
  // attribute. We do not check this in VerifyFunctionAttrs since that is
  // checking for Attributes that can/can not ever be on functions.
  Assert(!Attrs.hasAttribute(AttributeSet::FunctionIndex, Attribute::Builtin),
         "Attribute 'builtin' can only be applied to a callsite.", &F);

  // Check that this function meets the restrictions on this calling convention.
  // Sometimes varargs is used for perfectly forwarding thunks, so some of these
  // restrictions can be lifted.
  switch (F.getCallingConv()) {
  default:
  case CallingConv::C:
    break;
  case CallingConv::Fast:
  case CallingConv::Cold:
  case CallingConv::Intel_OCL_BI:
  case CallingConv::PTX_Kernel:
  case CallingConv::PTX_Device:
    Assert(!F.isVarArg(), "Calling convention does not support varargs or "
                          "perfect forwarding!",
           &F);
    break;
  }

  bool isLLVMdotName = F.getName().size() >= 5 &&
                       F.getName().substr(0, 5) == "llvm.";

  // Check that the argument values match the function type for this function...
  unsigned i = 0;
  for (const Argument &Arg : F.args()) {
    Assert(Arg.getType() == FT->getParamType(i),
           "Argument value does not match function argument type!", &Arg,
           FT->getParamType(i));
    Assert(Arg.getType()->isFirstClassType(),
           "Function arguments must have first-class types!", &Arg);
    if (!isLLVMdotName) {
      Assert(!Arg.getType()->isMetadataTy(),
             "Function takes metadata but isn't an intrinsic", &Arg, &F);
      Assert(!Arg.getType()->isTokenTy(),
             "Function takes token but isn't an intrinsic", &Arg, &F);
    }

    // Check that swifterror argument is only used by loads and stores.
    if (Attrs.hasAttribute(i+1, Attribute::SwiftError)) {
      verifySwiftErrorValue(&Arg);
    }
    ++i;
  }

  if (!isLLVMdotName)
    Assert(!F.getReturnType()->isTokenTy(),
           "Functions returns a token but isn't an intrinsic", &F);

  // Get the function metadata attachments.
  SmallVector<std::pair<unsigned, MDNode *>, 4> MDs;
  F.getAllMetadata(MDs);
  assert(F.hasMetadata() != MDs.empty() && "Bit out-of-sync");
  verifyFunctionMetadata(MDs);

  // Check validity of the personality function
  if (F.hasPersonalityFn()) {
    auto *Per = dyn_cast<Function>(F.getPersonalityFn()->stripPointerCasts());
    if (Per)
      Assert(Per->getParent() == F.getParent(),
             "Referencing personality function in another module!",
             &F, F.getParent(), Per, Per->getParent());
  }

  if (F.isMaterializable()) {
    // Function has a body somewhere we can't see.
    Assert(MDs.empty(), "unmaterialized function cannot have metadata", &F,
           MDs.empty() ? nullptr : MDs.front().second);
  } else if (F.isDeclaration()) {
    for (const auto &I : MDs) {
      AssertDI(I.first != LLVMContext::MD_dbg,
               "function declaration may not have a !dbg attachment", &F);
      Assert(I.first != LLVMContext::MD_prof,
             "function declaration may not have a !prof attachment", &F);

      // Verify the metadata itself.
      visitMDNode(*I.second);
    }
    Assert(!F.hasPersonalityFn(),
           "Function declaration shouldn't have a personality routine", &F);
  } else {
    // Verify that this function (which has a body) is not named "llvm.*".  It
    // is not legal to define intrinsics.
    Assert(!isLLVMdotName, "llvm intrinsics cannot be defined!", &F);

    // Check the entry node
    const BasicBlock *Entry = &F.getEntryBlock();
    Assert(pred_empty(Entry),
           "Entry block to function must not have predecessors!", Entry);

    // The address of the entry block cannot be taken, unless it is dead.
    if (Entry->hasAddressTaken()) {
      Assert(!BlockAddress::lookup(Entry)->isConstantUsed(),
             "blockaddress may not be used with the entry block!", Entry);
    }

    unsigned NumDebugAttachments = 0, NumProfAttachments = 0;
    // Visit metadata attachments.
    for (const auto &I : MDs) {
      // Verify that the attachment is legal.
      switch (I.first) {
      default:
        break;
      case LLVMContext::MD_dbg:
        ++NumDebugAttachments;
        AssertDI(NumDebugAttachments == 1,
                 "function must have a single !dbg attachment", &F, I.second);
        AssertDI(isa<DISubprogram>(I.second),
                 "function !dbg attachment must be a subprogram", &F, I.second);
        break;
      case LLVMContext::MD_prof:
        ++NumProfAttachments;
        Assert(NumProfAttachments == 1,
               "function must have a single !prof attachment", &F, I.second);
        break;
      }

      // Verify the metadata itself.
      visitMDNode(*I.second);
    }
  }

  // If this function is actually an intrinsic, verify that it is only used in
  // direct call/invokes, never having its "address taken".
  // Only do this if the module is materialized, otherwise we don't have all the
  // uses.
  if (F.getIntrinsicID() && F.getParent()->isMaterialized()) {
    const User *U;
    if (F.hasAddressTaken(&U))
      Assert(0, "Invalid user of intrinsic instruction!", U);
  }

  Assert(!F.hasDLLImportStorageClass() ||
             (F.isDeclaration() && F.hasExternalLinkage()) ||
             F.hasAvailableExternallyLinkage(),
         "Function is marked as dllimport, but not external.", &F);

  auto *N = F.getSubprogram();
  if (!N)
    return;

  visitDISubprogram(*N);

  // Check that all !dbg attachments lead to back to N (or, at least, another
  // subprogram that describes the same function).
  //
  // FIXME: Check this incrementally while visiting !dbg attachments.
  // FIXME: Only check when N is the canonical subprogram for F.
  SmallPtrSet<const MDNode *, 32> Seen;
  for (auto &BB : F)
    for (auto &I : BB) {
      // Be careful about using DILocation here since we might be dealing with
      // broken code (this is the Verifier after all).
      DILocation *DL =
          dyn_cast_or_null<DILocation>(I.getDebugLoc().getAsMDNode());
      if (!DL)
        continue;
      if (!Seen.insert(DL).second)
        continue;

      DILocalScope *Scope = DL->getInlinedAtScope();
      if (Scope && !Seen.insert(Scope).second)
        continue;

      DISubprogram *SP = Scope ? Scope->getSubprogram() : nullptr;

      // Scope and SP could be the same MDNode and we don't want to skip
      // validation in that case
      if (SP && ((Scope != SP) && !Seen.insert(SP).second))
        continue;

      // FIXME: Once N is canonical, check "SP == &N".
      Assert(SP->describes(&F),
             "!dbg attachment points at wrong subprogram for function", N, &F,
             &I, DL, Scope, SP);
    }
}

// verifyBasicBlock - Verify that a basic block is well formed...
//
void Verifier::visitBasicBlock(BasicBlock &BB) {
  InstsInThisBlock.clear();

  // Ensure that basic blocks have terminators!
  Assert(BB.getTerminator(), "Basic Block does not have terminator!", &BB);

  // Check constraints that this basic block imposes on all of the PHI nodes in
  // it.
  if (isa<PHINode>(BB.front())) {
    SmallVector<BasicBlock*, 8> Preds(pred_begin(&BB), pred_end(&BB));
    SmallVector<std::pair<BasicBlock*, Value*>, 8> Values;
    std::sort(Preds.begin(), Preds.end());
    PHINode *PN;
    for (BasicBlock::iterator I = BB.begin(); (PN = dyn_cast<PHINode>(I));++I) {
      // Ensure that PHI nodes have at least one entry!
      Assert(PN->getNumIncomingValues() != 0,
             "PHI nodes must have at least one entry.  If the block is dead, "
             "the PHI should be removed!",
             PN);
      Assert(PN->getNumIncomingValues() == Preds.size(),
             "PHINode should have one entry for each predecessor of its "
             "parent basic block!",
             PN);

      // Get and sort all incoming values in the PHI node...
      Values.clear();
      Values.reserve(PN->getNumIncomingValues());
      for (unsigned i = 0, e = PN->getNumIncomingValues(); i != e; ++i)
        Values.push_back(std::make_pair(PN->getIncomingBlock(i),
                                        PN->getIncomingValue(i)));
      std::sort(Values.begin(), Values.end());

      for (unsigned i = 0, e = Values.size(); i != e; ++i) {
        // Check to make sure that if there is more than one entry for a
        // particular basic block in this PHI node, that the incoming values are
        // all identical.
        //
        Assert(i == 0 || Values[i].first != Values[i - 1].first ||
                   Values[i].second == Values[i - 1].second,
               "PHI node has multiple entries for the same basic block with "
               "different incoming values!",
               PN, Values[i].first, Values[i].second, Values[i - 1].second);

        // Check to make sure that the predecessors and PHI node entries are
        // matched up.
        Assert(Values[i].first == Preds[i],
               "PHI node entries do not match predecessors!", PN,
               Values[i].first, Preds[i]);
      }
    }
  }

  // Check that all instructions have their parent pointers set up correctly.
  for (auto &I : BB)
  {
    Assert(I.getParent() == &BB, "Instruction has bogus parent pointer!");
  }
}

void Verifier::visitTerminatorInst(TerminatorInst &I) {
  // Ensure that terminators only exist at the end of the basic block.
  Assert(&I == I.getParent()->getTerminator(),
         "Terminator found in the middle of a basic block!", I.getParent());
  visitInstruction(I);
}

void Verifier::visitBranchInst(BranchInst &BI) {
  if (BI.isConditional()) {
    Assert(BI.getCondition()->getType()->isIntegerTy(1),
           "Branch condition is not 'i1' type!", &BI, BI.getCondition());
  }
  visitTerminatorInst(BI);
}

void Verifier::visitReturnInst(ReturnInst &RI) {
  Function *F = RI.getParent()->getParent();
  unsigned N = RI.getNumOperands();
  if (F->getReturnType()->isVoidTy())
    Assert(N == 0,
           "Found return instr that returns non-void in Function of void "
           "return type!",
           &RI, F->getReturnType());
  else
    Assert(N == 1 && F->getReturnType() == RI.getOperand(0)->getType(),
           "Function return type does not match operand "
           "type of return inst!",
           &RI, F->getReturnType());

  // Check to make sure that the return value has necessary properties for
  // terminators...
  visitTerminatorInst(RI);
}

void Verifier::visitSwitchInst(SwitchInst &SI) {
  // Check to make sure that all of the constants in the switch instruction
  // have the same type as the switched-on value.
  Type *SwitchTy = SI.getCondition()->getType();
  SmallPtrSet<ConstantInt*, 32> Constants;
  for (auto &Case : SI.cases()) {
    Assert(Case.getCaseValue()->getType() == SwitchTy,
           "Switch constants must all be same type as switch value!", &SI);
    Assert(Constants.insert(Case.getCaseValue()).second,
           "Duplicate integer as switch case", &SI, Case.getCaseValue());
  }

  visitTerminatorInst(SI);
}

void Verifier::visitIndirectBrInst(IndirectBrInst &BI) {
  Assert(BI.getAddress()->getType()->isPointerTy(),
         "Indirectbr operand must have pointer type!", &BI);
  for (unsigned i = 0, e = BI.getNumDestinations(); i != e; ++i)
    Assert(BI.getDestination(i)->getType()->isLabelTy(),
           "Indirectbr destinations must all have pointer type!", &BI);

  visitTerminatorInst(BI);
}

void Verifier::visitSelectInst(SelectInst &SI) {
  Assert(!SelectInst::areInvalidOperands(SI.getOperand(0), SI.getOperand(1),
                                         SI.getOperand(2)),
         "Invalid operands for select instruction!", &SI);

  Assert(SI.getTrueValue()->getType() == SI.getType(),
         "Select values must have same type as select instruction!", &SI);
  visitInstruction(SI);
}

/// visitUserOp1 - User defined operators shouldn't live beyond the lifetime of
/// a pass, if any exist, it's an error.
///
void Verifier::visitUserOp1(Instruction &I) {
  Assert(0, "User-defined operators should not live outside of a pass!", &I);
}

void Verifier::visitTruncInst(TruncInst &I) {
  // Get the source and destination types
  Type *SrcTy = I.getOperand(0)->getType();
  Type *DestTy = I.getType();

  // Get the size of the types in bits, we'll need this later
  unsigned SrcBitSize = SrcTy->getScalarSizeInBits();
  unsigned DestBitSize = DestTy->getScalarSizeInBits();

  Assert(SrcTy->isIntOrIntVectorTy(), "Trunc only operates on integer", &I);
  Assert(DestTy->isIntOrIntVectorTy(), "Trunc only produces integer", &I);
  Assert(SrcTy->isVectorTy() == DestTy->isVectorTy(),
         "trunc source and destination must both be a vector or neither", &I);
  Assert(SrcBitSize > DestBitSize, "DestTy too big for Trunc", &I);

  visitInstruction(I);
}

void Verifier::visitZExtInst(ZExtInst &I) {
  // Get the source and destination types
  Type *SrcTy = I.getOperand(0)->getType();
  Type *DestTy = I.getType();

  // Get the size of the types in bits, we'll need this later
  Assert(SrcTy->isIntOrIntVectorTy(), "ZExt only operates on integer", &I);
  Assert(DestTy->isIntOrIntVectorTy(), "ZExt only produces an integer", &I);
  Assert(SrcTy->isVectorTy() == DestTy->isVectorTy(),
         "zext source and destination must both be a vector or neither", &I);
  unsigned SrcBitSize = SrcTy->getScalarSizeInBits();
  unsigned DestBitSize = DestTy->getScalarSizeInBits();

  Assert(SrcBitSize < DestBitSize, "Type too small for ZExt", &I);

  visitInstruction(I);
}

void Verifier::visitSExtInst(SExtInst &I) {
  // Get the source and destination types
  Type *SrcTy = I.getOperand(0)->getType();
  Type *DestTy = I.getType();

  // Get the size of the types in bits, we'll need this later
  unsigned SrcBitSize = SrcTy->getScalarSizeInBits();
  unsigned DestBitSize = DestTy->getScalarSizeInBits();

  Assert(SrcTy->isIntOrIntVectorTy(), "SExt only operates on integer", &I);
  Assert(DestTy->isIntOrIntVectorTy(), "SExt only produces an integer", &I);
  Assert(SrcTy->isVectorTy() == DestTy->isVectorTy(),
         "sext source and destination must both be a vector or neither", &I);
  Assert(SrcBitSize < DestBitSize, "Type too small for SExt", &I);

  visitInstruction(I);
}

void Verifier::visitFPTruncInst(FPTruncInst &I) {
  // Get the source and destination types
  Type *SrcTy = I.getOperand(0)->getType();
  Type *DestTy = I.getType();
  // Get the size of the types in bits, we'll need this later
  unsigned SrcBitSize = SrcTy->getScalarSizeInBits();
  unsigned DestBitSize = DestTy->getScalarSizeInBits();

  Assert(SrcTy->isFPOrFPVectorTy(), "FPTrunc only operates on FP", &I);
  Assert(DestTy->isFPOrFPVectorTy(), "FPTrunc only produces an FP", &I);
  Assert(SrcTy->isVectorTy() == DestTy->isVectorTy(),
         "fptrunc source and destination must both be a vector or neither", &I);
  Assert(SrcBitSize > DestBitSize, "DestTy too big for FPTrunc", &I);

  visitInstruction(I);
}

void Verifier::visitFPExtInst(FPExtInst &I) {
  // Get the source and destination types
  Type *SrcTy = I.getOperand(0)->getType();
  Type *DestTy = I.getType();

  // Get the size of the types in bits, we'll need this later
  unsigned SrcBitSize = SrcTy->getScalarSizeInBits();
  unsigned DestBitSize = DestTy->getScalarSizeInBits();

  Assert(SrcTy->isFPOrFPVectorTy(), "FPExt only operates on FP", &I);
  Assert(DestTy->isFPOrFPVectorTy(), "FPExt only produces an FP", &I);
  Assert(SrcTy->isVectorTy() == DestTy->isVectorTy(),
         "fpext source and destination must both be a vector or neither", &I);
  Assert(SrcBitSize < DestBitSize, "DestTy too small for FPExt", &I);

  visitInstruction(I);
}

void Verifier::visitUIToFPInst(UIToFPInst &I) {
  // Get the source and destination types
  Type *SrcTy = I.getOperand(0)->getType();
  Type *DestTy = I.getType();

  bool SrcVec = SrcTy->isVectorTy();
  bool DstVec = DestTy->isVectorTy();

  Assert(SrcVec == DstVec,
         "UIToFP source and dest must both be vector or scalar", &I);
  Assert(SrcTy->isIntOrIntVectorTy(),
         "UIToFP source must be integer or integer vector", &I);
  Assert(DestTy->isFPOrFPVectorTy(), "UIToFP result must be FP or FP vector",
         &I);

  if (SrcVec && DstVec)
    Assert(cast<VectorType>(SrcTy)->getNumElements() ==
               cast<VectorType>(DestTy)->getNumElements(),
           "UIToFP source and dest vector length mismatch", &I);

  visitInstruction(I);
}

void Verifier::visitSIToFPInst(SIToFPInst &I) {
  // Get the source and destination types
  Type *SrcTy = I.getOperand(0)->getType();
  Type *DestTy = I.getType();

  bool SrcVec = SrcTy->isVectorTy();
  bool DstVec = DestTy->isVectorTy();

  Assert(SrcVec == DstVec,
         "SIToFP source and dest must both be vector or scalar", &I);
  Assert(SrcTy->isIntOrIntVectorTy(),
         "SIToFP source must be integer or integer vector", &I);
  Assert(DestTy->isFPOrFPVectorTy(), "SIToFP result must be FP or FP vector",
         &I);

  if (SrcVec && DstVec)
    Assert(cast<VectorType>(SrcTy)->getNumElements() ==
               cast<VectorType>(DestTy)->getNumElements(),
           "SIToFP source and dest vector length mismatch", &I);

  visitInstruction(I);
}

void Verifier::visitFPToUIInst(FPToUIInst &I) {
  // Get the source and destination types
  Type *SrcTy = I.getOperand(0)->getType();
  Type *DestTy = I.getType();

  bool SrcVec = SrcTy->isVectorTy();
  bool DstVec = DestTy->isVectorTy();

  Assert(SrcVec == DstVec,
         "FPToUI source and dest must both be vector or scalar", &I);
  Assert(SrcTy->isFPOrFPVectorTy(), "FPToUI source must be FP or FP vector",
         &I);
  Assert(DestTy->isIntOrIntVectorTy(),
         "FPToUI result must be integer or integer vector", &I);

  if (SrcVec && DstVec)
    Assert(cast<VectorType>(SrcTy)->getNumElements() ==
               cast<VectorType>(DestTy)->getNumElements(),
           "FPToUI source and dest vector length mismatch", &I);

  visitInstruction(I);
}

void Verifier::visitFPToSIInst(FPToSIInst &I) {
  // Get the source and destination types
  Type *SrcTy = I.getOperand(0)->getType();
  Type *DestTy = I.getType();

  bool SrcVec = SrcTy->isVectorTy();
  bool DstVec = DestTy->isVectorTy();

  Assert(SrcVec == DstVec,
         "FPToSI source and dest must both be vector or scalar", &I);
  Assert(SrcTy->isFPOrFPVectorTy(), "FPToSI source must be FP or FP vector",
         &I);
  Assert(DestTy->isIntOrIntVectorTy(),
         "FPToSI result must be integer or integer vector", &I);

  if (SrcVec && DstVec)
    Assert(cast<VectorType>(SrcTy)->getNumElements() ==
               cast<VectorType>(DestTy)->getNumElements(),
           "FPToSI source and dest vector length mismatch", &I);

  visitInstruction(I);
}

void Verifier::visitPtrToIntInst(PtrToIntInst &I) {
  // Get the source and destination types
  Type *SrcTy = I.getOperand(0)->getType();
  Type *DestTy = I.getType();

  Assert(SrcTy->getScalarType()->isPointerTy(),
         "PtrToInt source must be pointer", &I);

  if (auto *PTy = dyn_cast<PointerType>(SrcTy->getScalarType()))
    Assert(!M->getDataLayout().isNonIntegralPointerType(PTy),
           "ptrtoint not supported for non-integral pointers");

  Assert(DestTy->getScalarType()->isIntegerTy(),
         "PtrToInt result must be integral", &I);
  Assert(SrcTy->isVectorTy() == DestTy->isVectorTy(), "PtrToInt type mismatch",
         &I);

  if (SrcTy->isVectorTy()) {
    VectorType *VSrc = dyn_cast<VectorType>(SrcTy);
    VectorType *VDest = dyn_cast<VectorType>(DestTy);
    Assert(VSrc->getNumElements() == VDest->getNumElements(),
           "PtrToInt Vector width mismatch", &I);
  }

  visitInstruction(I);
}

void Verifier::visitIntToPtrInst(IntToPtrInst &I) {
  // Get the source and destination types
  Type *SrcTy = I.getOperand(0)->getType();
  Type *DestTy = I.getType();

  Assert(SrcTy->getScalarType()->isIntegerTy(),
         "IntToPtr source must be an integral", &I);
  Assert(DestTy->getScalarType()->isPointerTy(),
         "IntToPtr result must be a pointer", &I);

  if (auto *PTy = dyn_cast<PointerType>(DestTy->getScalarType()))
    Assert(!M->getDataLayout().isNonIntegralPointerType(PTy),
           "inttoptr not supported for non-integral pointers");

  Assert(SrcTy->isVectorTy() == DestTy->isVectorTy(), "IntToPtr type mismatch",
         &I);
  if (SrcTy->isVectorTy()) {
    VectorType *VSrc = dyn_cast<VectorType>(SrcTy);
    VectorType *VDest = dyn_cast<VectorType>(DestTy);
    Assert(VSrc->getNumElements() == VDest->getNumElements(),
           "IntToPtr Vector width mismatch", &I);
  }
  visitInstruction(I);
}

void Verifier::visitBitCastInst(BitCastInst &I) {
  Assert(
      CastInst::castIsValid(Instruction::BitCast, I.getOperand(0), I.getType()),
      "Invalid bitcast", &I);
  visitInstruction(I);
}

void Verifier::visitAddrSpaceCastInst(AddrSpaceCastInst &I) {
  Type *SrcTy = I.getOperand(0)->getType();
  Type *DestTy = I.getType();

  Assert(SrcTy->isPtrOrPtrVectorTy(), "AddrSpaceCast source must be a pointer",
         &I);
  Assert(DestTy->isPtrOrPtrVectorTy(), "AddrSpaceCast result must be a pointer",
         &I);
  Assert(SrcTy->getPointerAddressSpace() != DestTy->getPointerAddressSpace(),
         "AddrSpaceCast must be between different address spaces", &I);
  if (SrcTy->isVectorTy())
    Assert(SrcTy->getVectorNumElements() == DestTy->getVectorNumElements(),
           "AddrSpaceCast vector pointer number of elements mismatch", &I);
  visitInstruction(I);
}

/// visitPHINode - Ensure that a PHI node is well formed.
///
void Verifier::visitPHINode(PHINode &PN) {
  // Ensure that the PHI nodes are all grouped together at the top of the block.
  // This can be tested by checking whether the instruction before this is
  // either nonexistent (because this is begin()) or is a PHI node.  If not,
  // then there is some other instruction before a PHI.
  Assert(&PN == &PN.getParent()->front() ||
             isa<PHINode>(--BasicBlock::iterator(&PN)),
         "PHI nodes not grouped at top of basic block!", &PN, PN.getParent());

  // Check that a PHI doesn't yield a Token.
  Assert(!PN.getType()->isTokenTy(), "PHI nodes cannot have token type!");

  // Check that all of the values of the PHI node have the same type as the
  // result, and that the incoming blocks are really basic blocks.
  for (Value *IncValue : PN.incoming_values()) {
    Assert(PN.getType() == IncValue->getType(),
           "PHI node operands are not the same type as the result!", &PN);
  }

  // All other PHI node constraints are checked in the visitBasicBlock method.

  visitInstruction(PN);
}

void Verifier::verifyCallSite(CallSite CS) {
  Instruction *I = CS.getInstruction();

  Assert(CS.getCalledValue()->getType()->isPointerTy(),
         "Called function must be a pointer!", I);
  PointerType *FPTy = cast<PointerType>(CS.getCalledValue()->getType());

  Assert(FPTy->getElementType()->isFunctionTy(),
         "Called function is not pointer to function type!", I);

  Assert(FPTy->getElementType() == CS.getFunctionType(),
         "Called function is not the same type as the call!", I);

  FunctionType *FTy = CS.getFunctionType();

  // Verify that the correct number of arguments are being passed
  if (FTy->isVarArg())
    Assert(CS.arg_size() >= FTy->getNumParams(),
           "Called function requires more parameters than were provided!", I);
  else
    Assert(CS.arg_size() == FTy->getNumParams(),
           "Incorrect number of arguments passed to called function!", I);

  // Verify that all arguments to the call match the function type.
  for (unsigned i = 0, e = FTy->getNumParams(); i != e; ++i)
    Assert(CS.getArgument(i)->getType() == FTy->getParamType(i),
           "Call parameter type does not match function signature!",
           CS.getArgument(i), FTy->getParamType(i), I);

  AttributeSet Attrs = CS.getAttributes();

  Assert(verifyAttributeCount(Attrs, CS.arg_size()),
         "Attribute after last parameter!", I);

  // Verify call attributes.
  verifyFunctionAttrs(FTy, Attrs, I);

  // Conservatively check the inalloca argument.
  // We have a bug if we can find that there is an underlying alloca without
  // inalloca.
  if (CS.hasInAllocaArgument()) {
    Value *InAllocaArg = CS.getArgument(FTy->getNumParams() - 1);
    if (auto AI = dyn_cast<AllocaInst>(InAllocaArg->stripInBoundsOffsets()))
      Assert(AI->isUsedWithInAlloca(),
             "inalloca argument for call has mismatched alloca", AI, I);
  }

  // For each argument of the callsite, if it has the swifterror argument,
  // make sure the underlying alloca has swifterror as well.
  for (unsigned i = 0, e = FTy->getNumParams(); i != e; ++i)
    if (CS.paramHasAttr(i+1, Attribute::SwiftError)) {
      Value *SwiftErrorArg = CS.getArgument(i);
      auto AI = dyn_cast<AllocaInst>(SwiftErrorArg->stripInBoundsOffsets());
      Assert(AI, "swifterror argument should come from alloca", AI, I);
      if (AI)
        Assert(AI->isSwiftError(),
               "swifterror argument for call has mismatched alloca", AI, I);
    }

  if (FTy->isVarArg()) {
    // FIXME? is 'nest' even legal here?
    bool SawNest = false;
    bool SawReturned = false;

    for (unsigned Idx = 1; Idx < 1 + FTy->getNumParams(); ++Idx) {
      if (Attrs.hasAttribute(Idx, Attribute::Nest))
        SawNest = true;
      if (Attrs.hasAttribute(Idx, Attribute::Returned))
        SawReturned = true;
    }

    // Check attributes on the varargs part.
    for (unsigned Idx = 1 + FTy->getNumParams(); Idx <= CS.arg_size(); ++Idx) {
      Type *Ty = CS.getArgument(Idx-1)->getType();
      verifyParameterAttrs(Attrs, Idx, Ty, false, I);

      if (Attrs.hasAttribute(Idx, Attribute::Nest)) {
        Assert(!SawNest, "More than one parameter has attribute nest!", I);
        SawNest = true;
      }

      if (Attrs.hasAttribute(Idx, Attribute::Returned)) {
        Assert(!SawReturned, "More than one parameter has attribute returned!",
               I);
        Assert(Ty->canLosslesslyBitCastTo(FTy->getReturnType()),
               "Incompatible argument and return types for 'returned' "
               "attribute",
               I);
        SawReturned = true;
      }

      Assert(!Attrs.hasAttribute(Idx, Attribute::StructRet),
             "Attribute 'sret' cannot be used for vararg call arguments!", I);

      if (Attrs.hasAttribute(Idx, Attribute::InAlloca))
        Assert(Idx == CS.arg_size(), "inalloca isn't on the last argument!", I);
    }
  }

  // Verify that there's no metadata unless it's a direct call to an intrinsic.
  if (CS.getCalledFunction() == nullptr ||
      !CS.getCalledFunction()->getName().startswith("llvm.")) {
    for (Type *ParamTy : FTy->params()) {
      Assert(!ParamTy->isMetadataTy(),
             "Function has metadata parameter but isn't an intrinsic", I);
      Assert(!ParamTy->isTokenTy(),
             "Function has token parameter but isn't an intrinsic", I);
    }
  }

  // Verify that indirect calls don't return tokens.
  if (CS.getCalledFunction() == nullptr)
    Assert(!FTy->getReturnType()->isTokenTy(),
           "Return type cannot be token for indirect call!");

  if (Function *F = CS.getCalledFunction())
    if (Intrinsic::ID ID = (Intrinsic::ID)F->getIntrinsicID())
      visitIntrinsicCallSite(ID, CS);

  // Verify that a callsite has at most one "deopt", at most one "funclet" and
  // at most one "gc-transition" operand bundle.
  bool FoundDeoptBundle = false, FoundFuncletBundle = false,
       FoundGCTransitionBundle = false;
  for (unsigned i = 0, e = CS.getNumOperandBundles(); i < e; ++i) {
    OperandBundleUse BU = CS.getOperandBundleAt(i);
    uint32_t Tag = BU.getTagID();
    if (Tag == LLVMContext::OB_deopt) {
      Assert(!FoundDeoptBundle, "Multiple deopt operand bundles", I);
      FoundDeoptBundle = true;
    } else if (Tag == LLVMContext::OB_gc_transition) {
      Assert(!FoundGCTransitionBundle, "Multiple gc-transition operand bundles",
             I);
      FoundGCTransitionBundle = true;
    } else if (Tag == LLVMContext::OB_funclet) {
      Assert(!FoundFuncletBundle, "Multiple funclet operand bundles", I);
      FoundFuncletBundle = true;
      Assert(BU.Inputs.size() == 1,
             "Expected exactly one funclet bundle operand", I);
      Assert(isa<FuncletPadInst>(BU.Inputs.front()),
             "Funclet bundle operands should correspond to a FuncletPadInst",
             I);
    }
  }

  // Verify that each inlinable callsite of a debug-info-bearing function in a
  // debug-info-bearing function has a debug location attached to it. Failure to
  // do so causes assertion failures when the inliner sets up inline scope info.
  if (I->getFunction()->getSubprogram() && CS.getCalledFunction() &&
      CS.getCalledFunction()->getSubprogram())
    Assert(I->getDebugLoc(), "inlinable function call in a function with debug "
                             "info must have a !dbg location",
           I);

  visitInstruction(*I);
}

/// Two types are "congruent" if they are identical, or if they are both pointer
/// types with different pointee types and the same address space.
static bool isTypeCongruent(Type *L, Type *R) {
  if (L == R)
    return true;
  PointerType *PL = dyn_cast<PointerType>(L);
  PointerType *PR = dyn_cast<PointerType>(R);
  if (!PL || !PR)
    return false;
  return PL->getAddressSpace() == PR->getAddressSpace();
}

static AttrBuilder getParameterABIAttributes(int I, AttributeSet Attrs) {
  static const Attribute::AttrKind ABIAttrs[] = {
      Attribute::StructRet, Attribute::ByVal, Attribute::InAlloca,
      Attribute::InReg, Attribute::Returned, Attribute::SwiftSelf,
      Attribute::SwiftError};
  AttrBuilder Copy;
  for (auto AK : ABIAttrs) {
    if (Attrs.hasAttribute(I + 1, AK))
      Copy.addAttribute(AK);
  }
  if (Attrs.hasAttribute(I + 1, Attribute::Alignment))
    Copy.addAlignmentAttr(Attrs.getParamAlignment(I + 1));
  return Copy;
}

void Verifier::verifyMustTailCall(CallInst &CI) {
  Assert(!CI.isInlineAsm(), "cannot use musttail call with inline asm", &CI);

  // - The caller and callee prototypes must match.  Pointer types of
  //   parameters or return types may differ in pointee type, but not
  //   address space.
  Function *F = CI.getParent()->getParent();
  FunctionType *CallerTy = F->getFunctionType();
  FunctionType *CalleeTy = CI.getFunctionType();
  Assert(CallerTy->getNumParams() == CalleeTy->getNumParams(),
         "cannot guarantee tail call due to mismatched parameter counts", &CI);
  Assert(CallerTy->isVarArg() == CalleeTy->isVarArg(),
         "cannot guarantee tail call due to mismatched varargs", &CI);
  Assert(isTypeCongruent(CallerTy->getReturnType(), CalleeTy->getReturnType()),
         "cannot guarantee tail call due to mismatched return types", &CI);
  for (int I = 0, E = CallerTy->getNumParams(); I != E; ++I) {
    Assert(
        isTypeCongruent(CallerTy->getParamType(I), CalleeTy->getParamType(I)),
        "cannot guarantee tail call due to mismatched parameter types", &CI);
  }

  // - The calling conventions of the caller and callee must match.
  Assert(F->getCallingConv() == CI.getCallingConv(),
         "cannot guarantee tail call due to mismatched calling conv", &CI);

  // - All ABI-impacting function attributes, such as sret, byval, inreg,
  //   returned, and inalloca, must match.
  AttributeSet CallerAttrs = F->getAttributes();
  AttributeSet CalleeAttrs = CI.getAttributes();
  for (int I = 0, E = CallerTy->getNumParams(); I != E; ++I) {
    AttrBuilder CallerABIAttrs = getParameterABIAttributes(I, CallerAttrs);
    AttrBuilder CalleeABIAttrs = getParameterABIAttributes(I, CalleeAttrs);
    Assert(CallerABIAttrs == CalleeABIAttrs,
           "cannot guarantee tail call due to mismatched ABI impacting "
           "function attributes",
           &CI, CI.getOperand(I));
  }

  // - The call must immediately precede a :ref:`ret <i_ret>` instruction,
  //   or a pointer bitcast followed by a ret instruction.
  // - The ret instruction must return the (possibly bitcasted) value
  //   produced by the call or void.
  Value *RetVal = &CI;
  Instruction *Next = CI.getNextNode();

  // Handle the optional bitcast.
  if (BitCastInst *BI = dyn_cast_or_null<BitCastInst>(Next)) {
    Assert(BI->getOperand(0) == RetVal,
           "bitcast following musttail call must use the call", BI);
    RetVal = BI;
    Next = BI->getNextNode();
  }

  // Check the return.
  ReturnInst *Ret = dyn_cast_or_null<ReturnInst>(Next);
  Assert(Ret, "musttail call must be precede a ret with an optional bitcast",
         &CI);
  Assert(!Ret->getReturnValue() || Ret->getReturnValue() == RetVal,
         "musttail call result must be returned", Ret);
}

void Verifier::visitCallInst(CallInst &CI) {
  verifyCallSite(&CI);

  if (CI.isMustTailCall())
    verifyMustTailCall(CI);
}

void Verifier::visitInvokeInst(InvokeInst &II) {
  verifyCallSite(&II);

  // Verify that the first non-PHI instruction of the unwind destination is an
  // exception handling instruction.
  Assert(
      II.getUnwindDest()->isEHPad(),
      "The unwind destination does not have an exception handling instruction!",
      &II);

  visitTerminatorInst(II);
}

/// visitBinaryOperator - Check that both arguments to the binary operator are
/// of the same type!
///
void Verifier::visitBinaryOperator(BinaryOperator &B) {
  Assert(B.getOperand(0)->getType() == B.getOperand(1)->getType(),
         "Both operands to a binary operator are not of the same type!", &B);

  switch (B.getOpcode()) {
  // Check that integer arithmetic operators are only used with
  // integral operands.
  case Instruction::Add:
  case Instruction::Sub:
  case Instruction::Mul:
  case Instruction::SDiv:
  case Instruction::UDiv:
  case Instruction::SRem:
  case Instruction::URem:
    Assert(B.getType()->isIntOrIntVectorTy(),
           "Integer arithmetic operators only work with integral types!", &B);
    Assert(B.getType() == B.getOperand(0)->getType(),
           "Integer arithmetic operators must have same type "
           "for operands and result!",
           &B);
    break;
  // Check that floating-point arithmetic operators are only used with
  // floating-point operands.
  case Instruction::FAdd:
  case Instruction::FSub:
  case Instruction::FMul:
  case Instruction::FDiv:
  case Instruction::FRem:
    Assert(B.getType()->isFPOrFPVectorTy(),
           "Floating-point arithmetic operators only work with "
           "floating-point types!",
           &B);
    Assert(B.getType() == B.getOperand(0)->getType(),
           "Floating-point arithmetic operators must have same type "
           "for operands and result!",
           &B);
    break;
  // Check that logical operators are only used with integral operands.
  case Instruction::And:
  case Instruction::Or:
  case Instruction::Xor:
    Assert(B.getType()->isIntOrIntVectorTy(),
           "Logical operators only work with integral types!", &B);
    Assert(B.getType() == B.getOperand(0)->getType(),
           "Logical operators must have same type for operands and result!",
           &B);
    break;
  case Instruction::Shl:
  case Instruction::LShr:
  case Instruction::AShr:
    Assert(B.getType()->isIntOrIntVectorTy(),
           "Shifts only work with integral types!", &B);
    Assert(B.getType() == B.getOperand(0)->getType(),
           "Shift return type must be same as operands!", &B);
    break;
  default:
    llvm_unreachable("Unknown BinaryOperator opcode!");
  }

  visitInstruction(B);
}

void Verifier::visitICmpInst(ICmpInst &IC) {
  // Check that the operands are the same type
  Type *Op0Ty = IC.getOperand(0)->getType();
  Type *Op1Ty = IC.getOperand(1)->getType();
  Assert(Op0Ty == Op1Ty,
         "Both operands to ICmp instruction are not of the same type!", &IC);
  // Check that the operands are the right type
  Assert(Op0Ty->isIntOrIntVectorTy() || Op0Ty->getScalarType()->isPointerTy(),
         "Invalid operand types for ICmp instruction", &IC);
  // Check that the predicate is valid.
  Assert(IC.getPredicate() >= CmpInst::FIRST_ICMP_PREDICATE &&
             IC.getPredicate() <= CmpInst::LAST_ICMP_PREDICATE,
         "Invalid predicate in ICmp instruction!", &IC);

  visitInstruction(IC);
}

void Verifier::visitFCmpInst(FCmpInst &FC) {
  // Check that the operands are the same type
  Type *Op0Ty = FC.getOperand(0)->getType();
  Type *Op1Ty = FC.getOperand(1)->getType();
  Assert(Op0Ty == Op1Ty,
         "Both operands to FCmp instruction are not of the same type!", &FC);
  // Check that the operands are the right type
  Assert(Op0Ty->isFPOrFPVectorTy(),
         "Invalid operand types for FCmp instruction", &FC);
  // Check that the predicate is valid.
  Assert(FC.getPredicate() >= CmpInst::FIRST_FCMP_PREDICATE &&
             FC.getPredicate() <= CmpInst::LAST_FCMP_PREDICATE,
         "Invalid predicate in FCmp instruction!", &FC);

  visitInstruction(FC);
}

void Verifier::visitExtractElementInst(ExtractElementInst &EI) {
  Assert(
      ExtractElementInst::isValidOperands(EI.getOperand(0), EI.getOperand(1)),
      "Invalid extractelement operands!", &EI);
  visitInstruction(EI);
}

void Verifier::visitInsertElementInst(InsertElementInst &IE) {
  Assert(InsertElementInst::isValidOperands(IE.getOperand(0), IE.getOperand(1),
                                            IE.getOperand(2)),
         "Invalid insertelement operands!", &IE);
  visitInstruction(IE);
}

void Verifier::visitShuffleVectorInst(ShuffleVectorInst &SV) {
  Assert(ShuffleVectorInst::isValidOperands(SV.getOperand(0), SV.getOperand(1),
                                            SV.getOperand(2)),
         "Invalid shufflevector operands!", &SV);
  visitInstruction(SV);
}

void Verifier::visitGetElementPtrInst(GetElementPtrInst &GEP) {
  Type *TargetTy = GEP.getPointerOperandType()->getScalarType();

  Assert(isa<PointerType>(TargetTy),
         "GEP base pointer is not a vector or a vector of pointers", &GEP);
  Assert(GEP.getSourceElementType()->isSized(), "GEP into unsized type!", &GEP);
  SmallVector<Value*, 16> Idxs(GEP.idx_begin(), GEP.idx_end());
  Type *ElTy =
      GetElementPtrInst::getIndexedType(GEP.getSourceElementType(), Idxs);
  Assert(ElTy, "Invalid indices for GEP pointer type!", &GEP);

  Assert(GEP.getType()->getScalarType()->isPointerTy() &&
             GEP.getResultElementType() == ElTy,
         "GEP is not of right type for indices!", &GEP, ElTy);

  if (GEP.getType()->isVectorTy()) {
    // Additional checks for vector GEPs.
    unsigned GEPWidth = GEP.getType()->getVectorNumElements();
    if (GEP.getPointerOperandType()->isVectorTy())
      Assert(GEPWidth == GEP.getPointerOperandType()->getVectorNumElements(),
             "Vector GEP result width doesn't match operand's", &GEP);
    for (Value *Idx : Idxs) {
      Type *IndexTy = Idx->getType();
      if (IndexTy->isVectorTy()) {
        unsigned IndexWidth = IndexTy->getVectorNumElements();
        Assert(IndexWidth == GEPWidth, "Invalid GEP index vector width", &GEP);
      }
      Assert(IndexTy->getScalarType()->isIntegerTy(),
             "All GEP indices should be of integer type");
    }
  }
  visitInstruction(GEP);
}

static bool isContiguous(const ConstantRange &A, const ConstantRange &B) {
  return A.getUpper() == B.getLower() || A.getLower() == B.getUpper();
}

void Verifier::visitRangeMetadata(Instruction& I,
                                  MDNode* Range, Type* Ty) {
  assert(Range &&
         Range == I.getMetadata(LLVMContext::MD_range) &&
         "precondition violation");

  unsigned NumOperands = Range->getNumOperands();
  Assert(NumOperands % 2 == 0, "Unfinished range!", Range);
  unsigned NumRanges = NumOperands / 2;
  Assert(NumRanges >= 1, "It should have at least one range!", Range);

  ConstantRange LastRange(1); // Dummy initial value
  for (unsigned i = 0; i < NumRanges; ++i) {
    ConstantInt *Low =
        mdconst::dyn_extract<ConstantInt>(Range->getOperand(2 * i));
    Assert(Low, "The lower limit must be an integer!", Low);
    ConstantInt *High =
        mdconst::dyn_extract<ConstantInt>(Range->getOperand(2 * i + 1));
    Assert(High, "The upper limit must be an integer!", High);
    Assert(High->getType() == Low->getType() && High->getType() == Ty,
           "Range types must match instruction type!", &I);

    APInt HighV = High->getValue();
    APInt LowV = Low->getValue();
    ConstantRange CurRange(LowV, HighV);
    Assert(!CurRange.isEmptySet() && !CurRange.isFullSet(),
           "Range must not be empty!", Range);
    if (i != 0) {
      Assert(CurRange.intersectWith(LastRange).isEmptySet(),
             "Intervals are overlapping", Range);
      Assert(LowV.sgt(LastRange.getLower()), "Intervals are not in order",
             Range);
      Assert(!isContiguous(CurRange, LastRange), "Intervals are contiguous",
             Range);
    }
    LastRange = ConstantRange(LowV, HighV);
  }
  if (NumRanges > 2) {
    APInt FirstLow =
        mdconst::dyn_extract<ConstantInt>(Range->getOperand(0))->getValue();
    APInt FirstHigh =
        mdconst::dyn_extract<ConstantInt>(Range->getOperand(1))->getValue();
    ConstantRange FirstRange(FirstLow, FirstHigh);
    Assert(FirstRange.intersectWith(LastRange).isEmptySet(),
           "Intervals are overlapping", Range);
    Assert(!isContiguous(FirstRange, LastRange), "Intervals are contiguous",
           Range);
  }
}

void Verifier::checkAtomicMemAccessSize(const Module *M, Type *Ty,
                                        const Instruction *I) {
  unsigned Size = M->getDataLayout().getTypeSizeInBits(Ty);
  Assert(Size >= 8, "atomic memory access' size must be byte-sized", Ty, I);
  Assert(!(Size & (Size - 1)),
         "atomic memory access' operand must have a power-of-two size", Ty, I);
}

void Verifier::visitLoadInst(LoadInst &LI) {
  PointerType *PTy = dyn_cast<PointerType>(LI.getOperand(0)->getType());
  Assert(PTy, "Load operand must be a pointer.", &LI);
  Type *ElTy = LI.getType();
  Assert(LI.getAlignment() <= Value::MaximumAlignment,
         "huge alignment values are unsupported", &LI);
  Assert(ElTy->isSized(), "loading unsized types is not allowed", &LI);
  if (LI.isAtomic()) {
    Assert(LI.getOrdering() != AtomicOrdering::Release &&
               LI.getOrdering() != AtomicOrdering::AcquireRelease,
           "Load cannot have Release ordering", &LI);
    Assert(LI.getAlignment() != 0,
           "Atomic load must specify explicit alignment", &LI);
    Assert(ElTy->isIntegerTy() || ElTy->isPointerTy() ||
               ElTy->isFloatingPointTy(),
           "atomic load operand must have integer, pointer, or floating point "
           "type!",
           ElTy, &LI);
    checkAtomicMemAccessSize(M, ElTy, &LI);
  } else {
    Assert(LI.getSynchScope() == CrossThread,
           "Non-atomic load cannot have SynchronizationScope specified", &LI);
  }

  visitInstruction(LI);
}

void Verifier::visitStoreInst(StoreInst &SI) {
  PointerType *PTy = dyn_cast<PointerType>(SI.getOperand(1)->getType());
  Assert(PTy, "Store operand must be a pointer.", &SI);
  Type *ElTy = PTy->getElementType();
  Assert(ElTy == SI.getOperand(0)->getType(),
         "Stored value type does not match pointer operand type!", &SI, ElTy);
  Assert(SI.getAlignment() <= Value::MaximumAlignment,
         "huge alignment values are unsupported", &SI);
  Assert(ElTy->isSized(), "storing unsized types is not allowed", &SI);
  if (SI.isAtomic()) {
    Assert(SI.getOrdering() != AtomicOrdering::Acquire &&
               SI.getOrdering() != AtomicOrdering::AcquireRelease,
           "Store cannot have Acquire ordering", &SI);
    Assert(SI.getAlignment() != 0,
           "Atomic store must specify explicit alignment", &SI);
    Assert(ElTy->isIntegerTy() || ElTy->isPointerTy() ||
               ElTy->isFloatingPointTy(),
           "atomic store operand must have integer, pointer, or floating point "
           "type!",
           ElTy, &SI);
    checkAtomicMemAccessSize(M, ElTy, &SI);
  } else {
    Assert(SI.getSynchScope() == CrossThread,
           "Non-atomic store cannot have SynchronizationScope specified", &SI);
  }
  visitInstruction(SI);
}

/// Check that SwiftErrorVal is used as a swifterror argument in CS.
void Verifier::verifySwiftErrorCallSite(CallSite CS,
                                        const Value *SwiftErrorVal) {
  unsigned Idx = 0;
  for (CallSite::arg_iterator I = CS.arg_begin(), E = CS.arg_end();
       I != E; ++I, ++Idx) {
    if (*I == SwiftErrorVal) {
      Assert(CS.paramHasAttr(Idx+1, Attribute::SwiftError),
             "swifterror value when used in a callsite should be marked "
             "with swifterror attribute",
              SwiftErrorVal, CS);
    }
  }
}

void Verifier::verifySwiftErrorValue(const Value *SwiftErrorVal) {
  // Check that swifterror value is only used by loads, stores, or as
  // a swifterror argument.
  for (const User *U : SwiftErrorVal->users()) {
    Assert(isa<LoadInst>(U) || isa<StoreInst>(U) || isa<CallInst>(U) ||
           isa<InvokeInst>(U),
           "swifterror value can only be loaded and stored from, or "
           "as a swifterror argument!",
           SwiftErrorVal, U);
    // If it is used by a store, check it is the second operand.
    if (auto StoreI = dyn_cast<StoreInst>(U))
      Assert(StoreI->getOperand(1) == SwiftErrorVal,
             "swifterror value should be the second operand when used "
             "by stores", SwiftErrorVal, U);
    if (auto CallI = dyn_cast<CallInst>(U))
      verifySwiftErrorCallSite(const_cast<CallInst*>(CallI), SwiftErrorVal);
    if (auto II = dyn_cast<InvokeInst>(U))
      verifySwiftErrorCallSite(const_cast<InvokeInst*>(II), SwiftErrorVal);
  }
}

void Verifier::visitAllocaInst(AllocaInst &AI) {
  SmallPtrSet<Type*, 4> Visited;
  PointerType *PTy = AI.getType();
  Assert(PTy->getAddressSpace() == 0,
         "Allocation instruction pointer not in the generic address space!",
         &AI);
  Assert(AI.getAllocatedType()->isSized(&Visited),
         "Cannot allocate unsized type", &AI);
  Assert(AI.getArraySize()->getType()->isIntegerTy(),
         "Alloca array size must have integer type", &AI);
  Assert(AI.getAlignment() <= Value::MaximumAlignment,
         "huge alignment values are unsupported", &AI);

  if (AI.isSwiftError()) {
    verifySwiftErrorValue(&AI);
  }

  visitInstruction(AI);
}

void Verifier::visitAtomicCmpXchgInst(AtomicCmpXchgInst &CXI) {

  // FIXME: more conditions???
  Assert(CXI.getSuccessOrdering() != AtomicOrdering::NotAtomic,
         "cmpxchg instructions must be atomic.", &CXI);
  Assert(CXI.getFailureOrdering() != AtomicOrdering::NotAtomic,
         "cmpxchg instructions must be atomic.", &CXI);
  Assert(CXI.getSuccessOrdering() != AtomicOrdering::Unordered,
         "cmpxchg instructions cannot be unordered.", &CXI);
  Assert(CXI.getFailureOrdering() != AtomicOrdering::Unordered,
         "cmpxchg instructions cannot be unordered.", &CXI);
  Assert(!isStrongerThan(CXI.getFailureOrdering(), CXI.getSuccessOrdering()),
         "cmpxchg instructions failure argument shall be no stronger than the "
         "success argument",
         &CXI);
  Assert(CXI.getFailureOrdering() != AtomicOrdering::Release &&
             CXI.getFailureOrdering() != AtomicOrdering::AcquireRelease,
         "cmpxchg failure ordering cannot include release semantics", &CXI);

  PointerType *PTy = dyn_cast<PointerType>(CXI.getOperand(0)->getType());
  Assert(PTy, "First cmpxchg operand must be a pointer.", &CXI);
  Type *ElTy = PTy->getElementType();
  Assert(ElTy->isIntegerTy() || ElTy->isPointerTy(),
        "cmpxchg operand must have integer or pointer type",
         ElTy, &CXI);
  checkAtomicMemAccessSize(M, ElTy, &CXI);
  Assert(ElTy == CXI.getOperand(1)->getType(),
         "Expected value type does not match pointer operand type!", &CXI,
         ElTy);
  Assert(ElTy == CXI.getOperand(2)->getType(),
         "Stored value type does not match pointer operand type!", &CXI, ElTy);
  visitInstruction(CXI);
}

void Verifier::visitAtomicRMWInst(AtomicRMWInst &RMWI) {
  Assert(RMWI.getOrdering() != AtomicOrdering::NotAtomic,
         "atomicrmw instructions must be atomic.", &RMWI);
  Assert(RMWI.getOrdering() != AtomicOrdering::Unordered,
         "atomicrmw instructions cannot be unordered.", &RMWI);
  PointerType *PTy = dyn_cast<PointerType>(RMWI.getOperand(0)->getType());
  Assert(PTy, "First atomicrmw operand must be a pointer.", &RMWI);
  Type *ElTy = PTy->getElementType();
  Assert(ElTy->isIntegerTy(), "atomicrmw operand must have integer type!",
         &RMWI, ElTy);
  checkAtomicMemAccessSize(M, ElTy, &RMWI);
  Assert(ElTy == RMWI.getOperand(1)->getType(),
         "Argument value type does not match pointer operand type!", &RMWI,
         ElTy);
  Assert(AtomicRMWInst::FIRST_BINOP <= RMWI.getOperation() &&
             RMWI.getOperation() <= AtomicRMWInst::LAST_BINOP,
         "Invalid binary operation!", &RMWI);
  visitInstruction(RMWI);
}

void Verifier::visitFenceInst(FenceInst &FI) {
  const AtomicOrdering Ordering = FI.getOrdering();
  Assert(Ordering == AtomicOrdering::Acquire ||
             Ordering == AtomicOrdering::Release ||
             Ordering == AtomicOrdering::AcquireRelease ||
             Ordering == AtomicOrdering::SequentiallyConsistent,
         "fence instructions may only have acquire, release, acq_rel, or "
         "seq_cst ordering.",
         &FI);
  visitInstruction(FI);
}

void Verifier::visitExtractValueInst(ExtractValueInst &EVI) {
  Assert(ExtractValueInst::getIndexedType(EVI.getAggregateOperand()->getType(),
                                          EVI.getIndices()) == EVI.getType(),
         "Invalid ExtractValueInst operands!", &EVI);

  visitInstruction(EVI);
}

void Verifier::visitInsertValueInst(InsertValueInst &IVI) {
  Assert(ExtractValueInst::getIndexedType(IVI.getAggregateOperand()->getType(),
                                          IVI.getIndices()) ==
             IVI.getOperand(1)->getType(),
         "Invalid InsertValueInst operands!", &IVI);

  visitInstruction(IVI);
}

static Value *getParentPad(Value *EHPad) {
  if (auto *FPI = dyn_cast<FuncletPadInst>(EHPad))
    return FPI->getParentPad();

  return cast<CatchSwitchInst>(EHPad)->getParentPad();
}

void Verifier::visitEHPadPredecessors(Instruction &I) {
  assert(I.isEHPad());

  BasicBlock *BB = I.getParent();
  Function *F = BB->getParent();

  Assert(BB != &F->getEntryBlock(), "EH pad cannot be in entry block.", &I);

  if (auto *LPI = dyn_cast<LandingPadInst>(&I)) {
    // The landingpad instruction defines its parent as a landing pad block. The
    // landing pad block may be branched to only by the unwind edge of an
    // invoke.
    for (BasicBlock *PredBB : predecessors(BB)) {
      const auto *II = dyn_cast<InvokeInst>(PredBB->getTerminator());
      Assert(II && II->getUnwindDest() == BB && II->getNormalDest() != BB,
             "Block containing LandingPadInst must be jumped to "
             "only by the unwind edge of an invoke.",
             LPI);
    }
    return;
  }
  if (auto *CPI = dyn_cast<CatchPadInst>(&I)) {
    if (!pred_empty(BB))
      Assert(BB->getUniquePredecessor() == CPI->getCatchSwitch()->getParent(),
             "Block containg CatchPadInst must be jumped to "
             "only by its catchswitch.",
             CPI);
    Assert(BB != CPI->getCatchSwitch()->getUnwindDest(),
           "Catchswitch cannot unwind to one of its catchpads",
           CPI->getCatchSwitch(), CPI);
    return;
  }

  // Verify that each pred has a legal terminator with a legal to/from EH
  // pad relationship.
  Instruction *ToPad = &I;
  Value *ToPadParent = getParentPad(ToPad);
  for (BasicBlock *PredBB : predecessors(BB)) {
    TerminatorInst *TI = PredBB->getTerminator();
    Value *FromPad;
    if (auto *II = dyn_cast<InvokeInst>(TI)) {
      Assert(II->getUnwindDest() == BB && II->getNormalDest() != BB,
             "EH pad must be jumped to via an unwind edge", ToPad, II);
      if (auto Bundle = II->getOperandBundle(LLVMContext::OB_funclet))
        FromPad = Bundle->Inputs[0];
      else
        FromPad = ConstantTokenNone::get(II->getContext());
    } else if (auto *CRI = dyn_cast<CleanupReturnInst>(TI)) {
      FromPad = CRI->getOperand(0);
      Assert(FromPad != ToPadParent, "A cleanupret must exit its cleanup", CRI);
    } else if (auto *CSI = dyn_cast<CatchSwitchInst>(TI)) {
      FromPad = CSI;
    } else {
      Assert(false, "EH pad must be jumped to via an unwind edge", ToPad, TI);
    }

    // The edge may exit from zero or more nested pads.
    SmallSet<Value *, 8> Seen;
    for (;; FromPad = getParentPad(FromPad)) {
      Assert(FromPad != ToPad,
             "EH pad cannot handle exceptions raised within it", FromPad, TI);
      if (FromPad == ToPadParent) {
        // This is a legal unwind edge.
        break;
      }
      Assert(!isa<ConstantTokenNone>(FromPad),
             "A single unwind edge may only enter one EH pad", TI);
      Assert(Seen.insert(FromPad).second,
             "EH pad jumps through a cycle of pads", FromPad);
    }
  }
}

void Verifier::visitLandingPadInst(LandingPadInst &LPI) {
  // The landingpad instruction is ill-formed if it doesn't have any clauses and
  // isn't a cleanup.
  Assert(LPI.getNumClauses() > 0 || LPI.isCleanup(),
         "LandingPadInst needs at least one clause or to be a cleanup.", &LPI);

  visitEHPadPredecessors(LPI);

  if (!LandingPadResultTy)
    LandingPadResultTy = LPI.getType();
  else
    Assert(LandingPadResultTy == LPI.getType(),
           "The landingpad instruction should have a consistent result type "
           "inside a function.",
           &LPI);

  Function *F = LPI.getParent()->getParent();
  Assert(F->hasPersonalityFn(),
         "LandingPadInst needs to be in a function with a personality.", &LPI);

  // The landingpad instruction must be the first non-PHI instruction in the
  // block.
  Assert(LPI.getParent()->getLandingPadInst() == &LPI,
         "LandingPadInst not the first non-PHI instruction in the block.",
         &LPI);

  for (unsigned i = 0, e = LPI.getNumClauses(); i < e; ++i) {
    Constant *Clause = LPI.getClause(i);
    if (LPI.isCatch(i)) {
      Assert(isa<PointerType>(Clause->getType()),
             "Catch operand does not have pointer type!", &LPI);
    } else {
      Assert(LPI.isFilter(i), "Clause is neither catch nor filter!", &LPI);
      Assert(isa<ConstantArray>(Clause) || isa<ConstantAggregateZero>(Clause),
             "Filter operand is not an array of constants!", &LPI);
    }
  }

  visitInstruction(LPI);
}

void Verifier::visitResumeInst(ResumeInst &RI) {
  Assert(RI.getFunction()->hasPersonalityFn(),
         "ResumeInst needs to be in a function with a personality.", &RI);

  if (!LandingPadResultTy)
    LandingPadResultTy = RI.getValue()->getType();
  else
    Assert(LandingPadResultTy == RI.getValue()->getType(),
           "The resume instruction should have a consistent result type "
           "inside a function.",
           &RI);

  visitTerminatorInst(RI);
}

void Verifier::visitCatchPadInst(CatchPadInst &CPI) {
  BasicBlock *BB = CPI.getParent();

  Function *F = BB->getParent();
  Assert(F->hasPersonalityFn(),
         "CatchPadInst needs to be in a function with a personality.", &CPI);

  Assert(isa<CatchSwitchInst>(CPI.getParentPad()),
         "CatchPadInst needs to be directly nested in a CatchSwitchInst.",
         CPI.getParentPad());

  // The catchpad instruction must be the first non-PHI instruction in the
  // block.
  Assert(BB->getFirstNonPHI() == &CPI,
         "CatchPadInst not the first non-PHI instruction in the block.", &CPI);

  visitEHPadPredecessors(CPI);
  visitFuncletPadInst(CPI);
}

void Verifier::visitCatchReturnInst(CatchReturnInst &CatchReturn) {
  Assert(isa<CatchPadInst>(CatchReturn.getOperand(0)),
         "CatchReturnInst needs to be provided a CatchPad", &CatchReturn,
         CatchReturn.getOperand(0));

  visitTerminatorInst(CatchReturn);
}

void Verifier::visitCleanupPadInst(CleanupPadInst &CPI) {
  BasicBlock *BB = CPI.getParent();

  Function *F = BB->getParent();
  Assert(F->hasPersonalityFn(),
         "CleanupPadInst needs to be in a function with a personality.", &CPI);

  // The cleanuppad instruction must be the first non-PHI instruction in the
  // block.
  Assert(BB->getFirstNonPHI() == &CPI,
         "CleanupPadInst not the first non-PHI instruction in the block.",
         &CPI);

  auto *ParentPad = CPI.getParentPad();
  Assert(isa<ConstantTokenNone>(ParentPad) || isa<FuncletPadInst>(ParentPad),
         "CleanupPadInst has an invalid parent.", &CPI);

  visitEHPadPredecessors(CPI);
  visitFuncletPadInst(CPI);
}

void Verifier::visitFuncletPadInst(FuncletPadInst &FPI) {
  User *FirstUser = nullptr;
  Value *FirstUnwindPad = nullptr;
  SmallVector<FuncletPadInst *, 8> Worklist({&FPI});
  SmallSet<FuncletPadInst *, 8> Seen;

  while (!Worklist.empty()) {
    FuncletPadInst *CurrentPad = Worklist.pop_back_val();
    Assert(Seen.insert(CurrentPad).second,
           "FuncletPadInst must not be nested within itself", CurrentPad);
    Value *UnresolvedAncestorPad = nullptr;
    for (User *U : CurrentPad->users()) {
      BasicBlock *UnwindDest;
      if (auto *CRI = dyn_cast<CleanupReturnInst>(U)) {
        UnwindDest = CRI->getUnwindDest();
      } else if (auto *CSI = dyn_cast<CatchSwitchInst>(U)) {
        // We allow catchswitch unwind to caller to nest
        // within an outer pad that unwinds somewhere else,
        // because catchswitch doesn't have a nounwind variant.
        // See e.g. SimplifyCFGOpt::SimplifyUnreachable.
        if (CSI->unwindsToCaller())
          continue;
        UnwindDest = CSI->getUnwindDest();
      } else if (auto *II = dyn_cast<InvokeInst>(U)) {
        UnwindDest = II->getUnwindDest();
      } else if (isa<CallInst>(U)) {
        // Calls which don't unwind may be found inside funclet
        // pads that unwind somewhere else.  We don't *require*
        // such calls to be annotated nounwind.
        continue;
      } else if (auto *CPI = dyn_cast<CleanupPadInst>(U)) {
        // The unwind dest for a cleanup can only be found by
        // recursive search.  Add it to the worklist, and we'll
        // search for its first use that determines where it unwinds.
        Worklist.push_back(CPI);
        continue;
      } else {
        Assert(isa<CatchReturnInst>(U), "Bogus funclet pad use", U);
        continue;
      }

      Value *UnwindPad;
      bool ExitsFPI;
      if (UnwindDest) {
        UnwindPad = UnwindDest->getFirstNonPHI();
        if (!cast<Instruction>(UnwindPad)->isEHPad())
          continue;
        Value *UnwindParent = getParentPad(UnwindPad);
        // Ignore unwind edges that don't exit CurrentPad.
        if (UnwindParent == CurrentPad)
          continue;
        // Determine whether the original funclet pad is exited,
        // and if we are scanning nested pads determine how many
        // of them are exited so we can stop searching their
        // children.
        Value *ExitedPad = CurrentPad;
        ExitsFPI = false;
        do {
          if (ExitedPad == &FPI) {
            ExitsFPI = true;
            // Now we can resolve any ancestors of CurrentPad up to
            // FPI, but not including FPI since we need to make sure
            // to check all direct users of FPI for consistency.
            UnresolvedAncestorPad = &FPI;
            break;
          }
          Value *ExitedParent = getParentPad(ExitedPad);
          if (ExitedParent == UnwindParent) {
            // ExitedPad is the ancestor-most pad which this unwind
            // edge exits, so we can resolve up to it, meaning that
            // ExitedParent is the first ancestor still unresolved.
            UnresolvedAncestorPad = ExitedParent;
            break;
          }
          ExitedPad = ExitedParent;
        } while (!isa<ConstantTokenNone>(ExitedPad));
      } else {
        // Unwinding to caller exits all pads.
        UnwindPad = ConstantTokenNone::get(FPI.getContext());
        ExitsFPI = true;
        UnresolvedAncestorPad = &FPI;
      }

      if (ExitsFPI) {
        // This unwind edge exits FPI.  Make sure it agrees with other
        // such edges.
        if (FirstUser) {
          Assert(UnwindPad == FirstUnwindPad, "Unwind edges out of a funclet "
                                              "pad must have the same unwind "
                                              "dest",
                 &FPI, U, FirstUser);
        } else {
          FirstUser = U;
          FirstUnwindPad = UnwindPad;
          // Record cleanup sibling unwinds for verifySiblingFuncletUnwinds
          if (isa<CleanupPadInst>(&FPI) && !isa<ConstantTokenNone>(UnwindPad) &&
              getParentPad(UnwindPad) == getParentPad(&FPI))
            SiblingFuncletInfo[&FPI] = cast<TerminatorInst>(U);
        }
      }
      // Make sure we visit all uses of FPI, but for nested pads stop as
      // soon as we know where they unwind to.
      if (CurrentPad != &FPI)
        break;
    }
    if (UnresolvedAncestorPad) {
      if (CurrentPad == UnresolvedAncestorPad) {
        // When CurrentPad is FPI itself, we don't mark it as resolved even if
        // we've found an unwind edge that exits it, because we need to verify
        // all direct uses of FPI.
        assert(CurrentPad == &FPI);
        continue;
      }
      // Pop off the worklist any nested pads that we've found an unwind
      // destination for.  The pads on the worklist are the uncles,
      // great-uncles, etc. of CurrentPad.  We've found an unwind destination
      // for all ancestors of CurrentPad up to but not including
      // UnresolvedAncestorPad.
      Value *ResolvedPad = CurrentPad;
      while (!Worklist.empty()) {
        Value *UnclePad = Worklist.back();
        Value *AncestorPad = getParentPad(UnclePad);
        // Walk ResolvedPad up the ancestor list until we either find the
        // uncle's parent or the last resolved ancestor.
        while (ResolvedPad != AncestorPad) {
          Value *ResolvedParent = getParentPad(ResolvedPad);
          if (ResolvedParent == UnresolvedAncestorPad) {
            break;
          }
          ResolvedPad = ResolvedParent;
        }
        // If the resolved ancestor search didn't find the uncle's parent,
        // then the uncle is not yet resolved.
        if (ResolvedPad != AncestorPad)
          break;
        // This uncle is resolved, so pop it from the worklist.
        Worklist.pop_back();
      }
    }
  }

  if (FirstUnwindPad) {
    if (auto *CatchSwitch = dyn_cast<CatchSwitchInst>(FPI.getParentPad())) {
      BasicBlock *SwitchUnwindDest = CatchSwitch->getUnwindDest();
      Value *SwitchUnwindPad;
      if (SwitchUnwindDest)
        SwitchUnwindPad = SwitchUnwindDest->getFirstNonPHI();
      else
        SwitchUnwindPad = ConstantTokenNone::get(FPI.getContext());
      Assert(SwitchUnwindPad == FirstUnwindPad,
             "Unwind edges out of a catch must have the same unwind dest as "
             "the parent catchswitch",
             &FPI, FirstUser, CatchSwitch);
    }
  }

  visitInstruction(FPI);
}

void Verifier::visitCatchSwitchInst(CatchSwitchInst &CatchSwitch) {
  BasicBlock *BB = CatchSwitch.getParent();

  Function *F = BB->getParent();
  Assert(F->hasPersonalityFn(),
         "CatchSwitchInst needs to be in a function with a personality.",
         &CatchSwitch);

  // The catchswitch instruction must be the first non-PHI instruction in the
  // block.
  Assert(BB->getFirstNonPHI() == &CatchSwitch,
         "CatchSwitchInst not the first non-PHI instruction in the block.",
         &CatchSwitch);

  auto *ParentPad = CatchSwitch.getParentPad();
  Assert(isa<ConstantTokenNone>(ParentPad) || isa<FuncletPadInst>(ParentPad),
         "CatchSwitchInst has an invalid parent.", ParentPad);

  if (BasicBlock *UnwindDest = CatchSwitch.getUnwindDest()) {
    Instruction *I = UnwindDest->getFirstNonPHI();
    Assert(I->isEHPad() && !isa<LandingPadInst>(I),
           "CatchSwitchInst must unwind to an EH block which is not a "
           "landingpad.",
           &CatchSwitch);

    // Record catchswitch sibling unwinds for verifySiblingFuncletUnwinds
    if (getParentPad(I) == ParentPad)
      SiblingFuncletInfo[&CatchSwitch] = &CatchSwitch;
  }

  Assert(CatchSwitch.getNumHandlers() != 0,
         "CatchSwitchInst cannot have empty handler list", &CatchSwitch);

  for (BasicBlock *Handler : CatchSwitch.handlers()) {
    Assert(isa<CatchPadInst>(Handler->getFirstNonPHI()),
           "CatchSwitchInst handlers must be catchpads", &CatchSwitch, Handler);
  }

  visitEHPadPredecessors(CatchSwitch);
  visitTerminatorInst(CatchSwitch);
}

void Verifier::visitCleanupReturnInst(CleanupReturnInst &CRI) {
  Assert(isa<CleanupPadInst>(CRI.getOperand(0)),
         "CleanupReturnInst needs to be provided a CleanupPad", &CRI,
         CRI.getOperand(0));

  if (BasicBlock *UnwindDest = CRI.getUnwindDest()) {
    Instruction *I = UnwindDest->getFirstNonPHI();
    Assert(I->isEHPad() && !isa<LandingPadInst>(I),
           "CleanupReturnInst must unwind to an EH block which is not a "
           "landingpad.",
           &CRI);
  }

  visitTerminatorInst(CRI);
}

void Verifier::verifyDominatesUse(Instruction &I, unsigned i) {
  Instruction *Op = cast<Instruction>(I.getOperand(i));
  // If the we have an invalid invoke, don't try to compute the dominance.
  // We already reject it in the invoke specific checks and the dominance
  // computation doesn't handle multiple edges.
  if (InvokeInst *II = dyn_cast<InvokeInst>(Op)) {
    if (II->getNormalDest() == II->getUnwindDest())
      return;
  }

  // Quick check whether the def has already been encountered in the same block.
  // PHI nodes are not checked to prevent accepting preceeding PHIs, because PHI
  // uses are defined to happen on the incoming edge, not at the instruction.
  //
  // FIXME: If this operand is a MetadataAsValue (wrapping a LocalAsMetadata)
  // wrapping an SSA value, assert that we've already encountered it.  See
  // related FIXME in Mapper::mapLocalAsMetadata in ValueMapper.cpp.
  if (!isa<PHINode>(I) && InstsInThisBlock.count(Op))
    return;

  const Use &U = I.getOperandUse(i);
  Assert(DT.dominates(Op, U),
         "Instruction does not dominate all uses!", Op, &I);
}

void Verifier::visitDereferenceableMetadata(Instruction& I, MDNode* MD) {
  Assert(I.getType()->isPointerTy(), "dereferenceable, dereferenceable_or_null "
         "apply only to pointer types", &I);
  Assert(isa<LoadInst>(I),
         "dereferenceable, dereferenceable_or_null apply only to load"
         " instructions, use attributes for calls or invokes", &I);
  Assert(MD->getNumOperands() == 1, "dereferenceable, dereferenceable_or_null "
         "take one operand!", &I);
  ConstantInt *CI = mdconst::dyn_extract<ConstantInt>(MD->getOperand(0));
  Assert(CI && CI->getType()->isIntegerTy(64), "dereferenceable, "
         "dereferenceable_or_null metadata value must be an i64!", &I);
}

/// verifyInstruction - Verify that an instruction is well formed.
///
void Verifier::visitInstruction(Instruction &I) {
  BasicBlock *BB = I.getParent();
  Assert(BB, "Instruction not embedded in basic block!", &I);

  if (!isa<PHINode>(I)) {   // Check that non-phi nodes are not self referential
    for (User *U : I.users()) {
      Assert(U != (User *)&I || !DT.isReachableFromEntry(BB),
             "Only PHI nodes may reference their own value!", &I);
    }
  }

  // Check that void typed values don't have names
  Assert(!I.getType()->isVoidTy() || !I.hasName(),
         "Instruction has a name, but provides a void value!", &I);

  // Check that the return value of the instruction is either void or a legal
  // value type.
  Assert(I.getType()->isVoidTy() || I.getType()->isFirstClassType(),
         "Instruction returns a non-scalar type!", &I);

  // Check that the instruction doesn't produce metadata. Calls are already
  // checked against the callee type.
  Assert(!I.getType()->isMetadataTy() || isa<CallInst>(I) || isa<InvokeInst>(I),
         "Invalid use of metadata!", &I);

  // Check that all uses of the instruction, if they are instructions
  // themselves, actually have parent basic blocks.  If the use is not an
  // instruction, it is an error!
  for (Use &U : I.uses()) {
    if (Instruction *Used = dyn_cast<Instruction>(U.getUser()))
      Assert(Used->getParent() != nullptr,
             "Instruction referencing"
             " instruction not embedded in a basic block!",
             &I, Used);
    else {
      CheckFailed("Use of instruction is not an instruction!", U);
      return;
    }
  }

  for (unsigned i = 0, e = I.getNumOperands(); i != e; ++i) {
    Assert(I.getOperand(i) != nullptr, "Instruction has null operand!", &I);

    // Check to make sure that only first-class-values are operands to
    // instructions.
    if (!I.getOperand(i)->getType()->isFirstClassType()) {
      Assert(0, "Instruction operands must be first-class values!", &I);
    }

    if (Function *F = dyn_cast<Function>(I.getOperand(i))) {
      // Check to make sure that the "address of" an intrinsic function is never
      // taken.
      Assert(
          !F->isIntrinsic() ||
              i == (isa<CallInst>(I) ? e - 1 : isa<InvokeInst>(I) ? e - 3 : 0),
          "Cannot take the address of an intrinsic!", &I);
      Assert(
          !F->isIntrinsic() || isa<CallInst>(I) ||
              F->getIntrinsicID() == Intrinsic::donothing ||
              F->getIntrinsicID() == Intrinsic::experimental_patchpoint_void ||
              F->getIntrinsicID() == Intrinsic::experimental_patchpoint_i64 ||
              F->getIntrinsicID() == Intrinsic::experimental_gc_statepoint,
          "Cannot invoke an intrinsic other than donothing, patchpoint or "
          "statepoint",
          &I);
      Assert(F->getParent() == M, "Referencing function in another module!",
             &I, M, F, F->getParent());
    } else if (BasicBlock *OpBB = dyn_cast<BasicBlock>(I.getOperand(i))) {
      Assert(OpBB->getParent() == BB->getParent(),
             "Referring to a basic block in another function!", &I);
    } else if (Argument *OpArg = dyn_cast<Argument>(I.getOperand(i))) {
      Assert(OpArg->getParent() == BB->getParent(),
             "Referring to an argument in another function!", &I);
    } else if (GlobalValue *GV = dyn_cast<GlobalValue>(I.getOperand(i))) {
      Assert(GV->getParent() == M, "Referencing global in another module!", &I, M, GV, GV->getParent());
    } else if (isa<Instruction>(I.getOperand(i))) {
      verifyDominatesUse(I, i);
    } else if (isa<InlineAsm>(I.getOperand(i))) {
      Assert((i + 1 == e && isa<CallInst>(I)) ||
                 (i + 3 == e && isa<InvokeInst>(I)),
             "Cannot take the address of an inline asm!", &I);
    } else if (ConstantExpr *CE = dyn_cast<ConstantExpr>(I.getOperand(i))) {
      if (CE->getType()->isPtrOrPtrVectorTy()) {
        // If we have a ConstantExpr pointer, we need to see if it came from an
        // illegal bitcast (inttoptr <constant int> )
        visitConstantExprsRecursively(CE);
      }
    }
  }

  if (MDNode *MD = I.getMetadata(LLVMContext::MD_fpmath)) {
    Assert(I.getType()->isFPOrFPVectorTy(),
           "fpmath requires a floating point result!", &I);
    Assert(MD->getNumOperands() == 1, "fpmath takes one operand!", &I);
    if (ConstantFP *CFP0 =
            mdconst::dyn_extract_or_null<ConstantFP>(MD->getOperand(0))) {
      const APFloat &Accuracy = CFP0->getValueAPF();
      Assert(&Accuracy.getSemantics() == &APFloat::IEEEsingle,
             "fpmath accuracy must have float type", &I);
      Assert(Accuracy.isFiniteNonZero() && !Accuracy.isNegative(),
             "fpmath accuracy not a positive number!", &I);
    } else {
      Assert(false, "invalid fpmath accuracy!", &I);
    }
  }

  if (MDNode *Range = I.getMetadata(LLVMContext::MD_range)) {
    Assert(isa<LoadInst>(I) || isa<CallInst>(I) || isa<InvokeInst>(I),
           "Ranges are only for loads, calls and invokes!", &I);
    visitRangeMetadata(I, Range, I.getType());
  }

  if (I.getMetadata(LLVMContext::MD_nonnull)) {
    Assert(I.getType()->isPointerTy(), "nonnull applies only to pointer types",
           &I);
    Assert(isa<LoadInst>(I),
           "nonnull applies only to load instructions, use attributes"
           " for calls or invokes",
           &I);
  }

  if (MDNode *MD = I.getMetadata(LLVMContext::MD_dereferenceable))
    visitDereferenceableMetadata(I, MD);

  if (MDNode *MD = I.getMetadata(LLVMContext::MD_dereferenceable_or_null))
    visitDereferenceableMetadata(I, MD);

  if (MDNode *AlignMD = I.getMetadata(LLVMContext::MD_align)) {
    Assert(I.getType()->isPointerTy(), "align applies only to pointer types",
           &I);
    Assert(isa<LoadInst>(I), "align applies only to load instructions, "
           "use attributes for calls or invokes", &I);
    Assert(AlignMD->getNumOperands() == 1, "align takes one operand!", &I);
    ConstantInt *CI = mdconst::dyn_extract<ConstantInt>(AlignMD->getOperand(0));
    Assert(CI && CI->getType()->isIntegerTy(64),
           "align metadata value must be an i64!", &I);
    uint64_t Align = CI->getZExtValue();
    Assert(isPowerOf2_64(Align),
           "align metadata value must be a power of 2!", &I);
    Assert(Align <= Value::MaximumAlignment,
           "alignment is larger that implementation defined limit", &I);
  }

  if (MDNode *N = I.getDebugLoc().getAsMDNode()) {
    AssertDI(isa<DILocation>(N), "invalid !dbg metadata attachment", &I, N);
    visitMDNode(*N);
  }

  if (auto *DII = dyn_cast<DbgInfoIntrinsic>(&I))
    verifyBitPieceExpression(*DII);

  InstsInThisBlock.insert(&I);
}

/// Allow intrinsics to be verified in different ways.
void Verifier::visitIntrinsicCallSite(Intrinsic::ID ID, CallSite CS) {
  Function *IF = CS.getCalledFunction();
  Assert(IF->isDeclaration(), "Intrinsic functions should never be defined!",
         IF);

  // Verify that the intrinsic prototype lines up with what the .td files
  // describe.
  FunctionType *IFTy = IF->getFunctionType();
  bool IsVarArg = IFTy->isVarArg();

  SmallVector<Intrinsic::IITDescriptor, 8> Table;
  getIntrinsicInfoTableEntries(ID, Table);
  ArrayRef<Intrinsic::IITDescriptor> TableRef = Table;

  SmallVector<Type *, 4> ArgTys;
  Assert(!Intrinsic::matchIntrinsicType(IFTy->getReturnType(),
                                        TableRef, ArgTys),
         "Intrinsic has incorrect return type!", IF);
  for (unsigned i = 0, e = IFTy->getNumParams(); i != e; ++i)
    Assert(!Intrinsic::matchIntrinsicType(IFTy->getParamType(i),
                                          TableRef, ArgTys),
           "Intrinsic has incorrect argument type!", IF);

  // Verify if the intrinsic call matches the vararg property.
  if (IsVarArg)
    Assert(!Intrinsic::matchIntrinsicVarArg(IsVarArg, TableRef),
           "Intrinsic was not defined with variable arguments!", IF);
  else
    Assert(!Intrinsic::matchIntrinsicVarArg(IsVarArg, TableRef),
           "Callsite was not defined with variable arguments!", IF);

  // All descriptors should be absorbed by now.
  Assert(TableRef.empty(), "Intrinsic has too few arguments!", IF);

  // Now that we have the intrinsic ID and the actual argument types (and we
  // know they are legal for the intrinsic!) get the intrinsic name through the
  // usual means.  This allows us to verify the mangling of argument types into
  // the name.
  const std::string ExpectedName = Intrinsic::getName(ID, ArgTys);
  Assert(ExpectedName == IF->getName(),
         "Intrinsic name not mangled correctly for type arguments! "
         "Should be: " +
             ExpectedName,
         IF);

  // If the intrinsic takes MDNode arguments, verify that they are either global
  // or are local to *this* function.
  for (Value *V : CS.args()) 
    if (auto *MD = dyn_cast<MetadataAsValue>(V))
      visitMetadataAsValue(*MD, CS.getCaller());

  switch (ID) {
  default:
    break;
  case Intrinsic::ctlz:  // llvm.ctlz
  case Intrinsic::cttz:  // llvm.cttz
    Assert(isa<ConstantInt>(CS.getArgOperand(1)),
           "is_zero_undef argument of bit counting intrinsics must be a "
           "constant int",
           CS);
    break;
  case Intrinsic::dbg_declare: // llvm.dbg.declare
    Assert(isa<MetadataAsValue>(CS.getArgOperand(0)),
           "invalid llvm.dbg.declare intrinsic call 1", CS);
    visitDbgIntrinsic("declare", cast<DbgDeclareInst>(*CS.getInstruction()));
    break;
  case Intrinsic::dbg_value: // llvm.dbg.value
    visitDbgIntrinsic("value", cast<DbgValueInst>(*CS.getInstruction()));
    break;
  case Intrinsic::memcpy:
  case Intrinsic::memmove:
  case Intrinsic::memset: {
    ConstantInt *AlignCI = dyn_cast<ConstantInt>(CS.getArgOperand(3));
    Assert(AlignCI,
           "alignment argument of memory intrinsics must be a constant int",
           CS);
    const APInt &AlignVal = AlignCI->getValue();
    Assert(AlignCI->isZero() || AlignVal.isPowerOf2(),
           "alignment argument of memory intrinsics must be a power of 2", CS);
    Assert(isa<ConstantInt>(CS.getArgOperand(4)),
           "isvolatile argument of memory intrinsics must be a constant int",
           CS);
    break;
  }
  case Intrinsic::gcroot:
  case Intrinsic::gcwrite:
  case Intrinsic::gcread:
    if (ID == Intrinsic::gcroot) {
      AllocaInst *AI =
        dyn_cast<AllocaInst>(CS.getArgOperand(0)->stripPointerCasts());
      Assert(AI, "llvm.gcroot parameter #1 must be an alloca.", CS);
      Assert(isa<Constant>(CS.getArgOperand(1)),
             "llvm.gcroot parameter #2 must be a constant.", CS);
      if (!AI->getAllocatedType()->isPointerTy()) {
        Assert(!isa<ConstantPointerNull>(CS.getArgOperand(1)),
               "llvm.gcroot parameter #1 must either be a pointer alloca, "
               "or argument #2 must be a non-null constant.",
               CS);
      }
    }

    Assert(CS.getParent()->getParent()->hasGC(),
           "Enclosing function does not use GC.", CS);
    break;
  case Intrinsic::init_trampoline:
    Assert(isa<Function>(CS.getArgOperand(1)->stripPointerCasts()),
           "llvm.init_trampoline parameter #2 must resolve to a function.",
           CS);
    break;
  case Intrinsic::prefetch:
    Assert(isa<ConstantInt>(CS.getArgOperand(1)) &&
               isa<ConstantInt>(CS.getArgOperand(2)) &&
               cast<ConstantInt>(CS.getArgOperand(1))->getZExtValue() < 2 &&
               cast<ConstantInt>(CS.getArgOperand(2))->getZExtValue() < 4,
           "invalid arguments to llvm.prefetch", CS);
    break;
  case Intrinsic::stackprotector:
    Assert(isa<AllocaInst>(CS.getArgOperand(1)->stripPointerCasts()),
           "llvm.stackprotector parameter #2 must resolve to an alloca.", CS);
    break;
  case Intrinsic::lifetime_start:
  case Intrinsic::lifetime_end:
  case Intrinsic::invariant_start:
    Assert(isa<ConstantInt>(CS.getArgOperand(0)),
           "size argument of memory use markers must be a constant integer",
           CS);
    break;
  case Intrinsic::invariant_end:
    Assert(isa<ConstantInt>(CS.getArgOperand(1)),
           "llvm.invariant.end parameter #2 must be a constant integer", CS);
    break;

  case Intrinsic::localescape: {
    BasicBlock *BB = CS.getParent();
    Assert(BB == &BB->getParent()->front(),
           "llvm.localescape used outside of entry block", CS);
    Assert(!SawFrameEscape,
           "multiple calls to llvm.localescape in one function", CS);
    for (Value *Arg : CS.args()) {
      if (isa<ConstantPointerNull>(Arg))
        continue; // Null values are allowed as placeholders.
      auto *AI = dyn_cast<AllocaInst>(Arg->stripPointerCasts());
      Assert(AI && AI->isStaticAlloca(),
             "llvm.localescape only accepts static allocas", CS);
    }
    FrameEscapeInfo[BB->getParent()].first = CS.getNumArgOperands();
    SawFrameEscape = true;
    break;
  }
  case Intrinsic::localrecover: {
    Value *FnArg = CS.getArgOperand(0)->stripPointerCasts();
    Function *Fn = dyn_cast<Function>(FnArg);
    Assert(Fn && !Fn->isDeclaration(),
           "llvm.localrecover first "
           "argument must be function defined in this module",
           CS);
    auto *IdxArg = dyn_cast<ConstantInt>(CS.getArgOperand(2));
    Assert(IdxArg, "idx argument of llvm.localrecover must be a constant int",
           CS);
    auto &Entry = FrameEscapeInfo[Fn];
    Entry.second = unsigned(
        std::max(uint64_t(Entry.second), IdxArg->getLimitedValue(~0U) + 1));
    break;
  }

  case Intrinsic::experimental_gc_statepoint:
    Assert(!CS.isInlineAsm(),
           "gc.statepoint support for inline assembly unimplemented", CS);
    Assert(CS.getParent()->getParent()->hasGC(),
           "Enclosing function does not use GC.", CS);

    verifyStatepoint(CS);
    break;
  case Intrinsic::experimental_gc_result: {
    Assert(CS.getParent()->getParent()->hasGC(),
           "Enclosing function does not use GC.", CS);
    // Are we tied to a statepoint properly?
    CallSite StatepointCS(CS.getArgOperand(0));
    const Function *StatepointFn =
      StatepointCS.getInstruction() ? StatepointCS.getCalledFunction() : nullptr;
    Assert(StatepointFn && StatepointFn->isDeclaration() &&
               StatepointFn->getIntrinsicID() ==
                   Intrinsic::experimental_gc_statepoint,
           "gc.result operand #1 must be from a statepoint", CS,
           CS.getArgOperand(0));

    // Assert that result type matches wrapped callee.
    const Value *Target = StatepointCS.getArgument(2);
    auto *PT = cast<PointerType>(Target->getType());
    auto *TargetFuncType = cast<FunctionType>(PT->getElementType());
    Assert(CS.getType() == TargetFuncType->getReturnType(),
           "gc.result result type does not match wrapped callee", CS);
    break;
  }
  case Intrinsic::experimental_gc_relocate: {
    Assert(CS.getNumArgOperands() == 3, "wrong number of arguments", CS);

    Assert(isa<PointerType>(CS.getType()->getScalarType()),
           "gc.relocate must return a pointer or a vector of pointers", CS);

    // Check that this relocate is correctly tied to the statepoint

    // This is case for relocate on the unwinding path of an invoke statepoint
    if (LandingPadInst *LandingPad =
          dyn_cast<LandingPadInst>(CS.getArgOperand(0))) {

      const BasicBlock *InvokeBB =
          LandingPad->getParent()->getUniquePredecessor();

      // Landingpad relocates should have only one predecessor with invoke
      // statepoint terminator
      Assert(InvokeBB, "safepoints should have unique landingpads",
             LandingPad->getParent());
      Assert(InvokeBB->getTerminator(), "safepoint block should be well formed",
             InvokeBB);
      Assert(isStatepoint(InvokeBB->getTerminator()),
             "gc relocate should be linked to a statepoint", InvokeBB);
    }
    else {
      // In all other cases relocate should be tied to the statepoint directly.
      // This covers relocates on a normal return path of invoke statepoint and
      // relocates of a call statepoint.
      auto Token = CS.getArgOperand(0);
      Assert(isa<Instruction>(Token) && isStatepoint(cast<Instruction>(Token)),
             "gc relocate is incorrectly tied to the statepoint", CS, Token);
    }

    // Verify rest of the relocate arguments.

    ImmutableCallSite StatepointCS(
        cast<GCRelocateInst>(*CS.getInstruction()).getStatepoint());

    // Both the base and derived must be piped through the safepoint.
    Value* Base = CS.getArgOperand(1);
    Assert(isa<ConstantInt>(Base),
           "gc.relocate operand #2 must be integer offset", CS);

    Value* Derived = CS.getArgOperand(2);
    Assert(isa<ConstantInt>(Derived),
           "gc.relocate operand #3 must be integer offset", CS);

    const int BaseIndex = cast<ConstantInt>(Base)->getZExtValue();
    const int DerivedIndex = cast<ConstantInt>(Derived)->getZExtValue();
    // Check the bounds
    Assert(0 <= BaseIndex && BaseIndex < (int)StatepointCS.arg_size(),
           "gc.relocate: statepoint base index out of bounds", CS);
    Assert(0 <= DerivedIndex && DerivedIndex < (int)StatepointCS.arg_size(),
           "gc.relocate: statepoint derived index out of bounds", CS);

    // Check that BaseIndex and DerivedIndex fall within the 'gc parameters'
    // section of the statepoint's argument.
    Assert(StatepointCS.arg_size() > 0,
           "gc.statepoint: insufficient arguments");
    Assert(isa<ConstantInt>(StatepointCS.getArgument(3)),
           "gc.statement: number of call arguments must be constant integer");
    const unsigned NumCallArgs =
        cast<ConstantInt>(StatepointCS.getArgument(3))->getZExtValue();
    Assert(StatepointCS.arg_size() > NumCallArgs + 5,
           "gc.statepoint: mismatch in number of call arguments");
    Assert(isa<ConstantInt>(StatepointCS.getArgument(NumCallArgs + 5)),
           "gc.statepoint: number of transition arguments must be "
           "a constant integer");
    const int NumTransitionArgs =
        cast<ConstantInt>(StatepointCS.getArgument(NumCallArgs + 5))
            ->getZExtValue();
    const int DeoptArgsStart = 4 + NumCallArgs + 1 + NumTransitionArgs + 1;
    Assert(isa<ConstantInt>(StatepointCS.getArgument(DeoptArgsStart)),
           "gc.statepoint: number of deoptimization arguments must be "
           "a constant integer");
    const int NumDeoptArgs =
        cast<ConstantInt>(StatepointCS.getArgument(DeoptArgsStart))
            ->getZExtValue();
    const int GCParamArgsStart = DeoptArgsStart + 1 + NumDeoptArgs;
    const int GCParamArgsEnd = StatepointCS.arg_size();
    Assert(GCParamArgsStart <= BaseIndex && BaseIndex < GCParamArgsEnd,
           "gc.relocate: statepoint base index doesn't fall within the "
           "'gc parameters' section of the statepoint call",
           CS);
    Assert(GCParamArgsStart <= DerivedIndex && DerivedIndex < GCParamArgsEnd,
           "gc.relocate: statepoint derived index doesn't fall within the "
           "'gc parameters' section of the statepoint call",
           CS);

    // Relocated value must be either a pointer type or vector-of-pointer type,
    // but gc_relocate does not need to return the same pointer type as the
    // relocated pointer. It can be casted to the correct type later if it's
    // desired. However, they must have the same address space and 'vectorness'
    GCRelocateInst &Relocate = cast<GCRelocateInst>(*CS.getInstruction());
    Assert(Relocate.getDerivedPtr()->getType()->getScalarType()->isPointerTy(),
           "gc.relocate: relocated value must be a gc pointer", CS);

    auto ResultType = CS.getType();
    auto DerivedType = Relocate.getDerivedPtr()->getType();
    Assert(ResultType->isVectorTy() == DerivedType->isVectorTy(),
           "gc.relocate: vector relocates to vector and pointer to pointer",
           CS);
    Assert(
        ResultType->getPointerAddressSpace() ==
            DerivedType->getPointerAddressSpace(),
        "gc.relocate: relocating a pointer shouldn't change its address space",
        CS);
    break;
  }
  case Intrinsic::eh_exceptioncode:
  case Intrinsic::eh_exceptionpointer: {
    Assert(isa<CatchPadInst>(CS.getArgOperand(0)),
           "eh.exceptionpointer argument must be a catchpad", CS);
    break;
  }
  case Intrinsic::masked_load: {
    Assert(CS.getType()->isVectorTy(), "masked_load: must return a vector", CS);
    
    Value *Ptr = CS.getArgOperand(0);
    //Value *Alignment = CS.getArgOperand(1);
    Value *Mask = CS.getArgOperand(2);
    Value *PassThru = CS.getArgOperand(3);
    Assert(Mask->getType()->isVectorTy(),
           "masked_load: mask must be vector", CS);

    // DataTy is the overloaded type
    Type *DataTy = cast<PointerType>(Ptr->getType())->getElementType();
    Assert(DataTy == CS.getType(), 
           "masked_load: return must match pointer type", CS);
    Assert(PassThru->getType() == DataTy,
           "masked_load: pass through and data type must match", CS);
    Assert(Mask->getType()->getVectorNumElements() ==
           DataTy->getVectorNumElements(), 
           "masked_load: vector mask must be same length as data", CS);
    break;
  }
  case Intrinsic::masked_store: {
    Value *Val = CS.getArgOperand(0);
    Value *Ptr = CS.getArgOperand(1);
    //Value *Alignment = CS.getArgOperand(2);
    Value *Mask = CS.getArgOperand(3);
    Assert(Mask->getType()->isVectorTy(),
           "masked_store: mask must be vector", CS);

    // DataTy is the overloaded type
    Type *DataTy = cast<PointerType>(Ptr->getType())->getElementType();
    Assert(DataTy == Val->getType(), 
           "masked_store: storee must match pointer type", CS);
    Assert(Mask->getType()->getVectorNumElements() ==
           DataTy->getVectorNumElements(), 
           "masked_store: vector mask must be same length as data", CS);
    break;
  }

  case Intrinsic::experimental_guard: {
    Assert(CS.isCall(), "experimental_guard cannot be invoked", CS);
    Assert(CS.countOperandBundlesOfType(LLVMContext::OB_deopt) == 1,
           "experimental_guard must have exactly one "
           "\"deopt\" operand bundle");
    break;
  }

  case Intrinsic::experimental_deoptimize: {
    Assert(CS.isCall(), "experimental_deoptimize cannot be invoked", CS);
    Assert(CS.countOperandBundlesOfType(LLVMContext::OB_deopt) == 1,
           "experimental_deoptimize must have exactly one "
           "\"deopt\" operand bundle");
    Assert(CS.getType() == CS.getInstruction()->getFunction()->getReturnType(),
           "experimental_deoptimize return type must match caller return type");

    if (CS.isCall()) {
      auto *DeoptCI = CS.getInstruction();
      auto *RI = dyn_cast<ReturnInst>(DeoptCI->getNextNode());
      Assert(RI,
             "calls to experimental_deoptimize must be followed by a return");

      if (!CS.getType()->isVoidTy() && RI)
        Assert(RI->getReturnValue() == DeoptCI,
               "calls to experimental_deoptimize must be followed by a return "
               "of the value computed by experimental_deoptimize");
    }

    break;
  }
  };
}

/// \brief Carefully grab the subprogram from a local scope.
///
/// This carefully grabs the subprogram from a local scope, avoiding the
/// built-in assertions that would typically fire.
static DISubprogram *getSubprogram(Metadata *LocalScope) {
  if (!LocalScope)
    return nullptr;

  if (auto *SP = dyn_cast<DISubprogram>(LocalScope))
    return SP;

  if (auto *LB = dyn_cast<DILexicalBlockBase>(LocalScope))
    return getSubprogram(LB->getRawScope());

  // Just return null; broken scope chains are checked elsewhere.
  assert(!isa<DILocalScope>(LocalScope) && "Unknown type of local scope");
  return nullptr;
}

template <class DbgIntrinsicTy>
void Verifier::visitDbgIntrinsic(StringRef Kind, DbgIntrinsicTy &DII) {
  auto *MD = cast<MetadataAsValue>(DII.getArgOperand(0))->getMetadata();
  AssertDI(isa<ValueAsMetadata>(MD) ||
             (isa<MDNode>(MD) && !cast<MDNode>(MD)->getNumOperands()),
         "invalid llvm.dbg." + Kind + " intrinsic address/value", &DII, MD);
  AssertDI(isa<DILocalVariable>(DII.getRawVariable()),
         "invalid llvm.dbg." + Kind + " intrinsic variable", &DII,
         DII.getRawVariable());
  AssertDI(isa<DIExpression>(DII.getRawExpression()),
         "invalid llvm.dbg." + Kind + " intrinsic expression", &DII,
         DII.getRawExpression());

  // Ignore broken !dbg attachments; they're checked elsewhere.
  if (MDNode *N = DII.getDebugLoc().getAsMDNode())
    if (!isa<DILocation>(N))
      return;

  BasicBlock *BB = DII.getParent();
  Function *F = BB ? BB->getParent() : nullptr;

  // The scopes for variables and !dbg attachments must agree.
  DILocalVariable *Var = DII.getVariable();
  DILocation *Loc = DII.getDebugLoc();
  Assert(Loc, "llvm.dbg." + Kind + " intrinsic requires a !dbg attachment",
         &DII, BB, F);

  DISubprogram *VarSP = getSubprogram(Var->getRawScope());
  DISubprogram *LocSP = getSubprogram(Loc->getRawScope());
  if (!VarSP || !LocSP)
    return; // Broken scope chains are checked elsewhere.

  Assert(VarSP == LocSP, "mismatched subprogram between llvm.dbg." + Kind +
                             " variable and !dbg attachment",
         &DII, BB, F, Var, Var->getScope()->getSubprogram(), Loc,
         Loc->getScope()->getSubprogram());
}

static uint64_t getVariableSize(const DILocalVariable &V) {
  // Be careful of broken types (checked elsewhere).
  const Metadata *RawType = V.getRawType();
  while (RawType) {
    // Try to get the size directly.
    if (auto *T = dyn_cast<DIType>(RawType))
      if (uint64_t Size = T->getSizeInBits())
        return Size;

    if (auto *DT = dyn_cast<DIDerivedType>(RawType)) {
      // Look at the base type.
      RawType = DT->getRawBaseType();
      continue;
    }

    // Missing type or size.
    break;
  }

  // Fail gracefully.
  return 0;
}

void Verifier::verifyBitPieceExpression(const DbgInfoIntrinsic &I) {
  DILocalVariable *V;
  DIExpression *E;
  if (auto *DVI = dyn_cast<DbgValueInst>(&I)) {
    V = dyn_cast_or_null<DILocalVariable>(DVI->getRawVariable());
    E = dyn_cast_or_null<DIExpression>(DVI->getRawExpression());
  } else {
    auto *DDI = cast<DbgDeclareInst>(&I);
    V = dyn_cast_or_null<DILocalVariable>(DDI->getRawVariable());
    E = dyn_cast_or_null<DIExpression>(DDI->getRawExpression());
  }

  // We don't know whether this intrinsic verified correctly.
  if (!V || !E || !E->isValid())
    return;

  // Nothing to do if this isn't a bit piece expression.
  if (!E->isBitPiece())
    return;

  // The frontend helps out GDB by emitting the members of local anonymous
  // unions as artificial local variables with shared storage. When SROA splits
  // the storage for artificial local variables that are smaller than the entire
  // union, the overhang piece will be outside of the allotted space for the
  // variable and this check fails.
  // FIXME: Remove this check as soon as clang stops doing this; it hides bugs.
  if (V->isArtificial())
    return;

  // If there's no size, the type is broken, but that should be checked
  // elsewhere.
  uint64_t VarSize = getVariableSize(*V);
  if (!VarSize)
    return;

  unsigned PieceSize = E->getBitPieceSize();
  unsigned PieceOffset = E->getBitPieceOffset();
  Assert(PieceSize + PieceOffset <= VarSize,
         "piece is larger than or outside of variable", &I, V, E);
  Assert(PieceSize != VarSize, "piece covers entire variable", &I, V, E);
}

void Verifier::verifyCompileUnits() {
  auto *CUs = M->getNamedMetadata("llvm.dbg.cu");
  SmallPtrSet<const Metadata *, 2> Listed;
  if (CUs)
    Listed.insert(CUs->op_begin(), CUs->op_end());
  Assert(
      std::all_of(CUVisited.begin(), CUVisited.end(),
                  [&Listed](const Metadata *CU) { return Listed.count(CU); }),
      "All DICompileUnits must be listed in llvm.dbg.cu");
  CUVisited.clear();
}

void Verifier::verifyDeoptimizeCallingConvs() {
  if (DeoptimizeDeclarations.empty())
    return;

  const Function *First = DeoptimizeDeclarations[0];
  for (auto *F : makeArrayRef(DeoptimizeDeclarations).slice(1)) {
    Assert(First->getCallingConv() == F->getCallingConv(),
           "All llvm.experimental.deoptimize declarations must have the same "
           "calling convention",
           First, F);
  }
}

//===----------------------------------------------------------------------===//
//  Implement the public interfaces to this file...
//===----------------------------------------------------------------------===//

bool llvm::verifyFunction(const Function &f, raw_ostream *OS) {
  Function &F = const_cast<Function &>(f);

  // Don't use a raw_null_ostream.  Printing IR is expensive.
  Verifier V(OS, /*ShouldTreatBrokenDebugInfoAsError=*/true);

  // Note that this function's return value is inverted from what you would
  // expect of a function called "verify".
  return !V.verify(F);
}

bool llvm::verifyModule(const Module &M, raw_ostream *OS,
                        bool *BrokenDebugInfo) {
  // Don't use a raw_null_ostream.  Printing IR is expensive.
  Verifier V(OS, /*ShouldTreatBrokenDebugInfoAsError=*/!BrokenDebugInfo);

  bool Broken = false;
  for (const Function &F : M)
    Broken |= !V.verify(F);

  Broken |= !V.verify(M);
  if (BrokenDebugInfo)
    *BrokenDebugInfo = V.hasBrokenDebugInfo();
  // Note that this function's return value is inverted from what you would
  // expect of a function called "verify".
  return Broken;
}

namespace {
struct VerifierLegacyPass : public FunctionPass {
  static char ID;

  Verifier V;
  bool FatalErrors = true;

  VerifierLegacyPass()
      : FunctionPass(ID),
        V(&dbgs(), /*ShouldTreatBrokenDebugInfoAsError=*/false) {
    initializeVerifierLegacyPassPass(*PassRegistry::getPassRegistry());
  }
  explicit VerifierLegacyPass(bool FatalErrors)
      : FunctionPass(ID),
        V(&dbgs(), /*ShouldTreatBrokenDebugInfoAsError=*/false),
        FatalErrors(FatalErrors) {
    initializeVerifierLegacyPassPass(*PassRegistry::getPassRegistry());
  }

  bool runOnFunction(Function &F) override {
    if (!V.verify(F) && FatalErrors)
      report_fatal_error("Broken function found, compilation aborted!");

    return false;
  }

  bool doFinalization(Module &M) override {
    bool HasErrors = false;
    for (Function &F : M)
      if (F.isDeclaration())
        HasErrors |= !V.verify(F);

    HasErrors |= !V.verify(M);
    if (FatalErrors) {
      if (HasErrors)
        report_fatal_error("Broken module found, compilation aborted!");
      assert(!V.hasBrokenDebugInfo() && "Module contains invalid debug info");
    }

    // Strip broken debug info.
    if (V.hasBrokenDebugInfo()) {
      DiagnosticInfoIgnoringInvalidDebugMetadata DiagInvalid(M);
      M.getContext().diagnose(DiagInvalid);
      if (!StripDebugInfo(M))
        report_fatal_error("Failed to strip malformed debug info");
    }
    return false;
  }

  void getAnalysisUsage(AnalysisUsage &AU) const override {
    AU.setPreservesAll();
  }
};
}

char VerifierLegacyPass::ID = 0;
INITIALIZE_PASS(VerifierLegacyPass, "verify", "Module Verifier", false, false)

FunctionPass *llvm::createVerifierPass(bool FatalErrors) {
  return new VerifierLegacyPass(FatalErrors);
}

char VerifierAnalysis::PassID;
VerifierAnalysis::Result VerifierAnalysis::run(Module &M,
                                               ModuleAnalysisManager &) {
  Result Res;
  Res.IRBroken = llvm::verifyModule(M, &dbgs(), &Res.DebugInfoBroken);
  return Res;
}

VerifierAnalysis::Result VerifierAnalysis::run(Function &F,
                                               FunctionAnalysisManager &) {
  return { llvm::verifyFunction(F, &dbgs()), false };
}

PreservedAnalyses VerifierPass::run(Module &M, ModuleAnalysisManager &AM) {
  auto Res = AM.getResult<VerifierAnalysis>(M);
  if (FatalErrors) {
    if (Res.IRBroken)
      report_fatal_error("Broken module found, compilation aborted!");
    assert(!Res.DebugInfoBroken && "Module contains invalid debug info");
  }

  // Strip broken debug info.
  if (Res.DebugInfoBroken) {
    DiagnosticInfoIgnoringInvalidDebugMetadata DiagInvalid(M);
    M.getContext().diagnose(DiagInvalid);
    if (!StripDebugInfo(M))
      report_fatal_error("Failed to strip malformed debug info");
  }
  return PreservedAnalyses::all();
}

PreservedAnalyses VerifierPass::run(Function &F, FunctionAnalysisManager &AM) {
  auto res = AM.getResult<VerifierAnalysis>(F);
  if (res.IRBroken && FatalErrors)
    report_fatal_error("Broken function found, compilation aborted!");

  return PreservedAnalyses::all();
}

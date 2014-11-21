//===- InstrumentationBindings.cpp - instrumentation bindings -------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file defines C bindings for the instrumentation component.
//
//===----------------------------------------------------------------------===//

#include "InstrumentationBindings.h"

#include "llvm-c/Core.h"
#include "llvm/IR/Module.h"
#include "llvm/PassManager.h"
#include "llvm/Transforms/Instrumentation.h"

using namespace llvm;

void LLVMAddAddressSanitizerFunctionPass(LLVMPassManagerRef PM) {
  unwrap(PM)->add(createAddressSanitizerFunctionPass());
}

void LLVMAddAddressSanitizerModulePass(LLVMPassManagerRef PM) {
  unwrap(PM)->add(createAddressSanitizerModulePass());
}

void LLVMAddThreadSanitizerPass(LLVMPassManagerRef PM) {
  unwrap(PM)->add(createThreadSanitizerPass());
}

void LLVMAddMemorySanitizerPass(LLVMPassManagerRef PM) {
  unwrap(PM)->add(createMemorySanitizerPass());
}

void LLVMAddDataFlowSanitizerPass(LLVMPassManagerRef PM,
                                  const char *ABIListFile) {
  unwrap(PM)->add(createDataFlowSanitizerPass(ABIListFile));
}

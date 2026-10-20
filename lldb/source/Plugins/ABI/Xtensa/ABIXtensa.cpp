//===-- ABIXtensa.cpp -----------------------------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "ABIXtensa.h"
#include "lldb/Core/PluginManager.h"
#include "lldb/Utility/ArchSpec.h"

using namespace lldb;
using namespace lldb_private;

LLDB_PLUGIN_DEFINE(ABIXtensa)

void ABIXtensa::Initialize() {
  PluginManager::RegisterPlugin(GetPluginNameStatic(), "Xtensa ABI",
                                CreateInstance);
}

void ABIXtensa::Terminate() { PluginManager::UnregisterPlugin(CreateInstance); }

ABISP ABIXtensa::CreateInstance(ProcessSP process_sp, const ArchSpec &arch) {
  if (arch.GetMachine() != llvm::Triple::xtensa)
    return {};
  return ABISP(new ABIXtensa(process_sp, MakeMCRegisterInfo(arch)));
}

Status ABIXtensa::SetReturnValueObject(StackFrameSP &, ValueObjectSP &) {
  return Status::FromErrorString("Setting Xtensa return values is unsupported");
}

UnwindPlanSP ABIXtensa::CreateFunctionEntryUnwindPlan() {
  UnwindPlan::Row row;
  row.GetCFAValue().SetIsRegisterPlusOffset(LLDB_REGNUM_GENERIC_SP, 0);
  // A windowed return address contains the window increment in its top bits.
  // The architecture plugin supplies the decoded PC and the caller's window.
  // Stop if it cannot recover them instead of reporting an encoded RA as a PC.
  row.SetRegisterLocationToUndefined(LLDB_REGNUM_GENERIC_PC, true, false);
  row.SetUnspecifiedRegistersAreUndefined(true);
  auto plan = std::make_shared<UnwindPlan>(eRegisterKindGeneric);
  plan->AppendRow(std::move(row));
  plan->SetSourceName("Xtensa register-window fallback");
  plan->SetSourcedFromCompiler(eLazyBoolNo);
  plan->SetUnwindPlanValidAtAllInstructions(eLazyBoolNo);
  plan->SetUnwindPlanForSignalTrap(eLazyBoolNo);
  return plan;
}

UnwindPlanSP ABIXtensa::CreateDefaultUnwindPlan() {
  return CreateFunctionEntryUnwindPlan();
}

void ABIXtensa::AugmentRegisterInfo(
    std::vector<DynamicRegisterInfo::Register> &regs) {
  for (auto &reg : regs) {
    llvm::StringRef name = reg.name.GetStringRef();
    unsigned number;
    if (name.consume_front("a") && !name.getAsInteger(10, number) &&
        number < 16) {
      reg.regnum_dwarf = reg.regnum_ehframe = number;
      if (number == 0)
        reg.regnum_generic = LLDB_REGNUM_GENERIC_RA;
      else if (number == 1) {
        reg.regnum_generic = LLDB_REGNUM_GENERIC_SP;
        reg.alt_name = ConstString("sp");
      } else if (number == 7) {
        reg.regnum_generic = LLDB_REGNUM_GENERIC_FP;
        reg.alt_name = ConstString("fp");
      } else if (number >= 2 && number <= 6)
        reg.regnum_generic = LLDB_REGNUM_GENERIC_ARG1 + number - 2;
      continue;
    }
    name = reg.name.GetStringRef();
    if (name.consume_front("f") && !name.getAsInteger(10, number) &&
        number < 16) {
      reg.regnum_dwarf = reg.regnum_ehframe = 19 + number;
      continue;
    }
    if (reg.name == "pc")
      reg.regnum_generic = LLDB_REGNUM_GENERIC_PC;
    else if (reg.name == "ps")
      reg.regnum_generic = LLDB_REGNUM_GENERIC_FLAGS;
  }
}

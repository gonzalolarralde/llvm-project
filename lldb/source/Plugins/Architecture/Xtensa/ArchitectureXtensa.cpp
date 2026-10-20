//===-- ArchitectureXtensa.cpp --------------------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "ArchitectureXtensa.h"
#include "lldb/Core/PluginManager.h"
#include "lldb/Symbol/UnwindPlan.h"
#include "lldb/Target/Process.h"
#include "lldb/Target/RegisterContextUnwind.h"
#include "lldb/Target/Thread.h"
#include "lldb/Utility/ArchSpec.h"
#include "lldb/Utility/RegisterValue.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/Twine.h"

using namespace lldb;
using namespace lldb_private;

LLDB_PLUGIN_DEFINE(ArchitectureXtensa)

void ArchitectureXtensa::Initialize() {
  PluginManager::RegisterPlugin(GetPluginNameStatic(),
                                "Xtensa register-window unwinding", Create);
}

void ArchitectureXtensa::Terminate() {
  PluginManager::UnregisterPlugin(Create);
}

std::unique_ptr<Architecture> ArchitectureXtensa::Create(const ArchSpec &arch) {
  if (arch.GetMachine() != llvm::Triple::xtensa)
    return {};
  return std::make_unique<ArchitectureXtensa>();
}

UnwindPlanSP ArchitectureXtensa::GetArchitectureUnwindPlan(
    Thread &thread, RegisterContextUnwind *regctx,
    std::shared_ptr<const UnwindPlan> current_unwindplan) {
  ProcessSP process = thread.GetProcess();
  RegisterContextSP live = thread.GetRegisterContext();
  if (!process || !live || regctx->IsTrapHandlerFrame())
    return {};

  auto read = [](RegisterContext &ctx,
                 llvm::StringRef name) -> std::optional<uint32_t> {
    const RegisterInfo *info = ctx.GetRegisterInfoByName(name);
    RegisterValue value;
    if (!info || !ctx.ReadRegister(info, value))
      return std::nullopt;
    return value.GetAsUInt32();
  };
  auto memory = [&](addr_t address) -> std::optional<uint32_t> {
    Status error;
    uint32_t value =
        process->ReadUnsignedIntegerFromMemory(address, 4, 0, error);
    if (error.Fail())
      return std::nullopt;
    return value;
  };

  auto pc = read(*regctx, "pc");
  auto sp = read(*regctx, "a1");
  auto wb = read(*regctx, "windowbase");
  auto ws = read(*regctx, "windowstart");
  if (!pc || !sp || !wb || !ws)
    return {};

  // ENTRY identifies a windowed function. Do not reinterpret CALL0 return
  // addresses, interrupt frames, or arbitrary assembly as windowed frames.
  addr_t start;
  if (!regctx->GetStartPC(start) || start == LLDB_INVALID_ADDRESS)
    return {};
  Status error;
  uint64_t entry = process->ReadUnsignedIntegerFromMemory(start, 1, 0, error);
  if (error.Fail() || (entry & 0xff) != 0x36)
    return {};

  unsigned num_aregs = 0;
  while (live->GetRegisterInfoByName(
      (llvm::Twine("ar") + llvm::Twine(num_aregs)).str()))
    ++num_aregs;
  if ((num_aregs != 32 && num_aregs != 64) || *wb >= num_aregs / 4)
    return {};

  UnwindPlan::Row row;
  row.SetUnspecifiedRegistersAreUndefined(true);
  auto set = [&](llvm::StringRef name, uint32_t value) {
    // The CFA is the incoming stack pointer, including before ENTRY. Using
    // the current SP would change frame identity in the prologue and prevent
    // source stepping from recognizing that a call entered a younger frame.
    if (name == "a1")
      row.GetCFAValue().SetIsConstant(value);
    if (const RegisterInfo *info = regctx->GetRegisterInfoByName(name))
      row.SetRegisterLocationToIsConstant(info->kinds[eRegisterKindLLDB], value,
                                          true);
  };

  std::optional<uint32_t> ra;
  if (*pc == start) {
    // CALL has set PS.CALLINC and the outgoing return register, but ENTRY
    // has not rotated the register window yet.
    auto ps = read(*regctx, "ps");
    if (!ps || ((*ps >> 16) & 3) == 0)
      return {};
    unsigned rotation = ((*ps >> 16) & 3) * 4;
    ra = read(*regctx, (llvm::Twine("a") + llvm::Twine(rotation)).str());
    for (unsigned i = 0; i < rotation; ++i) {
      std::string name = (llvm::Twine("a") + llvm::Twine(i)).str();
      if (auto value = read(*regctx, name))
        set(name, *value);
    }
    set("windowbase", *wb);
    set("windowstart", *ws);
  } else {
    ra = read(*regctx, "a0");
    if (!ra || (*ra >> 30) == 0)
      return {};
    unsigned callinc = *ra >> 30;
    unsigned caller_wb = (*wb + num_aregs / 4 - callinc) % (num_aregs / 4);
    uint32_t caller_ws = *ws & ~(1u << *wb);
    unsigned preserved = callinc * 4;
    if (caller_ws & (1u << caller_wb)) {
      // The caller's window still resides in the physical register file.
      for (unsigned i = 0; i < preserved; ++i) {
        unsigned physical = (caller_wb * 4 + i) % num_aregs;
        auto value =
            read(*live, (llvm::Twine("ar") + llvm::Twine(physical)).str());
        if (!value)
          return {};
        set((llvm::Twine("a") + llvm::Twine(i)).str(), *value);
      }
    } else {
      // Window overflow saves a0-a3 below the callee's SP. Remaining
      // registers occupy the caller's extra save area, below its caller's SP.
      llvm::SmallVector<uint32_t, 12> saved;
      for (unsigned i = 0; i < 4; ++i) {
        auto value = memory(*sp - 16 + i * 4);
        if (!value)
          return {};
        saved.push_back(*value);
      }
      if (preserved > 4) {
        auto previous_sp = memory(saved[1] - 12);
        if (!previous_sp)
          return {};
        for (unsigned i = 4; i < preserved; ++i) {
          auto value = memory(*previous_sp - (preserved + 4 - i) * 4);
          if (!value)
            return {};
          saved.push_back(*value);
        }
      }
      for (unsigned i = 0; i < preserved; ++i)
        set((llvm::Twine("a") + llvm::Twine(i)).str(), saved[i]);
    }
    set("windowbase", caller_wb);
    set("windowstart", caller_ws);
  }
  if (!ra)
    return {};
  set("pc", (*ra & 0x3fffffff) | (*pc & 0xc0000000));
  auto plan = std::make_shared<UnwindPlan>(eRegisterKindLLDB);
  plan->AppendRow(std::move(row));
  plan->SetSourceName("Xtensa windowed ABI");
  plan->SetSourcedFromCompiler(eLazyBoolNo);
  plan->SetUnwindPlanValidAtAllInstructions(eLazyBoolYes);
  plan->SetUnwindPlanForSignalTrap(eLazyBoolNo);
  return plan;
}

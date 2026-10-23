//===-- ArchitectureXtensa.cpp --------------------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "ArchitectureXtensa.h"
#include "lldb/Core/Disassembler.h"
#include "lldb/Core/PluginManager.h"
#include "lldb/Symbol/Symbol.h"
#include "lldb/Symbol/UnwindPlan.h"
#include "lldb/Target/Process.h"
#include "lldb/Target/RegisterContextUnwind.h"
#include "lldb/Target/Target.h"
#include "lldb/Target/Thread.h"
#include "lldb/Utility/ArchSpec.h"
#include "lldb/Utility/RegisterValue.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/Twine.h"
#include <array>

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

std::optional<uint32_t>
ArchitectureXtensa::DecodeEntryFrameSize(llvm::ArrayRef<uint8_t> bytes) {
  // ENTRY is BRI12: op0=6, n=3, m=0, s=1 (a1), imm12 scaled by eight.
  if (bytes.size() != 3 || bytes[0] != 0x36 || (bytes[1] & 0xf) != 1)
    return std::nullopt;
  return ((bytes[1] >> 4) | (uint32_t(bytes[2]) << 4)) * 8;
}

bool ArchitectureXtensa::EntryBoundaryCannotBeRevisited(
    const ArchSpec &arch, llvm::ArrayRef<uint8_t> bytes) {
  // Decode a complete, bounded symbol, without symbol substitution in operands.
  // Do not cache this proof across stops: code memory can change on resume.
  if (bytes.size() <= 3 || bytes.size() > 64 * 1024 ||
      !DecodeEntryFrameSize(bytes.take_front(3)))
    return false;
  auto disassembler = Disassembler::DisassembleBytes(
      arch, nullptr, nullptr, nullptr, nullptr, Address(addr_t(0)),
      bytes.data(), bytes.size(), bytes.size(), false);
  if (!disassembler)
    return false;

  auto &instructions = disassembler->GetInstructionList();
  llvm::SmallVector<addr_t, 32> boundaries;
  llvm::SmallVector<addr_t, 16> destinations;
  size_t consumed = 0;
  bool terminal = false;
  for (size_t i = 0; i < instructions.GetSize(); ++i) {
    auto instruction = instructions.GetInstructionAtIndex(i);
    if (!instruction || instruction->GetAddress().GetFileAddress() != consumed)
      return false;
    boundaries.push_back(consumed);
    size_t size = instruction->GetOpcode().GetByteSize();
    if (size < 2 || size > 3 || size > bytes.size() - consumed)
      return false;
    consumed += size;
    llvm::StringRef mnemonic = instruction->GetMnemonic(nullptr);
    // Unknown instructions, explicit special-register writes (including loop
    // registers), and a second ENTRY cannot establish a unique entry boundary.
    if (mnemonic.empty() || mnemonic.starts_with(".") ||
        mnemonic.starts_with("wsr") || mnemonic.starts_with("xsr") ||
        (i != 0 && mnemonic == "entry"))
      return false;
    terminal = mnemonic == "retw" || mnemonic == "retw.n" || mnemonic == "j";
    if (mnemonic == "retw" || mnemonic == "retw.n")
      continue;
    if (!instruction->DoesBranch() && !mnemonic.starts_with("loop"))
      continue;

    // LLVMC prints direct Xtensa branch/call targets as absolute addresses.
    // Register-indirect or unrecognized transfers fail this parse.
    llvm::StringRef operands = instruction->GetOperands(nullptr);
    llvm::StringRef destination = operands.rsplit(',').second.trim();
    if (destination.empty())
      destination = operands.trim();
    addr_t target;
    if (destination.getAsInteger(0, target))
      return false;
    if (instruction->IsCall()) {
      // Recursion through the proper ENTRY creates a new frame. Calls into the
      // middle of this symbol do not establish that frame and are not proven.
      if (target != 0 && target < bytes.size())
        return false;
      continue;
    }
    if (target <= 3 || target >= bytes.size())
      return false;
    destinations.push_back(target);
  }
  if (consumed != bytes.size() || !terminal)
    return false;
  // A target inside an instruction could decode an entirely different path.
  return llvm::all_of(destinations, [&](addr_t target) {
    return llvm::is_contained(boundaries, target);
  });
}

static bool HasUniqueEntryBoundary(Process &process, addr_t start) {
  Target &target = process.GetTarget();
  Address address;
  if ((start & 3) != 0 || !target.ResolveLoadAddress(start, address))
    return false;
  Symbol *symbol = address.CalculateSymbolContextSymbol();
  if (!symbol || symbol->GetType() != eSymbolTypeCode ||
      !symbol->GetByteSizeIsValid() || symbol->GetSizeIsSynthesized() ||
      symbol->GetAddressRef().GetLoadAddress(&target) != start)
    return false;
  addr_t size = symbol->GetByteSize();
  if (size <= 3 || size > 64 * 1024)
    return false;
  llvm::SmallVector<uint8_t, 256> bytes(size);
  Status error;
  if (process.ReadMemory(start, bytes.data(), size, error) != size ||
      error.Fail())
    return false;
  return ArchitectureXtensa::EntryBoundaryCannotBeRevisited(
      target.GetArchitecture(), bytes);
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
  std::array<uint8_t, 3> entry;
  if (process->ReadMemory(start, entry.data(), entry.size(), error) !=
          entry.size() ||
      error.Fail())
    return {};
  auto entry_frame_size = DecodeEntryFrameSize(entry);
  if (!entry_frame_size)
    return {};

  unsigned num_aregs = 0;
  while (live->GetRegisterInfoByName(
      (llvm::Twine("ar") + llvm::Twine(num_aregs)).str()))
    ++num_aregs;
  if ((num_aregs != 32 && num_aregs != 64) || *wb >= num_aregs / 4)
    return {};

  UnwindPlan::Row row;
  row.SetUnspecifiedRegistersAreUndefined(true);
  std::optional<uint32_t> caller_sp;
  auto set = [&](llvm::StringRef name, uint32_t value) {
    // The CFA is the incoming stack pointer, including before ENTRY. Using
    // the current SP would change frame identity in the prologue and prevent
    // source stepping from recognizing that a call entered a younger frame.
    if (name == "a1") {
      row.GetCFAValue().SetIsConstant(value);
      caller_sp = value;
    }
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
    // Before ENTRY only CALL's return-register slot has been overwritten.
    // This transient recovery is valid only for the currently stopped frame;
    // older frames must not borrow the live callee's volatile registers.
    unsigned limit = (regctx->GetConcreteFrameIndex() == 0 &&
                      HasUniqueEntryBoundary(*process, start))
                         ? 16
                         : rotation;
    for (unsigned i = 0; i < limit; ++i) {
      if (i == rotation)
        continue;
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
    // Immediately after ENTRY, overlapping a2 and above have not yet been
    // changed by the callee. CALL wrote its RA slot and ENTRY wrote its SP
    // slot, so those two caller locations remain undefined. Check the decoded
    // ENTRY's stack adjustment as well as its exact instruction boundary.
    // Beyond this boundary (including RETW) arbitrary callee writes make the
    // volatile overlap unavailable, even if the physical register is readable.
    if (regctx->GetConcreteFrameIndex() == 0 && *pc == start + entry.size() &&
        caller_sp && uint64_t(*sp) + *entry_frame_size == *caller_sp &&
        HasUniqueEntryBoundary(*process, start)) {
      for (unsigned i = preserved + 2; i < 16; ++i) {
        auto value = read(
            *regctx, (llvm::Twine("a") + llvm::Twine(i - preserved)).str());
        if (value)
          set((llvm::Twine("a") + llvm::Twine(i)).str(), *value);
      }
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

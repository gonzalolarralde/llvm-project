//===-- ArchitectureXtensa.h ------------------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef LLDB_SOURCE_PLUGINS_ARCHITECTURE_XTENSA_ARCHITECTUREXTENSA_H
#define LLDB_SOURCE_PLUGINS_ARCHITECTURE_XTENSA_ARCHITECTUREXTENSA_H

#include "lldb/Core/Architecture.h"
#include "llvm/ADT/ArrayRef.h"
#include <optional>

namespace lldb_private {

class ArchitectureXtensa : public Architecture {
public:
  static llvm::StringRef GetPluginNameStatic() { return "xtensa"; }
  static void Initialize();
  static void Terminate();
  llvm::StringRef GetPluginName() override { return GetPluginNameStatic(); }
  void OverrideStopInfo(Thread &) const override {}

  // Decode the canonical three-byte ENTRY a1, imm used by windowed frames.
  // A partial read or an ENTRY with a different SP operand is not sufficient.
  static std::optional<uint32_t>
  DecodeEntryFrameSize(llvm::ArrayRef<uint8_t> bytes);

  // A complete function body must prove that no path revisits ENTRY or its
  // first body instruction before transient overlap registers can be trusted.
  static bool EntryBoundaryCannotBeRevisited(const ArchSpec &arch,
                                             llvm::ArrayRef<uint8_t> bytes);

  lldb::UnwindPlanSP GetArchitectureUnwindPlan(
      Thread &thread, RegisterContextUnwind *regctx,
      std::shared_ptr<const UnwindPlan> current_unwindplan) override;

private:
  static std::unique_ptr<Architecture> Create(const ArchSpec &arch);
};

} // namespace lldb_private
#endif

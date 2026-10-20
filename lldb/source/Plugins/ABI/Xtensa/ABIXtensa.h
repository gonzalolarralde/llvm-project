//===-- ABIXtensa.h ---------------------------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef LLDB_SOURCE_PLUGINS_ABI_XTENSA_ABIXTENSA_H
#define LLDB_SOURCE_PLUGINS_ABI_XTENSA_ABIXTENSA_H

#include "lldb/Target/ABI.h"

class ABIXtensa : public lldb_private::ABI {
public:
  static void Initialize();
  static void Terminate();
  static lldb::ABISP CreateInstance(lldb::ProcessSP process_sp,
                                    const lldb_private::ArchSpec &arch);
  static llvm::StringRef GetPluginNameStatic() { return "xtensa"; }
  llvm::StringRef GetPluginName() override { return GetPluginNameStatic(); }

  size_t GetRedZoneSize() const override { return 0; }

  bool PrepareTrivialCall(lldb_private::Thread &, lldb::addr_t, lldb::addr_t,
                          lldb::addr_t,
                          llvm::ArrayRef<lldb::addr_t>) const override {
    return false;
  }
  bool GetArgumentValues(lldb_private::Thread &,
                         lldb_private::ValueList &) const override {
    return false;
  }
  lldb_private::Status SetReturnValueObject(lldb::StackFrameSP &,
                                            lldb::ValueObjectSP &) override;

  lldb::UnwindPlanSP CreateFunctionEntryUnwindPlan() override;
  lldb::UnwindPlanSP CreateDefaultUnwindPlan() override;
  bool RegisterIsVolatile(const lldb_private::RegisterInfo *) override {
    return true;
  }
  bool CallFrameAddressIsValid(lldb::addr_t cfa) override {
    return cfa != 0 && cfa <= UINT32_MAX && (cfa & 15) == 0;
  }
  bool CodeAddressIsValid(lldb::addr_t pc) override {
    return pc != 0 && pc <= UINT32_MAX;
  }
  void AugmentRegisterInfo(
      std::vector<lldb_private::DynamicRegisterInfo::Register> &regs) override;

private:
  using ABI::ABI;
  lldb::ValueObjectSP
  GetReturnValueObjectImpl(lldb_private::Thread &,
                           lldb_private::CompilerType &) const override {
    return {};
  }
};

#endif

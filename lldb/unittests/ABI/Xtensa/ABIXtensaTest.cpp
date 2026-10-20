//===-- ABIXtensaTest.cpp -------------------------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "Plugins/ABI/Xtensa/ABIXtensa.h"
#include "lldb/Utility/ArchSpec.h"
#include "llvm/Support/TargetSelect.h"
#include "gtest/gtest.h"

using namespace lldb;
using namespace lldb_private;

TEST(ABIXtensaTest, RemoteRegistersAreMappedByName) {
  LLVMInitializeXtensaTargetInfo();
  LLVMInitializeXtensaTargetMC();
  ABISP abi =
      ABIXtensa::CreateInstance({}, ArchSpec("xtensa-unknown-none-elf"));
  ASSERT_TRUE(abi);
  std::vector<DynamicRegisterInfo::Register> regs;
  for (const char *name : {"pc", "ar0", "a7", "f15", "a0", "a1", "a2", "ps",
                           "windowbase", "a15"}) {
    DynamicRegisterInfo::Register reg;
    reg.name = ConstString(name);
    regs.push_back(reg);
  }
  abi->AugmentRegisterInfo(regs);
  EXPECT_EQ(regs[0].regnum_generic, uint32_t(LLDB_REGNUM_GENERIC_PC));
  EXPECT_EQ(regs[1].regnum_dwarf, LLDB_INVALID_REGNUM);
  EXPECT_EQ(regs[2].regnum_dwarf, 7u);
  EXPECT_EQ(regs[2].regnum_generic, uint32_t(LLDB_REGNUM_GENERIC_FP));
  EXPECT_EQ(regs[3].regnum_dwarf, 34u);
  EXPECT_EQ(regs[4].regnum_dwarf, 0u);
  EXPECT_EQ(regs[4].regnum_generic, uint32_t(LLDB_REGNUM_GENERIC_RA));
  EXPECT_EQ(regs[5].regnum_generic, uint32_t(LLDB_REGNUM_GENERIC_SP));
  EXPECT_EQ(regs[6].regnum_generic, uint32_t(LLDB_REGNUM_GENERIC_ARG1));
  EXPECT_EQ(regs[7].regnum_generic, uint32_t(LLDB_REGNUM_GENERIC_FLAGS));
  EXPECT_EQ(regs[8].regnum_dwarf, LLDB_INVALID_REGNUM);
  EXPECT_EQ(regs[9].regnum_dwarf, 15u);
}

TEST(ABIXtensaTest, CodeCanHaveByteAlignmentButStackRequires16Bytes) {
  LLVMInitializeXtensaTargetInfo();
  LLVMInitializeXtensaTargetMC();
  ABISP abi =
      ABIXtensa::CreateInstance({}, ArchSpec("xtensa-unknown-none-elf"));
  ASSERT_TRUE(abi);
  EXPECT_TRUE(abi->CodeAddressIsValid(0x42000003));
  EXPECT_FALSE(abi->CodeAddressIsValid(0x100000000));
  EXPECT_FALSE(abi->CodeAddressIsValid(0));
  EXPECT_TRUE(abi->CallFrameAddressIsValid(0x3fc97e00));
  EXPECT_FALSE(abi->CallFrameAddressIsValid(0x3fc97e04));
  EXPECT_FALSE(abi->CallFrameAddressIsValid(0));
}

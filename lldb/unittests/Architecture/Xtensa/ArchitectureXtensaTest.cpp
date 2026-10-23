//===-- ArchitectureXtensaTest.cpp ---------------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "Plugins/Architecture/Xtensa/ArchitectureXtensa.h"
#include "Plugins/Disassembler/LLVMC/DisassemblerLLVMC.h"
#include "lldb/Utility/ArchSpec.h"
#include "llvm/Support/TargetSelect.h"
#include "gtest/gtest.h"

using namespace lldb_private;

TEST(ArchitectureXtensaTest, DecodesCompleteStackPointerEntry) {
  // Encodings produced by the independent Espressif assembler.
  const uint8_t entry0[] = {0x36, 0x01, 0x00};
  const uint8_t entry32[] = {0x36, 0x41, 0x00};
  const uint8_t entry64[] = {0x36, 0x81, 0x00};
  const uint8_t entry128[] = {0x36, 0x01, 0x01};
  const uint8_t entry32760[] = {0x36, 0xf1, 0xff};
  EXPECT_EQ(ArchitectureXtensa::DecodeEntryFrameSize(entry0), 0u);
  EXPECT_EQ(ArchitectureXtensa::DecodeEntryFrameSize(entry32), 32u);
  EXPECT_EQ(ArchitectureXtensa::DecodeEntryFrameSize(entry64), 64u);
  EXPECT_EQ(ArchitectureXtensa::DecodeEntryFrameSize(entry128), 128u);
  EXPECT_EQ(ArchitectureXtensa::DecodeEntryFrameSize(entry32760), 32760u);
}

TEST(ArchitectureXtensaTest, RejectsIncompleteAndDifferentEntryForms) {
  const uint8_t first_byte_only[] = {0x36};
  const uint8_t truncated[] = {0x36, 0x81};
  const uint8_t extra_byte[] = {0x36, 0x81, 0x00, 0x00};
  const uint8_t different_opcode[] = {0x32, 0x81, 0x00};
  const uint8_t different_m[] = {0x76, 0x81, 0x00};
  const uint8_t different_sp[] = {0x36, 0x82, 0x00};
  EXPECT_FALSE(ArchitectureXtensa::DecodeEntryFrameSize({}));
  EXPECT_FALSE(ArchitectureXtensa::DecodeEntryFrameSize(first_byte_only));
  EXPECT_FALSE(ArchitectureXtensa::DecodeEntryFrameSize(truncated));
  EXPECT_FALSE(ArchitectureXtensa::DecodeEntryFrameSize(extra_byte));
  EXPECT_FALSE(ArchitectureXtensa::DecodeEntryFrameSize(different_opcode));
  EXPECT_FALSE(ArchitectureXtensa::DecodeEntryFrameSize(different_m));
  EXPECT_FALSE(ArchitectureXtensa::DecodeEntryFrameSize(different_sp));
}

class XtensaEntryBoundaryTest : public testing::Test {
public:
  static void SetUpTestSuite() {
    llvm::InitializeAllTargets();
    llvm::InitializeAllAsmPrinters();
    llvm::InitializeAllTargetMCs();
    llvm::InitializeAllDisassemblers();
    DisassemblerLLVMC::Initialize();
  }
  static void TearDownTestSuite() { DisassemblerLLVMC::Terminate(); }

  bool Check(llvm::ArrayRef<uint8_t> bytes) {
    return ArchitectureXtensa::EntryBoundaryCannotBeRevisited(
        ArchSpec("xtensa-esp32s3-none-elf"), bytes);
  }
};

TEST_F(XtensaEntryBoundaryTest, AllowsStraightLineAndOrdinaryRecursion) {
  // All encodings were assembled and linked with the independent GCC tools.
  const uint8_t straight[] = {0x36, 0x81, 0x00, 0x22, 0xa2,
                              0xbe, 0x90, 0x00, 0x00};
  const uint8_t recursive[] = {0x36, 0x81, 0x00, 0xe5, 0xff,
                               0xff, 0x90, 0x00, 0x00};
  const uint8_t later_loop[] = {0x36, 0x81, 0x00, 0x22, 0xa2, 0xbe, 0x32, 0xc3,
                                0xff, 0x56, 0x93, 0xff, 0x90, 0x00, 0x00};
  EXPECT_TRUE(Check(straight));
  EXPECT_TRUE(Check(recursive));
  EXPECT_TRUE(Check(later_loop));
}

TEST_F(XtensaEntryBoundaryTest, RejectsLoopBackAndUnknownTransfers) {
  const uint8_t loop_back[] = {0x36, 0x81, 0x00, 0x22, 0xa2, 0xbe,
                               0x56, 0x93, 0xff, 0x90, 0x00, 0x00};
  const uint8_t middle[] = {0x36, 0x81, 0x00, 0x22, 0xa2, 0xbe,
                            0x56, 0xa3, 0xff, 0x90, 0x00, 0x00};
  const uint8_t indirect[] = {0x36, 0x81, 0x00, 0x22, 0xa2,
                              0xbe, 0xa0, 0x03, 0x00};
  const uint8_t special[] = {0x36, 0x81, 0x00, 0x20, 0x00,
                             0x13, 0x90, 0x00, 0x00};
  const uint8_t unknown[] = {0x36, 0x81, 0x00, 0xff, 0xff, 0xff};
  EXPECT_FALSE(Check(loop_back));
  EXPECT_FALSE(Check(middle));
  EXPECT_FALSE(Check(indirect));
  EXPECT_FALSE(Check(special));
  EXPECT_FALSE(Check(unknown));
}

TEST_F(XtensaEntryBoundaryTest, RejectsAbsentOversizedAndIncompleteBodies) {
  const uint8_t entry_only[] = {0x36, 0x81, 0x00};
  const uint8_t truncated[] = {0x36, 0x81, 0x00, 0x22, 0xa2};
  std::vector<uint8_t> oversized(64 * 1024 + 1);
  oversized[0] = 0x36;
  oversized[1] = 0x81;
  EXPECT_FALSE(Check({}));
  EXPECT_FALSE(Check(entry_only));
  EXPECT_FALSE(Check(truncated));
  EXPECT_FALSE(Check(oversized));
}

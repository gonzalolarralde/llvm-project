//===- DWARFExpressionTest.cpp ---------------------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "llvm/BinaryFormat/Dwarf.h"
#include "llvm/DebugInfo/DWARF/LowLevel/DWARFExpression.h"
#include "llvm/Support/DataExtractor.h"
#include "gtest/gtest.h"

using namespace llvm;
using namespace llvm::dwarf;

namespace {
class TypedConstantExpressionTest : public testing::TestWithParam<uint8_t> {};

TEST_P(TypedConstantExpressionTest, OperandsAndOpaqueBlock) {
  // A multi-byte type reference followed by bytes which would not be valid
  // expression operations on their own. Only stack_value follows the block.
  const uint8_t Bytes[] = {GetParam(), 0xa5, 0x02, 5, 0xf4,
                           0xa4,       0xff, 0x80, 0, DW_OP_stack_value};
  DWARFExpression Expr(DataExtractor(Bytes, true), 8, DWARF32);
  auto It = Expr.begin();
  ASSERT_NE(It, Expr.end());
  ASSERT_FALSE(It->isError());
  EXPECT_EQ(It->getCode(), GetParam());
  EXPECT_EQ(It->getNumOperands(), 3u);
  EXPECT_EQ(It->getDescription().Op[0],
            DWARFExpression::Operation::BaseTypeRef);
  EXPECT_EQ(It->getRawOperand(0), 0x125u);
  EXPECT_EQ(It->getRawOperand(1), 5u);
  EXPECT_EQ(It->getRawOperand(2), 4u);
  EXPECT_EQ(It->getOperandEndOffset(0), 3u);
  EXPECT_EQ(It->getOperandEndOffset(1), 4u);
  EXPECT_EQ(It->getOperandEndOffset(2), 9u);
  EXPECT_EQ(It->getEndOffset(), 9u);
  ++It;
  ASSERT_NE(It, Expr.end());
  ASSERT_FALSE(It->isError());
  EXPECT_EQ(It->getCode(), DW_OP_stack_value);
  ++It;
  EXPECT_EQ(It, Expr.end());
}

TEST_P(TypedConstantExpressionTest, EmptyBlock) {
  const uint8_t Bytes[] = {GetParam(), 0x25, 0};
  DWARFExpression Expr(DataExtractor(Bytes, false), 4, DWARF64);
  auto It = Expr.begin();
  ASSERT_FALSE(It->isError());
  EXPECT_EQ(It->getRawOperand(1), 0u);
  EXPECT_EQ(It->getRawOperand(2), 3u);
  EXPECT_EQ(It->getEndOffset(), 3u);
  EXPECT_EQ(++It, Expr.end());
}

TEST_P(TypedConstantExpressionTest, TruncatedOperandsAndBlock) {
  const uint8_t Bytes[] = {GetParam(), 0xa5, 0x02, 5, 0xf4,
                           0xa4,       0xff, 0x80, 0};
  for (size_t Size = 1; Size < sizeof(Bytes); ++Size) {
    SCOPED_TRACE(Size);
    DWARFExpression Expr(DataExtractor(ArrayRef(Bytes).take_front(Size), true),
                         8, DWARF32);
    auto It = Expr.begin();
    ASSERT_NE(It, Expr.end());
    EXPECT_TRUE(It->isError());
    EXPECT_EQ(++It, Expr.end());
  }
}

TEST_P(TypedConstantExpressionTest, UnterminatedTypeReference) {
  const uint8_t Bytes[] = {GetParam(), 0x80, 0x80, 0x80, 0x80, 0x80,
                           0x80,       0x80, 0x80, 0x80, 0x80, 0x80};
  DWARFExpression Expr(DataExtractor(Bytes, true), 8, DWARF32);
  EXPECT_TRUE(Expr.begin()->isError());
}

INSTANTIATE_TEST_SUITE_P(StandardAndGNU, TypedConstantExpressionTest,
                        testing::Values(DW_OP_const_type, DW_OP_GNU_const_type));
} // namespace

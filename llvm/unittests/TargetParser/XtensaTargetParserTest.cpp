//===- XtensaTargetParserTest.cpp - Xtensa target parser tests --------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "llvm/TargetParser/XtensaTargetParser.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/ADT/Twine.h"
#include "gtest/gtest.h"

using namespace llvm;

TEST(XtensaTargetParser, CPUForTriple) {
  for (StringRef CPU : {"esp32", "esp32s2", "esp32s3"})
    EXPECT_EQ(CPU, Xtensa::getCPUForTriple(
                       Triple(("xtensa-" + CPU + "-none-elf").str())));
  for (StringRef Name : {"xtensa-unknown-none-elf", "xtensa-none-elf",
                         "xtensa-esp32s2extra-none-elf",
                         "riscv32-esp32-none-elf", "arm-esp32s3-none-elf"})
    EXPECT_TRUE(Xtensa::getCPUForTriple(Triple(Name)).empty());
}

TEST(XtensaTargetParser, EspressifCPUFeatures) {
  for (StringRef CPU : {"esp32", "esp32s2", "esp32s3"}) {
    SmallVector<StringRef> Features;
    Xtensa::getCPUFeatures(CPU, Features);
    EXPECT_TRUE(is_contained(Features, "+windowed"));
    EXPECT_EQ(CPU != "esp32s2", is_contained(Features, "+fp"));
    EXPECT_EQ(CPU != "esp32s2", is_contained(Features, "+s32c1i"));
    EXPECT_EQ(CPU == "esp32", is_contained(Features, "+dfpaccel"));
    EXPECT_EQ(CPU == "esp32s2", is_contained(Features, "+esp32s2ops"));
    EXPECT_EQ(CPU == "esp32s3", is_contained(Features, "+esp32s3ops"));
  }
}

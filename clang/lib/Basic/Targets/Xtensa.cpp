//===--- Xtensa.cpp - Implement Xtensa target feature support -------------===//
//
//                     The LLVM Compiler Infrastructure
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file implements Xtensa TargetInfo objects.
//
//===----------------------------------------------------------------------===//

#include "Xtensa.h"
#include "clang/Basic/Builtins.h"
#include "clang/Basic/Diagnostic.h"
#include "clang/Basic/MacroBuilder.h"

using namespace clang;
using namespace clang::targets;

bool XtensaTargetInfo::initFeatureMap(
    llvm::StringMap<bool> &Features, DiagnosticsEngine &Diags, StringRef CPU,
    const std::vector<std::string> &FeaturesVec) const {
  if (CPU.empty())
    CPU = getTriple().getVendorName() == "esp32s3" ? "esp32s3" : "generic";
  if (getTriple().getVendorName() == "esp32s3" && CPU != "esp32s3") {
    Diags.Report(diag::err_target_unsupported_cpu_for_triple)
        << CPU << getTriple().str();
    return false;
  }
  SmallVector<StringRef, 32> CPUFeatures;
  llvm::Xtensa::getCPUFeatures(CPU, CPUFeatures);
  for (StringRef Feature : CPUFeatures)
    Features[Feature.drop_front()] = true;
  if (!TargetInfo::initFeatureMap(Features, Diags, CPU, FeaturesVec))
    return false;

  // The ESP32-S3 triple selects a fixed windowed application ABI. Validate the
  // resolved feature map, including per-function attributes, so repeated flags
  // retain their usual last-option-wins behavior. Instruction-only overrides
  // such as -s32c1i remain available without changing the calling convention.
  if (getTriple().getVendorName() == "esp32s3" &&
      !Features.lookup("windowed")) {
    Diags.Report(diag::err_target_unsupported_abi_for_triple)
        << "call0" << getTriple().str();
    return false;
  }
  return true;
}

bool XtensaTargetInfo::handleTargetFeatures(
    std::vector<std::string> &Features, DiagnosticsEngine &) {
  EnabledFeatures.clear();
  for (StringRef Feature : Features)
    EnabledFeatures[Feature.drop_front()] = Feature.starts_with("+");
  MaxAtomicPromoteWidth = MaxAtomicInlineWidth =
      hasFeature("s32c1i") ? 32 : 0;
  return true;
}

void XtensaTargetInfo::getTargetDefines(const LangOptions &Opts,
                                        MacroBuilder &Builder) const {
  Builder.defineMacro("__xtensa__");
  Builder.defineMacro("__XTENSA__");
  if (BigEndian)
    Builder.defineMacro("__XTENSA_EB__");
  else
    Builder.defineMacro("__XTENSA_EL__");
  Builder.defineMacro("__XCHAL_HAVE_BE", BigEndian ? "1" : "0");
  Builder.defineMacro("__XCHAL_HAVE_ABS");  // core arch
  Builder.defineMacro("__XCHAL_HAVE_ADDX"); // core arch
  Builder.defineMacro("__XCHAL_HAVE_L32R"); // core arch
  Builder.defineMacro("__ELF__");
  Builder.defineMacro(hasFeature("windowed") ? "__XTENSA_WINDOWED_ABI__"
                                            : "__XTENSA_CALL0_ABI__");
  if (!hasFeature("fp"))
    Builder.defineMacro("__XTENSA_SOFT_FLOAT__");
  const std::pair<StringRef, StringRef> Macros[] = {
      {"fp", "__XCHAL_HAVE_FP"}, {"windowed", "__XCHAL_HAVE_WINDOWED"},
      {"density", "__XCHAL_HAVE_DENSITY"}, {"bool", "__XCHAL_HAVE_BOOLEANS"},
      {"loop", "__XCHAL_HAVE_LOOPS"}, {"mac16", "__XCHAL_HAVE_MAC16"},
      {"mul16", "__XCHAL_HAVE_MUL16"}, {"mul32", "__XCHAL_HAVE_MUL32"},
      {"mul32high", "__XCHAL_HAVE_MUL32_HIGH"}, {"div32", "__XCHAL_HAVE_DIV32"},
      {"s32c1i", "__XCHAL_HAVE_S32C1I"}};
  for (const auto &[Feature, Macro] : Macros)
    Builder.defineMacro(Macro, hasFeature(Feature) ? "1" : "0");
}

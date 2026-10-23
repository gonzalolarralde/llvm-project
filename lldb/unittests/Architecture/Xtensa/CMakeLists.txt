if ("Xtensa" IN_LIST LLVM_TARGETS_TO_BUILD)
  add_lldb_unittest(ArchitectureXtensaTests
    ArchitectureXtensaTest.cpp

    LINK_COMPONENTS
      Support
      ${LLVM_TARGETS_TO_BUILD}
    LINK_LIBS
      lldbCore
      lldbPluginDisassemblerLLVMC
      lldbPluginArchitectureXtensa
      lldbUtility)
endif()

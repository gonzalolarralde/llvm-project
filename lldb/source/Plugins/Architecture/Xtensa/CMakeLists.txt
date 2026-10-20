add_lldb_library(lldbPluginArchitectureXtensa PLUGIN
  ArchitectureXtensa.cpp

  LINK_COMPONENTS
    Support
  LINK_LIBS
    lldbCore
    lldbTarget
    lldbUtility
  )

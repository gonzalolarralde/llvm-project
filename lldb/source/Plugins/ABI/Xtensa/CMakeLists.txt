add_lldb_library(lldbPluginABIXtensa PLUGIN
  ABIXtensa.cpp

  LINK_COMPONENTS
    Support
    TargetParser
  LINK_LIBS
    lldbCore
    lldbSymbol
    lldbTarget
  )

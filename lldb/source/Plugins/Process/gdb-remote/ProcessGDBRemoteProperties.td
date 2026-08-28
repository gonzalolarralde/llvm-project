include "../../../../include/lldb/Core/PropertiesBase.td"

let Definition = "processgdbremote", Path = "plugin.process.gdb-remote" in {
  def PacketTimeout: Property<"packet-timeout", "UInt64">,
    Global,
#ifdef LLDB_SANITIZED
    DefaultUnsignedValue<60>,
#else
    DefaultUnsignedValue<5>,
#endif
    Desc<"Specify the default packet timeout in seconds.">;
  def TargetDefinitionFile: Property<"target-definition-file", "FileSpec">,
    Global,
    DefaultStringValue<"">,
    Desc<"The file that provides the description for remote target registers.">;
  def UseSVR4: Property<"use-libraries-svr4", "Boolean">,
    Global,
    DefaultTrue,
    Desc<"If true, the libraries-svr4 feature will be used to get a hold of the process's loaded modules. This setting is only effective if lldb was build with xml support.">;
  def UseGPacketForReading: Property<"use-g-packet-for-reading", "Boolean">,
    Global,
    DefaultFalse,
    Desc<"Specify if the server should use 'g' packets to read registers.">;
  def HardwareCoreIDAddress: Property<"hardware-core-id-address", "String">,
    Global,
    DefaultStringValue<"">,
    Desc<"Experimental: address of a read-only 32-bit CPU identity register, read through the selected hardware context. Setting this before connecting asserts that remote threads represent fixed hardware CPUs and that Hg selects the memory-access CPU. Do not use with RTOS threads. Empty disables this contract.">;
  def PacketTestDelay
      : Property<"packet-test-delay", "UInt64">,
        Global,
        DefaultUnsignedValue<0>,
        Desc<"Specify an artificial delay in milliseconds inserted before "
             "sending each packet, for testing purposes.">;
}

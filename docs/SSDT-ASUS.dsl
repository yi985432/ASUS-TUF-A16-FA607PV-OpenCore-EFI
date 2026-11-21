DefinitionBlock ("", "SSDT", 2, "ASUS", "TUFKBL", 0x00000000)
{
    External (_SB_.ATKD, DeviceObj)
    External (_SB_.ATKD.INIT, MethodObj)
    External (_SB_.PCI0.SBRG.SECC, MethodObj)

    Scope (_SB_)
    {
        Device (ALS0)
        {
            Name (_HID, "ACPI0008")
            Name (_CID, "smc-als")
            Name (_ALI, 150)
            Name (_ALR, Package()
            {
                Package() { 100, 150 }
            })
        }
    }

    Scope (_SB_.ATKD)
    {
        Method (_INI, 0, NotSerialized)
        {
            INIT (One)
        }

        Method (SKBV, 1, NotSerialized)
        {
            Local0 = (Arg0 / 16) | 0x80
            \_SB.PCI0.SBRG.SECC (0x05, Local0)
            Return (One)
        }
    }
}

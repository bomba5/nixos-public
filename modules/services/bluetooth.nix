# Module: modules/services/bluetooth.nix
# Purpose: Configure Bluetooth stack (BlueZ), tweak power/ERTM, and enable Blueman UI.
# Options: No custom options.
# Usage: Import on machines needing Bluetooth peripherals; included in graphical profile.
{ pkgs, ... }:

{
  # USB BT adapters (desktops) come up soft-blocked by the kernel's btusb
  # module — there is no ACPI/firmware to remember the radio state like on
  # laptops.  Unblock before bluetoothd starts so powerOnBoot actually works.
  # Harmless no-op on integrated (laptop) adapters that are already unblocked.
  systemd.services.rfkill-unblock-bluetooth = {
    description = "Unblock Bluetooth via rfkill";
    wantedBy = [ "bluetooth.service" ];
    before = [ "bluetooth.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.util-linux}/bin/rfkill unblock bluetooth";
    };
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;

    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket,Control,Gateway,Headset,HID,HumanInterfaceDeviceService";

        ControllerMode = "dual"; # allow both BR/EDR (classic) and LE
        JustWorksRepairing = "always";
        Privacy = "device";
        FastConnectable = true;
        Experimental = true; # harmless; needed for some HID/Battery quirks
      };
      GATT.ReconnectIntervals = "1,1,2,3,5,8,13,21,34,55";
    };
  };

  boot.extraModprobeConfig = ''
    options bluetooth disable_ertm=1
  '';

  # Prevent autosuspend on common btusb devices (tweak IDs after lsusb if needed)
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0a5c", TEST=="power/control", ATTR{power/control}="on"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="8087", TEST=="power/control", ATTR{power/control}="on"
  '';

  services.blueman.enable = true;
}

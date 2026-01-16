{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Enable the r8125 driver
  boot.extraModulePackages = [ config.boot.kernelPackages.r8125 ];

  # Ensure the module loads at boot
  boot.kernelModules = [ "r8125" ];

  # Blacklist the r8169 driver to prevent conflicts
  boot.blacklistedKernelModules = [ "r8169" ];

  # needed to load driver manually
  # ❯ echo "10ec 8126" | sudo tee /sys/bus/pci/drivers/r8125/new_id
  # 10ec 8126
  # ❯ sudo dmesg | tail -20
  # [   99.763486] ...
  # [  623.756546] r8125 Ethernet controller driver 9.016.01-NAPI loaded
  # [  623.756699] unknown chip version (64800000)
  # [  623.758888] r8125: This product is covered by one or more of the following patents: US6,570,884, US6,115,776, and US6,327,625.
  # [  623.758898] r8125  Copyright (C) 2025 Realtek NIC software team <nicfae@realtek.com>
  #                 This program comes with ABSOLUTELY NO WARRANTY; for details, please see <http://www.gnu.org/licenses/>.
  #                 This is free software, and you are welcome to redistribute it under certain conditions; see <http://www.gnu.org/licenses/>.
  # [  623.773432] r8125 0000:c4:00.0 enp196s0: renamed from eth0
  # [  623.779462] enp196s0: 0xffffce6c079c0000, 38:05:25:32:a4:2b, IRQ 118
  # [  627.601487] r8125: enp196s0: link up
  # boot.extraModprobeConfig = ''
  #   options r8125
  # '';
  services.udev.extraRules = ''
    # makes the driver attach to the hardware at boot 
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10ec", ATTR{device}=="0x8126", RUN+="${pkgs.bash}/bin/bash -c 'echo 10ec 8126 > /sys/bus/pci/drivers/r8125/new_id'"

    # rename it to something stable
    SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="38:05:25:32:a4:2b", NAME="eno2"
    # keep the atlantic one, thats already eno1 by default
  '';
  networking.interfaces.eno2.useDHCP = lib.mkDefault true;

}

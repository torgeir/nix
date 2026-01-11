{
  config,
  lib,
  pkgs,
  ...
}:

{

  system.activationScripts.rp2040-mountpoint = ''
    ${pkgs.lib.getExe' pkgs.coreutils "mkdir"} -pv /media/RPI-RP2
  '';

  services.udev.extraRules =
    let
    in
    ''
      # qmk nyquist keyboard RP2040, devnode is the udev node path, e.g. /dev/sde1
      ACTION=="add|change", SUBSYSTEMS=="usb", SUBSYSTEM=="block", ENV{ID_FS_USAGE}=="filesystem", ENV{ID_FS_LABEL}=="RPI-RP2", RUN+="${pkgs.lib.getExe' pkgs.systemd "systemd-mount"} --owner=1000 --no-block --collect $devnode /media/RPI-RP2"
    '';

  hardware.keyboard.qmk.enable = true;

  environment.systemPackages = with pkgs; [
    qmk
  ];

  services.udev.packages = [ pkgs.qmk-udev-rules ];
}

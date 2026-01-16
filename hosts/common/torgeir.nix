{
  config,
  lib,
  pkgs,
  ...
}:

{

  # set a password with passwd
  users.users.torgeir = {
    # mkpasswd 1234
    initialHashedPassword = "$y$j9T$RuAQHg50ZEFXDQs6v4mV7/$yQggB5i8V.0hjkKr4dRqjVr8fXICSY4GAq2W6mTumO/";
    shell = pkgs.zsh;
    isNormalUser = true;
    extraGroups = [
      "torgeir"
      "wheel" # enable sudo
      "corectrl" # adjust gpu fans
      "audio" # realtime audio for user
      "pipewire" # realtime audio for pw
      "video"
      "samba"
      "dialout" # arduino, /dev/ttyUSB0
      "plugdev" # mount usb and external drives
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIITJ5UIW0lXbeFfyOrdCXAfBtZsq/NycSzIADDZDi3TL"
    ];
  };

  programs = {
    # shell
    zsh.enable = true;
  };

  environment.systemPackages = with pkgs; [

  ];

  home-manager.users.torgeir = import ../../home/torgeir/${config.networking.hostName}.nix;
}

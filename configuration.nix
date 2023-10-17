# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).

{ config, lib, pkgs, ... }:

let
  homeManagerSessionVars = "/etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh";
in
{
  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  imports =
    [
      ./hardware-configuration.nix
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelParams = [
    # dual monitors, not working?
    "video=DP-1:2560x1440@59.951Hz"
    "video=DP-2:2560x1440@143.998Hz"
    # "video=DP-1:1920x1080@60Hz"
  ];

  # amd gpu
  boot.initrd.kernelModules = [ "amdgpu" ];
  hardware.opengl.enable = true;
  hardware.opengl.driSupport = true;
  hardware.opengl.extraPackages = with pkgs; [ amdvlk ];

  time.timeZone = "Europe/Oslo";
  networking.hostName = "torgnix";

  # wireless
  # networking.wireless.enable = true;
  # networking.networkmanager.enable = true;

  # proxy
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # locale
  i18n.defaultLocale = "en_US.UTF-8";

  # set a password with passwd
  users.users.torgeir = {
    shell = pkgs.zsh;
    isNormalUser = true;
    extraGroups = [
      "wheel"    # enable sudo
      "corectrl" # adjust gpu fans
    ];
  };

  # sorry stallman, can't live without them
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "spotify"
      "1password"
      "1password-cli"
      "1password-gui"
      "dropbox"
    ];

  # password manager
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "torgeir" ];
  };

  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    unzip
    gnumake
    lm_sensors
  ];

  # fix missing xdg session vars
  environment.extraInit = "[[ -f ${homeManagerSessionVars} ]] && source ${homeManagerSessionVars}";


  programs = {

    # amd gpu
    # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/hardware/corectrl.nix
    # https://gitlab.com/corectrl/corectrl/-/wikis/Setup#full-amd-gpu-controls
    corectrl = {
      enable = true;
      gpuOverclock = {
        enable = true;
        ppfeaturemask = "0xffffffff";
      };
    };

    # here, and not home-manager, as my own config is in dotfiles/
    sway.enable = true;

    # shell
    zsh.enable = true;
  };

  # ssh
  services.openssh.enable = false;

  # sound
  sound.enable = true;

  services = {

    # https://nixos.wiki/wiki/PipeWire
    pipewire = {
      enable = true;
      jack.enable = true;
      pulse.enable = true;
      #alsa.enable = true;
    };

    # thunderbolt
    # owc 11-port dock
    hardware.bolt.enable = true;
  };

  # sway needs polkit
  security.polkit.enable = true;

  # firewall
  networking.firewall.enable = true;
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];


  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05";

}


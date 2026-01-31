# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./realtek-interface.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "tank";
  networking.useDHCP = lib.mkDefault false;
  # don't bother waiting, they will come
  networking.dhcpcd.wait = "background";
  # 10G
  networking.interfaces.eno1 = {
    useDHCP = false;
    ipv4.addresses = [
      {
        address = "192.168.20.20";
        prefixLength = 24;
      }
    ];
  };
  # 5G
  networking.interfaces.eno2 = {
    useDHCP = false;
    ipv4.addresses = [
      {
        address = "192.168.50.20";
        prefixLength = 24;
      }
    ];
  };
  networking.defaultGateway = "192.168.20.1";
  networking = {
    domain = "wa.gd";
    nameservers = [
      "192.168.50.1"
      "192.168.20.1"
    ];
  };

  # Select internationalisation properties.
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true; # use xkb.options in tty.
  };

  # Enable sound.
  # hardware.pulseaudio.enable = true;
  # OR
  # services.pipewire = {
  #   enable = true;
  #   pulse.enable = true;
  # };

  # TODO after more ram
  # zram instead of swap
  zramSwap = {
    enable = true;
    algorithm = "zstd";
  };

  # nix search wget
  environment.systemPackages = with pkgs; [
    net-tools # arp
    inetutils # telnet
    pciutils # lspci
    tcpdump

    unzip
    git
    wget
    neovim

    # temps
    lm_sensors

    fastfetch
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  services.tailscale.enable = true;

  services.openssh = {
    enable = true;
    ports = [ 24 ];
    settings = {
      AllowUsers = [ "torgeir" ];
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 8080 ];
  networking.firewall.allowedUDPPorts = [ ];
  # Allow asymmetric routing: traffic arrives on eno1 (VLAN 20), replies via eno2 (VLAN 50)
  networking.firewall.checkReversePath = "loose"; # or false

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "24.11"; # Did you read the comment?

}

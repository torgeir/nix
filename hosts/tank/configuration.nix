# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:


{

  nixpkgs.overlays = [ (import ./overlay.nix { inherit pkgs inputs; }) ];

  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./realtek-interface.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # No onboard HDA codec present; avoid noisy probe errors on boot.
  boot.blacklistedKernelModules = [ "snd_hda_intel" ];

  # Strix Halo (gfx1151) unified memory: without amd_iommu=off, ROCm is capped at ~2 GB.
  # gttsize=131072 sets a 128 GB ceiling so the GPU can map all 64 GB system RAM.
  # ttm.pages_limit prevents allocation failures when loading large models.
  boot.kernelParams = [
    "amd_iommu=off"
    "amdgpu.gttsize=131072"
    "ttm.pages_limit=31457280"
  ];

  # Override generated /boot (vfat) permissions so loader random-seed is not world-readable.
  fileSystems."/boot".options = lib.mkForce [ "umask=0077" ];

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

  # without this services.unbound (?) setup messes up /etc/resolv.conf
  services.resolved.enable = false;
  networking.resolvconf.enable = false;
  environment.etc."resolv.conf".text = ''
    domain wa.gd
    nameserver 192.168.20.1
    nameserver ::1
    options trust-ad edns0
  '';

  # Select internationalisation properties.
  console = {
    # Provide Terminus fonts explicitly so setfont can find Lat2-Terminus16.
    packages = [ pkgs.terminus_font ];
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
    smartmontools

    fastfetch

    lemonade-server
    # Ryzen AI 9 HX PRO 370 (Strix Halo, gfx1151, XDNA2 NPU, 30GB iGPU VRAM) model suggestions:
    # - LMX-Omni-52B-Halo        -- built for Strix Halo, uses NPU+iGPU together
    # - Qwen3.5-9B-vLLM          -- vLLM backend, specifically targets gfx1151
    # - Qwen3-14B-GGUF           -- ROCm, fits in 30GB GPU pool, good reasoning/coding
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  services.tailscale.enable = true;

  systemd.tmpfiles.rules = [
    "d /fast/shared/apps/lemonade 0755 torgeir users -"
    # Fake /opt/rocm so lemond detects AMD ROCm (it hardcodes this Ubuntu path)
    "d /opt/rocm 0755 root root -"
    "d /opt/rocm/lib 0755 root root -"
    "d /opt/rocm/.info 0755 root root -"
    "f /opt/rocm/.info/2024-01-01 0644 root root -"
    "L /opt/rocm/lib/libhsa-runtime64.so - - - - ${pkgs.rocmPackages.rocm-runtime}/lib/libhsa-runtime64.so"
    "L /opt/rocm/lib/libhsa-runtime64.so.1 - - - - ${pkgs.rocmPackages.rocm-runtime}/lib/libhsa-runtime64.so.1"
    "L /opt/rocm/lib/libamdhip64.so - - - - ${pkgs.rocmPackages.clr}/lib/libamdhip64.so"
    "L /opt/rocm/lib/libamdhip64.so.6 - - - - ${pkgs.rocmPackages.clr}/lib/libamdhip64.so.6"
  ];

  systemd.services.lemond = {
    description = "Lemonade LLM server";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" "local-fs.target" ];
    path = with pkgs; [ bash gnutar gzip curl git unzip ];
    environment = {
      HF_HOME = "/fast/shared/apps/lemonade/huggingface";
      XDG_RUNTIME_DIR = "/run/user/1000";
      HIP_PATH = "/opt/rocm";
      ROCM_PATH = "/opt/rocm";
      HSA_OVERRIDE_GFX_VERSION = "11.5.0";
    };
    serviceConfig = {
      ExecStart = "${pkgs.lemonade-server}/bin/lemond --host 0.0.0.0 --port 13305 /fast/shared/apps/lemonade";
      User = "torgeir";
      Group = "users";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };

  # services.open-webui = {
  #   enable = true;
  #   host = "0.0.0.0";
  #   port = 8080;
  #   openFirewall = true;
  #   environment = {
  #     SCARF_NO_ANALYTICS = "True";
  #     DO_NOT_TRACK = "True";
  #     ANONYMIZED_TELEMETRY = "False";
  #     ENABLE_OLLAMA_API = "False";
  #     OPENAI_API_BASE_URL = "http://127.0.0.1:13305";
  #     OPENAI_API_KEY = "lemonade";
  #   };
  # };

  # Allow lemonade's downloaded pre-built llama-server (ROCm binary) to run on NixOS
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib
      zlib
      vulkan-loader
      openssl
      rocmPackages.clr
      rocmPackages.rocm-runtime
    ];
  };

  # Expose ROCm libs in /run/opengl-driver/lib/ so NixOS-built binaries (lemond) can detect AMD GPU.
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      rocmPackages.clr
      rocmPackages.rocm-runtime
    ];
  };
  # Use dbus-broker (migrate via `nixos-rebuild boot` + reboot, not live switch).
  services.dbus.implementation = "broker";

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
  networking.firewall.allowedTCPPorts = [
    53 # dns lookup from tailscale, this node is dns server
    # 8080
    # 11434
  ];
  networking.firewall.allowedUDPPorts = [
    53 # dns lookup from tailscale
  ];

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

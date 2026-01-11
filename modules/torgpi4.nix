{
  name,
  nixpkgs,
  inputs,
}:

nixpkgs.legacyPackages.x86_64-linux.pkgsCross.aarch64-multiplatform.nixos {
  imports = [

    "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64-new-kernel-no-zfs-installer.nix"

    (
      {
        lib,
        config,
        pkgs,
        ...
      }:
      {

        # need a trusted user for deploy-rs.
        nix.settings.trusted-users = [ "@wheel" ];

        boot = {
          kernelParams = [
            "console=ttyAMA0,115200n8"
            "console=ttyS0,115200n8"
          ];
          kernelModules = [ "i2c-dev" ];
          initrd.availableKernelModules = pkgs.lib.mkForce [ "mmc_block" ];

          # v4l2-loopback? https://gist.github.com/TheSirC/93130f70cc280cdcdff89faf8d4e98ab

          # supportedFilesystems = [ "cifs" ];

          loader = {
            grub.enable = false;
            generic-extlinux-compatible.enable = true;
          };

          kernelPackages = lib.mkForce (pkgs.linuxPackages_latest);

          # Avoids warning: mdadm: Neither MAILADDR nor PROGRAM has been set.
          # This will cause the `mdmon` service to crash.
          # https://github.com/NixOS/nixpkgs/issues/254807
          # swraid.enable = lib.mkForce false;

          # needed for deploy-rs
          binfmt.emulatedSystems = [ "x86_64-linux" ];
        };

        fileSystems = {
          "/" = {
            device = "/dev/disk/by-label/NIXOS_SD"; # name of sd card when written
            fsType = "ext4";
            options = [ "noatime" ];
          };
        };

        zramSwap = {
          enable = true;
          algorithm = "zstd";
        };

        nixpkgs.overlays = [
          (self: prev: {
            makeModulesClosure = x: prev.makeModulesClosure (x // { allowMissing = true; });
          })
        ];

        environment.systemPackages = with pkgs; [
          neofetch
          vim
          htop

          jalv
          neural-amp-modeler-lv2

          #pavucontrol
          #pa_applet
          alsa-lib
          # qjackctl
          # jack2
        ];

        # services.jack = {
        #   jackd = {
        #     enable = true;
        #     extraOptions = [
        #       "-dalsa"
        #       #--device" "hw:Microphone"
        #     ];
        #   };
        #   # support ALSA only programs via ALSA JACK PCM plugin
        #   alsa.enable = false;
        #   loopback = {
        #     enable = true;
        #     # buffering parameters for dmix device to work with ALSA only semi-professional sound programs
        #     dmixConfig = ''
        #       period_size 2048
        #     '';
        #   };
        # };

        sdImage.imageName = "${name}.img";
        sdImage.compressImage = false;

        # make sure wifi works
        hardware.enableRedistributableFirmware = lib.mkForce false;
        hardware.firmware = [ pkgs.raspberrypiWirelessFirmware ];

        services.openssh.enable = true;
        services.timesyncd.enable = true;

        networking = {
          hostName = name;
          wireless = {
            enable = true;
            networks."znort-guest".psk = "asdfasdf";
            interfaces = [ "wlan0" ];
          };
          interfaces."wlan0".useDHCP = true;
        };

        # users.users.root.openssh.authorizedKeys.keys = [ ];

        users.users.nam = {
          isNormalUser = true;
          home = "/home/nam";
          description = "nam";
          extraGroups = [
            "wheel"
            "networkmanager"
            "video"
            "audio"
            "jackaudio"
          ];
          openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIITJ5UIW0lXbeFfyOrdCXAfBtZsq/NycSzIADDZDi3TL"
          ];
        };

        security.sudo = {
          enable = true;
          wheelNeedsPassword = false;
        };

        services.getty.autologinUser = lib.mkForce "nam";

        # TODO fin rpi config
        # https://github.com/fursman/NixOS/blob/9015ecc18ddafecdadb5549ae3aff09afc8e2331/config/pi4.nix#L22

        # services.xserver = {
        #   enable = true;
        #   autorun = true;
        #   displayManager = {
        #     lightdm.enable = true;
        #   };
        #   windowManager = {
        #     dwm.enable = true;
        #   };
        # };
        # services.displayManager.enable = true;
        # services.displayManager.autoLogin.user = "nam";
        # services.displayManager.autoLogin.enable = true;
        # services.displayManager.defaultSession = "none+dwm";

        # displayManager.gdm.enable = true;
        # desktopManager.gnome.enable = true;
        #
        # services.xserver = { # X11
        #   enable = true;
        #   xkb = {
        #     layout = "us";
        #     options = "caps:escape";
        #     variant = "";
        #   };
        # };
        # services.displayManager.gdm.enable = true;
        # services.xserver.desktopManager.gnome.enable = true;

        # services.xserver = {
        #   enable = true;
        #   displayManager.lightdm.enable = true;
        #   desktopManager.xfce.enable = true;
        # };

        # # hardware.pulseaudio.enable = true;
        # services.pipewire = {
        #   enable = true;
        #   alsa.enable = true;
        #   alsa.support32Bit = true;
        #   pulse.enable = true;
        #   # If you want to use JACK applications, uncomment this
        #   jack.enable = true;
        #   # use the example session manager (no others are packaged yet so this is enabled by default,
        #   # no need to redefine it in your config for now)
        #   #media-session.enable = true;
        # };

        hardware.pulseaudio.enable = false;
        security.rtkit.enable = true;
        services.pipewire = {
          enable = true;
          alsa.enable = true;
          alsa.support32Bit = true;
          pulse.enable = true;
          # use JACK applications
          jack.enable = true;
        };

      }
    )

  ];

  system.stateVersion = "24.11";
}

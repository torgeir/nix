{ config, lib, pkgs, inputs, ... }:

let
  dotfiles = builtins.fetchGit {
    url = "https://github.com/torgeir/dotfiles";
    rev = "7e403c4975f816f81bdf4684d11c366a3c557f12";
  };
in {

  imports = [
    ./audio-production.nix
    ./autojump.nix
    ./browser.nix
    ./gtk.nix
    ./fonts.nix
    ./gpg.nix
    ./terminal
    ./editors
    ./file-manager.nix
  ];

  # let home manager install and manage itself
  programs.home-manager.enable = true;

  # inspiration for more
  # - https://github.com/panchoh/nixos
  # - https://github.com/hlissner/dotfiles/
  # - https://github.com/colemickens/nixcfg/
  # - https://github.com/nix-community/home-manager/
  # - https://github.com/nix-community/nixpkgs-wayland
  # - https://github.com/NixOS/nixpkgs/
  #
  # - https://github.com/Horus645/swww
  # - https://github.com/redyf/nixdots

  # find package paths with nix-env -qaP <pkg>
  #   nix-env -qaP nodejs
  #   nix-shell -p nodejs_20 --run "node -e 'console.log(42);'"
  # the same name is used here
  home.packages = with pkgs; [

    # terminal
    alacritty
    eza
    htop
    # TODO configure CONFIG_LATENCYTOP?
    latencytop

    # emacs
    nil # nix lsp https://github.com/oxalica/nil
    nixfmt

    # env
    direnv
    #nodejs

    # tools
    killall
    jq
    (ripgrep.override { withPCRE2 = true; })
    # screenshots
    grim
    slurp
    sway-contrib.grimshot
    swayimg

    # images
    imagemagick

    # notifications
    mako
    libnotify
    # https://discourse.nixos.org/t/cant-get-gnupg-to-work-no-pinentry/15373/28?page=2
    inputs.nixpkgs-wayland.packages.${system}.wayprompt

    # sensors
    inxi
    btop
    psensor
    i3status-rust

    #https://nixos.wiki/wiki/Samba

    # formats
    flac

    # apps
    mpv
    #mpc-cli
    ncmpcpp # mpd music player

    ncdu
    signal-desktop
    spotify
    slack
    playerctl
    dropbox

    # sound
    pavucontrol
    qpwgraph

    # unused, pipewire handles this
    # https://nixos.wiki/wiki/JACK
    # libjack2
    # jack2
    qjackctl

    # sudo -EH rpi-imager
    rpi-imager

    # wallpapers
    # https://github.com/natpen/awesome-wayland#wallpaper

    # fonts
    (pkgs.nerdfonts.override {
      fonts = [ "JetBrainsMono" "Iosevka" "IosevkaTerm" ];
    })

    # vst/audio-production
    reaper
    inputs.nix-gaming.packages.${pkgs.system}.wine-tkg # helix native needs wine with fsync patches
    (yabridge.override {
      wine = inputs.nix-gaming.packages.${pkgs.system}.wine-tkg;
    })
    (yabridgectl.override {
      wine = inputs.nix-gaming.packages.${pkgs.system}.wine-tkg;
    })
    winetricks
    dxvk_2
  ];

  # this puts files in the needed locations, but does however not make them
  # editable allows interop with torgeir/dotfiles.git without moving all this
  # configuration to .nix files
  home.file = {
    "dotfiles".source = dotfiles;

    "bg.jpg".source = dotfiles + "/bg.jpg";

    ".config/sway".source = dotfiles + "/config/sway";
    ".config/xkb".source = dotfiles + "/config/xkb";
    ".config/environment.d/envvars.conf".source = dotfiles
      + "/config/environment.d/envvars.conf";
    ".config/mako".source = dotfiles + "/config/mako";
    ".config/dunst".source = dotfiles + "/config/dunst";
    ".config/i3status-rust".source = dotfiles + "/config/i3status-rust";
    ".config/corectrl/profiles".source = dotfiles + "/config/corectrl/profiles";
    ".config/corectrl/corectrl.ini".source = dotfiles
      + "/config/corectrl/corectrl.ini";

    ".p10k.zsh".source = dotfiles + "/p10k.zsh";
    ".gitconfig".source = dotfiles + "/gitconfig";

    ".config/pipewire/1-jack-rt.conf".text = ''
      context.properties = {
          mem.mlock-all   = true
          log.level        = 0
      }

      context.spa-libs = {
          support.* = support/libspa-support
      }

      context.modules = [
          { name = libpipewire-module-rt
              args = {
                  # rtirq status | head
                  # less than my usb sound card that has from 90 to 72, irq/*-xhci_hcd
                  rt.prio      = 71
                  rt.time.soft = -1
                  rt.time.hard = -1
                   }
              flags = [ ifexists nofail ]
          }
          { name = libpipewire-module-protocol-native }
          { name = libpipewire-module-client-node }
          { name = libpipewire-module-metadata }
      ]

      jack.properties = {
           node.latency       = 64/48000
      }
    '';

    # TODO is this needed?
    # https://github.com/hannesmann/dotfiles/blob/51a52957d49d83e5e57113a8cd838147cd79ccc2/etc/wireplumber/main.lua.d/90-realtek.lua#L27
    # https://forum.manjaro.org/t/click-sound-before-playing-any-audio/47237/2
    ".config/wireplumber/main.lua.d/98-alsa-no-pop.lua".text = ''
      table.insert(alsa_monitor.rules, {
        matches = {
          { -- Matches all sources.
            { "node.name", "matches", "alsa_input.*" },
          },
          { -- Matches all sinks.
            { "node.name", "matches", "alsa_output.*" },
          },
        },
        apply_properties = {
          ["session.suspend-timeout-seconds"] = 0,
          ["suspend-node"] = false,
          ["node.pause-on-idle"] = false,
        },
      })
    '';

    ".zsh".source = dotfiles + "/zsh/";
    ".zshrc".source = dotfiles + "/zshrc";
    ".zprofile".source = dotfiles + "/profile";
    ".inputrc".source = dotfiles + "/inputrc";
  };

  # sops with home manager is a little different, see configuration.nix
  #   imports = [ inputs.sops-nix.homeManagerModules.sops ];
  #   sops.age.keyFile = "/etc/nix-sops-secret.key";
  #   sops.secrets."smb".owner = "torgeir";

  home.stateVersion = "23.11";

}

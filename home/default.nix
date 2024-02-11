{ config, lib, pkgs, inputs, ... }:

let
  dotfiles = builtins.fetchGit {
    url = "https://github.com/torgeir/dotfiles";
    rev = "93a0a0a31e53648d879b3c9f75e30eb0ae8c3a56";
  };
in {

  imports = [
    ./audio-production.nix
    ./autojump.nix
    ./browser.nix
    ./gtk.nix
    ./fonts.nix
    ./gpg.nix
    ./tofi.nix
    ./editors
    ./file-manager.nix
  ];

  # find package paths with nix-env -qaP <pkg>
  #   nix-env -qaP nodejs
  #   nix-shell -p nodejs_20 --run "node -e 'console.log(42);'"
  # the same name is used here
  home.packages = with pkgs; [

    # terminal
    alacritty
    bat
    eza
    fzf
    htop
    tmux
    # TODO configure CONFIG_LATENCYTOP?
    latencytop

    # emacs
    nil # nix lsp https://github.com/oxalica/nil
    nixfmt

    # env
    direnv

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
    gnuplot

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

    # sudo -EH rpi-imager
    rpi-imager

    # wallpapers
    # https://github.com/natpen/awesome-wayland#wallpaper

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
    ".local/bin/reaper-low-latency".source =
      pkgs.writeShellScript "launch-reaper-low-latency" ''
        # make firefox play nice, not to hinder realtime audio
        pgrep -f -w firefox | xargs renice --relative 5 {}
        PIPEWIRE_QUANTUM=48/48000 ${pkgs.reaper}/bin/reaper
      '';

    ".config/dotfiles".source = dotfiles;

    "bg.jpg".source = dotfiles + "/bg.jpg";

    ".config/alacritty/alacritty.toml".source = dotfiles
      + "/config/alacritty/alacritty.toml";
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

    ".zsh".source = dotfiles + "/zsh/";
    ".zshrc".source = dotfiles + "/zshrc";
    ".zprofile".source = dotfiles + "/profile";
    ".fzfrc".source = dotfiles + "/fzfrc";
    ".inputrc".source = dotfiles + "/inputrc";
    ".tmux.conf".source = dotfiles + "/tmux.conf";
  };

  # sops with home manager is a little different, see configuration.nix
  #   imports = [ inputs.sops-nix.homeManagerModules.sops ];
  #   sops.age.keyFile = "/etc/nix-sops-secret.key";
  #   sops.secrets."smb".owner = "torgeir";

  home.stateVersion = "23.11";

}

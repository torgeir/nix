{ config, lib, pkgs, inputs, ... }:

let
  dotfiles = builtins.fetchGit {
    url = "https://github.com/torgeir/dotfiles";
    rev = "5abec19af26cf11e3d3f0bc36604324507786907";
  };
in {

  imports =
    [ ./autojump.nix ./gtk.nix ./fonts.nix ./gpg.nix ./terminal ./editors ];

  # let home manager install and manage itself
  programs.home-manager.enable = true;

  # TODO inspiration for more
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

    # emacs
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
    playerctl
    dropbox

    # sound
    pavucontrol
    qpwgraph

    # internet
    brave

    # wallpapers
    # https://github.com/natpen/awesome-wayland#wallpaper

    # fonts
    (pkgs.nerdfonts.override { fonts = [ "JetBrainsMono" "Iosevka" ]; })
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

    ".config/pipewire".source = dotfiles + "/config/pipewire";
    ".config/wireplumber".source = dotfiles + "/config/wireplumber";

    ".p10k.zsh".source = dotfiles + "/p10k.zsh";
    ".gitconfig".source = dotfiles + "/gitconfig";

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

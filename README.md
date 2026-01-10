# nix

My first stab at nixos, your mileage may vary.

```sh
nix flake check --show-trace

# build the main system: torgnix
clear; pushd ~/nixos-config; ./untrack-secrets.sh && sudo nixos-rebuild --flake .#torgnix switch && notify-send nixos reloaded; popd'

# build and push another system
nixos-rebuild switch --flake .#tank --target-host tank --sudo --ask-sudo-password
```

## notes

All nix files referenced must be added to git, secrets.yaml as well as imports. I use the hackery in untrack-secrets.sh to keep some files out of version control.

Nix for darwin? https://xyno.space/post/nix-darwin-introduction

## inspiration
- https://git.sr.ht/~montchr/dotfield
- https://github.com/lovesegfault/nix-config
- https://github.com/oddlama/nix-config
- https://github.com/panchoh/nixos/
- https://git.sr.ht/~misterio
- https://github.com/Mic92/dotfiles/
- https://github.com/hlissner/dotfiles/
- https://github.com/colemickens/nixcfg/
- https://github.com/Horus645/swww
- https://github.com/redyf/nixdots

## good resources
- https://nixos.asia/en
- https://zero-to-nix.com/
- https://nixos-and-flakes.thiscute.world/
- https://nix-tutorial.gitlabpages.inria.fr/nix-tutorial/first-package.html
- https://www.bekk.christmas/post/2021/16/dotfiles-with-nix-and-home-manager
- https://www.bekk.christmas/post/2021/13/deterministic-systems-with-nix
- https://www.tweag.io/blog/2020-05-25-flakes/

## other useful links
- https://github.com/NixOS/nixpkgs/ (lookup the branch for your chosen version)
- https://github.com/nix-community/home-manager/
- https://github.com/nix-community/nixpkgs-wayland

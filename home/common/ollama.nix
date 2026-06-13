{
  dotfiles,
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

{

  services.ollama = {
    enable = true;
    acceleration = "rocm";
  };

}

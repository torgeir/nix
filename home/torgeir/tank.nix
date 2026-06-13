{
  config,
  lib,
  inputs,
  dotfiles,
  pkgs,
  ...
}:

{

  imports = [
    (inputs.nix-home-manager + "/modules")
    # ../common/ollama.nix
  ];

  home.packages = with pkgs; [
    pi-coding-agent
    inxi
  ];

  # home.sessionVariables = {
  #   OLLAMA_MODELS = "/fast/shared/apps/ollama/models";
  # };
  # services.ollama = {
  #   environmentVariables = {
  #     OLLAMA_MODELS = "/fast/shared/apps/ollama/models";
  #   };
  # };

  programs.t-git.enable = true;
  programs.t-nvim.enable = true;

  programs.t-shell-tooling.enable = true;
  # make session vars load
  programs.zsh.enable = true;

  programs.t-zoxide.enable = true;
  programs.t-tmux.enable = true;

  home.file.".config/dotfiles".source = dotfiles;

  home.stateVersion = "23.11";

}

{
  pkgs,
  inputs,
  ...
}:
{
  programs.ghostty = {
    enable = true;
    package = if pkgs.stdenv.isDarwin then pkgs.ghostty-bin else pkgs.ghostty;

    systemd.enable = true;

    enableBashIntegration = true;
    enableFishIntegration = false;
    enableZshIntegration = true;

    settings =
      let
        pad = "20";
      in
      {
        # theme = "dark:Catppuccin Mocha,light:Catppuccin Latte";
        theme = "Catppuccin Mocha";

        font-family = "IosevkaTerm Nerd Font";
        font-size = "20";

        background-opacity = "0.95";

        # all on
        shell-integration-features = true;

        window-padding-balance = true;
        window-padding-x = "${pad},${pad}";
        window-padding-y = "${pad},${pad}";
        keybind = [
          #"global:ctrl+space=toggle_quick_terminal"

          "cmd+d=new_split:right"
          "cmd+shift+d=new_split:down"

          "cmd+alt+left=goto_split:left"
          "cmd+alt+right=goto_split:right"
          "cmd+alt+down=goto_split:down"
          "cmd+alt+up=goto_split:up"

          "ctrl+left=previous_tab"
          "ctrl+right=next_tab"
          "ctrl+shift+left=move_tab:-1"
          "ctrl+shift+right=move_tab:1"

          "super+1=goto_tab:1"
          "super+2=goto_tab:2"
          "super+3=goto_tab:3"
          "super+4=goto_tab:4"
          "super+5=goto_tab:5"
          "super+6=goto_tab:6"
          "super+7=goto_tab:7"
          "super+8=goto_tab:8"
          "super+9=goto_tab:9"

          "alt+up=esc:a"
          "alt+down=esc:e"
          "alt+left=esc:b"
          "alt+right=esc:f"
        ];
      };
  };
}

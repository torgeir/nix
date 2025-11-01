{ config, lib, pkgs, ... }:

{
  # the following allows logging in from the Cradle Hub.exe app on wine
  xdg.enable = true;
  xdg.mimeApps.enable = true;
  xdg.mimeApps.associations.added = {
    "x-scheme-handler/http" = "org.mozilla.firefox.desktop";
    "x-scheme-handler/https" = "org.mozilla.firefox.desktop";

    # also, firefox needs about:config -> network.protocol-handler.external."app.cradle": false and
    # then the first time it pops up a dialog asking to allow permission, say always allow
    "x-scheme-handler/app.cradle" = "cradle.desktop"; 
  };

  # this will be the cradle.desktop file contents,
  # file ends up in /etc/profiles/per-user-torgeir/share/applications/wine-extension-cradle.desktop";
  # https://specifications.freedesktop.org/desktop-entry-spec/latest/exec-variables.html
  xdg.desktopEntries.cradle = {
    name = "Cradle Hub";
    genericName = "Plugin handler";
    # if this fails, put it in a shellscript, use chmod u+x <file>, and put /home/torgeir/bin/test.sh "%u" here instead
    # exec = "env WINEPREFIX=\\$HOME/.wine wine \"C:\\Program Files\\Cradle\\Cradle Hub.exe\" \"%u\"";
    # exec = "/home/torgeir/bin/test.sh \"%u\"";
    exec = "${pkgs.writeShellScript "launch-cradle-hub-with-oauth-code" ''
      #!/usr/bin/env bash
      export WINEPREFIX="$HOME/.wine"
      logger -p user.info "[Cradle hub]: Running wine cmd with URL: $1"
      wine "C:\\Program Files\\Cradle\\Cradle Hub.exe" "$1"
      logger -p user.info "[Cradle hub]: Done"
    ''} %u";
    terminal = false;
    categories = [];
    mimeType = [ "x-scheme-handler/app.cradle" ];
  };
}

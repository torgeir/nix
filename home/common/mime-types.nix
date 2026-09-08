{
  config,
  lib,
  pkgs,
  ...
}:

{

  xdg.enable = true;
  xdg.mimeApps.enable = true;

  # force sane defaults instead, not to let wine mess up
  xdg.mimeApps.defaultApplications = {
    "application/pdf" = "emacsclient-pdf.desktop";

    "text/plain" = "emacsclient.desktop";
    "text/x-log" = "emacsclient.desktop";
    "application/x-shellscript" = "emacsclient.desktop";

    "image/png" = "swayimg.desktop";
    "image/jpeg" = "swayimg.desktop";
    "image/jpg" = "swayimg.desktop";
    "image/gif" = "swayimg.desktop";
    "image/bmp" = "swayimg.desktop";
    "image/webp" = "swayimg.desktop";
    "image/tiff" = "swayimg.desktop";
    "image/svg+xml" = "swayimg.desktop";
    "image/x-portable-pixmap" = "swayimg.desktop";
    "image/x-portable-bitmap" = "swayimg.desktop";
    "image/x-portable-anymap" = "swayimg.desktop";
    "image/x-portable-graymap" = "swayimg.desktop";
  };

  xdg.mimeApps.associations.added = {
    "application/pdf" = "emacsclient-pdf.desktop";
  };

  xdg.desktopEntries.emacsclient-pdf = {
    name = "Emacs Client";
    exec = ''emacsclient --socket-name ${config.home.homeDirectory}/.emacs.d/server/server -a "" -n -q %u'';
    mimeType = [ "application/pdf" ];
  };

  xdg.desktopEntries.emacsclient = {
    name = "Emacs Client";
    exec = ''emacsclient --socket-name ${config.home.homeDirectory}/.emacs.d/server/server -a "" -n -q %u'';
    mimeType = [
      "text/plain"
      "text/x-log"
      "application/x-shellscript"
    ];
  };
}

{
  config,
  lib,
  pkgs,
  ...
}:

{

  xdg.enable = true;
  xdg.mimeApps.enable = true;

  # open pdfs in emacs
  xdg.mimeApps.associations.added = {
    "application/pdf" = "emacsclient-pdf.desktop";
  };
  xdg.desktopEntries.emacsclient-pdf = {
    name = "Emacs Client";
    exec = ''emacsclient --socket-name ${config.home.homeDirectory}/.emacs.d/server/server -a "" -n -q %u'';
    mimeType = [ "application/pdf" ];
  };
}

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

    ".config/pipewire/pipewire-pulse.conf".text = ''
      # PulseAudio config file for PipeWire version "0.3.84" #
      #
      # Copy and edit this file in /etc/pipewire for system-wide changes
      # or in ~/.config/pipewire for local changes.
      #
      # It is also possible to place a file with an updated section in
      # /etc/pipewire/pipewire-pulse.conf.d/ for system-wide changes or in
      # ~/.config/pipewire/pipewire-pulse.conf.d/ for local changes.
      #

      context.properties = {
          ## Configure properties in the system.
          #mem.warn-mlock  = false
          #mem.allow-mlock = true
          #mem.mlock-all   = false
          #log.level       = 2

          #default.clock.quantum-limit = 8192
      }

      context.spa-libs = {
          audio.convert.* = audioconvert/libspa-audioconvert
          support.*       = support/libspa-support
      }

      context.modules = [
          { name = libpipewire-module-rt
              args = {
                  nice.level   = -11
                  #rt.prio      = 88
                  rt.prio      = 71
                  #rt.time.soft = -1
                  #rt.time.hard = -1
              }
              flags = [ ifexists nofail ]
          }
          { name = libpipewire-module-protocol-native }
          { name = libpipewire-module-client-node }
          { name = libpipewire-module-adapter }
          { name = libpipewire-module-metadata }

          { name = libpipewire-module-protocol-pulse
              args = {
      	    # contents of pulse.properties can also be placed here
      	    # to have config per server.
              }
          }
      ]

      # Extra scripts can be started here. Setup in default.pa can be moved in
      # a script or in pulse.cmd below
      context.exec = [
          #{ path = "pactl"        args = "load-module module-always-sink" }
          #{ path = "pactl"        args = "upload-sample my-sample.wav my-sample" }
          #{ path = "/usr/bin/sh"  args = "~/.config/pipewire/default.pw" }
      ]

      # Extra commands can be executed here.
      #   load-module : loads a module with args and flags
      #      args = "<module-name> <module-args>"
      #      ( flags = [ nofail ] )
      pulse.cmd = [
          { cmd = "load-module" args = "module-always-sink" flags = [ ] }
          #{ cmd = "load-module" args = "module-switch-on-connect" }
          #{ cmd = "load-module" args = "module-gsettings" flags = [ nofail ] }
      ]

      stream.properties = {
          #node.latency          = 1024/48000
          #node.autoconnect      = true
          #resample.quality      = 4
          #channelmix.normalize  = false
          #channelmix.mix-lfe    = true
          #channelmix.upmix      = true
          #channelmix.upmix-method = psd  # none, simple
          #channelmix.lfe-cutoff = 150
          #channelmix.fc-cutoff  = 12000
          #channelmix.rear-delay = 12.0
          #channelmix.stereo-widen = 0.0
          #channelmix.hilbert-taps = 0
          #dither.noise = 0
      }

      pulse.properties = {
          # the addresses this server listens on
          server.address = [
              "unix:native"
              #"unix:/tmp/something"              # absolute paths may be used
              #"tcp:4713"                         # IPv4 and IPv6 on all addresses
              #"tcp:[::]:9999"                    # IPv6 on all addresses
              #"tcp:127.0.0.1:8888"               # IPv4 on a single address
              #
              #{ address = "tcp:4713"             # address
              #  max-clients = 64                 # maximum number of clients
              #  listen-backlog = 32              # backlog in the server listen queue
              #  client.access = "restricted"     # permissions for clients
              #}
          ]
          #server.dbus-name       = "org.pulseaudio.Server"
          #pulse.min.req          = 128/48000     # 2.7ms
          #pulse.default.req      = 960/48000     # 20 milliseconds
          #pulse.min.frag         = 128/48000     # 2.7ms
          #pulse.default.frag     = 96000/48000   # 2 seconds
          #pulse.default.tlength  = 96000/48000   # 2 seconds
          #pulse.min.quantum      = 128/48000     # 2.7ms
          #pulse.idle.timeout     = 0             # don't pause after underruns
          #pulse.default.format   = F32
          #pulse.default.position = [ FL FR ]
          # These overrides are only applied when running in a vm.
          vm.overrides = {
              pulse.min.quantum = 1024/48000      # 22ms
          }
      }

      # client/stream specific properties
      pulse.rules = [
          {
              matches = [
                  {
                      # all keys must match the value. ! negates. ~ starts regex.
                      #client.name                = "Firefox"
                      #application.process.binary = "teams"
                      #application.name           = "~speech-dispatcher.*"
                  }
              ]
              actions = {
                  update-props = {
                      #node.latency = 512/48000
                  }
                  # Possible quirks:"
                  #    force-s16-info                 forces sink and source info as S16 format
                  #    remove-capture-dont-move       removes the capture DONT_MOVE flag
                  #    block-source-volume            blocks updates to source volume
                  #    block-sink-volume              blocks updates to sink volume
                  #quirks = [ ]
              }
          }
          {
              # skype does not want to use devices that don't have an S16 sample format.
              matches = [
                   { application.process.binary = "teams" }
                   { application.process.binary = "teams-insiders" }
                   { application.process.binary = "skypeforlinux" }
              ]
              actions = { quirks = [ force-s16-info ] }
          }
          {
              # firefox marks the capture streams as don't move and then they
              # can't be moved with pavucontrol or other tools.
              matches = [ { application.process.binary = "firefox" } ]
              actions = { quirks = [ remove-capture-dont-move ] }
          }
          {
              # speech dispatcher asks for too small latency and then underruns.
              matches = [ { application.name = "~speech-dispatcher.*" } ]
              actions = {
                  update-props = {
                      pulse.min.req          = 512/48000      # 10.6ms
                      pulse.min.quantum      = 512/48000      # 10.6ms
                      pulse.idle.timeout     = 5              # pause after 5 seconds of underrun
                  }
              }
          }
          #{
          #    matches = [ { application.process.binary = "Discord" } ]
          #    actions = { quirks = [ block-source-volume ] }
          #}
      ]
    '';

    ".config/pipewire/pipewire.conf".text = ''
      # Daemon config file for PipeWire version "0.3.84" #
      #
      # Copy and edit this file in /etc/pipewire for system-wide changes
      # or in ~/.config/pipewire for local changes.
      #
      # It is also possible to place a file with an updated section in
      # /etc/pipewire/pipewire.conf.d/ for system-wide changes or in
      # ~/.config/pipewire/pipewire.conf.d/ for local changes.
      #

      context.properties = {
          ## Configure properties in the system.
          #library.name.system                   = support/libspa-support
          #context.data-loop.library.name.system = support/libspa-support
          #support.dbus                          = true
          #link.max-buffers                      = 64
          link.max-buffers                       = 16                       # version < 3 clients can't handle more
          #mem.warn-mlock                        = false
          #mem.allow-mlock                       = true
          #mem.mlock-all                         = false
          #clock.power-of-two-quantum            = true
          #log.level                             = 2
          #cpu.zero.denormals                    = false

          core.daemon = true              # listening for socket connections
          core.name   = pipewire-0        # core name and socket name

          ## Properties for the DSP configuration.
          default.clock.rate          = 48000
          default.clock.allowed-rates = [ 48000 ]
          #default.clock.quantum       = 512
          default.clock.min-quantum   = 32
          default.clock.max-quantum   = 2048
          #default.clock.quantum-limit = 8192
          #default.video.width         = 640
          #default.video.height        = 480
          #default.video.rate.num      = 25
          #default.video.rate.denom    = 1
          #
          #settings.check-quantum      = false
          #settings.check-rate         = false
          #
          # These overrides are only applied when running in a vm.
          vm.overrides = {
              default.clock.min-quantum = 1024
          }

          # keys checked below to disable module loading
          module.x11.bell = true
          # enables autoloading of access module, when disabled an alternative
          # access module needs to be loaded.
          module.access = true
          # enables autoloading of module-jackdbus-detect
          module.jackdbus-detect = true
      }

      context.spa-libs = {
          #<factory-name regex> = <library-name>
          #
          # Used to find spa factory names. It maps an spa factory name
          # regular expression to a library name that should contain
          # that factory.
          #
          audio.convert.* = audioconvert/libspa-audioconvert
          avb.*           = avb/libspa-avb
          api.alsa.*      = alsa/libspa-alsa
          api.v4l2.*      = v4l2/libspa-v4l2
          api.libcamera.* = libcamera/libspa-libcamera
          api.bluez5.*    = bluez5/libspa-bluez5
          api.vulkan.*    = vulkan/libspa-vulkan
          api.jack.*      = jack/libspa-jack
          support.*       = support/libspa-support
          #videotestsrc   = videotestsrc/libspa-videotestsrc
          #audiotestsrc   = audiotestsrc/libspa-audiotestsrc
      }

      context.modules = [
          #{ name = <module-name>
          #    ( args  = { <key> = <value> ... } )
          #    ( flags = [ ( ifexists ) ( nofail ) ] )
          #    ( condition = [ { <key> = <value> ... } ... ] )
          #}
          #
          # Loads a module with the given parameters.
          # If ifexists is given, the module is ignored when it is not found.
          # If nofail is given, module initialization failures are ignored.
          # If condition is given, the module is loaded only when the context
          # properties all match the match rules.
          #

          # Uses realtime scheduling to boost the audio thread priorities. This uses
          # RTKit if the user doesn't have permission to use regular realtime
          # scheduling.
          { name = libpipewire-module-rt
              args = {
                  nice.level    = -11
                  rt.prio      = 71
                  #rt.time.soft = -1
                  #rt.time.hard = -1
              }
              flags = [ ifexists nofail ]
          }

          # The native communication protocol.
          { name = libpipewire-module-protocol-native
              args = {
                  # List of server Unix sockets, and optionally permissions
                  #sockets = [ { name = "pipewire-0" }, { name = "pipewire-0-manager" } ]
              }
          }

          # The profile module. Allows application to access profiler
          # and performance data. It provides an interface that is used
          # by pw-top and pw-profiler.
          { name = libpipewire-module-profiler }

          # Allows applications to create metadata objects. It creates
          # a factory for Metadata objects.
          { name = libpipewire-module-metadata }

          # Creates a factory for making devices that run in the
          # context of the PipeWire server.
          { name = libpipewire-module-spa-device-factory }

          # Creates a factory for making nodes that run in the
          # context of the PipeWire server.
          { name = libpipewire-module-spa-node-factory }

          # Allows creating nodes that run in the context of the
          # client. Is used by all clients that want to provide
          # data to PipeWire.
          { name = libpipewire-module-client-node }

          # Allows creating devices that run in the context of the
          # client. Is used by the session manager.
          { name = libpipewire-module-client-device }

          # The portal module monitors the PID of the portal process
          # and tags connections with the same PID as portal
          # connections.
          { name = libpipewire-module-portal
              flags = [ ifexists nofail ]
          }

          # The access module can perform access checks and block
          # new clients.
          { name = libpipewire-module-access
              args = {
                  # Socket-specific access permissions
                  #access.socket = { pipewire-0 = "default", pipewire-0-manager = "unrestricted" }

                  # Deprecated legacy mode (not socket-based),
                  # for now enabled by default if access.socket is not specified
                  #access.legacy = true
              }
              condition = [ { module.access = true } ]
          }

          # Makes a factory for wrapping nodes in an adapter with a
          # converter and resampler.
          { name = libpipewire-module-adapter }

          # Makes a factory for creating links between ports.
          { name = libpipewire-module-link-factory }

          # Provides factories to make session manager objects.
          { name = libpipewire-module-session-manager }

          # Use libcanberra to play X11 Bell
          { name = libpipewire-module-x11-bell
              args = {
                  #sink.name = ""
                  #sample.name = "bell-window-system"
                  #x11.display = null
                  #x11.xauthority = null
              }
              flags = [ ifexists nofail ]
              condition = [ { module.x11.bell = true } ]
          }
          { name = libpipewire-module-jackdbus-detect
              args = {
                  #jack.library     = libjack.so.0
                  #jack.server      = null
                  #jack.client-name = PipeWire
                  #jack.connect     = true
                  #tunnel.mode      = duplex  # source|sink|duplex
                  source.props = {
                      #audio.channels = 2
      		#midi.ports = 1
                      #audio.position = [ FL FR ]
                      # extra sink properties
                  }
                  sink.props = {
                      #audio.channels = 2
      		#midi.ports = 1
                      #audio.position = [ FL FR ]
                      # extra sink properties
                  }
              }
              flags = [ ifexists nofail ]
              condition = [ { module.jackdbus-detect = true } ]
          }
      ]

      context.objects = [
          #{ factory = <factory-name>
          #    ( args  = { <key> = <value> ... } )
          #    ( flags = [ ( nofail ) ] )
          #    ( condition = [ { <key> = <value> ... } ... ] )
          #}
          #
          # Creates an object from a PipeWire factory with the given parameters.
          # If nofail is given, errors are ignored (and no object is created).
          # If condition is given, the object is created only when the context properties
          # all match the match rules.
          #
          #{ factory = spa-node-factory   args = { factory.name = videotestsrc node.name = videotestsrc node.description = videotestsrc "Spa:Pod:Object:Param:Props:patternType" = 1 } }
          #{ factory = spa-device-factory args = { factory.name = api.jack.device foo=bar } flags = [ nofail ] }
          #{ factory = spa-device-factory args = { factory.name = api.alsa.enum.udev } }
          #{ factory = spa-node-factory   args = { factory.name = api.alsa.seq.bridge node.name = Internal-MIDI-Bridge } }
          #{ factory = adapter            args = { factory.name = audiotestsrc node.name = my-test node.description = audiotestsrc } }
          #{ factory = spa-node-factory   args = { factory.name = api.vulkan.compute.source node.name = my-compute-source } }

          # A default dummy driver. This handles nodes marked with the "node.always-driver"
          # property when no other driver is currently active. JACK clients need this.
          { factory = spa-node-factory
              args = {
                  factory.name    = support.node.driver
                  node.name       = Dummy-Driver
                  node.group      = pipewire.dummy
                  priority.driver = 20000
                  #clock.id       = monotonic # realtime | tai | monotonic-raw | boottime
                  #clock.name     = "clock.system.monotonic"
              }
          }
          { factory = spa-node-factory
              args = {
                  factory.name    = support.node.driver
                  node.name       = Freewheel-Driver
                  priority.driver = 19000
                  node.group      = pipewire.freewheel
                  node.freewheel  = true
              }
          }

          # This creates a new Source node. It will have input ports
          # that you can link, to provide audio for this source.
          #{ factory = adapter
          #    args = {
          #        factory.name     = support.null-audio-sink
          #        node.name        = "my-mic"
          #        node.description = "Microphone"
          #        media.class      = "Audio/Source/Virtual"
          #        audio.position   = "FL,FR"
          #    }
          #}

          # This creates a single PCM source device for the given
          # alsa device path hw:0. You can change source to sink
          # to make a sink in the same way.
          #{ factory = adapter
          #    args = {
          #        factory.name           = api.alsa.pcm.source
          #        node.name              = "alsa-source"
          #        node.description       = "PCM Source"
          #        media.class            = "Audio/Source"
          #        api.alsa.path          = "hw:0"
          #        api.alsa.period-size   = 1024
          #        api.alsa.headroom      = 0
          #        api.alsa.disable-mmap  = false
          #        api.alsa.disable-batch = false
          #        audio.format           = "S16LE"
          #        audio.rate             = 48000
          #        audio.channels         = 2
          #        audio.position         = "FL,FR"
          #    }
          #}

          # Use the metadata factory to create metadata and some default values.
          #{ factory = metadata
          #    args = {
          #        metadata.name = my-metadata
          #        metadata.values = [
          #            { key = default.audio.sink   value = { name = somesink } }
          #            { key = default.audio.source value = { name = somesource } }
          #        ]
          #    }
          #}
      ]

      context.exec = [
          #{   path = <program-name>
          #    ( args = "<arguments>" )
          #    ( condition = [ { <key> = <value> ... } ... ] )
          #}
          #
          # Execute the given program with arguments.
          # If condition is given, the program is executed only when the context
          # properties all match the match rules.
          #
          # You can optionally start the session manager here,
          # but it is better to start it as a systemd service.
          # Run the session manager with -h for options.
          #
          #{ path = "/nix/store/ayj04lvgq3b958gickjx69ry4cqj1lki-pipewire-0.3.84/bin/pipewire-media-session" args = ""
          #  condition = [ { exec.session-manager = null } { exec.session-manager = true } ] }
          #
          # You can optionally start the pulseaudio-server here as well
          # but it is better to start it as a systemd service.
          # It can be interesting to start another daemon here that listens
          # on another address with the -a option (eg. -a tcp:4713).
          #
          #{ path = "/nix/store/ayj04lvgq3b958gickjx69ry4cqj1lki-pipewire-0.3.84/bin/pipewire" args = "-c pipewire-pulse.conf"
          #  condition = [ { exec.pipewire-pulse = null } { exec.pipewire-pulse = true } ] }
      ]
    '';

    #
    # rtirq status | head
    # less than my usb sound card that has from 90 to 72, irq/*-xhci_hcd
    ".config/pipewire/1-jack-rt.conf".text = ''
      # JACK client config file for PipeWire version "0.3.84" #
      #
      # Copy and edit this file in /etc/pipewire for system-wide changes
      # or in ~/.config/pipewire for local changes.
      #
      # It is also possible to place a file with an updated section in
      # /etc/pipewire/jack.conf.d/ for system-wide changes or in
      # ~/.config/pipewire/jack.conf.d/ for local changes.
      #

      context.properties = {
          ## Configure properties in the system.
          #mem.warn-mlock  = false
          #mem.allow-mlock = true
          #mem.mlock-all   = false
          log.level        = 0

          #default.clock.quantum-limit = 8192
      }

      context.spa-libs = {
          #<factory-name regex> = <library-name>
          #
          # Used to find spa factory names. It maps an spa factory name
          # regular expression to a library name that should contain
          # that factory.
          #
          support.* = support/libspa-support
      }

      context.modules = [
          #{ name = <module-name>
          #    ( args  = { <key> = <value> ... } )
          #    ( flags = [ ( ifexists ) ( nofail ) ] )
          #    ( condition = [ { <key> = <value> ... } ... ] )
          #}
          #
          # Loads a module with the given parameters.
          # If ifexists is given, the module is ignored when it is not found.
          # If nofail is given, module initialization failures are ignored.
          #
          #
          # Boost the data thread priority.
          { name = libpipewire-module-rt
              args = {
                  rt.prio      = 71
                  rt.time.soft = -1
                  rt.time.hard = -1
              }
              flags = [ ifexists nofail ]
          }

          # The native communication protocol.
          { name = libpipewire-module-protocol-native }

          # Allows creating nodes that run in the context of the
          # client. Is used by all clients that want to provide
          # data to PipeWire.
          { name = libpipewire-module-client-node }

          # Allows applications to create metadata objects. It creates
          # a factory for Metadata objects.
          { name = libpipewire-module-metadata }
      ]

      # global properties for all jack clients
      jack.properties = {
           node.latency        = 64/48000
           #node.rate          = 1/48000
           #node.quantum       = 1024/48000
           #node.lock-quantum  = true
           #node.force-quantum = 0
           #jack.show-monitor  = true
           #jack.merge-monitor = true
           #jack.show-midi     = true
           #jack.short-name    = false
           #jack.filter-name   = false
           #jack.filter-char   = " "
           #
           # allow:           Don't restrict self connect requests
           # fail-external:   Fail self connect requests to external ports only
           # ignore-external: Ignore self connect requests to external ports only
           # fail-all:        Fail all self connect requests
           # ignore-all:      Ignore all self connect requests
           #jack.self-connect-mode = allow
           #jack.locked-process    = true
           #jack.default-as-system = false
           #jack.fix-midi-events   = true
           #jack.global-buffer-size = false
           #jack.max-client-ports   = 768
           #jack.fill-aliases       = false
           #jack.writable-input     = true
      }

      # client specific properties
      jack.rules = [
          {   matches = [
                  {
                      # all keys must match the value. ! negates. ~ starts regex.
                      #client.name                = "Carla"
                      #application.process.binary = "jack_simple_client"
                      #application.name           = "~jack_simple_client.*"
                  }
              ]
              actions = {
                  update-props = {
                      #node.latency = 512/48000
                  }
              }
          }
          {   matches = [ { application.process.binary = "jack_bufsize" } ]
              actions = {
                  update-props = {
                      jack.global-buffer-size = true   # quantum set globally using metadata
                  }
              }
          }
          {   matches = [ { application.process.binary = "qsynth" } ]
              actions = {
                  update-props = {
                      node.always-process = false # makes qsynth idle
                      node.pause-on-idle = false  # makes audio fade out when idle
                      node.passive = out          # makes the sink and qsynth suspend
                  }
              }
          }
          {   matches = [ { client.name = "Mixxx" } ]
              actions = {
                  update-props = {
                      jack.merge-monitor = false
                  }
              }
          }
      ]
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

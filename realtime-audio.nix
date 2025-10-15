{ config, lib, inputs, pkgs, nixpkgs, ... }: {

  imports = [ inputs.musnix.nixosModules.musnix ];

  # realtime kernel
  #musnix.kernel.realtime = true;
  #musnix.kernel.packages = pkgs.linuxPackages_6_11_rt;
  # torgeir: removed musnix rtirq, postcommandscript does the same better
  #
  # or, latest kernels has realtime audio improvements
  # boot.kernelPackages = pkgs.linuxKernel.packages.linux_zen;
  # is realtime nescessary?
  boot.kernelPackages = pkgs.linuxPackages_6_16;

  # make helix native activation happy
  environment.etc.machine-id.source = ./machine-id;
  # Chatgpt suggests this instead
  # # Use systemd.tmpfiles.rules to create the symlink
  # systemd.tmpfiles.rules = [
  #   "L /etc/machine-id - - - - /var/lib/dbus/machine-id"
  # ];

  # # Ensure the /var/lib/dbus/machine-id has the correct content
  # environment.etc."var/lib/dbus/machine-id".text =
  #   builtins.readFile /path/to/your/static/machine-id;

  boot.blacklistedKernelModules = [
    # blacklist pci sound card, use usb arturia audiofuse
    "snd_hda_intel"

    # https://discourse.nixos.org/t/how-to-disable-bluetooth/9483
    # blacklist bluetooth
    # "bluetooth"
    # "btusb"

    # blacklist wifi
    "cfg80211"
  ];

  # minimize latency
  # also prioritize the pid and interrupts of the sound card
  boot.postBootCommands = ''
    #!/usr/bin/env bash

    # fix nix paths
    export PATH=/run/current-system/sw/bin/:$PATH

    priority=94
    irq=$(cat /proc/interrupts | grep "xhci_hcd" | awk '{sum=0; for(i=2;i<=NF-3;i++) sum+=$i; print sum, $1}' | sort -nr | head -1 | awk '{gsub(/:/, "", $2); print $2}')
    pid=$(pgrep irq/$irq-)
    thread=$(ps -eo comm | grep irq/$irq-)

    logger -p user.info "[realtime audio]: setting priority to $priority for soundcard irqs pid $pid, thread $thread."
    chrt -f -p $priority $pid

    # Spread across CPUs 24-31 (last CCD on 5950X)
    cpus="24-27"
    logger -p user.info "[realtime audio]: spreading soundcard irqs $pid on thread $thread to cpus $cpus."

    echo $cpus > /proc/irq/$irq/smp_affinity_list
    logger -p user.info "[realtime audio] smp_affinity_list for irq $irq is now $(cat /proc/irq/$irq/smp_affinity_list)"
  '';

  # check what is set with
  #   cat /proc/cmdline
  boot.kernelParams = [
    # make threads out of irqs, for preemt_dynamic kernels
    "threadirqs"
    # not needed for rt kernels
    "preemt=full"

    "isolcpus=24-27"     # Isolate 4 CPUs for audio IRQs
    "nohz_full=24-27"
    "rcu_nocbs=24-27"
    "irqaffinity=0-23"   # Keep other IRQs on otther cpus

    # TODO torgeir
    "usbhid.mousepoll=0"  # Reduce USB polling overhead
    "usbcore.autosuspend=-1"
    "printk.devkmsg=on"  # Disable message rate limiting
  ];

  # limit swappiness, but really i use zram instead
  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
    # This tells the kernel: "Don't delay USB processing to throttle log messages."
    "kernel.printk_ratelimit" = 0;  # Disable printk rate limiting
    "kernel.printk_ratelimit_burst" = 0;

    "vm.dirty_ratio" = 10;          # Default 20
    "vm.dirty_background_ratio" = 3; # Default 10
  };

  # disable wifi
  networking.wireless.enable = false;

  # https://gitlab.freedesktop.org/pipewire/pipewire/-/wikis/Performance-tuning
  # https://linuxmusicians.com/viewtopic.php?t=25556
  # https://github.com/chmaha/ArchProAudio
  # https://nixos.wiki/wiki/PipeWire
  #   pw-dump to check pipewire config
  #   systemctl --user status pipewire wireplumber
  #   systemctl --user restart pipewire wireplumber
  services.pipewire = {
    package = pkgs.pipewire;
    enable = true;
    audio.enable = true;
    wireplumber.enable = true;
    alsa.enable = true; # alsa support
    pulse.enable = true; # pipewire pulse emulation
    jack.enable = true; # pipewire jack emulation
    wireplumber.configPackages = [
      (pkgs.writeTextDir "share/wireplumber/main.lua.d/98-alsa-no-pop.lua" ''
        table.insert(alsa_monitor.rules, {
          matches = {
            {
              -- run pw-top to see the names
              { "node.name", "matches", "alsa_input.usb-LINE_6_HELIX*" },
              { "node.name", "matches", "alsa_output.usb-LINE_6_HELIX*" },
            },
          },
          apply_properties = {
            -- keep it alive
            ["session.suspend-timeout-seconds"] = 0,
            ["suspend-node"] = false,
            ["node.pause-on-idle"] = false,
            ["api.alsa.disable-batch"] = true,
            ["priority.session"] = 3000,
            ["api.alsa.rate"] = 48000,
            ["api.alsa.period-size"] = 128,
          }
        })

        table.insert(alsa_monitor.rules, {
          matches = {
            {
              -- run pw-top to see the names
              { "node.name", "matches", "alsa_input.usb-ARTURIA_AudioFuse*" },
              { "node.name", "matches", "alsa_output.usb-ARTURIA_AudioFuse*" },
            },
          },
          apply_properties = {

            -- keep it alive
            ["session.suspend-timeout-seconds"] = 0,
            ["suspend-node"] = false,
            ["node.pause-on-idle"] = false,

            -- pipewire docs: ALSA Buffer Properties:
            -- It removes the extra delay added of period-size/2 if the device can
            -- support this. for batch devices it is also a good idea to lower the
            -- period-size (and increase the IRQ frequency) to get smaller batch
            -- updates and lower latency.
            ["api.alsa.disable-batch"] = true,

            -- pipewire docs: Change node priority:
            -- Device priorities are usually from 0 to 2000.
            ["priority.session"] = 3000,

            -- pipewire docs: ALSA Buffer Properties
            -- extra delay between hardware pointers and software pointers
            ["api.alsa.headroom"] = 32,

            -- Interface: Arturia Audiofuse
            -- Reaper using alsa only can do this, without any pops;
            --   Rate 48000
            --   Size 64
            --   Periods 3

            -- https://wiki.linuxaudio.org/wiki/list_of_jack_frame_period_settings_ideal_for_usb_interface
            ["api.alsa.rate"] = 48000,
            ["api.alsa.period-num"] = 3,
            ["api.alsa.period-size"] = 168,
            -- experiments
            --["api.alsa.period-size"] = 48 -- and run reaper with PIPEWIRE_LATENCY=48/48000 reaper, this gives 1ms latency
            --["api.alsa.period-size"] = 64
            --["api.alsa.period-size"] = 96
            --["api.alsa.period-size"] = 128
            --["api.alsa.period-size"] = 168
            --["api.alsa.period-size"] = 144
            --["api.alsa.period-size"] = 160
            --["api.alsa.period-size"] = 256
          },
        })
      '')
    ];
  };

  # jack
  #
  # adjust pipewire settings at runtime
  # ~direct monitoring, some pops
  #   pw-metadata -n settings 0 clock.force-quantum 48
  # reasonable latency, few/no pops
  #   pw-metadata -n settings 0 clock.force-quantum 480
  #
  # https://linuxmusicians.com/viewtopic.php?t=26271
  #
  # flip reaper audio system over to DummyAudio and back to Jack
  # after adjusting these. Also remember to
  #   systemctl --user restart pipewire wireplumber
  environment.etc."/pipewire/jack.conf.d/override.conf".text = ''
    jack.properties = {
      node.force-quantum = 48 # 0.001s, given alsa rate 48000
      #node.force-quantum = 64 # 0.00xs
      # node.force-quantum = 96 # 0.002s
      # node.force-quantum = 128 # 0.0026s
      # node.force-quantum = 144 # 0.003s
      # node.force-quantum = 240 # 0.005s
      # node.force-quantum = 288 # 0.006s
      # node.force-quantum = 384 # 0.008s
      # node.force-quantum = 480 # 0.01s
    }
  '';

  environment.etc."/pipewire/pipewire.conf".text =
    builtins.replaceStrings
      ["rt.prio       = 88"]
      ["rt.prio       = 94"]
      (builtins.readFile "${pkgs.pipewire}/share/pipewire/pipewire.conf");

  # environment.etc."/pipewire/pipewire.conf.d/00-rtprio.conf".text = builtins.toJSON {
  #   "context.properties" = {
  #     # makes pipewire not load the default libpipewire-module-rt first
  #   };
  #   "context.modules" = [
  #     {
  #       name = "libpipewire-module-rt";
  #       args = {
  #         "nice.level" = -11;
  #         "rt.prio" = 94;
  #         "rt.time.soft" = 2000000;
  #         "rt.time.hard" = 2000000;
  #       };
  #       flags = ["ifexists" "nofail"];
  #     }
  #   ];
  # };

  # help reaper control cpu latency, when you start it from audio group user
  # control power mgmt from userspace (audio) group
  # https://wiki.linuxaudio.org/wiki/system_configuration#quality_of_service_interface
  #
  # Run "udevadm monitor" and do what you want to monitor, e.g. plug something
  services.udev.extraRules = ''
    DEVPATH=="/devices/virtual/misc/cpu_dma_latency", OWNER="root", GROUP="audio", MODE="0660"

    # set scheduler for nvme
    # cat /sys/block/*/queue/scheduler
    ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="none"

    # restart dhcpcd on sleep wake
    ACTION=="remove", SUBSYSTEM=="usb", DRIVERS=="usb", ATTRS{idVendor}=="1c75", ATTRS{idProduct}=="af02", RUN+="${pkgs.systemd}/bin/systemctl --no-block stop dhcpcd.service"
    ACTION=="add", SUBSYSTEM=="usb", DRIVERS=="usb", ATTRS{idVendor}=="1c75", ATTRS{idProduct}=="af02", RUN+="${pkgs.systemd}/bin/systemctl --no-block restart dhcpcd.service"

    # prevent ps4 touchpad acting as mouse
    # usb
    #ACTION=="add|change", ATTRS{name}=="Sony Interactive Entertainment Wireless Controller Touchpad", ENV{LIBINPUT_IGNORE_DEVICE}="1"
    # bluetooth
    #ACTION=="add|change", ATTRS{name}=="Wireless Controller Touchpad", ENV{LIBINPUT_IGNORE_DEVICE}="1"
  '';

  # force full perf cpu mode
  # cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
  # obs: corecontrol also controls this
  powerManagement.cpuFreqGovernor = "performance";

  # These settings go well with reaper
  #   Thread priority: Highest (recommended)
  #   Behavior: 8 - Aggressive
  #   Anticipate FX processing [x]
  #   Allow live FX processing off (5950x)
  #
  # enable realtime kit, so that pipewire's realtime priority can be adjusted automatically
  # https://gitlab.freedesktop.org/pipewire/pipewire/-/wikis/Performance-tuning#rtkit
  # rtkit != rtirq
  security.rtkit.enable = true;
  systemd.services.rtkit-daemon.serviceConfig.ExecStart = [
    ""
    # claude raised max-realtime-priority from 88 to 94
    "${pkgs.rtkit}/libexec/rtkit-daemon --scheduling-policy=FIFO --our-realtime-priority=95 --max-realtime-priority=94 --min-nice-level=-19 --rttime-usec-max=2000000 --users-max=100 --processes-per-user-max=1000 --threads-per-user-max=10000 --actions-burst-sec=10 --actions-per-burst-max=1000 --canary-cheep-msec=30000 --canary-watchdog-msec=60000"
  ];

  systemd.services.pipewire-affinity = {
    description = "Pin user Pipewire to isolated CPUs";
    after = [ "user@1000.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.writeShellScript "pipewire-affinity" ''
        #!/usr/bin/env bash
        sleep 5

        # Get your username dynamically
        USER_NAME="${config.users.users.torgeir.name}"
        USER_ID=$(${pkgs.coreutils}/bin/id -u $USER_NAME)

        # Pin main pipewire process
        for p in $(${pkgs.procps}/bin/pgrep -u $USER_ID -x pipewire); do
          ${pkgs.util-linux}/bin/taskset -cp 24-27 $p && \
            ${pkgs.util-linux}/bin/chrt -f -p 89 $p && \
            echo "Pinned pipewire PID $p to CPUs 24-27 with priority 94"
        done

        # Pin all data-loop threads
        for tid in $(${pkgs.procps}/bin/ps -eLo tid,euser,comm | ${pkgs.gawk}/bin/awk -v user="$USER_NAME" '$2==user && $3=="data-loop" {print $1}'); do
          ${pkgs.util-linux}/bin/taskset -cp 24-27 $tid && \
            ${pkgs.util-linux}/bin/chrt -f -p 89 $tid && \
            echo "Pinned data-loop TID $tid to CPUs 24-27 with priority 94"
        done

        # Pin pipewire-pulse if running
        for p in $(${pkgs.procps}/bin/pgrep -u $USER_ID -x pipewire-pulse); do
          ${pkgs.util-linux}/bin/taskset -cp 24-27 $p && \
            echo "Pinned pipewire-pulse PID $p to CPUs 24-27"
        done
      ''}";
    };
  };

  systemd.user.services.reaper-rt = {
    description = "Set REAPER/yabridge RT priority";
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.writeShellScript "reaper-rt" ''
        while true; do
          # Check if REAPER is running
          if ! ${pkgs.procps}/bin/pgrep -x reaper > /dev/null 2>&1; then
            sleep 30
            continue
          fi

          # REAPER main process
          for p in $(${pkgs.procps}/bin/pgrep -x reaper); do
            if ${pkgs.util-linux}/bin/chrt -f -p 92 $p 2>/dev/null; then
              echo "Set REAPER PID $p to priority 92"
            fi
            if ${pkgs.util-linux}/bin/taskset -cp 26 $p 2>/dev/null; then
              echo "Pinned REAPER PID $p to CPU 26"
            fi
          done

          # Yabridge processes
          for p in $(${pkgs.procps}/bin/pgrep -f yabridge-host); do
            if ${pkgs.util-linux}/bin/chrt -f -p 92 $p 2>/dev/null; then
              echo "Set yabridge-host PID $p to priority 92"
            fi
          done

          # Wineserver
          for p in $(${pkgs.procps}/bin/pgrep -x wineserver); do
            if ${pkgs.util-linux}/bin/chrt -f -p 92 $p 2>/dev/null; then
              echo "Set wineserver PID $p to priority 92"
            fi
          done

          sleep 30
        done
      ''}";
      Restart = "always";
      RestartSec = 5;
    };
    wantedBy = [ "default.target" ];
  };

  # logrotate less
  systemd.timers.logrotate.timerConfig = {
    OnCalendar = lib.mkForce "weekly";
    Persistent = true;
  };

  # allow realtime for pipewire and user audio group
  security.pam.loginLimits = [
    # TODO torgeir unødvendig?
    # {domain = "@pipewire"; item = "memlock"; type = "-"; value = "unlimited";}
    # {domain = "@pipewire"; item = "rtprio"; type = "-"; value = "98";}
    # {domain = "@pipewire"; item = "nice"; type = "-"; value = "-11";}
    {domain = "@audio"; item = "memlock"; type = "-"; value = "unlimited";}
    {domain = "@audio"; item = "rtprio"; type = "-"; value = "98";}
    {domain = "@audio"; item = "nice"; type = "-"; value = "-11";}
  ];

  environment.systemPackages = with pkgs; [
    perf

    cpuset

    sysstat # iostat etc
    iotop # e.g. sudo iotop -d 0.1 -a
    lsof # e.g. lsof -p $(pidof wineserver)

    jalv
    lilv # provides tools like lv2ls

    # piano
    # 2025 funker ikke med siste nix-unstable
    # 20250115 ingen av disse to virker
    # 20250125 stable funker
    pkgs.stable.linuxsampler # add lv2 path /run/current-system/sw/lib/lv2/ to reaper, rescan
    qsampler # launch this and add channel, select plugin and the .gig piano file

    (writeScriptBin "reaper-pw"
      "pw-metadata -n settings 0 clock.force-quantum $1")
    (writeScriptBin "reaper-pw-48"
      "pw-metadata -n settings 0 clock.force-quantum 48")
    (writeScriptBin "reaper-pw-96"
      "pw-metadata -n settings 0 clock.force-quantum 96")
    (writeScriptBin "reaper-pw-144"
      "pw-metadata -n settings 0 clock.force-quantum 144")
    (writeScriptBin "reaper-pw-256"
      "pw-metadata -n settings 0 clock.force-quantum 256")
    (writeScriptBin "reaper-pw-512"
      "pw-metadata -n settings 0 clock.force-quantum 512")
  ];
  # https://magazine.odroid.com/article/setting-irq-cpu-affinities-improving-irq-performance-on-the-odroid-xu4/
  # services.irqbalance.enable = true;

  environment.variables = {
    DSSI_PATH =
      "$HOME/.dssi:$HOME/.nix-profile/lib/dssi:/run/current-system/sw/lib/dssi";
    LADSPA_PATH =
      "$HOME/.ladspa:$HOME/.nix-profile/lib/ladspa:/run/current-system/sw/lib/ladspa";
    LV2_PATH =
      "$HOME/.lv2:$HOME/.nix-profile/lib/lv2:/run/current-system/sw/lib/lv2";
    LXVST_PATH =
      "$HOME/.lxvst:$HOME/.nix-profile/lib/lxvst:/run/current-system/sw/lib/lxvst";
    VST_PATH =
      "$HOME/.vst:$HOME/.nix-profile/lib/vst:/run/current-system/sw/lib/vst";
  };

# pw-top with this setup gives, after playing a while in helix native with pipewire period set to 48
# S   ID  QUANT   RATE    WAIT    BUSY   W/Q   B/Q  ERR FORMAT           NAME
# I   30      0      0   0.0us   0.0us  ???   ???     0                  Dummy-Driver
# S   31      0      0    ---     ---   ---   ---     0                  Freewheel-Driver
# S   59      0      0    ---     ---   ---   ---     0                  bluez_midi.server
# S   62      0      0    ---     ---   ---   ---     0                  alsa_output.usb-LINE_6_HELIX_2929049-01.pro-output-0
# S   63      0      0    ---     ---   ---   ---     0                  alsa_input.usb-LINE_6_HELIX_2929049-01.pro-input-0
# R   65     48  48000 332.3us   0.7us  0.33  0.00    4    S32LE 8 48000 alsa_input.usb-ARTURIA_AudioFuse-00.pro-input-0
# R   49      0      0   1.9us   2.6us  0.00  0.00    0                   + Midi-Bridge
# R   64      0      0   5.0us   4.5us  0.00  0.00    0    S32LE 8 48000  + alsa_output.usb-ARTURIA_AudioFuse-00.pro-output-0
# R  133     48      0   7.0us 309.8us  0.01  0.31    9                   + REAPER
# S   70      0      0    ---     ---   ---   ---     0                  alsa_input.usb-046d_HD_Pro_Webcam_C920_4928B4EF-02.analog-stereo
# S   73      0      0    ---     ---   ---   ---     0                  alsa_input.usb-Elgato_Cam_Link_4K_00051EF253000-03.analog-stereo
# S  126      0      0    ---     ---   ---   ---     0                  v4l2_input.pci-0000_09_00.0-usb-0_1.4.3.4_1.0
# S  128      0      0    ---     ---   ---   ---     0                  v4l2_input.pci-0000_a6_00.1-usb-0_3_1.0

}

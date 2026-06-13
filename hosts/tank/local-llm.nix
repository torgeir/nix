{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Strix Halo (gfx1151) unified memory: without amd_iommu=off, ROCm is capped at ~2 GB.
  # gttsize=131072 sets a 128 GB ceiling so the GPU can map all 64 GB system RAM.
  # ttm.pages_limit prevents allocation failures when loading large models.
  boot.kernelParams = [
    "amd_iommu=off"
    "amdgpu.gttsize=131072"
    "ttm.pages_limit=31457280"
  ];

  environment.systemPackages = with pkgs; [
    lemonade-server
    # Ryzen AI 9 HX PRO 370 (Strix Halo, gfx1151, XDNA2 NPU, 30GB iGPU VRAM) model suggestions:
    # - Qwen3.6-35B-A3B-MTP-GGUF    -- llamacpp/ROCm, 23.8GB, vision+MTP, same LLM backbone as LMX-Omni
    # - LMX-Omni-52B-Halo           -- multimodal collection (LLM+vision+whisper+TTS)
    # - Qwen3-14B-GGUF              -- lighter, 8.5GB, reasoning/coding
  ];

  systemd.tmpfiles.rules = [
    "d /fast/shared/apps/lemonade 0755 torgeir users -"
    # Fake /opt/rocm so lemond detects AMD ROCm (it hardcodes this Ubuntu path)
    "d /opt/rocm 0755 root root -"
    "d /opt/rocm/lib 0755 root root -"
    "d /opt/rocm/.info 0755 root root -"
    "f /opt/rocm/.info/2024-01-01 0644 root root -"
    "L /opt/rocm/lib/libhsa-runtime64.so - - - - ${pkgs.rocmPackages.rocm-runtime}/lib/libhsa-runtime64.so"
    "L /opt/rocm/lib/libhsa-runtime64.so.1 - - - - ${pkgs.rocmPackages.rocm-runtime}/lib/libhsa-runtime64.so.1"
    "L /opt/rocm/lib/libamdhip64.so - - - - ${pkgs.rocmPackages.clr}/lib/libamdhip64.so"
    "L /opt/rocm/lib/libamdhip64.so.6 - - - - ${pkgs.rocmPackages.clr}/lib/libamdhip64.so.6"
  ];

  systemd.services.lemond = {
    description = "Lemonade LLM server";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" "local-fs.target" ];
    path = with pkgs; [ bash gnutar gzip curl git unzip ];
    environment = {
      HF_HOME = "/fast/shared/apps/lemonade/huggingface";
      XDG_RUNTIME_DIR = "/run/user/1000";
      HIP_PATH = "/opt/rocm";
      ROCM_PATH = "/opt/rocm";
      HSA_OVERRIDE_GFX_VERSION = "11.5.0";
      # llamacpp must come before whispercpp — both ship libggml.so.0 but different versions.
      # No ROCm paths here — ROCm ships gflags/glog which double-loads against lemond's static copy.
      LD_LIBRARY_PATH = "/fast/shared/apps/lemonade/bin/llamacpp/rocm-stable:/fast/shared/apps/lemonade/bin/llamacpp/vulkan:/fast/shared/apps/lemonade/bin/whispercpp/vulkan:${pkgs.stdenv.cc.cc.lib}/lib:${pkgs.vulkan-loader}/lib:${pkgs.openssl.out}/lib";
    };
    serviceConfig = {
      ExecStart = "${pkgs.lemonade-server}/bin/lemond --host 0.0.0.0 --port 13305 /fast/shared/apps/lemonade";
      User = "torgeir";
      Group = "users";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };

  # Expose ROCm libs in /run/opengl-driver/lib/ so NixOS-built binaries (lemond) can detect AMD GPU.
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      rocmPackages.clr
      rocmPackages.rocm-runtime
    ];
  };

  # Allow lemonade's downloaded pre-built llama-server (ROCm binary) to run on NixOS.
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib
      zlib
      vulkan-loader
      openssl
      rocmPackages.clr
      rocmPackages.rocm-runtime
    ];
  };

  networking.firewall.allowedTCPPorts = [ 13305 ];
}

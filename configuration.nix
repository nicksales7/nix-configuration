{ config, lib, pkgs, ... }:
let 
  nvidia-offload = pkgs.writeShellScriptBin "nvidia-offload" ''
  export __NV_PRIME_RENDER_OFFLOAD = 1
  export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
  export __GLX_VENDOR_LIBRARY_NAME=nvidia
  export __VK_LAYER_NV_optimus=NVIDIA_only
  exec -a "$0" "$@"
  '';
in

{
  imports = [
    ./hardware-configuration.nix # Hardware configuration.
  ];

  # Bootloader settings.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.blacklistedKernelModules = [ "nouveau" ];

  # System hostname.
  networking.hostName = "nixos";

  # Network configuration.
  networking.networkmanager.enable = true; # Easy-to-use network management.

  # Timezone and localization settings.
  time.timeZone = "Canada/Eastern";
  i18n.defaultLocale = "en_US.UTF-8";

  # Enable OpenGL
  hardware.graphics = {
    enable = true;
  };

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.beta;
    nvidiaPersistenced = true;
    prime = {
      offload.enable = true;
      amdgpuBusId = "PCI:5:0:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  services.blueman.enable = true;
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # X11 and window manager settings.
  services.xserver = {
    enable = true;
    videoDrivers = ["nvidia"];
    desktopManager.xterm.enable = false;
    displayManager = {
      defaultSession = "none+i3";
    };
    windowManager.i3 = {
      enable = true;
      extraPackages = with pkgs; [ rofi i3status i3blocks lm_sensors ];
    };
    xkb.layout = "us";
  };

  services.tlp = {
        enable = true;
        settings = {
          CPU_SCALING_GOVERNOR_ON_AC = "performance";
          CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

          CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
          CPU_ENERGY_PERF_POLICY_ON_AC = "performance";

          CPU_MIN_PERF_ON_AC = 0;
          CPU_MAX_PERF_ON_AC = 100;
          CPU_MIN_PERF_ON_BAT = 0;
          CPU_MAX_PERF_ON_BAT = 20;

         START_CHARGE_THRESH_BAT0 = 40; 
         STOP_CHARGE_THRESH_BAT0 = 80; 

        };
  };

  services.logind = {
    powerKey = "suspend";
  };
  
  services.libinput = {
    enable = true;
    mouse = {
      accelProfile = "flat";
    };
    touchpad = {
      accelProfile = "flat";
      disableWhileTyping = true;
      naturalScrolling = true;
      tapping = false;
    };
  };

  # Enable unfree packages and flakes.
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Enable printing support.
  services.printing.enable = true;

  # Enable sound using PipeWire.
  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  # User configuration.
  users.users.nick = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable sudo for the user.
    packages = with pkgs; [ tree ];
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true; 
  };

  environment.variables = {
    GTK_THEME = "Adwaita:dark"; 
  };
  
  # System-wide packages.
  environment.systemPackages = with pkgs; [
    helix
    wget
    alacritty
    google-chrome
    git
    neofetch
    discord    
    ranger
    zathura
    nvidia-offload
  ];

  # Enable OpenSSH daemon.
  services.openssh.enable = true;

  # System state version (do not change without migration).
  system.stateVersion = "24.11";
}

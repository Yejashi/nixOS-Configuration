# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  # hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;


  boot = {
    # Get latest kernel
    kernelPackages = pkgs.linuxPackages_latest;

    # initrd.kernelModules = [ "nvidia-drm" ];
    #initrd.kernelModules = [ "amdgpu" ];

    initrd.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];

    loader = {
      systemd-boot = {
        enable = true;
        #devices = [ "/dev/vda" ];
        #useOSProber = true;
        # You can have at most 5 nixos configurations at a time
        configurationLimit = 5;
      };
      timeout = 5;
    };
  };

  hardware.graphics = {
    enable = true;
  };

  hardware.nvidia = {

    # Modesetting is required.
    modesetting.enable = true;

    nvidiaPersistenced = true;
    # prime = {
    #     offload.enable = true;
    #     #sync.enable = true;

    #     # amdgpuBusId = "PCI:5:0:0";

    #     # nvidiaBusId = "PCI:1:0:0";
    # };

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    # Enable this if you have graphical corruption issues or application crashes after waking
    # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead 
    # of just the bare essentials.
    powerManagement.enable = false;

    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    # powerManagement.finegrained = false;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of 
    # supported GPUs is at: 
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus 
    # Only available from driver 515.43.04+
    # Currently alpha-quality/buggy, so false is currently the recommended setting.
    open = false;

    # Enable the Nvidia settings menu,
	# accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    # package = config.boot.kernelPackages.nvidiaPackages.stable;
    package = config.boot.kernelPackages.nvidiaPackages.production;
  };

#   boot.blacklistedKernelModules = [
#     "nouveau"
#     "rivafb"
#     "nvidiafb"
#     "rivatv"
#     "nv"
#     "uvcvideo"
#   ];

  networking.hostName = "yejashi"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  services = {
    xserver = {
      # Enable the X11 windowing system.
      enable = true;

      videoDrivers = [ "nvidia" "amdgpu"];

      displayManager = {
        gdm.enable = true;
      };

      desktopManager = {
        # Enable the GNOME Desktop Environment.
        gnome = {
            enable = true;
            extraGSettingsOverridePackages = [ pkgs.mutter ];
            extraGSettingsOverrides = ''
                [org.gnome.mutter]
                edge-tiling=true
            '';
        };
      };
    };
  };


  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  #sound = {
   # enable = true;
    #mediaKeys.enable = true;
  #};

  hardware.bluetooth = {
    enable = true;
    #hsphfpd.enable = true; # Conflicts with WirePlumber
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
      };
    };
  };
  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.yejashi = {
    isNormalUser = true;
    description = "yejashi";
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "storage"
      "network"
      "lp"
    ];
    # initialPassword = "password";
    packages = with pkgs; [
      #  thunderbird
    ];
  };

  # Install firefox.
  programs.firefox.enable = true;
  programs.steam.enable = true;
  services.input-remapper.enable = true;
  services.flatpak.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;


  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    wget
    curl
    zip
    vim
    git
    killall
    sshfs
    nix-ld
    python312
    python312Packages.pillow

    # Gnome Packages
    gnome-tweaks
    kitty-themes

    # Icons + Themes
    tela-circle-icon-theme
    orchis-theme
    material-icons
    material-design-icons
    # oranchelo-icon-theme

    kitty
    xfce.thunar
    vscode
    starship
    input-remapper
    # flatpak
    # flatpak-builder
    # Add zen-browser later on
  ];

  # TODO: Find a way to fix neofetch icons
  fonts.packages = with pkgs; [
    oranchelo-icon-theme
    source-code-pro
    noto-fonts
    nerdfonts
    cantarell-fonts
    mononoki
  ];

  # Can't do this in home-manager for some reason, bummer
  programs.starship = {
    enable = true;
    interactiveOnly = true;
    # Configuration written to ~/.config/starship.toml
    settings = {
      # add_newline = false;

      # character = {
      #   success_symbol = "[➜](bold green)";
      #   error_symbol = "[➜](bold red)";
      # };

      # package.disabled = true;
    };

    presets = [ "tokyo-night" ];
  };

  #   services.flatpak.package = [
  #     "io.github.zen_browser.zen"
  #   ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?

}

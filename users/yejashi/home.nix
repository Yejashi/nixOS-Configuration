{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "yejashi";
  home.homeDirectory = "/home/yejashi";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.05"; # Please read the comment before changing.

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # programs.spicetify =
  #   let
  #     spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.system};
  #   in
  #   {
  #     enable = true;
  #     enabledExtensions = with spicePkgs.extensions; [
  #       adblock
  #       hidePodcasts
  #       shuffle # shuffle+ (special characters are sanitized out of extension names)
  #     ];
  #     theme = spicePkgs.themes.catppuccin;
  #     colorScheme = "mocha";
  #   };

  imports = [
    # For home-manager
    inputs.spicetify-nix.homeManagerModules.default
  ];

  home.sessionVariables = {
    EDITOR = "vim";
  };
  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    htop
    neofetch
    # spotify # It comes with spicetify?
    foliate
    variety
    slack
    rofi
    fzf
    cpu-x
    # starship
    ranger
    discord
    neovim
    zoom-us
    gdu
    obsidian
    openssl
    lshw
    inxi
    cava
    btop
    # vimPlugins.vim-plug
    # Gnome Extensions
    gnomeExtensions.blur-my-shell
    gnomeExtensions.bluetooth-battery-meter
    gnomeExtensions.just-perfection
    gnomeExtensions.tray-icons-reloaded
    gnomeExtensions.user-themes
    gnomeExtensions.quick-settings-audio-panel
    linuxKernel.packages.linux_zen.cpupower
  ];


  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
    ".config/ranger" = {
      source = ./ranger;
      recursive = true;
    };

    ".config/rofi" = {
      source = ./rofi;
      recursive = true;
    };

    ".config/neofetch" = {
      source = ./neofetch;
      recursive = true;
    };

    ".config/kitty" = {
      source = ./kitty;
      recursive = true;
    };

    ".config/input-remapper-2" = {
      source = ./input-remapper-2;
      recursive = true;
    };

    # Make firefox look roundy, might i say ride eternal, shiny and chrome
    # ".mozilla/firefox/huuecasm.default/chrome" = {
    #   source = ./chrome;
    #   recursive = true;
    # };

    # ".mozilla/firefox/*.default/user.js" = {
    #   source = ./user.js;
    # };

    # "Documents/wallpapers/walls" = {
    #   source = ./walls;
    #   recursive = true;
    # };

    ".vimrc" = {
      source = ./.vimrc;
    };

    ".bashrc" = {
      source = ./.bashrc;
    };

    ".ssh/config" = {
      source = ./config;
    };

    ".config/variety/variety.conf" = {
      source = ./variety/variety.conf;
    };

  };

  dconf.settings = {
    # ...
    "org/gnome/shell" = {
      disable-user-extensions = false;

      # `gnome-extensions list` for a list
      enabled-extensions = [
        "blur-my-shell@aunetx"
        "Bluetooth-Battery-Meter@maniacx.github.com"
        "trayIconsReloaded@selfmade.pl"
        "just-perfection-desktop@just-perfection"
        "system-monitor@gnome-shell-extensions.gcampax.github.com"
        "user-theme@gnome-shell-extensions.gcampax.github.com"
        "workspace-indicator@gnome-shell-extensions.gcampax.github.com"
        "quick-settings-audio-panel@rayzeq.github.io"
      ];

      favorite-apps = [
        "firefox.desktop"
        "code.desktop"
        "spotify.desktop"
        "org.gnome.Nautilus.desktop"
        "kitty.desktop"
      ];

    };

    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };

    "org/gnome/desktop/wm/preferences" = {
      button-layout = "appmenu:minimize,maximize,close";
      action-middle-click-titlebar = "minimize";
    };

    "org/gnome/shell/extensions/user-theme" = {
      name = "Orchis-Dark";
    };

    # Remap default key bindings
    "org/gnome/desktop/wm/keybindings" = {
      switch-to-workspace-left = [ "<Super>Tab" ];
    };

    "org/gnome/desktop/wm/keybindings" = {
      switch-to-workspace-right = [ "<Super>grave" ];
    };

    # - Disable conflicts
    "org/gnome/desktop/wm/keybindings" = {
      switch-applications = [ ];
    };

    "org/gnome/desktop/wm/keybindings" = {
      switch-group = [ ];
    };

    # Custom Keybindings
    "org/gnome/settings-daemon/plugins/media-keys" = {
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
      ];
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      name = "Rofi";
      binding = "<Control>p";
      command = "rofi -show drun";
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
      name = "Kitty";
      binding = "<Super>Return";
      command = "kitty --single-instance";
    };
  };

  # Legacy Application Theme
  gtk = {
    enable = true;

    theme = {
      name = "Orchis-Dark";
      package = pkgs.orchis-theme;
    };

    iconTheme = {
      name = "Tela-circle";
      package = pkgs.tela-circle-icon-theme;
    };
  };

  # I should be executed for writing something like this. Forgive me dear observer
  home.activation.postBuildScript = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -d "~/home_env" ]; then
        /run/current-system/sw/bin/python -m venv home_env
    fi
  '';

  programs.spicetify =
    let
      spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.system};
    in
    {
      enable = true;
      enabledExtensions = with spicePkgs.extensions; [
        shuffle # shuffle+ (special characters are sanitized out of extension names)
      ];
      theme = spicePkgs.themes.starryNight;
      colorScheme = "mocha";
    };



}

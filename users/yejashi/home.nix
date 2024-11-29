{ config, pkgs, lib, ... }:

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

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    htop
    neofetch
    spotify
    foliate
    variety
    slack
    rofi
    fzf
    # starship
    ranger
    # vimPlugins.vim-plug
    # Gnome Extensions
    gnomeExtensions.blur-my-shell
    gnomeExtensions.bluetooth-battery-meter
    gnomeExtensions.just-perfection
    gnomeExtensions.tray-icons-reloaded
    gnomeExtensions.user-themes
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

    "Documents/wallpapers/walls" = {
      source = ./walls;
      recursive = true;
    };

    ".vimrc" = {
      source = ./.vimrc;
    };

    ".bashrc" = {
      source = ./.bashrc;
    };

    ".ssh/config" = {
      source = ./config;
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
      ];

      favorite-apps = [
        "firefox.desktop"
        "code.desktop"
        "spotify.desktop"
        "org.gnome.Nautilus.desktop"
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

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings" = {
        "custom0" = {
            name = "Rofi";
            binding = "<Control>p";
            command = "rofi -show drun";
        }:
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

  # TODO: What to do with this?
#   programs.python = {
#     enable = true;
#     package = pkgs.python312;
#   };
  
  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/yejashi/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    EDITOR = "vim";
  };

  ## Manage dot files here: store files in github and create symlinks where they are necessary

}

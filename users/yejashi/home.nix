{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  # Lifted out of home.packages so systemd.user.services.opencode-server can
  # point at the same wrapped derivation rather than whatever happens to be on
  # PATH. The wrapper matters for the service too: it puts nodejs on PATH for
  # the language servers opencode spawns.
  opencodeWrapped =
    with pkgs;
    symlinkJoin {
      name = "opencode";
      paths = [ opencode ];
      buildInputs = [ makeWrapper ];
      postBuild =
        let
          silenceHarnessMemoryLogs = writeShellScript "silence-harness-memory-logs" ''
            cacheRoot="''${XDG_CACHE_HOME:-$HOME/.cache}/opencode/packages"

            for pluginFile in "$cacheRoot"/harness-memory@*/node_modules/harness-memory/dist/plugin/index.js; do
              [ -f "$pluginFile" ] || continue

              if ${gnugrep}/bin/grep -Fq 'console.log(PLUGIN_LOG_PREFIX, ...args);' "$pluginFile"; then
                ${gnused}/bin/sed -i \
                  's/  console\.log(PLUGIN_LOG_PREFIX, \.\.\.args);/  return;/' \
                  "$pluginFile"
              fi
            done
          '';
        in
        ''
          wrapProgram $out/bin/opencode \
            --run ${silenceHarnessMemoryLogs} \
            --prefix PATH : ${lib.makeBinPath [ nodejs ]} \
            --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ stdenv.cc.cc.lib ]}
        '';
    };
in

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
  home.stateVersion = "24.11"; # Please read the comment before changing.

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
    inputs.spicetify-nix.homeManagerModules.default
  ];

  home.sessionVariables = {
    EDITOR = "vim";
  };
  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    (writeShellScriptBin "lm-studio" ''
      exec env -u ELECTRON_RUN_AS_NODE \
        ${appimage-run}/bin/appimage-run \
        /home/yejashi/HDD/AI/apps/LM-Studio-0.4.21-2-x64.AppImage "$@"
    '')
    (writeShellScriptBin "lms" ''
      exec /home/yejashi/.lmstudio/bin/lms "$@"
    '')
    htop
    fastfetch
    playerctl
    foliate
    variety
    slack
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
    opencodeWrapped

    # Attach a TUI to the always-running opencode-server in the current repo,
    # instead of `opencode` starting its own private session. Sources the
    # password at runtime rather than going through home.sessionVariables,
    # which would bake the secret into the world-readable Nix store.
    (writeShellScriptBin "oc" ''
      envFile="$HOME/.config/opencode-server.env"
      if [ ! -r "$envFile" ]; then
        echo "oc: missing $envFile (see systemd.user.services.opencode-server)" >&2
        exit 1
      fi
      set -a
      . "$envFile"
      set +a
      exec ${opencodeWrapped}/bin/opencode attach \
        "''${OPENCODE_SERVER_URL:-http://127.0.0.1:4096}" --dir "$PWD" "$@"
    '')
    lshw
    inxi
    cava
    git-lfs
    btop-rocm
    plocate
    nix-index
    pciutils
    mpv
    waybar
    swaybg
    wlogout
    gimp-with-plugins
    libreoffice-qt6-fresh
    # vimPlugins.vim-plug
    # Gnome Extensions
    gnome-ext-hanabi
    gnomeExtensions.blur-my-shell
    gnomeExtensions.bluetooth-battery-meter
    gnomeExtensions.just-perfection
    gnomeExtensions.tray-icons-reloaded
    gnomeExtensions.user-themes
    gnomeExtensions.quick-settings-audio-panel
    gnomeExtensions.forge
    linuxKernel.packages.linux_zen.cpupower
    viewnior
    glow
    grip
    graphviz
    rustc
    cargo
    rustfmt
    clippy
    peek
    spotify
    thunderbird
    mailspring
    youtube-music
    ghostscript
    xcolor
    zotero
    walker
    elephant
    yazi
    vlc
    tmux
    jq
    claude-code
    # CLI tools (llama-cli, llama-bench, ...) for poking at models by hand.
    # The server itself runs from services.llama-cpp, not from here.
    llama-cpp-vulkan
  ];

  xdg.desktopEntries.lm-studio = {
    name = "LM Studio";
    comment = "Run local language models";
    exec = "lm-studio";
    icon = "applications-development";
    terminal = false;
    categories = [ "Development" "Utility" ];
  };


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

    ".config/opencode" = {
      source = ./opencode;
      recursive = true;
      force = true;
    };
  };

  dconf.settings = {
    # Keep the workstation reachable while it is plugged in. Manual suspend
    # and hibernation remain available and will still make it unreachable.
    "org/gnome/settings-daemon/plugins/power" = {
      sleep-inactive-ac-type = "nothing";
      sleep-inactive-ac-timeout = 0;
    };

    # GNOME Desktop Sharing refuses to attach to a locked session ("Session
    # creation inhibited"), so a lock screen strands remote access until
    # someone runs `loginctl unlock-session` over SSH.
    "org/gnome/desktop/screensaver" = {
      lock-enabled = false;
    };

    "org/gnome/desktop/session" = {
      idle-delay = lib.hm.gvariant.mkUint32 0;
    };

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
        "forge@jmmaranan.com"
        "hanabi-extension@jeffshee.github.io"
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
      name = "Walker";
      binding = "<Control>p";
      command = "walker";
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
      name = "Kitty";
      binding = "<Super>Return";
      command = "kitty --single-instance";
    };

    # GNOME Extensio Settings
    "org/gnome/shell/extensions/forge" = {

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

    # Orchis-Dark's GTK4 CSS hardcodes selectors into Nautilus's internal
    # widget tree (e.g. placessidebar > scrolledwindow > viewport > row),
    # which GNOME 50's Nautilus no longer matches -- causes a misaligned
    # sidebar selection highlight. GTK4/libadwaita apps fall back to
    # stock Adwaita instead of a possibly-incompatible custom theme.
    gtk4.theme = null;
  };

  # nixpkgs ships plain `walker`/`elephant` packages but no home-manager
  # module (that only exists upstream, gated behind adding their flakes as
  # inputs). Wire up the same systemd --user services their module would
  # generate by hand instead of pulling in two more flake inputs.
  systemd.user.services.elephant = {
    Unit = {
      Description = "Elephant launcher backend";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
      ConditionEnvironment = "WAYLAND_DISPLAY";
    };
    Service = {
      ExecStart = "${pkgs.elephant}/bin/elephant";
      Restart = "on-failure";
      RestartSec = 1;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.services.walker = {
    Unit = {
      Description = "Walker - Application Runner";
      ConditionEnvironment = "WAYLAND_DISPLAY";
      After = [ "graphical-session.target" "elephant.service" ];
      Requires = [ "elephant.service" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.walker}/bin/walker --gapplication-service";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # Persistent headless opencode server, so a run started at the desk stays
  # reachable from a phone. The TUI becomes a client rather than the owner of
  # the session -- that is the part that matters: a permission prompt raised
  # mid-run is answerable from whichever client is at hand, desk or phone.
  # Start work with `oc` (alias below), not bare `opencode`.
  #
  # Bound to 0.0.0.0, with the firewall opening 4096 on tailscale0 only --
  # the same treatment 3389/3390 already get. Binding straight to the Tailscale
  # address would race tailscaled at boot.
  #
  # EnvironmentFile is deliberately NOT optional. Without
  # OPENCODE_SERVER_PASSWORD the server serves every route unauthenticated, and
  # these agents hold bash and edit tools -- so a missing password file must
  # mean "refuse to start", never "start wide open". The file is 0600 and
  # outside the Nix store, because store contents are world-readable.
  systemd.user.services.opencode-server = {
    Unit = {
      Description = "Headless opencode server (reachable over Tailscale)";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      ExecStart = "${opencodeWrapped}/bin/opencode serve --hostname 0.0.0.0 --port 4096";
      WorkingDirectory = config.home.homeDirectory;
      EnvironmentFile = "${config.home.homeDirectory}/.config/opencode-server.env";
      Restart = "always";
      RestartSec = 5;
    };
    Install.WantedBy = [ "default.target" ];
  };


  # I should be executed for writing something like this. Forgive me dear observer
# home.activation.postBuildScript = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
#   if [ ! -d "~/home_env" ]; then
#       /run/current-system/sw/bin/python -m venv home_env
#   fi
# '';

# programs.spicetify =
#   let
#     spicePkgs = inputs.spicetify-nix.packages.${pkgs.system}.default;
#   in
#   {
#     enable = true;
#     theme = spicePkgs.themes.Default;
#   };

    


}

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

  # Fixes an argument-order bug that makes programs.spicetify.xpui inert. See
  # the imports block below for why we need that option to work at all.
  #
  # Deliberately NOT the module-arg `pkgs`: this feeds `imports`, and `pkgs`
  # depends on config (nixpkgs.config.allowUnfree below), so reaching for it
  # here is an infinite recursion. `inputs` is an extraSpecialArg and carries no
  # such dependency. The bare nixpkgs instance costs nothing real - all it does
  # is rewrite one line of a Nix file.
  spicetifyPatched = inputs.nixpkgs.legacyPackages.x86_64-linux.applyPatches {
    name = "spicetify-flake-xpui-fix";
    src = inputs.spicetify-nix;
    postPatch = ''
      substituteInPlace module.nix \
        --replace-fail \
          "recursiveUpdate cfg.xpui spiceLib.types.defaultXpui" \
          "recursiveUpdate spiceLib.types.defaultXpui cfg.xpui"
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

  programs.spicetify =
    let
      spicePkgs = inputs.spicetify-nix.packages.${pkgs.system}.default;

      # Two things broke this against nixpkgs 26.05, and the module gives us
      # exactly one lever to fix both: spicetifyPackage. Its extraCommands and
      # cssMap options are declared but never passed to the builder in this
      # fork, so they are not usable as hooks.
      #
      # 1. Layout. spicetify-cli now ships bin/spicetify plus
      #    share/spicetify/{jsHelper,css-map.json}; it used to ship
      #    bin/spicetify-cli and bin/jsHelper. The builder still copies the old
      #    paths and dies on "cp: cannot stat .../bin/spicetify-cli", and it
      #    reads the css map as "${spicetify.src}/css-map.json". So the shim
      #    republishes the old bin/ layout and carries a src pointing at the
      #    directory that now holds the map.
      #
      # 2. State dir. spicetify 2.43.2 writes its backup under $XDG_STATE_HOME
      #    and no longer creates the directory, so the builder's final
      #    "spicetify-cli --no-restart backup apply" dies on the sandbox's
      #    read-only /homeless-shelter. bin/spicetify-cli is therefore a
      #    wrapper that points HOME at the build dir first. The backup itself
      #    is throwaway - only the "apply" half affects $out, and restoring is
      #    a rebuild here, not a spicetify restore.
      #
      # Upstream has not fixed either: yuu-fur/spicetify-flake HEAD is the rev
      # we already pin. Revisit if that repo moves.
      spicetifyCompat = pkgs.runCommand "spicetify-cli-compat"
        {
          passthru.src = "${pkgs.spicetify-cli}/share/spicetify";
        }
        ''
          mkdir -p $out/bin
          cat > $out/bin/spicetify-cli <<'WRAPPER'
          #!${pkgs.runtimeShell}
          export HOME="''${TMPDIR:-/tmp}/spicetify-home"
          export XDG_STATE_HOME="$HOME/.local/state"
          mkdir -p "$XDG_STATE_HOME/spicetify"
          exec ${pkgs.spicetify-cli}/share/spicetify/spicetify "$@"
          WRAPPER
          chmod +x $out/bin/spicetify-cli
          ln -s spicetify-cli $out/bin/spicetify
          cp -r ${pkgs.spicetify-cli}/share/spicetify/jsHelper $out/bin/jsHelper
        '';

      # StarryNight lives in the spicetify/spicetify-themes checkout that this
      # flake already fetches, but pkgs/themes.nix never runs mkOfficialTheme
      # on it, so there is no spicePkgs.themes.StarryNight to use. The fetched
      # source is still reachable through any theme that does come from that
      # repo, so borrow it from one and hand-roll the same attrset shape
      # mkOfficialTheme would have produced.
      #
      # theme.js (the shooting-star animation) is not an extension here: the
      # builder copies the whole theme folder, and spicetify's inject_theme_js
      # picks up Themes/StarryNight/theme.js on its own. Listing it under
      # requiredExtensions as well would load it twice.
      officialThemes = spicePkgs.themes.Sleek.src;

      starryNight = {
        name = "StarryNight";
        src = officialThemes;
        appendName = true;
        injectCss = true;
        replaceColors = true;
        overwriteAssets = false;
        sidebarConfig = false;
      };
    in
    {
      enable = true;
      spicetifyPackage = spicetifyCompat;
      enabledExtensions = with spicePkgs.extensions; [
        adblock
        hidePodcasts
        shuffle # shuffle+ (special characters are sanitized out of extension names)
      ];
      xpui.AdditionalOptions.sidebar_config = false;
      enabledCustomApps = with spicePkgs.apps; [ marketplace ];
      theme = starryNight;
      # color.ini sections: Base, Cotton-candy, Forest, Galaxy, Orange, Sky,
      # Sunrise.
      colorScheme = "Base";
    };

  imports = [
    # Spotify pops a snackbar on every launch: "Sidebar config is not supported
    # when Global Navbar is enabled. In your terminal, please run spicetify
    # config sidebar_config 0". It comes from helper/sidebarConfig.js, which
    # spicetify injects into Apps/xpui/index.html whenever
    # [AdditionalOptions]/sidebar_config is 1. Two bugs in this fork conspire to
    # pin it there:
    #
    # 1. A theme's sidebarConfig is written to [Setting]/sidebar_config, but
    #    spicetify reads [AdditionalOptions]/sidebar_config. So the theme has no
    #    say, and the generated ini carries both keys with opposite values.
    #
    # 2. The [AdditionalOptions] copy comes from cfg.xpui, which module.nix
    #    computes as `recursiveUpdate cfg.xpui defaultXpui`. recursiveUpdate
    #    lets its RIGHT argument win, so the defaults clobber everything the
    #    user sets and the whole xpui option does nothing.
    #
    # Patching (2) is the smaller fix and makes xpui behave as documented, which
    # then lets us set sidebar_config directly. The swap is otherwise a no-op:
    # cfg.xpui's own defaults are defaultXpui, so unset keys resolve the same.
    ((import "${spicetifyPatched}/module.nix") { isNixOSModule = false; })
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
    gnomeExtensions.clipboard-history
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
    # spotify comes from programs.spicetify (the spiced build already
    # provides bin/spotify); listing it here too collides in buildEnv.
    thunderbird
    mailspring
    pear-desktop
    git
    lazygit
    tree-sitter
    curl
    ripgrep
    fd
    gcc
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

    # LSP servers (declared here so LazyVim uses PATH executables instead of
    # Mason downloading duplicates).
    bash-language-server
    llvmPackages.clang-tools
    pyright
    lua-language-server
    nil
    vscode-langservers-extracted
    yaml-language-server
    marksman
    zoxide
    reptyr
    pi-coding-agent
    crush
    # pi shells out to npm to install its packages (tellico-agentic-setup's
    # pi-tellico needs it for Magic Context), and that repo's tests run on node.
    nodejs
    webex
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

    # config.json is generated rather than symlinked from ./input-remapper-2.
    # input-remapper runs its migration on *every* invocation, and the last
    # step rewrites config.json to stamp the running version -- which dies
    # with EROFS when the file is a read-only store symlink, taking the whole
    # autoload command with it. Emitting the running version here makes the
    # `v < VERSION` guard false, so the migration becomes a permanent no-op
    # and never attempts the write. Reading the version off the package
    # itself means a future input-remapper bump can't quietly bring the
    # breakage back, the way a hardcoded "2.2.0" would.
    ".config/input-remapper-2/config.json".text = builtins.toJSON {
      version = pkgs.input-remapper.version;
      autoload = {
        # Keys are input-remapper *group* keys -- the shortest evdev name of
        # the device. Entries for absent devices are simply never matched.
        "USB OPTICAL MOUSE " = "Mouse Volume";
        "LIFT Mouse" = "Mouse Volume";
      };
    };

    ".config/input-remapper-2/presets" = {
      source = ./input-remapper-2/presets;
      recursive = true;
    };

    ".config/input-remapper-2/xmodmap.json".source = ./input-remapper-2/xmodmap.json;

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

    ".config/nvim" = {
      source = ./nvim;
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
        "clipboard-history@alexsaveau.dev"
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
  # The root daemon comes up with config_dir = None: daemon.py only calls
  # set_config_dir for a non-root user, and as a systemd service it is root.
  # Until some *session* process hands it a config dir it refuses every
  # autoload. The udev rules cannot do it either -- they fire as root, and
  # input_remapper_control.py skips set_config_dir for root. So the udev half
  # alone maps nothing after a reboot; this is the other half. It points the
  # daemon at this user's config once per login and loads whatever is already
  # connected, after which udev can handle the mouse coming and going.
  #
  # Upstream ships exactly this as an XDG autostart .desktop, which the NixOS
  # module does not install -- hence doing it as a user unit here.
  systemd.user.services.input-remapper-autoload = {
    Unit = {
      Description = "Autoload input-remapper presets for this session";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      # Mirrors upstream's `stop-all && autoload`; the stop clears injections
      # left by a previous session and is allowed to fail on a clean boot.
      ExecStartPre = "-${pkgs.input-remapper}/bin/input-remapper-control --command stop-all";
      ExecStart = "${pkgs.input-remapper}/bin/input-remapper-control --command autoload";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

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



}

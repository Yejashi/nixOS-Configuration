{
  description = "A simple NixOS flake";

  inputs = {
    # NixOS official package source, using the nixos-26.05 branch
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # Used only for a handful of fast-moving packages (see the overlay below),
    # so the rest of the system stays on the stable release.
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # OpenCode 2 comes from upstream's own flake: nixpkgs only packages the 1.x
    # line. Pinned to a release tag rather than the dev branch, which moves
    # several times a day. Bump the tag to upgrade.
    opencode.url = "github:anomalyco/opencode/v2.0.26";

    # Hermes Agent (CLI + Electron desktop) from Nous Research's own flake;
    # not in nixpkgs. Pinned to a release tag, same reasoning as opencode.
    # Its nixpkgs is left alone: the package is built against the uv2nix lock
    # upstream tests with, and following ours would just invite breakage.
    hermes-agent.url = "github:NousResearch/hermes-agent/v2026.9.24";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    spicetify-nix = {
      url = "github:yuu-fur/spicetify-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser.url = "github:0xc000022070/zen-browser-flake";

    hanabi = {
      url = "github:jeffshee/gnome-ext-hanabi";
      flake = false;
    };

    # Declarative KDE Plasma settings (theme, panel, shortcuts) for home-manager.
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # Plastile, the KWin tiling script. `nix flake update plastile` to bump.
    plastile = {
      url = "github:Yejashi/plastile";
      flake = false;
    };

  };

  outputs = { self, nixpkgs, nixpkgs-unstable, opencode, home-manager, ... }@inputs:
    let
      system = "x86_64-linux";

      # Packages that move faster than the stable release can keep up with.
      unstableOverlay = final: prev:
        let
          unstable = import nixpkgs-unstable {
            inherit system;
            config = prev.config;
          };
        in
        {
          # OpenCode 2 from upstream: see the opencode input above.
          opencode = opencode.packages.${system}.default;

          # Stable's llama-cpp is built CPU-only (GGML_VULKAN=FALSE) and is
          # ~1400 commits behind, missing flags this host's config relies on
          # (--spec-type draft-mtp, --fit, --load-mode). The RX 6750 XT has
          # no ROCm support in nixpkgs, so Vulkan is the only GPU backend.
          llama-cpp-vulkan = unstable.llama-cpp-vulkan;

          # Stable's T3 Code is 0.0.24 and this is a fast-moving 0.0.x app;
          # its OpenCode provider is what reaches the tellico models.
          # Electron leaf, nothing links against it.
          #
          # The package sets dontPatchELF, so node-pty's vendored prebuilt has
          # no way to find libstdc++. The backend dies on startup when it fails
          # to load, and the app never opens a window. RPATH rather than
          # LD_LIBRARY_PATH on the wrapper, which would leak into every agent
          # and terminal T3 Code spawns. Drop this once nixpkgs patches it.
          t3code = unstable.t3code.override {
            t3code-unwrapped = unstable.t3code.unwrapped.overrideAttrs (old: {
              postFixup = (old.postFixup or "") + ''
                find "$out"/libexec/t3code -type f \
                  -path '*/node-pty/prebuilds/linux-x64/pty.node' \
                  -exec patchelf --add-rpath ${unstable.lib.makeLibraryPath [ unstable.stdenv.cc.cc.lib ]} {} +
              '';
            });
          };

          # Panel Colorizer plasmoid (compiled plugin, loaded by plasmashell)
          # must match the unstable Plasma in plasmaOverlay. It lives here,
          # not there, because plasma-manager adds it to home.packages from
          # home-manager's pkgs whenever a panel uses the widget. It is a
          # leaf, so nothing stable links against its unstable libraries.
          plasma-panel-colorizer = unstable.plasma-panel-colorizer;

          # The 2026-10-07 nixpkgs bump moved this from 2025-02-10 to
          # 2026-07-07, and that release ships three symlinks pointing at icon
          # names the tarball no longer contains (xsi-addon-symbolic,
          # org.xfce.appfinder, and the -dark copy of the first). The
          # noBrokenSymlinks hook makes those a build failure, which breaks
          # both this package and anything pulling it in -- here, systemPackages
          # and gtk.iconTheme. The dangling entries are icons for apps this
          # host does not install, so GTK never looks them up; skipping the
          # check keeps the theme on the current release instead of pinning it
          # back. Drop this once upstream prunes the stale links.
          tela-circle-icon-theme = prev.tela-circle-icon-theme.overrideAttrs {
            dontCheckForBrokenSymlinks = true;
          };

          gnome-ext-hanabi = prev.callPackage ../users/yejashi/pkgs/hanabi.nix { src = inputs.hanabi; };
        };

      # Plasma 6.7 from unstable: stable ships KWin 6.6, and Plastile needs
      # KWin >= 6.7. Same Qt (6.11) on both branches. This moves the whole KDE
      # stack (frameworks, Plasma, KDE apps); GNOME is untouched.
      #
      # System only, not home-manager: unstable's KDE libraries need its newer
      # glibc, so any stable package built against them (LibreOffice's Qt
      # backend, for one) would be rebuilt from source and fail to link.
      plasmaOverlay = final: prev:
        let
          unstable = import nixpkgs-unstable {
            inherit system;
            config = prev.config;
          };
        in
        {
          kdePackages = unstable.kdePackages;
          # Compiled KWin effect: must match the KWin above.
          kde-rounded-corners = unstable.kde-rounded-corners;
          # Window decoration + Qt style plugins loaded by KWin and Qt apps:
          # same reason.
          klassy = unstable.klassy;
          darkly = unstable.darkly;
          # Built with unstable's toolchain for the same glibc reason.
          plastile = unstable.callPackage ../users/yejashi/pkgs/plastile.nix { src = inputs.plastile; };
        };
    in
    {
      nixosConfigurations.yejashi = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./configuration.nix
          { nixpkgs.overlays = [ unstableOverlay plasmaOverlay ]; }
        ];
      };

      homeConfigurations.yejashi = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ unstableOverlay ];
        };
        extraSpecialArgs = { inherit inputs; };
        modules = [ ../users/yejashi/home.nix ];
      };

    };
}

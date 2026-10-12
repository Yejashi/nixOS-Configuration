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
    in
    {
      nixosConfigurations.yejashi = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./configuration.nix
          { nixpkgs.overlays = [ unstableOverlay ]; }
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

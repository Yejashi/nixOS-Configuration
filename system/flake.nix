{
  description = "A simple NixOS flake";

  inputs = {
    # NixOS official package source, using the nixos-26.05 branch
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # Used only for a handful of fast-moving packages (see the overlay below),
    # so the rest of the system stays on the stable release.
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # Pinned to the last nixpkgs-unstable revision whose opencode build works.
    # Upstream republished the 1.18.30 artifact with a regression: every prompt
    # dies in SystemPrompt.environment with "undefined is not an object
    # (evaluating 'a.name')" because a built-in reference entry has no name
    # (anomalyco/opencode#48811, fix in PR #49025). The version string is still
    # 1.18.30, so only the pin distinguishes the good build from the bad one.
    # Drop this input and go back to unstable.opencode once a release carrying
    # that fix lands in nixpkgs.
    nixpkgs-opencode.url = "github:NixOS/nixpkgs/aff8a0b28396750446e5537a96461bc4facdb287";

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

  outputs = { self, nixpkgs, nixpkgs-unstable, nixpkgs-opencode, home-manager, ... }@inputs:
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
          # Pinned, not from unstable: see the nixpkgs-opencode input above.
          opencode = (import nixpkgs-opencode {
            inherit system;
            config = prev.config;
          }).opencode;

          # Stable's llama-cpp is built CPU-only (GGML_VULKAN=FALSE) and is
          # ~1400 commits behind, missing flags this host's config relies on
          # (--spec-type draft-mtp, --fit, --load-mode). The RX 6750 XT has
          # no ROCm support in nixpkgs, so Vulkan is the only GPU backend.
          llama-cpp-vulkan = unstable.llama-cpp-vulkan;

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

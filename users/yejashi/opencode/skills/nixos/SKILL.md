---
name: nixos
description: Work safely and declaratively on this NixOS and Home Manager configuration. Use for Nix, NixOS, Home Manager, flakes, packages, services, desktop settings, OpenCode configuration, rebuilds, and system configuration changes.
compatibility: opencode
metadata:
  platform: nixos
  configuration: home-manager
---

# NixOS configuration workflow

Use this skill whenever the task changes or diagnoses this NixOS configuration.

## Repository layout

This repository is a flake-based NixOS configuration.

- `system/flake.nix` defines the flake inputs and the `nixosConfigurations.yejashi` and `homeConfigurations.yejashi` outputs.
- `system/configuration.nix` contains machine/system-level NixOS configuration.
- `users/yejashi/home.nix` contains user-level Home Manager configuration.
- `users/yejashi/opencode/` is recursively installed to `~/.config/opencode` by Home Manager.
- The NixOS host/configuration name is `yejashi`.
- The Home Manager configuration name is `yejashi`.

## Core rules

1. Prefer declarative changes in this repository over imperative fixes.
2. Do not use `nix-env -i`, `nix profile install`, manual edits under `/etc`, or ad-hoc files in `~/.config` when the equivalent can be represented in Nix/Home Manager.
3. Put system-wide packages, services, kernel/driver settings, networking, boot, and hardware configuration in the NixOS configuration.
4. Put user applications, dotfiles, session variables, user services, and desktop preferences in Home Manager unless they genuinely require system scope.
5. Preserve the existing stable/unstable package split. Do not move packages to unstable without a concrete reason.
6. Make the smallest change that solves the requested problem. Avoid unrelated formatting or refactors.
7. Never silently change `home.stateVersion` or the NixOS `system.stateVersion`.
8. Do not modify generated files or the Nix store.

## Before editing

Inspect the relevant Nix file and nearby patterns before proposing a change. Check whether the setting is already managed elsewhere to avoid duplicate declarations.

For OpenCode changes, inspect both:

- `users/yejashi/opencode/opencode.json`
- `users/yejashi/home.nix`

Remember that the whole `users/yejashi/opencode` directory is already deployed recursively to `~/.config/opencode`.

## Editing guidance

Follow the style already present in the repository.

- Use existing package names and module options when possible.
- Prefer module options over shell activation hooks.
- Prefer `systemd.user.services` for persistent user daemons.
- Prefer `home.file` for managed user configuration files.
- When a file tree is already recursively linked by Home Manager, add files inside that source tree instead of creating redundant individual `home.file` entries.
- Keep comments focused on why a non-obvious choice exists.

When an option or package name is uncertain, verify it rather than guessing.

## Validation

After edits, use the narrowest useful validation first.

From the repository root, the flake lives in `system/`. Appropriate checks include:

```bash
nix flake check ./system
nix eval ./system#nixosConfigurations.yejashi.config.system.build.toplevel.drvPath
nix eval ./system#homeConfigurations.yejashi.activationPackage.drvPath
```

For a full NixOS build without activating it:

```bash
sudo nixos-rebuild build --flake ./system#yejashi
```

For activation, only run this when the user actually wants the live system changed:

```bash
sudo nixos-rebuild switch --flake ./system#yejashi
```

If the change is Home Manager-only and Home Manager is available separately, a Home Manager build/switch may be sufficient. Do not perform both a Home Manager switch and a NixOS switch unless there is a reason.

## Failure handling

If evaluation or rebuild fails:

1. Report the first meaningful Nix error, not the entire log.
2. Identify the exact option, package, path, or syntax responsible.
3. Fix only that issue.
4. Re-run the failed validation.
5. Do not work around a declarative configuration error with an imperative system mutation.

## Completion report

Summarize:

- files changed,
- what behavior changed,
- validation performed and its result,
- whether a rebuild/switch is still required.

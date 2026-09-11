---
name: nixos
description: Operate the Yejashi/nixOS-Configuration repository correctly: find Nix packages and module options, edit NixOS vs Home Manager at the right scope, work with this repo's flakes and stable/unstable overlay, evaluate and build changes, update flake inputs safely, diagnose Nix errors, and apply configuration changes.
compatibility: opencode
metadata:
  repository: Yejashi/nixOS-Configuration
  host: yejashi
  platform: NixOS
---

# NixOS operator skill for this repository

Treat this repository as the source of truth. Persistent machine or user configuration belongs in Nix, not in ad-hoc imperative changes.

## 1. How NixOS works

Nix evaluates expressions into derivations and immutable paths under `/nix/store`. NixOS and Home Manager build generations from those declarations. Packages are derivations such as `pkgs.firefox`; adding one to a package list makes it part of that generation.

This repo uses two separate module systems:

- **NixOS**: boot, kernel, hardware, networking, system services, firewall, users, system packages.
- **Home Manager**: user packages, dotfiles, `~/.config`, dconf, user services, shells, OpenCode.

A module normally looks like:

```nix
{ config, pkgs, lib, inputs, ... }:
{
  services.foo.enable = true;
}
```

The module system merges option definitions across imported modules. Do not edit `/nix/store`; it is immutable.

## 2. Exact repository layout

The Git repository root is **not** the flake root. The flake is under `system/`.

- `system/flake.nix` — inputs, overlays, NixOS and Home Manager outputs.
- `system/flake.lock` — exact pinned revisions.
- `system/configuration.nix` — host-level NixOS configuration.
- `system/hardware-configuration.nix` — hardware/filesystem declarations; do not casually rewrite it.
- `users/yejashi/home.nix` — standalone Home Manager configuration.
- `users/yejashi/opencode/` — recursively deployed to `~/.config/opencode`.
- `users/yejashi/opencode/opencode.json` — OpenCode configuration.
- `users/yejashi/opencode/skills/` — global OpenCode skills after Home Manager activation.

Flake outputs:

```text
nixosConfigurations.yejashi
homeConfigurations.yejashi
```

Target platform: `x86_64-linux`.

### Critical activation fact

Home Manager is a **standalone flake output** here. It is not imported into `nixosConfigurations.yejashi`.

Therefore:

- NixOS-only change -> build/switch NixOS.
- Home Manager-only change -> build/switch Home Manager.
- Both changed -> validate and activate both separately.

A successful `nixos-rebuild switch` does **not** apply `users/yejashi/home.nix`.

## 3. Flake inputs and stable/unstable policy

Current `system/flake.nix` uses:

- `nixpkgs` -> `nixos-26.05`
- `nixpkgs-unstable` -> `nixpkgs-unstable`
- `home-manager` -> `release-26.05`, following stable `nixpkgs`
- `spicetify-nix`
- `zen-browser`

The machine intentionally stays on stable NixOS while selected fast-moving packages come from unstable.

The existing overlay imports unstable and currently overrides:

```nix
{
  opencode = unstable.opencode;
}
```

That overlay is supplied to both the NixOS and Home Manager package sets, so `pkgs.opencode` resolves to unstable in both.

Use stable by default. If one package genuinely needs unstable, extend the existing whitelist-style overlay:

```nix
{
  opencode = unstable.opencode;
  somePackage = unstable.somePackage;
}
```

Do not switch the entire system or Home Manager package set to unstable to obtain one package.

## 4. Decide the correct scope before editing

### NixOS: `system/configuration.nix`

Use for:

- bootloader, kernel, initrd;
- GPU/kernel drivers and firmware;
- filesystems and hardware;
- NetworkManager, DNS, routing, firewall;
- system daemons and `services.*`;
- Tailscale, SSH, printing, Bluetooth, PipeWire;
- system users/groups and security;
- system-wide packages required by system services.

### Home Manager: `users/yejashi/home.nix`

Use for:

- ordinary user applications;
- user CLI tools;
- `~/.config/*`, shell/editor config;
- GNOME dconf settings;
- user-level systemd services;
- OpenCode, Kitty, Ranger, Variety, etc.

Prefer `home.packages` for normal user-facing software. Do not use `environment.systemPackages` merely because the user wants to run a program.

### OpenCode

Home Manager already declares:

```nix
".config/opencode" = {
  source = ./opencode;
  recursive = true;
  force = true;
};
```

Therefore edit files under `users/yejashi/opencode/`. Do not create redundant individual `home.file` entries for files already inside that tree.

## 5. Finding packages correctly

Do not guess package attributes. Program names, executable names, project names, and nixpkgs attributes often differ.

### Search stable first

Match the release declared by this flake:

```bash
nix search github:NixOS/nixpkgs/nixos-26.05 '<term>'
```

Examples:

```bash
nix search github:NixOS/nixpkgs/nixos-26.05 'ripgrep'
nix search github:NixOS/nixpkgs/nixos-26.05 'language server'
```

For a package that may need unstable:

```bash
nix search github:NixOS/nixpkgs/nixpkgs-unstable '<term>'
```

`nix search nixpkgs <term>` is fine for quick exploration, but the local flake registry can point at a different nixpkgs revision. Never treat that alone as proof that an attribute exists in this configuration.

Online package search:

`https://search.nixos.org/packages`

Use the matching release when possible.

### Verify the candidate against this actual flake

NixOS package set:

```bash
nix eval --raw './system#nixosConfigurations.yejashi.pkgs.<attribute>.name'
```

Example:

```bash
nix eval --raw './system#nixosConfigurations.yejashi.pkgs.ripgrep.name'
```

Home Manager package set:

```bash
nix eval --raw './system#homeConfigurations.yejashi.pkgs.<attribute>.name'
```

If the attribute is missing, search again. Do not guess package variants until one evaluates.

### If only an executable name is known

`nix-index` is installed. If its database is available:

```bash
nix-locate --whole-name 'bin/<binary>'
```

Use that to find candidate packages, then verify the package attribute through this flake.

## 6. Finding NixOS and Home Manager options

Packages and module options are different. For a service/configuration task, check whether a module already exists before merely installing the package.

### NixOS options

Search:

- `https://search.nixos.org/options`
- `man configuration.nix`
- NixOS manual/module source if needed.

Verify a candidate option exists in this exact evaluation:

```bash
nix eval --raw './system#nixosConfigurations.yejashi.options.<option.path>.description'
```

Example:

```bash
nix eval --raw './system#nixosConfigurations.yejashi.options.services.openssh.enable.description'
```

Inspect its current evaluated value:

```bash
nix eval --json './system#nixosConfigurations.yejashi.config.<option.path>'
```

Example:

```bash
nix eval --json './system#nixosConfigurations.yejashi.config.services.openssh.enable'
```

### Home Manager options

Search:

`https://home-manager-options.extranix.com/`

Then verify against the actual Home Manager output:

```bash
nix eval --raw './system#homeConfigurations.yejashi.options.<option.path>.description'
```

Inspect its current value:

```bash
nix eval --json './system#homeConfigurations.yejashi.config.<option.path>'
```

Never assume an option exists in both NixOS and Home Manager.

## 7. Prefer modules over hand-written services

If NixOS or Home Manager provides a module, use it.

Prefer:

```nix
services.foo = {
  enable = true;
  settings = { ... };
};
```

over installing `foo` and hand-writing a systemd unit.

Use custom `systemd.services` or `systemd.user.services` only when no suitable module exists or the requested behavior is custom.

- Machine daemon -> NixOS `services.*` or `systemd.services`.
- User daemon -> Home Manager `systemd.user.services`.

## 8. Nix syntax and module semantics that matter

### Attribute sets

```nix
{
  foo = "bar";
  nested.value = true;
}
```

Bindings end in semicolons.

### Lists

```nix
home.packages = with pkgs; [
  ripgrep
  fd
  jq
];
```

List elements do not use commas.

### Strings

Nix interpolation:

```nix
"${pkgs.git}/bin/git"
```

Indented multi-line string:

```nix
''
  command here
''
```

When a shell variable inside an indented Nix string must be expanded by the shell rather than Nix, escape it:

```nix
''${HOME}
```

### `with pkgs;`

Inside:

```nix
home.packages = with pkgs; [ ripgrep ];
```

`ripgrep` means `pkgs.ripgrep`.

### Module merging

Different modules can define the same module option when its type supports merging. This does not make duplicate literal attribute definitions valid everywhere.

Use intentionally:

- `lib.mkIf condition value` — conditional module fragment.
- `lib.mkMerge [ ... ]` — merge module fragments.
- `lib.mkDefault value` — lower-priority default.
- `lib.mkForce value` — force an override only after identifying a real conflict.

Do not use `mkForce` as a generic error suppressor.

## 9. Flake mechanics

A flake has **inputs** and **outputs**.

Inputs are external dependencies pinned in `system/flake.lock`.
Outputs expose buildable/evaluable configurations.

NixOS gets:

```nix
specialArgs = { inherit inputs; };
```

Home Manager gets:

```nix
extraSpecialArgs = { inherit inputs; };
```

That is why modules in this repo can accept `inputs` as an argument.

### Inspect before inventing output names

```bash
nix flake show ./system
nix flake metadata ./system
```

### Add a new input without refreshing everything

Edit `system/flake.nix`, then:

```bash
nix flake lock ./system
```

This adds missing lock entries without intentionally updating unrelated existing inputs. Inspect the `system/flake.lock` diff.

### Update one existing input intentionally

```bash
nix flake update <input-name> --flake ./system
```

Examples:

```bash
nix flake update nixpkgs --flake ./system
nix flake update nixpkgs-unstable --flake ./system
```

Do not run an all-input `nix flake update --flake ./system` unless the user explicitly wants all dependencies refreshed.

## 10. Validation: evaluate, then build, then activate

Never activate first.

### NixOS evaluation

```bash
nix eval './system#nixosConfigurations.yejashi.config.system.build.toplevel.drvPath' --raw
```

### Home Manager evaluation

```bash
nix eval './system#homeConfigurations.yejashi.activationPackage.drvPath' --raw
```

### General flake check

```bash
nix flake check ./system
```

If the short error is insufficient:

```bash
nix flake check ./system --show-trace
```

Do not start with `--show-trace`; it is noisy.

### Build without activation

NixOS:

```bash
nix build --no-link './system#nixosConfigurations.yejashi.config.system.build.toplevel'
```

Home Manager:

```bash
nix build --no-link './system#homeConfigurations.yejashi.activationPackage'
```

Evaluation catches syntax/module resolution errors. A full build also validates package realization and generated configuration more strongly.

## 11. Activation commands

Run from the Git repository root.

### NixOS

```bash
sudo nixos-rebuild switch --flake ./system#yejashi
```

Non-activating rebuild:

```bash
sudo nixos-rebuild build --flake ./system#yejashi
```

### Home Manager

```bash
home-manager switch --flake ./system#yejashi
```

If both NixOS and Home Manager changed, validate both and activate both separately.

Never claim a Home Manager change is live because only `nixos-rebuild switch` succeeded.

## 12. Common workflows

### Install program X

1. Decide user scope vs system scope.
2. Search stable 26.05.
3. Verify the exact attribute through this flake.
4. Prefer `home.packages` for ordinary user software.
5. Use `environment.systemPackages` only when system scope is justified.
6. If stable is insufficient, verify unstable and whitelist only that package in the existing overlay.
7. Evaluate and build the affected output.

### Enable/configure service X

1. Search for a NixOS/Home Manager module first.
2. Verify the candidate option through the relevant `.options` output.
3. Inspect the current evaluated value if relevant.
4. Configure the module.
5. Change firewall, groups, ports, or security only when actually required.
6. Build before activation.

### Change a dotfile or OpenCode setting

1. Check whether `home.nix` already recursively manages the containing directory.
2. Edit the repository source, not the live file under `~/.config`.
3. Build `homeConfigurations.yejashi.activationPackage`.
4. Apply with `home-manager switch --flake ./system#yejashi`.

### Use a newer package

1. Determine whether stable satisfies the requirement.
2. Check unstable only if it does not.
3. Extend the existing selective unstable overlay.
4. Do not change the whole `nixpkgs` input to unstable.
5. Evaluate and build.

### Add an external flake

1. Confirm nixpkgs does not already provide the needed package/module.
2. Add a narrow input in `system/flake.nix`.
3. When appropriate, make its nixpkgs input follow this repo's nixpkgs to avoid duplicate dependency graphs.
4. Wire its package/module explicitly.
5. Run `nix flake lock ./system`.
6. Inspect the lockfile diff.
7. Evaluate/build the affected output.

## 13. Diagnosing common failures

### Parser/syntax error

Look for missing semicolons, malformed strings, braces, or list syntax. Fix the smallest issue and re-evaluate.

### `attribute '<name>' missing`

Usually a wrong package/output attribute or package-set mismatch. Search and verify it. Do not work around it with `nix profile install` or `nix-env -i`.

### `The option '<path>' does not exist`

The option may:

- be misspelled;
- belong to Home Manager instead of NixOS or vice versa;
- require another module import;
- have changed between releases.

Search the correct option set and verify it against `.options`.

### Infinite recursion

Usually an overlay/module is referring to itself through the wrong package set or configuration depends recursively on itself.

For the overlay:

- `final` = final package set after overlays;
- `prev` = package set before this overlay;
- `unstable` = separately imported unstable package set.

Do not try to cure recursion with arbitrary `mkForce`.

### Conflicting definitions

Find every declaration first. Decide which should own the value. Use `mkDefault`/`mkForce` only when the priority semantics are intentional.

### Package build failure

Distinguish a broken package derivation from a Nix configuration error. Read the first relevant failing derivation/log. A stable package being broken while unstable is fixed can justify a selective unstable override.

## 14. OpenCode worker roles for Nix tasks

The orchestrator knows this skill but intentionally does not edit files or execute arbitrary shell itself.

Use:

- **explore** — locate/read relevant repository declarations and answer narrow source questions;
- **tester** — run read-only shell inspection, Nix search/eval/build, diagnostics, and Git diff/status;
- **implementer** — edit already-identified files; it cannot broadly search or run shell commands;
- **operator** — run exact state-changing shell commands such as activation, rebuild, Git staging/commit/push.

Typical sequence:

1. Explore the relevant existing configuration.
2. If package/option identity is uncertain, use tester for discovery and exact flake verification.
3. Give implementer exact file paths and edits.
4. Use tester to evaluate/build and inspect the diff.
5. Use operator only for state-changing commands the user requested.

Never ask implementer to "find the right file."
Never ask operator to improvise after a failure.

## 15. Machine-specific guardrails

- Keep `system.stateVersion = "24.11"` unless explicitly performing a state-version migration.
- Keep `home.stateVersion = "24.11"` for the same reason.
- Keep stable `nixos-26.05` as the base unless explicitly performing a NixOS release migration.
- Do not casually rewrite `hardware-configuration.nix`.
- Preserve the selective unstable policy.
- Do not disable the firewall or weaken SSH merely to make a service work.
- The active graphics stack is AMD; do not resurrect the commented NVIDIA configuration without a real hardware change.
- Tailscale uses `--accept-dns=false`; DNS/network changes must account for that policy.
- This machine is deliberately configured to remain reachable remotely instead of automatically suspending while plugged in or at the login screen. Do not undo that incidentally.


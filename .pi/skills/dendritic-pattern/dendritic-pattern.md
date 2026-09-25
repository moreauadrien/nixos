# The Dendritic Pattern (NixOS flake structure)

Reference repos studied:
- https://git.voidarc.co.uk/voidarc/nixos (voidarc)
- https://github.com/vimjoyer/nixconf (vimjoyer)

"Dendritic" (tree-shaped) = one flake where **every `.nix` file is auto-imported as a
flake-parts module**, and each file contributes to whatever part of the flake it owns
(nixosModules, nixosConfigurations, packages, diskoConfigurations...). There is no
central file listing modules: the tree grows by adding files, never by editing a hub.

### The philosophy (from voidarc's README)

Beyond the file layout, the point of the pattern is **dependency closure**: a config
module wraps the binaries it references, so config and binaries are intrinsically
linked. Like Rust's mandatory parameters (no optional ones), nothing can be missing:
no dotfile manager, no app assumed installed, no orphaned config file. A host that
imports `nixosModules.hyprland` *always* gets hyprland, its config, and its
dependencies — forgetting one cannot brick the setup.

Corollary: every feature is also a standalone runnable binary
(`nix run .#appname`, or from a remote git URL) since each `features/<app>` exposes
its wrapped binary in `perSystem.packages`. One repo = reproducible systems AND
directly runnable, fully-versioned apps.

## Core ingredients

1. **flake-parts** — the framework. `outputs` is a single call to
   `mkFlake`, everything else lives in imported files.
2. **import-tree** (or a `lib.fileset` filter, as vimjoyer does) — recursively
   imports every `.nix` file under `./modules` (vimjoyer skips files prefixed `_`).
3. **`flake.nixosModules.<name>`** — each feature/system file exports itself as a
   named nixos module in the flake output. Hosts and profiles pull them in by name.

## Canonical root flake (minimal)

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
  };
  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } {
    systems = [ "x86_64-linux" ];
    imports = [ (inputs.import-tree ./modules) ];
  };
}
```

vimjoyer variant: no `import-tree` input, a small `importTree` helper with
`lib.fileset.toList (fileFilter ...)` instead — identical effect, zero extra input.

## Directory layout (voidarc, the richest example)

```
modules/
├── parts.nix              # shared flake-parts config (systems list, overlays)
├── features/<app>/        # one dir per optional app/service
│   └── default.nix        # flake.nixosModules.hyprland, steam, zsh, ...
├── attrs/<profile>/       # profiles = bundles of features ("branch" of the tree)
│   ├── gaming/default.nix # imports steam, adds prismlauncher
│   └── development/...    # imported only by hosts that want it
├── system/<area>/         # always-on system concerns, no binaries,
│   │                      # NOT meant to run standalone (README wording)
│   ├── core/              # always-on base (user, locale, network, nix, boot)
│   ├── network/ audio/ drivers/ systemTheme/
├── hosts/<host>/
│   ├── default.nix        # flake.nixosConfigurations.<host> = nixosSystem {...}
│   └── <host>Configuration.nix  # host-specific config as a nixosModule
└── attrs/…                # vimjoyer calls the profile layer "features/"
```

Each feature ships its own config, colocated with its module (no central
`dotfiles/`): `modules/features/alacritty.nix` + `modules/features/alacritty/config/`,
referenced via relative paths (`hjem.users.<user>.files."…".source = ./config`).

On `system/` vs `attrs/`: the README says `system/` should not be run standalone and
reserves `attrs/` for bundles — so a pure profile bundle arguably belongs in
`attrs/`. voidarc in practice puts its `desktop` profile in `system/`; this repo
does the same (see `modules/system/desktop.nix`). Move to `attrs/` if bundles ever
proliferate.

## Key mechanics

### Every file is a flake-parts module

```nix
# modules/features/zsh/default.nix
{
  flake.nixosModules.zsh = { pkgs, ... }: {
    programs.zsh.enable = true;
  };
  # the same file can ALSO contribute perSystem packages, overlays, etc.
  perSystem.packages.myPkg = ...;
}
```

No file is imported manually; add a file → it exists. A file may define several
outputs at once (a nixosModule + packages + disko config).

### Composition via `imports` of sibling modules

Features depend on other features by listing them, not by importing paths:

```nix
# modules/attrs/gaming/default.nix
{
  flake.nixosModules.gaming = { pkgs, ... }: {
    imports = with self.nixosModules; [ steam ];
    environment.systemPackages = [ pkgs.prismlauncher ];
  };
}
```

`attrs/` (profiles) are just modules whose only job is to bundle other modules —
this is the "branch" of the tree. Hosts pick profiles; profiles pick features;
features implement options.

### Hosts are one small file

```nix
# modules/hosts/HACKSTATION/default.nix
{ self, inputs, ... }: {
  flake.nixosConfigurations.HACKSTATION = inputs.nixpkgs.lib.nixosSystem {
    modules = with self.nixosModules; [
      core              # always-on base (boot, user, locale, nix)
      desktop
      gaming
      hackstationConfiguration   # machine-specific bits, also a nixosModule
    ];
  };
}
```

The host file only *selects* modules. All logic lives in shared feature modules —
that's what keeps hosts cheap: a second host reuses 90% of the list.

### Crossing the perSystem/system boundary: `moduleWithSystem`

To give a nixosModule access to `self'`/`inputs'`/`perSystem` packages (wrapped
apps, custom builds):

```nix
{
  moduleWithSystem,
  ...
}: {
  flake.nixosModules.hyprland = moduleWithSystem ({ self', pkgs, ... }: {
    config.programs.hyprland.package = self'.packages.hyprland;
  });
  perSystem.packages.hyprland = ...;
}
```

### Module naming convention (voidarc)

A module is a **directory with a `default.nix`**, and the module name equals the
directory name (`features/kitty/default.nix` → `flake.nixosModules.kitty`, and
`nix run .#kitty`). Files with other names don't follow this convention.

This repo deviates on purpose: flat file per feature (`git.nix`) when a feature fits
in one file, directory only when it holds several. Same idea, less nesting.

### Host build specifics (from voidarc)

- Hosts reference `/etc/nixos/hardware-configuration.nix` (kept out of the repo) →
  all rebuilds need `--impure`.
- **No default nixosConfigurations output**: `nixos-rebuild --flake .` only works if
  the current hostname matches a host folder; otherwise evaluation errors.

### Shared defaults via options

`base` modules declare options (`preferences.monitors`, `preferences.keymap` in
vimjoyer) that feature modules read — decoupling hosts from feature internals.
Hosts set the option, any feature can consume it.

## Current state of /nixos-next

Already dendritic: `flake.nix` is minimal (`flake-parts` + `import-tree`), hjem for
dotfiles, disko + preservation, host `tallyho` in `modules/hosts/tallyho/`. Shared
logic lives in `modules/system/` (boot, user, locale, network, and the `desktop`
and `dev` profiles) and `modules/features/` (each app with its own config, pi,
plymouth); packages are `perSystem.packages` consumed via `moduleWithSystem` + `self'`.
Still missing vs the references:
- no `attrs/` (profile) layer — add when a second host or a "bundle" need appears.

## Rules of thumb for the agent working on this repo

- `modules/features/<name>.nix` for an **optional app** (one app = one module).
  `system/` for what is **always on**; a system profile like `desktop` stays in
  `system/` and composes features (like voidarc) — do not put it in `features/`.
  No directory + default.nix for a lone file: use a flat file (`git.nix`); a
  directory only when it holds several files.
- Host-specific values (hostname, disk, hardware) stay in
  `modules/hosts/<host>/`; everything generic goes up the tree.
- Cross-module communication through options (`mkOption`/`mkDefault`), not by
  importing host files from features.
- Need a wrapped/custom package? `perSystem.packages.<name>` in the same file as
  the feature that uses it, consumed via `moduleWithSystem` + `self'`.
- Flat file per feature (`<name>.nix`); split sub-files (e.g. `gtk.nix`,
  `cursor.nix`) in a directory only when the file gets big — each is still its
  own nixosModule.
- Comments in English.

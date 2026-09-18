---
name: dendritic-pattern
description: NixOS flake structure rules for this repo (dendritic pattern with flake-parts). Use whenever working on modules/, flake.nix, hosts, features, packages, or dotfiles in this repository.
---

# Dendritic Pattern (this repo)

Full reference: [docs/dendritic-pattern.md](../../../docs/dendritic-pattern.md) (relative to this SKILL.md, i.e. `docs/dendritic-pattern.md` at the repo root).

Rules of thumb for working on this repo:

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
- Every `.nix` file under `modules/` is auto-imported (import-tree) and
  contributes to whatever flake output it owns (`flake.nixosModules.*`,
  `nixosConfigurations`, `perSystem.packages`, ...). Never edit a central
  import list — add a file, it exists.

# Pi resources

`package/` is a local Pi package bundled into the Nix wrapper, including for
`nix run .#pi`. It contains the clipboard and quit extensions, caveman and ponytail,
and pinned npm dependencies for ask-user-question and pi-subagents (including its
skills and prompts). Gondolin mounts the bundle read-only at its original path.
Repository-specific skills and extensions remain in the repository's `.pi/`.

## Switch from manual installs

After activating the new wrapper, remove the old npm package declarations with
`pi remove npm:pi-subagents` and
`pi remove npm:@juicesharp/rpiv-ask-user-question` to avoid loading two copies.
Remove `npm:pi-claude-bridge` too if it is still declared: it is not bundled.
Remove old manual caveman/ponytail copies from `~/.pi/agent/skills/` once any local
changes are saved here. Hjem no longer installs the clipboard/quit extensions
there; remove any manually installed copies as well.
User settings, sessions and credentials are not managed or overwritten.

## Update and check

Edit the dependency versions in `package/package.json`, then run
`npm install --package-lock-only --ignore-scripts --legacy-peer-deps` there.
Update `npmDepsHash` in `pi.nix` using the new dependency hash, then build:

```sh
nix build .#pi
```

The isolated loader check takes the installed Pi module root and the built
resource bundle path (both are in the wrapper's Nix closure):

```sh
node modules/features/pi/check-resources.mjs \
  /nix/store/…-pi-coding-agent-…/lib/node_modules/pi-monorepo \
  /nix/store/…-pi-personal-resources-1.0.0
```

It checks that all four extensions load, that the question and delegation tools
register, and that exactly the four expected personal/package skills are found.

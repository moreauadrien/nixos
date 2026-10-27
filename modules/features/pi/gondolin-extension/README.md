# Gondolin sandbox for Pi

The extension owns its Nix-enabled Alpine image:

- `build-config.json`: base image, disk size and guest environment.
- `provision-nix.sh`: Nix installation and guest packages.
- `package.json` / `package-lock.json`: pinned Gondolin builder dependency.

At session startup, the extension hashes the lockfile, build configuration and
provisioning script. It reuses the corresponding local image or builds it with
`gondolin build` before starting the VM. Build output is saved under
`${XDG_CACHE_HOME:-$HOME/.cache}/gondolin/pi-build-*.log`; Pi displays its path.
A build failure blocks sandbox startup, without falling back to host tools.

NixOS supplies the host dependencies and loads the extension; it does not build
the guest image. Pi package-management subcommands do not start or build a VM.
Edit these local files and rebuild the Pi package to change the sandbox. The
first subsequent session builds the new image, which may take several minutes.

Run the lightweight tests from the repository root with Node 24:

```sh
node --test modules/features/pi/gondolin-extension/*.test.ts
```

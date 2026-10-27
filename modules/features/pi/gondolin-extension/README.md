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

## GitHub authentication

Set `GH_TOKEN` in the host environment before launching Pi. To avoid putting the
value in shell history (Bash):

```sh
read -rs -p 'GitHub token: ' GH_TOKEN; printf '\n'
export GH_TOKEN
pi
unset GH_TOKEN
```

The extension reads the token on VM startup. Only a placeholder enters the VM;
Gondolin substitutes the real token in HTTP headers sent to `api.github.com`
(for the API) and `github.com` (for Git over HTTPS).
Pi's bash environment forwarding also strips the real `GH_TOKEN` so it cannot
overwrite that placeholder. Without `GH_TOKEN`, GitHub authentication is not
configured. Restart Pi to change tokens.

The agent can exercise the token's permissions even though it cannot read the
value. Use a short-lived, fine-grained token with minimal permissions. Never put
the token in the workspace, image configuration or a guest-visible file. This
protects the token from sandboxed tools, not trusted host-side extensions or
unsandboxed Pi sessions (`pi-yolo`).

## Tests

Run the lightweight tests from the repository root with Node 24:

```sh
(cd modules/features/pi/gondolin-extension && npm ci --ignore-scripts)
node --test modules/features/pi/gondolin-extension/*.test.ts
```

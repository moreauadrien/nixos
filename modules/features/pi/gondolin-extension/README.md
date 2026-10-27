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

### GitHub App (automatic renewal)

Install a dedicated GitHub App on the selected repositories, granting only the
permissions the agent needs (for example **Contents: Read and write** for Git
pushes). Generate and download an RSA private key from the App settings.

On the **host**, outside the repository and all Gondolin mounts, create
`~/.config/gondolin/github-app.json`:

```json
{
  "appId": "123456",
  "installationId": "789012",
  "privateKeyFile": "/home/adrien/.config/gondolin/github-app.pem"
}
```

Both IDs are strings. The App ID is shown in the App settings; the installation
ID is the number in the installation settings URL (`/installations/<id>`).
`privateKeyFile` must be an absolute path to the downloaded key, not the PEM
contents. Set permissions on the host:

```sh
chmod 700 ~/.config/gondolin
chmod 600 ~/.config/gondolin/github-app.json ~/.config/gondolin/github-app.pem
pi
```

Do not commit these files, manage them as Nix store sources, paste the key into
Pi, or run Pi from a directory containing these files. The extension rejects
credential files under any guest-visible mount (including symlink aliases),
files readable by other users, and hard-linked files.

The host signs a short-lived JWT and obtains an installation token at startup.
It renews the token five minutes before expiry, retrying every 30 seconds after
a failure. The guest keeps the same `GH_TOKEN` placeholder across renewals.
If renewal fails past expiry, GitHub requests fail closed until renewal succeeds;
other destinations remain available. Renewal timers and requests stop on session
shutdown/reload. Tokens and JWTs are not saved to disk or session history.

Use `/github-status` in Pi to see the App, installation and token expiration,
without displaying credentials. To check repository access from the guest:

```sh
gh api installation/repositories
```

For Git HTTPS authentication, use `gh auth setup-git` or a per-command credential
helper, for example `git -c credential.helper='!gh auth git-credential' push`.
The agent acts as the App, not as your user; commands requiring a user identity
or permissions unavailable to installation tokens may not work.

App configuration takes precedence over a host `GH_TOKEN`. An invalid config or
initial token request blocks sandbox startup rather than switching identities.
Restart Pi after changing App configuration or its private key.

### Static token (manual renewal)

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
configured unless the GitHub App is configured. Restart Pi to change tokens.

### Security boundary

The agent can exercise the token's permissions even though it cannot read the
value. Restrict App installation repositories and permissions; for static tokens,
use short-lived, fine-grained tokens with minimal permissions. Never put
the token in the workspace, image configuration or a guest-visible file. This
protects the token from sandboxed tools, not trusted host-side extensions or
unsandboxed Pi sessions (`pi-yolo`).

## Tests

Run the lightweight tests from the repository root with Node 24:

```sh
(cd modules/features/pi/gondolin-extension && npm ci --ignore-scripts)
node --test modules/features/pi/gondolin-extension/*.test.ts
```

sudo loadkeys fr

## WSL host: orbit

For an existing x86_64 NixOS-WSL installation, run from this repository:

```sh
sudo nixos-rebuild switch --flake .#orbit
```

This host keeps `nixos` as the default WSL user and uses state version `26.05`.
It does not import the desktop, disk layout, or boot configuration from `tallyho`.

## Installer (automated)

From the NixOS installer ISO (with your SSH key loaded for repo access):

nix run --extra-experimental-features "nix-command flakes" 'git+https://github.com/moreauadrien/nixos#install'

It clones the repo to a tmpdir, generates the hardware config (conventional
commit), asks for the install disk, the user password and the LUKS
passphrase, installs with disko-install, then copies the repo to
/persistent/etc/nixos on the new machine.

---

## Manual steps

sudo loadkeys fr

mkdir nixos && cd nixos

nixos-generate-config --show-hardware-config --root . > hardware-configuration.nix


---

nixos-generate-config \
  --no-filesystems \
  --flake \
  --dir .

sudo nix --extra-experimental-features "nix-command flakes" \
  run 'github:nix-community/disko/latest#disko-install' -- \
  --flake .#nixos \
  --disk main /dev/vda


Trouver la plus grosse partition dans lsblk (ici /dev/vda4)

sudo mount -o subvol=persistent /dev/mapper/cryptroot /mnt

sudo cp ~/nixos/* /mnt/etc/nixos

sudo reboot

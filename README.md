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

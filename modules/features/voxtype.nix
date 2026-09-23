# Voice-to-text daemon (whisper.cpp via voxtype-vulkan).
{
  moduleWithSystem,
  ...
}: {
  flake.nixosModules.voxtype = moduleWithSystem ({ pkgs, ... }: {
    hjem.users.adrien.packages = [ pkgs.voxtype-vulkan ];

    # hjem.users.adrien.files.".config/voxtype/config.toml".text = ''
    # '';
  });
}

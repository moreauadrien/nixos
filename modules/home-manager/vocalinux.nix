{
  pkgs,
  ...
}: let
  python = pkgs.python312;
  # pywhispercpp (bindings whisper.cpp, moteur par défaut) absent de nixpkgs :
  # wheel manylinux officielle qui embarque whisper.cpp compilé.
  pywhispercpp = python.pkgs.buildPythonPackage rec {
    pname = "pywhispercpp";
    version = "1.5.1";
    format = "wheel";
    src = pkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/fe/e2/0509ccac8e2c89489a1b800aa0e45a79ff3a3c86cb7c0a335c81bbebc89b/pywhispercpp-${version}-cp312-cp312-manylinux_2_27_x86_64.manylinux_2_28_x86_64.whl";
      sha256 = "1n6rvv4k83v1kjqw2l1dvph4mvhwz68j9y8kbrzwcjvzqarsyglp";
    };
    # runtime deps déclarées par le wheel (numpy/requests utilisés par pywhispercpp)
    propagatedBuildInputs = with python.pkgs; [numpy requests tqdm platformdirs];
  };
  vocalinux = python.pkgs.buildPythonApplication rec {
    pname = "vocalinux";
    version = "0.16.2";
    format = "wheel";
    src = pkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/c5/28/15ae46a83e35fc87620e95bef0c43eca997ce9fce9c904844ab78c48ab9e/vocalinux-${version}-py3-none-any.whl";
      sha256 = "00ch7ayz1vvxrc72xxglpz9j0ihrxwlpydb55jhafcvvp8dbbpi2";
    };
    propagatedBuildInputs = with python.pkgs; [
      pywhispercpp
      pynput
      evdev
      requests
      numpy
      pyaudio
      pygobject3
      psutil
    ];
    buildInputs = with pkgs; [
      gtk3
      libnotify
      libayatana-appindicator
    ];
    nativeBuildInputs = [pkgs.wrapGAppsHook3];
    # Outils externes lancés à l'exécution (injection de texte, presse-papier)
    # + typelibs GObject (non ramassés par wrapGAppsHook3 sur un build wheel)
    giTypelibPath = pkgs.lib.makeSearchPath "lib/girepository-1.0" [
      pkgs.gtk3
      pkgs.pango.out
      pkgs.gdk-pixbuf
      pkgs.at-spi2-core # Atk
      pkgs.harfbuzz
      pkgs.glib.out
      pkgs.gobject-introspection
      pkgs.libnotify
      pkgs.libayatana-appindicator
    ];
    makeWrapperArgs = [
      "--prefix GI_TYPELIB_PATH : ${giTypelibPath}"
      "--set-default FONTCONFIG_FILE ${pkgs.fontconfig.out}/etc/fonts/fonts.conf"
      "--prefix PATH : ${pkgs.lib.makeBinPath [
        pkgs.wtype
        pkgs.ydotool
        pkgs.xdotool
        pkgs.wl-clipboard
        pkgs.xclip
      ]}"
    ];
  };
in {
  home.packages = [vocalinux];
}

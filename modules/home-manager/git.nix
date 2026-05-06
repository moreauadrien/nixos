{...}: {
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Adrien Moreau";
        email = "adrienmoreau@ik.me";
      };
      init = {
        defaultBranch = "main";
      };
    };
  };
}

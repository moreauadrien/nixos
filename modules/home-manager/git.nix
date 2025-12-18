{...}: {
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Adrien Moreau";
        email = "moreauadrien92@gmail.com";
      };
      init = {
        defaultBranch = "main";
      };
    };
  };
}

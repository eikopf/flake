{ identity, ... }:
{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = identity.fullName;
        email = identity.email;
      };

      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };
}

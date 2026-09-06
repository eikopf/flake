{ identity, ... }:
{
  programs.jujutsu = {
    enable = true;
    settings = {
      ui.editor = "nvim";

      user = {
        name = identity.fullName;
        email = identity.email;
      };
    };
  };
}

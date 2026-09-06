{ pkgs, ... }:
{
  # Install neovim without letting home-manager manage ~/.config/nvim/init.lua,
  # which would overwrite the git-tracked config living there.
  home.packages = [ pkgs.neovim ];
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
}

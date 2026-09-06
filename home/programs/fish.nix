{ ... }:
let
  shellAliases = {
    # git
    gs = "git status";
    gl = "git log --graph --decorate --oneline --all";

    # jujutsu
    js = "jj status --no-pager";
    jl = "jj log --no-pager";

    # eza
    ezaa = "eza -alh";
  };
in
{
  programs.fish = {
    enable = true;
    inherit shellAliases;
    functions = {
      fish_greeting = {
        body = "";
      };
    };
  };
}

{ ... }:
{
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;

    # fish integration is enabled by default (the home-manager option defaults to true)
    enableBashIntegration = true;
  };
}

{ identity, ... }:
{
  imports = [ ../../modules/common/users.nix ];
  nix.settings.trusted-users = [ identity.username ];
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    extraSpecialArgs = { inherit identity; };
    users.${identity.username}.imports = [ ../../home/profiles/personal.nix ];
  };
}

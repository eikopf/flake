# basic configuration for all macOS hosts

{
  self,
  identity,
  user,
  ...
}:
{
  users.knownUsers = [ user ];

  # this is apparently the default uid for the primary user on macOS, but you
  # can get the exact value by running `dscl . -read /Users/<user> UniqueID`
  users.users.${user}.uid = identity.darwinUid;

  security.pam.services.sudo_local.touchIdAuth = true;

  # this is apparently necessary for an ongoing migration, and will be
  # removed at some later point
  system.primaryUser = user;

  system.configurationRevision = self.rev or self.dirtyRev or null;

  system.defaults = {
    dock.autohide = true;
    dock.mru-spaces = false;
    finder.AppleShowAllExtensions = true;
    finder.FXPreferredViewStyle = "clmv"; # use columns in Finder by default
    NSGlobalDomain.AppleICUForce24HourTime = true;
    NSGlobalDomain.NSAutomaticSpellingCorrectionEnabled = false;
  };
}

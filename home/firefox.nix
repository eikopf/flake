{ lib, config, ... }:
{
  programs.firefox = {
    enable = lib.mkDefault false;
    # Preserve the profile location used before Home Manager 26.05. Moving it
    # requires an explicit data migration, not merely a package update.
    configPath = ".mozilla/firefox";

    # see https://firefox-admin-docs.mozilla.org/reference/policies/ for details
    policies = {
      # disable telemetry and annoying features
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;
      DontCheckDefaultBrowser = true;
      OfferToSaveLoginsDefault = false;
      SkipTermsOfUse = true;
      OverrideFirstRunPage = "";
      OverridePostUpdatePage = "";

      # fix download directory to match $XDG_DOWNLOAD_DIR
      DefaultDownloadDirectory = config.xdg.userDirs.download;

      # configure home page
      FirefoxHome = {
        Search = true;
        TopSites = false;
        SponsoredTopSites = false;
        Highlights = false;
        Pocket = false;
        Stories = false;
        SponsoredPocket = false;
        SponsoredStories = false;
        Snippets = false;
        Locked = false;
      };

      # set locales
      RequestedLocales = [
        "en-CH"
        "en-AU"
        "en-US"
        "de-CH"
        "de-DE"
      ];

      # disable suggestions
      FirefoxSuggest = {
        WebSuggestions = false;
        SponsoredSuggestions = false;
        ImproveSuggest = false;
      };

      # disable user messages
      UserMessaging = {
        SkipOnboarding = true;
        MoreFromMozilla = false;
        FirefoxLabs = false;
      };

      ExtensionSettings = {
        # uBlock Origin
        "uBlock0@raymondhill.net" = {
          installation_mode = "normal_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          private_browsing = true;
        };
        # Bitwarden
        "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
          installation_mode = "normal_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
          private_browsing = true;
          default_area = "navbar";
        };
      };

      # extension-specific settings
      "3rdparty".Extensions = {
        "uBlock0@raymondhill.net".userSettings = {
          showIconBadge = false;
        };
      };
    };

    profiles.default = {
      isDefault = true;

      settings = {
        "browser.aboutConfig.showWarning" = false;
      };
    };
  };
}

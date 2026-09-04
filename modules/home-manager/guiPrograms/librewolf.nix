{
  pkgs,
  config,
  ...
}: let
  startpage_preferences = import ../startpage-preferences.nix;
in {
  programs.firefox = {
    enable = true;
    package = pkgs.librewolf;
    configPath = "${config.xdg.configHome}/mozilla/firefox";
    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      SanitizeOnShutdown = false;
      Preferences = {
        "cookiebanners.service.mode.privateBrowsing" = 2; # Block cookie banners in private browsing
        "cookiebanners.service.mode" = 2; # Block cookie banners
        "privacy.donottrackheader.enabled" = true;
        "privacy.fingerprintingProtection" = true;
        "privacy.resistFingerprinting" = true;
        "privacy.trackingprotection.emailtracking.enabled" = true;
        "privacy.trackingprotection.enabled" = true;
        "privacy.trackingprotection.fingerprinting.enabled" = true;
        "privacy.trackingprotection.socialtracking.enabled" = true;
      };
      RequestedLocales = [
        "fr"
        "en-US"
      ];
      SearchEngines = {
        Default = "Startpage";
        Add = [
          {
            Name = "Startpage";
            URLTemplate = "https://www.startpage.com/sp/search?prfe=${startpage_preferences}&query={searchTerms}";
            Method = "GET";
            IconURL = "https://www.startpage.com/favicon.ico";
            Alias = "sp";
          }
        ];
      };
      ExtensionSettings = {
        #Bitwarden
        "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
        };

        #Linkwarden
        "jordanlinkwarden@gmail.com" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/linkwarden/latest.xpi";
        };

        #UBlock-Origin
        "uBlock0@raymondhill.net" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          installation_mode = "force_installed";
        };

        #Ophirofox
        "{cfd3c5c2-31ec-4c1b-a28e-df38357d02d9}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ophirofox/latest.xpi";
          installation_mode = "force_installed";
        };
      };
    };
  };
}

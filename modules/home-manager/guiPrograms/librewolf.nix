{ pkgs, config, ... }:
let
  startpage_preferences = "cc666ed1e7fcf6d77c7258d739352543093f0c2464f9965afd4df3006aab0ed5ecf3a18d28395e3d64ed1d1db0a4ef0ee90d84b320ecf497afa49d736b2462d40daa63a73b15e9b6b677903774ac8096ed4d";
in
{
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
      };
    };
  };
}

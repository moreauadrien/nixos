# LibreWolf browser with privacy policies, search engines and forced extensions
# (mirrors the legacy home-manager config, applied via the wrapper's extraPolicies).
{ ... }: {
  flake.nixosModules.librewolf = { pkgs, ... }: {
    # Make LibreWolf the default browser (html/web mime types)
    xdg.mime = {
      enable = true;
      defaultApplications = {
        "x-scheme-handler/http" = "librewolf.desktop";
        "x-scheme-handler/https" = "librewolf.desktop";
        "text/html" = "librewolf.desktop";
        "application/xhtml+xml" = "librewolf.desktop";
      };
    };

    environment.systemPackages = [
      (pkgs.librewolf.override {
        extraPolicies = {
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
            Default = "DuckDuckGo";
            Add = [
              {
                Name = "DuckDuckGo";
                URLTemplate = "https://noai.duckduckgo.com/?q={searchTerms}";
                Method = "GET";
                IconURL = "https://noai.duckduckgo.com/favicon.ico";
                Alias = "dd";
              }
              {
                Name = "Startpage";
                URLTemplate = "https://www.startpage.com/sp/search?prfe=cc666ed1e7fcf6d77c7258d739352543093f0c2464f9965afd4df3006aab0ed5ecf3a18d28395e3d64ed1d1db0a4ef0ee90d84b320ecf497afa49d736b2462d40daa63a73b15e9b6b677903774ac8096ed4d&query={searchTerms}";
                Method = "GET";
                IconURL = "https://www.startpage.com/favicon.ico";
                Alias = "sp";
              }
              {
                Name = "Brave Search";
                URLTemplate = "https://search.brave.com/search?q={searchTerms}";
                Method = "GET";
                IconURL = "https://search.brave.com/favicon.ico";
                Alias = "brave";
              }
              {
                # udm=web = web only, no AI
                Name = "Google";
                URLTemplate = "https://www.google.com/search?q={searchTerms}&udm=web";
                Method = "GET";
                IconURL = "https://www.google.com/favicon.ico";
                Alias = "g";
              }
              {
                Name = "Kagi";
                URLTemplate = "https://kagi.com/search?q={searchTerms}";
                Method = "GET";
                IconURL = "https://kagi.com/favicon.ico";
                Alias = "kagi";
              }
            ];
          };
          ExtensionSettings = {
            # Bitwarden
            "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
              installation_mode = "force_installed";
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
            };
            # Linkwarden
            "jordanlinkwarden@gmail.com" = {
              installation_mode = "force_installed";
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/linkwarden/latest.xpi";
            };
            # uBlock Origin
            "uBlock0@raymondhill.net" = {
              installation_mode = "force_installed";
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
            };
            # Ophirofox
            "{cfd3c5c2-31ec-4c1b-a28e-df38357d02d9}" = {
              installation_mode = "force_installed";
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/ophirofox/latest.xpi";
            };
          };
        };
      })
    ];
  };
}

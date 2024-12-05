{ lib, pkgs, config, ... }:
{
  services.nginx = {
    enable = true;
    virtualHosts."home" = {
      root = "/var/www/website/";
      default = true;
      extraConfig = "error_page 404 403 500 503 /index.html;";
    };

  };

  systemd.tmpfiles.settings = {
      "10-websitefiles" = {
        "/var/www/website" = {
          "C+" = {
            group = "users";
            mode = "0777";
            user = "nginx";
            argument = "${./website}";
          };
        };
      };
      "20-editablewebsitefiles" = {
        "/var/www/website" = {
          "Z+" = {
            group = "users";
            mode = "0777";
            user = "nginx";
          };
        };
      };
  };

  networking.firewall.allowedTCPPorts = [80 443];

}

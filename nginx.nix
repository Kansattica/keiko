{ lib, pkgs, config, ... }:
{
  services.nginx = {
    enable = true;
    virtualHosts."home" = {
      root = "/var/www/website/";
      default = true;
    };

  };

  systemd.tmpfiles.settings = {
      "10-websitefiles" = {
        "/var/www/website" = {
          d = {
            group = "users";
            mode = "0777";
            user = "nginx";
          };
        };
        "/var/www/website/index.html" = {
          f = {
            group = "users";
            mode = "0777";
            user = "nginx";
            argument = "horse boot love wins";
          };
        };
      };
  };

  networking.firewall.allowedTCPPorts = [80 443];

}

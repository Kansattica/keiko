{ lib, pkgs, config, ... }:
{
  services.nginx = {
    enable = true;
    virtualHosts."*" = {
      root = "/var/www/website/";
    };

  };
}

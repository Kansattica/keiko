{ lib, pkgs, config, ... }:
{
	services.haveged.enable = true;
	services.create_ap = {
		enable = true;
		settings = {
			INTERNET_IFACE = "enu1";
			WIFI_IFACE = "wlan0";
            SSID = "Keikonet";
			COUNTRY = "US";
			NO_DNSMASQ = 1;
			ISOLATE_CLIENTS = 0;
			GATEWAY = "10.0.0.1";
		};
	};

  networking.networkmanager.unmanaged = [ "interface-name:wlp*" ]
	  ++ lib.optional config.services.hostapd.enable "interface-name:${config.services.hostapd.interface}";

	services.dnsmasq = {
		enable = true;
		settings = {
			domain-needed = true;
			no-resolv = true;
			no-poll = true;
			no-hosts = true;
			local-ttl = 30;

			dhcp-range = [ "10.0.0.2,10.0.0.254" ];
			interface = "ap0";
			bind-interfaces = true;
			address = "/#/10.0.0.1";
		};

		resolveLocalQueries = false;

	};

	networking.firewall.allowedUDPPorts = [53 67];

}

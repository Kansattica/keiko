{ lib, pkgs, ... }:
{
	services.haveged.enable = true;
	services.create_ap = {
		enable = true;
		settings = {
			INTERNET_IFACE = "enp0s31f6";
			WIFI_IFACE = "wlp1s0";
	    SSID = "Wikipetan!";
			COUNTRY = "US";
			NO_DNSMASQ = 1;
			ISOLATE_CLIENTS = 1;
			GATEWAY = "10.0.0.1";
		};
	};

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

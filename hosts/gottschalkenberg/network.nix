{ ... }:
{
  networking.useDHCP = false;
  networking.useNetworkd = true;

  systemd.network = {
    enable = true;
    links."10-pi-ethernet" = {
      matchConfig = {
        Driver = "macb";
        PermanentMACAddress = "98:fe:54:4d:d8:eb";
      };
      linkConfig.Name = "lan0";
    };
    netdevs."20-br0" = {
      netdevConfig = {
        Kind = "bridge";
        Name = "br0";
        MACAddress = "98:fe:54:4d:d8:eb";
      };
    };
    networks = {
      "20-lan0" = {
        matchConfig.Name = "lan0";
        networkConfig = {
          Bridge = "br0";
          LinkLocalAddressing = "no";
        };
        linkConfig.RequiredForOnline = "enslaved";
      };
      "30-br0" = {
        matchConfig.Name = "br0";
        networkConfig = {
          DHCP = "yes";
          IPv6AcceptRA = true;
        };
        linkConfig.RequiredForOnline = "routable";
      };
    };
  };
}

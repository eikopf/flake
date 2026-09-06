{ pkgs, ... }:
let
  gaps = {
    inner = 10;
    outer = 5;
  };
  # Keep in sync with sway.nix — edgeGap aligns waybar with window edges
  edgeGap = gaps.outer + gaps.inner;

  # Emits waybar custom-module JSON from `tailscale status --json`.
  tailscale-status = pkgs.writeShellScript "waybar-tailscale" ''
    if ! status=$(${pkgs.tailscale}/bin/tailscale status --json 2>/dev/null); then
      echo '{"text": "<b>TAIL</b> !", "class": "down", "tooltip": "tailscaled not running"}'
      exit 0
    fi
    ${pkgs.jq}/bin/jq -c '
      .BackendState as $state
      | (if $state == "Running" then ["\u2195", "up"]
         elif $state == "NeedsLogin" or $state == "NeedsMachineAuth" then ["\ue0a2", "login"]
         else ["!", "down"] end) as [$symbol, $class]
      | { text: ("<b>TAIL</b> " + $symbol),
          class: $class,
          tooltip: (if $state == "Running"
                    then (.Self.DNSName | rtrimstr(".")) + " — " + (.TailscaleIPs[0] // "?")
                    else $state end) }
    ' <<<"$status"
  '';
in
{
  programs.waybar = {
    enable = true;
    # Let HM generate the waybar.service unit (WantedBy graphical-session.target).
    systemd.enable = true;
    settings = [
      {
        layer = "top";
        position = "top";
        height = 28;
        spacing = 0;
        modules-left = [ "sway/workspaces" ];
        modules-right = [
          "custom/tailscale"
          "memory"
          "clock#date"
          "clock#time"
        ];

        "custom/tailscale" = {
          exec = "${tailscale-status}";
          return-type = "json";
          interval = 5;
        };

        "sway/workspaces" = {
          disable-scroll = true;
        };

        memory = {
          format = "<b>MEM</b> {}%";
          interval = 5;
        };

        "clock#date" = {
          format = "<b>DATE</b> {:%Y-%m-%d}";
          interval = 60;
        };

        "clock#time" = {
          format = "<b>TIME</b> {:%H:%M %Z}";
          interval = 5;
        };
      }
    ];
    style = ''
      * {
        font-family: Berkeley Mono;
        font-weight: 500;
        font-size: 10pt;
        border: none;
        border-radius: 0;
        min-height: 0;
        margin: 0;
        padding: 0;
      }

      window#waybar {
        background-color: #f5f5f5;
        color: #303030;
      }

      /* Left outer spacing: #workspaces confirmed to produce visible margin */
      #workspaces {
        margin-left: ${toString edgeGap}px;
      }

      /* Right outer spacing: .modules-right padding-right confirmed to affect right edge */
      .modules-right {
        padding-right: ${toString edgeGap}px;
      }

      /* Inter-module spacing on the right */
      .modules-right label {
        margin-left: 15px;
      }

      #custom-tailscale.down {
        color: #989898;
      }

      #workspaces button {
        padding: 0 6px;
        color: #585858;
        background-color: transparent;
      }

      #workspaces button.focused {
        color: #ffffff;
        background-color: #585858;
      }

      #workspaces button.urgent {
        color: #303030;
        background-color: #cecece;
      }
    '';
  };
}

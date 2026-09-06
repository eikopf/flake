{ pkgs, config, ... }:
let
  modifier = "Mod4";
  gaps = {
    inner = 10;
    outer = 5;
  };
in
{
  wayland.windowManager.sway = {
    enable = true;
    # Use the system-level sway (programs.sway) which has the gtk wrapper enabled;
    # HM manages only the config, not the package.
    package = null;
    # Config validation runs sway --validate which needs a binary; skip it when package = null.
    checkConfig = false;
    systemd.enable = true;
    config = {
      inherit modifier;
      terminal = "ghostty";
      menu = "rofi -show drun";

      fonts = {
        names = [ "Berkeley Mono" ];
        style = "Medium";
        size = 10.0;
      };

      input = {
        "type:keyboard" = {
          xkb_options = "ctrl:nocaps";
        };
      };

      gaps = {
        inherit (gaps) inner outer;
      };

      window = {
        border = 2;
        titlebar = false;
      };

      floating = {
        border = 2;
        titlebar = false;
        modifier = modifier;
      };

      focus.followMouse = false;

      colors = {
        focused = {
          border = "#585858";
          background = "#585858";
          text = "#ffffff";
          indicator = "#585858";
          childBorder = "#585858";
        };
        unfocused = {
          border = "#cecece";
          background = "#cecece";
          text = "#585858";
          indicator = "#cecece";
          childBorder = "#cecece";
        };
        focusedInactive = {
          border = "#cecece";
          background = "#cecece";
          text = "#585858";
          indicator = "#cecece";
          childBorder = "#cecece";
        };
        urgent = {
          border = "#cecece";
          background = "#cecece";
          text = "#585858";
          indicator = "#cecece";
          childBorder = "#cecece";
        };
      };

      keybindings = {
        # terminal and launcher
        "${modifier}+Return" = "exec ghostty";
        "${modifier}+space" = "exec rofi -show drun";
        "${modifier}+Shift+q" = "kill";

        # focus (vim-style)
        "${modifier}+h" = "focus left";
        "${modifier}+j" = "focus down";
        "${modifier}+k" = "focus up";
        "${modifier}+l" = "focus right";
        "${modifier}+Left" = "focus left";
        "${modifier}+Down" = "focus down";
        "${modifier}+Up" = "focus up";
        "${modifier}+Right" = "focus right";

        # move windows
        "${modifier}+Shift+h" = "move left";
        "${modifier}+Shift+j" = "move down";
        "${modifier}+Shift+k" = "move up";
        "${modifier}+Shift+l" = "move right";
        "${modifier}+Shift+Left" = "move left";
        "${modifier}+Shift+Down" = "move down";
        "${modifier}+Shift+Up" = "move up";
        "${modifier}+Shift+Right" = "move right";

        # splits
        "${modifier}+Shift+s" = "split h";
        "${modifier}+Shift+v" = "split v";

        # layout
        "${modifier}+f" = "fullscreen toggle";
        "${modifier}+s" = "layout stacking";
        "${modifier}+w" = "layout tabbed";
        "${modifier}+e" = "layout toggle split";
        "${modifier}+Shift+t" = "floating toggle";
        "${modifier}+t" = "focus mode_toggle";
        "${modifier}+a" = "focus parent";

        # workspaces
        "${modifier}+1" = "workspace number 1";
        "${modifier}+2" = "workspace number 2";
        "${modifier}+3" = "workspace number 3";
        "${modifier}+4" = "workspace number 4";
        "${modifier}+5" = "workspace number 5";
        "${modifier}+6" = "workspace number 6";
        "${modifier}+7" = "workspace number 7";
        "${modifier}+8" = "workspace number 8";
        "${modifier}+9" = "workspace number 9";
        "${modifier}+0" = "workspace number 10";
        "${modifier}+Shift+1" = "move container to workspace number 1";
        "${modifier}+Shift+2" = "move container to workspace number 2";
        "${modifier}+Shift+3" = "move container to workspace number 3";
        "${modifier}+Shift+4" = "move container to workspace number 4";
        "${modifier}+Shift+5" = "move container to workspace number 5";
        "${modifier}+Shift+6" = "move container to workspace number 6";
        "${modifier}+Shift+7" = "move container to workspace number 7";
        "${modifier}+Shift+8" = "move container to workspace number 8";
        "${modifier}+Shift+9" = "move container to workspace number 9";
        "${modifier}+Shift+0" = "move container to workspace number 10";

        # screenshots (grim + slurp)
        "${modifier}+Ctrl+3" =
          "exec grim ${config.xdg.userDirs.pictures}/screenshots/$(date +%F-%H-%M-%S).png";
        "${modifier}+Ctrl+4" =
          "exec grim -g \"$(slurp)\" ${config.xdg.userDirs.pictures}/screenshots/$(date +%F-%H-%M-%S).png";

        # volume
        "XF86AudioRaiseVolume" = "exec pactl set-sink-volume @DEFAULT_SINK@ +10%";
        "XF86AudioLowerVolume" = "exec pactl set-sink-volume @DEFAULT_SINK@ -10%";
        "XF86AudioMute" = "exec pactl set-sink-mute @DEFAULT_SINK@ toggle";
        "XF86AudioMicMute" = "exec pactl set-source-mute @DEFAULT_SOURCE@ toggle";

        # lock screen
        "${modifier}+Ctrl+l" = "exec swaylock -f -c 000000";

        # sway management
        "${modifier}+Shift+c" = "reload";
        "${modifier}+Shift+e" =
          "exec rofi -show power-menu -modi \"power-menu:${pkgs.rofi-power-menu}/bin/rofi-power-menu --no-symbols\"";
        "${modifier}+Shift+b" =
          "exec systemctl --user is-active --quiet waybar && systemctl --user stop waybar || systemctl --user start waybar";
        "${modifier}+r" = "mode resize";
      };

      modes = {
        resize = {
          "h" = "resize shrink width 10 px";
          "j" = "resize grow height 10 px";
          "k" = "resize shrink height 10 px";
          "l" = "resize grow width 10 px";
          "Left" = "resize shrink width 10 px";
          "Down" = "resize grow height 10 px";
          "Up" = "resize shrink height 10 px";
          "Right" = "resize grow width 10 px";
          "Return" = "mode default";
          "Escape" = "mode default";
          "${modifier}+r" = "mode default";
        };
      };

      seat = {
        "*" = {
          xcursor_theme = "Adwaita 24";
        };
      };

      bars = [ ];

      startup = [
        { command = "swaymsg workspace number 1"; }
      ];
    };
  };
}

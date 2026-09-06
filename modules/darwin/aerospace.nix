{ lib, ... }:
{
  # aerospace
  services.aerospace = {
    enable = true;

    settings = {
      # normalisation — disable flatten to get BSP-style 1/2 + 1/4 + 1/4 layout
      enable-normalization-flatten-containers = false;

      # layout
      gaps = {
        outer.top = 8;
        outer.bottom = 8;
        outer.left = 8;
        outer.right = 8;

        inner.horizontal = 8;
        inner.vertical = 8;
      };

      # primary keybindings
      mode.main.binding = {
        alt-slash = "layout tiles horizontal vertical";
        alt-comma = "layout accordion horizontal vertical";

        alt-h = "focus --boundaries all-monitors-outer-frame left";
        alt-j = "focus --boundaries all-monitors-outer-frame down";
        alt-k = "focus --boundaries all-monitors-outer-frame up";
        alt-l = "focus --boundaries all-monitors-outer-frame right";

        alt-shift-h = "move left";
        alt-shift-j = "move down";
        alt-shift-k = "move up";
        alt-shift-l = "move right";

        ctrl-alt-shift-h = "move-node-to-monitor --focus-follows-window left";
        ctrl-alt-shift-l = "move-node-to-monitor --focus-follows-window right";

        ctrl-minus = "resize smart -50";
        ctrl-equal = "resize smart +50";

        alt-shift-semicolon = "mode service";
      };

      # service mode keybindings
      mode.service.binding = lib.mapAttrs (_: v: [ v ] ++ [ "mode main" ]) {
        esc = "reload-config";
        r = "flatten-workspace-tree"; # reset layout
        f = "layout floating tiling"; # toggle between floating and tiling layout
        backspace = "close-all-windows-but-current";
      };
    };
  };

}

{ pkgs, ... }:
{
  services.swayidle = {
    enable = true;
    timeouts = [
      {
        timeout = 300;
        command = "${pkgs.swaylock}/bin/swaylock -f -c 000000";
      }
      {
        timeout = 330;
        command = "${pkgs.sway}/bin/swaymsg 'output * dpms off'";
        resumeCommand = "${pkgs.sway}/bin/swaymsg 'output * dpms on'";
      }
    ];
    events = {
      before-sleep = "${pkgs.swaylock}/bin/swaylock -f -c 000000";
      after-resume = "${pkgs.sway}/bin/swaymsg 'output * dpms on'";
    };
  };
}

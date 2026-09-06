{ lib, ... }:
{
  programs.starship = {
    enable = true;
    settings = {
      character.success_symbol = "λ";
      character.error_symbol = "λ";

      hostname = {
        ssh_only = false;
        ssh_symbol = "";
      };

      username = {
        show_always = true;
        format = "[$user]($style)@";
      };

      direnv = {
        disabled = false;
        symbol = "direnv";
        format = "[\\($symbol\\)]($style) ";
      };

      # configured to only show venv information, and to only
      # activate when a venv is currently activated
      python = {
        detect_extensions = [ ];
        detect_files = [ ];
        format = "[\\($virtualenv $version\\)]($style) ";
      };

      format = lib.concatStrings [
        "$python"
        "$direnv"
        "$username"
        "$hostname"
        "$directory"
        "$git_branch"
        "$git_commit"
        "$git_state"
        "$git_metrics"
        "$git_status"
        "$sudo"
        "$cmd_duration"
        "$line_break"
        "$jobs"
        "$time"
        "$status"
        "$shell"
        "$character"
      ];
    };
  };
}

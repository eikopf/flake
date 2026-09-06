{ pkgs, ... }:
{
  # Unicode fallback fonts — covers CJK, emoji, and broad script support.
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
  ];
}

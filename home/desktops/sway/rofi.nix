{ ... }:
{
  programs.rofi = {
    enable = true;
    theme = "alabaster";
  };

  xdg.dataFile."rofi/themes/alabaster.rasi".text = ''
    * {
        background-color: #f5f5f5;
        text-color:       #303030;
        border-color:     #585858;
        font:             "Berkeley Mono 10";
        padding:          0;
        margin:           0;
        spacing:          0;
    }

    window {
        border:  2px;
        padding: 8px;
        width:   40%;
    }

    inputbar {
        spacing:      6px;
        padding:      0 0 6px 0;
        children:     [prompt, entry];
        border:       0 0 1px 0;
        border-color: #cecece;
    }

    listview {
        padding:   4px 0 0 0;
        scrollbar: false;
    }

    element {
        padding:      4px 6px;
        spacing:      6px;
        border:       0 0 1px 0;
        border-color: #cecece;
    }

    element selected {
        background-color: #585858;
        text-color:       #ffffff;
        border-color:     #585858;
    }

    element-text {
        background-color: transparent;
        text-color:       inherit;
    }

    element-icon {
        background-color: transparent;
        size:             1em;
    }
  '';
}

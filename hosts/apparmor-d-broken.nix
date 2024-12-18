{
  security.apparmor-d.profiles = {
    "agetty" = "disable"; # breaks qemu tty login -> password doesn't get prompted
    "baloorunner" = "disable"; # ERROR processing regexs
    "cron" = "disable"; # ERROR processing regexs
    "dbus-session" = "disable"; # ERROR processing regexs
    "dbus-system" = "disable"; # ERROR processing regexs
    "dolphin" = "disable"; # ERROR processing regexs
    "exo-helper" = "disable"; # ERROR processing regexs
    "exo-open" = "disable";
    "flatpak-app" = "disable";
    "gio-launch-desktop" = "disable";
    "gjs-console" = "disable";
    "gnome-calculator-search-provider" = "disable";
    "gnome-session-binary" = "disable"; # profile open
    "gnome-shell" = "disable"; # profile open
    "gsd-housekeeping" = "disable";
    "hyprland" = "disable";
    "jgmenu" = "disable";
    "ksmserver" = "disable";
    "kstart" = "disable";
    "kwin_wayland" = "disable";
    "labwc" = "disable";
    "makepkg" = "disable";
    "mono-sgen" = "disable";
    "openbox" = "disable"; # profile autostart
    "pkexec" = "disable";
    "plank" = "disable";
    "plasmashell.apparmor.d" = "disable";
    "pypr" = "disable";
    "su" = "disable";
    "sudo" = "disable";
    "systemd-udevd" = "disable";
    "tint2" = "disable";
    "torsocks" = "disable";
    "waybar" = "disable";
    "xfce-appfinder" = "disable";
    "xfce-panel" = "disable";
    "xfce-session" = "disable";
    "xfdesktop" = "disable";
    "xinit" = "disable";
  };
}

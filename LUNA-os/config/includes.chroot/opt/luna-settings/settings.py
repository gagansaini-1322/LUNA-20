#!/usr/bin/env python3
"""Luna OS Settings window — dark themed GTK3 settings panel."""

import os
import shutil
import signal
import subprocess

import gi
gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
from gi.repository import Gtk, Gdk, GLib, GdkPixbuf

WIN_W = 900
WIN_H = 620
TITLE_H = 38

PRIMARY = (0.388, 0.4, 0.945)
SELECTED = (0.357, 0.357, 0.839)
BG = (0.063, 0.075, 0.102)
CARD = (0.106, 0.122, 0.165)
BORDER = (0.118, 0.125, 0.188)
TEXT = (0.91, 0.92, 0.94)
MUTED = (0.546, 0.576, 0.686)


CATEGORIES = [
    ("System", "preferences-system",
     [("Display", "preferences-desktop-display", "xfce4-display-settings"),
      ("Keyboard", "preferences-desktop-keyboard", "xfce4-keyboard-settings"),
      ("Mouse & Touchpad", "input-mouse", "xfce4-mouse-settings"),
      ("Date & Time", "preferences-system-time", "xfce4-time-out-plugin"),
      ("Default Apps", "preferences-system-windows", "xfce4-session-settings")]),
    ("Bluetooth", "bluetooth",
     [("Manage Devices", "bluetooth", "blueman-manager"),
      ("Send / Receive Files", "bluetooth", "blueman-services")]),
    ("Network", "network",
     [("Wi-Fi", "network-wireless", "nm-connection-editor"),
      ("VPN", "network-vpn", "nm-connection-editor"),
      ("Proxy", "preferences-system-network", "xfce4-settings-manager --proxy"),
      ("Firewall", "network-server", "gufw")]),
    ("Personalization", "preferences-desktop-wallpaper",
     [("Wallpaper", "preferences-desktop-wallpaper", "/usr/lib/luna-app-store/luna-set-wallpaper default"),
      ("Appearance", "preferences-desktop-theme", "xfce4-appearance-settings"),
      ("Fonts", "preferences-fonts", "xfce4-appearance-settings --fonts"),
      ("Window Manager", "preferences-system-windows", "xfwm4-settings"),
      ("Panel", "preferences-panel", "xfce4-panel --prefs")]),
    ("Apps", "applications-system",
     [("Default Apps", "preferences-system-windows", "xfce4-session-settings"),
      ("Permissions", "preferences-system-privacy", "polkit-gnome-authorization")]),
    ("Notifications", "preferences-system-notifications",
     [("Toggle Notifications", "preferences-system-notifications", "xfce4-notifyd-config"),
      ("DND", "preferences-system-notifications", "xfce4-notifyd-config")]),
    ("Sound", "audio-volume",
     [("Output", "audio-speakers", "pavucontrol"),
      ("Input", "audio-input-microphone", "pavucontrol --record"),
      ("Profiles", "audio-card", "pavucontrol")]),
    ("Power", "battery",
     [("Power Profiles", "power-profile-performance", "xfce4-power-manager-settings"),
      ("Battery", "battery", "xfce4-power-manager-settings"),
      ("Sleep", "preferences-screensaver", "xfce4-screensaver-preferences")]),
    ("Privacy", "preferences-system-privacy",
     [("Screen Lock", "preferences-screensaver", "light-locker"),
      ("Location", "location", "xfce4-settings-manager"),
      ("Camera", "camera", "guvcview")]),
    ("About", "help-about",
     [("About Luna OS", "help-about", "/usr/local/bin/luna-about"),
      ("System Info", "computer", "neofetch"),
      ("Updates", "system-software-update", "software-properties-gtk")]),
]


class SettingsWin(Gtk.Window):
    def __init__(self):
        super().__init__()
        self.set_title("Luna Settings")
        self.set_default_size(WIN_W, WIN_H)
        self.set_resizable(True)
        self.set_size_request(720, 480)
        self.set_decorated(False)
        self.set_app_paintable(True)
        self.set_position(Gtk.WindowPosition.CENTER)

        self._drag_offset = None
        self._current_cat = 0
        self._content_rows = []

        css = Gtk.CssProvider()
        css.load_from_data(b"""
            window {
                background-color: #10131a;
            }
            .sidebar {
                background: #0f1117;
            }
            .sidebar row {
                background: transparent;
                color: #E8EAF0;
                border-radius: 8px;
                padding: 8px 14px;
                margin: 2px 6px;
                font-size: 13px;
                font-weight: 600;
            }
            .sidebar row:hover {
                background: #1a1d2e;
            }
            .sidebar row:selected {
                background: #5B5BD6;
                color: #ffffff;
            }
            .topbar {
                background: #0F1117;
            }
            .panel {
                background: #10131a;
            }
            .row:hover {
                background: #1a1d2e;
            }
            .row {
                padding: 10px 14px;
                border-bottom: 1px solid #1e2030;
            }
            .row-text {
                color: #E8EAF0;
                font-size: 13px;
            }
            .chev {
                color: #8b93a7;
                font-size: 16px;
            }
        """)
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(), css,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)

        outer = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        self.add(outer)

        topbar = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=0)
        topbar.set_size_request(-1, TITLE_H)
        topbar.get_style_context().add_class("topbar")
        outer.pack_start(topbar, False, False, 0)

        back = Gtk.Button.new_from_icon_name("go-previous-symbolic", Gtk.IconSize.BUTTON)
        back.set_relief(Gtk.ReliefStyle.NONE)
        back.set_size_request(48, TITLE_H)
        back.connect("clicked", lambda *_: self.destroy())
        topbar.pack_start(back, False, False, 0)

        title = Gtk.Label()
        title.set_markup("<b>Settings</b>")
        title.set_xalign(0.0)
        title.get_style_context().add_class("title")
        title.set_margin_start(8)
        topbar.pack_start(title, True, True, 0)

        traffic = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        traffic.set_margin_end(14)
        for color, ti in (("#FFBD2E", "minimize"), ("#27C840", "maximize"), ("#FF5F57", "close")):
            b = Gtk.Button()
            b.set_size_request(14, 14)
            b.set_relief(Gtk.ReliefStyle.NONE)
            css2 = Gtk.CssProvider()
            css2.load_from_data(
                ("* { background-color:%s; border-radius:50%%; border:none;"
                 " min-width:14px; min-height:14px; padding:0; }") % color)
            ctx = b.get_style_context()
            ctx.add_provider(css2, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)
            ctx.add_class("traffic")
            if ti == "close":
                b.connect("clicked", lambda *_: self.destroy())
            traffic.pack_start(b, False, False, 0)
        topbar.pack_end(traffic, False, False, 4)

        topbar_event = Gtk.EventBox()
        topbar_event.set_above_child(False)
        topbar_event.add(topbar)
        topbar_event.connect("button-press-event", self._on_title_press)
        topbar_event.connect("button-release-event", self._on_title_release)
        overlay = Gtk.Fixed()
        outer.add(overlay)
        topbar_event.set_size_request(WIN_W, TITLE_H)
        overlay.put(topbar_event, 0, 0)

        body = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=0)
        body.set_size_request(WIN_W, WIN_H - TITLE_H)
        outer.pack_start(body, True, True, 0)
        body.connect("size-allocate", lambda *_: None)

        sidebar = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        sidebar.get_style_context().add_class("sidebar")
        sidebar.set_size_request(240, -1)
        body.pack_start(sidebar, False, False, 0)

        self._list = Gtk.ListBox()
        self._list.set_selection_mode(Gtk.SelectionMode.SINGLE)
        self._list.get_style_context().add_class("sidebar")
        sidebar.pack_start(self._list, True, True, 0)

        for label, icon, _rows in CATEGORIES:
            row = Gtk.ListBoxRow()
            h = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
            h.set_margin_start(8)
            h.set_margin_end(8)
            try:
                img = Gtk.Image.new_from_icon_name(icon, Gtk.IconSize.LARGE_TOOLBAR)
            except Exception:
                img = Gtk.Image.new_from_icon_name("applications-system", Gtk.IconSize.LARGE_TOOLBAR)
            h.pack_start(img, False, False, 0)
            l = Gtk.Label(label=label)
            l.set_xalign(0.0)
            h.pack_start(l, True, True, 0)
            row.add(h)
            self._list.add(row)
        self._list.connect("row-selected", self._on_select_cat)
        self._list.select_row(self._list.get_row_at_index(0))

        panel = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        panel.get_style_context().add_class("panel")
        body.pack_start(panel, True, True, 0)

        header = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=0)
        header.set_size_request(-1, 56)
        header.set_margin_start(24)
        header.set_margin_end(24)
        header.set_valign(Gtk.Align.CENTER)
        panel.pack_start(header, False, False, 0)

        self._title = Gtk.Label()
        self._title.set_markup("<b><span size='18000'>System</span></b>")
        self._title.set_xalign(0.0)
        header.pack_start(self._title, True, True, 0)

        self._scroller = Gtk.ScrolledWindow()
        self._scroller.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        panel.pack_start(self._scroller, True, True, 0)

        self._list_box = Gtk.ListBox()
        self._list_box.get_style_context().add_class("rows")
        self._scroller.add(self._list_box)
        self._render_cat(0)

    def _on_title_press(self, _w, event):
        if event.button == 1:
            win = self.get_window()
            if win is not None:
                win.begin_move_drag(event.button, int(event.x_root), int(event.y_root),
                                    event.time)
        return False

    def _on_title_release(self, _w, event):
        self._drag_offset = None
        return False

    def _on_select_cat(self, _w, row):
        if row is None:
            return
        idx = row.get_index()
        if idx < 0:
            return
        self._current_cat = idx
        label, icon, _ = CATEGORIES[idx]
        self._title.set_markup("<b><span size='18000'>%s</span></b>" % label)
        self._render_cat(idx)

    def _render_cat(self, idx):
        if idx < 0 or idx >= len(CATEGORIES):
            return
        for child in self._list_box.get_children():
            self._list_box.remove(child)
        _label, _icon, rows = CATEGORIES[idx]
        for (label, icon_name, exec_cmd) in rows:
            row = Gtk.ListBoxRow()
            h = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
            h.set_margin_start(20)
            h.set_margin_end(20)
            h.set_margin_top(2)
            h.set_margin_bottom(2)
            h.set_valign(Gtk.Align.CENTER)
            try:
                img = Gtk.Image.new_from_icon_name(icon_name, Gtk.IconSize.LARGE_TOOLBAR)
            except Exception:
                img = Gtk.Image.new_from_icon_name("applications-system", Gtk.IconSize.LARGE_TOOLBAR)
            h.pack_start(img, False, False, 0)
            l = Gtk.Label(label=label)
            l.set_xalign(0.0)
            h.pack_start(l, True, True, 0)
            chev = Gtk.Label(label="\u203A")
            chev.set_xalign(1.0)
            chev.get_style_context().add_class("chev")
            h.pack_start(chev, False, False, 0)
            row.add(h)
            row.set_size_request(-1, 48)
            row.connect("row-activated", self._on_row_activate, exec_cmd)
            self._list_box.add(row)
        self._list_box.show_all()

    def _on_row_activate(self, _w, _row, cmd):
        if not cmd:
            return
        first = cmd.split()[0]
        if first.startswith("/") and not os.path.exists(first):
            return
        if not first.startswith("/") and not shutil.which(first):
            return
        try:
            subprocess.Popen(cmd, shell=True,
                             stdout=subprocess.DEVNULL,
                             stderr=subprocess.DEVNULL)
        except Exception:
            pass


def main():
    win = SettingsWin()
    win.connect("destroy", Gtk.main_quit)
    signal.signal(signal.SIGINT, lambda *_: Gtk.main_quit())
    Gtk.main()


if __name__ == "__main__":
    main()

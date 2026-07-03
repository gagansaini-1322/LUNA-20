#!/usr/bin/env python3
"""Luna Settings - Custom settings window for Luna OS"""

import os
import subprocess
import shutil
import gi
gi.require_version('Gtk', '3.0')
gi.require_version('Gdk', '3.0')
from gi.repository import Gtk, Gdk, GLib

BG = "#0F0F14"
SURFACE = "#1a1d2e"
SELECTED = "#5B5BD6"
TEXT_PRIMARY = "#E8EAF0"
TEXT_SECONDARY = "#8b93a7"
BORDER = "#1e2030"

CATEGORIES = [
    {"name": "System", "icon": "preferences-system", "items": [
        {"label": "About", "icon": "help-about", "cmd": "luna-about"},
        {"label": "Date & Time", "icon": "preferences-system-time", "cmd": "xfce4-datetime-settings"},
        {"label": "Users and Groups", "icon": "system-users", "cmd": "users-admin"},
        {"label": "Software & Updates", "icon": "system-software-update", "cmd": "software-properties-gtk"},
    ]},
    {"name": "Bluetooth", "icon": "bluetooth", "items": [
        {"label": "Bluetooth Settings", "icon": "bluetooth", "cmd": "blueman-manager"},
    ]},
    {"name": "Network", "icon": "network-wireless", "items": [
        {"label": "Network Connections", "icon": "network-wireless", "cmd": "nm-connection-editor"},
        {"label": "Network Proxy", "icon": "network-proxy", "cmd": "xfce4-settings-manager -p networking"},
    ]},
    {"name": "Personalization", "icon": "preferences-desktop-wallpaper", "items": [
        {"label": "Appearance", "icon": "preferences-desktop-theme", "cmd": "xfce4-settings-manager -p appearance"},
        {"label": "Desktop", "icon": "preferences-desktop-wallpaper", "cmd": "xfce4-settings-manager -p desktop"},
        {"label": "Panel", "icon": "preferences-panel", "cmd": "xfce4-settings-manager -p panel"},
        {"label": "Window Manager", "icon": "xfce-wm", "cmd": "xfce4-settings-manager -p wm"},
    ]},
    {"name": "Apps", "icon": "system-file-manager", "items": [
        {"label": "Default Applications", "icon": "system-file-manager", "cmd": "xfce4-settings-manager -p default-apps"},
        {"label": "File Manager", "icon": "thunar", "cmd": "thunar --bulk-rename"},
    ]},
    {"name": "Notifications", "icon": "dialog-information", "items": [
        {"label": "Notifications", "icon": "dialog-information", "cmd": "xfce4-settings-manager -p notifications"},
    ]},
    {"name": "Sound", "icon": "audio-volume-high", "items": [
        {"label": "Volume Control", "icon": "audio-volume-high", "cmd": "pavucontrol"},
        {"label": "Sound Settings", "icon": "audio-volume-high", "cmd": "xfce4-settings-manager -p sound"},
    ]},
    {"name": "Power", "icon": "system-suspend", "items": [
        {"label": "Power Manager", "icon": "system-suspend", "cmd": "xfce4-power-manager-settings"},
        {"label": "Performance Mode", "icon": "utilities-system-monitor", "cmd": "powerprofilesctl get"},
    ]},
    {"name": "Privacy", "icon": "system-lock-screen", "items": [
        {"label": "Screen Lock", "icon": "system-lock-screen", "cmd": "xfce4-screensaver-preferences"},
    ]},
    {"name": "About", "icon": "help-about", "items": [
        {"label": "About Luna OS", "icon": "luna-logo", "cmd": "luna-about"},
    ]},
]


class SettingsWindow(Gtk.Window):
    def __init__(self):
        super().__init__(title="Settings")
        self.set_default_size(900, 620)
        self.set_resizable(False)
        self.set_decorated(False)
        self.set_position(Gtk.WindowPosition.CENTER)

        self.selected_cat = 0

        # Main vertical box
        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.add(vbox)

        # Custom titlebar
        titlebar = Gtk.DrawingArea()
        titlebar.set_size_request(-1, 40)
        titlebar.connect("draw", self.draw_titlebar)
        titlebar.add_events(Gdk.EventMask.BUTTON_PRESS_MASK | Gdk.EventMask.BUTTON_MOTION_MASK)
        titlebar.connect("button-press-event", self.on_titlebar_click)
        titlebar.connect("motion-notify-event", self.on_titlebar_drag)
        self.titlebar_widget = titlebar
        self._dragging = False
        self._drag_x = 0
        self._drag_y = 0
        vbox.pack_start(titlebar, False, False, 0)

        # Content area
        content = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        vbox.pack_start(content, True, True, 0)

        # Sidebar
        self.sidebar = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        self.sidebar.set_size_request(240, -1)
        self.sidebar.set_margin_top(8)
        self.sidebar.set_margin_bottom(8)
        self.sidebar.set_margin_start(8)
        self.sidebar.set_margin_end(4)
        scrolled_sidebar = Gtk.ScrolledWindow()
        scrolled_sidebar.add(self.sidebar)
        scrolled_sidebar.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        content.pack_start(scrolled_sidebar, False, False, 0)

        # Sidebar separator
        sep = Gtk.Separator(orientation=Gtk.Orientation.VERTICAL)
        content.pack_start(sep, False, False, 0)

        # Right panel
        self.right_panel = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.right_panel.set_margin_start(16)
        self.right_panel.set_margin_end(16)
        self.right_panel.set_margin_top(16)
        self.right_panel.set_margin_bottom(16)
        scrolled_right = Gtk.ScrolledWindow()
        scrolled_right.add(self.right_panel)
        scrolled_right.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        content.pack_start(scrolled_right, True, True, 0)

        self.build_sidebar()
        self.build_right_panel(0)
        self.connect("destroy", lambda w: Gtk.main_quit())
        self.show_all()

    def draw_titlebar(self, widget, cr):
        w = widget.get_allocated_width()
        h = widget.get_allocated_height()

        cr.set_source_rgb(15/255, 17/255, 23/255)
        cr.rectangle(0, 0, w, h)
        cr.fill()

        # Back arrow
        cr.set_source_rgb(139/255, 163/255, 178/255)
        cr.select_font_face("Inter", 0, 0)
        cr.set_font_size(18)
        cr.move_to(16, 28)
        cr.show_text("‹")

        # Title
        cr.set_source_rgb(232/255, 234/255, 240/255)
        cr.set_font_size(14)
        cr.move_to(40, 28)
        cr.show_text("Settings")

        # Traffic light buttons (top-right)
        buttons = [
            (w - 60, "#FFBD2E"),  # Yellow minimize
            (w - 40, "#27C840"),  # Green maximize
            (w - 20, "#FF5F57"),  # Red close
        ]
        for bx, color in buttons:
            r, g, b = self._hex_to_rgb(color)
            cr.set_source_rgb(r, g, b)
            cr.arc(bx, 20, 7, 0, 2 * 3.14159)
            cr.fill()

    def _hex_to_rgb(self, h):
        h = h.lstrip('#')
        return tuple(int(h[i:i+2], 16)/255 for i in (0, 2, 4))

    def on_titlebar_click(self, widget, event):
        w = widget.get_allocated_width()
        if event.button == 1:
            if w - 20 <= event.x <= w:
                self.destroy()
                return True
            self._dragging = True
            self._drag_x = int(event.x_root)
            self._drag_y = int(event.y_root)
        elif event.button == 3:
            pass
        return False

    def on_titlebar_drag(self, widget, event):
        if self._dragging:
            dx = int(event.x_root) - self._drag_x
            dy = int(event.y_root) - self._drag_y
            x, y = self.get_position()
            self.move(x + dx, y + dy)
            self._drag_x = int(event.x_root)
            self._drag_y = int(event.y_root)

    def build_sidebar(self):
        for child in self.sidebar.get_children():
            self.sidebar.remove(child)

        for i, cat in enumerate(CATEGORIES):
            btn = Gtk.Button()
            btn.set_relief(Gtk.ReliefStyle.NONE)
            label_text = f"  {cat['icon']}  {cat['name']}"
            lbl = Gtk.Label(label=cat['name'])
            lbl.set_xalign(0)
            lbl.set_margin_start(12)
            lbl.set_margin_top(8)
            lbl.set_margin_bottom(8)
            lbl.set_margin_end(12)

            if i == self.selected_cat:
                lbl.override_color(Gtk.StateFlags.NORMAL, Gdk.color_parse("#ffffff"))
            else:
                lbl.override_color(Gtk.StateFlags.NORMAL, Gdk.color_parse(TEXT_SECONDARY))

            btn.add(lbl)
            cat_idx = i
            btn.connect("clicked", self.on_category_click, cat_idx)

            if i == self.selected_cat:
                btn.override_background_color(Gtk.StateFlags.NORMAL, Gdk.color_parse(SELECTED))

            self.sidebar.pack_start(btn, False, False, 2)

        self.sidebar.show_all()

    def on_category_click(self, button, index):
        self.selected_cat = index
        self.build_sidebar()
        self.build_right_panel(index)

    def build_right_panel(self, cat_index):
        for child in self.right_panel.get_children():
            self.right_panel.remove(child)

        cat = CATEGORIES[cat_index]

        # Category title
        title = Gtk.Label(label=cat['name'])
        title.set_xalign(0)
        title.override_font(Pango.FontDescription("Inter Bold 20"))
        title.override_color(Gtk.StateFlags.NORMAL, Gdk.color_parse(TEXT_PRIMARY))
        title.set_margin_bottom(16)
        self.right_panel.pack_start(title, False, False, 0)

        # Settings rows
        for item in cat['items']:
            row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
            row.set_margin_bottom(4)
            row.set_margin_top(4)
            row.set_margin_start(8)
            row.set_margin_end(8)

            # Icon
            icon = Gtk.Image.new_from_icon_name(item['icon'], Gtk.IconSize.LARGE_TOOLBAR)
            row.pack_start(icon, False, False, 0)

            # Label
            lbl = Gtk.Label(label=item['label'])
            lbl.set_xalign(0)
            lbl.override_color(Gtk.StateFlags.NORMAL, Gdk.color_parse(TEXT_PRIMARY))
            row.pack_start(lbl, True, True, 0)

            # Chevron
            chevron = Gtk.Label(label="›")
            chevron.override_color(Gtk.StateFlags.NORMAL, Gdk.color_parse(TEXT_SECONDARY))
            row.pack_start(chevron, False, False, 0)

            # Clickable event box
            event_box = Gtk.EventBox()
            event_box.add(row)
            event_box.connect("button-release-event", self.on_row_click, item)
            event_box.set_margin_top(4)
            event_box.set_margin_bottom(4)

            self.right_panel.pack_start(event_box, False, False, 0)

            # Separator
            sep = Gtk.Separator(orientation=Gtk.Orientation.HORIZONTAL)
            self.right_panel.pack_start(sep, False, False, 0)

        self.right_panel.show_all()

    def on_row_click(self, widget, event, item):
        cmd = item.get('cmd', '')
        if cmd:
            cmd_base = cmd.split()[0]
            if shutil.which(cmd_base) or cmd_base.startswith('python3') or cmd_base.startswith('xfce4'):
                subprocess.Popen(cmd, shell=True)


def main():
    win = SettingsWindow()
    Gtk.main()


if __name__ == '__main__':
    main()

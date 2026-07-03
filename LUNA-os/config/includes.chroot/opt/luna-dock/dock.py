#!/usr/bin/env python3
"""Luna Dock - Custom floating pill dock at bottom of screen"""

import os
import shutil
import subprocess
import gi
gi.require_version('Gtk', '3.0')
gi.require_version('Gdk', '3.0')
from gi.repository import Gtk, Gdk, GdkPixbuf, GLib

try:
    import psutil
    HAS_PSUTIL = True
except ImportError:
    HAS_PSUTIL = False

APPS = [
    {"name": "Launcher", "cmd": "xfce4-popup-whiskermenu", "icon": "luna-logo"},
    {"name": "Files", "cmd": "thunar", "icon": "thunar"},
    {"name": "Browser", "cmd": "firefox", "icon": "firefox"},
    {"name": "Terminal", "cmd": "lxterminal", "icon": "utilities-terminal"},
    {"name": "Music", "cmd": "rhythmbox", "icon": "rhythmbox"},
    {"name": "Settings", "cmd": "python3 /opt/luna-settings/settings.py", "icon": "preferences-system"},
    {"name": "Calendar", "cmd": "orage", "icon": "xfce4-calendar"},
]

ICON_SIZE = 52
HOVER_SIZE = 62
PADDING = 16
ICON_DIR = "/usr/share/icons"

class DockWindow(Gtk.Window):
    def __init__(self):
        super().__init__(type=Gtk.WindowType.POPUP)
        self.set_decorated(False)
        self.set_keep_above(True)
        self.set_app_paintable(True)

        screen = Gdk.Screen.get_default()
        self.set_default_size(0, 0)

        visual = screen.get_rgba_visual()
        if visual:
            self.set_visual(visual)

        self.connect("draw", self.on_draw)
        self.connect("size-allocate", self.on_size_allocate)

        self.visible_apps = []
        for app in APPS:
            cmd_base = app["cmd"].split()[0]
            if shutil.which(cmd_base) or cmd_base.startswith("python3"):
                self.visible_apps.append(app)

        self.hover_index = -1
        self.dock_height = ICON_SIZE + 24
        self.dock_width = len(self.visible_apps) * (ICON_SIZE + PADDING) + PADDING

        self.icon_pixbufs = {}
        self.icon_hover_pixbufs = {}
        self.load_icons()

        self.events = (Gdk.EventMask.BUTTON_PRESS_MASK |
                       Gdk.EventMask.POINTER_MOTION_MASK |
                       Gdk.EventMask.LEAVE_NOTIFY_MASK)
        self.add_events(self.events)
        self.connect("button-press-event", self.on_click)
        self.connect("motion-notify-event", self.on_hover)
        self.connect("leave-notify-event", self.on_leave)

        self.position_dock()
        self.show_all()

        GLib.timeout_add(5000, self.check_running)

    def load_icons(self):
        for app in self.visible_apps:
            for size in [ICON_SIZE, HOVER_SIZE]:
                pixbuf = self.find_icon(app["icon"], size)
                if pixbuf:
                    key = (app["icon"], size)
                    self.icon_pixbufs[key] = pixbuf

    def find_icon(self, icon_name, size):
        theme = Gtk.IconTheme.get_default()
        try:
            pixbuf = theme.load_icon(icon_name, size, 0)
            if pixbuf:
                return pixbuf.scale_simple(size, size, GdkPixbuf.InterpType.BILINEAR)
        except:
            pass

        for ext in ['.png', '.svg']:
            for path in [os.path.join(ICON_DIR, f"hicolor/{size}x{size}/apps/{icon_name}{ext}"),
                         os.path.join(ICON_DIR, f"Adwaita/{size}x{size}/apps/{icon_name}{ext}")]:
                if os.path.exists(path):
                    try:
                        return GdkPixbuf.Pixbuf.new_from_file_at_scale(path, size, size, True)
                    except:
                        pass
        return None

    def position_dock(self):
        screen = self.get_screen()
        monitor = screen.get_display().get_primary_monitor()
        if not monitor:
            monitor = screen.get_display().get_monitor_at_point(0, 0)
        geo = monitor.get_geometry()

        self.dock_width = len(self.visible_apps) * (ICON_SIZE + PADDING) + PADDING
        x = (geo.width - self.dock_width) // 2
        y = geo.height - self.dock_height - 8
        self.move(x, y)
        self.set_size_request(self.dock_width, self.dock_height)

    def on_size_allocate(self, widget, allocation):
        pass

    def on_draw(self, widget, cr):
        w = self.get_allocated_width()
        h = self.get_allocated_height()

        # Glassmorphism background pill
        cr.set_source_rgba(18/255, 20/255, 30/255, 0.88)
        radius = h / 2
        cr.new_path()
        cr.arc(radius, radius, radius, 3.14159, 1.5 * 3.14159)
        cr.arc(w - radius, radius, radius, 1.5 * 3.14159, 2 * 3.14159)
        cr.arc(w - radius, h - radius, radius, 0, 3.14159)
        cr.arc(radius, h - radius, radius, 3.14159, 2 * 3.14159)
        cr.close_path()
        cr.fill()

        cr.set_source_rgba(40/255, 42/255, 58/255, 0.3)
        cr.set_line_width(1)
        cr.stroke()

        # Draw icons
        start_x = PADDING // 2 + (PADDING - (ICON_SIZE - ICON_SIZE)) // 2
        for i, app in enumerate(self.visible_apps):
            x = start_x + i * (ICON_SIZE + PADDING) + PADDING // 2
            y = (h - ICON_SIZE) // 2

            is_hovered = (i == self.hover_index)
            size = HOVER_SIZE if is_hovered else ICON_SIZE
            key = (app["icon"], size)
            pixbuf = self.icon_pixbufs.get(key)

            if pixbuf:
                draw_x = x + (ICON_SIZE - size) // 2 if not is_hovered else x - (HOVER_SIZE - ICON_SIZE) // 2
                draw_y = y + (ICON_SIZE - size) // 2 if not is_hovered else y - (HOVER_SIZE - ICON_SIZE) // 2
                Gdk.cairo_set_source_pixbuf(cr, pixbuf, draw_x, draw_y)
                cr.paint()

            # Active dot
            if self.is_running(app["cmd"]):
                dot_x = x + ICON_SIZE // 2
                dot_y = h - 6
                cr.set_source_rgba(1.0, 1.0, 1.0, 0.9)
                cr.arc(dot_x, dot_y, 3, 0, 2 * 3.14159)
                cr.fill()

    def is_running(self, cmd):
        if not HAS_PSUTIL:
            return False
        base = cmd.split()[0]
        for proc in psutil.process_iter(['name', 'cmdline']):
            try:
                cmdline = proc.info.get('cmdline', []) or []
                name = proc.info.get('name', '')
                if name == base or any(base in c for c in cmdline):
                    return True
            except:
                continue
        return False

    def check_running(self):
        self.queue_draw()
        return True

    def on_click(self, widget, event):
        for i, app in enumerate(self.visible_apps):
            x = PADDING // 2 + i * (ICON_SIZE + PADDING) + PADDING // 2
            if x <= event.x <= x + ICON_SIZE:
                cmd = app["cmd"]
                if cmd.startswith("python3"):
                    subprocess.Popen(cmd.split())
                else:
                    subprocess.Popen([cmd])
                break

    def on_hover(self, widget, event):
        new_index = -1
        for i, app in enumerate(self.visible_apps):
            x = PADDING // 2 + i * (ICON_SIZE + PADDING) + PADDING // 2
            if x <= event.x <= x + ICON_SIZE:
                new_index = i
                break

        if new_index != self.hover_index:
            self.hover_index = new_index
            self.queue_draw()

    def on_leave(self, widget, event):
        self.hover_index = -1
        self.queue_draw()

def main():
    dock = DockWindow()
    Gtk.main()

if __name__ == '__main__':
    main()

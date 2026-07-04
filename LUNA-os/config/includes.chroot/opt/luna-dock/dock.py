#!/usr/bin/env python3
"""Luna OS Dock — a custom GTK3 + Cairo floating bottom dock."""

import os
import shutil
import signal
import subprocess
from datetime import datetime

import gi
gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
from gi.repository import Gtk, Gdk, GLib, GdkPixbuf

import cairo
import psutil

ICON_SIZE = 52
ICON_HOVER_SIZE = 62
PILL_HEIGHT = 76
PILL_PADDING = 14
BOTTOM_GAP = 8
DOT_RADIUS = 3


HANDLERS = {
    "settings": "xfce4-settings-manager",
    "files": "thunar",
    "browser": "firefox",
    "terminal": "lxterminal",
    "music": "rhythmbox",
    "calendar": "gnome-calendar",
    "apps": "xdotool",
}
if not shutil.which("gnome-calendar") and shutil.which("orage"):
    HANDLERS["calendar"] = "orage"


APPS = [
    ("Apps", "view-grid-symbolic", "/usr/share/applications", "apps"),
    ("Files", "system-file-manager", "thunar", "files"),
    ("Browser", "firefox", "firefox", "browser"),
    ("Terminal", "utilities-terminal", "lxterminal", "terminal"),
    ("Music", "rhythmbox", "rhythmbox", "music"),
    ("Settings", "preferences-system", "xfce4-settings-manager", "settings"),
    ("Calendar", "x-office-calendar", HANDLERS["calendar"], "calendar"),
]


def get_icon_pixbuf(name, size):
    try:
        gtk_icon_theme = Gtk.IconTheme.get_default()
        info = gtk_icon_theme.lookup_icon(name, size, Gtk.IconLookupFlags.FORCE_SIZE)
        if info:
            pb = info.load_icon()
            if pb is not None and pb.get_width() >= size:
                return pb
    except Exception:
        pass
    for ext in ("svg", "png", "xpm"):
        path = f"/usr/share/pixmaps/{name}.{ext}"
        if os.path.exists(path):
            try:
                return GdkPixbuf.Pixbuf.new_from_file_at_size(path, size, size)
            except Exception:
                pass
    if os.path.exists(name) and os.path.isfile(name):
        try:
            return GdkPixbuf.Pixbuf.new_from_file_at_size(name, size, size)
        except Exception:
            pass
    try:
        return Gtk.IconTheme.get_default().load_icon("application-x-executable", size, 0)
    except Exception:
        return None


def is_app_running(name):
    try:
        for p in psutil.process_iter(["name", "cmdline"]):
            n = (p.info.get("name") or "").lower()
            cn = name.lower()
            if n == cn:
                return True
            cmd = " ".join(p.info.get("cmdline") or []).lower()
            if cn in cmd:
                return True
    except Exception:
        pass
    return False


def launch(handler_key):
    cmd = HANDLERS.get(handler_key)
    if not cmd:
        return
    try:
        subprocess.Popen(cmd.split(), stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        pass


PILL_BG = (0.07, 0.08, 0.12, 0.88)
PILL_BORDER = (0.16, 0.18, 0.26, 0.95)
HOVER_TINT = (0.14, 0.16, 0.25, 1.0)
ACTIVE_DOT = (1.0, 1.0, 1.0, 0.95)
DROP_SHADOW = (0.0, 0.0, 0.0, 0.45)


class DockWindow(Gtk.Window):
    def __init__(self):
        super().__init__(type=Gtk.WindowType.POPUP)
        self.set_title("Luna Dock")
        self.set_decorated(False)
        self.set_keep_above(True)
        self.set_accept_focus(True)
        self.set_skip_taskbar_hint(True)
        self.set_skip_pager_hint(True)
        self.set_app_paintable(True)

        self._hover_index = -1
        self._active_keys = set()
        self._pixbufs = {}
        self._pixbufs_hover = {}
        self._valid_apps = []
        for label, icon, execname, key in APPS:
            if execname and not execname.startswith("/") and not shutil.which(execname):
                continue
            self._valid_apps.append((label, icon, key))

        self.get_screen().connect("size-changed", lambda *_: GLib.idle_add(self._reposition))
        self.connect("screen-changed", self._on_screen_changed)
        self.connect("draw", self._on_draw)
        self.connect("motion-notify-event", self._on_motion)
        self.connect("leave-notify-event", self._on_leave)
        self.connect("button-press-event", self._on_click)
        self.add_events(Gdk.EventMask.POINTER_MOTION_MASK
                        | Gdk.EventMask.LEAVE_NOTIFY_MASK
                        | Gdk.EventMask.BUTTON_PRESS_MASK)

        self._compute_size()
        self._reposition()
        GLib.timeout_add_seconds(2, self._refresh_active)
        self._refresh_active()
        self.show_all()

    def _compute_size(self):
        n = len(self._valid_apps)
        if n <= 0:
            n = 1
        width = PILL_PADDING * 2 + n * (ICON_HOVER_SIZE + 8)
        height = PILL_HEIGHT
        self.set_size_request(width, height)
        self.set_default_size(width, height)

    def _on_screen_changed(self, *_):
        self._reposition()

    def _reposition(self):
        s = self.get_screen()
        if not s:
            return
        mon = s.get_primary_monitor()
        if mon is None and s.get_n_monitors() > 0:
            mon = 0
        if mon is None:
            return
        geom = s.get_monitor_geometry(mon)
        if not geom:
            return
        w, h = self.get_size_request()
        x = geom.x + (geom.width - w) // 2
        y = geom.y + geom.height - h - BOTTOM_GAP
        self.move(x, y)
        if self._pixbufs:
            return
        for _, icon_name, _ in self._valid_apps:
            self._pixbufs[icon_name] = get_icon_pixbuf(icon_name, ICON_SIZE)
            self._pixbufs_hover[icon_name] = get_icon_pixbuf(icon_name, ICON_HOVER_SIZE)

    def _refresh_active(self):
        new_active = set()
        for _, _, key in self._valid_apps:
            handler = HANDLERS.get(key)
            if handler and is_app_running(handler.split()[0]):
                new_active.add(key)
        if new_active != self._active_keys:
            self._active_keys = new_active
            self.queue_draw()
        return True

    def _index_at(self, x, y):
        n = len(self._valid_apps)
        if n == 0 or y < 0 or y > PILL_HEIGHT:
            return -1
        avail_w = self.get_allocated_width()
        item_w = ICON_HOVER_SIZE + 8
        first_x = (avail_w - (item_w * n - 8)) // 2
        rel = x - first_x
        if rel < 0 or rel >= item_w * n:
            return -1
        return int(rel // item_w)

    def _on_motion(self, _w, event):
        i = self._index_at(event.x, event.y)
        if i != self._hover_index:
            self._hover_index = i
            cursor = Gdk.Cursor.new_for_display(self.get_display(), Gdk.CursorType.HAND2)
            self.get_window().set_cursor(cursor if i >= 0 else None)
            self.queue_draw()
        return True

    def _on_leave(self, *_):
        if self._hover_index != -1:
            self._hover_index = -1
            self.queue_draw()
        return True

    def _on_click(self, _w, event):
        i = self._index_at(event.x, event.y)
        if 0 <= i < len(self._valid_apps):
            _, _, key = self._valid_apps[i]
            launch(key)
            return True
        return False

    def _draw_rounded_pill(self, cr, x, y, w, h, r):
        cr.new_sub_path()
        cr.arc(x + w - r, y + r, r, -1.5707963, 0)
        cr.arc(x + w - r, y + h - r, r, 0, 1.5707963)
        cr.arc(x + r, y + h - r, r, 1.5707963, 3.1415927)
        cr.arc(x + r, y + r, r, 3.1415927, 4.7123889)
        cr.close_path()

    def _on_draw(self, _w, ctx):
        alloc = self.get_allocation()
        w, h = alloc.width, alloc.height
        r = h // 2

        ctx.save()
        ctx.set_operator(cairo.OPERATOR_SOURCE)
        ctx.set_source_rgba(0, 0, 0, 0)
        ctx.paint()
        ctx.restore()

        ctx.save()
        self._draw_rounded_pill(ctx, 0, 0, w, h, r)
        ctx.set_source_rgba(*PILL_BG)
        ctx.fill_preserve()
        ctx.set_source_rgba(*PILL_BORDER)
        ctx.set_line_width(1)
        ctx.stroke()
        ctx.restore()

        n = len(self._valid_apps)
        if n == 0:
            return False
        item_w = ICON_HOVER_SIZE + 8
        first_x = (w - (item_w * n - 8)) // 2
        base_y = (h - ICON_HOVER_SIZE) // 2

        for i, (label, icon_name, key) in enumerate(self._valid_apps):
            ix = first_x + i * item_w
            iy = base_y
            is_hover = (i == self._hover_index)
            size = ICON_HOVER_SIZE if is_hover else ICON_SIZE
            ox = ix + (ICON_HOVER_SIZE - size) // 2
            oy = iy + (ICON_HOVER_SIZE - size) // 2

            if is_hover:
                ctx.save()
                self._draw_rounded_pill(ctx, ox - 4, oy - 4, size + 8, size + 8, 10)
                ctx.set_source_rgba(*HOVER_TINT)
                ctx.fill()
                ctx.restore()

            pb = self._pixbufs_hover.get(icon_name) if is_hover else self._pixbufs.get(icon_name)
            pb_use = pb if pb else (
                self._pixbufs.get(icon_name) if not is_hover else None
            )
            if pb_use is not None:
                ctx.save()
                ctx.translate(ox, oy)
                Gdk.cairo_set_source_pixbuf(ctx, pb_use, 0, 0)
                ctx.paint()
                ctx.restore()
            else:
                ctx.save()
                ctx.set_source_rgba(*HOVER_TINT)
                self._draw_rounded_pill(ctx, ox, oy, size, size, 10)
                ctx.fill()
                ctx.restore()

            if key in self._active_keys:
                ctx.save()
                ctx.set_source_rgba(*ACTIVE_DOT)
                ctx.arc(ix + ICON_HOVER_SIZE // 2,
                        iy + ICON_HOVER_SIZE + 2, DOT_RADIUS, 0, 6.2831853)
                ctx.fill()
                ctx.restore()

        return False


def main():
    win = DockWindow()
    win.connect("destroy", Gtk.main_quit)
    signal.signal(signal.SIGINT, lambda *_: Gtk.main_quit())
    Gtk.main()


if __name__ == "__main__":
    main()

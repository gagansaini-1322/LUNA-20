#!/usr/bin/env python3
"""Luna OS Top Bar — custom GTK3 + Cairo top-of-screen status bar."""

import os
import shutil
import signal
import subprocess
import time
from datetime import datetime

import gi
gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
from gi.repository import Gtk, Gdk, GLib, GdkPixbuf

import cairo

BAR_HEIGHT = 48
PADDING = 14
NOTIFY_DIR = "/tmp/luna-notifications.json"
NOTIFY_BADGE_INITIAL = 0


COLOR_BG = (0.058, 0.066, 0.090, 0.92)
COLOR_BG_HOVER = (0.10, 0.12, 0.18, 0.95)
COLOR_BORDER = (0.117, 0.125, 0.188, 1.0)
COLOR_BRAND = (0.66, 0.33, 0.97, 1.0)
COLOR_TEXT = (0.91, 0.92, 0.94, 1.0)
COLOR_MUTED = (0.546, 0.576, 0.686, 1.0)
COLOR_RED = (1.0, 0.37, 0.34, 1.0)
COLOR_YELLOW = (1.0, 0.785, 0.34, 1.0)


def _run(cmd, timeout=2):
    try:
        return subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
    except Exception:
        return None


def sh(cmd):
    return _run(cmd.split(), timeout=3)


def check_x():
    if not os.environ.get("DISPLAY"):
        return False
    return True


def wifi_info():
    r = sh("nmcli -t -f active,ssid,signal general")
    if r and r.returncode == 0 and r.stdout:
        for line in r.stdout.splitlines():
            parts = line.split(":")
            if len(parts) >= 2 and parts[0] == "yes":
                try:
                    pct = int(parts[2]) if len(parts) > 2 else 80
                except Exception:
                    pct = 80
                return {"connected": True, "ssid": parts[1], "signal": pct}
    return {"connected": False, "ssid": None, "signal": 0}


def volume_info():
    r = sh("pactl get-sink-volume @DEFAULT_SINK@")
    pct = 0
    if r and r.returncode == 0 and r.stdout:
        s = r.stdout
        try:
            if "%" in s:
                pct = int(s.split("%")[0].split()[-1])
        except Exception:
            pct = 0
    mute = False
    r2 = sh("pactl get-sink-mute @DEFAULT_SINK@")
    if r2 and r2.returncode == 0 and "yes" in r2.stdout.lower():
        mute = True
    return {"pct": pct, "muted": mute}


def bt_info():
    r = sh("bluetoothctl show")
    if r and r.returncode == 0 and r.stdout:
        return {"on": "yes" in r.stdout.lower() and "powered: yes" in r.stdout.lower()}
    return {"on": False}


def battery_info():
    base = None
    for cand in ("/sys/class/power_supply/BAT0",
                 "/sys/class/power_supply/BAT1"):
        if os.path.isdir(cand):
            base = cand
            break
    if not base:
        return None
    try:
        cap = int(open(os.path.join(base, "capacity")).read().strip())
    except Exception:
        cap = -1
    try:
        status = open(os.path.join(base, "status")).read().strip()
    except Exception:
        status = "Unknown"
    return {"pct": cap, "charging": status.lower() in ("charging", "full")}


def ws_count():
    r = sh("xdotool get_num_desktops")
    if r and r.returncode == 0:
        try:
            return int(r.stdout.strip())
        except Exception:
            pass
    return 1


def switch_ws(idx):
    sh(f"xdotool set_desktop {idx}")


def _icon(name, size=16):
    fallback = name
    try:
        info = Gtk.IconTheme.get_default().lookup_icon(name, size, Gtk.IconLookupFlags.FORCE_SIZE)
        if info:
            return info.load_icon()
    except Exception:
        pass
    try:
        return Gtk.IconTheme.get_default().load_icon("image-missing", size, 0)
    except Exception:
        return None


def launch(cmd):
    if not cmd or not shutil.which(cmd.split()[0]):
        return
    try:
        subprocess.Popen(cmd.split(), stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        pass


def get_work_area():
    if not check_x():
        return 0, 0, 800, 600
    s = Gdk.Screen.get_default()
    if not s:
        return 0, 0, 800, 600
    mon = s.get_primary_monitor() or 0
    geom = s.get_monitor_geometry(mon)
    return geom.x, geom.y, geom.width, geom.height


class TopBar(Gtk.Window):
    def __init__(self):
        super().__init__(type=Gtk.WindowType.POPUP)
        self.set_title("Luna Top Bar")
        self.set_decorated(False)
        self.set_keep_above(True)
        self.set_app_paintable(True)
        self.set_skip_taskbar_hint(True)
        self.set_skip_pager_hint(True)
        self.stick()

        self.add_events(Gdk.EventMask.POINTER_MOTION_MASK
                        | Gdk.EventMask.BUTTON_PRESS_MASK
                        | Gdk.EventMask.LEAVE_NOTIFY_MASK)

        self.set_default_size(get_work_area()[2], BAR_HEIGHT)
        _, _, w, h = get_work_area()
        self.move(0, 0)
        self.resize(w, BAR_HEIGHT)

        self.connect("draw", self._on_draw)
        self.connect("button-press-event", self._on_click)
        self.connect("size-allocate", self._on_size)
        self.connect("screen-changed", lambda *_: self._on_size(None, None))

        self._wifi = {"connected": False}
        self._vol = {"pct": 0, "muted": False}
        self._bt = {"on": False}
        self._bat = None
        self._n_ws = ws_count()
        self._cur_ws = 0
        r = sh("xdotool get_desktop")
        if r and r.returncode == 0:
            try:
                self._cur_ws = int(r.stdout.strip())
            except Exception:
                self._cur_ws = 0
        self._notifs = NOTIFY_BADGE_INITIAL
        self._hover = None
        self._show_all = False

        GLib.timeout_add_seconds(30, self._tick_clock)
        GLib.timeout_add_seconds(10, self._tick_state)
        self._tick_clock()
        self._tick_state()
        self._reserve_strut()
        self.show_all()

    def _on_size(self, *_):
        _, _, w, _ = get_work_area()
        self.resize(w, BAR_HEIGHT)
        self._reserve_strut()
        self.queue_draw()
        return False

    def _reserve_strut(self):
        try:
            if not check_x():
                return
            xid = self.get_window().get_xid()
            strut = (0, 0, BAR_HEIGHT, 0,
                     0, 0, 0, 0,
                     0, 0, 0, int(self.get_allocated_width() or 1920))
            cmd = ["xprop", "-id", str(xid),
                   "-format", "_NET_WM_STRUT_PARTIAL", "32c",
                   "-set", "_NET_WM_STRUT_PARTIAL", "\t".join(str(v) for v in strut)]
            subprocess.run(cmd, stderr=subprocess.DEVNULL)
        except Exception:
            pass

    def _on_draw(self, _w, ctx):
        alloc = self.get_allocation()
        w, h = alloc.width, alloc.height

        ctx.set_source_rgba(*COLOR_BG)
        ctx.rectangle(0, 0, w, h)
        ctx.fill()
        ctx.set_source_rgba(*COLOR_BORDER)
        ctx.rectangle(0, h - 1, w, 1)
        ctx.fill()

        ctx.save()
        try:
            ctx.select_font_face("Inter", cairo.FONT_SLANT_NORMAL, cairo.FONT_WEIGHT_BOLD)
        except Exception:
            pass
        ctx.set_font_size(13)

        x_left = PADDING
        brand_size = 28
        brand_r = brand_size // 2
        cx, cy = PADDING + brand_r, h // 2
        ctx.set_source_rgba(*COLOR_BG_HOVER)
        ctx.arc(cx, cy, brand_r, 0, 6.2831853)
        ctx.fill()
        ctx.set_source_rgba(*COLOR_BRAND)
        ctx.arc(cx + 4, cy - 2, brand_r - 4, -0.6, 1.9)
        ctx.fill()
        ctx.set_source_rgba(*COLOR_BG)
        ctx.arc(cx + 7, cy - 3, brand_r - 9, -0.6, 1.9)
        ctx.fill()

        ctx.set_source_rgba(*COLOR_BRAND)
        ctx.move_to(x_left + brand_size + 8, h // 2 + 5)
        ctx.show_text("LUNA OS")
        ctx.fill()

        ws_x = x_left + brand_size + 80
        ctx.set_source_rgba(*COLOR_TEXT)
        ctx.move_to(ws_x, h // 2 + 5)
        ctx.show_text(f"Workspace {self._cur_ws + 1} of {self._n_ws}")
        ctx.fill()
        ctx.set_source_rgba(*COLOR_MUTED)
        ctx.move_to(ws_x + 110, h // 2 + 5)
        ctx.show_text("v")
        ctx.fill()

        now = datetime.now()
        time_str = now.strftime("%a, %b %d  %I:%M %p").lstrip("0")
        ctx.set_font_size(14)
        ctx.set_source_rgba(*COLOR_TEXT)
        ext = ctx.text_extents(time_str)
        cx_t = w // 2 - ext[2] // 2
        ctx.move_to(cx_t, h // 2 + 5)
        ctx.show_text(time_str)
        ctx.fill()

        ctx.set_font_size(13)
        right_x = w - PADDING
        slots = []
        icons = []
        labels = []
        wifi_text = "WiFi: ON" if self._wifi["connected"] else "WiFi: OFF"
        slots.append(("/wifi", 60, "nm-connection-editor", wifi_text))
        icons.append(("network-wireless-signal-" + (
            "excellent" if self._wifi["signal"] >= 75 else
            "good" if self._wifi["signal"] >= 50 else
            "ok" if self._wifi["signal"] >= 25 else "weak" if self._wifi["connected"] else "off"),
                     self._wifi["connected"]))
        labels.append(wifi_text)

        vol = self._vol
        vol_text = f"Vol: {vol['pct']}%" + (" (M)" if vol["muted"] else "")
        slots.append(("/volume", 80, "pavucontrol", vol_text, self._vol))
        icons.append(("audio-volume-high" if vol["pct"] > 60 else
                      "audio-volume-medium" if vol["pct"] > 30 else
                      "audio-volume-low" if vol["pct"] > 0 else
                      "audio-volume-muted" if vol["muted"] else "audio-volume-off",
                     True))
        labels.append(vol_text)

        bt_text = "BT: ON" if self._bt["on"] else "BT: OFF"
        slots.append(("/bt", 60, "blueman-manager", bt_text))
        icons.append(("bluetooth-active" if self._bt["on"] else "bluetooth-disabled", self._bt["on"]))
        labels.append(bt_text)

        if self._bat is not None:
            pct = self._bat["pct"]
            bat_text = f"Bat: {pct}%"
            slots.append(("/battery", 50, "xfce4-power-manager-settings", bat_text))
            low = pct <= 20 and not self._bat["charging"]
            icons.append(("battery-caution" if low else "battery-full" if pct > 90 else "battery-good",
                          low))
            labels.append(bat_text)

        slots.append(("/notif", 40, "xfce4-notifyd-config", f"Notif: {self._notifs}"))
        icons.append(("preferences-system-notifications", self._notifs > 0))
        labels.append(f"{self._notifs}")

        slots.append(("/power", 60, None, "Power"))
        icons.append(("system-shutdown", True))
        labels.append("\u23FB")

        self._hit_rects = []
        rx = right_x
        for slot in reversed(slots):
            label = slot[-1]
            width = list(slot)[1] if isinstance(slot, tuple) else 60
            rx -= width + 8
            if self._hover and self._hover.get("rect") and self._hover["slot"] == slot[0]:
                ctx.set_source_rgba(*COLOR_BG_HOVER)
                ctx.rectangle(rx, 0, width, h)
                ctx.fill()
            self._hit_rects.append((rx, 0, width, h, slot[0]))
            ico = icons[len(self._hit_rects) - 1] if icons else None
            if ico:
                name, _on = ico
                pb = _icon(name, 16)
                if pb is not None:
                    ctx.save()
                    ctx.translate(rx + 8, h // 2 - 8)
                    Gdk.cairo_set_source_pixbuf(ctx, pb, 0, 0)
                    ctx.paint()
                    ctx.restore()
            ctx.set_source_rgba(*COLOR_TEXT)
            ctx.move_to(rx + 28, h // 2 + 5)
            ctx.show_text(label)
            ctx.fill()

        ctx.restore()
        return False

    def _on_click(self, _w, event):
        for (x, y, ww, hh, slot) in self._hit_rects:
            if x <= event.x <= x + ww and y <= event.y <= y + hh:
                if slot == "/wifi":
                    launch("nm-connection-editor" if shutil.which("nm-connection-editor") else "xfce4-settings-manager")
                elif slot == "/volume":
                    launch("pavucontrol")
                elif slot == "/bt":
                    launch("blueman-manager")
                elif slot == "/battery":
                    launch("xfce4-power-manager-settings")
                elif slot == "/notif":
                    pass
                elif slot == "/power":
                    if shutil.which("xfce4-session-logout"):
                        launch("xfce4-session-logout")
                    elif shutil.which("luna-settings"):
                        launch("luna-settings")
                return True
        if PADDING + 14 <= event.x <= PADDING + 14 + 80 and event.y <= BAR_HEIGHT:
            launch("python3 /opt/luna-settings/settings.py")
            return True
        return False

    def _motion(self, _w, event):
        new_hover = None
        for (x, y, ww, hh, slot) in self._hit_rects:
            if x <= event.x <= x + ww and y <= event.y <= y + hh:
                new_hover = {"rect": (x, y, ww, hh), "slot": slot}
                break
        if (new_hover or self._hover) and (
            not new_hover or not self._hover or
            new_hover["slot"] != self._hover["slot"]):
            self._hover = new_hover
            self.queue_draw()
        return True

    def _tick_clock(self):
        self.queue_draw()
        return True

    def _tick_state(self):
        try:
            self._wifi = wifi_info()
            self._vol = volume_info()
            self._bt = bt_info()
            self._bat = battery_info()
            self._n_ws = max(1, ws_count())
            r = sh("xdotool get_desktop")
            if r and r.returncode == 0:
                self._cur_ws = int(r.stdout.strip())
        except Exception:
            pass
        self.queue_draw()
        return True


def main():
    if not check_x():
        return
    win = TopBar()
    win.add_events(Gdk.EventMask.POINTER_MOTION_MASK
                   | Gdk.EventMask.LEAVE_NOTIFY_MASK)
    win.connect("motion-notify-event", win._motion)
    win.connect("leave-notify-event",
                lambda *_: setattr(win, "_hover", None) or win.queue_draw())
    win.connect("destroy", Gtk.main_quit)
    signal.signal(signal.SIGINT, lambda *_: Gtk.main_quit())
    Gtk.main()


if __name__ == "__main__":
    import sys
    main()

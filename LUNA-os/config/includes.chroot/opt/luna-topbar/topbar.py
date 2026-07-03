#!/usr/bin/env python3
"""Luna Top Bar - Custom top bar for Luna OS"""

import os
import subprocess
import time
import shutil
from datetime import datetime
import gi
gi.require_version('Gtk', '3.0')
gi.require_version('Gdk', '3.0')
from gi.repository import Gtk, Gdk, GLib, Pango

try:
    import psutil
    HAS_PSUTIL = True
except ImportError:
    HAS_PSUTIL = False

BAR_HEIGHT = 48
ACCENT = "#a855f7"
BG_COLOR = (15/255, 17/255, 23/255, 0.92)
TEXT_COLOR = "#E8EAF0"
TEXT_SECONDARY = "#8b93a7"

def get_wifi_status():
    try:
        result = subprocess.run(['nmcli', '-t', '-f', 'ACTIVE,SSID', 'dev', 'wifi'],
                               capture_output=True, text=True, timeout=2)
        for line in result.stdout.strip().split('\n'):
            if line.startswith('yes:'):
                return {'connected': True, 'ssid': line.split(':', 1)[1]}
        return {'connected': False, 'ssid': ''}
    except:
        return {'connected': False, 'ssid': ''}

def get_volume():
    try:
        result = subprocess.run(['pactl', 'get-sink-volume', '@DEFAULT_SINK@'],
                               capture_output=True, text=True, timeout=2)
        pct = int(''.join(c for c in result.stdout.split('%')[0] if c.isdigit()) or '0')
        result2 = subprocess.run(['pactl', 'get-sink-mute', '@DEFAULT_SINK@'],
                                capture_output=True, text=True, timeout=2)
        muted = 'yes' in result2.stdout.lower()
        return {'level': pct, 'muted': muted}
    except:
        return {'level': 0, 'muted': False}

def get_bluetooth_status():
    try:
        result = subprocess.run(['bluetoothctl', 'show'], capture_output=True, text=True, timeout=2)
        for line in result.stdout.split('\n'):
            if 'Powered:' in line:
                return 'yes' in line.lower()
        return False
    except:
        return False

def get_battery():
    try:
        with open('/sys/class/power_supply/BAT0/capacity') as f:
            level = int(f.read().strip())
        with open('/sys/class/power_supply/BAT0/status') as f:
            charging = 'charging' in f.read().lower()
        return {'level': level, 'charging': charging, 'exists': True}
    except:
        return {'level': -1, 'charging': False, 'exists': False}

def get_workspaces():
    try:
        result = subprocess.run(['xdotool', 'get_num_desktops'], capture_output=True, text=True, timeout=2)
        total = int(result.stdout.strip())
        result2 = subprocess.run(['xdotool', 'get_current_desktop'], capture_output=True, text=True, timeout=2)
        current = int(result2.stdout.strip()) if result2.returncode == 0 else 0
        return {'current': current, 'total': total}
    except:
        return {'current': 0, 'total': 4}

def get_notification_count():
    return 0


class TopBar(Gtk.Window):
    def __init__(self):
        super().__init__(type=Gtk.WindowType.POPUP)
        self.set_decorated(False)
        self.set_app_paintable(True)
        self.set_keep_above(True)

        screen = Gdk.Screen.get_default()
        monitor = screen.get_display().get_primary_monitor()
        if not monitor:
            monitor = screen.get_display().get_monitor_at_point(0, 0)
        geo = monitor.get_geometry()
        screen_width = screen.get_width()

        self.set_default_size(screen_width, BAR_HEIGHT)
        self.move(0, 0)

        visual = screen.get_rgba_visual()
        if visual:
            self.set_visual(visual)

        self.connect("draw", self.on_draw)
        self.connect("button-press-event", self.on_click)

        self.events = (Gdk.EventMask.BUTTON_PRESS_MASK |
                       Gdk.EventMask.POINTER_MOTION_MASK)
        self.add_events(self.events)

        self._set_strut()
        self.show_all()

        GLib.timeout_add(30000, self.update_clock)
        GLib.timeout_add(10000, self.update_indicators)

        self.clock_text = ""
        self.wifi = get_wifi_status()
        self.volume = get_volume()
        self.bt_on = get_bluetooth_status()
        self.battery = get_battery()
        self.notif_count = get_notification_count()
        self.ws = get_workspaces()

        self.update_clock()
        self.update_indicators()

    def _set_strut(self):
        screen = self.get_screen()
        w = screen.get_width()
        try:
            subprocess.run([
                'xprop', '-root', '-f', '_NET_WM_STRUT_PARTIAL', '32c',
                '-set', '_NET_WM_STRUT_PARTIAL',
                f'0,0,0,0,0,{BAR_HEIGHT},0,0,0,0,0,0'
            ], timeout=2, capture_output=True)
        except:
            pass

    def update_clock(self):
        now = datetime.now()
        self.clock_text = now.strftime("%a, %b %d  %I:%M %p")
        self.queue_draw()
        return True

    def update_indicators(self):
        self.wifi = get_wifi_status()
        self.volume = get_volume()
        self.bt_on = get_bluetooth_status()
        self.battery = get_battery()
        self.ws = get_workspaces()
        self.queue_draw()
        return True

    def on_draw(self, widget, cr):
        w = self.get_allocated_width()
        h = self.get_allocated_height()

        # Background
        cr.set_source_rgba(*BG_COLOR)
        cr.rectangle(0, 0, w, h)
        cr.fill()

        # Bottom border
        cr.set_source_rgba(30/255, 32/255, 48/255, 0.5)
        cr.set_line_width(1)
        cr.move_to(0, h - 0.5)
        cr.line_to(w, h - 0.5)
        cr.stroke()

        # === LEFT SECTION ===
        # Logo
        cr.set_source_rgb(168/255, 85/255, 247/255)  # #a855f7
        cr.select_font_face("Inter", 0, 1)
        cr.set_font_size(16)
        cr.move_to(16, 32)
        cr.show_text("LUNA OS")

        # Workspace
        ws_x = 130
        cr.set_source_rgb(139/255, 163/255, 178/255)
        cr.set_font_size(12)
        cr.move_to(ws_x, 32)
        cr.show_text(f"Workspace {self.ws['current'] + 1}")

        # === CENTER SECTION ===
        cr.set_source_rgb(232/255, 234/255, 240/255)
        cr.set_font_size(14)
        cr.move_to(w / 2 - 80, 32)
        cr.show_text(self.clock_text)

        # === RIGHT SECTION ===
        rx = w - 20

        # Power button
        cr.set_source_rgb(139/255, 163/255, 178/255)
        cr.set_font_size(16)
        rx -= 20
        cr.move_to(rx, 32)
        cr.show_text("⏻")

        # Notification bell
        rx -= 28
        cr.move_to(rx, 32)
        cr.show_text("🔔")

        # Battery
        if self.battery['exists']:
            rx -= 50
            cr.set_font_size(12)
            color = "#F59E0B" if self.battery['level'] <= 20 else TEXT_COLOR
            cr.set_source_rgb(*self._hex_to_rgb(color))
            cr.move_to(rx, 32)
            cr.show_text(f"{self.battery['level']}%")

        # Bluetooth
        rx -= 28
        bt_color = "#6366F1" if self.bt_on else "#4a4d60"
        cr.set_source_rgb(*self._hex_to_rgb(bt_color))
        cr.set_font_size(14)
        cr.move_to(rx, 32)
        cr.show_text("BT")

        # Volume
        rx -= 40
        vol_icon = "🔇" if self.volume['muted'] else "🔊"
        cr.set_source_rgb(232/255, 234/255, 240/255)
        cr.move_to(rx, 32)
        cr.show_text(vol_icon)

        # WiFi
        rx -= 30
        wifi_color = "#6366F1" if self.wifi['connected'] else "#EF4444"
        cr.set_source_rgb(*self._hex_to_rgb(wifi_color))
        cr.set_font_size(12)
        cr.move_to(rx, 32)
        cr.show_text("WiFi" if self.wifi['connected'] else "!!")

    def _hex_to_rgb(self, hex_color):
        h = hex_color.lstrip('#')
        return tuple(int(h[i:i+2], 16)/255 for i in (0, 2, 4))

    def on_click(self, widget, event):
        w = self.get_allocated_width()
        rx = w - 20

        # Power button area
        if rx - 20 <= event.x <= rx + 10:
            self.show_power_menu(event)
            return

        # Clock area
        if w/2 - 100 <= event.x <= w/2 + 100:
            try:
                subprocess.Popen(['orage'])
            except:
                pass
            return

        # Logo area
        if event.x <= 130:
            try:
                subprocess.Popen(['python3', '/opt/luna-settings/settings.py'])
            except:
                pass
            return

    def show_power_menu(self, event):
        menu = Gtk.Menu()

        items = [
            ("Lock Screen", lambda: subprocess.Popen(['xflock4'])),
            ("Sleep", lambda: subprocess.Popen(['systemctl', 'suspend'])),
            ("Restart", lambda: subprocess.Popen(['systemctl', 'reboot'])),
            ("Shut Down", lambda: subprocess.Popen(['systemctl', 'poweroff'])),
        ]

        for label, action in items:
            item = Gtk.MenuItem(label=label)
            item.connect("activate", lambda w, a=action: a())
            menu.append(item)

        menu.show_all()
        menu.popup_at_pointer(event)


def main():
    bar = TopBar()
    Gtk.main()

if __name__ == '__main__':
    main()

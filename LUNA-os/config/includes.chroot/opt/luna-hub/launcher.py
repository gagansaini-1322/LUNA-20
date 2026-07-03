#!/usr/bin/env python3
"""Luna Hub - GTK3 Launcher with WebKit2"""

import subprocess
import sys
import signal
import gi
gi.require_version('Gtk', '3.0')
gi.require_version('WebKit2', '4.1')
from gi.repository import Gtk, WebKit2

class LunaHubWindow(Gtk.Window):
    def __init__(self):
        super().__init__(title="Luna Hub")
        self.set_default_size(420, 600)
        self.set_resizable(False)
        self.set_decorated(False)
        self.set_position(Gtk.WindowPosition.CENTER)

        # Start backend
        self.backend_proc = subprocess.Popen(
            [sys.executable, '/opt/luna-hub/backend.py'],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )

        # WebKit view
        web_settings = WebKit2.Settings.new()
        web_settings.set_enable_smooth_scrolling(True)

        self.webview = WebKit2.WebView.new_with_settings(web_settings)
        self.webview.load_uri('http://127.0.0.1:5151/')

        self.add(self.webview)
        self.connect('destroy', self.on_destroy)
        self.show_all()

    def on_destroy(self, widget):
        if self.backend_proc:
            self.backend_proc.terminate()
            self.backend_proc.wait()
        Gtk.main_quit()

def main():
    signal.signal(signal.SIGINT, signal.SIG_DFL)
    window = LunaHubWindow()
    Gtk.main()

if __name__ == '__main__':
    main()

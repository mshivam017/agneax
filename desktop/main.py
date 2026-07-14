import sys
import os
import json
import socket
import threading
import time
import ctypes
from PySide6.QtCore import QObject, Slot, Signal, Property, QTimer
from PySide6.QtWidgets import QApplication
from PySide6.QtQml import QQmlApplicationEngine

class SettingsManager:
    @staticmethod
    def get_config_path():
        path = os.path.expanduser("~/.config/agneax")
        os.makedirs(path, exist_ok=True)
        return os.path.join(path, "settings.json")

    @staticmethod
    def load_settings(category, default_settings):
        config_file = SettingsManager.get_config_path()
        if os.path.exists(config_file):
            try:
                with open(config_file, "r") as f:
                    data = json.load(f)
                    if category in data:
                        default_settings.update(data[category])
            except Exception as e:
                print(f"Error loading persistent settings: {e}")
        return default_settings

    @staticmethod
    def save_settings(category, settings):
        config_file = SettingsManager.get_config_path()
        data = {}
        if os.path.exists(config_file):
            try:
                with open(config_file, "r") as f:
                    data = json.load(f)
            except Exception:
                pass
        data[category] = settings
        try:
            with open(config_file, "w") as f:
                json.dump(data, f, indent=4)
        except Exception as e:
            print(f"Error saving settings: {e}")

class SystemBridge(QObject):
    telemetryUpdated = Signal(str)
    wallpaperPathChanged = Signal(str)
    themeChanged = Signal(str)
    accentColorChanged = Signal(str)

    def __init__(self):
        super().__init__()
        self._telemetry = {
            "cpu_usage": 0.0,
            "total_mem": 8589934592,
            "used_mem": 4294967296,
            "mem_usage_pct": 50.0,
            "cpu_temp": 45.0,
            "disks": [{"mount_point": "/", "total": 128000000000, "available": 64000000000}],
            "battery": {"pct": 80, "charging": True},
            "uptime": 3600
        }
        self.running = True
        self.lock = threading.Lock()
        
        # Try to load the C++ layout library
        self.lib = None
        cpp_lib_path = "/usr/lib/libcompositor_helper.so"
        if os.path.exists(cpp_lib_path):
            try:
                self.lib = ctypes.CDLL(cpp_lib_path)
                # Define ctypes structs and signatures
                class WindowGeometry(ctypes.Structure):
                    _fields_ = [
                        ("x", ctypes.c_int),
                        ("y", ctypes.c_int),
                        ("width", ctypes.c_int),
                        ("height", ctypes.c_int)
                    ]
                self.WindowGeometry = WindowGeometry
                
                self.lib.calculate_tiling_grid.argtypes = [
                    ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_int
                ]
                self.lib.calculate_tiling_grid.restype = WindowGeometry
                
                self.lib.calculate_snap_geometry.argtypes = [
                    ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_int
                ]
                self.lib.calculate_snap_geometry.restype = WindowGeometry
                print("Loaded C++ Layout Helper library successfully.")
            except Exception as e:
                print(f"Error loading C++ library: {e}")
        else:
            print("C++ helper library not found. Falling back to Python calculations.")

        # Start thread to read daemon telemetry
        self.telemetry_thread = threading.Thread(target=self._telemetry_worker, daemon=True)
        self.telemetry_thread.start()

        # Persistent settings poller (Step 2)
        self._appearance = SettingsManager.load_settings("appearance", {
            "theme": "Dark Mode",
            "accent_color": "#00F2FE",
            "wallpaper": "Sleek Carbon Glass",
        })
        self._settings_mtime = 0
        self._settings_timer = QTimer(self)
        self._settings_timer.setInterval(1000)
        self._settings_timer.timeout.connect(self._check_settings_update)
        self._settings_timer.start()

        # Trigger startup chime (Step 5)
        if sys.platform != "win32":
            threading.Thread(target=self._play_startup_sound, daemon=True).start()

    def _play_startup_sound(self):
        # Look for custom sound first
        custom_sound = "/opt/agneax/branding/startup.wav"
        if os.path.exists(custom_sound):
            os.system(f"aplay {custom_sound} > /dev/null 2>&1")
        else:
            # Fallback to debian system sounds if available
            system_sound = "/usr/share/sounds/alsa/Front_Center.wav"
            if os.path.exists(system_sound):
                os.system(f"aplay {system_sound} > /dev/null 2>&1")

    def _telemetry_worker(self):
        while self.running:
            try:
                # Check for UNIX domain socket on Linux (Step 6)
                if sys.platform != "win32" and os.path.exists("/run/agneax-core.sock"):
                    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
                    s.connect("/run/agneax-core.sock")
                else:
                    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                    s.connect(("127.0.0.1", 9090))

                with s:
                    s.settimeout(2.0)
                    while self.running:
                        req = json.dumps({"method": "get_telemetry"})
                        s.sendall(req.encode('utf-8'))
                        data = s.recv(4096)
                        if not data:
                            break
                        
                        # Parse responses split by newline
                        for line in data.decode('utf-8').split('\n'):
                            if not line.strip():
                                continue
                            try:
                                res = json.loads(line)
                                if res.get("status") == "success":
                                    with self.lock:
                                        self._telemetry = res.get("data")
                                    self.telemetryUpdated.emit(json.dumps(self._telemetry))
                            except Exception:
                                pass
                        time.sleep(1.0)
            except Exception:
                # Daemon is not running, fall back to simulated telemetry
                self._simulate_telemetry()
                time.sleep(1.0)

    def _simulate_telemetry(self):
        # Graceful simulation to allow direct running of the UI on Windows/Mac
        import random
        with self.lock:
            self._telemetry["cpu_usage"] = round(random.uniform(2.0, 15.0), 1)
            self._telemetry["cpu_temp"] = round(40.0 + random.uniform(0, 10), 1)
            # Memory variation
            used = self._telemetry["used_mem"] + int(random.uniform(-50000000, 50000000))
            used = max(1000000000, min(used, self._telemetry["total_mem"]))
            self._telemetry["used_mem"] = used
            self._telemetry["mem_usage_pct"] = round((used / self._telemetry["total_mem"]) * 100.0, 1)
            
            # Uptime increments
            self._telemetry["uptime"] += 1
            
            # Battery level drops/changes
            pct = self._telemetry["battery"]["pct"]
            if random.random() > 0.95:
                pct = max(10, pct - 1)
                self._telemetry["battery"]["pct"] = pct

        self.telemetry_thread_safe_emit()

    def telemetry_thread_safe_emit(self):
        # Helper to push updates to front-end thread
        self.telemetryUpdated.emit(json.dumps(self._telemetry))

    @Slot(result=str)
    def getTelemetry(self):
        with self.lock:
            return json.dumps(self._telemetry)

    def _check_settings_update(self):
        config_file = SettingsManager.get_config_path()
        if os.path.exists(config_file):
            try:
                mtime = os.path.getmtime(config_file)
                if mtime > self._settings_mtime:
                    self._settings_mtime = mtime
                    # Reload settings
                    self._appearance = SettingsManager.load_settings("appearance", {
                        "theme": "Dark Mode",
                        "accent_color": "#00F2FE",
                        "wallpaper": "Sleek Carbon Glass",
                    })
                    # Emit signals to QML
                    self.wallpaperPathChanged.emit(self.wallpaperPath)
                    self.themeChanged.emit(self._appearance.get("theme", "Dark Mode"))
                    self.accentColorChanged.emit(self._appearance.get("accent_color", "#00F2FE"))
            except Exception as e:
                print(f"Error checking settings updates: {e}")

    @Property(str, notify=wallpaperPathChanged)
    def wallpaperPath(self):
        # Determine actual wallpaper file based on name
        wp_name = self._appearance.get("wallpaper", "Sleek Carbon Glass")
        
        # Check if we have PNG/SVG wallpapers
        opt_dir = "/opt/agneax/branding"
        local_dir = os.path.join(os.path.dirname(__file__), "..", "branding")
        
        # Map wallpaper names to filenames
        wp_files = {
            "Sleek Carbon Glass": "wallpaper.png",
            "Aurora Wave": "wallpaper.svg",
            "Neon Horizon": "wallpaper.svg"
        }
        
        filename = wp_files.get(wp_name, "wallpaper.png")
        
        # Check in opt first (inside live ISO)
        opt_path = os.path.join(opt_dir, filename)
        if os.path.exists(opt_path):
            return "file://" + opt_path
            
        # Check in local repository
        local_path = os.path.join(local_dir, filename)
        if os.path.exists(local_path):
            formatted_path = os.path.abspath(local_path).replace("\\", "/")
            return "file:///" + formatted_path
            
        # Hard fallback to wallpaper.svg if PNG does not exist yet
        fallback_file = "wallpaper.svg"
        if os.path.exists(os.path.join(opt_dir, fallback_file)):
            return "file://" + os.path.join(opt_dir, fallback_file)
        formatted_path = os.path.abspath(os.path.join(local_dir, fallback_file)).replace("\\", "/")
        return "file:///" + formatted_path

    @Property(str, notify=themeChanged)
    def theme(self):
        return self._appearance.get("theme", "Dark Mode")

    @Property(str, notify=accentColorChanged)
    def accentColor(self):
        return self._appearance.get("accent_color", "#00F2FE")

    # Exposed Window management layout calculators (utilizes C++ libraries or Python fallback)
    @Slot(int, int, int, int, int, int, result=str)
    def calculateTilingGrid(self, screen_w, screen_h, taskbar_h, count, gap, index):
        if self.lib:
            try:
                g = self.lib.calculate_tiling_grid(screen_w, screen_h, taskbar_h, count, gap, index)
                return json.dumps({"x": g.x, "y": g.y, "width": g.width, "height": g.height})
            except Exception as e:
                print("C++ call failed, falling back to python:", e)
        
        # Python fallback calculation
        import math
        usable_h = screen_h - taskbar_h
        cols = math.ceil(math.sqrt(count))
        rows = math.ceil(count / cols)
        col_w = (screen_w - (gap * (cols + 1))) // cols
        row_h = (usable_h - (gap * (rows + 1))) // rows
        
        col_idx = index % cols
        row_idx = index // cols
        
        x = gap + col_idx * (col_w + gap)
        y = gap + row_idx * (row_h + gap)
        w = col_w
        h = row_h
        
        if row_idx == rows - 1:
            remaining = count - (row_idx * cols)
            if remaining < cols:
                col_w = (screen_w - (gap * (remaining + 1))) // remaining
                x = gap + col_idx * (col_w + gap)
                w = col_w

        return json.dumps({"x": x, "y": y, "width": w, "height": h})

    @Slot(int, int, int, int, result=str)
    def calculateSnapGeometry(self, screen_w, screen_h, taskbar_h, direction):
        if self.lib:
            try:
                g = self.lib.calculate_snap_geometry(screen_w, screen_h, taskbar_h, direction)
                return json.dumps({"x": g.x, "y": g.y, "width": g.width, "height": g.height})
            except Exception as e:
                print("C++ call failed, falling back to python:", e)

        # Python fallback
        half_w = screen_w // 2
        half_h = (screen_h - taskbar_h) // 2
        
        x, y = 0, 0
        w, h = screen_w, screen_h - taskbar_h
        
        if direction == 1: # Left
            w = half_w
        elif direction == 2: # Right
            x = half_w
            w = half_w
        elif direction == 3: # Top-Left
            w = half_w
            h = half_h
        elif direction == 4: # Top-Right
            x = half_w
            w = half_w
            h = half_h
        elif direction == 5: # Bottom-Left
            y = half_h
            w = half_w
            h = half_h
        elif direction == 6: # Bottom-Right
            x = half_w
            y = half_h
            w = half_w
            h = half_h
            
        return json.dumps({"x": x, "y": y, "width": w, "height": h})

    @Slot(str)
    def launchApp(self, app_name):
        print(f"Launching application safely: {app_name}")
        import subprocess

        # Strict allowlist of commands to execute (Step 4)
        allowlist = {
            "control-center": ["python3", "../control-center/main.py"],
            "store": ["python3", "../store/main.py"],
            "installer": ["python3", "../installer/main.py"],
            "terminal": ["python3", "terminal.py"],
            "file-manager": ["python3", "file_manager.py"],
            "firefox": ["firefox"],
            "vlc": ["vlc"],
            "steam": ["steam"],
            "discord": ["discord"]
        }

        if app_name in allowlist:
            try:
                subprocess.Popen(allowlist[app_name], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                print(f"Launched application: {app_name}")
            except Exception as e:
                print(f"Error launching {app_name}: {e}")
        else:
            print(f"Blocked attempt to launch non-allowlisted application: {app_name}")

def main():
    app = QApplication(sys.argv)
    app.setApplicationName("Agneax Desktop")
    app.setOrganizationName("Agneax")
    
    bridge = SystemBridge()
    
    engine = QQmlApplicationEngine()
    engine.rootContext().setContextProperty("systemBridge", bridge)
    
    # Load QML file
    qml_file = os.path.join(os.path.dirname(__file__), "qml", "DesktopShell.qml")
    engine.load(qml_file)
    
    if not engine.rootObjects():
        sys.exit(-1)
        
    sys.exit(app.exec())

if __name__ == "__main__":
    main()

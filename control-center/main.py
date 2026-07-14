import sys
import os
import json
import socket
from PySide6.QtCore import QObject, Slot, Signal, Property
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

class SettingsBridge(QObject):
    settingsChanged = Signal(str)

    def __init__(self):
        super().__init__()
        # Default appearance configurations (merged with persistent settings.json)
        self._appearance = SettingsManager.load_settings("appearance", {
            "theme": "Dark Mode",
            "accent_color": "#00F2FE",
            "wallpaper": "Sleek Carbon Glass",
            "font_size": 12
        })
        self._network = SettingsManager.load_settings("network", {
            "wifi_enabled": True,
            "connected_ssid": "Agneax_Secure_5G",
            "ip_address": "192.168.1.144"
        })
        self._firewall = SettingsManager.load_settings("firewall", {
            "enabled": True,
            "incoming": "Deny",
            "outgoing": "Allow"
        })

    @Slot(result=str)
    def getAppearanceSettings(self):
        return json.dumps(self._appearance)

    @Slot(result=str)
    def getNetworkSettings(self):
        return json.dumps(self._network)

    @Slot(result=str)
    def getFirewallSettings(self):
        return json.dumps(self._firewall)

    @Slot(str, str)
    def saveAppearance(self, key, value):
        self._appearance[key] = value
        SettingsManager.save_settings("appearance", self._appearance)
        self.settingsChanged.emit(json.dumps({"category": "appearance", "settings": self._appearance}))
        print(f"Appearance setting updated: {key} -> {value}")

    @Slot(bool)
    def setWifiEnabled(self, enabled):
        self._network["wifi_enabled"] = enabled
        if not enabled:
            self._network["connected_ssid"] = "Disconnected"
            self._network["ip_address"] = "N/A"
        else:
            self._network["connected_ssid"] = "Agneax_Secure_5G"
            self._network["ip_address"] = "192.168.1.144"
        SettingsManager.save_settings("network", self._network)
        self.settingsChanged.emit(json.dumps({"category": "network", "settings": self._network}))

    @Slot(bool)
    def setFirewallEnabled(self, enabled):
        self._firewall["enabled"] = enabled
        # Try to contact Rust daemon to make live UFW modification
        try:
            # Check for UNIX domain socket on Linux (Step 6)
            if sys.platform != "win32" and os.path.exists("/run/agneax-core.sock"):
                s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
                s.connect("/run/agneax-core.sock")
            else:
                s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                s.connect(("127.0.0.1", 9090))

            with s:
                s.settimeout(1.0)
                req = json.dumps({"method": "toggle_firewall", "params": {"enable": enabled}})
                s.sendall(req.encode('utf-8'))
                res = s.recv(1024)
                print(f"Daemon response: {res.decode('utf-8')}")
        except Exception as e:
            print(f"Could not connect to Rust daemon for firewall modification, mocked: {e}")

        SettingsManager.save_settings("firewall", self._firewall)
        self.settingsChanged.emit(json.dumps({"category": "firewall", "settings": self._firewall}))

    @Slot(result=str)
    def getSystemSpecs(self):
        import platform
        
        specs = {
            "os": "Agneax OS 1.0.0 Alpha",
            "kernel": f"Linux {platform.release()}" if sys.platform != "win32" else f"Windows {platform.release()}",
            "cpu": "Unknown Processor",
            "ram": "8.0 GB"
        }
        
        # Read CPU model name and Memory size on Linux
        if sys.platform != "win32":
            try:
                if os.path.exists("/proc/cpuinfo"):
                    with open("/proc/cpuinfo", "r") as f:
                        for line in f:
                            if "model name" in line:
                                specs["cpu"] = line.split(":", 1)[1].strip()
                                break
                if os.path.exists("/proc/meminfo"):
                    with open("/proc/meminfo", "r") as f:
                        for line in f:
                            if "MemTotal" in line:
                                kb = int(line.split()[1])
                                specs["ram"] = f"{round(kb / (1024 * 1024), 1)} GB"
                                break
            except Exception:
                pass
        else:
            # Fallback values for Windows dev environment
            specs["cpu"] = platform.processor() or "Intel Core i7"
            try:
                import ctypes
                class MEMORYSTATUSEX(ctypes.Structure):
                    _fields_ = [
                        ("dwLength", ctypes.c_ulong),
                        ("dwMemoryLoad", ctypes.c_ulong),
                        ("ullTotalPhys", ctypes.c_ulonglong),
                        ("ullAvailPhys", ctypes.c_ulonglong),
                        ("ullTotalPageFile", ctypes.c_ulonglong),
                        ("ullAvailPageFile", ctypes.c_ulonglong),
                        ("ullTotalVirtual", ctypes.c_ulonglong),
                        ("ullAvailVirtual", ctypes.c_ulonglong),
                        ("ullAvailExtendedVirtual", ctypes.c_ulonglong),
                    ]
                stat = MEMORYSTATUSEX()
                stat.dwLength = ctypes.sizeof(stat)
                ctypes.windll.kernel32.GlobalMemoryStatusEx(ctypes.byref(stat))
                specs["ram"] = f"{round(stat.ullTotalPhys / (1024 * 1024 * 1024), 1)} GB"
            except Exception:
                specs["ram"] = "16.0 GB"
                
        return json.dumps(specs)

def main():
    app = QApplication(sys.argv)
    app.setApplicationName("Agneax Control Center")
    app.setOrganizationName("Agneax")
    
    bridge = SettingsBridge()
    
    engine = QQmlApplicationEngine()
    engine.rootContext().setContextProperty("settingsBridge", bridge)
    
    qml_file = os.path.join(os.path.dirname(__file__), "qml", "ControlCenter.qml")
    engine.load(qml_file)
    
    if not engine.rootObjects():
        sys.exit(-1)
        
    sys.exit(app.exec())

if __name__ == "__main__":
    main()

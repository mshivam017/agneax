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
    wifiConnectCompleted = Signal(str, bool, str) # ssid, success, error_message
    devToolInstallCompleted = Signal(str, bool, str) # tool_id, success, message

    def __init__(self):
        super().__init__()
        # Default appearance configurations (merged with persistent settings.json)
        self._appearance = SettingsManager.load_settings("appearance", {
            "theme": "Dark Mode",
            "accent_color": "#00F2FE",
            "wallpaper": "Sleek Carbon Glass",
            "font_size": 12,
            "taskbar_layout": "Panel",
            "night_light": 0.0
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
            
        if sys.platform != "win32":
            import subprocess
            status = "on" if enabled else "off"
            try:
                subprocess.run(["nmcli", "radio", "wifi", status], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            except Exception:
                pass

        SettingsManager.save_settings("network", self._network)
        self.settingsChanged.emit(json.dumps({"category": "network", "settings": self._network}))

    @Slot(result=str)
    def getWifiNetworks(self):
        if sys.platform == "win32":
            # Mock Wi-Fi networks for Windows dev environment
            return json.dumps([
                {"ssid": "Agneax_Secure_5G", "signal": 95, "secured": True, "active": True},
                {"ssid": "Airport_Free_WiFi", "signal": 60, "secured": False, "active": False},
                {"ssid": "Home_Net_2.4G", "signal": 80, "secured": True, "active": False},
                {"ssid": "Coffee_Shop_5G", "signal": 45, "secured": True, "active": False}
            ])
            
        import subprocess
        try:
            # Re-scan WiFi access points
            subprocess.run(["nmcli", "device", "wifi", "rescan"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            res = subprocess.run(
                ["nmcli", "-t", "-f", "SSID,SIGNAL,SECURITY,ACTIVE", "device", "wifi", "list"],
                capture_output=True,
                text=True
            )
            networks = []
            seen_ssids = set()
            if res.returncode == 0:
                for line in res.stdout.strip().split("\n"):
                    if not line.strip():
                        continue
                    parts = line.split(":")
                    if len(parts) >= 4:
                        ssid = parts[0].strip()
                        if not ssid or ssid in seen_ssids:
                            continue
                        seen_ssids.add(ssid)
                        
                        try:
                            signal = int(parts[1].strip())
                        except ValueError:
                            signal = 50
                            
                        secured = "WPA" in parts[2] or "WEP" in parts[2]
                        active = parts[3].strip().lower() == "yes"
                        
                        networks.append({
                            "ssid": ssid,
                            "signal": signal,
                            "secured": secured,
                            "active": active
                        })
            networks.sort(key=lambda x: (x["active"], x["signal"]), reverse=True)
            if not networks:
                return json.dumps([
                    {"ssid": "Agneax_Secure_5G", "signal": 90, "secured": True, "active": True},
                    {"ssid": "Guest_Net", "signal": 70, "secured": False, "active": False}
                ])
            return json.dumps(networks)
        except Exception as e:
            print(f"Error listing WiFi: {e}")
            return json.dumps([])

    @Slot(str, str)
    def connectToWifi(self, ssid, password):
        print(f"Attempting connection to WiFi: {ssid}")
        threading.Thread(target=self._wifi_connect_worker, args=(ssid, password), daemon=True).start()

    def _wifi_connect_worker(self, ssid, password):
        if sys.platform == "win32":
            time.sleep(2.0)
            self._network["connected_ssid"] = ssid
            self._network["wifi_enabled"] = True
            self._network["ip_address"] = "192.168.1.144"
            SettingsManager.save_settings("network", self._network)
            self.settingsChanged.emit(json.dumps({"category": "network", "settings": self._network}))
            self.wifiConnectCompleted.emit(ssid, True, "Mock connection successful")
            return

        import subprocess
        try:
            cmd = ["nmcli", "device", "wifi", "connect", ssid]
            if password:
                cmd.extend(["password", password])
            res = subprocess.run(cmd, capture_output=True, text=True)
            if res.returncode == 0:
                self._network["connected_ssid"] = ssid
                self._network["wifi_enabled"] = True
                ip_res = subprocess.run(["hostname", "-I"], capture_output=True, text=True)
                ip = ip_res.stdout.strip().split()[0] if ip_res.stdout.strip() else "192.168.1.100"
                self._network["ip_address"] = ip
                
                SettingsManager.save_settings("network", self._network)
                self.settingsChanged.emit(json.dumps({"category": "network", "settings": self._network}))
                self.wifiConnectCompleted.emit(ssid, True, "Connected successfully")
            else:
                self.wifiConnectCompleted.emit(ssid, False, res.stderr.strip() or "Connection failed")
        except Exception as e:
            self.wifiConnectCompleted.emit(ssid, False, str(e))

    @Slot(result=int)
    def getVolume(self):
        if sys.platform == "win32":
            return 50
        import subprocess
        try:
            res = subprocess.run(["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"], capture_output=True, text=True)
            if res.returncode == 0:
                parts = res.stdout.strip().split()
                if len(parts) >= 2:
                    val = float(parts[1])
                    return int(val * 100)
        except Exception:
            pass
        return 70

    @Slot(int)
    def setVolume(self, pct):
        pct = max(0, min(100, pct))
        print(f"Setting system volume: {pct}%")
        if sys.platform != "win32":
            import subprocess
            try:
                val = pct / 100.0
                subprocess.run(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", f"{val}"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            except Exception as e:
                print(f"Error setting volume: {e}")

    @Slot(str)
    def installDevTool(self, tool_id):
        print(f"Triggering developer tool installation: {tool_id}")
        threading.Thread(target=self._install_dev_tool_worker, args=(tool_id,), daemon=True).start()

    def _install_dev_tool_worker(self, tool_id):
        package_map = {
            "git": "git build-essential",
            "node": "nodejs npm",
            "rust": "cargo",
            "docker": "docker.io"
        }
        
        pkg_list = package_map.get(tool_id)
        if not pkg_list:
            self.devToolInstallCompleted.emit(tool_id, False, "Unknown developer tool ID")
            return

        if sys.platform == "win32":
            time.sleep(3.0)
            self.devToolInstallCompleted.emit(tool_id, True, "Mock dev tool install successful on Windows")
            return

        try:
            if os.path.exists("/run/agneax-core.sock"):
                s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
                s.connect("/run/agneax-core.sock")
            else:
                s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                s.connect(("127.0.0.1", 9090))

            with s:
                s.settimeout(60.0)
                req = json.dumps({"method": "install_package", "params": {"package_id": pkg_list}})
                s.sendall(req.encode('utf-8'))
                res = s.recv(4096)
                resp = json.loads(res.decode('utf-8').strip())
                if resp.get("status") == "success":
                    self.devToolInstallCompleted.emit(tool_id, True, f"Installed {tool_id} successfully")
                else:
                    self.devToolInstallCompleted.emit(tool_id, False, resp.get("message", "Installation failed"))
        except Exception as e:
            self.devToolInstallCompleted.emit(tool_id, False, str(e))

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

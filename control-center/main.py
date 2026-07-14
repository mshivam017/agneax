import sys
import os
import json
import socket
from PySide6.QtCore import QObject, Slot, Signal
from PySide6.QtWidgets import QApplication
from PySide6.QtQml import QQmlApplicationEngine

class SettingsBridge(QObject):
    settingsChanged = Signal(str)

    def __init__(self):
        super().__init__()
        # Default appearance configurations
        self._appearance = {
            "theme": "Dark Mode",
            "accent_color": "#00F2FE",
            "wallpaper": "Sleek Carbon Glass",
            "font_size": 12
        }
        self._network = {
            "wifi_enabled": True,
            "connected_ssid": "Agneax_Secure_5G",
            "ip_address": "192.168.1.144"
        }
        self._firewall = {
            "enabled": True,
            "incoming": "Deny",
            "outgoing": "Allow"
        }

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
        self.settingsChanged.emit(json.dumps({"category": "network", "settings": self._network}))

    @Slot(bool)
    def setFirewallEnabled(self, enabled):
        self._firewall["enabled"] = enabled
        # Try to contact Rust daemon to make live UFW modification
        try:
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
                s.settimeout(1.0)
                s.connect(("127.0.0.1", 9090))
                req = json.dumps({"method": "toggle_firewall", "params": {"enable": enabled}})
                s.sendall(req.encode('utf-8'))
                res = s.recv(1024)
                print(f"Daemon response: {res.decode('utf-8')}")
        except Exception as e:
            print(f"Could not connect to Rust daemon for firewall modification, mocked: {e}")

        self.settingsChanged.emit(json.dumps({"category": "firewall", "settings": self._firewall}))

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

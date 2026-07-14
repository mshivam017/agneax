import sys
import os
import json
import socket
import threading
import time
from PySide6.QtCore import QObject, Slot, Signal
from PySide6.QtWidgets import QApplication
from PySide6.QtQml import QQmlApplicationEngine

class StoreBridge(QObject):
    installProgress = Signal(str, float) # app_id, percentage
    installCompleted = Signal(str, bool) # app_id, success

    def __init__(self):
        super().__init__()
        # Simulated packages directory catalog database
        self._catalog = [
            {"id": "firefox", "name": "Firefox Web Browser", "icon": "🌐", "desc": "Fast, secure, and private web browser built by Mozilla.", "category": "Internet", "size": "82 MB", "installed": True, "flatpak": False},
            {"id": "vscode", "name": "Visual Studio Code", "icon": "💻", "desc": "Premium code editor optimized for building modern web and cloud applications.", "category": "Developer", "size": "95 MB", "installed": False, "flatpak": True},
            {"id": "gimp", "name": "GIMP Image Editor", "icon": "🎨", "desc": "GNU Image Manipulation Program for professional photo editing and drawing.", "category": "Graphics", "size": "120 MB", "installed": False, "flatpak": False},
            {"id": "blender", "name": "Blender 3D Suite", "icon": "🎬", "desc": "Open-source 3D creation suite supporting modeling, rigging, animation, and rendering.", "category": "Graphics", "size": "340 MB", "installed": False, "flatpak": True},
            {"id": "steam", "name": "Steam Gaming Client", "icon": "🎮", "desc": "The ultimate gaming platform for playing, creating, and discussing games.", "category": "Gaming", "size": "45 MB", "installed": False, "flatpak": False},
            {"id": "libreoffice", "name": "LibreOffice Writer", "icon": "📝", "desc": "Powerful office suite with clean interface and rich features.", "category": "Productivity", "size": "210 MB", "installed": True, "flatpak": False},
            {"id": "vlc", "name": "VLC Media Player", "icon": "🎥", "desc": "Free and open-source cross-platform multimedia player that plays most multimedia files.", "category": "Multimedia", "size": "38 MB", "installed": True, "flatpak": False},
            {"id": "discord", "name": "Discord Chat Client", "icon": "💬", "desc": "Talk, chat, and hang out with friends in server communities.", "category": "Internet", "size": "65 MB", "installed": False, "flatpak": True}
        ]

    @Slot(result=str)
    def getCatalog(self):
        return json.dumps(self._catalog)

    @Slot(str)
    def installApp(self, app_id):
        print(f"Store installing: {app_id}")
        # Spawn install worker thread to prevent GUI blocking
        threading.Thread(target=self._install_worker, args=(app_id,), daemon=True).start()

    @Slot(str)
    def uninstallApp(self, app_id):
        print(f"Store uninstalling: {app_id}")
        threading.Thread(target=self._uninstall_worker, args=(app_id,), daemon=True).start()

    def _install_worker(self, app_id):
        # Notify progress updates
        for progress in range(0, 101, 10):
            self.installProgress.emit(app_id, float(progress))
            time.sleep(0.2)

        # Update local cache state
        success = True
        for app in self._catalog:
            if app["id"] == app_id:
                app["installed"] = True
                break

        # Attempt to make real installation using Rust privileged executor if live
        try:
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
                s.settimeout(2.0)
                s.connect(("127.0.0.1", 9090))
                # Trigger a mock package update cache or install script execution
                req = json.dumps({"method": "pkg_update_cache"})
                s.sendall(req.encode('utf-8'))
                res = s.recv(1024)
                print(f"Daemon install verification: {res.decode('utf-8')}")
        except Exception:
            pass

        self.installCompleted.emit(app_id, success)

    def _uninstall_worker(self, app_id):
        for progress in range(0, 101, 20):
            self.installProgress.emit(app_id, float(progress))
            time.sleep(0.1)

        for app in self._catalog:
            if app["id"] == app_id:
                app["installed"] = False
                break

        self.installCompleted.emit(app_id, False)

def main():
    app = QApplication(sys.argv)
    app.setApplicationName("Agneax Store")
    app.setOrganizationName("Agneax")
    
    bridge = StoreBridge()
    
    engine = QQmlApplicationEngine()
    engine.rootContext().setContextProperty("storeBridge", bridge)
    
    qml_file = os.path.join(os.path.dirname(__file__), "qml", "Store.qml")
    engine.load(qml_file)
    
    if not engine.rootObjects():
        sys.exit(-1)
        
    sys.exit(app.exec())

if __name__ == "__main__":
    main()

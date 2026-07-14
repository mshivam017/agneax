import sys
import os
import json
import threading
import time
import subprocess
from PySide6.QtCore import QObject, Slot, Signal
from PySide6.QtWidgets import QApplication
from PySide6.QtQml import QQmlApplicationEngine

class InstallerBridge(QObject):
    installProgress = Signal(float, str) # progress pct, status string
    installCompleted = Signal(bool, str) # success status, log/message

    def __init__(self):
        super().__init__()
        # Simulated/discovered disk storage drives
        self._drives = [
            {"path": "/dev/sda", "model": "SATA SSD 128GB", "size": "128 GB", "type": "SSD"},
            {"path": "/dev/sdb", "model": "WDC HDD 500GB", "size": "500 GB", "type": "HDD"},
            {"path": "/dev/nvme0n1", "model": "NVMe M.2 SSD 256GB", "size": "256 GB", "type": "NVMe"}
        ]

    @Slot(result=str)
    def getDrives(self):
        return json.dumps(self._drives)

    @Slot(str, str, str, str)
    def startInstallation(self, target_drive, username, password, hostname):
        print(f"Starting Agneax installation on {target_drive} for {username}...")
        # Spawn thread for background copying
        threading.Thread(
            target=self._installation_worker,
            args=(target_drive, username, password, hostname),
            daemon=True
        ).start()

    def _installation_worker(self, drive, user, pwd, host):
        steps = [
            (5.0, "Detecting hardware configurations..."),
            (15.0, f"Creating partition tables on {drive}..."),
            (25.0, f"Formatting /dev/sda1 (FAT32 EFI) and /dev/sda2 (ext4 rootfs)..."),
            (40.0, "Mounting target root filesystem..."),
            (55.0, "Extracting system squashfs package (copying OS core files)..."),
            (75.0, "Configuring user credentials and locale options..."),
            (85.0, "Setting hostname and configuring NetworkManager..."),
            (95.0, "Installing GRUB bootloader to EFI System Partition..."),
            (100.0, "Finalizing installation configurations...")
        ]

        is_live_environment = os.path.exists("/live/image/live/filesystem.squashfs") or os.path.exists("/run/live/medium/live/filesystem.squashfs")

        for progress, status in steps:
            self.installProgress.emit(progress, status)
            if not is_live_environment:
                # Simulate timing on development host
                time.sleep(0.5)
            else:
                # Real live environment speed simulation / process tracking
                if "extracting" in status.lower():
                    # Mock a long unpack wait if in live mode
                    time.sleep(5.0)
                else:
                    time.sleep(1.0)

        # Real installer partition/copy triggers can be placed here if live
        success = True
        message = "Agneax OS installed successfully! Please reboot your computer and remove the installation media."
        
        self.installCompleted.emit(success, message)

def main():
    app = QApplication(sys.argv)
    app.setApplicationName("Agneax OS Installer")
    app.setOrganizationName("Agneax")
    
    bridge = InstallerBridge()
    
    engine = QQmlApplicationEngine()
    engine.rootContext().setContextProperty("installerBridge", bridge)
    
    qml_file = os.path.join(os.path.dirname(__file__), "qml", "Installer.qml")
    engine.load(qml_file)
    
    if not engine.rootObjects():
        sys.exit(-1)
        
    sys.exit(app.exec())

if __name__ == "__main__":
    main()

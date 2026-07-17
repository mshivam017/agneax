import sys
import os
import json
import unittest
from unittest.mock import MagicMock

# Dynamic Mocking of PySide6 to support running tests in headless CI and hosts without Qt installed
try:
    import PySide6
except ImportError:
    class MockQObject:
        def __init__(self, *args, **kwargs):
            pass

    mock_core = MagicMock()
    mock_core.QObject = MockQObject
    mock_core.Slot = lambda *args, **kwargs: (lambda f: f)
    mock_core.Signal = lambda *args, **kwargs: MagicMock()
    mock_core.Property = lambda *args, **kwargs: (lambda f: f)
    
    sys.modules['PySide6'] = MagicMock()
    sys.modules['PySide6.QtCore'] = mock_core
    sys.modules['PySide6.QtWidgets'] = MagicMock()
    sys.modules['PySide6.QtQml'] = MagicMock()

# Append repository root path to system paths for testing
sys.path.append(os.path.join(os.path.dirname(__file__), ".."))

import importlib
desktop_main = importlib.import_module("agneax-desktop.main")
SystemBridge = desktop_main.SystemBridge

store_main = importlib.import_module("agneax-store.main")
StoreBridge = store_main.StoreBridge

installer_main = importlib.import_module("agneax-installer.main")
InstallerBridge = installer_main.InstallerBridge

cc_main = importlib.import_module("agneax-settings.main")
SettingsBridge = cc_main.SettingsBridge

class TestSystemBridge(unittest.TestCase):
    def setUp(self):
        self.bridge = SystemBridge()

    def test_initial_telemetry(self):
        # Validate that telemetry JSON parses correctly and has required fields
        data_str = self.bridge.getTelemetry()
        data = json.loads(data_str)
        self.assertIn("cpu_usage", data)
        self.assertIn("total_mem", data)
        self.assertIn("used_mem", data)
        self.assertIn("battery", data)

    def test_tiling_calculations(self):
        # Test grid math layout fallback calculations
        grid_str = self.bridge.calculateTilingGrid(1920, 1080, 50, 4, 10, 0)
        grid = json.loads(grid_str)
        self.assertEqual(grid["x"], 10)
        self.assertEqual(grid["y"], 10)
        # Dimensions must fit inside bounds
        self.assertLessEqual(grid["width"], 950)
        self.assertLessEqual(grid["height"], 510)

    def test_snap_calculations(self):
        # Test snap coordinates geometries
        snap_str = self.bridge.calculateSnapGeometry(1920, 1080, 50, 1) # Left snap
        snap = json.loads(snap_str)
        self.assertEqual(snap["x"], 0)
        self.assertEqual(snap["width"], 960)
        self.assertEqual(snap["height"], 1030)

    def test_launch_app_allowlist(self):
        # Verify app launcher blocks unallowlisted binaries (Step 4)
        # We can capture standard output to verify block log
        import io
        captured_output = io.StringIO()
        sys.stdout = captured_output
        self.bridge.launchApp("malicious_sh")
        sys.stdout = sys.__stdout__
        self.assertIn("Blocked attempt to launch", captured_output.getvalue())


class TestStoreBridge(unittest.TestCase):
    def setUp(self):
        self.bridge = StoreBridge()

    def test_catalog_retrieval(self):
        # Validate store software package catalog loading
        catalog_str = self.bridge.getCatalog()
        catalog = json.loads(catalog_str)
        self.assertGreater(len(catalog), 0)
        self.assertEqual(catalog[0]["id"], "firefox")

    def test_desktop_shortcut_creation_removal(self):
        # Test that installApp worker creates a desktop shortcut and uninstallApp deletes it (Step 3)
        self.bridge.installApp("firefox")
        import time
        shortcut = os.path.expanduser("~/Desktop/firefox.desktop")
        
        # Poll up to 10 seconds for the shortcut file to be created (prevents VM runner lag)
        created = False
        for _ in range(100):
            if os.path.exists(shortcut):
                created = True
                break
            time.sleep(0.1)
            
        self.assertTrue(created or not os.path.exists(os.path.expanduser("~/Desktop")))
        
        self.bridge.uninstallApp("firefox")
        
        # Poll up to 10 seconds for the shortcut file to be deleted
        deleted = False
        for _ in range(100):
            if not os.path.exists(shortcut):
                deleted = True
                break
            time.sleep(0.1)
            
        self.assertTrue(deleted)


class TestInstallerBridge(unittest.TestCase):
    def setUp(self):
        self.bridge = InstallerBridge()

    def test_drives_discovery(self):
        # Validate targets drives list structure
        drives_str = self.bridge.getDrives()
        drives = json.loads(drives_str)
        self.assertGreater(len(drives), 0)
        self.assertTrue(drives[0]["path"].startswith("/dev/"))


class TestSettingsBridge(unittest.TestCase):
    def setUp(self):
        self.bridge = SettingsBridge()

    def test_appearance_settings(self):
        appearance_str = self.bridge.getAppearanceSettings()
        appearance = json.loads(appearance_str)
        self.assertEqual(appearance["theme"], "Dark Mode")

    def test_firewall_toggle(self):
        self.bridge.setFirewallEnabled(False)
        firewall_str = self.bridge.getFirewallSettings()
        firewall = json.loads(firewall_str)
        self.assertEqual(firewall["enabled"], False)

if __name__ == "__main__":
    unittest.main()

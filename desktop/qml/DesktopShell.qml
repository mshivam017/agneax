import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

ApplicationWindow {
    id: root
    visible: true
    width: 1280
    height: 800
    title: "Agneax Desktop"
    flags: Qt.FramelessWindowHint | Qt.Window | Qt.MaximizeUsingFullscreenGeometryHint

    // App state management
    property bool isDarkMode: true
    property string accentColor: "#00F2FE" // Bright Neon Blue-Teal
    property string glassBgColor: isDarkMode ? "rgba(20, 24, 33, 0.75)" : "rgba(255, 255, 255, 0.75)"
    property string textPrimaryColor: isDarkMode ? "#FFFFFF" : "#1A202C"
    property string textSecondaryColor: isDarkMode ? "#A0AEC0" : "#718096"
    property string cardBgColor: isDarkMode ? "rgba(45, 55, 72, 0.5)" : "rgba(247, 250, 252, 0.8)"
    property string borderColor: isDarkMode ? "rgba(255, 255, 255, 0.08)" : "rgba(0, 0, 0, 0.08)"

    // Open/Close triggers for Panels
    property bool startMenuOpen: false
    property bool quickSettingsOpen: false

    // Telemetry storage (updated from SystemBridge python class)
    property var telemetry: {
        "cpu_usage": 0,
        "mem_usage_pct": 0,
        "cpu_temp": 0,
        "battery": { "pct": 100, "charging": true }
    }

    // Connect to Python SystemBridge
    Connections {
        target: systemBridge
        onTelemetryUpdated: {
            telemetry = JSON.parse(data);
        }
    }

    Component.onCompleted: {
        // Fetch initial telemetry
        telemetry = JSON.parse(systemBridge.getTelemetry());
    }

    // Dynamic abstract wallpaper background
    Image {
        id: bgImage
        anchors.fill: parent
        source: "../branding/wallpaper.svg"
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }

    // Desktop workspace canvas grid
    Grid {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.bottom: panel.top
        anchors.right: parent.right
        anchors.margins: 20
        columns: 1
        rows: 5
        spacing: 15

        // Custom Desktop Shortcuts
        DesktopIcon {
            iconName: "File Manager"
            iconSource: "folder"
            onClicked: systemBridge.launchApp("file-manager")
        }
        DesktopIcon {
            iconName: "Terminal"
            iconSource: "terminal"
            onClicked: systemBridge.launchApp("terminal")
        }
        DesktopIcon {
            iconName: "Control Center"
            iconSource: "settings"
            onClicked: systemBridge.launchApp("control-center")
        }
        DesktopIcon {
            iconName: "App Store"
            iconSource: "shopping-bag"
            onClicked: systemBridge.launchApp("store")
        }
        DesktopIcon {
            iconName: "Install Agneax"
            iconSource: "download"
            accentColor: "#FF5E62"
            onClicked: systemBridge.launchApp("installer")
        }
    }

    // Glassmorphic Start Menu Overlay
    StartMenu {
        id: startMenu
        anchors.bottom: panel.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 12
        visible: root.startMenuOpen
    }

    // Glassmorphic Quick Settings Overlay
    QuickSettings {
        id: quickSettings
        anchors.bottom: panel.top
        anchors.right: parent.right
        anchors.rightMargin: 20
        anchors.bottomMargin: 12
        visible: root.quickSettingsOpen
    }

    // Bottom Taskbar Panel
    Panel {
        id: panel
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 52
    }
}

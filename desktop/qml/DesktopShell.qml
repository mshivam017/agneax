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

    // App state management (bound to persistent SystemBridge settings)
    property bool isDarkMode: systemBridge.theme === "Dark Mode"
    property string accentColor: systemBridge.accentColor
    property string glassBgColor: isDarkMode ? "rgba(20, 24, 33, 0.75)" : "rgba(255, 255, 255, 0.75)"
    property string textPrimaryColor: isDarkMode ? "#FFFFFF" : "#1A202C"
    property string textSecondaryColor: isDarkMode ? "#A0AEC0" : "#718096"
    property string cardBgColor: isDarkMode ? "rgba(45, 55, 72, 0.5)" : "rgba(247, 250, 252, 0.8)"
    property string borderColor: isDarkMode ? "rgba(255, 255, 255, 0.08)" : "rgba(0, 0, 0, 0.08)"
    property bool isTabletMode: false

    // Shared list of available system applications
    property var appsList: [
        {"name": "File Manager", "icon": "📁", "id": "file-manager", "category": "System"},
        {"name": "Terminal", "icon": "🐚", "id": "terminal", "category": "System"},
        {"name": "Control Center", "icon": "⚙️", "id": "control-center", "category": "System"},
        {"name": "App Store", "icon": "🛍️", "id": "store", "category": "System"},
        {"name": "Install Agneax OS", "icon": "💾", "id": "installer", "category": "System"},
        {"name": "Web Browser", "icon": "🌐", "id": "firefox", "category": "Internet"},
        {"name": "Text Editor", "icon": "📝", "id": "gedit", "category": "Office"},
        {"name": "Calculator", "icon": "🧮", "id": "gnome-calculator", "category": "Utilities"},
        {"name": "System Monitor", "icon": "📈", "id": "gnome-system-monitor", "category": "System"},
        {"name": "Media Player", "icon": "🎬", "id": "vlc", "category": "Multimedia"}
    ]

    // Open/Close triggers for Panels
    property bool startMenuOpen: false
    property bool quickSettingsOpen: false
    property bool widgetsOpen: false
    property bool welcomeDialogOpen: systemBridge.isLiveEnvironment
    property string taskbarLayout: systemBridge.taskbarLayout
    property int snapPreviewDirection: 0 // 0=None, 1=Left, 2=Right, 7=Fullscreen

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
        onTaskbarLayoutChanged: {
            taskbarLayout = layout;
        }
    }

    Component.onCompleted: {
        // Fetch initial telemetry
        telemetry = JSON.parse(systemBridge.getTelemetry());
        // Set focus to capture keys
        root.forceActiveFocus();
    }

    // Dynamic abstract wallpaper background
    Image {
        id: bgImage
        anchors.fill: parent
        source: systemBridge.wallpaperPath
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
        anchors.bottom: root.taskbarLayout == "Panel" ? panel.top : parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: root.taskbarLayout == "Panel" ? 12 : 20
        visible: root.startMenuOpen && !root.isTabletMode
    }

    // Full-Screen Apps Overview Grid Drawer (Convergence Mode)
    AppsOverview {
        id: appsOverview
        anchors.fill: parent
        visible: root.startMenuOpen && root.isTabletMode
    }

    // Glassmorphic Quick Settings Overlay
    QuickSettings {
        id: quickSettings
        anchors.bottom: root.taskbarLayout == "Panel" ? panel.top : parent.bottom
        anchors.right: parent.right
        anchors.rightMargin: 20
        anchors.bottomMargin: root.taskbarLayout == "Panel" ? 12 : 20
        visible: root.quickSettingsOpen
    }

    // Bottom Taskbar Panel
    Panel {
        id: panel
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 52
        visible: root.taskbarLayout == "Panel"
    }

    // Floating Dock Launcher (Step 1.2)
    Dock {
        id: dock
        anchors.bottom: root.taskbarLayout == "Panel" ? panel.top : parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: root.taskbarLayout == "Panel" ? 8 : 16
        visible: root.taskbarLayout == "Dock" && !root.startMenuOpen && !root.quickSettingsOpen
    }

    // Snapping Highlight Preview Overlay (Step 1.1)
    Rectangle {
        id: snapPreview
        visible: root.snapPreviewDirection > 0
        color: "rgba(0, 242, 254, 0.15)"
        border.color: root.accentColor
        border.width: 2
        radius: 12

        // Set layout geometries dynamically on drag status
        x: {
            if (root.snapPreviewDirection == 1) return 0;
            if (root.snapPreviewDirection == 2) return root.width / 2;
            return 0;
        }
        y: 0
        width: {
            if (root.snapPreviewDirection == 1 || root.snapPreviewDirection == 2) return root.width / 2;
            return root.width;
        }
        height: root.height - panel.height

        Behavior on x { NumberAnimation { duration: 150 } }
        Behavior on width { NumberAnimation { duration: 150 } }
        Behavior on height { NumberAnimation { duration: 150 } }
    }

    // Default Running Window on Desktop
    DesktopWindow {
        id: settingsWindow
        windowTitle: "Agneax System Settings"
        iconText: "⚙️"
        x: 150
        y: 120
    }

    // Widgets Dashboard (Phase 5)
    WidgetsDashboard {
        id: widgetsDashboard
        x: root.widgetsOpen ? 0 : -340
        anchors.top: parent.top
        z: 100

        Behavior on x {
            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
        }
    }

    // Night Light warm filter overlay (Phase 5)
    Rectangle {
        id: nightLightOverlay
        anchors.fill: parent
        color: "#FF7000"
        opacity: (systemBridge.nightLight || 0.0) * 0.18
        z: 999999
        enabled: false
    }

    // Ubuntu-style "Try or Install" Welcome Dialog Overlay
    Rectangle {
        id: welcomeOverlay
        anchors.fill: parent
        color: "rgba(10, 12, 18, 0.85)"
        z: 9999999
        visible: root.welcomeDialogOpen

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.AllButtons
        }

        Rectangle {
            anchors.centerIn: parent
            width: 580
            height: 380
            color: root.glassBgColor
            border.color: root.borderColor
            border.width: 1
            radius: 20

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 30
                spacing: 20

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 4
                    Text {
                        text: "Agnea"
                        font.pixelSize: 36
                        font.bold: true
                        color: root.textPrimaryColor
                    }
                    Text {
                        text: "X"
                        font.pixelSize: 36
                        font.bold: true
                        color: "#FF6600"
                    }
                    Text {
                        text: " OS"
                        font.pixelSize: 36
                        font.bold: true
                        color: root.textPrimaryColor
                    }
                }

                Text {
                    text: "Welcome! Would you like to try Agneax OS live or install it permanently?"
                    font.pixelSize: 13
                    color: root.textSecondaryColor
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }

                Item { height: 10 }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 30

                    Rectangle {
                        width: 180
                        height: 120
                        color: tryMouseArea.containsMouse ? "rgba(255, 255, 255, 0.08)" : root.cardBgColor
                        border.color: tryMouseArea.containsMouse ? root.accentColor : root.borderColor
                        border.width: 1.5
                        radius: 14

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 8
                            Text { text: "💻"; font.pixelSize: 32; Layout.alignment: Qt.AlignHCenter }
                            Text { text: "Try Agneax OS"; font.bold: true; font.pixelSize: 12; color: root.textPrimaryColor; Layout.alignment: Qt.AlignHCenter }
                        }

                        MouseArea {
                            id: tryMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                root.welcomeDialogOpen = false;
                            }
                        }
                    }

                    Rectangle {
                        width: 180
                        height: 120
                        color: installMouseArea.containsMouse ? "rgba(255, 255, 255, 0.08)" : root.cardBgColor
                        border.color: installMouseArea.containsMouse ? root.accentColor : root.borderColor
                        border.width: 1.5
                        radius: 14

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 8
                            Text { text: "💾"; font.pixelSize: 32; Layout.alignment: Qt.AlignHCenter }
                            Text { text: "Install Agneax OS"; font.bold: true; font.pixelSize: 12; color: root.textPrimaryColor; Layout.alignment: Qt.AlignHCenter }
                        }

                        MouseArea {
                            id: installMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                systemBridge.launchApp("installer");
                                root.welcomeDialogOpen = false;
                            }
                        }
                    }
                }
            }
        }
    }

    // Global Keyboard Shortcuts (Phase 5)
    focus: true
    Keys.onPressed: {
        if (event.key === Qt.Key_Menu || event.key === Qt.Key_Meta) {
            root.startMenuOpen = !root.startMenuOpen;
            event.accepted = true;
        }
        if (event.key === Qt.Key_T && (event.modifiers & Qt.ControlModifier) && (event.modifiers & Qt.AltModifier)) {
            systemBridge.launchApp("terminal");
            event.accepted = true;
        }
        if (event.key === Qt.Key_T && (event.modifiers & Qt.MetaModifier)) {
            root.isTabletMode = !root.isTabletMode;
            event.accepted = true;
        }
        if (event.key === Qt.Key_W && (event.modifiers & Qt.MetaModifier)) {
            root.widgetsOpen = !root.widgetsOpen;
            event.accepted = true;
        }
        if (event.key === Qt.Key_D && (event.modifiers & Qt.MetaModifier)) {
            settingsWindow.visible = !settingsWindow.visible;
            event.accepted = true;
        }
    }
}

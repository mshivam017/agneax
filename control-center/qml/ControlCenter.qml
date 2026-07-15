import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

ApplicationWindow {
    id: ccWindow
    visible: true
    width: 820
    height: 560
    title: "Agneax Control Center"
    
    // Aesthetic Styling Variables (Glassmorphism dark theme)
    property string activeAccentColor: "#00F2FE"
    property string sidebarBgColor: "#0F1219"
    property string contentBgColor: "#141821"
    property string cardBgColor: "#1E2330"
    property string textPrimaryColor: "#FFFFFF"
    property string textSecondaryColor: "#A0AEC0"
    property string borderColor: "rgba(255, 255, 255, 0.08)"

    // Active Category Index
    property int currentCategory: 0

    // Fetch bridge objects
    property var appearance: JSON.parse(settingsBridge.getAppearanceSettings())
    property var network: JSON.parse(settingsBridge.getNetworkSettings())
    property var firewall: JSON.parse(settingsBridge.getFirewallSettings())
    property var systemSpecs: JSON.parse(settingsBridge.getSystemSpecs())

    property string statusGit: "Install"
    property string statusNode: "Install"
    property string statusRust: "Install"
    property string statusDocker: "Install"

    Connections {
        target: settingsBridge
        onSettingsChanged: {
            var data = JSON.parse(settings);
            if (category == "appearance") appearance = data;
            if (category == "network") network = data;
            if (category == "firewall") firewall = data;
        }
    }

    background: Rectangle {
        color: ccWindow.contentBgColor
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // Left Navigation Sidebar
        Rectangle {
            Layout.preferredWidth: 200
            Layout.fillHeight: true
            color: ccWindow.sidebarBgColor

            // Border Separator
            Rectangle {
                anchors.right: parent.right
                width: 1
                height: parent.height
                color: ccWindow.borderColor
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: 24
                anchors.bottomMargin: 24
                spacing: 12

                // Logo and Title Header
                RowLayout {
                    Layout.leftMargin: 20
                    Layout.bottomMargin: 16
                    spacing: 8
                    Text { text: "⚙️"; font.pixelSize: 22 }
                    Column {
                        Text {
                            text: "Control Center"
                            font.bold: true
                            font.pixelSize: 13
                            font.family: "Segoe UI, Inter"
                            color: ccWindow.textPrimaryColor
                        }
                        Text {
                            text: "Agneax OS Settings"
                            font.pixelSize: 9
                            font.family: "Segoe UI, Inter"
                            color: ccWindow.textSecondaryColor
                        }
                    }
                }

                // Category Buttons List
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    SidebarItem {
                        title: "System Details"
                        icon: "💻"
                        active: ccWindow.currentCategory == 0
                        onClicked: ccWindow.currentCategory = 0
                    }
                    SidebarItem {
                        title: "Appearance"
                        icon: "🎨"
                        active: ccWindow.currentCategory == 1
                        onClicked: ccWindow.currentCategory = 1
                    }
                    SidebarItem {
                        title: "Wi-Fi & Network"
                        icon: "📶"
                        active: ccWindow.currentCategory == 2
                        onClicked: ccWindow.currentCategory = 2
                    }
                    SidebarItem {
                        title: "Security & Firewall"
                        icon: "🛡️"
                        active: ccWindow.currentCategory == 3
                        onClicked: ccWindow.currentCategory = 3
                    }
                    SidebarItem {
                        title: "Developer Mode"
                        icon: "🛠️"
                        active: ccWindow.currentCategory == 4
                        onClicked: ccWindow.currentCategory = 4
                    }
                    SidebarItem {
                        title: "Sound & Display"
                        icon: "🔊"
                        active: ccWindow.currentCategory == 5
                        onClicked: ccWindow.currentCategory = 5
                    }
                    SidebarItem {
                        title: "Backup & Power"
                        icon: "🔋"
                        active: ccWindow.currentCategory == 6
                        onClicked: ccWindow.currentCategory = 6
                    }
                }

                Item { Layout.fillHeight: true } // Spacer
            }
        }

        // Right Settings Content Panel
        StackLayout {
            id: contentStack
            currentIndex: ccWindow.currentCategory
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Category 0: System details
            ScrollView {
                clip: true
                ColumnLayout {
                    width: parent.width - 40
                    anchors.top: parent.top
                    anchors.topMargin: 24
                    anchors.left: parent.left
                    anchors.leftMargin: 20
                    spacing: 16

                    Text {
                        text: "System Information"
                        font.bold: true
                        font.pixelSize: 20
                        color: ccWindow.textPrimaryColor
                    }

                    // Specs Card
                    Rectangle {
                        Layout.fillWidth: true
                        height: 240
                        color: ccWindow.cardBgColor
                        radius: 12
                        border.color: ccWindow.borderColor

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 18
                            spacing: 12

                            Text {
                                text: "Hardware & Software Specs"
                                font.bold: true
                                font.pixelSize: 12
                                color: ccWindow.activeAccentColor
                            }

                            Rectangle { Layout.fillWidth: true; height: 1; color: ccWindow.borderColor }

                            GridLayout {
                                columns: 2
                                rowSpacing: 8
                                columnSpacing: 40

                                Text { text: "OS Name"; color: ccWindow.textSecondaryColor; font.pixelSize: 11 }
                                Text { text: ccWindow.systemSpecs.os; color: ccWindow.textPrimaryColor; font.bold: true; font.pixelSize: 11 }

                                Text { text: "Kernel Version"; color: ccWindow.textSecondaryColor; font.pixelSize: 11 }
                                Text { text: ccWindow.systemSpecs.kernel; color: ccWindow.textPrimaryColor; font.pixelSize: 11 }

                                Text { text: "Windowing System"; color: ccWindow.textSecondaryColor; font.pixelSize: 11 }
                                Text { text: "Wayland (Weston Compositor)"; color: ccWindow.textPrimaryColor; font.pixelSize: 11 }

                                Text { text: "Processor (CPU)"; color: ccWindow.textSecondaryColor; font.pixelSize: 11 }
                                Text { text: ccWindow.systemSpecs.cpu; color: ccWindow.textPrimaryColor; font.pixelSize: 11; elide: Text.ElideRight; Layout.preferredWidth: 280 }

                                Text { text: "Total RAM"; color: ccWindow.textSecondaryColor; font.pixelSize: 11 }
                                Text { text: ccWindow.systemSpecs.ram; color: ccWindow.textPrimaryColor; font.pixelSize: 11 }

                                Text { text: "Hardware Support"; color: ccWindow.textSecondaryColor; font.pixelSize: 11 }
                                Text { text: "Intel, AMD, NVIDIA, UEFI, VBox, VMware"; color: ccWindow.textPrimaryColor; font.pixelSize: 11 }
                            }
                        }
                    }
                }
            }

            // Category 1: Appearance details
            ScrollView {
                clip: true
                ColumnLayout {
                    width: parent.width - 40
                    anchors.top: parent.top
                    anchors.topMargin: 24
                    anchors.left: parent.left
                    anchors.leftMargin: 20
                    spacing: 16

                    Text {
                        text: "Appearance Settings"
                        font.bold: true
                        font.pixelSize: 20
                        color: ccWindow.textPrimaryColor
                    }

                    // Themes Selector Card
                    Rectangle {
                        Layout.fillWidth: true
                        height: 120
                        color: ccWindow.cardBgColor
                        radius: 12
                        border.color: ccWindow.borderColor

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 18

                            ColumnLayout {
                                Text { text: "System theme style"; font.bold: true; font.pixelSize: 12; color: ccWindow.textPrimaryColor }
                                Text { text: "Choose dark glassmorphism layout or light layouts"; font.pixelSize: 10; color: ccWindow.textSecondaryColor }
                            }
                            Item { Layout.fillWidth: true }
                            Button {
                                text: ccWindow.appearance.theme
                                onClicked: {
                                    var nextTheme = ccWindow.appearance.theme == "Dark Mode" ? "Light Mode" : "Dark Mode";
                                    settingsBridge.saveAppearance("theme", nextTheme);
                                }
                            }
                        }
                    }

                    // Accent Colors Chooser Card
                    Rectangle {
                        Layout.fillWidth: true
                        height: 120
                        color: ccWindow.cardBgColor
                        radius: 12
                        border.color: ccWindow.borderColor

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 18
                            spacing: 10

                            Text { text: "Select System Accent Color"; font.bold: true; font.pixelSize: 12; color: ccWindow.textPrimaryColor }

                            Row {
                                spacing: 14
                                AccentCircle { colorCode: "#00F2FE"; selected: ccWindow.appearance.accent_color == "#00F2FE"; onClicked: settingsBridge.saveAppearance("accent_color", "#00F2FE") }
                                AccentCircle { colorCode: "#FF5E62"; selected: ccWindow.appearance.accent_color == "#FF5E62"; onClicked: settingsBridge.saveAppearance("accent_color", "#FF5E62") }
                                AccentCircle { colorCode: "#B06AB3"; selected: ccWindow.appearance.accent_color == "#B06AB3"; onClicked: settingsBridge.saveAppearance("accent_color", "#B06AB3") }
                                AccentCircle { colorCode: "#11998E"; selected: ccWindow.appearance.accent_color == "#11998E"; onClicked: settingsBridge.saveAppearance("accent_color", "#11998E") }
                            }
                        }
                    }

                    // System Wallpaper Selector Card (Task 3)
                    Rectangle {
                        Layout.fillWidth: true
                        height: 180
                        color: ccWindow.cardBgColor
                        radius: 12
                        border.color: ccWindow.borderColor

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 18
                            spacing: 10

                            Text { text: "Select Desktop Wallpaper"; font.bold: true; font.pixelSize: 12; color: ccWindow.textPrimaryColor }

                            RowLayout {
                                spacing: 14
                                Layout.fillWidth: true

                                // Sleek Carbon Glass
                                Rectangle {
                                    width: 140; height: 90; radius: 6; color: "#252B3C"; border.color: ccWindow.appearance.wallpaper == "Sleek Carbon Glass" ? ccWindow.activeAccentColor : ccWindow.borderColor; border.width: ccWindow.appearance.wallpaper == "Sleek Carbon Glass" ? 2 : 1
                                    Text { anchors.centerIn: parent; text: "Carbon Glass"; font.pixelSize: 11; font.bold: true; color: "#FFFFFF" }
                                    MouseArea { anchors.fill: parent; onClicked: settingsBridge.saveAppearance("wallpaper", "Sleek Carbon Glass") }
                                }
                                // Aurora Wave
                                Rectangle {
                                    width: 140; height: 90; radius: 6; color: "#1B3B32"; border.color: ccWindow.appearance.wallpaper == "Aurora Wave" ? ccWindow.activeAccentColor : ccWindow.borderColor; border.width: ccWindow.appearance.wallpaper == "Aurora Wave" ? 2 : 1
                                    Text { anchors.centerIn: parent; text: "Aurora Wave"; font.pixelSize: 11; font.bold: true; color: "#FFFFFF" }
                                    MouseArea { anchors.fill: parent; onClicked: settingsBridge.saveAppearance("wallpaper", "Aurora Wave") }
                                }
                                // Neon Horizon
                                Rectangle {
                                    width: 140; height: 90; radius: 6; color: "#4A2E35"; border.color: ccWindow.appearance.wallpaper == "Neon Horizon" ? ccWindow.activeAccentColor : ccWindow.borderColor; border.width: ccWindow.appearance.wallpaper == "Neon Horizon" ? 2 : 1
                                    Text { anchors.centerIn: parent; text: "Neon Horizon"; font.pixelSize: 11; font.bold: true; color: "#FFFFFF" }
                                    MouseArea { anchors.fill: parent; onClicked: settingsBridge.saveAppearance("wallpaper", "Neon Horizon") }
                                }
                            }

                            Item { height: 10 }

                            Text { text: "Select Taskbar Layout"; font.bold: true; font.pixelSize: 12; color: ccWindow.textPrimaryColor }

                            RowLayout {
                                spacing: 14
                                Layout.fillWidth: true

                                // Standard Panel
                                Rectangle {
                                    width: 140; height: 50; radius: 6; color: "#252B3C"; border.color: ccWindow.appearance.taskbar_layout == "Panel" ? ccWindow.activeAccentColor : ccWindow.borderColor; border.width: ccWindow.appearance.taskbar_layout == "Panel" ? 2 : 1
                                    Text { anchors.centerIn: parent; text: "Standard Panel"; font.pixelSize: 11; font.bold: true; color: "#FFFFFF" }
                                    MouseArea { anchors.fill: parent; onClicked: settingsBridge.saveAppearance("taskbar_layout", "Panel") }
                                }
                                // Floating Dock
                                Rectangle {
                                    width: 140; height: 50; radius: 6; color: "#1E2530"; border.color: ccWindow.appearance.taskbar_layout == "Dock" ? ccWindow.activeAccentColor : ccWindow.borderColor; border.width: ccWindow.appearance.taskbar_layout == "Dock" ? 2 : 1
                                    Text { anchors.centerIn: parent; text: "Floating Dock"; font.pixelSize: 11; font.bold: true; color: "#FFFFFF" }
                                    MouseArea { anchors.fill: parent; onClicked: settingsBridge.saveAppearance("taskbar_layout", "Dock") }
                                }
                            }
                        }
                    }
                }
            }

            // Category 2: WiFi and Network
            ScrollView {
                clip: true
                ColumnLayout {
                    width: parent.width - 40
                    anchors.top: parent.top
                    anchors.topMargin: 24
                    anchors.left: parent.left
                    anchors.leftMargin: 20
                    spacing: 16

                    Text {
                        text: "Wi-Fi & Connections"
                        font.bold: true
                        font.pixelSize: 20
                        color: ccWindow.textPrimaryColor
                    }

                    // Wifi Switch Card
                    Rectangle {
                        Layout.fillWidth: true
                        height: 100
                        color: ccWindow.cardBgColor
                        radius: 12
                        border.color: ccWindow.borderColor

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 18

                            ColumnLayout {
                                Text { text: "Enable Wireless Networking"; font.bold: true; font.pixelSize: 12; color: ccWindow.textPrimaryColor }
                                Text {
                                    text: ccWindow.network.wifi_enabled ? "Connected to: " + ccWindow.network.connected_ssid : "Wireless radio is switched off"
                                    font.pixelSize: 10
                                    color: ccWindow.textSecondaryColor
                                }
                            }
                            Item { Layout.fillWidth: true }
                            Switch {
                                checked: ccWindow.network.wifi_enabled
                                onCheckedChanged: settingsBridge.setWifiEnabled(checked)
                            }
                        }
                    }

                    // Available Network List Card
                    Rectangle {
                        Layout.fillWidth: true
                        height: 220
                        color: ccWindow.cardBgColor
                        radius: 12
                        border.color: ccWindow.borderColor
                        visible: ccWindow.network.wifi_enabled

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 18
                            spacing: 8

                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: "Available Wi-Fi Networks"; font.bold: true; font.pixelSize: 11; color: ccWindow.activeAccentColor }
                                Item { Layout.fillWidth: true }
                                Text {
                                    id: wifiStatusText
                                    text: ""
                                    font.pixelSize: 9
                                    color: ccWindow.activeAccentColor
                                }
                            }

                            ListModel {
                                id: wifiListModel
                            }

                            ListView {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                model: wifiListModel
                                clip: true
                                delegate: Item {
                                    width: parent.width
                                    height: 32
                                    RowLayout {
                                        anchors.fill: parent
                                        spacing: 8
                                        Text { text: model.name; font.pixelSize: 11; font.bold: model.active; color: model.active ? ccWindow.activeAccentColor : ccWindow.textPrimaryColor }
                                        Text { text: model.active ? " (Connected)" : ""; font.pixelSize: 9; color: ccWindow.activeAccentColor }
                                        Text { text: model.locked ? "🔒" : "🔓"; font.pixelSize: 10 }
                                        Item { Layout.fillWidth: true }
                                        Text { text: model.strength; font.pixelSize: 10 }
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            if (model.locked) {
                                                wifiPasswordDialog.targetSsid = model.name;
                                                wifiPasswordInput.text = "";
                                                wifiPasswordDialog.open();
                                            } else {
                                                wifiStatusText.text = "Connecting to " + model.name + "...";
                                                settingsBridge.connectToWifi(model.name, "");
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Category 3: Security & Firewall
            ScrollView {
                clip: true
                ColumnLayout {
                    width: parent.width - 40
                    anchors.top: parent.top
                    anchors.topMargin: 24
                    anchors.left: parent.left
                    anchors.leftMargin: 20
                    spacing: 16

                    Text {
                        text: "Security & Protection"
                        font.bold: true
                        font.pixelSize: 20
                        color: ccWindow.textPrimaryColor
                    }

                    // Firewall Switch Card
                    Rectangle {
                        Layout.fillWidth: true
                        height: 110
                        color: ccWindow.cardBgColor
                        radius: 12
                        border.color: ccWindow.borderColor

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 18

                            ColumnLayout {
                                Text { text: "UFW Firewall Protection"; font.bold: true; font.pixelSize: 12; color: ccWindow.textPrimaryColor }
                                Text { text: "Blocks unauthorized incoming access requests to your ports"; font.pixelSize: 10; color: ccWindow.textSecondaryColor }
                            }
                            Item { Layout.fillWidth: true }
                            Switch {
                                checked: ccWindow.firewall.enabled
                                onCheckedChanged: settingsBridge.setFirewallEnabled(checked)
                            }
                        }
                    }

                    // Shield Details
                    Rectangle {
                        Layout.fillWidth: true
                        height: 140
                        color: ccWindow.cardBgColor
                        radius: 12
                        border.color: ccWindow.borderColor

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 18
                            spacing: 10

                            Text { text: "Firewall Policies"; font.bold: true; font.pixelSize: 11; color: ccWindow.activeAccentColor }

                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: "Incoming Traffic Policy"; color: ccWindow.textSecondaryColor; font.pixelSize: 11 }
                                Item { Layout.fillWidth: true }
                                Text { text: ccWindow.firewall.incoming; color: "#FF5E62"; font.bold: true; font.pixelSize: 11 }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: "Outgoing Traffic Policy"; color: ccWindow.textSecondaryColor; font.pixelSize: 11 }
                                Item { Layout.fillWidth: true }
                                Text { text: ccWindow.firewall.outgoing; color: "#00F2FE"; font.bold: true; font.pixelSize: 11 }
                            }
                        }
                    }
                }
            }

            // Category 4: Developer Mode
            ScrollView {
                clip: true
                ColumnLayout {
                    width: parent.width - 40
                    anchors.top: parent.top
                    anchors.topMargin: 24
                    anchors.left: parent.left
                    anchors.leftMargin: 20
                    spacing: 16

                    Text {
                        text: "Developer Suite"
                        font.bold: true
                        font.pixelSize: 20
                        color: ccWindow.textPrimaryColor
                    }

                    // Developer Toggle
                    Rectangle {
                        Layout.fillWidth: true
                        height: 100
                        color: ccWindow.cardBgColor
                        radius: 12
                        border.color: ccWindow.borderColor

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 18

                            ColumnLayout {
                                Text { text: "Developer Mode Control"; font.bold: true; font.pixelSize: 12; color: ccWindow.textPrimaryColor }
                                Text { text: "Enable superuser compiler suites, docker services, and debugging hooks"; font.pixelSize: 10; color: ccWindow.textSecondaryColor }
                            }
                            Item { Layout.fillWidth: true }
                            Switch {
                                id: devSwitch
                                checked: false
                            }
                        }
                    }

                    // Developer tool installations
                    Rectangle {
                        Layout.fillWidth: true
                        height: 200
                        color: ccWindow.cardBgColor
                        radius: 12
                        border.color: ccWindow.borderColor
                        visible: devSwitch.checked

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 18
                            spacing: 12

                            Text { text: "Developer Stack Installer"; font.bold: true; font.pixelSize: 11; color: ccWindow.activeAccentColor }

                            GridLayout {
                                columns: 2
                                rowSpacing: 10
                                Layout.fillWidth: true

                                RowLayout {
                                    Text { text: "🛠️ Git & Dev Tools"; font.pixelSize: 11; color: ccWindow.textPrimaryColor }
                                    Item { Layout.fillWidth: true }
                                    Button {
                                        text: ccWindow.statusGit
                                        font.pixelSize: 9
                                        enabled: ccWindow.statusGit != "Installing..." && ccWindow.statusGit != "Installed"
                                        onClicked: {
                                            ccWindow.statusGit = "Installing..."
                                            settingsBridge.installDevTool("git")
                                        }
                                    }
                                }
                                RowLayout {
                                    Text { text: "📦 Node.js & NPM"; font.pixelSize: 11; color: ccWindow.textPrimaryColor }
                                    Item { Layout.fillWidth: true }
                                    Button {
                                        text: ccWindow.statusNode
                                        font.pixelSize: 9
                                        enabled: ccWindow.statusNode != "Installing..." && ccWindow.statusNode != "Installed"
                                        onClicked: {
                                            ccWindow.statusNode = "Installing..."
                                            settingsBridge.installDevTool("node")
                                        }
                                    }
                                }
                                RowLayout {
                                    Text { text: "🦀 Rust & Cargo"; font.pixelSize: 11; color: ccWindow.textPrimaryColor }
                                    Item { Layout.fillWidth: true }
                                    Button {
                                        text: ccWindow.statusRust
                                        font.pixelSize: 9
                                        enabled: ccWindow.statusRust != "Installing..." && ccWindow.statusRust != "Installed"
                                        onClicked: {
                                            ccWindow.statusRust = "Installing..."
                                            settingsBridge.installDevTool("rust")
                                        }
                                    }
                                }
                                RowLayout {
                                    Text { text: "🐳 Docker Engine"; font.pixelSize: 11; color: ccWindow.textPrimaryColor }
                                    Item { Layout.fillWidth: true }
                                    Button {
                                        text: ccWindow.statusDocker
                                        font.pixelSize: 9
                                        enabled: ccWindow.statusDocker != "Installing..." && ccWindow.statusDocker != "Installed"
                                        onClicked: {
                                            ccWindow.statusDocker = "Installing..."
                                            settingsBridge.installDevTool("docker")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Category 5: Sound & Display
            ScrollView {
                clip: true
                ColumnLayout {
                    width: parent.width - 40
                    anchors.top: parent.top
                    anchors.topMargin: 24
                    anchors.left: parent.left
                    anchors.leftMargin: 20
                    spacing: 16

                    Text {
                        text: "Display & Audio Settings"
                        font.bold: true
                        font.pixelSize: 20
                        color: ccWindow.textPrimaryColor
                    }

                    // Display Card
                    Rectangle {
                        Layout.fillWidth: true
                        height: 200
                        color: ccWindow.cardBgColor
                        radius: 12
                        border.color: ccWindow.borderColor

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 18
                            spacing: 10

                            Text { text: "Display Settings"; font.bold: true; font.pixelSize: 12; color: ccWindow.activeAccentColor }

                            RowLayout {
                                spacing: 20
                                Column {
                                    spacing: 4
                                    Text { text: "Screen Resolution"; font.pixelSize: 10; color: ccWindow.textSecondaryColor }
                                    ComboBox {
                                        model: ["1920 x 1080 (16:9)", "1440 x 900 (16:10)", "1280 x 720 (16:9)", "1024 x 768 (4:3)"]
                                        width: 180
                                    }
                                }

                                Column {
                                    spacing: 4
                                    Text { text: "Refresh Rate"; font.pixelSize: 10; color: ccWindow.textSecondaryColor }
                                    ComboBox {
                                        model: ["60 Hz", "120 Hz", "144 Hz"]
                                        width: 120
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: "Night Light"; font.pixelSize: 10; color: ccWindow.textSecondaryColor; Layout.preferredWidth: 100 }
                                Slider {
                                    id: nightLightSlider
                                    value: ccWindow.appearance.night_light || 0.0
                                    Layout.fillWidth: true
                                    onMoved: {
                                        settingsBridge.saveAppearance("night_light", value);
                                    }
                                }
                                Text {
                                    text: Math.round(nightLightSlider.value * 100) + "%"
                                    font.pixelSize: 11
                                    color: ccWindow.textPrimaryColor
                                }
                            }
                        }
                    }

                    // Audio Card
                    Rectangle {
                        Layout.fillWidth: true
                        height: 180
                        color: ccWindow.cardBgColor
                        radius: 12
                        border.color: ccWindow.borderColor

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 18
                            spacing: 10

                            Text { text: "Audio Settings (PipeWire)"; font.bold: true; font.pixelSize: 12; color: ccWindow.activeAccentColor }

                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: "Output Device"; font.pixelSize: 10; color: ccWindow.textSecondaryColor; Layout.preferredWidth: 100 }
                                ComboBox {
                                    model: ["Built-in Analog Stereo Speakers", "HDMI Audio Output Controller", "External Headset Jack"]
                                    Layout.fillWidth: true
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: "Master Volume"; font.pixelSize: 10; color: ccWindow.textSecondaryColor; Layout.preferredWidth: 100 }
                                Slider {
                                    id: volumeSlider
                                    value: 0.7
                                    Layout.fillWidth: true
                                    Component.onCompleted: {
                                        value = settingsBridge.getVolume() / 100.0;
                                    }
                                    onMoved: {
                                        settingsBridge.setVolume(Math.round(value * 100));
                                    }
                                }
                                Text {
                                    text: Math.round(volumeSlider.value * 100) + "%"
                                    font.pixelSize: 11
                                    color: ccWindow.textPrimaryColor
                                }
                            }
                    // Accessibility Tools Card (Step 6.1)
                    Rectangle {
                        Layout.fillWidth: true
                        height: 150
                        color: ccWindow.cardBgColor
                        radius: 12
                        border.color: ccWindow.borderColor

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 18
                            spacing: 10

                            Text { text: "Accessibility Tools"; font.bold: true; font.pixelSize: 12; color: ccWindow.activeAccentColor }

                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: "Screen Reader Speech Utility"; font.pixelSize: 10; color: ccWindow.textSecondaryColor }
                                Item { Layout.fillWidth: true }
                                Switch { checked: false }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: "Desktop Screen Magnifier"; font.pixelSize: 10; color: ccWindow.textSecondaryColor }
                                Item { Layout.fillWidth: true }
                                Switch { checked: false }
                            }
                        }
                    }
                }
            }

            // Category 6: Backup & Power
            ScrollView {
                clip: true
                ColumnLayout {
                    width: parent.width - 40
                    anchors.top: parent.top
                    anchors.topMargin: 24
                    anchors.left: parent.left
                    anchors.leftMargin: 20
                    spacing: 16

                    Text {
                        text: "Backup & Power Configuration"
                        font.bold: true
                        font.pixelSize: 20
                        color: ccWindow.textPrimaryColor
                    }

                    // Backup Card
                    Rectangle {
                        Layout.fillWidth: true
                        height: 150
                        color: ccWindow.cardBgColor
                        radius: 12
                        border.color: ccWindow.borderColor

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 18
                            spacing: 10

                            Text { text: "Scheduled Backups (Timeshift Hooks)"; font.bold: true; font.pixelSize: 12; color: ccWindow.activeAccentColor }

                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: "Automatic System Backups"; font.pixelSize: 10; color: ccWindow.textSecondaryColor }
                                Item { Layout.fillWidth: true }
                                Switch { id: backupSwitch; checked: true }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                visible: backupSwitch.checked
                                Text { text: "Backup Frequency"; font.pixelSize: 10; color: ccWindow.textSecondaryColor }
                                Item { Layout.fillWidth: true }
                                ComboBox {
                                    model: ["Hourly", "Daily", "Weekly", "Monthly"]
                                    width: 120
                                }
                            }
                        }
                    }

                    // Power Card
                    Rectangle {
                        Layout.fillWidth: true
                        height: 160
                        color: ccWindow.cardBgColor
                        radius: 12
                        border.color: ccWindow.borderColor

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 18
                            spacing: 10

                            Text { text: "Power Management Plan"; font.bold: true; font.pixelSize: 12; color: ccWindow.activeAccentColor }

                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: "Select Power Profile"; font.pixelSize: 10; color: ccWindow.textSecondaryColor }
                                Item { Layout.fillWidth: true }
                                ComboBox {
                                    model: ["High Performance Mode", "Balanced Mode (Recommended)", "Power Saving Saver Mode"]
                                    width: 220
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: "Turn off screen after idle"; font.pixelSize: 10; color: ccWindow.textSecondaryColor }
                                Item { Layout.fillWidth: true }
                                ComboBox {
                                    model: ["5 Minutes", "15 Minutes", "30 Minutes", "Never"]
                                    width: 120
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // WiFi Scanning Timer (Phase 1)
    Timer {
        id: wifiScanTimer
        interval: 4000
        running: ccWindow.currentCategory == 2 && ccWindow.network.wifi_enabled
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            updateWifiList();
        }
    }

    function updateWifiList() {
        try {
            var raw = settingsBridge.getWifiNetworks();
            var list = JSON.parse(raw);
            wifiListModel.clear();
            for (var i = 0; i < list.length; i++) {
                var item = list[i];
                var stars = "⭐";
                if (item.signal > 75) stars = "⭐⭐⭐⭐";
                else if (item.signal > 50) stars = "⭐⭐⭐";
                else if (item.signal > 25) stars = "⭐⭐";
                
                wifiListModel.append({
                    "name": item.ssid,
                    "locked": item.secured,
                    "strength": stars,
                    "active": item.active
                });
            }
        } catch(e) {
            console.log("Error scanning WiFi: " + e);
        }
    }

    // WiFi Password Prompt Dialog (Phase 1)
    Dialog {
        id: wifiPasswordDialog
        title: "Connect to Wi-Fi"
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        width: 320
        height: 180
        modal: true
        
        property string targetSsid: ""

        background: Rectangle {
            color: ccWindow.cardBgColor
            radius: 12
            border.color: ccWindow.borderColor
        }

        header: Text {
            text: "Enter Password for " + wifiPasswordDialog.targetSsid
            color: ccWindow.textPrimaryColor
            font.bold: true
            font.pixelSize: 13
            horizontalAlignment: Text.AlignHCenter
            topPadding: 14
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            TextField {
                id: wifiPasswordInput
                placeholderText: "Password"
                echoMode: TextField.Password
                Layout.fillWidth: true
                color: ccWindow.textPrimaryColor
                background: Rectangle {
                    color: ccWindow.contentBgColor
                    radius: 6
                    border.color: ccWindow.borderColor
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                
                Button {
                    text: "Cancel"
                    Layout.fillWidth: true
                    onClicked: wifiPasswordDialog.close()
                }
                
                Button {
                    text: "Connect"
                    Layout.fillWidth: true
                    onClicked: {
                        wifiStatusText.text = "Connecting to " + wifiPasswordDialog.targetSsid + "...";
                        settingsBridge.connectToWifi(wifiPasswordDialog.targetSsid, wifiPasswordInput.text);
                        wifiPasswordDialog.close();
                    }
                }
            }
        }
    }

    Timer {
        id: wifiStatusTextTimer
        interval: 3000
        running: false
        repeat: false
        onTriggered: {
            wifiStatusText.text = "";
        }
    }

    Connections {
        target: settingsBridge
        onWifiConnectCompleted: {
            console.log("WiFi connection completed for: " + ssid + " success: " + success + " msg: " + error_message);
            wifiStatusText.text = success ? "Connected successfully" : "Connection failed";
            wifiStatusTextTimer.start();
            updateWifiList();
        }
        onDevToolInstallCompleted: {
            console.log("Dev tool connection completed: " + tool_id + " success: " + success);
            var label = success ? "Installed" : "Failed";
            if (tool_id == "git") ccWindow.statusGit = label;
            else if (tool_id == "node") ccWindow.statusNode = label;
            else if (tool_id == "rust") ccWindow.statusRust = label;
            else if (tool_id == "docker") ccWindow.statusDocker = label;
        }
    }
}

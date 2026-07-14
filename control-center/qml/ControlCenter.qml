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
                                Text { text: "Agneax OS 1.0.0 LTS (Debian Core)"; color: ccWindow.textPrimaryColor; font.bold: true; font.pixelSize: 11 }

                                Text { text: "Kernel Version"; color: ccWindow.textSecondaryColor; font.pixelSize: 11 }
                                Text { text: "Linux 6.1.0-21-amd64"; color: ccWindow.textPrimaryColor; font.pixelSize: 11 }

                                Text { text: "Windowing System"; color: ccWindow.textSecondaryColor; font.pixelSize: 11 }
                                Text { text: "Wayland (Weston Compositor)"; color: ccWindow.textPrimaryColor; font.pixelSize: 11 }

                                Text { text: "Processor (CPU)"; color: ccWindow.textSecondaryColor; font.pixelSize: 11 }
                                Text { text: "Intel® Core™ i7 / AMD Ryzen™ (x86_64)"; color: ccWindow.textPrimaryColor; font.pixelSize: 11 }

                                Text { text: "Total RAM"; color: ccWindow.textSecondaryColor; font.pixelSize: 11 }
                                Text { text: "8.0 GB Physical Memory"; color: ccWindow.textPrimaryColor; font.pixelSize: 11 }

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
                        height: 200
                        color: ccWindow.cardBgColor
                        radius: 12
                        border.color: ccWindow.borderColor
                        visible: ccWindow.network.wifi_enabled

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 18
                            spacing: 8

                            Text { text: "Available Wi-Fi Networks"; font.bold: true; font.pixelSize: 11; color: ccWindow.activeAccentColor }

                            ListModel {
                                id: wifiListModel
                                ListElement { name: "Agneax_Secure_5G"; locked: true; strength: "⭐⭐⭐⭐" }
                                ListElement { name: "Public_Airport_WiFi"; locked: false; strength: "⭐⭐⭐" }
                                ListElement { name: "Guest_House_Network"; locked: true; strength: "⭐⭐" }
                            }

                            ListView {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                model: wifiListModel
                                delegate: Item {
                                    width: parent.width
                                    height: 32
                                    RowLayout {
                                        anchors.fill: parent
                                        Text { text: model.name; font.pixelSize: 11; color: ccWindow.textPrimaryColor }
                                        Text { text: model.locked ? "🔒" : "🔓"; font.pixelSize: 10 }
                                        Item { Layout.fillWidth: true }
                                        Text { text: model.strength; font.pixelSize: 10 }
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
                                    Button { text: "Install"; font.pixelSize: 9 }
                                }
                                RowLayout {
                                    Text { text: "📦 Node.js & NPM"; font.pixelSize: 11; color: ccWindow.textPrimaryColor }
                                    Item { Layout.fillWidth: true }
                                    Button { text: "Install"; font.pixelSize: 9 }
                                }
                                RowLayout {
                                    Text { text: "🦀 Rust & Cargo"; font.pixelSize: 11; color: ccWindow.textPrimaryColor }
                                    Item { Layout.fillWidth: true }
                                    Button { text: "Install"; font.pixelSize: 9 }
                                }
                                RowLayout {
                                    Text { text: "🐳 Docker Engine"; font.pixelSize: 11; color: ccWindow.textPrimaryColor }
                                    Item { Layout.fillWidth: true }
                                    Button { text: "Install"; font.pixelSize: 9 }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

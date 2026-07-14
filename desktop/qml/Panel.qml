import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: rootPanel
    color: root.glassBgColor
    border.color: root.borderColor
    border.width: 1
    radius: 0 // full width taskbar

    // Glassmorphism accent border glow
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: "rgba(255, 255, 255, 0.15)"
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16

        // Left Section: Start Menu Trigger Button
        Button {
            id: startButton
            flat: true
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40

            background: Rectangle {
                radius: 8
                color: startButton.hovered ? "rgba(255, 255, 255, 0.1)" : "transparent"
                border.color: startButton.down ? root.accentColor : "transparent"
                border.width: 1
            }

            contentItem: Text {
                text: "Λ"
                font.bold: true
                font.pixelSize: 22
                color: root.accentColor
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            onClicked: {
                root.startMenuOpen = !root.startMenuOpen;
                root.quickSettingsOpen = false;
            }
        }

        Item { Layout.fillWidth: true } // Spacer

        // Center Section: Running Applications Launcher
        Row {
            spacing: 12
            Layout.alignment: Qt.AlignHCenter

            TaskbarIcon {
                iconText: "📁"
                tooltip: "File Manager"
                onClicked: systemBridge.launchApp("file-manager")
            }
            TaskbarIcon {
                iconText: "🐚"
                tooltip: "Terminal"
                onClicked: systemBridge.launchApp("terminal")
            }
            TaskbarIcon {
                iconText: "⚙️"
                tooltip: "Control Center"
                onClicked: systemBridge.launchApp("control-center")
            }
            TaskbarIcon {
                iconText: "🛍️"
                tooltip: "App Store"
                onClicked: systemBridge.launchApp("store")
            }
        }

        Item { Layout.fillWidth: true } // Spacer

        // Right Section: Clock & Status Indicators (Battery, Connection)
        RowLayout {
            spacing: 14
            Layout.alignment: Qt.AlignRight

            // Battery telemetry display
            Row {
                spacing: 4
                verticalAlignment: Text.AlignVCenter
                Text {
                    text: root.telemetry.battery.charging ? "⚡" : "🔋"
                    font.pixelSize: 14
                    color: root.textPrimaryColor
                }
                Text {
                    text: root.telemetry.battery.pct + "%"
                    font.pixelSize: 12
                    font.family: "Segoe UI, Inter"
                    color: root.textPrimaryColor
                }
            }

            // Wi-Fi Connection icon
            Text {
                text: "📶"
                font.pixelSize: 14
                color: root.textPrimaryColor
            }

            // Date / Time
            Column {
                Layout.alignment: Qt.AlignVCenter
                spacing: 1
                Text {
                    id: timeText
                    text: ""
                    font.pixelSize: 12
                    font.bold: true
                    font.family: "Segoe UI, Inter"
                    color: root.textPrimaryColor
                    horizontalAlignment: Text.AlignRight
                }
                Text {
                    id: dateText
                    text: ""
                    font.pixelSize: 9
                    font.family: "Segoe UI, Inter"
                    color: root.textSecondaryColor
                    horizontalAlignment: Text.AlignRight
                }
            }

            // System Time Updater
            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: {
                    var date = new Date();
                    timeText.text = date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
                    dateText.text = date.toLocaleDateString([], { month: 'short', day: 'numeric' });
                }
                Component.onCompleted: triggered()
            }

            // Quick Settings Drawer Trigger
            Button {
                id: qsButton
                flat: true
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36

                background: Rectangle {
                    radius: 18
                    color: qsButton.hovered ? "rgba(255, 255, 255, 0.1)" : "transparent"
                }

                contentItem: Text {
                    text: "⚙️"
                    font.pixelSize: 16
                    color: root.textPrimaryColor
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: {
                    root.quickSettingsOpen = !root.quickSettingsOpen;
                    root.startMenuOpen = false;
                }
            }
        }
    }
}

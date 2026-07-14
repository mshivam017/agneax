import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: rootQS
    width: 360
    height: 480
    color: root.glassBgColor
    border.color: root.borderColor
    border.width: 1
    radius: 16

    // Glowing highlight border
    Rectangle {
        anchors.fill: parent
        anchors.margins: -1
        color: "transparent"
        border.color: "rgba(255, 255, 255, 0.1)"
        border.width: 1
        radius: 16
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16

        // Header Title
        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "Quick Settings"
                font.bold: true
                font.pixelSize: 16
                font.family: "Segoe UI, Inter"
                color: root.textPrimaryColor
            }
            Item { Layout.fillWidth: true }
            Text {
                text: "v0.1.0"
                font.pixelSize: 10
                font.family: "Segoe UI, Inter"
                color: root.textSecondaryColor
            }
        }

        // Quick Settings Toggles Grid
        GridLayout {
            columns: 3
            rowSpacing: 12
            columnSpacing: 12
            Layout.fillWidth: true

            // Wi-Fi Toggle
            QSToggleButton {
                label: "Wi-Fi"
                icon: "📶"
                active: true
            }

            // Bluetooth Toggle
            QSToggleButton {
                label: "Bluetooth"
                icon: "🌐"
                active: false
            }

            // Dark Mode Toggle
            QSToggleButton {
                label: "Dark Mode"
                icon: root.isDarkMode ? "🌙" : "☀️"
                active: root.isDarkMode
                onClicked: root.isDarkMode = !root.isDarkMode
            }

            // Airplane Mode Toggle
            QSToggleButton {
                label: "Airplane"
                icon: "✈️"
                active: false
            }

            // Firewall (UFW) Toggle
            QSToggleButton {
                label: "Firewall"
                icon: "🛡️"
                active: true
            }

            // Developer Mode Toggle
            QSToggleButton {
                label: "Dev Mode"
                icon: "💻"
                active: false
            }

            // Accessibility Toggle (Step 6.1)
            QSToggleButton {
                label: "Access"
                icon: "👁️"
                active: false
            }
        }

        // Sliders Section (Volume and Brightness)
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 10

            // Volume Slider
            RowLayout {
                Layout.fillWidth: true
                Text { text: "🔊"; font.pixelSize: 14; color: root.textPrimaryColor }
                Slider {
                    id: volumeSlider
                    value: 0.7
                    Layout.fillWidth: true
                }
                Text {
                    text: Math.round(volumeSlider.value * 100) + "%"
                    font.pixelSize: 11
                    font.family: "Segoe UI, Inter"
                    color: root.textPrimaryColor
                    Layout.preferredWidth: 30
                }
            }

            // Brightness Slider
            RowLayout {
                Layout.fillWidth: true
                Text { text: "🔆"; font.pixelSize: 14; color: root.textPrimaryColor }
                Slider {
                    id: brightnessSlider
                    value: 0.8
                    Layout.fillWidth: true
                }
                Text {
                    text: Math.round(brightnessSlider.value * 100) + "%"
                    font.pixelSize: 11
                    font.family: "Segoe UI, Inter"
                    color: root.textPrimaryColor
                    Layout.preferredWidth: 30
                }
            }
        }

        // Live Resource Dashboard Telemetry Card
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: root.cardBgColor
            radius: 12
            border.color: "rgba(255, 255, 255, 0.05)"
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                Text {
                    text: "System Telemetry"
                    font.bold: true
                    font.pixelSize: 11
                    font.family: "Segoe UI, Inter"
                    color: root.textSecondaryColor
                }

                // Telemetry Data details
                RowLayout {
                    Layout.fillWidth: true
                    Column {
                        Text { text: "CPU Usage"; font.pixelSize: 10; color: root.textSecondaryColor }
                        Text {
                            text: root.telemetry.cpu_usage + "%"
                            font.bold: true
                            font.pixelSize: 16
                            color: root.accentColor
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Column {
                        Text { text: "CPU Temperature"; font.pixelSize: 10; color: root.textSecondaryColor }
                        Text {
                            text: root.telemetry.cpu_temp + "°C"
                            font.bold: true
                            font.pixelSize: 16
                            color: "#FF5E62"
                        }
                    }
                }

                // Memory Display
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Memory (RAM)"; font.pixelSize: 10; color: root.textSecondaryColor }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: root.telemetry.mem_usage_pct + "%"
                            font.pixelSize: 10
                            font.bold: true
                            color: root.textPrimaryColor
                        }
                    }

                    // Progress bar for memory
                    ProgressBar {
                        value: root.telemetry.mem_usage_pct / 100.0
                        Layout.fillWidth: true
                    }
                }

                // System Uptime Indicator
                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "System Uptime"; font.pixelSize: 10; color: root.textSecondaryColor }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: {
                            var sec = root.telemetry.uptime;
                            var h = Math.floor(sec / 3600);
                            var m = Math.floor((sec % 3600) / 60);
                            return h + "h " + m + "m";
                        }
                        font.pixelSize: 10
                        font.bold: true
                        color: root.textPrimaryColor
                    }
                }
            }
        }
    }
}

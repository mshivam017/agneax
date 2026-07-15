import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: dashboardRoot
    width: 320
    height: parent.height - 52
    color: root.glassBgColor
    border.color: root.borderColor
    border.width: 1
    radius: 0
    
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.color: "rgba(255, 255, 255, 0.08)"
        border.width: 1
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        Text {
            text: "Agneax Widgets"
            font.pixelSize: 18
            font.bold: true
            color: root.textPrimaryColor
        }

        Rectangle {
            Layout.fillWidth: true
            height: 110
            color: root.cardBgColor
            radius: 12
            border.color: root.borderColor

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 4
                
                Text {
                    id: clockText
                    font.pixelSize: 28
                    font.bold: true
                    color: root.textPrimaryColor
                    horizontalAlignment: Text.AlignHCenter
                }
                
                Text {
                    id: dateText
                    font.pixelSize: 11
                    color: root.textSecondaryColor
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            Timer {
                interval: 1000
                running: true
                repeat: true
                triggeredOnStart: true
                onTriggered: {
                    var date = new Date();
                    clockText.text = date.toLocaleTimeString(Qt.locale(), "hh:mm:ss AP");
                    dateText.text = date.toLocaleDateString(Qt.locale(), "dddd, MMMM dd, yyyy");
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 120
            color: root.cardBgColor
            radius: 12
            border.color: root.borderColor

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                Text {
                    text: "System Telemetry"
                    font.pixelSize: 11
                    font.bold: true
                    color: root.accentColor
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    ColumnLayout {
                        Layout.fillWidth: true
                        Text { text: "CPU Usage"; font.pixelSize: 9; color: root.textSecondaryColor; horizontalAlignment: Text.AlignHCenter }
                        ProgressBar {
                            value: root.telemetry.cpu_usage / 100.0
                            Layout.fillWidth: true
                        }
                        Text { text: Math.round(root.telemetry.cpu_usage) + "%"; font.pixelSize: 11; font.bold: true; color: root.textPrimaryColor; horizontalAlignment: Text.AlignHCenter }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Text { text: "RAM Usage"; font.pixelSize: 9; color: root.textSecondaryColor; horizontalAlignment: Text.AlignHCenter }
                        ProgressBar {
                            value: root.telemetry.mem_usage_pct / 100.0
                            Layout.fillWidth: true
                        }
                        Text { text: Math.round(root.telemetry.mem_usage_pct) + "%"; font.pixelSize: 11; font.bold: true; color: root.textPrimaryColor; horizontalAlignment: Text.AlignHCenter }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: root.cardBgColor
            radius: 12
            border.color: root.borderColor

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                RowLayout {
                    Text { text: "Sticky Notes"; font.pixelSize: 11; font.bold: true; color: root.accentColor }
                    Item { Layout.fillWidth: true }
                    Text { text: "Saved 📝"; font.pixelSize: 9; color: root.textSecondaryColor }
                }

                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    TextArea {
                        id: stickyNotesInput
                        placeholderText: "Type notes here..."
                        placeholderTextColor: root.textSecondaryColor
                        color: root.textPrimaryColor
                        wrapMode: TextArea.Wrap
                        font.pixelSize: 11
                        font.family: "Segoe UI, Inter"
                        selectByMouse: true
                        
                        Component.onCompleted: {
                            text = systemBridge.loadNotes();
                        }
                        
                        onTextChanged: {
                            notesTimer.restart();
                        }
                    }
                }
            }

            Timer {
                id: notesTimer
                interval: 1000
                running: false
                repeat: false
                onTriggered: {
                    systemBridge.saveNotes(stickyNotesInput.text);
                }
            }
        }
    }
}

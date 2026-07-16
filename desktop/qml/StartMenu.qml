import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: rootMenu
    width: 480
    height: 520
    color: root.glassBgColor
    border.color: root.borderColor
    border.width: 1
    radius: 16

    // Shadow effect simulation using overlapping rectangles
    Rectangle {
        anchors.fill: parent
        anchors.margins: -1
        color: "transparent"
        border.color: "rgba(255, 255, 255, 0.1)"
        border.width: 1
        radius: 16
    }

    // List of available system applications
    property var appsList: root.appsList

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16

        // Search Bar Section
        Rectangle {
            Layout.fillWidth: true
            height: 40
            color: "rgba(255, 255, 255, 0.08)"
            radius: 10
            border.color: "rgba(255, 255, 255, 0.1)"
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12

                Text {
                    text: "🔍"
                    font.pixelSize: 14
                    color: root.textSecondaryColor
                }

                TextField {
                    id: searchField
                    placeholderText: "Search apps, documents, settings..."
                    placeholderTextColor: root.textSecondaryColor
                    color: root.textPrimaryColor
                    background: null
                    Layout.fillWidth: true
                    font.family: "Segoe UI, Inter"
                    font.pixelSize: 12
                    selectByMouse: true
                    Keys.onReturnPressed: {
                        for (var i = 0; i < rootMenu.appsList.length; i++) {
                            var app = rootMenu.appsList[i];
                            if (app.name.toLowerCase().includes(searchField.text.toLowerCase())) {
                                systemBridge.launchApp(app.id);
                                root.startMenuOpen = false;
                                searchField.text = "";
                                break;
                            }
                        }
                    }
                }
            }
        }

        // Main Grid list of Apps
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            Grid {
                columns: 4
                spacing: 16
                width: parent.width

                Repeater {
                    model: rootMenu.appsList

                    delegate: Item {
                        // Search filter matching logic
                        visible: modelData.name.toLowerCase().includes(searchField.text.toLowerCase())
                        width: visible ? 100 : 0
                        height: visible ? 100 : 0

                        Rectangle {
                            anchors.fill: parent
                            color: itemMouseArea.containsMouse ? "rgba(255, 255, 255, 0.08)" : "transparent"
                            radius: 12
                            border.color: itemMouseArea.containsMouse ? "rgba(255, 255, 255, 0.1)" : "transparent"
                            border.width: 1

                            Column {
                                anchors.centerIn: parent
                                spacing: 8

                                Rectangle {
                                    width: 44
                                    height: 44
                                    radius: 12
                                    color: "rgba(255, 255, 255, 0.05)"
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.icon
                                        font.pixelSize: 22
                                    }
                                }

                                Text {
                                    text: modelData.name
                                    font.pixelSize: 10
                                    font.family: "Segoe UI, Inter"
                                    color: root.textPrimaryColor
                                    horizontalAlignment: Text.AlignHCenter
                                    width: 90
                                    elide: Text.ElideRight
                                }
                            }

                            MouseArea {
                                id: itemMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    systemBridge.launchApp(modelData.id)
                                    root.startMenuOpen = false
                                }
                            }
                        }
                    }
                }
            }
        }

        // Bottom User Profile Panel & Power Controls
        Rectangle {
            Layout.fillWidth: true
            height: 60
            color: "rgba(255, 255, 255, 0.04)"
            radius: 12
            border.color: "rgba(255, 255, 255, 0.05)"
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16

                // User Info
                Row {
                    spacing: 10
                    Layout.alignment: Qt.AlignLeft
                    Rectangle {
                        width: 36
                        height: 36
                        radius: 18
                        color: root.accentColor
                        Text {
                            anchors.centerIn: parent
                            text: "A"
                            font.bold: true
                            font.pixelSize: 16
                            color: "#0F1219"
                        }
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        Text {
                            text: "Agneax User"
                            font.pixelSize: 12
                            font.bold: true
                            font.family: "Segoe UI, Inter"
                            color: root.textPrimaryColor
                        }
                        Text {
                            text: "Standard Account"
                            font.pixelSize: 9
                            font.family: "Segoe UI, Inter"
                            color: root.textSecondaryColor
                        }
                    }
                }

                Item { Layout.fillWidth: true } // Spacer

                // Power options
                Row {
                    spacing: 8
                    Layout.alignment: Qt.AlignRight

                    Button {
                        flat: true
                        text: "🔒"
                        font.pixelSize: 14
                        onClicked: {
                            console.log("Locked Screen")
                            root.startMenuOpen = false
                        }
                    }
                    Button {
                        flat: true
                        text: "🔄"
                        font.pixelSize: 14
                        onClicked: {
                            console.log("Rebooting")
                            root.startMenuOpen = false
                        }
                    }
                    Button {
                        flat: true
                        text: "🔴"
                        font.pixelSize: 14
                        onClicked: {
                            console.log("Shutting down")
                            root.startMenuOpen = false
                            Qt.quit()
                        }
                    }
                }
            }
        }
    }
}

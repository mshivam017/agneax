import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

ApplicationWindow {
    id: storeWindow
    visible: true
    width: 920
    height: 640
    title: "Agneax Software Hub"

    // Custom UI Colors
    property string accentColor: "#00F2FE"
    property string activeAccentColor: "#00F2FE"
    property string contentBgColor: "#0F1219"
    property string cardBgColor: "#171B26"
    property string textPrimaryColor: "#FFFFFF"
    property string textSecondaryColor: "#A0AEC0"
    property string borderColor: "rgba(255, 255, 255, 0.06)"

    property string activeFilter: "All"
    property var catalogList: JSON.parse(storeBridge.getCatalog())

    // Tracks downloading status
    property var downloadingApps: ({})

    Connections {
        target: storeBridge
        onInstallProgress: {
            var temp = {...downloadingApps};
            temp[app_id] = progress / 100.0;
            downloadingApps = temp;
        }
        onInstallCompleted: {
            var temp = {...downloadingApps};
            delete temp[app_id];
            downloadingApps = temp;
            // Refresh catalog list cache
            catalogList = JSON.parse(storeBridge.getCatalog());
        }
    }

    background: Rectangle {
        color: storeWindow.contentBgColor
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Header Panel Navigation
        Rectangle {
            Layout.fillWidth: true
            height: 64
            color: "#0B0D13"
            border.color: storeWindow.borderColor
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 24
                anchors.rightMargin: 24

                Text { text: "🛍️"; font.pixelSize: 24 }
                Text {
                    text: "Agneax Software Store"
                    font.bold: true
                    font.pixelSize: 15
                    font.family: "Segoe UI, Inter"
                    color: storeWindow.textPrimaryColor
                }

                Item { Layout.fillWidth: true } // Spacer

                // App category filters Row
                Row {
                    spacing: 12
                    CategoryButton { label: "All"; active: storeWindow.activeFilter == "All"; onClicked: storeWindow.activeFilter = "All" }
                    CategoryButton { label: "Developer"; active: storeWindow.activeFilter == "Developer"; onClicked: storeWindow.activeFilter = "Developer" }
                    CategoryButton { label: "Graphics"; active: storeWindow.activeFilter == "Graphics"; onClicked: storeWindow.activeFilter = "Graphics" }
                    CategoryButton { label: "Gaming"; active: storeWindow.activeFilter == "Gaming"; onClicked: storeWindow.activeFilter = "Gaming" }
                    CategoryButton { label: "Internet"; active: storeWindow.activeFilter == "Internet"; onClicked: storeWindow.activeFilter = "Internet" }
                }
            }
        }

        // Main body split: Featured banner + App List
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ColumnLayout {
                width: parent.width - 40
                anchors.top: parent.top
                anchors.topMargin: 20
                anchors.left: parent.left
                anchors.leftMargin: 20
                spacing: 20

                // Premium Hero banner (Blender 3D suite)
                Rectangle {
                    Layout.fillWidth: true
                    height: 180
                    radius: 16
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#FF5E62" }
                        GradientStop { position: 1.0; color: "#B06AB3" }
                    }

                    // Banner highlights
                    Rectangle {
                        anchors.fill: parent
                        radius: 16
                        color: "rgba(0, 0, 0, 0.4)"
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 28
                        spacing: 20

                        Text {
                            text: "🎨"
                            font.pixelSize: 80
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 6
                            Text {
                                text: "FEATURED APPLICATION"
                                font.pixelSize: 9
                                font.bold: true
                                color: "#00F2FE"
                            }
                            Text {
                                text: "Blender 3D Suite"
                                font.bold: true
                                font.pixelSize: 22
                                color: "#FFFFFF"
                            }
                            Text {
                                text: "Create stunning 3D graphics, animations, models, and video edits inside the native Linux environment."
                                font.pixelSize: 11
                                color: "#E2E8F0"
                                Layout.preferredWidth: 450
                                wrapMode: Text.WordWrap
                            }
                        }

                        Button {
                            text: "Install Now"
                            background: Rectangle {
                                radius: 8
                                color: "#FFFFFF"
                            }
                            contentItem: Text {
                                text: "Install Now"
                                font.bold: true
                                color: "#1A202C"
                            }
                            onClicked: storeBridge.installApp("blender")
                        }
                    }
                }

                // Grid Catalog list
                Text {
                    text: "Available Applications"
                    font.bold: true
                    font.pixelSize: 14
                    color: storeWindow.textPrimaryColor
                }

                Grid {
                    columns: 2
                    spacing: 16
                    width: parent.width

                    Repeater {
                        model: storeWindow.catalogList

                        delegate: Item {
                            // Filter logic
                            visible: storeWindow.activeFilter == "All" || modelData.category == storeWindow.activeFilter
                            width: visible ? 420 : 0
                            height: visible ? 130 : 0

                            Rectangle {
                                anchors.fill: parent
                                color: storeWindow.cardBgColor
                                radius: 14
                                border.color: storeWindow.borderColor
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 16
                                    spacing: 16

                                    // App icon
                                    Rectangle {
                                        width: 56
                                        height: 56
                                        radius: 12
                                        color: "rgba(255, 255, 255, 0.05)"
                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.icon
                                            font.pixelSize: 32
                                        }
                                    }

                                    // Info
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 4
                                        RowLayout {
                                            Text {
                                                text: modelData.name
                                                font.bold: true
                                                font.pixelSize: 12
                                                color: storeWindow.textPrimaryColor
                                            }
                                            Text {
                                                text: modelData.flatpak ? "Flatpak" : "APT"
                                                font.pixelSize: 8
                                                font.bold: true
                                                color: modelData.flatpak ? "#00F2FE" : "#FF5E62"
                                                background: Rectangle {
                                                    color: "rgba(255, 255, 255, 0.06)"
                                                    radius: 4
                                                    anchors.margins: -4
                                                }
                                            }
                                        }
                                        Text {
                                            text: modelData.desc
                                            font.pixelSize: 10
                                            color: storeWindow.textSecondaryColor
                                            Layout.preferredWidth: 220
                                            wrapMode: Text.WordWrap
                                            elide: Text.ElideRight
                                            maximumLineCount: 2
                                        }
                                        Text {
                                            text: "Size: " + modelData.size + " | Category: " + modelData.category
                                            font.pixelSize: 9
                                            color: storeWindow.textSecondaryColor
                                        }
                                    }

                                    // Action / Progress section
                                    ColumnLayout {
                                        Layout.alignment: Qt.AlignRight

                                        // Install button
                                        Button {
                                            id: actionBtn
                                            visible: !(modelData.id in storeWindow.downloadingApps)
                                            text: modelData.installed ? "Uninstall" : "Install"
                                            
                                            background: Rectangle {
                                                radius: 8
                                                color: modelData.installed ? "rgba(255, 94, 98, 0.15)" : "rgba(0, 242, 254, 0.15)"
                                                border.color: modelData.installed ? "#FF5E62" : "#00F2FE"
                                                border.width: 1
                                            }
                                            contentItem: Text {
                                                text: actionBtn.text
                                                font.bold: true
                                                color: modelData.installed ? "#FF5E62" : "#00F2FE"
                                                horizontalAlignment: Text.AlignHCenter
                                            }

                                            onClicked: {
                                                if (modelData.installed) {
                                                    storeBridge.uninstallApp(modelData.id);
                                                } else {
                                                    storeBridge.installApp(modelData.id);
                                                }
                                            }
                                        }

                                        // Progress indicators during download/install
                                        Column {
                                            visible: modelData.id in storeWindow.downloadingApps
                                            spacing: 4
                                            width: 80
                                            Text {
                                                text: "Installing..."
                                                font.pixelSize: 9
                                                color: storeWindow.textSecondaryColor
                                                horizontalAlignment: Text.AlignHCenter
                                            }
                                            ProgressBar {
                                                width: 80
                                                value: storeWindow.downloadingApps[modelData.id] || 0.0
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

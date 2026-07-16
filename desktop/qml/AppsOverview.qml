import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: overviewRoot
    color: isDarkMode ? "rgba(10, 12, 18, 0.92)" : "rgba(240, 244, 248, 0.95)"
    z: 100

    property bool isDarkMode: false
    property string textPrimaryColor: "#FFFFFF"
    property string textSecondaryColor: "#A0AEC0"
    property string accentColor: "#00F2FE"
    property var appsList: []
    property string searchFilter: ""
    property string activeCategory: "All"

    signal closeRequested()

    // Background blur fallback styling
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.color: "rgba(255, 255, 255, 0.05)"
        border.width: 1
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 40
        spacing: 24

        // Top: Close Button & Header
        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "Applications Drawer"
                font.family: "Segoe UI, Inter"
                font.bold: true
                font.pixelSize: 28
                color: overviewRoot.textPrimaryColor
            }
            Item { Layout.fillWidth: true }
            Button {
                flat: true
                text: "✕"
                font.pixelSize: 22
                contentItem: Text {
                    text: parent.text
                    font: parent.font
                    color: overviewRoot.textPrimaryColor
                }
                onClicked: overviewRoot.closeRequested()
            }
        }

        // Search Bar Section
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 600
            height: 48
            color: "rgba(255, 255, 255, 0.08)"
            radius: 12
            border.color: "rgba(255, 255, 255, 0.15)"
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16

                Text {
                    text: "🔍"
                    font.pixelSize: 18
                    color: overviewRoot.textSecondaryColor
                }

                TextField {
                    id: searchField
                    placeholderText: "Search apps..."
                    placeholderTextColor: overviewRoot.textSecondaryColor
                    color: overviewRoot.textPrimaryColor
                    background: null
                    Layout.fillWidth: true
                    font.family: "Segoe UI, Inter"
                    font.pixelSize: 14
                    selectByMouse: true
                    onTextChanged: overviewRoot.searchFilter = text.toLowerCase()
                }
            }
        }

        // Categories Navigation Bar
        Row {
            Layout.alignment: Qt.AlignHCenter
            spacing: 12

            Repeater {
                model: ["All", "System", "Internet", "Office", "Utilities", "Multimedia"]
                delegate: Button {
                    flat: true
                    text: modelData
                    font.bold: overviewRoot.activeCategory === modelData
                    font.pixelSize: 13
                    
                    background: Rectangle {
                        radius: 8
                        color: overviewRoot.activeCategory === modelData ? overviewRoot.accentColor : "transparent"
                    }

                    contentItem: Text {
                        text: parent.text
                        font: parent.font
                        color: overviewRoot.activeCategory === modelData ? "#0F1219" : overviewRoot.textPrimaryColor
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: overviewRoot.activeCategory = modelData
                }
            }
        }

        // Main Grid list of Apps
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            Flow {
                width: parent.width - 20
                spacing: 24
                padding: 10

                Repeater {
                    model: overviewRoot.appsList
                    delegate: Item {
                        visible: modelData.name.toLowerCase().includes(overviewRoot.searchFilter) && (overviewRoot.activeCategory === "All" || modelData.category === overviewRoot.activeCategory)
                        width: visible ? 120 : 0
                        height: visible ? 120 : 0

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 8
                            anchors.centerIn: parent

                            // App Icon container
                            Rectangle {
                                Layout.alignment: Qt.AlignHCenter
                                width: 72
                                height: 72
                                radius: 16
                                color: appMouseArea.hovered ? "rgba(255, 255, 255, 0.12)" : "rgba(255, 255, 255, 0.05)"
                                border.color: appMouseArea.hovered ? overviewRoot.accentColor : "transparent"
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.icon
                                    font.pixelSize: 36
                                }
                            }

                            // App Name Label
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                Layout.maximumWidth: 100
                                text: modelData.name
                                font.family: "Segoe UI, Inter"
                                font.pixelSize: 12
                                font.bold: true
                                color: overviewRoot.textPrimaryColor
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }

                        MouseArea {
                            id: appMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                systemBridge.launchApp(modelData.id);
                                overviewRoot.closeRequested();
                            }
                        }
                    }
                }
            }
        }
    }
}

import QtQuick 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: dockRoot
    height: 64
    width: dockRow.width + 32
    color: "rgba(20, 24, 33, 0.6)"
    border.color: "rgba(255, 255, 255, 0.08)"
    border.width: 1
    radius: 20

    property int hoveredIndex: -1

    // Inner glow
    Rectangle {
        anchors.fill: parent
        radius: 20
        color: "transparent"
        border.color: "rgba(255, 255, 255, 0.12)"
        border.width: 1
    }

    Row {
        id: dockRow
        anchors.centerIn: parent
        spacing: 14

        DockItem { itemIndex: 0; iconText: "🌐"; tooltip: "Firefox Browser"; onClicked: systemBridge.launchApp("firefox") }
        DockItem { itemIndex: 1; iconText: "📁"; tooltip: "Files"; onClicked: systemBridge.launchApp("file-manager") }
        DockItem { itemIndex: 2; iconText: "🐚"; tooltip: "Console"; onClicked: systemBridge.launchApp("terminal") }
        DockItem { itemIndex: 3; iconText: "🛍️"; tooltip: "App Hub"; onClicked: systemBridge.launchApp("store") }
        DockItem { itemIndex: 4; iconText: "⚙️"; tooltip: "Settings"; onClicked: systemBridge.launchApp("control-center") }
    }
}

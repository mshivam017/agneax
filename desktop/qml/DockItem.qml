import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: rootItem
    width: 44
    height: 44

    property string iconText: "📁"
    property string tooltip: "App"
    signal clicked()

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: rootItem.clicked()
    }

    // Zoom and jump effects on hover
    scale: mouseArea.containsMouse ? 1.35 : 1.0
    y: mouseArea.containsMouse ? -8 : 0

    Behavior on scale {
        NumberAnimation { duration: 150; easing.type: Easing.OutBack }
    }
    Behavior on y {
        NumberAnimation { duration: 150; easing.type: Easing.OutBack }
    }

    // Graphical Circle
    Rectangle {
        anchors.fill: parent
        radius: 22
        color: "rgba(255, 255, 255, 0.08)"
        border.color: mouseArea.containsMouse ? root.accentColor : "rgba(255, 255, 255, 0.1)"
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: rootItem.iconText
            font.pixelSize: 22
        }
    }

    // Floating tooltip
    Rectangle {
        id: tooltipBox
        visible: mouseArea.containsMouse
        anchors.bottom: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 14
        height: 22
        width: label.width + 16
        color: "#0F1219"
        border.color: "rgba(255,255,255,0.08)"
        radius: 6

        Text {
            id: label
            anchors.centerIn: parent
            text: rootItem.tooltip
            font.pixelSize: 9
            font.bold: true
            font.family: "Segoe UI, Inter"
            color: "#FFFFFF"
        }
    }
}

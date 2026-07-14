import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: root
    width: 44
    height: 44

    property string iconText: "📁"
    property string tooltip: "App"
    signal clicked()

    MouseArea {
        id: clickArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }

    // Hover background highlight
    Rectangle {
        anchors.fill: parent
        radius: 8
        color: "rgba(255, 255, 255, 0.08)"
        visible: clickArea.containsMouse
        scale: clickArea.pressed ? 0.90 : 1.0

        Behavior on scale {
            NumberAnimation { duration: 100 }
        }
    }

    Text {
        anchors.centerIn: parent
        text: root.iconText
        font.pixelSize: 22
        scale: clickArea.containsMouse ? 1.1 : 1.0
        
        Behavior on scale {
            NumberAnimation { duration: 100 }
        }
    }

    // Modern flat tooltip popup on hover
    Rectangle {
        id: tooltipRect
        visible: clickArea.containsMouse
        anchors.bottom: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 8
        height: 24
        width: tooltipText.width + 16
        color: "#1E222B"
        border.color: "rgba(255, 255, 255, 0.1)"
        border.width: 1
        radius: 6

        Text {
            id: tooltipText
            anchors.centerIn: parent
            text: root.tooltip
            font.pixelSize: 10
            font.bold: true
            font.family: "Segoe UI, Inter"
            color: "#FFFFFF"
        }
    }
}

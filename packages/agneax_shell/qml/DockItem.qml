import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: rootItem
    width: 44
    height: 44

    property string iconText: "📁"
    property string tooltip: "App"
    property int itemIndex: -1
    signal clicked()

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: rootItem.clicked()
        onContainsMouseChanged: {
            if (parent && parent.parent) {
                if (containsMouse) {
                    parent.parent.hoveredIndex = itemIndex;
                } else if (parent.parent.hoveredIndex === itemIndex) {
                    parent.parent.hoveredIndex = -1;
                }
            }
        }
    }

    // Proximity magnification curve calculation
    scale: {
        if (parent && parent.parent && parent.parent.hoveredIndex !== -1) {
            var diff = Math.abs(parent.parent.hoveredIndex - itemIndex);
            if (diff === 0) return 1.35;
            if (diff === 1) return 1.15;
        }
        return 1.0;
    }

    y: {
        if (parent && parent.parent && parent.parent.hoveredIndex !== -1) {
            var diff = Math.abs(parent.parent.hoveredIndex - itemIndex);
            if (diff === 0) return -12;
            if (diff === 1) return -6;
        }
        return 0;
    }

    Behavior on scale {
        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
    }
    Behavior on y {
        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
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

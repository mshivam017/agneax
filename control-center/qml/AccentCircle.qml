import QtQuick 2.15

Rectangle {
    id: root
    width: 28
    height: 28
    radius: 14
    color: colorCode

    property string colorCode: "#00F2FE"
    property bool selected: false
    signal clicked()

    border.color: root.selected ? "#FFFFFF" : "rgba(255, 255, 255, 0.2)"
    border.width: root.selected ? 2 : 1

    MouseArea {
        id: clickArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }

    // Hover scale animation
    scale: clickArea.containsMouse ? 1.15 : 1.0

    Behavior on scale {
        NumberAnimation { duration: 100 }
    }
}

import QtQuick 2.15
import QtQuick.Controls 2.15

Button {
    id: control
    flat: true

    property string label: "Filter"
    property bool active: false

    background: Rectangle {
        radius: 8
        color: control.active ? "rgba(0, 242, 254, 0.15)" : (control.hovered ? "rgba(255, 255, 255, 0.04)" : "transparent")
        border.color: control.active ? storeWindow.accentColor : "transparent"
        border.width: 1

        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }

    contentItem: Text {
        text: control.label
        font.pixelSize: 11
        font.bold: control.active
        font.family: "Segoe UI, Inter"
        color: control.active ? "#FFFFFF" : storeWindow.textSecondaryColor
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}

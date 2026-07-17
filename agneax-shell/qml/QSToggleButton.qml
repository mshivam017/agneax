import QtQuick 2.15
import QtQuick.Controls 2.15

Button {
    id: control
    flat: true
    Layout.preferredWidth: 90
    Layout.preferredHeight: 70

    property string label: "Toggle"
    property string icon: "📶"
    property bool active: false

    background: Rectangle {
        radius: 12
        color: control.active ? "rgba(0, 242, 254, 0.2)" : "rgba(255, 255, 255, 0.05)"
        border.color: control.active ? root.accentColor : "rgba(255, 255, 255, 0.08)"
        border.width: 1

        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }

    contentItem: Column {
        anchors.centerIn: parent
        spacing: 4

        Text {
            text: control.icon
            font.pixelSize: 18
            horizontalAlignment: Text.AlignHCenter
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: control.label
            font.pixelSize: 9
            font.family: "Segoe UI, Inter"
            font.bold: true
            color: control.active ? root.accentColor : root.textSecondaryColor
            horizontalAlignment: Text.AlignHCenter
            anchors.horizontalCenter: parent.horizontalCenter
            elide: Text.ElideRight
            width: 80
        }
    }
}

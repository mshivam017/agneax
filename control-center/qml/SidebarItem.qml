import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Button {
    id: control
    flat: true
    Layout.fillWidth: true
    Layout.preferredHeight: 40
    Layout.leftMargin: 8
    Layout.rightMargin: 8

    property string title: "Item"
    property string icon: "📄"
    property bool active: false

    background: Rectangle {
        radius: 8
        color: control.active ? "rgba(0, 242, 254, 0.15)" : (control.hovered ? "rgba(255, 255, 255, 0.04)" : "transparent")
        
        // Active accent highlight bar
        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 3
            color: ccWindow.activeAccentColor
            visible: control.active
            radius: 1.5
        }
    }

    contentItem: RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        spacing: 12

        Text {
            text: control.icon
            font.pixelSize: 14
            color: control.active ? ccWindow.activeAccentColor : ccWindow.textPrimaryColor
        }

        Text {
            text: control.title
            font.pixelSize: 11
            font.family: "Segoe UI, Inter"
            font.bold: control.active
            color: control.active ? ccWindow.textPrimaryColor : ccWindow.textSecondaryColor
            Layout.fillWidth: true
        }
    }
}

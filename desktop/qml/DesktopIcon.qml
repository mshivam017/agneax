import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: root
    width: 80
    height: 90

    property string iconName: "Shortcut"
    property string iconSource: "folder"
    property string accentColor: "#00F2FE"
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
        color: root.isDarkMode ? "rgba(255, 255, 255, 0.08)" : "rgba(0, 0, 0, 0.06)"
        visible: clickArea.containsMouse
        scale: clickArea.pressed ? 0.95 : 1.0

        Behavior on scale {
            NumberAnimation { duration: 100 }
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 6
        width: parent.width

        // Icon Graphic using simple vector shapes for ultimate self-containment
        Rectangle {
            width: 48
            height: 48
            radius: 12
            color: clickArea.containsMouse ? root.accentColor : "rgba(45, 55, 72, 0.7)"
            anchors.horizontalCenter: parent.horizontalCenter

            // Glassmorphism shine
            Rectangle {
                anchors.fill: parent
                radius: 12
                color: "transparent"
                border.color: "rgba(255, 255, 255, 0.15)"
                border.width: 1
            }

            // Custom text/character icon based on type
            Text {
                anchors.centerIn: parent
                text: {
                    if (root.iconSource == "folder") return "📁";
                    if (root.iconSource == "terminal") return "🐚";
                    if (root.iconSource == "settings") return "⚙️";
                    if (root.iconSource == "shopping-bag") return "🛍️";
                    if (root.iconSource == "download") return "💾";
                    return "📄";
                }
                font.pixelSize: 22
            }
        }

        // Icon text label
        Text {
            text: root.iconName
            font.pixelSize: 11
            font.family: "Segoe UI, Inter, Roboto"
            color: "#FFFFFF"
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            width: parent.width
            style: Text.Outline
            styleColor: "rgba(0,0,0,0.5)"
        }
    }
}

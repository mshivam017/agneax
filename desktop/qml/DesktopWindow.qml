import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: windowRoot
    width: 640
    height: 400
    color: "rgba(20, 24, 33, 0.9)"
    border.color: "rgba(255, 255, 255, 0.15)"
    border.width: 1
    radius: 12
    clip: true

    property string windowTitle: "Application"
    property string iconText: "📄"
    property bool isMaximized: false
    property var previousGeometry: ({"x": 100, "y": 100, "width": 640, "height": 400})

    // Snapping indicator targets
    signal windowSnapped(int direction) // 1=Left, 2=Right, 7=Fullscreen

    // Title Bar
    Rectangle {
        id: titleBar
        width: parent.width
        height: 38
        color: "rgba(255, 255, 255, 0.03)"
        border.color: "rgba(255, 255, 255, 0.05)"
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 8

            Text {
                text: windowRoot.iconText
                font.pixelSize: 16
            }

            Text {
                text: windowRoot.windowTitle
                font.bold: true
                font.pixelSize: 11
                font.family: "Segoe UI, Inter"
                color: "#FFFFFF"
                Layout.fillWidth: true
            }

            // Window Controls (Minimize, Maximize, Close)
            Row {
                spacing: 8
                Layout.alignment: Qt.AlignRight

                // Minimize
                Rectangle {
                    width: 12; height: 12; radius: 6; color: "#FFDF00"
                    MouseArea {
                        anchors.fill: parent
                        onClicked: windowRoot.visible = false
                    }
                }
                // Maximize
                Rectangle {
                    width: 12; height: 12; radius: 6; color: "#00F2FE"
                    MouseArea {
                        anchors.fill: parent
                        onClicked: toggleMaximize()
                    }
                }
                // Close
                Rectangle {
                    width: 12; height: 12; radius: 6; color: "#FF5E62"
                    MouseArea {
                        anchors.fill: parent
                        onClicked: windowRoot.destroy()
                    }
                }
            }
        }

        // Drag Handler
        MouseArea {
            anchors.fill: parent
            property point clickPos: "0,0"
            onPressed: {
                clickPos = Qt.point(mouse.x, mouse.y)
            }
            onPositionChanged: {
                if (windowRoot.isMaximized) return;
                var delta = Qt.point(mouse.x - clickPos.x, mouse.y - clickPos.y)
                windowRoot.x += delta.x
                windowRoot.y += delta.y

                // Snap Detection during drag
                checkSnapTriggers(windowRoot.x + mouse.x, windowRoot.y + mouse.y)
            }
            onReleased: {
                finalizeSnap(windowRoot.x + mouse.x, windowRoot.y + mouse.y)
            }
        }
    }

    // Window Inner Client Content Area
    Rectangle {
        anchors.top: titleBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        color: "transparent"

        // Placeholder content
        Text {
            anchors.centerIn: parent
            text: windowRoot.windowTitle + " GUI Viewport"
            font.pixelSize: 16
            color: "rgba(255,255,255,0.4)"
        }
    }

    function toggleMaximize() {
        if (!isMaximized) {
            previousGeometry = {"x": windowRoot.x, "y": windowRoot.y, "width": windowRoot.width, "height": windowRoot.height}
            // Ask systemBridge for fullscreen snap layout details
            var geom = JSON.parse(systemBridge.calculateSnapGeometry(root.width, root.height, panel.height, 7))
            windowRoot.x = geom.x
            windowRoot.y = geom.y
            windowRoot.width = geom.width
            windowRoot.height = geom.height
            windowRoot.radius = 0
            isMaximized = true
        } else {
            windowRoot.x = previousGeometry.x
            windowRoot.y = previousGeometry.y
            windowRoot.width = previousGeometry.width
            windowRoot.height = previousGeometry.height
            windowRoot.radius = 12
            isMaximized = false
        }
    }

    function checkSnapTriggers(mx, my) {
        // Trigger visual snapping guides previews
        if (mx < 50) {
            root.snapPreviewDirection = 1; // Left snap preview
        } else if (mx > root.width - 50) {
            root.snapPreviewDirection = 2; // Right snap preview
        } else if (my < 30) {
            root.snapPreviewDirection = 7; // Fullscreen snap preview
        } else {
            root.snapPreviewDirection = 0; // Hide preview
        }
    }

    function finalizeSnap(mx, my) {
        root.snapPreviewDirection = 0;
        if (mx < 50) {
            snapToDirection(1); // Left
        } else if (mx > root.width - 50) {
            snapToDirection(2); // Right
        } else if (my < 30) {
            snapToDirection(7); // Fullscreen
        }
    }

    function snapToDirection(direction) {
        var geom = JSON.parse(systemBridge.calculateSnapGeometry(root.width, root.height, panel.height, direction))
        windowRoot.x = geom.x
        windowRoot.y = geom.y
        windowRoot.width = geom.width
        windowRoot.height = geom.height
        if (direction == 7) {
            windowRoot.radius = 0;
            isMaximized = true;
        } else {
            windowRoot.radius = 12;
            isMaximized = false;
        }
    }
}

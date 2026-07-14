import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

ApplicationWindow {
    id: instWindow
    visible: true
    width: 780
    height: 520
    title: "Agneax OS Installation System"

    // Custom UI Colors
    property string activeAccentColor: "#00F2FE"
    property string contentBgColor: "#0F1219"
    property string cardBgColor: "#171B26"
    property string textPrimaryColor: "#FFFFFF"
    property string textSecondaryColor: "#A0AEC0"
    property string borderColor: "rgba(255, 255, 255, 0.06)"

    // Wizard wizard step control
    property int currentStep: 0

    // User credential data inputs
    property string selectedDrive: ""
    property string username: ""
    property string password: ""
    property string hostname: "agneax-pc"

    // Discovered target drives
    property var targetDrives: JSON.parse(installerBridge.getDrives())

    // Progress metrics
    property real progressPct: 0.0
    property string statusMsg: "Preparing installation..."
    property string completionMsg: ""

    Connections {
        target: installerBridge
        onInstallProgress: {
            instWindow.progressPct = pct / 100.0;
            instWindow.statusMsg = status;
        }
        onInstallCompleted: {
            if (success) {
                instWindow.completionMsg = log;
                instWindow.currentStep = 4; // Complete slide
            } else {
                instWindow.statusMsg = "Error: " + log;
            }
        }
    }

    background: Rectangle {
        color: instWindow.contentBgColor
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 30
        spacing: 20

        // Top Header
        RowLayout {
            Layout.fillWidth: true
            Text { text: "💾"; font.pixelSize: 24 }
            Text {
                text: "Agneax OS System Installation Wizard"
                font.bold: true
                font.pixelSize: 15
                font.family: "Segoe UI, Inter"
                color: instWindow.textPrimaryColor
            }
            Item { Layout.fillWidth: true }
            Text {
                text: "Step " + (instWindow.currentStep + 1) + " of 5"
                font.pixelSize: 10
                font.family: "Segoe UI, Inter"
                color: instWindow.textSecondaryColor
                visible: instWindow.currentStep < 4
            }
        }

        // Main wizard stack layouts
        StackLayout {
            id: wizardStack
            currentIndex: instWindow.currentStep
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Step 0: Welcome & Locale setup
            ColumnLayout {
                spacing: 16
                Layout.fillWidth: true

                Rectangle {
                    Layout.fillWidth: true
                    height: 280
                    color: instWindow.cardBgColor
                    radius: 12
                    border.color: instWindow.borderColor

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 24
                        spacing: 12
                        
                        Text {
                            text: "Welcome to Agneax OS"
                            font.bold: true
                            font.pixelSize: 22
                            color: instWindow.activeAccentColor
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Text {
                            text: "This helper wizard will guide you through setting up and installing a clean copy of Agneax OS on your computer. Please select your preferences below."
                            font.pixelSize: 11
                            color: instWindow.textSecondaryColor
                            horizontalAlignment: Text.AlignHCenter
                            Layout.preferredWidth: 500
                            anchors.horizontalCenter: parent.horizontalCenter
                            wrapMode: Text.WordWrap
                        }

                        RowLayout {
                            spacing: 20
                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: 12

                            Column {
                                spacing: 4
                                Text { text: "Select System Language"; font.pixelSize: 10; color: instWindow.textSecondaryColor }
                                ComboBox {
                                    model: ["English (United States)", "Español (España)", "Deutsch (Deutschland)", "Français (France)"]
                                    width: 200
                                }
                            }

                            Column {
                                spacing: 4
                                Text { text: "Select Keyboard Layout"; font.pixelSize: 10; color: instWindow.textSecondaryColor }
                                ComboBox {
                                    model: ["English (US)", "English (UK)", "Spanish", "German QWERTZ"]
                                    width: 200
                                }
                            }
                        }
                    }
                }
            }

            // Step 1: Disk selection and partitioning
            ColumnLayout {
                spacing: 16
                Layout.fillWidth: true

                Rectangle {
                    Layout.fillWidth: true
                    height: 350
                    color: instWindow.cardBgColor
                    radius: 12
                    border.color: instWindow.borderColor

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 12

                        Text { text: "Select Target Drive & Partition Setup"; font.bold: true; font.pixelSize: 13; color: instWindow.textPrimaryColor }

                        ListModel {
                            id: driveListModel
                            Component.onCompleted: {
                                for(var i = 0; i < instWindow.targetDrives.length; i++) {
                                    append(instWindow.targetDrives[i]);
                                }
                            }
                        }

                        ListView {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 110
                            model: driveListModel
                            spacing: 6
                            clip: true
                            delegate: Rectangle {
                                width: parent.width
                                height: 44
                                radius: 8
                                color: instWindow.selectedDrive == model.path ? "rgba(0, 242, 254, 0.1)" : "rgba(255, 255, 255, 0.03)"
                                border.color: instWindow.selectedDrive == model.path ? instWindow.activeAccentColor : "rgba(255, 255, 255, 0.08)"
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12

                                    Text { text: "💽"; font.pixelSize: 16 }
                                    Column {
                                        Text { text: model.model; font.bold: true; font.pixelSize: 10; color: instWindow.textPrimaryColor }
                                        Text { text: model.path + " | " + model.type; font.pixelSize: 8; color: instWindow.textSecondaryColor }
                                    }
                                    Item { Layout.fillWidth: true }
                                    Text { text: model.size; font.pixelSize: 10; font.bold: true; color: instWindow.textPrimaryColor }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: instWindow.selectedDrive = model.path
                                }
                            }
                        }

                        // Partition Visualizer Grid (Step 4.1)
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            visible: instWindow.selectedDrive !== ""

                            Text { text: "Automatic Partition Tiling Layout Map:"; font.pixelSize: 9; color: instWindow.textSecondaryColor }
                            RowLayout {
                                spacing: 4
                                Layout.fillWidth: true
                                height: 28

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: 15
                                    height: 28; color: "#00F2FE"; radius: 4
                                    Text { anchors.centerIn: parent; text: "sda1\nEFI (512MB)"; font.pixelSize: 8; font.bold: true; color: "#0F1219"; horizontalAlignment: Text.AlignHCenter }
                                }
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: 70
                                    height: 28; color: "#1E293B"; radius: 4; border.color: "rgba(255,255,255,0.1)"
                                    Text { anchors.centerIn: parent; text: "sda2 (System ext4 Rootfs)"; font.pixelSize: 8; color: "#FFFFFF"; horizontalAlignment: Text.AlignHCenter }
                                }
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: 15
                                    height: 28; color: "#FF5E62"; radius: 4
                                    Text { anchors.centerIn: parent; text: "sda3\nSwap (4GB)"; font.pixelSize: 8; font.bold: true; color: "#FFFFFF"; horizontalAlignment: Text.AlignHCenter }
                                }
                            }
                        }

                        // LUKS Disk Encryption (Step 4.2)
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12
                            visible: instWindow.selectedDrive !== ""

                            Switch {
                                id: encryptSwitch
                                text: "Encrypt Agneax installation drive (LUKS)"
                                font.pixelSize: 10
                                font.bold: true
                            }
                            Item { Layout.fillWidth: true }
                            TextField {
                                placeholderText: "Encryption Passphrase"
                                echoMode: TextInput.Password
                                visible: encryptSwitch.checked
                                font.pixelSize: 9
                                selectByMouse: true
                                width: 180
                            }
                        }
                    }
                }
            }

            // Step 2: User Account Creation
            ColumnLayout {
                spacing: 16
                Layout.fillWidth: true

                Rectangle {
                    Layout.fillWidth: true
                    height: 280
                    color: instWindow.cardBgColor
                    radius: 12
                    border.color: instWindow.borderColor

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 24
                        spacing: 12

                        Text { text: "Create Administrator Account"; font.bold: true; font.pixelSize: 14; color: instWindow.textPrimaryColor }

                        GridLayout {
                            columns: 2
                            rowSpacing: 10
                            columnSpacing: 20
                            Layout.fillWidth: true

                            Text { text: "Your Name:"; color: instWindow.textSecondaryColor; font.pixelSize: 11 }
                            TextField {
                                id: usernameInput
                                placeholderText: "e.g. administrator"
                                color: instWindow.textPrimaryColor
                                Layout.fillWidth: true
                                selectByMouse: true
                            }

                            Text { text: "Computer Name:"; color: instWindow.textSecondaryColor; font.pixelSize: 11 }
                            TextField {
                                id: hostnameInput
                                text: "agneax-pc"
                                color: instWindow.textPrimaryColor
                                Layout.fillWidth: true
                                selectByMouse: true
                            }

                            Text { text: "Create Password:"; color: instWindow.textSecondaryColor; font.pixelSize: 11 }
                            TextField {
                                id: passwordInput
                                echoMode: TextInput.Password
                                placeholderText: "Choose a strong password"
                                color: instWindow.textPrimaryColor
                                Layout.fillWidth: true
                                selectByMouse: true
                            }
                        }
                    }
                }
            }

            // Step 3: Installation progress
            ColumnLayout {
                spacing: 20
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter

                Rectangle {
                    Layout.fillWidth: true
                    height: 200
                    color: instWindow.cardBgColor
                    radius: 12
                    border.color: instWindow.borderColor

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 24
                        spacing: 16
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            text: "Installing Agneax OS..."
                            font.bold: true
                            font.pixelSize: 16
                            color: instWindow.textPrimaryColor
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        ProgressBar {
                            value: instWindow.progressPct
                            Layout.fillWidth: true
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Text {
                            text: instWindow.statusMsg
                            font.pixelSize: 11
                            color: instWindow.textSecondaryColor
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }
            }

            // Step 4: Finished Setup
            ColumnLayout {
                spacing: 20
                Layout.fillWidth: true

                Rectangle {
                    Layout.fillWidth: true
                    height: 280
                    color: instWindow.cardBgColor
                    radius: 12
                    border.color: instWindow.borderColor

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 24
                        spacing: 16

                        Text {
                            text: "🎉 System Installation Completed!"
                            font.bold: true
                            font.pixelSize: 22
                            color: instWindow.activeAccentColor
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Text {
                            text: instWindow.completionMsg
                            font.pixelSize: 11
                            color: instWindow.textSecondaryColor
                            horizontalAlignment: Text.AlignHCenter
                            Layout.preferredWidth: 450
                            anchors.horizontalCenter: parent.horizontalCenter
                            wrapMode: Text.WordWrap
                        }

                        Button {
                            text: "Reboot System"
                            Layout.alignment: Qt.AlignHCenter
                            background: Rectangle {
                                radius: 8
                                color: instWindow.activeAccentColor
                            }
                            contentItem: Text {
                                text: "Reboot Now"
                                font.bold: true
                                color: "#0F1219"
                            }
                            onClicked: Qt.quit()
                        }
                    }
                }
            }
        }

        // Bottom Navigation Buttons Control
        RowLayout {
            Layout.fillWidth: true
            visible: instWindow.currentStep < 3

            Button {
                text: "Back"
                enabled: instWindow.currentStep > 0
                onClicked: instWindow.currentStep--
            }

            Item { Layout.fillWidth: true } // Spacer

            Button {
                text: instWindow.currentStep == 2 ? "Install Now" : "Next"
                enabled: {
                    if (instWindow.currentStep == 1 && instWindow.selectedDrive == "") return false;
                    return true;
                }
                background: Rectangle {
                    radius: 6
                    color: enabled ? instWindow.activeAccentColor : "rgba(255,255,255,0.05)"
                }
                contentItem: Text {
                    text: instWindow.currentStep == 2 ? "Install Now" : "Next"
                    font.bold: true
                    color: enabled ? "#0F1219" : "#4A5568"
                }

                onClicked: {
                    if (instWindow.currentStep == 2) {
                        instWindow.username = usernameInput.text;
                        instWindow.password = passwordInput.text;
                        instWindow.hostname = hostnameInput.text;
                        installerBridge.startInstallation(instWindow.selectedDrive, instWindow.username, instWindow.password, instWindow.hostname);
                    }
                    instWindow.currentStep++
                }
            }
        }
    }
}

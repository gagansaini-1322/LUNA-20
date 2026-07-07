import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import SddmComponents 2.0

Rectangle {
    id: root

    width: 640
    height: 480
    anchors.fill: parent

    // Background
    Image {
        id: backgroundImage
        anchors.fill: parent
        source: config.background || "backgrounds/bg1.png"
        fillMode: Image.PreserveAspectCrop
        visible: false
    }

    // Blurred background
    FastBlur {
        anchors.fill: backgroundImage
        source: backgroundImage
        radius: config.boolValue("blur") ? config.intValue("blurRadius") : 0
    }

    // Color overlay
    Rectangle {
        anchors.fill: parent
        color: "#800a0e1a"
    }

    // Main content area
    ColumnLayout {
        anchors.centerIn: parent
        width: 300
        spacing: 20

        // Logo
        Image {
            Layout.alignment: Qt.AlignHCenter
            source: "logo.png"
            Layout.preferredWidth: 100
            Layout.preferredHeight: 100
        }

        // Welcome text
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: qsTr("Welcome to LUNA OS")
            color: "#ffffff"
            font.pixelSize: 24
            font.bold: true
        }

        // Username field
        TextField {
            id: usernameField
            Layout.fillWidth: true
            placeholderText: qsTr("Username")
            color: "#ffffff"
            placeholderTextColor: "#80ffffff"

            background: Rectangle {
                color: "#40ffffff"
                radius: 8
            }

            Component.onCompleted: {
                if (userModel.lastUser) {
                    text = userModel.lastUser
                }
            }
        }

        // Password field
        TextField {
            id: passwordField
            Layout.fillWidth: true
            placeholderText: qsTr("Password")
            color: "#ffffff"
            placeholderTextColor: "#80ffffff"
            echoMode: TextInput.Password

            background: Rectangle {
                color: "#40ffffff"
                radius: 8
            }

            Keys.onReturnPressed: loginButton.clicked()
            Keys.onEnterPressed: loginButton.clicked()
        }

        // Session selector
        ComboBox {
            id: sessionCombo
            Layout.fillWidth: true
            model: sessionModel
            currentIndex: sessionModel.lastIndex

            contentItem: Text {
                text: sessionCombo.displayText
                color: "#ffffff"
                verticalAlignment: Text.AlignVCenter
                leftPadding: 10
            }

            background: Rectangle {
                color: "#40ffffff"
                radius: 8
            }
        }

        // Login button
        Button {
            id: loginButton
            Layout.fillWidth: true
            text: qsTr("Login")

            contentItem: Text {
                text: loginButton.text
                color: "#ffffff"
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            background: Rectangle {
                color: loginButton.pressed ? "#3000b4ff" : "#4000b4ff"
                radius: 8
            }

            onClicked: {
                sddm.login(
                    usernameField.text,
                    passwordField.text,
                    sessionCombo.currentIndex
                )
            }
        }

        // Power buttons row
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: 20

            Button {
                text: "⏻"
                onClicked: sddm.powerOff()
                background: Rectangle {
                    color: "#40ffffff"
                    radius: 4
                }
                contentItem: Text {
                    text: parent.text
                    color: "#ffffff"
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            Button {
                text: "↻"
                onClicked: sddm.reboot()
                background: Rectangle {
                    color: "#40ffffff"
                    radius: 4
                }
                contentItem: Text {
                    text: parent.text
                    color: "#ffffff"
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        // Error message
        Text {
            id: errorMessage
            Layout.alignment: Qt.AlignHCenter
            color: "#ff6b6b"
            font.pixelSize: 14
            visible: false
        }
    }

    // Clock
    Text {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 20
        color: "#ffffff"
        font.pixelSize: 48
        visible: config.boolValue("showClock") !== false

        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: clock.text = Qt.formatDateTime(new Date(), "HH:mm")
        }

        Component.onCompleted: text = Qt.formatDateTime(new Date(), "HH:mm")
    }

    // Handle login failure
    Connections {
        target: sddm
        function onLoginFailed() {
            errorMessage.text = qsTr("Login failed. Please try again.")
            errorMessage.visible = true
            passwordField.text = ""
            passwordField.forceActiveFocus()
        }
    }
}

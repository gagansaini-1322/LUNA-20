import QtQuick 2.15

Item {
    id: root

    Image {
        id: backgroundImage
        anchors.fill: parent
        source: "../wallpapers/lunaos/IMG_2030.png"
        fillMode: Image.PreserveAspectCrop
    }

    Rectangle {
        anchors.fill: parent
        color: "#800a0e1a"
    }

    Column {
        anchors.centerIn: parent
        spacing: 20

        Image {
            anchors.horizontalCenter: parent.horizontalCenter
            source: "../../icons/logo.png"
            width: 100
            height: 100
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "LUNA OS"
            color: "#ffffff"
            font.pixelSize: 32
            font.bold: true
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Loading..."
            color: "#a0a8c0"
            font.pixelSize: 16
        }
    }
}

import QtQuick
import LunaHub
import LunaHub.Controls
import LunaHub.Theme

pragma ComponentBehavior: Bound

Item {
    id: control

    property string heading: ""
    property string body: ""
    property string actionLabel: ""
    property string iconName: "○"
    signal action()

    Column {
        anchors.centerIn: parent
        spacing: Metrics.xs16
        width: Math.min(parent.width - Metrics.xs32, 360)

        Item {
            width: Metrics.iconXxl + Metrics.xs16
            height: Metrics.iconXxl + Metrics.xs16
            anchors.horizontalCenter: parent.horizontalCenter
            Rectangle {
                anchors.fill: parent
                radius: width * 0.5
                color: Qt.rgba(Theme.accentPrimary.r, Theme.accentPrimary.g, Theme.accentPrimary.b, 0.16)
                border.width: Metrics.strokeHairline
                border.color: Qt.rgba(Theme.accentPrimary.r, Theme.accentPrimary.g, Theme.accentPrimary.b, 0.4)
            }
            Label {
                anchors.centerIn: parent
                text: control.iconName
                color: Theme.accentPrimary
                font.pixelSize: Metrics.iconXl + 4
                font.family: Typography.family
            }
        }

        Label {
            width: parent.width
            text: control.heading
            horizontalAlignment: Text.AlignHCenter
            color: Theme.textPrimary
            font.family: Typography.family
            font.pixelSize: Typography.pageHeading.size
            font.weight: Typography.pageHeading.weight
            wrapMode: Text.WordWrap
        }

        Label {
            width: parent.width
            visible: control.body.length > 0
            text: control.body
            horizontalAlignment: Text.AlignHCenter
            color: Theme.textSecondary
            font.family: Typography.family
            font.pixelSize: Typography.bodyLabel.size
            wrapMode: Text.WordWrap
        }

        LunaButton {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: control.actionLabel.length > 0
            text: control.actionLabel
            sizeMode: LunaButton.Size.Medium
            onClicked: control.action()
        }
    }
}

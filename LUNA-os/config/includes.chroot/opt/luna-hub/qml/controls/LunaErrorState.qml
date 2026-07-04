import QtQuick
import LunaHub
import LunaHub.Controls
import LunaHub.Theme

pragma ComponentBehavior: Bound

Item {
    id: control

    property string heading: "Something went wrong"
    property string body: ""
    property string actionLabel: "Retry"
    property string secondaryLabel: ""
    signal retry()
    signal secondary()

    Column {
        anchors.centerIn: parent
        spacing: Metrics.xs16
        width: Math.min(parent.width - Metrics.xs32, 380)

        Item {
            width: Metrics.iconXxl + Metrics.xs16
            height: Metrics.iconXxl + Metrics.xs16
            anchors.horizontalCenter: parent.horizontalCenter
            Rectangle {
                anchors.fill: parent
                radius: width * 0.5
                color: Qt.rgba(Theme.criticalColor.r, Theme.criticalColor.g, Theme.criticalColor.b, 0.16)
                border.width: Metrics.strokeHairline
                border.color: Qt.rgba(Theme.criticalColor.r, Theme.criticalColor.g, Theme.criticalColor.b, 0.45)
            }
            Label {
                anchors.centerIn: parent
                text: "!"
                color: Theme.criticalColor
                font.pixelSize: Metrics.iconXl + 4
                font.family: Typography.family
                font.weight: Font.DemiBold
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

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Metrics.xs12
            LunaButton {
                text: control.secondaryLabel
                visible: control.secondaryLabel.length > 0
                variant: LunaButton.Variant.Ghost
                onClicked: control.secondary()
            }
            LunaButton {
                text: control.actionLabel
                variant: LunaButton.Variant.Primary
                onClicked: control.retry()
            }
        }
    }
}

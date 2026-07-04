import QtQuick
import LunaHub
import LunaHub.Controls
import LunaHub.Theme

pragma ComponentBehavior: Bound

LunaDialog {
    id: dlg
    property string processName: "discord"
    property string processTitle: "Discord"
    property string reasonDescription: ""

    title: "Stop Optimization?"
    subtitle: ""
    confirmLabel: "Confirm"
    destructive: true

    body: Item {
        Column {
            anchors.fill: parent
            spacing: Metrics.xs12

            Rectangle {
                color: Qt.rgba(Theme.warningColor.r, Theme.warningColor.g, Theme.warningColor.b, 0.12)
                radius: Metrics.radiusMd
                border.width: Metrics.strokeHairline
                border.color: Qt.rgba(Theme.warningColor.r, Theme.warningColor.g, Theme.warningColor.b, 0.45)
                width: parent.width
                height: 64
                Row {
                    anchors.fill: parent
                    anchors.leftMargin: Metrics.xs16
                    anchors.rightMargin: Metrics.xs16
                    spacing: Metrics.xs12

                    Label {
                        text: "!"
                        color: Theme.warningColor
                        font.pixelSize: Metrics.iconXl
                        font.family: Typography.family
                        font.weight: Font.DemiBold
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        Label {
                            text: dlg.processTitle + " (" + dlg.processName + ")"
                            color: Theme.textPrimary
                            font.family: Typography.family
                            font.pixelSize: Typography.bodyLabel.size
                            font.weight: Font.Medium
                        }
                        Label {
                            text: dlg.reasonDescription
                            color: Theme.textSecondary
                            font.family: Typography.family
                            font.pixelSize: Typography.caption.size
                            wrapMode: Text.WordWrap
                            width: 360
                        }
                    }
                }
            }

            Label {
                text: "Continuing will halt the action. You can re-enable it later from Optimizer."
                color: Theme.textSecondary
                font.family: Typography.family
                font.pixelSize: Typography.bodyLabel.size
                wrapMode: Text.WordWrap
                width: parent.width
            }
        }
    }
}

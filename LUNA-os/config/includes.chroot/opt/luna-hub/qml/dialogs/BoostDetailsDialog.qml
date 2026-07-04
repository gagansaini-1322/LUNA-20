import QtQuick
import LunaHub
import LunaHub.Controls
import LunaHub.Theme

pragma ComponentBehavior: Bound

LunaDialog {
    id: dlg

    property string profileName: "Balanced"
    property var actions: [
        { "label": "CPU Boost Active",        "status": "OK",       "state": "ok" },
        { "label": "GPU Boost Active",        "status": "OK",       "state": "ok" },
        { "label": "Game Priority Boosted",   "status": "OK",       "state": "ok" },
        { "label": "Background Throttling",   "status": "Idle",     "state": "neutral" },
        { "label": "RGB Game Sync",           "status": "Paused",   "state": "neutral" },
        { "label": "Thermal Guard",           "status": "Standby",  "state": "warning" }
    ]

    title: "Luna Boost"
    subtitle: "Profile: " + dlg.profileName
    confirmLabel: "Close"
    cancelLabel: "Edit Profile"

    body: Item {
        Column {
            anchors.fill: parent
            spacing: Metrics.xs4

            Repeater {
                model: dlg.actions
                delegate: Rectangle {
                    width: parent.width
                    height: 44
                    radius: Metrics.radiusMd
                    color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.35)
                    border.width: Metrics.strokeHairline
                    border.color: Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.5)

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: Metrics.xs12
                        anchors.rightMargin: Metrics.xs12
                        spacing: Metrics.xs12
                        Item {
                            width: 24; height: 24
                            anchors.verticalCenter: parent.verticalCenter
                            Rectangle {
                                anchors.fill: parent
                                radius: 12
                                color: modelData.state === "ok"
                                    ? Qt.rgba(Theme.successColor.r, Theme.successColor.g, Theme.successColor.b, 0.25)
                                    : modelData.state === "warning"
                                        ? Qt.rgba(Theme.warningColor.r, Theme.warningColor.g, Theme.warningColor.b, 0.25)
                                        : Qt.rgba(Theme.disabledColor.r, Theme.disabledColor.g, Theme.disabledColor.b, 0.25)
                                border.width: Metrics.strokeHairline
                                border.color: modelData.state === "ok"
                                    ? Qt.rgba(Theme.successColor.r, Theme.successColor.g, Theme.successColor.b, 0.55)
                                    : modelData.state === "warning"
                                        ? Qt.rgba(Theme.warningColor.r, Theme.warningColor.g, Theme.warningColor.b, 0.55)
                                        : Qt.rgba(Theme.disabledColor.r, Theme.disabledColor.g, Theme.disabledColor.b, 0.55)
                            }
                            Label {
                                anchors.centerIn: parent
                                text: modelData.state === "ok" ? "✓" : modelData.state === "warning" ? "!" : "·"
                                color: modelData.state === "ok"
                                    ? Theme.successColor
                                    : modelData.state === "warning"
                                        ? Theme.warningColor
                                        : Theme.textMuted
                                font.pixelSize: Metrics.iconSm
                                font.family: Typography.family
                                font.weight: Font.DemiBold
                            }
                        }
                        Label {
                            text: modelData.label
                            color: Theme.textPrimary
                            font.family: Typography.family
                            font.pixelSize: Typography.bodyLabel.size
                            width: parent.width - 240
                            elide: Text.ElideRight
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Item { width: parent.width - 360 }
                        LunaStatusBadge {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.status
                            tone: modelData.state === "ok" ? LunaStatusBadge.Tone.Success
                                  : modelData.state === "warning" ? LunaStatusBadge.Tone.Warning
                                  : LunaStatusBadge.Tone.Neutral
                            dot: modelData.state === "ok"
                        }
                    }
                }
            }
        }
    }
}

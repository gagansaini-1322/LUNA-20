import QtQuick
import LunaHub
import LunaHub.Theme

pragma ComponentBehavior: Bound

Rectangle {
    id: card

    property var rows: [
        { "k": "Distro",   "v": "LunaOS 20.0 Falcon (rolling)" },
        { "k": "Host",     "v": "luna-gaming-rig" },
        { "k": "Kernel",   "v": "6.6.21-luna (PREEMPT)" },
        { "k": "Uptime",   "v": "11h 27m" },
        { "k": "Shell",    "v": "fish 3.7" },
        { "k": "DE",       "v": "Luna Shell (QML)" },
        { "k": "Packages", "v": "2,418 native / 9 flatpaks" }
    ]
    color: Theme.panelBg
    radius: Metrics.radiusLg
    border.width: Metrics.strokeHairline
    border.color: Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.65)

    Column {
        anchors.fill: parent
        anchors.margins: Metrics.xs20
        spacing: Metrics.xs8

        Label {
            text: "System Information"
            color: Theme.textPrimary
            font.family: Typography.family
            font.pixelSize: Typography.pageHeading.size
            font.weight: Typography.pageHeading.weight
        }

        Repeater {
            model: card.rows
            delegate: Row {
                spacing: Metrics.xs16
                Label {
                    text: modelData.k
                    color: Theme.textMuted
                    font.family: Typography.family
                    font.pixelSize: Typography.bodyLabel.size
                    font.weight: Font.Medium
                    width: 80
                }
                Label {
                    text: modelData.v
                    color: Theme.textPrimary
                    font.family: Typography.family
                    font.pixelSize: Typography.bodyLabel.size
                }
            }
        }
    }
}

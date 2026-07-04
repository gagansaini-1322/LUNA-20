import QtQuick
import LunaHub
import LunaHub.Controls
import LunaHub.Theme

pragma ComponentBehavior: Bound

Rectangle {
    id: card
    color: Theme.panelBg
    radius: Metrics.radiusLg
    border.width: Metrics.strokeHairline
    border.color: Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.65)

    property var services: [
        { "name": "luna-telemetry.service", "title": "Luna Telemetry",     "state": "active",   "running": true },
        { "name": "luna-boost.service",     "title": "Luna Boost engine",  "state": "active",   "running": true },
        { "name": "luna-rgb.service",       "title": "Luna RGB controller","state": "active",   "running": false },
        { "name": "luna-input.service",     "title": "Luna Input mapper",  "state": "inactive", "running": false },
        { "name": "systemd-journald",       "title": "Journal",            "state": "active",   "running": true }
    ]

    Column {
        anchors.fill: parent
        anchors.margins: Metrics.xs20
        spacing: Metrics.xs12

        Label {
            text: "Services"
            color: Theme.textPrimary
            font.family: Typography.family
            font.pixelSize: Typography.pageHeading.size
            font.weight: Typography.pageHeading.weight
        }

        ListView {
            width: parent.width
            height: parent.height - 50
            clip: true
            spacing: Metrics.xs4
            model: card.services
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
            delegate: Rectangle {
                width: parent ? parent.width : 0
                height: 48
                color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.35)
                radius: Metrics.radiusMd
                border.width: Metrics.strokeHairline
                border.color: Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.55)
                Row {
                    anchors.fill: parent
                    anchors.leftMargin: Metrics.xs12
                    anchors.rightMargin: Metrics.xs12
                    spacing: Metrics.xs12
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        Label {
                            text: modelData.title
                            color: Theme.textPrimary
                            font.family: Typography.family
                            font.pixelSize: Typography.bodyLabel.size
                            font.weight: Font.Medium
                        }
                        Label {
                            text: modelData.name
                            color: Theme.textMuted
                            font.family: Typography.family
                            font.pixelSize: Typography.caption.size
                        }
                    }
                    Item { width: parent.width - 240 }
                    LunaStatusBadge {
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.running ? "Running" : "Stopped"
                        tone: modelData.running ? LunaStatusBadge.Tone.Success : LunaStatusBadge.Tone.Neutral
                        dot: true
                    }
                    LunaButton {
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.running ? "Restart" : "Start"
                        sizeMode: LunaButton.Size.Small
                        variant: modelData.running ? LunaButton.Variant.Subtle : LunaButton.Variant.Primary
                    }
                }
            }
        }
    }
}

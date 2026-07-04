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

    property var drivers: [
        { "name": "NVIDIA 555.42",         "device": "RTX 4070 SUPER", "ts": "2024-04-22", "active": true,  "recommended": true },
        { "name": "AMD Mesa 24.0.5",       "device": "iGPU",            "ts": "2024-04-12", "active": true,  "recommended": false },
        { "name": "Realtek r8125 9.011",   "device": "2.5G NIC",         "ts": "2024-02-18", "active": true,  "recommended": false },
        { "name": "Intel IPU7",            "device": "Camera/WoV",       "ts": "2024-03-01", "active": false, "recommended": false }
    ]

    Column {
        anchors.fill: parent
        anchors.margins: Metrics.xs20
        spacing: Metrics.xs12

        Row {
            width: parent.width
            Label {
                text: "Drivers"
                color: Theme.textPrimary
                font.family: Typography.family
                font.pixelSize: Typography.pageHeading.size
                font.weight: Typography.pageHeading.weight
            }
            Item { width: parent.width - 240 }
            LunaButton { text: "Scan"; sizeMode: LunaButton.Size.Small; variant: LunaButton.Variant.Ghost; iconName: "↻"; hasIcon: true }
            LunaButton { text: "Install Recommended"; sizeMode: LunaButton.Size.Small; variant: LunaButton.Variant.Primary }
        }

        ListView {
            width: parent.width
            height: parent.height - 60
            spacing: Metrics.xs4
            model: card.drivers
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
            delegate: Rectangle {
                width: parent ? parent.width : 0
                height: 56
                color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.35)
                radius: Metrics.radiusMd
                border.width: Metrics.strokeHairline
                border.color: Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.5)
                Row {
                    anchors.fill: parent
                    anchors.leftMargin: Metrics.xs12
                    anchors.rightMargin: Metrics.xs12
                    spacing: Metrics.xs12
                    Column {
                        spacing: 2
                        anchors.verticalCenter: parent.verticalCenter
                        Label {
                            text: modelData.name + "  ·  " + modelData.device
                            color: Theme.textPrimary
                            font.family: Typography.family
                            font.pixelSize: Typography.bodyLabel.size
                            font.weight: Font.Medium
                        }
                        Label {
                            text: "Installed " + modelData.ts
                            color: Theme.textMuted
                            font.family: Typography.family
                            font.pixelSize: Typography.caption.size
                        }
                    }
                    Item { width: parent.width - 320 }
                    LunaStatusBadge {
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.recommended ? "Recommended" : (modelData.active ? "Active" : "Inactive")
                        tone: modelData.recommended ? LunaStatusBadge.Tone.Info : modelData.active ? LunaStatusBadge.Tone.Success : LunaStatusBadge.Tone.Neutral
                        dot: true
                    }
                    LunaButton {
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.recommended ? "Apply" : "Update"
                        sizeMode: LunaButton.Size.Small
                        variant: modelData.recommended ? LunaButton.Variant.Primary : LunaButton.Variant.Subtle
                    }
                }
            }
        }
    }
}

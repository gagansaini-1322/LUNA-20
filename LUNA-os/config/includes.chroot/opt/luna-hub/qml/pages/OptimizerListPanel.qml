import QtQuick
import LunaHub
import LunaHub.Controls
import LunaHub.Theme

pragma ComponentBehavior: Bound

Rectangle {
    id: panel

    property string heading: ""
    property string subheading: ""
    property string itemKind: "process"
    property var items: []
    color: Theme.panelBg
    radius: Metrics.radiusLg
    border.width: Metrics.strokeHairline
    border.color: Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.65)

    Column {
        anchors.fill: parent
        anchors.margins: Metrics.xs20
        spacing: Metrics.xs12

        Column {
            width: parent.width
            spacing: 2
            Label {
                text: panel.heading
                color: Theme.textPrimary
                font.family: Typography.family
                font.pixelSize: Typography.pageHeading.size
                font.weight: Typography.pageHeading.weight
            }
            Label {
                text: panel.subheading
                color: Theme.textSecondary
                font.family: Typography.family
                font.pixelSize: Typography.bodyLabel.size
                wrapMode: Text.WordWrap
                width: parent.width
            }
        }

        ListView {
            width: parent.width
            height: parent.height - 80
            clip: true
            spacing: Metrics.xs4
            model: panel.items
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
                    Item {
                        width: 32; height: 32
                        anchors.verticalCenter: parent.verticalCenter
                        Rectangle {
                            anchors.fill: parent
                            radius: Metrics.radiusSm
                            color: Qt.rgba(Theme.accentPrimary.r, Theme.accentPrimary.g, Theme.accentPrimary.b, 0.18)
                            border.width: Metrics.strokeHairline
                            border.color: Qt.rgba(Theme.accentPrimary.r, Theme.accentPrimary.g, Theme.accentPrimary.b, 0.45)
                        }
                        Label {
                            anchors.centerIn: parent
                            text: modelData.title.charAt(0)
                            color: Theme.accentPrimary
                            font.pixelSize: Metrics.iconSm
                            font.family: Typography.family
                            font.weight: Font.DemiBold
                        }
                    }
                    Column {
                        spacing: 2
                        width: parent.width - 220
                        anchors.verticalCenter: parent.verticalCenter
                        Label {
                            text: modelData.title
                            color: Theme.textPrimary
                            font.family: Typography.family
                            font.pixelSize: Typography.bodyLabel.size
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                            width: parent.width
                        }
                        Label {
                            text: (modelData.load ? modelData.load + "  ·  " : "")
                                  + (modelData.memory ? modelData.memory + "  ·  " : "")
                                  + (modelData.impact ? "Impact: " + modelData.impact + "  ·  " : "")
                                  + (modelData.status || "")
                            color: Theme.textMuted
                            font.family: Typography.family
                            font.pixelSize: Typography.caption.size
                            elide: Text.ElideRight
                            width: parent.width
                        }
                    }
                    LunaStatusBadge {
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.status || (modelData.enabled ? "Enabled" : "Disabled")
                        tone: modelData.status === "Throttled" || modelData.status === "Warm" ? LunaStatusBadge.Tone.Warning
                              : modelData.status === "Optimized" || modelData.status === "Active" || modelData.impact === "Low"
                                  ? LunaStatusBadge.Tone.Success
                              : LunaStatusBadge.Tone.Neutral
                        dot: true
                    }
                    LunaToggle {
                        anchors.verticalCenter: parent.verticalCenter
                        checked: modelData.active !== undefined ? modelData.active : modelData.enabled
                        accentOverride: Theme.accentPrimary
                    }
                }
            }
        }
    }
}

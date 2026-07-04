import QtQuick
import LunaHub
import LunaHub.Controls
import LunaHub.Theme

pragma ComponentBehavior: Bound

Rectangle {
    id: panel

    property string game: ""
    property string source: ""
    property string profile: ""
    property var items: []

    color: "transparent"

    Column {
        anchors.fill: parent
        spacing: Metrics.xs16

        Rectangle {
            color: Theme.panelBg
            radius: Metrics.radiusLg
            border.width: Metrics.strokeHairline
            border.color: Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.65)
            width: parent.width
            height: 132

            Row {
                anchors.fill: parent
                anchors.margins: Metrics.xs20
                spacing: Metrics.xs20

                Item {
                    width: 80
                    height: 80
                    anchors.verticalCenter: parent.verticalCenter
                    Rectangle {
                        anchors.fill: parent
                        radius: Metrics.radiusMd
                        color: Qt.rgba(Theme.accentSecondary.r, Theme.accentSecondary.g, Theme.accentSecondary.b, 0.18)
                        border.width: Metrics.strokeHairline
                        border.color: Qt.rgba(Theme.accentSecondary.r, Theme.accentSecondary.g, Theme.accentSecondary.b, 0.45)
                    }
                    Label {
                        anchors.centerIn: parent
                        text: "▶"
                        color: Theme.accentSecondary
                        font.pixelSize: Metrics.iconXl + 4
                        font.family: Typography.family
                    }
                }

                Column {
                    width: parent.width - 80 - 200 - parent.spacing
                    spacing: Metrics.xs4
                    anchors.verticalCenter: parent.verticalCenter

                    Label {
                        text: panel.source.toUpperCase()
                        color: Theme.textMuted
                        font.family: Typography.family
                        font.pixelSize: Typography.overline.size
                        font.letterSpacing: 1.2
                    }
                    Label {
                        text: panel.game
                        color: Theme.textPrimary
                        font.family: Typography.family
                        font.pixelSize: Typography.displayMetric.size
                        font.weight: Typography.displayMetric.weight
                    }

                    Row {
                        spacing: Metrics.xs8
                        LunaStatusBadge {
                            text: panel.profile
                            tone: LunaStatusBadge.Tone.Info
                            iconName: "✺"
                            dot: true
                        }
                        LunaStatusBadge { text: "FPS Stable"; tone: LunaStatusBadge.Tone.Success; dot: true }
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Metrics.xs8
                    LunaButton { text: "Pause Boost"; sizeMode: LunaButton.Size.Small }
                    LunaButton { text: "Switch Profile"; sizeMode: LunaButton.Size.Small; variant: LunaButton.Variant.Ghost }
                }
            }
        }

        Rectangle {
            color: Theme.panelBg
            radius: Metrics.radiusLg
            border.width: Metrics.strokeHairline
            border.color: Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.65)
            width: parent.width
            height: parent.height - 132 - Metrics.xs16

            Column {
                anchors.fill: parent
                anchors.margins: Metrics.xs20
                spacing: Metrics.xs12

                Row {
                    width: parent.width
                    Label {
                        text: "Live recommendations"
                        color: Theme.textPrimary
                        font.family: Typography.family
                        font.pixelSize: Typography.pageHeading.size
                        font.weight: Typography.pageHeading.weight
                    }
                    Item { width: parent.width - 240 }
                    LunaButton { text: "Apply All"; sizeMode: LunaButton.Size.Small; variant: LunaButton.Variant.Primary }
                }

                Column {
                    width: parent.width
                    height: parent.height - 50
                    spacing: Metrics.xs8

                    Repeater {
                        model: panel.items
                        delegate: Rectangle {
                            width: parent.width
                            height: 64
                            radius: Metrics.radiusMd
                            color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.35)
                            border.width: Metrics.strokeHairline
                            border.color: Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.55)

                            Row {
                                anchors.fill: parent
                                anchors.margins: Metrics.xs12
                                spacing: Metrics.xs12

                                Item {
                                    width: 32; height: 32
                                    anchors.verticalCenter: parent.verticalCenter
                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 4
                                        color: Qt.rgba(Theme.accentPrimary.r, Theme.accentPrimary.g, Theme.accentPrimary.b, 0.16)
                                    }
                                    Label {
                                        anchors.centerIn: parent
                                        text: modelData.apply ? "✓" : "•"
                                        color: modelData.apply ? Theme.successColor : Theme.textMuted
                                        font.pixelSize: Metrics.iconMd
                                        font.family: Typography.family
                                    }
                                }

                                Column {
                                    width: parent.width - 220
                                    spacing: 2
                                    anchors.verticalCenter: parent.verticalCenter
                                    Label {
                                        text: modelData.title
                                        color: Theme.textPrimary
                                        font.family: Typography.family
                                        font.pixelSize: Typography.bodyLabel.size
                                        font.weight: Font.Medium
                                    }
                                    Label {
                                        text: modelData.reason
                                        color: Theme.textMuted
                                        font.family: Typography.family
                                        font.pixelSize: Typography.caption.size
                                    }
                                }

                                LunaStatusBadge {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.impact
                                    tone: LunaStatusBadge.Tone.Info
                                }

                                LunaButton {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.apply ? "Apply" : "Ignore"
                                    sizeMode: LunaButton.Size.Small
                                    variant: modelData.apply ? LunaButton.Variant.Primary : LunaButton.Variant.Ghost
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

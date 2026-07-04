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

    Column {
        anchors.fill: parent
        anchors.margins: Metrics.xs20
        spacing: Metrics.xs16

        Label {
            text: "Recovery"
            color: Theme.textPrimary
            font.family: Typography.family
            font.pixelSize: Typography.pageHeading.size
            font.weight: Typography.pageHeading.weight
        }

        Repeater {
            model: [
                { "title": "Roll Back Boost Settings",  "sub": "Restore last good configuration", "tone": LunaStatusBadge.Tone.Warning },
                { "title": "Reset GPU Profile",          "sub": "Re-detect optimal clocks and fan curves", "tone": LunaStatusBadge.Tone.Info },
                { "title": "Rebuild Library Index",      "sub": "Re-scan Steam, GOG, Epic, Battle.net", "tone": LunaStatusBadge.Tone.Neutral },
                { "title": "Disable Boost on Next Boot","sub": "Suspends Luna Boost until toggled back on", "tone": LunaStatusBadge.Tone.Warning },
                { "title": "Reset All Settings",         "sub": "Returns Luna Hub to first-run state", "tone": LunaStatusBadge.Tone.Critical }
            ]
            delegate: Rectangle {
                width: parent.width
                height: 56
                color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.35)
                radius: Metrics.radiusMd
                border.width: Metrics.strokeHairline
                border.color: Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.55)

                Row {
                    anchors.fill: parent
                    anchors.margins: Metrics.xs12
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
                            text: modelData.sub
                            color: Theme.textMuted
                            font.family: Typography.family
                            font.pixelSize: Typography.caption.size
                        }
                    }
                    Item { width: parent.width - 280 }
                    LunaButton {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Run"
                        sizeMode: LunaButton.Size.Small
                        variant: modelData.tone === LunaStatusBadge.Tone.Critical ? LunaButton.Variant.Danger : LunaButton.Variant.Subtle
                    }
                }
            }
        }
    }
}

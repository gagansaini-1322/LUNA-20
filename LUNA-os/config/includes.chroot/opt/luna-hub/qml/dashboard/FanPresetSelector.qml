import QtQuick
import LunaHub
import LunaHub.Theme

pragma ComponentBehavior: Bound

Row {
    id: row
    property string current: "Balanced"
    signal selectedPreset(string preset)
    spacing: Metrics.xs4

    Repeater {
        model: [
            { "key": "Silent",      "label": "Silent",   "tone": Theme.successColor },
            { "key": "Balanced",    "label": "Balanced", "tone": Theme.accentPrimary },
            { "key": "Turbo",       "label": "Turbo",    "tone": Theme.warningColor },
            { "key": "Full Speed",  "label": "Full",     "tone": Theme.criticalColor }
        ]
        delegate: Rectangle {
            height: 24
            width: 64
            radius: Metrics.radiusPill
            color: row.current === modelData.key
                   ? Qt.rgba(modelData.tone.r, modelData.tone.g, modelData.tone.b, 0.25)
                   : Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.45)
            border.width: Metrics.strokeHairline
            border.color: row.current === modelData.key
                   ? Qt.rgba(modelData.tone.r, modelData.tone.g, modelData.tone.b, 0.55)
                   : Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.55)
            Behavior on color { ColorAnimation { duration: Metrics.durFast } }
            Behavior on border.color { ColorAnimation { duration: Metrics.durFast } }
            Label {
                anchors.centerIn: parent
                text: modelData.label
                color: row.current === modelData.key ? Theme.textPrimary : Theme.textSecondary
                font.family: Typography.family
                font.pixelSize: Typography.caption.size
                font.weight: Font.Medium
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: row.selectedPreset(modelData.key)
            }
        }
    }
}

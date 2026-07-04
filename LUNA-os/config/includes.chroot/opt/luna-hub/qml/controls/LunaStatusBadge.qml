import QtQuick
import LunaHub
import LunaHub.Controls
import LunaHub.Theme

pragma ComponentBehavior: Bound

Item {
    id: control

    enum Tone { Neutral, Success, Warning, Critical, Info, Accent }
    property int tone: LunaStatusBadge.Tone.Neutral
    property string text: ""
    property string iconName: ""
    property bool dot: false
    property bool outlined: false

    implicitHeight: 22
    implicitWidth: row.implicitWidth + Metrics.xs12 * 2

    Rectangle {
        anchors.fill: parent
        radius: height * 0.5
        color: {
            if (control.outlined) return "transparent"
            switch (control.tone) {
                case LunaStatusBadge.Tone.Success: return Qt.rgba(Theme.successColor.r, Theme.successColor.g, Theme.successColor.b, 0.18)
                case LunaStatusBadge.Tone.Warning: return Qt.rgba(Theme.warningColor.r, Theme.warningColor.g, Theme.warningColor.b, 0.18)
                case LunaStatusBadge.Tone.Critical: return Qt.rgba(Theme.criticalColor.r, Theme.criticalColor.g, Theme.criticalColor.b, 0.22)
                case LunaStatusBadge.Tone.Info: return Qt.rgba(Theme.accentPrimary.r, Theme.accentPrimary.g, Theme.accentPrimary.b, 0.18)
                case LunaStatusBadge.Tone.Accent: return Qt.rgba(Theme.accentSecondary.r, Theme.accentSecondary.g, Theme.accentSecondary.b, 0.18)
                default: return Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.4)
            }
        }
        border.width: Metrics.strokeHairline
        border.color: {
            switch (control.tone) {
                case LunaStatusBadge.Tone.Success: return Qt.rgba(Theme.successColor.r, Theme.successColor.g, Theme.successColor.b, 0.55)
                case LunaStatusBadge.Tone.Warning: return Qt.rgba(Theme.warningColor.r, Theme.warningColor.g, Theme.warningColor.b, 0.55)
                case LunaStatusBadge.Tone.Critical: return Qt.rgba(Theme.criticalColor.r, Theme.criticalColor.g, Theme.criticalColor.b, 0.6)
                case LunaStatusBadge.Tone.Info: return Qt.rgba(Theme.accentPrimary.r, Theme.accentPrimary.g, Theme.accentPrimary.b, 0.55)
                case LunaStatusBadge.Tone.Accent: return Qt.rgba(Theme.accentSecondary.r, Theme.accentSecondary.g, Theme.accentSecondary.b, 0.55)
                default: return Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.6)
            }
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Metrics.xs4
        Rectangle {
            visible: control.dot
            width: 6
            height: 6
            radius: 3
            anchors.verticalCenter: parent.verticalCenter
            color: {
                switch (control.tone) {
                    case LunaStatusBadge.Tone.Success: return Theme.successColor
                    case LunaStatusBadge.Tone.Warning: return Theme.warningColor
                    case LunaStatusBadge.Tone.Critical: return Theme.criticalColor
                    case LunaStatusBadge.Tone.Info: return Theme.accentPrimary
                    case LunaStatusBadge.Tone.Accent: return Theme.accentSecondary
                    default: return Theme.textMuted
                }
            }
        }
        Label {
            visible: control.iconName.length > 0
            text: control.iconName
            color: {
                switch (control.tone) {
                    case LunaStatusBadge.Tone.Success: return Theme.successColor
                    case LunaStatusBadge.Tone.Warning: return Theme.warningColor
                    case LunaStatusBadge.Tone.Critical: return Theme.criticalColor
                    case LunaStatusBadge.Tone.Info: return Theme.accentPrimary
                    case LunaStatusBadge.Tone.Accent: return Theme.accentSecondary
                    default: return Theme.textSecondary
                }
            }
            font.pixelSize: Typography.caption.size
            font.family: Typography.family
            anchors.verticalCenter: parent.verticalCenter
        }
        Label {
            text: control.text
            color: {
                switch (control.tone) {
                    case LunaStatusBadge.Tone.Success: return Theme.successColor
                    case LunaStatusBadge.Tone.Warning: return Theme.warningColor
                    case LunaStatusBadge.Tone.Critical: return Theme.criticalColor
                    case LunaStatusBadge.Tone.Info: return Theme.accentPrimary
                    case LunaStatusBadge.Tone.Accent: return Theme.accentSecondary
                    default: return Theme.textSecondary
                }
            }
            font.family: Typography.family
            font.pixelSize: Typography.caption.size
            font.weight: Font.Medium
            font.letterSpacing: 0.4
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}

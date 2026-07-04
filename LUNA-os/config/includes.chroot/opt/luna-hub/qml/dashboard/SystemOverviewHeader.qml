import QtQuick
import LunaHub
import LunaHub.Controls
import LunaHub.Theme

pragma ComponentBehavior: Bound

Item {
    id: header

    property string title: "SYSTEM OVERVIEW"
    property string subtitle: "Live Performance Monitoring"
    property string sessionInfo: ""
    property string perfProfile: "Balanced"
    property bool perfActive: false
    property bool perfActivate: false
    signal perfModeTriggered()
    signal perfModePrimary()

    implicitHeight: layout.implicitHeight + Metrics.xs24 * 2

    Column {
        id: layout
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: Metrics.xs4

        Row {
            spacing: Metrics.xs12
            Label {
                text: header.title
                color: Theme.textSecondary
                font.family: Typography.family
                font.pixelSize: Typography.overline.size
                font.weight: Typography.overline.weight
                font.letterSpacing: Typography.overline.letterSpacing
                anchors.verticalCenter: parent.verticalCenter
            }
            Rectangle {
                width: 1
                height: 10
                color: Theme.borderDefault
                anchors.verticalCenter: parent.verticalCenter
            }
            Label {
                text: header.subtitle
                color: Theme.textMuted
                font.family: Typography.family
                font.pixelSize: Typography.overline.size
                font.weight: Font.Medium
                font.letterSpacing: 1.2
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Row {
            spacing: Metrics.xs12
            Label {
                text: "Live session"
                color: Theme.textPrimary
                font.family: Typography.family
                font.pixelSize: Typography.displayMetric.size
                font.weight: Typography.displayMetric.weight
                anchors.verticalCenter: parent.verticalCenter
            }
            LunaStatusBadge {
                text: header.perfProfile
                tone: header.perfActive ? LunaStatusBadge.Tone.Success : LunaStatusBadge.Tone.Neutral
                dot: true
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    Row {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: Metrics.xs12

        LunaButton {
            text: header.perfActive ? "Active" : "Boost Now"
            sizeMode: LunaButton.Size.Small
            variant: LunaButton.Variant.Primary
            onClicked: header.perfModePrimary()
        }
        LunaButton {
            text: "Switch Profile"
            sizeMode: LunaButton.Size.Small
            variant: LunaButton.Variant.Subtle
            iconName: "↻"
            hasIcon: true
            onClicked: header.perfModeTriggered()
        }
    }
}

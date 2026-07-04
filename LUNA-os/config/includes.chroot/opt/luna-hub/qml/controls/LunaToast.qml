import QtQuick
import LunaHub
import LunaHub.Controls
import LunaHub.Theme

pragma ComponentBehavior: Bound

Item {
    id: control

    property string title: ""
    property string message: ""
    property int tone: LunaStatusBadge.Tone.Info
    property int durationMs: 3200
    property bool dismissible: true

    signal dismissed()

    function present() {
        slide.targetOffset = 0
        fade.targetOpacity = 1.0
        dismissTimer.restart()
    }

    function dismiss() {
        slide.targetOffset = 8
        fade.targetOpacity = 0
        dismissTimer.stop()
    }

    visible: opacity > 0.01
    opacity: 0
    y: 8

    Behavior on opacity { NumberAnimation { duration: Metrics.durFade } }
    Behavior on y { NumberAnimation { duration: Metrics.durFade } }

    QtObject {
        id: slide
        property real targetOffset: 8
    }
    QtObject {
        id: fade
        property real targetOpacity: 0
    }

    Timer {
        id: dismissTimer
        interval: control.durationMs
        repeat: false
        onTriggered: control.dismissed(); control.dismiss()
    }

    Rectangle {
        id: visualRoot
        anchors.fill: parent
        radius: Metrics.radiusLg
        color: Theme.bgElevated
        border.width: Metrics.strokeHairline
        border.color: {
            switch (control.tone) {
                case LunaStatusBadge.Tone.Success: return Qt.rgba(Theme.successColor.r, Theme.successColor.g, Theme.successColor.b, 0.55)
                case LunaStatusBadge.Tone.Warning: return Qt.rgba(Theme.warningColor.r, Theme.warningColor.g, Theme.warningColor.b, 0.55)
                case LunaStatusBadge.Tone.Critical: return Qt.rgba(Theme.criticalColor.r, Theme.criticalColor.g, Theme.criticalColor.b, 0.6)
                default: return Theme.borderHover
            }
        }
        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 3
            color: {
                switch (control.tone) {
                    case LunaStatusBadge.Tone.Success: return Theme.successColor
                    case LunaStatusBadge.Tone.Warning: return Theme.warningColor
                    case LunaStatusBadge.Tone.Critical: return Theme.criticalColor
                    default: return Theme.accentPrimary
                }
            }
            radius: Metrics.radiusLg
        }
        Row {
            anchors.fill: parent
            anchors.leftMargin: Metrics.xs20
            anchors.rightMargin: Metrics.xs12
            anchors.topMargin: Metrics.xs12
            anchors.bottomMargin: Metrics.xs12
            spacing: Metrics.xs12

            Column {
                width: parent.width - 36 - parent.spacing
                spacing: Metrics.xs4
                Label {
                    width: parent.width
                    text: control.title
                    color: Theme.textPrimary
                    font.family: Typography.family
                    font.pixelSize: Typography.bodyLabel.size
                    font.weight: Font.Medium
                    wrapMode: Text.WordWrap
                }
                Label {
                    width: parent.width
                    visible: control.message.length > 0
                    text: control.message
                    color: Theme.textSecondary
                    font.family: Typography.family
                    font.pixelSize: Typography.caption.size
                    wrapMode: Text.WordWrap
                }
            }
            LunaIconButton {
                anchors.verticalCenter: parent.verticalCenter
                iconName: "✕"
                sizeMode: 1
                visible: control.dismissible
                iconPx: Metrics.iconSm
                tooltipText: "Dismiss"
                onClicked: { control.dismiss(); control.dismissed() }
            }
        }
    }

    onOpacityChanged: { /* for binding convenience */ }
    onYChanged: {}
}

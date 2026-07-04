import QtQuick
import LunaHub
import LunaHub.Controls
import LunaHub.Theme

pragma ComponentBehavior: Bound

Rectangle {
    id: card

    property int currentRpm: 0
    property int maxRpm: 2200
    property int percent: 0
    property string profile: "Balanced"
    property bool telemetryActive: true
    property bool capabilityAvailable: true
    property bool rotateWhenActive: true
    signal profileChanged(string profile)
    signal toggleRequested()

    implicitHeight: 240

    color: Theme.panelBg
    radius: Metrics.radiusLg
    border.width: Metrics.strokeHairline
    border.color: Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.65)

    Column {
        anchors.fill: parent
        anchors.margins: Metrics.xs20
        spacing: Metrics.xs12

        Row {
            width: parent.width
            spacing: Metrics.xs12
            Label {
                text: "Fan Control"
                color: Theme.textPrimary
                font.family: Typography.family
                font.pixelSize: Typography.pageHeading.size
                font.weight: Typography.pageHeading.weight
            }
            LunaStatusBadge {
                anchors.verticalCenter: parent.verticalCenter
                text: card.capabilityAvailable ? "Available" : "Unavailable"
                tone: card.capabilityAvailable ? LunaStatusBadge.Tone.Success : LunaStatusBadge.Tone.Critical
                dot: true
            }
            Item { width: parent.width - 220 }
            LunaButton {
                text: "Manage"
                sizeMode: LunaButton.Size.Small
                variant: LunaButton.Variant.Subtle
                anchors.verticalCenter: parent.verticalCenter
                onClicked: card.toggleRequested()
            }
        }

        Row {
            width: parent.width
            spacing: Metrics.xs20

            FanGauge {
                width: 110
                height: 110
                rpmValue: card.currentRpm
                maxRpm: card.maxRpm
                rotate: card.rotateWhenActive && card.telemetryActive && card.currentRpm > 80
                active: card.capabilityAvailable
            }

            Column {
                width: parent.width - 130
                spacing: Metrics.xs12

                Column {
                    spacing: 0
                    Label {
                        text: "Current Profile"
                        color: Theme.textMuted
                        font.family: Typography.family
                        font.pixelSize: Typography.caption.size
                        font.weight: Font.Medium
                        font.letterSpacing: 0.6
                    }
                    Label {
                        text: card.profile
                        color: Theme.textPrimary
                        font.family: Typography.family
                        font.pixelSize: Typography.telemetryValue.size
                        font.weight: Typography.telemetryValue.weight
                    }
                    Label {
                        text: "RPM " + card.currentRpm + " / " + card.maxRpm + " (" + card.percent + "%)"
                        color: Theme.textSecondary
                        font.family: Typography.family
                        font.pixelSize: Typography.smallTelemetry.size
                        font.features: { "tnum": true }
                    }
                }

                FanPresetSelector {
                    width: parent.width
                    current: card.profile
                    onSelectedPreset: (preset) => card.profileChanged(preset)
                }
            }
        }
    }
}

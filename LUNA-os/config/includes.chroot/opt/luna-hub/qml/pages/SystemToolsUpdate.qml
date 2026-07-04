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

        Row {
            width: parent.width
            spacing: Metrics.xs12
            Label {
                text: "System Update"
                color: Theme.textPrimary
                font.family: Typography.family
                font.pixelSize: Typography.pageHeading.size
                font.weight: Typography.pageHeading.weight
            }
            LunaStatusBadge {
                text: "Up to date"
                tone: LunaStatusBadge.Tone.Success
                dot: true
            }
            Item { width: parent.width - 320 }
            LunaButton { text: "Check Now"; sizeMode: LunaButton.Size.Small; variant: LunaButton.Variant.Subtle; iconName: "↻"; hasIcon: true }
            LunaButton { text: "Update All"; sizeMode: LunaButton.Size.Small; variant: LunaButton.Variant.Primary }
        }

        Rectangle {
            width: parent.width
            height: parent.height - 100
            color: "transparent"

            LunaEmptyState {
                anchors.centerIn: parent
                width: 360
                heading: "Your system is current"
                body: "Last checked 11 minutes ago."
                actionLabel: "Re-check"
                iconName: "✓"
            }
        }
    }
}

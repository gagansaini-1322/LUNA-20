import QtQuick
import LunaHub
import LunaHub.Controls
import LunaHub.Theme

pragma ComponentBehavior: Bound

Rectangle {
    id: panel
    color: Theme.panelBg
    radius: Metrics.radiusLg
    border.width: Metrics.strokeHairline
    border.color: Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.65)

    Column {
        anchors.fill: parent
        anchors.margins: Metrics.xs20
        spacing: Metrics.xs12

        Label {
            text: "Optimizer history"
            color: Theme.textPrimary
            font.family: Typography.family
            font.pixelSize: Typography.pageHeading.size
            font.weight: Typography.pageHeading.weight
        }
        Label {
            text: "Recent Luna Boost sessions and tunings."
            color: Theme.textSecondary
            font.family: Typography.family
            font.pixelSize: Typography.bodyLabel.size
        }

        ListView {
            width: parent.width
            height: parent.height - 80
            spacing: Metrics.xs4
            clip: true
            model: 12
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
                    anchors.leftMargin: Metrics.xs16
                    anchors.rightMargin: Metrics.xs16
                    spacing: Metrics.xs16
                    Item {
                        width: 28; height: 28
                        anchors.verticalCenter: parent.verticalCenter
                        Rectangle {
                            anchors.fill: parent
                            radius: 14
                            color: Qt.rgba(Theme.successColor.r, Theme.successColor.g, Theme.successColor.b, 0.16)
                        }
                        Label {
                            anchors.centerIn: parent
                            text: "✓"
                            color: Theme.successColor
                            font.pixelSize: Metric.md
                            font.family: Typography.family
                        }
                    }
                    Column {
                        spacing: 2
                        width: parent.width - 240
                        anchors.verticalCenter: parent.verticalCenter
                        Label {
                            text: "Helldivers 2: Turbo +12% avg FPS"
                            color: Theme.textPrimary
                            font.family: Typography.family
                            font.pixelSize: Typography.bodyLabel.size
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                            width: parent.width
                        }
                        Label {
                            text: "00:48 · Boost 18min"
                            color: Theme.textMuted
                            font.family: Typography.family
                            font.pixelSize: Typography.caption.size
                        }
                    }
                    LunaButton {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Revert"
                        sizeMode: LunaButton.Size.Small
                        variant: LunaButton.Variant.Ghost
                    }
                }
            }
        }
    }

    Component.onCompleted: { }
}

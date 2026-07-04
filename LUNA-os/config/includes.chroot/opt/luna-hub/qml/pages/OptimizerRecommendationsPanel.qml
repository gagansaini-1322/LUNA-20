import QtQuick
import LunaHub
import LunaHub.Controls
import LunaHub.Theme

pragma ComponentBehavior: Bound

Rectangle {
    id: panel
    property var items: []
    color: Theme.panelBg
    radius: Metrics.radiusLg
    border.width: Metrics.strokeHairline
    border.color: Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.65)

    Column {
        anchors.fill: parent
        anchors.margins: Metrics.xs20
        spacing: Metrics.xs12

        Label {
            text: "Recommendations"
            color: Theme.textPrimary
            font.family: Typography.family
            font.pixelSize: Typography.pageHeading.size
            font.weight: Typography.pageHeading.weight
        }
        Label {
            text: "Luna Hub curated actions tuned to current workload."
            color: Theme.textSecondary
            font.family: Typography.family
            font.pixelSize: Typography.bodyLabel.size
            wrapMode: Text.WordWrap
            width: parent.width
        }

        Column {
            width: parent.width
            height: parent.height - 80
            spacing: Metrics.xs8

            Repeater {
                model: panel.items
                delegate: Rectangle {
                    width: parent.width
                    height: 76
                    color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.35)
                    radius: Metrics.radiusMd
                    border.width: Metrics.strokeHairline
                    border.color: Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.55)

                    Row {
                        anchors.fill: parent
                        anchors.margins: Metrics.xs16
                        spacing: Metrics.xs16

                        Column {
                            width: parent.width - 220
                            spacing: 2
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
                                text: modelData.reason
                                color: Theme.textSecondary
                                font.family: Typography.family
                                font.pixelSize: Typography.caption.size
                                elide: Text.ElideRight
                                width: parent.width
                            }
                        }

                        LunaStatusBadge {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.impact
                            tone: LunaStatusBadge.Tone.Info
                        }

                        LunaButton {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Apply"
                            sizeMode: LunaButton.Size.Small
                            variant: LunaButton.Variant.Primary
                        }
                    }
                }
            }
        }
    }
}

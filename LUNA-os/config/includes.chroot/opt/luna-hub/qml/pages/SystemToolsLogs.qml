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
        spacing: Metrics.xs12

        Row {
            width: parent.width
            Label {
                text: "Logs"
                color: Theme.textPrimary
                font.family: Typography.family
                font.pixelSize: Typography.pageHeading.size
                font.weight: Typography.pageHeading.weight
            }
            Item { width: parent.width - 320 }
            LunaDropdown {
                Layout.preferredWidth: 140
                modelArray: [
                    { label: "Last hour", value: "1h" },
                    { label: "Today", value: "24h" },
                    { label: "Last 7 days", value: "7d" }
                ]
            }
            LunaButton { text: "Export"; sizeMode: LunaButton.Size.Small; variant: LunaButton.Variant.Ghost }
        }

        Rectangle {
            color: Theme.bgPrimary
            radius: Metrics.radiusMd
            border.width: Metrics.strokeHairline
            border.color: Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.55)
            width: parent.width
            height: parent.height - 60

            ListView {
                anchors.fill: parent
                clip: true
                model: 12
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                delegate: Row {
                    width: parent ? parent.width : 0
                    height: 22
                    spacing: Metrics.xs12
                    Item {
                        width: parent.width - 16
                        height: parent.height
                        Rectangle {
                            anchors.fill: parent
                            color: index % 2 === 0
                                   ? Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.4)
                                   : "transparent"
                        }
                        Label {
                            anchors.left: parent.left
                            anchors.leftMargin: Metrics.xs8
                            anchors.verticalCenter: parent.verticalCenter
                            text: "00:14:23"
                            color: Theme.textMuted
                            font.family: Typography.family
                            font.pixelSize: Typography.caption.size
                            font.features: { "tnum": true }
                        }
                        Label {
                            anchors.left: parent.left
                            anchors.leftMargin: 96
                            anchors.verticalCenter: parent.verticalCenter
                            text: "INFO "
                            color: Theme.cpuAccent
                            font.family: Typography.family
                            font.pixelSize: Typography.caption.size
                        }
                        Label {
                            anchors.left: parent.left
                            anchors.leftMargin: 140
                            anchors.verticalCenter: parent.verticalCenter
                            text: "luna-telemetry: GPU sampling 90Hz ✓"
                            color: Theme.textPrimary
                            font.family: Typography.family
                            font.pixelSize: Typography.caption.size
                        }
                    }
                }
            }
        }
    }
}

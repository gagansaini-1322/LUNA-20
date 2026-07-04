import QtQuick
import LunaHub
import LunaHub.Dashboard
import LunaHub.Controls
import LunaHub.Theme

pragma ComponentBehavior: Bound

Item {
    id: page
    property string routeName: "network"

    Column {
        anchors.fill: parent
        anchors.margins: Metrics.xs24
        spacing: Metrics.xs16

        Row {
            width: parent.width
            spacing: Metrics.xs12

            MetricCard {
                width: (parent.width - parent.spacing * 4) / 5
                title: "DOWN"
                primaryValue: "12.4"
                unit: " Mb/s"
                secondaryValue: "↘"
                accent: Theme.successColor
                sparkMax: 100
                state: MetricCard.State.Active
            }
            MetricCard {
                width: (parent.width - parent.spacing * 4) / 5
                title: "UP"
                primaryValue: "0.9"
                unit: " Mb/s"
                secondaryValue: "↗"
                accent: Theme.warningColor
                sparkMax: 100
            }
            MetricCard {
                width: (parent.width - parent.spacing * 4) / 5
                title: "LATENCY"
                primaryValue: "14"
                unit: " ms"
                secondaryValue: "↘"
                accent: Theme.cpuAccent
                sparkMax: 100
            }
            MetricCard {
                width: (parent.width - parent.spacing * 4) / 5
                title: "PACKET LOSS"
                primaryValue: "0.2"
                unit: "%"
                secondaryValue: "stable"
                accent: Theme.successColor
                sparkMax: 5
            }
            MetricCard {
                width: (parent.width - parent.spacing * 4) / 5
                title: "INTERFACE"
                primaryValue: "2.5G"
                unit: " ETH"
                secondaryValue: "enp6s0"
                accent: Theme.accentSecondary
                showSparkline: false
            }
        }

        PerformanceMonitor {
            width: parent.width
            height: 280
        }

        Row {
            width: parent.width
            spacing: Metrics.xs16

            Rectangle {
                color: Theme.panelBg
                radius: Metrics.radiusLg
                border.width: Metrics.strokeHairline
                border.color: Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.65)
                width: parent.width * 0.55 - parent.spacing
                height: 220

                Column {
                    anchors.fill: parent
                    anchors.margins: Metrics.xs20
                    spacing: Metrics.xs12

                    Label {
                        text: "Active sessions"
                        color: Theme.textPrimary
                        font.family: Typography.family
                        font.pixelSize: Typography.pageHeading.size
                        font.weight: Typography.pageHeading.weight
                    }

                    ListView {
                        width: parent.width
                        height: parent.height - 50
                        spacing: Metrics.xs4
                        clip: true
                        model: 4
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                        delegate: Rectangle {
                            width: parent ? parent.width : 0
                            height: 42
                            color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.35)
                            radius: Metrics.radiusSm
                            border.width: Metrics.strokeHairline
                            border.color: Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.5)
                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: Metrics.xs12
                                anchors.rightMargin: Metrics.xs12
                                spacing: Metrics.xs12
                                Label {
                                    text: "Steam  " + (27000 + index * 17)
                                    color: Theme.accentSecondary
                                    font.family: Typography.family
                                    font.pixelSize: Typography.caption.size
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Label {
                                    text: "Steam Friends · 3 KB/s"
                                    color: Theme.textPrimary
                                    font.family: Typography.family
                                    font.pixelSize: Typography.bodyLabel.size
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 240
                                    elide: Text.ElideRight
                                }
                                LunaStatusBadge {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Active"
                                    tone: LunaStatusBadge.Tone.Success
                                    dot: true
                                }
                            }
                        }
                    }
                }
            }

            PerformanceQueue {
                width: parent.width * 0.45 - parent.spacing
                height: 220
                items: []
            }
        }
    }
}

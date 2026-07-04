import QtQuick
import LunaHub
import LunaHub.Controls
import LunaHub.Theme

pragma ComponentBehavior: Bound

Item {
    id: card

    enum Metric { CPU, RAM, GPU, FPS, Net }
    enum State { Active, Waiting, Error, Loading, Unavailable }

    property int metric: MetricCard.Metric.CPU
    property int state: MetricCard.State.Active
    property string title: ""
    property string primaryValue: ""
    property string unit: ""
    property string secondaryValue: ""
    property real sparkvalue: 0
    property real sparkMax: 100
    property color accent: Theme.cpuAccent
    property var trendPoints: []
    property string trendLabel: "60s"
    property bool showSparkline: true
    property bool compact: false
    property bool pulse: false

    implicitHeight: compact ? Metrics.cardMinHeight : Metrics.cardMinHeight + 36
    implicitWidth: 220

    Rectangle {
        anchors.fill: parent
        color: Theme.panelBg
        radius: Metrics.radiusLg
        border.width: Metrics.strokeHairline
        border.color: Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.65)

        Rectangle {
            anchors.fill: parent
            anchors.margins: -1
            radius: Metrics.radiusLg + 1
            color: "transparent"
            border.color: card.accent
            border.width: Metrics.strokeThin
            opacity: card.state === MetricCard.State.Active ? Theme.glowSoft : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Metrics.durIndicator } }
        }

        Column {
            anchors.fill: parent
            anchors.topMargin: Metrics.xs16
            anchors.bottomMargin: Metrics.xs16
            anchors.leftMargin: Metrics.xs16
            anchors.rightMargin: Metrics.xs16
            spacing: Metrics.xs8

            Row {
                width: parent.width
                spacing: Metrics.xs8
                Rectangle {
                    width: 26
                    height: 26
                    radius: Metrics.radiusSm
                    color: Qt.rgba(card.accent.r, card.accent.g, card.accent.b, 0.16)
                    border.width: Metrics.strokeHairline
                    border.color: Qt.rgba(card.accent.r, card.accent.g, card.accent.b, 0.45)
                    anchors.verticalCenter: parent.verticalCenter
                    Label {
                        anchors.centerIn: parent
                        text: metricIcon(card.metric)
                        color: card.accent
                        font.pixelSize: Metrics.iconMd
                        font.family: Typography.family
                    }
                }
                Column {
                    width: parent.width - 32 - 8
                    spacing: 0
                    anchors.verticalCenter: parent.verticalCenter
                    Label {
                        text: card.title
                        color: Theme.textSecondary
                        font.family: Typography.family
                        font.pixelSize: Typography.caption.size
                        font.weight: Font.Medium
                        font.letterSpacing: 0.6
                        width: parent.width
                        elide: Text.ElideRight
                    }
                    Label {
                        text: card.trendLabel
                        color: Theme.textMuted
                        font.family: Typography.family
                        font.pixelSize: Typography.caption.size
                    }
                }
                Item { Layout.fillWidth: true }
            }

            Row {
                width: parent.width
                spacing: Metrics.xs4
                Label {
                    text: card.state === MetricCard.State.Unavailable
                          ? "—"
                          : card.state === MetricCard.State.Loading ? "…" : card.primaryValue
                    color: card.state === MetricCard.State.Error ? Theme.criticalColor : Theme.textPrimary
                    font.family: Typography.family
                    font.pixelSize: Typography.telemetryValue.size
                    font.weight: Typography.telemetryValue.weight
                    font.features: { "tnum": true }
                    anchors.verticalCenter: parent.verticalCenter
                }
                Label {
                    text: card.unit
                    color: Theme.textMuted
                    font.family: Typography.family
                    font.pixelSize: Typography.bodyLabel.size
                    anchors.verticalCenter: parent.bottom
                }

                Item { width: Metrics.xs8 }

                Label {
                    visible: card.secondaryValue.length > 0
                    text: card.secondaryValue
                    color: Theme.textSecondary
                    font.family: Typography.family
                    font.pixelSize: Typography.smallTelemetry.size
                    font.features: { "tnum": true }
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Item {
                width: parent.width
                height: 28
                visible: card.showSparkline && card.state !== MetricCard.State.Unavailable
                Sparkline {
                    anchors.fill: parent
                    anchors.topMargin: 0
                    anchors.bottomMargin: 0
                    points: card.trendPoints.length > 0 ? card.trendPoints : defaultSeries()
                    color: card.accent
                    fillOpacity: 0.16
                    sampleMax: card.sparkMax
                }
            }
        }

        Loader {
            anchors.fill: parent
            visible: card.state === MetricCard.State.Loading
            sourceComponent: Item {
                anchors.fill: parent
                color: "transparent"
                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(Theme.panelBg.r, Theme.panelBg.g, Theme.panelBg.b, 0.65)
                    radius: Metrics.radiusLg
                }
                LunaLoadingState {
                    anchors.centerIn: parent
                    size: 22
                    label: "Sampling"
                }
            }
        }

        Loader {
            anchors.fill: parent
            visible: card.state === MetricCard.State.Error
            sourceComponent: Item {
                anchors.fill: parent
                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(Theme.criticalColor.r, Theme.criticalColor.g, Theme.criticalColor.b, 0.06)
                    radius: Metrics.radiusLg
                }
                Column {
                    anchors.centerIn: parent
                    spacing: Metrics.xs4
                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Sensor offline"
                        color: Theme.criticalColor
                        font.family: Typography.family
                        font.pixelSize: Typography.bodyLabel.size
                        font.weight: Font.Medium
                    }
                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Retrying in 10s"
                        color: Theme.textMuted
                        font.family: Typography.family
                        font.pixelSize: Typography.caption.size
                    }
                }
            }
        }

        Loader {
            anchors.fill: parent
            visible: card.state === MetricCard.State.Unavailable
            sourceComponent: Item {
                Column {
                    anchors.centerIn: parent
                    spacing: Metrics.xs4
                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "n/a"
                        color: Theme.disabledColor
                        font.family: Typography.family
                        font.pixelSize: Typography.telemetryValue.size
                    }
                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Not supported"
                        color: Theme.textMuted
                        font.family: Typography.family
                        font.pixelSize: Typography.caption.size
                    }
                }
            }
        }
    }

    function metricIcon(metric) {
        switch (metric) {
            case MetricCard.Metric.CPU: return "▣"
            case MetricCard.Metric.RAM: return "◫"
            case MetricCard.Metric.GPU: return "◆"
            case MetricCard.Metric.FPS: return "▶"
            case MetricCard.Metric.Net: return "↕"
        }
        return "○"
    }

    function defaultSeries() {
        var arr = []
        for (var i = 0; i < 64; i++) arr.push(40 + 30 * Math.sin(i / 6.0) + Math.random() * 6)
        return arr
    }
}

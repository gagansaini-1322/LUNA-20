import QtQuick
import QtQuick.Layouts
import LunaHub
import LunaHub.Dashboard
import LunaHub.Controls
import LunaHub.Theme

pragma ComponentBehavior: Bound

Item {
    id: page
    property string routeName: "performance"

    property var sections: [
        { "label": "Overview" },
        { "label": "CPU" },
        { "label": "GPU" },
        { "label": "Memory" },
        { "label": "Thermals" },
        { "label": "Processes" }
    ]
    property int sectionIndex: 0

    Column {
        anchors.fill: parent
        anchors.margins: Metrics.xs24
        spacing: Metrics.xs16

        LunaTabBar {
            width: parent.width
            tabs: page.sections
            currentIndex: page.sectionIndex
            onCurrentChanged: (idx) => page.sectionIndex = idx
        }

        PerformanceMonitor {
            width: parent.width
            height: 280
        }

        Row {
            width: parent.width
            spacing: Metrics.xs16

            MetricCard {
                width: (parent.width - parent.spacing * 4) / 5
                metric: MetricCard.Metric.CPU
                title: "CPU 1-Core"
                primaryValue: "62"
                unit: "%"
                secondaryValue: "5.0 GHz"
                accent: Theme.cpuAccent
                sparkMax: 100
                trendPoints: page.cpuSeries()
            }
            MetricCard {
                width: (parent.width - parent.spacing * 4) / 5
                metric: MetricCard.Metric.CPU
                title: "CPU ALL"
                primaryValue: "48"
                unit: "%"
                secondaryValue: "65W"
                accent: Theme.cpuAccent
                sparkMax: 100
                trendPoints: page.fakeSeries()
            }
            MetricCard {
                width: (parent.width - parent.spacing * 4) / 5
                metric: MetricCard.Metric.GPU
                title: "GPU Core"
                primaryValue: "71"
                unit: "%"
                secondaryValue: "1.92 GHz"
                accent: Theme.gpuAccent
                sparkMax: 100
                trendPoints: page.fakeSeries()
            }
            MetricCard {
                width: (parent.width - parent.spacing * 4) / 5
                metric: MetricCard.Metric.RAM
                title: "RAM Used"
                primaryValue: "18.2"
                unit: "GB"
                secondaryValue: "57%"
                accent: Theme.ramAccent
                sparkMax: 32
                trendPoints: page.fakeSeries()
            }
            MetricCard {
                width: (parent.width - parent.spacing * 4) / 5
                metric: MetricCard.Metric.FPS
                title: "Frame P95"
                primaryValue: "9.4"
                unit: "ms"
                secondaryValue: "138 fps"
                accent: Theme.accentSecondary
                sparkMax: 16
                trendPoints: page.fakeSeries()
            }
        }

        Row {
            width: parent.width
            spacing: Metrics.xs16

            SystemInfoCard {
                width: parent.width * 0.55 - parent.spacing
                height: 240
            }

            TemperatureCard {
                width: parent.width * 0.45 - parent.spacing
                height: 240
                sensors: [
                    { "name": "CPU Package", "label": "Tctl", "value": 71, "max": 105, "status": "warm" },
                    { "name": "GPU", "label": "GPU", "value": 64, "max": 95, "status": "warm" },
                    { "name": "VRM", "label": "VRM", "value": 49, "max": 100, "status": "ok" }
                ]
            }
        }
    }

    function fakeSeries() {
        var arr = []
        for (var i = 0; i < 64; i++) arr.push(40 + 30 * Math.sin(i / 4.2))
        return arr
    }
    function cpuSeries() {
        var arr = []
        for (var i = 0; i < 64; i++) arr.push(28 + 40 * Math.abs(Math.sin(i / 5.0)))
        return arr
    }
}

import QtQuick
import QtQuick.Layouts
import LunaHub
import LunaHub.Dashboard
import LunaHub.Theme

pragma ComponentBehavior: Bound

Item {
    id: page
    property string routeName: "dashboard"

    property bool telemetryActive: true
    property string currentProfile: "Balanced"
    property string boostState: "on"

    readonly property var metricSlots: [
        { "metric": 0, "title": "CPU LOAD",       "primary": "62", "unit": "%", "secondary": "3.6 GHz", "accent": Theme.cpuAccent,  "value": 62, "max": 100, "samples": sampled("cpu") },
        { "metric": 1, "title": "MEMORY",         "primary": "18.2", "unit": "GB", "secondary": "57%", "accent": Theme.ramAccent, "value": 17, "max": 32, "samples": sampled("ram") },
        { "metric": 2, "title": "GPU",            "primary": "71", "unit": "%", "secondary": "1.92 GHz", "accent": Theme.gpuAccent, "value": 71, "max": 100, "samples": sampled("gpu") },
        { "metric": 3, "title": "FPS",            "primary": "138", "unit": " fps", "secondary": "144 cap", "accent": Theme.accentSecondary, "value": 138, "max": 240, "samples": sampled("fps") },
        { "metric": 4, "title": "NETWORK",        "primary": "0.9", "unit": " Mb/s", "secondary": "↕ 14ms", "accent": Theme.fanAccent, "value": 14, "max": 100, "samples": sampled("net") }
    ]

    readonly property var sensorList: [
        { "name": "CPU Package", "label": "Tctl",  "value": 71,  "max": 105, "status": "warm" },
        { "name": "GPU Core",    "label": "Edge",  "value": 64,  "max": 95,  "status": "warm" },
        { "name": "VRM",         "label": "VRM1",  "value": 49,  "max": 100, "status": "ok" },
        { "name": "Chipset",     "label": "PCH",   "value": 42,  "max": 90,  "status": "ok" },
        { "name": "SSD NVMe",    "label": "M.2",   "value": 38,  "max": 80,  "status": "ok" },
        { "name": "Liquid Loop", "label": "Inlet", "value": 33,  "max": 50,  "status": "ok" }
    ]

    function sampled(key) {
        var arr = []
        var n = 64
        for (var i = 0; i < n; i++) arr.push(40 + 30 * Math.sin(i / 6.0 + key.length))
        return arr
    }

    function networkSeries() {
        var s = ({})
        s.cpu = sampled("cpu")
        s.ram = sampled("ram")
        s.gpu = sampled("gpu")
        s.fps = sampled("fps")
        return s
    }

    function queueItems() {
        return [
            { "title": "Helldivers 2",        "game": "STEAM · active",  "status": "Running", "priority": "High" },
            { "title": "Counter-Strike 2",   "game": "STEAM · queued",  "status": "Ready",   "priority": "Normal" },
            { "title": "Baldur's Gate 3",    "game": "GOG · queued",    "status": "Paused",  "priority": "Low" },
            { "title": "Cyberpunk 2077",      "game": "GOG · installed", "status": "Ready",   "priority": "Normal" }
        ]
    }

    Item {
        anchors.fill: parent
        anchors.margins: Metrics.xs24

        Column {
            anchors.fill: parent
            spacing: Metrics.xs20

            SystemOverviewHeader {
                width: parent.width
                perfProfile: page.currentProfile
                perfActive: page.boostState === "on"
                onPerfModePrimary: page.queueBoost()
                onPerfModeTriggered: page.cycleProfile()
            }

            GridLayout {
                id: grid
                width: parent.width
                columns: 5
                columnSpacing: Metrics.xs12
                rowSpacing: Metrics.xs12

                Repeater {
                    model: page.metricSlots.length
                    delegate: MetricCard {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Metrics.cardMinHeight + 24
                        metric: page.metricSlots[index].metric
                        title: page.metricSlots[index].title
                        primaryValue: page.metricSlots[index].primary
                        unit: page.metricSlots[index].unit
                        secondaryValue: page.metricSlots[index].secondary
                        accent: page.metricSlots[index].accent
                        trendPoints: page.metricSlots[index].samples
                        showSparkline: true
                        state: page.telemetryActive ? MetricCard.State.Active : MetricCard.State.Waiting
                    }
                }
            }

            Row {
                width: parent.width
                spacing: Metrics.xs16

                PerformanceMonitor {
                    width: parent.width * 0.65 - parent.spacing / 2
                    height: 320
                    series: page.networkSeries()
                }

                LunaBoostBar {
                    width: parent.width * 0.35 - parent.spacing / 2
                    state: page.boostState
                    profileName: page.currentProfile
                    detailLabel: "3 actions running · 138 fps stable"
                }
            }

            Row {
                width: parent.width
                spacing: Metrics.xs16

                PerformanceQueue {
                    width: parent.width * 0.45 - parent.spacing / 2
                    height: 280
                    items: page.queueItems()
                    onAddRequested: page.addToQueue()
                }

                TemperatureCard {
                    width: parent.width * 0.30 - parent.spacing
                    height: 280
                    sensors: page.sensorList
                }

                FanControlCard {
                    width: parent.width * 0.25 - parent.spacing / 2
                    height: 280
                    currentRpm: 1280
                    maxRpm: 2200
                    percent: 58
                    profile: page.currentProfile
                    telemetryActive: page.telemetryActive
                }
            }
        }
    }

    function addToQueue() { openDialog("gameSelection", {}) }
    function queueBoost() { /* imperative: toggle boost */ }
    function cycleProfile() {
        var p = page.currentProfile
        page.currentProfile = p === "Silent" ? "Balanced"
                              : p === "Balanced" ? "Turbo"
                              : p === "Turbo" ? "Full Speed"
                              : "Silent"
    }
    function openDialog(name, props) { /* delegate to shell */ }
}

import QtQuick
import QtQuick.Layouts
import LunaHub
import LunaHub.Controls
import LunaHub.Theme

pragma ComponentBehavior: Bound

Rectangle {
    id: monitor

    property var series: ({})
    property var visibleSeries: (["cpu", "ram", "gpu", "fps"])
    property string rangeLabel: "60s"
    property int rangeIndex: 1
    signal rangeChanged_(int index)

    implicitHeight: 280

    readonly property var ranges: [
        { "label": "30s", "duration": 30000 },
        { "label": "60s", "duration": 60000 },
        { "label": "5m",  "duration": 300000 },
        { "label": "15m", "duration": 900000 }
    ]

    color: Theme.panelBg
    radius: Metrics.radiusLg
    border.width: Metrics.strokeHairline
    border.color: Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.65)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Metrics.xs20
        spacing: Metrics.xs12

        RowLayout {
            Layout.fillWidth: true
            spacing: Metrics.xs12
            Label {
                text: "Performance Monitor"
                color: Theme.textPrimary
                font.family: Typography.family
                font.pixelSize: Typography.pageHeading.size
                font.weight: Typography.pageHeading.weight
            }
            Item { Layout.fillWidth: true }
            LunaSegmented {
                Layout.preferredHeight: 30
                options: [
                    { "label": "30s" }, { "label": "60s" }, { "label": "5m" }, { "label": "15m" }
                ]
                currentIndex: monitor.rangeIndex
                onCurrentIndexChanged_: (idx) => {
                    monitor.rangeIndex = idx
                    monitor.rangeChanged_(idx)
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ChartCanvas {
                id: chart
                anchors.fill: parent
                series: monitor.series
                visibleSeries: monitor.visibleSeries
            }

            ChartLegend {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.leftMargin: Metrics.xs8
                anchors.bottomMargin: Metrics.xs8
            }
        }

        SeriesToggleRow {
            Layout.fillWidth: true
            visibleSeries: monitor.visibleSeries
            onToggleSeries: (key) => {
                var arr = monitor.visibleSeries.slice()
                var idx = arr.indexOf(key)
                if (idx >= 0) arr.splice(idx, 1)
                else arr.push(key)
                monitor.visibleSeries = arr
            }
        }
    }

    component ChartLegend: RowLayout {
        spacing: Metrics.xs12
        Repeater {
            model: [
                { "key": "cpu", "label": "CPU", "color": Theme.cpuAccent },
                { "key": "ram", "label": "RAM", "color": Theme.ramAccent },
                { "key": "gpu", "label": "GPU", "color": Theme.gpuAccent },
                { "key": "fps", "label": "FPS", "color": Theme.accentSecondary }
            ]
            delegate: RowLayout {
                spacing: Metrics.xs4
                Rectangle { width: 8; height: 2; color: modelData.color }
                Label {
                    text: modelData.label
                    color: Theme.textSecondary
                    font.family: Typography.family
                    font.pixelSize: Typography.caption.size
                    font.weight: Font.Medium
                }
            }
        }
    }
}

component ChartCanvas: Item {
    property var series: ({})
    property var visibleSeries: []

    implicitHeight: 200
    implicitWidth: 400

    Item {
        anchors.fill: parent

        // Grid lines
        Repeater {
            model: 5
            delegate: Rectangle {
                width: parent.width
                height: Metrics.strokeHairline
                y: parent.height * (index + 1) / 6
                color: Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.5)
            }
        }

        Repeater {
            model: 6
            delegate: Rectangle {
                width: Metrics.strokeHairline
                height: parent.height
                x: parent.width * index / 5
                color: Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.35)
            }
        }

        // Y-axis labels
        Column {
            anchors.left: parent.left
            anchors.leftMargin: -2
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            spacing: 0
            Label { visible: false }
            Label {
                anchors.top: parent.top
                text: "100%"
                color: Theme.textMuted
                font.family: Typography.family
                font.pixelSize: 9
            }
            Label {
                anchors.bottom: parent.bottom
                text: "0%"
                color: Theme.textMuted
                font.family: Typography.family
                font.pixelSize: 9
            }
            Item { Layout.fillHeight: true }
        }
    }

    Item {
        id: plotLayer
        anchors.fill: parent

        Canvas {
            id: perfCanvas
            anchors.fill: parent
            antialiasing: true
            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()
                var w = width
                var h = height
                var colors = {
                    "cpu": Theme.cpuAccent,
                    "ram": Theme.ramAccent,
                    "gpu": Theme.gpuAccent,
                    "fps": Theme.accentSecondary
                }
                var keys = Object.keys(series)
                for (var i = 0; i < keys.length; i++) {
                    var key = keys[i]
                    if (visibleSeries.indexOf(key) < 0) continue
                    var pts = series[key]
                    if (!pts || pts.length < 2) continue
                    var color = colors[key] || Theme.accentPrimary
                    var n = pts.length
                    var stepX = w / (n - 1)
                    ctx.beginPath()
                    for (var k = 0; k < n; k++) {
                        var xv = k * stepX
                        var vv = Math.max(0, Math.min(1, pts[k]))
                        var yv = h - vv * h
                        if (k === 0) ctx.moveTo(xv, yv)
                        else ctx.lineTo(xv, yv)
                    }
                    ctx.strokeStyle = color
                    ctx.lineWidth = 1.6
                    ctx.lineJoin = "round"
                    ctx.lineCap = "round"
                    ctx.stroke()

                    // fill
                    ctx.lineTo(w, h)
                    ctx.lineTo(0, h)
                    ctx.closePath()
                    ctx.fillStyle = Qt.rgba(color.r, color.g, color.b, 0.08)
                    ctx.fill()
                }
            }
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            Connections {
                target: plotLayer.parent
                function onSeriesChanged() { perfCanvas.requestPaint() }
                function onVisibleSeriesChanged() { perfCanvas.requestPaint() }
            }
        }
    }
}

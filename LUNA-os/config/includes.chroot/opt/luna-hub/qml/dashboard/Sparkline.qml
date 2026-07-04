import QtQuick
import LunaHub
import LunaHub.Theme

pragma ComponentBehavior: Bound

Item {
    id: sparkline

    property var points: []
    property color lineColor: Theme.accentPrimary
    property real fillOpacity: 0.18
    property real sampleMax: 100
    property real minValue: 0
    property bool showFill: true
    property bool showLine: true

    implicitHeight: 36
    implicitWidth: 200

    onPointsChanged: canvas.requestPaint()
    onLineColorChanged: canvas.requestPaint()
    onSampleMaxChanged: canvas.requestPaint()
    onFillOpacityChanged: canvas.requestPaint()
    onWidthChanged: canvas.requestPaint()
    onHeightChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true
        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            if (!sparkline.points || sparkline.points.length < 2) return
            var w = width
            var h = height
            var maxv = Math.max(sparkline.sampleMax, 1)
            var minv = sparkline.minValue
            var n = sparkline.points.length
            var stepX = w / (n - 1)

            // Fill
            if (sparkline.showFill) {
                ctx.beginPath()
                ctx.moveTo(0, h)
                for (var i = 0; i < n; i++) {
                    var x = i * stepX
                    var v = Math.max(minv, Math.min(maxv, (sparkline.points[i] - minv) / (maxv - minv)))
                    var y = h - v * h
                    ctx.lineTo(x, y)
                }
                ctx.lineTo(w, h)
                ctx.closePath()
                ctx.fillStyle = Qt.rgba(sparkline.lineColor.r, sparkline.lineColor.g, sparkline.lineColor.b, sparkline.fillOpacity)
                ctx.fill()
            }
            // Stroke
            if (sparkline.showLine) {
                ctx.beginPath()
                for (var k = 0; k < n; k++) {
                    var xv = k * stepX
                    var vv = Math.max(minv, Math.min(maxv, (sparkline.points[k] - minv) / (maxv - minv)))
                    var yv = h - vv * h
                    if (k === 0) ctx.moveTo(xv, yv)
                    else ctx.lineTo(xv, yv)
                }
                ctx.strokeStyle = sparkline.lineColor
                ctx.lineWidth = Metrics.graphStrokeWidth
                ctx.lineJoin = "round"
                ctx.lineCap = "round"
                ctx.stroke()
            }
        }
    }
}

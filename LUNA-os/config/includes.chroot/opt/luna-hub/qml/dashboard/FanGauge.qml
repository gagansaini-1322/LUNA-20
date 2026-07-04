import QtQuick
import LunaHub
import LunaHub.Theme

pragma ComponentBehavior: Bound

Item {
    id: gauge

    property int rpmValue: 0
    property int maxRpm: 2200
    property bool active: true
    property bool rotate: false
    property color bandColor: Theme.fanAccent

    implicitHeight: 110
    implicitWidth: 110

    Rectangle {
        anchors.fill: parent
        radius: width * 0.5
        color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.5)
        border.width: Metrics.strokeHairline
        border.color: Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.65)

        Item {
            anchors.fill: parent
            anchors.margins: 8

            // Bands: Low (60), Med (60->140), High (140->Max)
            Repeater {
                model: [
                    { "start": 0,    "end": 60,   "color": Theme.disabledColor },
                    { "start": 60,   "end": 140,  "color": Theme.successColor },
                    { "start": 141,  "end": 1000, "color": Theme.warningColor },
                    { "start": 0,    "end": 2200, "color": Theme.criticalColor }
                ]
                delegate: Canvas {
                    anchors.fill: parent
                    antialiasing: true
                    property real start: modelData.start
                    property real end: modelData.end
                    property color col: modelData.color
                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.reset()
                        if (!active) return
                        var w = width
                        var h = height
                        var r = Math.min(w, h) / 2
                        var cx = w / 2
                        var cy = h / 2
                        var startDeg = 135
                        var sweepDeg = 270
                        var startA = (start / gauge.maxRpm) * sweepDeg + startDeg
                        var endA = (end / gauge.maxRpm) * sweepDeg + startDeg
                        var startRad = (startA - 90) * Math.PI / 180.0
                        var endRad = (endA - 90) * Math.PI / 180.0
                        ctx.beginPath()
                        ctx.arc(cx, cy, r - 6, startRad, endRad)
                        ctx.strokeStyle = col
                        ctx.lineWidth = 6
                        ctx.lineCap = "butt"
                        ctx.stroke()
                    }
                    Component.onCompleted: requestPaint()
                }
            }
        }

        Item {
            id: fan
            anchors.fill: parent
            anchors.margins: 22
            visible: active

            Rectangle {
                anchors.centerIn: parent
                width: parent.width * 0.7
                height: width
                radius: width * 0.5
                color: Qt.rgba(Theme.bgElevated.r, Theme.bgElevated.g, Theme.bgElevated.b, 0.5)
                border.width: Metrics.strokeHairline
                border.color: Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.65)
            }

            Rectangle {
                anchors.centerIn: parent
                width: parent.width
                height: 4
                color: Theme.fanAccent
                radius: 2
                transformOrigin: Item.Center
                rotation: 0
                NumberAnimation on rotation {
                    running: gauge.rotate
                    from: 0
                    to: 360
                    duration: 4000
                    loops: Animation.Infinite
                }
            }

            Rectangle {
                anchors.centerIn: parent
                width: parent.width * 0.8
                height: 4
                color: Qt.rgba(Theme.fanAccent.r, Theme.fanAccent.g, Theme.fanAccent.b, 0.55)
                radius: 2
                rotation: 45
                transformOrigin: Item.Center
                NumberAnimation on rotation {
                    running: gauge.rotate
                    from: 45
                    to: 405
                    duration: 4800
                    loops: Animation.Infinite
                }
            }
        }

        Item {
            anchors.centerIn: parent
            width: parent.width - 12
            height: 18
            Rectangle {
                anchors.fill: parent
                radius: height * 0.5
                color: Qt.rgba(Theme.bgSecondary.r, Theme.bgSecondary.g, Theme.bgSecondary.b, 0.85)
                border.width: Metrics.strokeHairline
                border.color: Qt.rgba(Theme.borderHover.r, Theme.borderHover.g, Theme.borderHover.b, 0.55)
            }
            Label {
                anchors.centerIn: parent
                text: gauge.rpmValue + " RPM"
                color: Theme.textPrimary
                font.family: Typography.family
                font.pixelSize: Typography.smallTelemetry.size
                font.weight: Font.DemiBold
                font.features: { "tnum": true }
            }
        }
    }

    Loader {
        active: !gauge.active
        anchors.fill: parent
        sourceComponent: Item {
            anchors.fill: parent
            Label {
                anchors.centerIn: parent
                text: "OFF"
                color: Theme.textMuted
                font.family: Typography.family
                font.pixelSize: Typography.caption.size
                font.weight: Font.DemiBold
            }
        }
    }
}

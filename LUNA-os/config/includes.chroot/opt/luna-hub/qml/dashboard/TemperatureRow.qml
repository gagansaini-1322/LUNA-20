import QtQuick
import LunaHub
import LunaHub.Controls
import LunaHub.Theme

pragma ComponentBehavior: Bound

Rectangle {
    id: row

    property string sensorName: ""
    property real sensorValue: 0
    property string sensorLabel: ""
    property string sensorStatus: "ok"
    property real maxValue: 100

    color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.35)
    radius: Metrics.radiusMd
    border.width: Metrics.strokeHairline
    border.color: Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.5)

    implicitHeight: 36

    function statusColor() {
        if (sensorStatus === "hot") return Theme.criticalColor
        if (sensorStatus === "warm") return Theme.warningColor
        return Theme.successColor
    }

    function validate() {
        if (sensorStatus === "hot") return Theme.criticalColor
        if (sensorStatus === "warm") return Theme.warningColor
        return Theme.successColor
    }

    Row {
        anchors.fill: parent
        anchors.leftMargin: Metrics.xs12
        anchors.rightMargin: Metrics.xs12
        spacing: Metrics.xs12

        Rectangle {
            width: 8
            height: 8
            radius: 4
            color: row.validate()
            anchors.verticalCenter: parent.verticalCenter
        }

        Label {
            text: row.sensorName
            color: Theme.textPrimary
            font.family: Typography.family
            font.pixelSize: Typography.bodyLabel.size
            width: 96
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
        }

        Label {
            text: row.sensorLabel
            color: Theme.textMuted
            font.family: Typography.family
            font.pixelSize: Typography.caption.size
            width: 80
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
        }

        Item {
            height: 4
            width: parent.width - 280
            anchors.verticalCenter: parent.verticalCenter
            Rectangle {
                anchors.fill: parent
                radius: height * 0.5
                color: Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.55)
            }
            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width * Math.min(1, row.sensorValue / row.maxValue)
                radius: height * 0.5
                color: row.validate()
                Behavior on width { NumberAnimation { duration: Metrics.durFast } }
            }
        }

        Label {
            text: Math.round(row.sensorValue) + "°C"
            color: row.sensorStatus === "hot" ? Theme.criticalColor : Theme.textPrimary
            font.family: Typography.family
            font.pixelSize: Typography.telemetryValue.size
            font.weight: Typography.telemetryValue.weight
            font.features: { "tnum": true }
            anchors.verticalCenter: parent.verticalCenter
        }

        LunaStatusBadge {
            anchors.verticalCenter: parent.verticalCenter
            text: row.sensorStatus === "ok" ? "OK" : row.sensorStatus === "warm" ? "Warm" : "Hot"
            tone: row.sensorStatus === "ok" ? LunaStatusBadge.Tone.Success
                  : row.sensorStatus === "warm" ? LunaStatusBadge.Tone.Warning
                  : LunaStatusBadge.Tone.Critical
            dot: true
        }
    }
}

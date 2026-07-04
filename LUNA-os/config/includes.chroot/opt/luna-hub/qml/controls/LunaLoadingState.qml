import QtQuick
import LunaHub
import LunaHub.Theme

pragma ComponentBehavior: Bound

Item {
    id: control

    property string label: "Loading"
    property string sublabel: ""
    property real size: 28

    implicitHeight: column.implicitHeight + Metrics.xs16 * 2
    implicitWidth: 200

    Column {
        id: column
        anchors.centerIn: parent
        spacing: Metrics.xs12

        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: control.size
            height: control.size
            NumberAnimation on rotation {
                from: 0
                to: 360
                duration: Metrics.durSpinner
                loops: Animation.Infinite
                running: true
            }
            Canvas {
                anchors.fill: parent
                antialiasing: true
                property real t: 0.0
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.reset()
                    ctx.lineWidth = 2
                    ctx.strokeStyle = Theme.accentPrimary
                    ctx.beginPath()
                    ctx.arc(control.size / 2, control.size / 2,
                            control.size / 2 - 2, 0, Math.PI * 1.6)
                    ctx.stroke()
                    ctx.strokeStyle = Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.4)
                    ctx.beginPath()
                    ctx.arc(control.size / 2, control.size / 2,
                            control.size / 2 - 2, Math.PI * 1.6, Math.PI * 2)
                    ctx.stroke()
                }
            }
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: control.label
            color: Theme.textSecondary
            font.family: Typography.family
            font.pixelSize: Typography.bodyLabel.size
            font.weight: Font.Medium
        }
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: control.sublabel.length > 0
            text: control.sublabel
            color: Theme.textMuted
            font.family: Typography.family
            font.pixelSize: Typography.caption.size
        }
    }
}

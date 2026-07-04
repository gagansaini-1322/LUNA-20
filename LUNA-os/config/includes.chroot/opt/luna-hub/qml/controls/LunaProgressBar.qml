import QtQuick
import LunaHub
import LunaHub.Theme

pragma ComponentBehavior: Bound

Item {
    id: control

    property real value: 0
    property real max: 1
    property color fillColor: Theme.accentPrimary
    property color trackColor: Theme.borderDefault
    property bool showLabel: false
    property string unit: "%"
    property bool indeterminate: false
    readonly property real computed: Math.max(0, Math.min(1, max > 0 ? value / max : 0))

    implicitHeight: 6
    implicitWidth: 240

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height * 0.5
        color: control.trackColor
        opacity: 0.6
        Rectangle {
            id: fillRect
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            radius: height * 0.5
            color: control.fillColor
            width: control.indeterminate
                   ? parent.width * 0.35
                   : parent.width * control.computed
            Behavior on width {
                NumberAnimation { duration: Metrics.durFast }
            }
            NumberAnimation on x {
                running: control.indeterminate
                from: -parent.width * 0.35
                to: parent.width
                duration: 1100
                loops: Animation.Infinite
            }
            visible: control.indeterminate || control.computed > 0
        }
    }

    Item {
        anchors.fill: parent
        visible: control.showLabel
        Label {
            anchors.centerIn: parent
            visible: !control.indeterminate
            text: Math.round(control.computed * 100) + control.unit
            color: Theme.textSecondary
            font.family: Typography.family
            font.pixelSize: Typography.caption.size
            font.weight: Font.Medium
        }
    }
}

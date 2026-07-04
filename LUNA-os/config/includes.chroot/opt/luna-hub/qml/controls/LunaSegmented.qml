import QtQuick
import LunaHub
import LunaHub.Theme

pragma ComponentBehavior: Bound

Item {
    id: control

    property var options: []
    property int currentIndex: 0
    signal currentIndexChanged_(int idx)

    implicitHeight: 32

    Rectangle {
        id: track
        anchors.fill: parent
        radius: Metrics.radiusMd
        color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.45)
        border.width: Metrics.strokeHairline
        border.color: Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.55)
        smooth: true
    }

    Item {
        id: highlight
        width: track.width / Math.max(1, control.options.length)
        height: track.height - 2
        x: 1 + width * control.currentIndex
        y: 1
        radius: Metrics.radiusSm + 4
        color: Qt.rgba(Theme.accentPrimary.r, Theme.accentPrimary.g, Theme.accentPrimary.b, 0.32)
        border.width: Metrics.strokeHairline
        border.color: Qt.rgba(Theme.accentPrimary.r, Theme.accentPrimary.g, Theme.accentPrimary.b, 0.55)
        Rectangle {
            anchors.fill: parent
            anchors.margins: -1
            radius: Metrics.radiusSm + 5
            color: "transparent"
            border.color: Theme.accentPrimary
            border.width: Metrics.strokeThin
            opacity: Theme.glowSoft
        }
        Behavior on x { NumberAnimation { duration: Metrics.durIndicator; easing.type: Easing.OutCubic } }
    }

    Row {
        anchors.fill: parent
        Repeater {
            model: control.options.length
            delegate: Item {
                width: track.width / Math.max(1, control.options.length)
                height: track.height
                Label {
                    anchors.centerIn: parent
                    text: control.options[index].label !== undefined ? control.options[index].label : ""
                    color: control.currentIndex === index ? Theme.textPrimary : Theme.textSecondary
                    font.family: Typography.family
                    font.pixelSize: Typography.buttonLabel.size
                    font.weight: Font.Medium
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        control.currentIndex = index
                        control.currentIndexChanged_(index)
                    }
                }
            }
        }
    }
}

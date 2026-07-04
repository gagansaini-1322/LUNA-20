import QtQuick
import QtQuick.Layouts
import LunaHub
import LunaHub.Controls
import LunaHub.Theme

pragma ComponentBehavior: Bound

Item {
    id: control

    property var tabs: []
    property int currentIndex: 0
    signal currentChanged(int index)

    readonly property int itemHeight: 30
    implicitHeight: itemHeight + Metrics.xs8 * 2

    Row {
        id: row
        anchors.fill: parent
        anchors.leftMargin: Metrics.xs4
        anchors.rightMargin: Metrics.xs4
        spacing: 0

        Repeater {
            model: control.tabs.length
            delegate: Rectangle {
                id: pill
                width: calcWidth()
                height: control.itemHeight
                radius: Metrics.radiusMd
                color: control.currentIndex === index
                       ? Qt.rgba(Theme.accentPrimary.r, Theme.accentPrimary.g, Theme.accentPrimary.b, 0.22)
                       : "transparent"
                border.width: control.currentIndex === index ? Metrics.strokeHairline : 0
                border.color: Qt.rgba(Theme.accentPrimary.r, Theme.accentPrimary.g, Theme.accentPrimary.b, 0.45)

                Behavior on color { ColorAnimation { duration: Metrics.durFast } }

                Row {
                    anchors.centerIn: parent
                    spacing: Metrics.xs8

                    Label {
                        visible: control.tabs[index].icon !== undefined
                        text: control.tabs[index].icon || ""
                        color: control.currentIndex === index ? Theme.textPrimary : Theme.textMuted
                        font.family: Typography.family
                        font.pixelSize: Typography.buttonLabel.size
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Label {
                        text: control.tabs[index].label || ""
                        color: control.currentIndex === index ? Theme.textPrimary : Theme.textSecondary
                        font.family: Typography.family
                        font.pixelSize: Typography.buttonLabel.size
                        font.weight: Font.Medium
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    LunaStatusBadge {
                        visible: control.tabs[index].badge !== undefined
                        text: control.tabs[index].badge || ""
                        tone: control.tabs[index].badgeTone !== undefined ? control.tabs[index].badgeTone : LunaStatusBadge.Tone.Neutral
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: {
                        control.currentIndex = index
                        control.currentChanged(index)
                    }
                    onEntered: pill.color = control.currentIndex === index
                                   ? Qt.rgba(Theme.accentPrimary.r, Theme.accentPrimary.g, Theme.accentPrimary.b, 0.28)
                                   : Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.18)
                    onExited: pill.color = control.currentIndex === index
                                   ? Qt.rgba(Theme.accentPrimary.r, Theme.accentPrimary.g, Theme.accentPrimary.b, 0.22)
                                   : "transparent"
                }
            }
        }
    }

    Rectangle {
        anchors.left: row.left
        anchors.right: row.right
        anchors.bottom: parent.bottom
        height: Metrics.strokeHairline
        color: Theme.borderDefault
    }

    function calcWidth() {
        var maxW = 120
        var base = 32
        if (tabs.length === 0) return base
        var total = parent ? parent.width - Metrics.xs4 * 2 : 600
        return Math.max(base, total / tabs.length)
    }

    Behavior on currentIndex { enabled: false }
}

import QtQuick
import LunaHub
import LunaHub.Theme

pragma ComponentBehavior: Bound

RowLayout {
    id: row
    property var visibleSeries: ["cpu", "ram", "gpu", "fps"]
    signal toggleSeries(string key)
    spacing: Metrics.xs12

    Repeater {
        model: [
            { "key": "cpu", "label": "CPU", "color": Theme.cpuAccent },
            { "key": "ram", "label": "RAM", "color": Theme.ramAccent },
            { "key": "gpu", "label": "GPU", "color": Theme.gpuAccent },
            { "key": "fps", "label": "FPS", "color": Theme.accentSecondary }
        ]
        delegate: Rectangle {
            Layout.preferredHeight: 26
            radius: Metrics.radiusMd
            color: row.visibleSeries.indexOf(modelData.key) >= 0
                   ? Qt.rgba(modelData.color.r, modelData.color.g, modelData.color.b, 0.18)
                   : Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.45)
            border.width: Metrics.strokeHairline
            border.color: row.visibleSeries.indexOf(modelData.key) >= 0
                   ? Qt.rgba(modelData.color.r, modelData.color.g, modelData.color.b, 0.5)
                   : Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.55)
            Behavior on color { ColorAnimation { duration: Metrics.durFast } }
            Behavior on border.color { ColorAnimation { duration: Metrics.durFast } }

            Row {
                anchors.fill: parent
                anchors.leftMargin: Metrics.xs12
                anchors.rightMargin: Metrics.xs12
                spacing: Metrics.xs8
                Rectangle {
                    width: 8
                    height: 8
                    radius: 4
                    color: modelData.color
                    anchors.verticalCenter: parent.verticalCenter
                }
                Label {
                    text: modelData.label
                    color: Theme.textPrimary
                    font.family: Typography.family
                    font.pixelSize: Typography.caption.size
                    font.weight: Font.Medium
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: row.toggleSeries(modelData.key)
            }
        }
    }
}

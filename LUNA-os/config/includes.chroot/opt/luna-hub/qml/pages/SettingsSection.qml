import QtQuick
import LunaHub
import LunaHub.Theme

pragma ComponentBehavior: Bound

Rectangle {
    id: section

    property string heading: ""
    property string subheading: ""
    default property alias sectionItems: contentHolder.children
    color: Theme.panelBg
    radius: Metrics.radiusLg
    border.width: Metrics.strokeHairline
    border.color: Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.65)

    implicitHeight: layout.implicitHeight + Metrics.xs40

    Column {
        id: layout
        anchors.fill: parent
        anchors.margins: Metrics.xs20
        spacing: Metrics.xs12

        Column {
            width: parent.width
            spacing: Metrics.xs4
            Label {
                text: section.heading
                color: Theme.textPrimary
                font.family: Typography.family
                font.pixelSize: Typography.pageHeading.size
                font.weight: Typography.pageHeading.weight
            }
            Label {
                visible: section.subheading.length > 0
                text: section.subheading
                color: Theme.textSecondary
                font.family: Typography.family
                font.pixelSize: Typography.bodyLabel.size
                wrapMode: Text.WordWrap
                width: parent.width
            }
        }

        Column {
            id: contentHolder
            width: parent.width
            spacing: Metrics.xs12
        }
    }
}

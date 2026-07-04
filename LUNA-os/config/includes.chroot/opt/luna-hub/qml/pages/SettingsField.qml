import QtQuick
import LunaHub
import LunaHub.Theme

pragma ComponentBehavior: Bound

Item {
    id: field
    property string label: ""
    property string description: ""
    default property Item field

    implicitHeight: 48
    implicitWidth: 600

    Row {
        anchors.fill: parent
        spacing: Metrics.xs16

        Column {
            width: parent.width - 260
            spacing: 2
            anchors.verticalCenter: parent.verticalCenter
            Label {
                text: field.label
                color: Theme.textPrimary
                font.family: Typography.family
                font.pixelSize: Typography.bodyLabel.size
                font.weight: Font.Medium
            }
            Label {
                visible: field.description.length > 0
                text: field.description
                color: Theme.textMuted
                font.family: Typography.family
                font.pixelSize: Typography.caption.size
                wrapMode: Text.WordWrap
                width: parent.width
            }
        }

        Item {
            width: 240
            anchors.verticalCenter: parent.verticalCenter
            Loader {
                anchors.fill: parent
                sourceComponent: field.field
            }
        }
    }
}

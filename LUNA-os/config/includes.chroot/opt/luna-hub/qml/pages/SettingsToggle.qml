import QtQuick
import LunaHub
import LunaHub.Controls
import LunaHub.Theme

pragma ComponentBehavior: Bound

Item {
    id: tog
    property string label: ""
    property string description: ""
    property bool checked: false

    implicitHeight: 44

    Row {
        anchors.fill: parent
        spacing: Metrics.xs16

        Column {
            width: parent.width - 60
            spacing: 2
            anchors.verticalCenter: parent.verticalCenter
            Label {
                text: tog.label
                color: Theme.textPrimary
                font.family: Typography.family
                font.pixelSize: Typography.bodyLabel.size
                font.weight: Font.Medium
            }
            Label {
                visible: tog.description.length > 0
                text: tog.description
                color: Theme.textMuted
                font.family: Typography.family
                font.pixelSize: Typography.caption.size
                wrapMode: Text.WordWrap
                width: parent.width
            }
        }

        LunaToggle {
            anchors.verticalCenter: parent.verticalCenter
            checked: tog.checked
        }
    }
}

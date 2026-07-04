import QtQuick
import QtQuick.Controls.Basic
import LunaHub
import LunaHub.Theme

pragma ComponentBehavior: Bound

TextField {
    id: control

    property string label: ""
    property string helper: ""
    property string errorText: ""
    property string leadingIcon: ""
    property string trailingIcon: ""
    property bool compact: false
    property int sizeMode: 0

    background: Rectangle {
        radius: Metrics.radiusMd
        color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.45)
        border.width: Metrics.strokeHairline
        border.color: {
            if (control.errorText.length > 0) return Theme.criticalColor
            if (control.activeFocus) return Theme.borderActive
            if (control.hovered) return Theme.borderHover
            return Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.55)
        }
        Behavior on border.color { ColorAnimation { duration: Metrics.durFast } }
        implicitHeight: control.sizeMode === 1 ? 30 : 36
    }

    color: Theme.textPrimary
    placeholderTextColor: Theme.textMuted
    selectionColor: Theme.accentPrimary
    selectedTextColor: Theme.textPrimary
    font.family: Typography.family
    font.pixelSize: Typography.bodyLabel.size
    leftPadding: (control.leadingIcon.length > 0 ? Metrics.xs32 : Metrics.xs12)
    rightPadding: (control.trailingIcon.length > 0 ? Metrics.xs32 : Metrics.xs12)
    verticalAlignment: TextInput.AlignVCenter
    placeholderText: ""

    Item {
        parent: control
        anchors.left: control.left
        anchors.leftMargin: Metrics.xs12
        anchors.verticalCenter: control.verticalCenter
        width: Metrics.iconMd
        height: Metrics.iconMd
        visible: control.leadingIcon.length > 0
        Label {
            anchors.centerIn: parent
            text: control.leadingIcon
            color: Theme.textMuted
            font.pixelSize: Metrics.iconMd
            font.family: Typography.family
        }
    }
    Item {
        parent: control
        anchors.right: control.right
        anchors.rightMargin: Metrics.xs12
        anchors.verticalCenter: control.verticalCenter
        width: Metrics.iconMd
        height: Metrics.iconMd
        visible: control.trailingIcon.length > 0
        Label {
            anchors.centerIn: parent
            text: control.trailingIcon
            color: Theme.textMuted
            font.pixelSize: Metrics.iconMd
            font.family: Typography.family
        }
    }

    Accessible.role: Accessible.EditableText
    Accessible.name: label
}

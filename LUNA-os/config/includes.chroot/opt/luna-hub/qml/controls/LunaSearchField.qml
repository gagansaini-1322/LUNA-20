import QtQuick
import QtQuick.Controls.Basic
import LunaHub
import LunaHub.Controls
import LunaHub.Theme

pragma ComponentBehavior: Bound

Rectangle {
    id: control

    property string placeholder: "Search…"
    property alias text: field.text
    property string helper: ""
    signal accepted()

    implicitHeight: 36
    implicitWidth: 280

    radius: Metrics.radiusMd
    color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.45)
    border.width: Metrics.strokeHairline
    border.color: {
        if (field.activeFocus) return Theme.borderActive
        if (hover.containsMouse) return Theme.borderHover
        return Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.55)
    }
    Behavior on border.color { ColorAnimation { duration: Metrics.durFast } }

    Row {
        anchors.fill: parent
        anchors.leftMargin: Metrics.xs12
        anchors.rightMargin: Metrics.xs8
        spacing: Metrics.xs8

        Item {
            width: Metrics.iconMd
            height: parent.height
            Label {
                anchors.centerIn: parent
                text: "⌕"
                color: Theme.textMuted
                font.pixelSize: Metrics.iconMd + 2
                font.family: Typography.family
            }
        }

        TextField {
            id: field
            width: parent.width - 32
            height: parent.height
            background: Item {}
            color: Theme.textPrimary
            placeholderText: control.placeholder
            placeholderTextColor: Theme.textMuted
            selectionColor: Theme.accentPrimary
            selectedTextColor: Theme.textPrimary
            font.family: Typography.family
            font.pixelSize: Typography.bodyLabel.size
            verticalAlignment: TextInput.AlignVCenter
            clip: true
            selectByMouse: true
            onAccepted: control.accepted()
        }

        Item {
            width: 24
            height: parent.height
            visible: field.text.length > 0
            LunaIconButton {
                anchors.centerIn: parent
                iconName: "✕"
                iconPx: Metrics.iconSm
                tooltipText: "Clear"
                onClicked: { field.clear() }
            }
        }
    }

    HoverHandler { id: hover }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.IBeamCursor
        onPressed: (m) => { field.forceActiveFocus(); m.accepted = true }
    }
}

import QtQuick
import QtQuick.Controls.Basic
import LunaHub
import LunaHub.Theme

pragma ComponentBehavior: Bound

ComboBox {
    id: control

    property color accent: Theme.accentPrimary
    property string placeholder: ""
    property bool compact: false
    property var valueRole: "value"
    property var displayRole: "label"
    property var modelArray: []

    flat: true
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus

    font.family: Typography.family
    font.pixelSize: Typography.buttonLabel.size
    font.weight: Typography.buttonLabel.weight

    implicitHeight: compact ? 30 : 34
    implicitWidth: 160

    model: modelArray
    textRole: typeof displayRole === "string" ? displayRole : ""

    onActivated: (index) => {
        if (index >= 0 && index < modelArray.length) {
            currentValue = (typeof modelArray[index] === "object" && modelArray[index] !== null)
                ? modelArray[index][valueRole]
                : modelArray[index]
            valueSelected(currentValue, index)
        }
    }
    property var currentIndex_: -1
    property var currentValue: null

    signal valueSelected(var value, int index)

    indicator: Item {
        x: control.width - width - Metrics.xs12
        y: control.topPadding + (control.availableHeight - height) / 2
        width: Metrics.iconSm
        height: Metrics.iconSm
        Label {
            anchors.centerIn: parent
            text: control.popup.visible ? "▴" : "▾"
            color: Theme.textSecondary
            font.pixelSize: Metrics.iconSm
            font.family: Typography.family
        }
    }

    background: Rectangle {
        radius: Metrics.radiusMd
        color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.45)
        border.width: Metrics.strokeHairline
        border.color: {
            if (control.activeFocus) return Theme.borderActive
            if (control.hovered) return Theme.borderHover
            return Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.55)
        }
        Behavior on border.color { ColorAnimation { duration: Metrics.durFast } }
    }

    contentItem: Row {
        anchors.left: parent.left
        anchors.leftMargin: Metrics.xs12
        anchors.right: parent.right
        anchors.rightMargin: Metrics.xs32
        anchors.verticalCenter: parent.verticalCenter
        spacing: Metrics.xs8
        Label {
            text: control.placeholder.length > 0 && control.currentIndex === -1
                  ? control.placeholder
                  : (control.currentText || control.placeholder)
            color: control.currentIndex < 0 ? Theme.textMuted : Theme.textPrimary
            font: control.font
            elide: Text.ElideRight
            width: parent.width - parent.spacing
            verticalAlignment: Text.AlignVCenter
        }
    }

    popup: Popup {
        y: control.height + Metrics.xs4
        width: control.width
        implicitHeight: contentItem.implicitHeight + Metrics.xs8 * 2
        padding: Metrics.xs4
        opacity: 1.0
        Behavior on opacity {
            NumberAnimation { duration: Metrics.durFade }
        }
        enter: Transition {
            Parallel {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Metrics.durFade }
            }
        }
        exit: Transition {
            Parallel {
                NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Metrics.durFade }
            }
        }
        background: Rectangle {
            radius: Metrics.radiusMd
            color: Theme.bgElevated
            border.width: Metrics.strokeHairline
            border.color: Theme.borderHover
        }

        contentItem: ListView {
            id: listView
            clip: true
            implicitHeight: contentHeight
            model: control.delegateModel
            currentIndex: control.currentIndex
            spacing: 0
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
        }

        delegate: ItemDelegate {
            id: del
            width: listView.width
            text: typeof modelData === "object" && modelData !== null ? modelData[control.displayRole] : modelData
            hoverEnabled: true
            background: Rectangle {
                radius: Metrics.radiusSm
                color: {
                    if (del.hovered || del.highlighted) return Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.4)
                    return "transparent"
                }
            }
            contentItem: Label {
                text: del.text
                color: del.highlighted ? Theme.textPrimary : Theme.textSecondary
                font.family: Typography.family
                font.pixelSize: Typography.bodyLabel.size
                verticalAlignment: Text.AlignVCenter
            }
            highlighted: ListView.isCurrentItem
        }
    }
}

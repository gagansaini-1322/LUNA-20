import QtQuick
import QtQuick.Layouts
import LunaHub
import LunaHub.Controls
import LunaHub.Theme

pragma ComponentBehavior: Bound

Dialog {
    id: control

    property string title: ""
    property string subtitle: ""
    property string confirmLabel: "Confirm"
    property string cancelLabel: "Cancel"
    property bool destructive: false
    property var actions: []

    signal confirmed()
    signal cancelled()

    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent
    padding: 0
    parent: Overlay.overlay
    anchors.centerIn: parent

    implicitWidth: Math.min(480, Overlay.overlay ? Overlay.overlay.width - 48 : 480)
    implicitHeight: Math.min(contentColumn.implicitHeight + Metrics.xs24 * 2, 600)

    enter: Transition {
        Parallel {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Metrics.durModal }
        }
    }
    exit: Transition {
        Parallel {
            NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Metrics.durModal }
        }
    }

    background: Rectangle {
        id: bg
        color: Theme.bgElevated
        radius: Metrics.radiusLg
        border.width: Metrics.strokeHairline
        border.color: Theme.borderHover
        Rectangle {
            anchors.fill: parent
            anchors.margins: -1
            radius: Metrics.radiusLg + 1
            color: "transparent"
            border.color: Theme.accentPrimary
            border.width: Metrics.strokeThin
            opacity: Theme.glowSoft
        }
    }

    contentItem: ColumnLayout {
        id: contentColumn
        spacing: 0
        anchors.fill: parent

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: Metrics.iconXxl + Metrics.xs24
            Column {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Metrics.xs24
                anchors.rightMargin: Metrics.xs24
                spacing: Metrics.xs4
                Label {
                    text: control.title
                    color: Theme.textPrimary
                    font.family: Typography.family
                    font.pixelSize: Typography.pageHeading.size
                    font.weight: Typography.pageHeading.weight
                    wrapMode: Text.WordWrap
                    width: parent.width
                }
                Label {
                    visible: control.subtitle.length > 0
                    text: control.subtitle
                    color: Theme.textSecondary
                    font.family: Typography.family
                    font.pixelSize: Typography.bodyLabel.size
                    wrapMode: Text.WordWrap
                    width: parent.width
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: Metrics.strokeHairline
            color: Theme.borderDefault
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: Metrics.xs24
            Item {
                id: bodyHost
                anchors.fill: parent
                data: control.body ? [control.body] : []
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: Metrics.strokeHairline
            color: Theme.borderDefault
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: Metrics.iconXl * 2
            Layout.margins: Metrics.xs16
            Layout.rightMargin: Metrics.xs24
            spacing: Metrics.xs12
            Item { Layout.fillWidth: true }
            LunaButton {
                Layout.preferredHeight: 36
                text: control.cancelLabel
                variant: LunaButton.Variant.Ghost
                onClicked: { control.cancelled(); control.close() }
            }
            LunaButton {
                Layout.preferredHeight: 36
                Layout.preferredWidth: 120
                text: control.confirmLabel
                variant: control.destructive ? LunaButton.Variant.Danger : LunaButton.Variant.Primary
                onClicked: { control.confirmed(); control.close() }
            }
        }
    }

    property Item body: null

    BackdropOverlay {
        anchors.fill: parent
        onClicked: { control.cancelled(); control.close() }
    }

    BackdropOverlay { id: backdrop }
}

component BackdropOverlay: Rectangle {
    color: Qt.rgba(Theme.overlayBg.r, Theme.overlayBg.g, Theme.overlayBg.b, 0.7)
    anchors.fill: parent
    Behavior on opacity { NumberAnimation { duration: Metrics.durFade } }
}

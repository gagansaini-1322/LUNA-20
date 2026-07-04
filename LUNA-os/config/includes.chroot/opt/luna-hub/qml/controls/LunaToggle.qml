import QtQuick
import QtQuick.Controls.Basic
import LunaHub
import LunaHub.Theme

pragma ComponentBehavior: Bound

Switch {
    id: control

    property string label: ""
    property string description: ""
    property color accentOverride: Theme.accentPrimary
    property bool respectReducedMotion: true

    padding: 0
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus

    implicitWidth: 38
    implicitHeight: 22

    background: Item {
        Rectangle {
            id: track
            anchors.fill: parent
            radius: height * 0.5
            color: control.checked
                ? control.accentOverride
                : Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.85)
            border.width: Metrics.strokeHairline
            border.color: control.checked
                ? Qt.lighter(control.accentOverride, 1.15)
                : Theme.borderHover
            opacity: control.enabled ? 1.0 : 0.5

            Behavior on color {
                ColorAnimation { duration: Metrics.durToggle }
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: -2
                radius: height * 0.5
                color: "transparent"
                border.color: control.accentOverride
                border.width: Metrics.strokeThin
                opacity: control.checked && control.activeFocus ? Theme.glowMedium : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: Metrics.durToggle } }
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: control.checked ? parent.height - 6 : parent.height - 10
                height: width
                radius: width * 0.5
                x: control.checked ? (parent.width - width - 3) : 5
                color: Theme.textPrimary
                Behavior on x {
                    NumberAnimation { duration: control.respectReducedMotion ? Metrics.durToggle : Metrics.durFast }
                }
                Behavior on width {
                    NumberAnimation { duration: Metrics.durToggle }
                }
            }
        }
    }

    indicator: null
    contentItem: null

    Accessible.role: Accessible.CheckBox
    Accessible.name: label
    Accessible.description: description
    Accessible.checkable: true
    Accessible.checked: checked

    Behavior on focus { enabled: false }
}

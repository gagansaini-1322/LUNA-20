import LunaHub
import LunaHub.Theme

pragma ComponentBehavior: Bound

Item {
    id: cardSlot

    property string heading: ""
    property string subheading: ""
    property color accent: Theme.accentPrimary
    property string contentState: "active"
    default property Item content
    implicitWidth: 220
    implicitHeight: 160

    Rectangle {
        anchors.fill: parent
        radius: Metrics.radiusLg
        color: Theme.panelBg
        border.width: Metrics.strokeHairline
        border.color: Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.65)
    }
}

import QtQuick
import LunaHub
import LunaHub.Controls
import LunaHub.Theme

pragma ComponentBehavior: Bound

Rectangle {
    id: bar
    property string state: "off"   // off | enabling | on | partial | error
    property string profileName: "Balanced"
    property string detailLabel: ""
    signal openDetails()
    signal toggle()
    implicitHeight: 76
    color: Theme.panelBg
    radius: Metrics.radiusLg
    border.width: Metrics.strokeHairline
    border.color: Qt.rgba(borderPick(), 1)

    function borderPick() {
        if (state === "on") return Theme.borderActive
        if (state === "partial") return Theme.warningColor
        if (state === "error") return Theme.criticalColor
        return Theme.borderDefault
    }
    function ringColor() {
        if (state === "on") return Theme.accentPrimary
        if (state === "partial") return Theme.warningColor
        if (state === "error") return Theme.criticalColor
        return Theme.borderHover
    }
    function stateLabel() {
        if (state === "on") return "On"
        if (state === "partial") return "Partial"
        if (state === "error") return "Error"
        if (state === "enabling") return "Enabling"
        return "Off"
    }
    function stateTone() {
        if (state === "on") return LunaStatusBadge.Tone.Info
        if (state === "partial") return LunaStatusBadge.Tone.Warning
        if (state === "error") return LunaStatusBadge.Tone.Critical
        if (state === "enabling") return LunaStatusBadge.Tone.Accent
        return LunaStatusBadge.Tone.Neutral
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -1
        radius: Metrics.radiusLg + 1
        color: "transparent"
        border.color: bar.ringColor()
        border.width: Metrics.strokeThin
        opacity: bar.state === "on" ? Theme.glowMedium : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Metrics.durIndicator } }
    }

    Row {
        anchors.fill: parent
        anchors.leftMargin: Metrics.xs20
        anchors.rightMargin: Metrics.xs16
        spacing: Metrics.xs20

        Item {
            width: 36
            height: 36
            anchors.verticalCenter: parent.verticalCenter
            Rectangle {
                anchors.fill: parent
                radius: Metrics.radiusMd
                color: Qt.rgba(bar.ringColor().r, bar.ringColor().g, bar.ringColor().b, 0.2)
                border.width: Metrics.strokeHairline
                border.color: Qt.rgba(bar.ringColor().r, bar.ringColor().g, bar.ringColor().b, 0.55)
            }
            Label {
                anchors.centerIn: parent
                text: "⚡"
                color: bar.ringColor()
                font.pixelSize: Metrics.iconXl
                font.family: Typography.family
            }
        }

        Column {
            width: bar.width - 36 - 230
            spacing: 2
            anchors.verticalCenter: parent.verticalCenter
            Label {
                text: "Luna Boost"
                color: Theme.textPrimary
                font.family: Typography.family
                font.pixelSize: Typography.pageHeading.size
                font.weight: Typography.pageHeading.weight
            }
            Label {
                text: bar.profileName.length > 0
                      ? "Profile: " + bar.profileName + (bar.detailLabel.length > 0 ? "  ·  " + bar.detailLabel : "")
                      : "System idle"
                color: Theme.textSecondary
                font.family: Typography.family
                font.pixelSize: Typography.bodyLabel.size
                elide: Text.ElideRight
                width: parent.width
            }
        }

        LunaStatusBadge {
            anchors.verticalCenter: parent.verticalCenter
            text: bar.stateLabel()
            tone: bar.stateTone()
            dot: true
        }

        LunaButton {
            anchors.verticalCenter: parent.verticalCenter
            text: bar.state === "on" ? "Stop" : "Start"
            sizeMode: LunaButton.Size.Small
            variant: bar.state === "on" ? LunaButton.Variant.Subtle : LunaButton.Variant.Primary
            onClicked: bar.toggle()
        }
        LunaButton {
            anchors.verticalCenter: parent.verticalCenter
            text: "Details"
            sizeMode: LunaButton.Size.Small
            variant: LunaButton.Variant.Ghost
            onClicked: bar.openDetails()
        }
    }
}

import QtQuick
import LunaHub
import LunaHub.Controls
import LunaHub.Theme

pragma ComponentBehavior: Bound

Item {
    id: page
    property string routeName: "rgb"

    property var devices: [
        { "name": "Keyboard",  "model": "Corsair K70",     "zones": ["per-key"],        "selected": true,  "tone": Theme.accentSecondary },
        { "name": "Mouse",     "model": "Razer DeathAdder", "zones": ["logo", "scroll"], "selected": false, "tone": Theme.successColor },
        { "name": "Headset",   "model": "Audeze Maxwell",  "zones": ["cups"],           "selected": false, "tone": Theme.cpuAccent },
        { "name": "Strip",     "model": "Argb 60cm",       "zones": ["strip"],          "selected": true,  "tone": Theme.warningColor }
    ]

    property string effect: "Static"
    property int brightness: 80

    property var effects: [
        { "label": "Static",   "tone": Theme.accentPrimary },
        { "label": "Breathing","tone": Theme.successColor },
        { "label": "Spectrum", "tone": Theme.accentSecondary },
        { "label": "Reactive", "tone": Theme.cpuAccent },
        { "label": "Wave",     "tone": Theme.ramAccent },
        { "label": "Off",      "tone": Theme.warningColor }
    ]

    Column {
        anchors.fill: parent
        anchors.margins: Metrics.xs24
        spacing: Metrics.xs16

        Row {
            width: parent.width
            spacing: Metrics.xs16
            Rectangle {
                width: parent.width * 0.55 - parent.spacing
                height: 220
                color: Theme.panelBg
                radius: Metrics.radiusLg
                border.width: Metrics.strokeHairline
                border.color: Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.65)
                Column {
                    anchors.fill: parent
                    anchors.margins: Metrics.xs20
                    spacing: Metrics.xs12
                    Label {
                        text: "Devices"
                        color: Theme.textPrimary
                        font.family: Typography.family
                        font.pixelSize: Typography.pageHeading.size
                        font.weight: Typography.pageHeading.weight
                    }
                    ListView {
                        width: parent.width
                        height: parent.height - 40
                        model: page.devices
                        clip: true
                        spacing: Metrics.xs4
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                        delegate: Rectangle {
                            width: parent ? parent.width : 0
                            height: 56
                            radius: Metrics.radiusMd
                            color: modelData.selected
                                   ? Qt.rgba(modelData.tone.r, modelData.tone.g, modelData.tone.b, 0.2)
                                   : Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.35)
                            border.width: modelData.selected ? Metrics.strokeThin : Metrics.strokeHairline
                            border.color: modelData.selected
                                   ? Qt.rgba(modelData.tone.r, modelData.tone.g, modelData.tone.b, 0.55)
                                   : Qt.rgba(Theme.borderDefault.r, modelData.tone.b, modelData.tone.b, 0.5)
                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: -1
                                radius: Metrics.radiusMd + 1
                                color: "transparent"
                                border.color: modelData.tone
                                border.width: Metrics.strokeThin
                                opacity: modelData.selected ? Theme.glowSoft : 0
                                visible: opacity > 0
                            }
                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: Metrics.xs12
                                anchors.rightMargin: Metrics.xs12
                                spacing: Metrics.xs12
                                Item {
                                    width: 36; height: 36
                                    anchors.verticalCenter: parent.verticalCenter
                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 4
                                        color: Qt.rgba(modelData.tone.r, modelData.tone.g, modelData.tone.b, 0.18)
                                        border.width: Metrics.strokeHairline
                                        border.color: Qt.rgba(modelData.tone.r, modelData.tone.g, modelData.tone.b, 0.5)
                                    }
                                    Label {
                                        anchors.centerIn: parent
                                        text: "❖"
                                        color: modelData.tone
                                        font.pixelSize: Metrics.iconMd
                                        font.family: Typography.family
                                    }
                                }
                                Column {
                                    spacing: 2
                                    anchors.verticalCenter: parent.verticalCenter
                                    Label {
                                        text: modelData.name + " — " + modelData.model
                                        color: Theme.textPrimary
                                        font.family: Typography.family
                                        font.pixelSize: Typography.bodyLabel.size
                                        font.weight: Font.Medium
                                    }
                                    Label {
                                        text: "Zones: " + (modelData.zones.join(", "))
                                        color: Theme.textMuted
                                        font.family: Typography.family
                                        font.pixelSize: Typography.caption.size
                                    }
                                }
                                Item { width: parent.width - 220 }
                                LunaToggle { anchors.verticalCenter: parent.verticalCenter; checked: modelData.selected; accentOverride: modelData.tone }
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width * 0.45 - parent.spacing
                height: 220
                color: Theme.panelBg
                radius: Metrics.radiusLg
                border.width: Metrics.strokeHairline
                border.color: Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.65)
                Column {
                    anchors.fill: parent
                    anchors.margins: Metrics.xs20
                    spacing: Metrics.xs12
                    Label {
                        text: "Brightness"
                        color: Theme.textPrimary
                        font.family: Typography.family
                        font.pixelSize: Typography.pageHeading.size
                        font.weight: Typography.pageHeading.weight
                    }
                    Label {
                        text: page.brightness + "%"
                        color: Theme.accentPrimary
                        font.family: Typography.family
                        font.pixelSize: Typography.displayMetric.size
                        font.weight: Typography.displayMetric.weight
                        font.features: { "tnum": true }
                    }
                    LunaProgressBar {
                        width: parent.width
                        height: 6
                        value: page.brightness
                        max: 100
                        fillColor: Theme.accentPrimary
                    }
                    Row {
                        spacing: Metrics.xs12
                        LunaButton { text: "Sync"; sizeMode: LunaButton.Size.Small; variant: LunaButton.Variant.Primary }
                        LunaButton { text: "Turn Off"; sizeMode: LunaButton.Size.Small; variant: LunaButton.Variant.Danger }
                    }
                }
            }
        }

        Rectangle {
            color: Theme.panelBg
            radius: Metrics.radiusLg
            border.width: Metrics.strokeHairline
            border.color: Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.65)
            width: parent.width
            height: 200
            Column {
                anchors.fill: parent
                anchors.margins: Metrics.xs20
                spacing: Metrics.xs12
                Label {
                    text: "Effects"
                    color: Theme.textPrimary
                    font.family: Typography.family
                    font.pixelSize: Typography.pageHeading.size
                    font.weight: Typography.pageHeading.weight
                }

                Flow {
                    width: parent.width
                    height: 100
                    spacing: Metrics.xs8
                    Repeater {
                        model: page.effects
                        delegate: Rectangle {
                            width: 110
                            height: 38
                            radius: Metrics.radiusMd
                            color: page.effect === modelData.label
                                   ? Qt.rgba(modelData.tone.r, modelData.tone.g, modelData.tone.b, 0.24)
                                   : Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.45)
                            border.width: Metrics.strokeHairline
                            border.color: page.effect === modelData.label
                                   ? Qt.rgba(modelData.tone.r, modelData.tone.g, modelData.tone.b, 0.55)
                                   : Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.55)
                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: -1
                                radius: Metrics.radiusMd + 1
                                color: "transparent"
                                border.color: modelData.tone
                                border.width: Metrics.strokeThin
                                opacity: page.effect === modelData.label ? Theme.glowSoft : 0
                                visible: opacity > 0
                            }
                            Label {
                                anchors.centerIn: parent
                                text: modelData.label
                                color: page.effect === modelData.label ? Theme.textPrimary : Theme.textSecondary
                                font.family: Typography.family
                                font.pixelSize: Typography.buttonLabel.size
                                font.weight: Font.Medium
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: page.effect = modelData.label
                            }
                        }
                    }
                }
            }
        }
    }

    property var metric: Metrics
}

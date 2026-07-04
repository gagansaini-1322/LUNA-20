import QtQuick
import QtQuick.Layouts
import LunaHub
import LunaHub.Controls
import LunaHub.Theme

pragma ComponentBehavior: Bound

LunaDialog {
    id: dlg

    width: Math.min(640, Overlay.overlay.width - 64)

    property var library: [
        { "title": "Helldivers 2",         "source": "Steam" },
        { "title": "Counter-Strike 2",    "source": "Steam" },
        { "title": "Baldur's Gate 3",     "source": "GOG" },
        { "title": "Cyberpunk 2077",      "source": "GOG" },
        { "title": "Diablo IV",           "source": "Battle.net" },
        { "title": "Fortnite",            "source": "Epic" },
        { "title": "Hades II",            "source": "Steam" },
        { "title": "Elden Ring",          "source": "Steam" },
        { "title": "Luna Native Demo",    "source": "Luna" }
    ]

    property string search: ""
    property string sourceFilter: "All"
    property var sources: ["All", "Steam", "GOG", "Battle.net", "Epic", "Luna"]
    property var picked: []

    title: "Add Game"
    subtitle: "Select titles to include in the Performance Queue."
    confirmLabel: "Add"
    cancelLabel: "Cancel"

    body: Item {
        ColumnLayout {
            anchors.fill: parent
            spacing: Metrics.xs12

            RowLayout {
                Layout.fillWidth: true
                spacing: Metrics.xs12
                LunaSearchField {
                    Layout.fillWidth: true
                    placeholder: "Search"
                    text: dlg.search
                    onAccepted: {}
                }
                LunaDropdown {
                    Layout.preferredWidth: 140
                    modelArray: dlg.sources.map(function(s) { return { label: s, value: s } })
                    currentIndex: dlg.sources.indexOf(dlg.sourceFilter)
                    onValueSelected: (val, idx) => dlg.sourceFilter = val
                    displayRole: "label"
                    valueRole: "value"
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Theme.bgPrimary
                radius: Metrics.radiusMd
                border.width: Metrics.strokeHairline
                border.color: Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.55)

                ListView {
                    anchors.fill: parent
                    anchors.margins: Metrics.xs8
                    clip: true
                    spacing: Metrics.xs4
                    model: filtered()
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                    delegate: Rectangle {
                        width: parent ? parent.width : 0
                        height: 44
                        radius: Metrics.radiusSm
                        color: dlg.picked.indexOf(modelData.title) >= 0
                               ? Qt.rgba(Theme.accentPrimary.r, Theme.accentPrimary.g, Theme.accentPrimary.b, 0.18)
                               : Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.35)
                        border.width: Metrics.strokeHairline
                        border.color: dlg.picked.indexOf(modelData.title) >= 0
                               ? Qt.rgba(Theme.accentPrimary.r, Theme.accentPrimary.g, Theme.accentPrimary.b, 0.55)
                               : Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.55)

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: Metrics.xs12
                            anchors.rightMargin: Metrics.xs12
                            spacing: Metrics.xs8
                            Label {
                                width: 26
                                anchors.verticalCenter: parent.verticalCenter
                                text: dlg.picked.indexOf(modelData.title) >= 0 ? "✓" : ""
                                color: Theme.accentPrimary
                                font.pixelSize: Metrics.iconMd
                                font.family: Typography.family
                            }
                            Label {
                                width: parent.width - 200
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.title
                                color: Theme.textPrimary
                                font.family: Typography.family
                                font.pixelSize: Typography.bodyLabel.size
                                font.weight: Font.Medium
                                elide: Text.ElideRight
                            }
                            LunaStatusBadge {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.source
                                tone: LunaStatusBadge.Tone.Neutral
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                var idx = dlg.picked.indexOf(modelData.title)
                                if (idx >= 0) dlg.picked.splice(idx, 1)
                                else dlg.picked.push(modelData.title)
                                dlg.pickedChanged()
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Metrics.xs8
                LunaStatusBadge {
                    text: dlg.picked.length + " selected"
                    tone: dlg.picked.length > 0 ? LunaStatusBadge.Tone.Info : LunaStatusBadge.Tone.Neutral
                }
                Item { Layout.fillWidth: true }
                LunaButton {
                    text: "Clear"
                    visible: dlg.picked.length > 0
                    variant: LunaButton.Variant.Ghost
                    sizeMode: LunaButton.Size.Small
                    onClicked: { dlg.picked = []; dlg.pickedChanged() }
                }
            }
        }
    }

    function filtered() {
        var s = dlg.search.toLowerCase()
        return dlg.library.filter(function(g) {
            var matchSearch = s.length === 0 || g.title.toLowerCase().indexOf(s) >= 0
            var matchSource = dlg.sourceFilter === "All" || g.source === dlg.sourceFilter
            return matchSearch && matchSource
        })
    }
}

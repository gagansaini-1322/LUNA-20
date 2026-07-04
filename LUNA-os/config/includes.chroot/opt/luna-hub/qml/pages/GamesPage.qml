import QtQuick
import LunaHub
import LunaHub.Controls
import LunaHub.Theme

pragma ComponentBehavior: Bound

Item {
    id: page
    property string routeName: "games"

    property string searchText: ""
    property string sourceFilter: "All"
    property var sources: ["All", "Steam", "Battle.net", "Epic", "GOG", "Luna"]

    property var library: [
        { "title": "Helldivers 2",          "source": "Steam",     "size": "62 GB",  "installed": true,  "running": true,  "profile": "FPS Priority" },
        { "title": "Counter-Strike 2",     "source": "Steam",     "size": "32 GB",  "installed": true,  "running": false, "profile": "Competitive" },
        { "title": "Hades II",             "source": "Steam",     "size": "5.4 GB", "installed": true,  "running": false, "profile": null },
        { "title": "Baldur's Gate 3",      "source": "GOG",       "size": "122 GB", "installed": true,  "running": false, "profile": "Story" },
        { "title": "Diablo IV",            "source": "Battle.net","size": "75 GB",  "installed": true,  "running": false, "profile": null },
        { "title": "Fortnite",             "source": "Epic",      "size": "32 GB",  "installed": true,  "running": false, "profile": null },
        { "title": "Cyberpunk 2077",       "source": "GOG",       "size": "70 GB",  "installed": true,  "running": false, "profile": "Cinematic" },
        { "title": "Elden Ring",           "source": "Steam",     "size": "50 GB",  "installed": true,  "running": false, "profile": null },
        { "title": "No Man's Sky",         "source": "Steam",     "size": "20 GB",  "installed": true,  "running": false, "profile": null },
        { "title": "The Finals",           "source": "Steam",     "size": "24 GB",  "installed": true,  "running": false, "profile": null },
        { "title": "Warhammer 40K: SM2",   "source": "Steam",     "size": "100 GB", "installed": true,  "running": false, "profile": "Cinematic" },
        { "title": "Luna Native Demo",     "source": "Luna",      "size": "1.2 GB", "installed": true,  "running": false, "profile": null }
    ]

    Column {
        anchors.fill: parent
        anchors.margins: Metrics.xs24
        spacing: Metrics.xs16

        Row {
            width: parent.width
            spacing: Metrics.xs12
            LunaSearchField {
                width: parent.width * 0.6
                placeholder: "Search library"
                text: page.searchText
                onTextChanged: (t) => page.searchText = t
            }
            LunaDropdown {
                Layout.preferredWidth: 160
                modelArray: page.sources.map(function(s, i) { return { label: s, value: s } })
                currentIndex: page.sources.indexOf(page.sourceFilter)
                onValueSelected: (val, idx) => page.sourceFilter = val
                displayRole: "label"
                valueRole: "value"
            }
            Item { width: parent.width * 0.05 }
            LunaButton { text: "Add Game"; sizeMode: LunaButton.Size.Small; variant: LunaButton.Variant.Subtle; iconName: "+"; hasIcon: true }
            LunaButton { text: "Refresh"; sizeMode: LunaButton.Size.Small; variant: LunaButton.Variant.Ghost; iconName: "↻"; hasIcon: true }
            LunaButton { text: "Import Folder"; sizeMode: LunaButton.Size.Small }
        }

        Rectangle {
            color: Theme.panelBg
            radius: Metrics.radiusLg
            border.width: Metrics.strokeHairline
            border.color: Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.65)
            width: parent.width
            height: parent.height - y - Metrics.xs16

            ListView {
                anchors.fill: parent
                anchors.margins: Metrics.xs20
                clip: true
                spacing: Metrics.xs4
                model: filtered()
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                delegate: Rectangle {
                    width: parent ? parent.width : 0
                    height: 60
                    color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.35)
                    radius: Metrics.radiusMd
                    border.width: Metrics.strokeHairline
                    border.color: Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.5)

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: Metrics.xs12
                        anchors.rightMargin: Metrics.xs12
                        spacing: Metrics.xs12
                        Item {
                            width: 40; height: 40
                            anchors.verticalCenter: parent.verticalCenter
                            Rectangle {
                                anchors.fill: parent
                                radius: 6
                                color: Qt.rgba(Theme.accentSecondary.r, Theme.accentSecondary.g, Theme.accentSecondary.b, 0.16)
                                border.width: Metrics.strokeHairline
                                border.color: Qt.rgba(Theme.accentSecondary.r, Theme.accentSecondary.g, Theme.accentSecondary.b, 0.45)
                            }
                            Label {
                                anchors.centerIn: parent
                                text: "▶"
                                color: Theme.accentSecondary
                                font.pixelSize: Metrics.iconMd
                                font.family: Typography.family
                            }
                        }
                        Column {
                            spacing: 2
                            anchors.verticalCenter: parent.verticalCenter
                            Label {
                                text: modelData.title
                                color: Theme.textPrimary
                                font.family: Typography.family
                                font.pixelSize: Typography.bodyLabel.size
                                font.weight: Font.Medium
                            }
                            Label {
                                text: modelData.source + "  ·  " + modelData.size
                                color: Theme.textMuted
                                font.family: Typography.family
                                font.pixelSize: Typography.caption.size
                            }
                        }
                        Item { width: parent.width - 360 }
                        LunaStatusBadge {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.running ? "Running" : "Ready"
                            tone: modelData.running ? LunaStatusBadge.Tone.Success : LunaStatusBadge.Tone.Neutral
                            dot: true
                        }
                        LunaButton {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.profile ? "Profile: " + modelData.profile : "Add Profile"
                            sizeMode: LunaButton.Size.Small
                            variant: modelData.profile ? LunaButton.Variant.Subtle : LunaButton.Variant.Primary
                        }
                    }
                }
            }
        }
    }

    function filtered() {
        var s = page.searchText.toLowerCase()
        return page.library.filter(function(g) {
            var matchSearch = s.length === 0 || g.title.toLowerCase().indexOf(s) >= 0
            var matchSource = page.sourceFilter === "All" || g.source === page.sourceFilter
            return matchSearch && matchSource
        })
    }
}

import QtQuick
import QtQuick.Layouts
import LunaHub
import LunaHub.Theme

pragma ComponentBehavior: Bound

Rectangle {
    id: sidebar

    property var navigationItems: []
    property string currentRoute: ""
    property string logoName: "◐ LUNA"
    property string versionString: "v1.0"
    property string serviceStatus: "Idle"
    signal routeRequested(string route)

    color: Theme.bgSecondary
    border.width: Metrics.strokeHairline
    border.color: Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.6)

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: Metrics.titleBarHeight
            Row {
                anchors.left: parent.left
                anchors.leftMargin: Metrics.xs16
                anchors.verticalCenter: parent.verticalCenter
                spacing: Metrics.xs8
                Rectangle {
                    width: 18
                    height: 18
                    radius: 4
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.accentPrimary
                    Label {
                        anchors.centerIn: parent
                        text: "◐"
                        color: Theme.textPrimary
                        font.pixelSize: Metrics.iconSm
                        font.family: Typography.family
                        font.weight: Font.DemiBold
                    }
                }
                Label {
                    text: "LUNA"
                    color: Theme.textPrimary
                    font.family: Typography.family
                    font.pixelSize: Typography.caption.size
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.4
                    anchors.verticalCenter: parent.verticalCenter
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
            Column {
                anchors.fill: parent
                anchors.topMargin: Metrics.xs16
                anchors.bottomMargin: Metrics.xs16
                spacing: Metrics.xs4

                Repeater {
                    model: sidebar.navigationItems.length
                    delegate: SidebarItem {
                        width: parent.width
                        height: 36
                        label: sidebar.navigationItems[index].label || ""
                        icon: sidebar.navigationItems[index].icon || ""
                        active: sidebar.currentRoute === sidebar.navigationItems[index].route
                        badgeCount: sidebar.navigationItems[index].badgeCount !== undefined
                                    ? sidebar.navigationItems[index].badgeCount : (sidebar.navigationItems[index].badge !== undefined ? sidebar.navigationItems[index].badge : "")
                        onClicked: sidebar.routeRequested(sidebar.navigationItems[index].route)
                    }
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
            Layout.preferredHeight: 64
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Metrics.xs12
                spacing: Metrics.xs4

                RowLayout {
                    spacing: Metrics.xs8
                    Rectangle {
                        width: 22
                        height: 22
                        radius: 4
                        color: Qt.rgba(Theme.accentSecondary.r, Theme.accentSecondary.g, Theme.accentSecondary.b, 0.22)
                        border.width: Metrics.strokeHairline
                        border.color: Qt.rgba(Theme.accentSecondary.r, Theme.accentSecondary.g, Theme.accentSecondary.b, 0.55)
                        Label {
                            anchors.centerIn: parent
                            text: "◐"
                            color: Theme.accentSecondary
                            font.pixelSize: Metrics.iconSm
                            font.family: Typography.family
                            font.weight: Font.DemiBold
                        }
                    }
                    ColumnLayout {
                        spacing: 0
                        Label {
                            text: "Luna Hub"
                            color: Theme.textPrimary
                            font.family: Typography.family
                            font.pixelSize: Typography.bodyLabel.size
                            font.weight: Font.Medium
                        }
                        Label {
                            text: sidebar.versionString
                            color: Theme.textMuted
                            font.family: Typography.family
                            font.pixelSize: Typography.caption.size
                        }
                    }
                }
                RowLayout {
                    spacing: Metrics.xs8
                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        color: {
                            if (sidebar.serviceStatus === "Connected") return Theme.successColor
                            if (sidebar.serviceStatus === "Error") return Theme.criticalColor
                            return Theme.warningColor
                        }
                    }
                    Label {
                        Layout.fillWidth: true
                        text: "Telemetry: " + sidebar.serviceStatus
                        color: Theme.textSecondary
                        font.family: Typography.family
                        font.pixelSize: Typography.caption.size
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}

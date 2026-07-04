import QtQuick
import QtQuick.Layouts
import LunaHub
import LunaHub.Controls
import LunaHub.Theme

pragma ComponentBehavior: Bound

Rectangle {
    id: topbar

    property string pageTitle: ""
    property var actions: []

    color: Theme.bgSecondary
    border.width: Metrics.strokeHairline
    border.color: Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.55)

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: Metrics.strokeHairline
        color: Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.7)
    }

    Item {
        id: titleBar
        anchors.left: parent.left
        anchors.right: windowControls.left
        anchors.top: parent.top
        height: Metrics.titleBarHeight

        DragHandler {
            target: null
            onTranslationChanged: (delta) => {
                if (topbar.parent && topbar.parent.Window && topbar.parent.Window.startSystemMove)
                    topbar.parent.Window.startSystemMove()
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: Metrics.titleBarHeight

            RowLayout {
                anchors.left: parent.left
                anchors.leftMargin: Metrics.xs20
                anchors.verticalCenter: parent.verticalCenter
                spacing: Metrics.xs12

                Label {
                    text: topbar.pageTitle
                    color: Theme.textSecondary
                    font.family: Typography.family
                    font.pixelSize: Typography.caption.size
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.2
                }
            }

            WindowControls {
                id: windowControls
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: Metrics.strokeHairline
            color: Theme.borderDefault
            opacity: 0.7
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Metrics.xs24
                anchors.rightMargin: Metrics.xs24
                anchors.topMargin: Metrics.xs8
                anchors.bottomMargin: Metrics.xs8
                spacing: Metrics.xs12

                Label {
                    text: topbar.pageTitle
                    color: Theme.textPrimary
                    font.family: Typography.family
                    font.pixelSize: Typography.pageHeading.size
                    font.weight: Typography.pageHeading.weight
                }

                Item { Layout.fillWidth: true }

                LunaButton {
                    Layout.preferredHeight: 30
                    text: "Boost"
                    sizeMode: LunaButton.Size.Small
                    variant: LunaButton.Variant.Primary
                }
                LunaButton {
                    Layout.preferredHeight: 30
                    text: "Auto Profile"
                    sizeMode: LunaButton.Size.Small
                    iconName: "✺"
                    hasIcon: true
                }
                LunaSearchField {
                    Layout.preferredHeight: 30
                    placeholder: "Search telemetry"
                }
            }
        }
    }
}

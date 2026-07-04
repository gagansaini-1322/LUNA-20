import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import LunaHub
import LunaHub.Controls
import LunaHub.Pages
import LunaHub.Theme

pragma ComponentBehavior: Bound

LunaDialog {
    id: dlg

    property string reportBody: ""
    property var includeOptions: [
        { "key": "system",       "label": "System metadata",     "checked": true },
        { "key": "telemetry",    "label": "Telemetry summary",   "checked": true },
        { "key": "logs",         "label": "Recent logs",         "checked": false },
        { "key": "stacktrace",   "label": "Crash stack trace",   "checked": false }
    ]

    title: "Diagnostics Report"
    subtitle: "A sanitized preview of what's included in this bundle."
    confirmLabel: "Save"
    cancelLabel: "Cancel"

    body: Item {
        Column {
            anchors.fill: parent
            spacing: Metrics.xs12

            SettingsField {
                width: parent.width
                label: "Included sections"
                field: Item {
                    width: 240
                    height: parent.height
                    Column {
                        anchors.fill: parent
                        spacing: Metrics.xs4
                        Repeater {
                            model: dlg.includeOptions
                            delegate: Item {
                                width: parent.width
                                height: 28
                                RowLayout {
                                    anchors.fill: parent
                                    spacing: Metrics.xs8
                                    Switch { checked: modelData.checked }
                                    Label {
                                        text: modelData.label
                                        color: Theme.textPrimary
                                        font.family: Typography.family
                                        font.pixelSize: Typography.bodyLabel.size
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: parent.height - 80
                color: Theme.bgPrimary
                radius: Metrics.radiusMd
                border.width: Metrics.strokeHairline
                border.color: Qt.rgba(Theme.borderDefault.r, Theme.borderDefault.g, Theme.borderDefault.b, 0.55)

                Flickable {
                    anchors.fill: parent
                    anchors.margins: Metrics.xs16
                    contentWidth: width
                    contentHeight: reportLabel.implicitHeight
                    clip: true
                    Label {
                        id: reportLabel
                        width: parent.width
                        text: dlg.reportBody
                                  || "// Luna Diagnostic\nGenerated: " + Qt.formatDateTime(new Date(), "yyyy-MM-dd hh:mm")
                                  +  "\n\n== System ==\nLunaOS 20.0 · Kernel 6.6\nRTX 4070 SUPER · 18/32 GB\n== Telemetry ==\nSampler: 10Hz · Sensors: 32\n\n// No PII collected."
                        color: Theme.textPrimary
                        font.family: Typography.monoFamily
                        font.pixelSize: Typography.caption.size
                        wrapMode: Text.NoWrap
                    }
                }
            }
        }
    }
}

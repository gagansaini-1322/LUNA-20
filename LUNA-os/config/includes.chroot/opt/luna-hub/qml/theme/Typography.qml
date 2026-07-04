pragma Singleton
import QtQuick

QtObject {
    id: typography

    readonly property string family: "Inter"
    readonly property string familyAlt: "Cantarell"
    readonly property string monoFamily: "JetBrains Mono"

    function pickFamily() {
        return family.length > 0 ? family : familyAlt
    }

    readonly property bool tabularNumeralsDefault: true
    function tabular(value) {
        return value === undefined ? tabularNumeralsDefault : value
    }

    // Role-based scale
    readonly property QtObject displayMetric: QtObject {
        readonly property int size: 28
        readonly property int weight: Font.DemiBold
        readonly property bool tabularNum: true
        readonly property real letterSpacing: -0.2
        readonly property string family: typography.family
    }

    readonly property QtObject pageHeading: QtObject {
        readonly property int size: 16
        readonly property int weight: Font.DemiBold
        readonly property bool tabularNum: false
        readonly property real letterSpacing: 0
        readonly property string family: typography.family
    }

    readonly property QtObject cardHeading: QtObject {
        readonly property int size: 12
        readonly property int weight: Font.Medium
        readonly property bool tabularNum: false
        readonly property real letterSpacing: 0.4
        readonly property string family: typography.family
    }

    readonly property QtObject bodyLabel: QtObject {
        readonly property int size: 12
        readonly property int weight: Font.Normal
        readonly property bool tabularNum: false
        readonly property real letterSpacing: 0
        readonly property string family: typography.family
    }

    readonly property QtObject caption: QtObject {
        readonly property int size: 10
        readonly property int weight: Font.Normal
        readonly property bool tabularNum: false
        readonly property real letterSpacing: 0.3
        readonly property string family: typography.family
    }

    readonly property QtObject buttonLabel: QtObject {
        readonly property int size: 12
        readonly property int weight: Font.Medium
        readonly property bool tabularNum: false
        readonly property real letterSpacing: 0.2
        readonly property string family: typography.family
    }

    readonly property QtObject telemetryValue: QtObject {
        readonly property int size: 20
        readonly property int weight: Font.DemiBold
        readonly property bool tabularNum: true
        readonly property real letterSpacing: -0.1
        readonly property string family: typography.family
    }

    readonly property QtObject smallTelemetry: QtObject {
        readonly property int size: 11
        readonly property int weight: Font.Medium
        readonly property bool tabularNum: true
        readonly property real letterSpacing: 0
        readonly property string family: typography.family
    }

    readonly property QtObject overline: QtObject {
        readonly property int size: 10
        readonly property int weight: Font.DemiBold
        readonly property bool tabularNum: true
        readonly property real letterSpacing: 1.2
        readonly property string family: typography.family
    }
}

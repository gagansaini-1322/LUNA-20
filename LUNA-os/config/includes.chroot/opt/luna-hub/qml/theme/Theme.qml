pragma Singleton
import QtQuick

QtObject {
    id: theme

    // Core surfaces — subtle tonal separation, never pure black
    readonly property color bgPrimary: "#0A0D14"
    readonly property color bgSecondary: "#0F141C"
    readonly property color bgElevated: "#141A26"
    readonly property color panelBg: "#0E141F"
    readonly property color panelBg2: "#1A2030"

    // Borders
    readonly property color borderDefault: "#1F2A38"
    readonly property color borderHover: "#2C3A4E"
    readonly property color borderActive: "#4A6BFF"

    // Text
    readonly property color textPrimary: "#E6EBF2"
    readonly property color textSecondary: "#8AABC2"
    readonly property color textMuted: "#4F6280"

    // Accents
    readonly property color accentPrimary: "#6366F1"
    readonly property color accentSecondary: "#A78BFA"

    // Per-component chart accents
    readonly property color cpuAccent: "#4DD2FF"
    readonly property color ramAccent: "#36C2A8"
    readonly property color gpuAccent: "#FFAA55"
    readonly property color fanAccent: "#80E0FF"

    // Status
    readonly property color successColor: "#36C281"
    readonly property color warningColor: "#FFC857"
    readonly property color criticalColor: "#FF5F57"
    readonly property color disabledColor: "#3A445B"

    // Overlays & popups
    readonly property color overlayBg: "#061018"
    readonly property color tooltipBg: "#141A26"

    // Semantic helpers
    function safeAreaL(side) { return side === "left" ? safeAreaLeft : safeAreaTop }
    readonly property int safeAreaLeft: 0
    readonly property int safeAreaTop: 32
    readonly property int safeAreaRight: 0
    readonly property int safeAreaBottom: 0

    // Surfaces with opacity variants
    readonly property color surface: bgElevated
    readonly property color surfaceMuted: Qt.rgba(borderDefault.r, borderDefault.g, borderDefault.b, 0.35)
    readonly property color surfaceTransparent: Qt.rgba(panelBg2.r, panelBg2.g, panelBg2.b, 0.5)

    // Elevation — soft shadows (QML doesn't get CSS shadows, expose values)
    readonly property int elevation1: 1
    readonly property int elevation2: 2
    readonly property int elevation3: 4

    // Glow alpha ramp (used in Multiplies/rectangles to fake halos)
    readonly property real glowSoft: 0.18
    readonly property real glowMedium: 0.32
    readonly property real glowStrong: 0.55

    function withAlpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }
    function tint(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }

    function mix(c1, c2, t) {
        return Qt.rgba(c1.r * (1 - t) + c2.r * t,
                       c1.g * (1 - t) + c2.g * t,
                       c1.b * (1 - t) + c2.b * t,
                       1.0)
    }
}

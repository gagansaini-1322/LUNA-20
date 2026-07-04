// Luna OS Project
//
// SettingsController implementation. Uses QSettings (INI on Linux by
// default). All setters clamp to legal ranges before notifying.

#include "SettingsController.h"

#include <QVariant>
#include <QVariantMap>

#include <algorithm>
#include <exception>

namespace Luna::Hub {

namespace {

constexpr int kGlowMin = 0;
constexpr int kGlowMax = 100;
constexpr int kGlowDefault = 60;
constexpr int kHistoryMin = 30;
constexpr int kHistoryMax = 7200;
constexpr int kHistoryDefault = 600;
constexpr const char *kDefaultTheme = "midnight";

const QStringList kThemes{
    QStringLiteral("midnight"),
    QStringLiteral("aurora"),
    QStringLiteral("sage"),
    QStringLiteral("ember"),
    QStringLiteral("cobalt"),
};

} // namespace

SettingsController::SettingsController(QObject *parent)
    : QObject(parent),
      m_store(QSettings::IniFormat,
              QSettings::UserScope,
              QStringLiteral("LunaOS"),
              QStringLiteral("luna-hub")) {
}

SettingsController::~SettingsController() {
    try {
        m_store.sync();
    } catch (...) {
        // settings flush errors should not propagate from destructor
    }
}

int SettingsController::glowIntensity() const {
    return m_store.value(QStringLiteral("glowIntensity"), kGlowDefault).toInt();
}

void SettingsController::setGlowIntensity(int value) {
    try {
        const int clamped = std::max(kGlowMin, std::min(value, kGlowMax));
        if (clamped == glowIntensity()) {
            return;
        }
        m_store.setValue(QStringLiteral("glowIntensity"), clamped);
        m_store.sync();
        emit glowIntensityChanged();
    } catch (const std::exception &ex) {
        emit errorOccurred(QStringLiteral("setGlowIntensity: ") + QString::fromUtf8(ex.what()));
    } catch (...) {
        emit errorOccurred(QStringLiteral("setGlowIntensity: unknown failure"));
    }
}

bool SettingsController::reducedMotion() const {
    return m_store.value(QStringLiteral("reducedMotion"), false).toBool();
}

void SettingsController::setReducedMotion(bool value) {
    try {
        if (value == reducedMotion()) {
            return;
        }
        m_store.setValue(QStringLiteral("reducedMotion"), value);
        m_store.sync();
        emit reducedMotionChanged();
    } catch (const std::exception &ex) {
        emit errorOccurred(QStringLiteral("setReducedMotion: ") + QString::fromUtf8(ex.what()));
    } catch (...) {
        emit errorOccurred(QStringLiteral("setReducedMotion: unknown failure"));
    }
}

QString SettingsController::theme() const {
    return m_store.value(QStringLiteral("theme"), QString::fromLatin1(kDefaultTheme)).toString();
}

void SettingsController::setTheme(const QString &value) {
    try {
        if (value.isEmpty() || !kThemes.contains(value)) {
            emit errorOccurred(QStringLiteral("setTheme: unknown theme ") + value);
            return;
        }
        if (value == theme()) {
            return;
        }
        m_store.setValue(QStringLiteral("theme"), value);
        m_store.sync();
        emit themeChanged();
    } catch (...) {
        emit errorOccurred(QStringLiteral("setTheme: unknown failure"));
    }
}

int SettingsController::historyLength() const {
    return m_store.value(QStringLiteral("historyLength"), kHistoryDefault).toInt();
}

void SettingsController::setHistoryLength(int value) {
    try {
        const int clamped = std::max(kHistoryMin, std::min(value, kHistoryMax));
        if (clamped == historyLength()) {
            return;
        }
        m_store.setValue(QStringLiteral("historyLength"), clamped);
        m_store.sync();
        emit historyLengthChanged();
    } catch (...) {
        emit errorOccurred(QStringLiteral("setHistoryLength: unknown failure"));
    }
}

QStringList SettingsController::availableThemes() const {
    return kThemes;
}

void SettingsController::flush() {
    try {
        m_store.sync();
    } catch (const std::exception &ex) {
        emit errorOccurred(QStringLiteral("flush: ") + QString::fromUtf8(ex.what()));
    } catch (...) {
        emit errorOccurred(QStringLiteral("flush: unknown failure"));
    }
}

void SettingsController::resetDefaults() {
    try {
        m_store.remove(QStringLiteral("reducedMotion"));
        m_store.remove(QStringLiteral("glowIntensity"));
        m_store.remove(QStringLiteral("theme"));
        m_store.remove(QStringLiteral("historyLength"));
        m_store.sync();
        emit reducedMotionChanged();
        emit glowIntensityChanged();
        emit themeChanged();
        emit historyLengthChanged();
    } catch (const std::exception &ex) {
        emit errorOccurred(QStringLiteral("resetDefaults: ") + QString::fromUtf8(ex.what()));
    } catch (...) {
        emit errorOccurred(QStringLiteral("resetDefaults: unknown failure"));
    }
}

QVariantMap SettingsController::asVariantMap() const {
    QVariantMap m;
    m.insert(QStringLiteral("reducedMotion"), reducedMotion());
    m.insert(QStringLiteral("glowIntensity"), glowIntensity());
    m.insert(QStringLiteral("theme"), theme());
    m.insert(QStringLiteral("historyLength"), historyLength());
    return m;
}

void SettingsController::loadFromVariantMap(const QVariantMap &values) {
    try {
        bool rm = values.value(QStringLiteral("reducedMotion"), reducedMotion()).toBool();
        int glow = values.value(QStringLiteral("glowIntensity"), glowIntensity()).toInt();
        QString th = values.value(QStringLiteral("theme"), theme()).toString();
        int hist = values.value(QStringLiteral("historyLength"), historyLength()).toInt();

        setReducedMotion(rm);
        setGlowIntensity(glow);
        setTheme(th);
        setHistoryLength(hist);
    } catch (...) {
        emit errorOccurred(QStringLiteral("loadFromVariantMap: unknown failure"));
    }
}

}  // namespace Luna::Hub

// Luna OS Project
//
// Settings persistence via QSettings. Includes reduced motion,
// glow intensity, theme, and history length. Writes are flushed
// synchronously to disk so a power-loss event after a configuration
// change does not lose the user's preference.

#ifndef LUNA_SETTINGS_CONTROLLER_H
#define LUNA_SETTINGS_CONTROLLER_H

#include <QObject>
#include <QSettings>
#include <QString>
#include <QStringList>

namespace Luna::Hub {

class SettingsController : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool reducedMotion READ reducedMotion WRITE setReducedMotion NOTIFY reducedMotionChanged)
    Q_PROPERTY(int glowIntensity READ glowIntensity WRITE setGlowIntensity NOTIFY glowIntensityChanged)
    Q_PROPERTY(QString theme READ theme WRITE setTheme NOTIFY themeChanged)
    Q_PROPERTY(int historyLength READ historyLength WRITE setHistoryLength NOTIFY historyLengthChanged)
    Q_PROPERTY(QStringList availableThemes READ availableThemes CONSTANT)

public:
    explicit SettingsController(QObject *parent = nullptr);
    ~SettingsController() override;

    bool reducedMotion() const;
    void setReducedMotion(bool value);

    int glowIntensity() const;
    void setGlowIntensity(int value);

    QString theme() const;
    void setTheme(const QString &value);

    int historyLength() const;
    void setHistoryLength(int value);

    QStringList availableThemes() const;

    Q_INVOKABLE void flush();
    Q_INVOKABLE void resetDefaults();
    Q_INVOKABLE QVariantMap asVariantMap() const;
    Q_INVOKABLE void loadFromVariantMap(const QVariantMap &values);

Q_SIGNALS:
    void reducedMotionChanged();
    void glowIntensityChanged();
    void themeChanged();
    void historyLengthChanged();
    void errorOccurred(const QString &message);

private:
    QSettings m_store;
};

}  // namespace Luna::Hub

#endif // LUNA_SETTINGS_CONTROLLER_H

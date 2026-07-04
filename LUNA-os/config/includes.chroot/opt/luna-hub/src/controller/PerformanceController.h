// Luna OS Project
//
// Performance profile manager. Wraps `powerprofilesctl` for the
// power-profile daemon (TLP/power-profiles-daemon) and exposes a
// normalized enum to QML. Luna Boost is treated as a derived state
// by the LunaBoostController.

#ifndef LUNA_PERFORMANCE_CONTROLLER_H
#define LUNA_PERFORMANCE_CONTROLLER_H

#include <QObject>
#include <QPointer>
#include <QString>
#include <QStringList>

namespace Luna::Hub {

class IpcClient;

class PerformanceController : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString currentProfile READ currentProfile NOTIFY currentProfileChanged)
    Q_PROPERTY(QStringList availableProfiles READ availableProfiles CONSTANT)
    Q_PROPERTY(bool powerprofilesctlAvailable READ powerprofilesctlAvailable CONSTANT)
    Q_PROPERTY(bool lunaBoostAvailable READ lunaBoostAvailable CONSTANT)
    Q_PROPERTY(QString profileDetailsText READ profileDetailsText NOTIFY profileStateChanged)

public:
    explicit PerformanceController(QObject *parent = nullptr);
    ~PerformanceController() override;

    QString currentProfile() const;
    QStringList availableProfiles() const;
    bool powerprofilesctlAvailable() const { return m_ppctlAvailable; }
    bool lunaBoostAvailable() const { return m_lunaBoostAvailable; }
    QString profileDetailsText() const;

    void attachIpc(IpcClient *ipc);

    Q_INVOKABLE void refresh();
    Q_INVOKABLE QString setProfile(const QString &name);
    Q_INVOKABLE QString powerprofilesctlPath() const;

Q_SIGNALS:
    void currentProfileChanged();
    void profileStateChanged();
    void profileApplicationRequested(const QString &name);
    void errorOccurred(const QString &message);

private:
    QString normalize(const QString &raw) const;
    QString detectPowerprofiles() const;
    bool fileExists(const QString &p) const;
    QString run(const QString &mode);

    QPointer<IpcClient> m_ipc;
    QString m_current = QStringLiteral("balanced");
    bool m_ppctlAvailable = false;
    bool m_lunaBoostAvailable = true;
    QString m_lastDetail;
};

}  // namespace Luna::Hub

#endif // LUNA_PERFORMANCE_CONTROLLER_H

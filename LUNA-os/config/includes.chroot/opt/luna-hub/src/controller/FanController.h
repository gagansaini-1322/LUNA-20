// Luna OS Project
//
// Detects fan-control capability and forwards profile changes to the
// telemetryd daemon. Capability states mirror CapabilityProbe from
// state.rs (MonitorOnly, ControlAvailable, PermissionRequired,
// Unsupported, Error).

#ifndef LUNA_FAN_CONTROLLER_H
#define LUNA_FAN_CONTROLLER_H

#include <QList>
#include <QObject>
#include <QString>
#include <QStringList>
#include <QVariantList>
#include <QVariantMap>

namespace Luna::Hub {

class IpcClient;

class FanController : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString capability READ capability NOTIFY capabilityChanged)
    Q_PROPERTY(QString currentProfile READ currentProfile NOTIFY currentProfileChanged)
    Q_PROPERTY(QStringList availableProfiles READ availableProfiles CONSTANT)
    Q_PROPERTY(QVariantList devices READ devicesVariant NOTIFY capabilityChanged)
    Q_PROPERTY(QString summary READ summary NOTIFY summaryChanged)

public:
    explicit FanController(QObject *parent = nullptr);
    ~FanController() override;

    QString capability() const { return m_capability; }
    QString currentProfile() const { return m_currentProfile; }
    QStringList availableProfiles() const;
    QVariantMap capabilityDetails() const { return m_capabilityDetails; }
    QVariantList devicesVariant() const;
    QString summary() const { return m_summary; }

    void attachIpc(IpcClient *ipc);

    Q_INVOKABLE void refresh();
    Q_INVOKABLE QString setProfile(const QString &name);
    Q_INVOKABLE QVariantMap detectCapability();

    // Tests / QML helpers
    Q_INVOKABLE QVariantList enumerateHwmon() const;
    Q_INVOKABLE bool canProbePwm() const;

Q_SIGNALS:
    void capabilityChanged();
    void currentProfileChanged();
    void summaryChanged();
    void errorOccurred(const QString &message);

private:
    QString runProbe();
    static QString capabilityFromProbes(bool anyFan,
                                        bool anyPwm,
                                        bool anyPwmWritable,
                                        bool anyTemp,
                                        bool hasFancontrolBin);

    QPointer<IpcClient> m_ipc;
    QString m_capability = QStringLiteral("unsupported");
    QString m_currentProfile = QStringLiteral("balanced");
    QString m_summary;
    QVariantMap m_capabilityDetails;
    QList<QVariantMap> m_devices;
};

}  // namespace Luna::Hub

#endif // LUNA_FAN_CONTROLLER_H

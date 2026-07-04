// Luna OS Project
//
// Provides the static system information registers QML wants to
// render on the About page: OS pretty name, kernel release, CPU model,
// logical core count, and GPU list. The values are derived once on
// initialization; explicit Q_INVOKABLE refresh() re-runs detection.

#ifndef LUNA_SYSTEM_INFO_CONTROLLER_H
#define LUNA_SYSTEM_INFO_CONTROLLER_H

#include <QList>
#include <QObject>
#include <QString>
#include <QVariantList>
#include <QVariantMap>

#include "sysinfo/GpuDetector.h"

namespace Luna::Hub {

class SystemInfoController : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString osName READ osName NOTIFY infoChanged)
    Q_PROPERTY(QString osId READ osId NOTIFY infoChanged)
    Q_PROPERTY(QString kernel READ kernel NOTIFY infoChanged)
    Q_PROPERTY(QString hostname READ hostname NOTIFY infoChanged)
    Q_PROPERTY(QString cpuModel READ cpuModel NOTIFY infoChanged)
    Q_PROPERTY(int logicalCores READ logicalCores NOTIFY infoChanged)
    Q_PROPERTY(int physicalCores READ physicalCores NOTIFY infoChanged)
    Q_PROPERTY(qulonglong memoryTotalBytes READ memoryTotalBytes NOTIFY infoChanged)
    Q_PROPERTY(QVariantList gpus READ gpuListVariant NOTIFY infoChanged)
    Q_PROPERTY(bool hasNvidiaSmi READ hasNvidiaSmi NOTIFY infoChanged)
    Q_PROPERTY(bool hasPowerprofilesctl READ hasPowerprofilesctl NOTIFY infoChanged)
    Q_PROPERTY(bool hasGamemode READ hasGamemode NOTIFY infoChanged)
    Q_PROPERTY(bool hasFancontrol READ hasFancontrol NOTIFY infoChanged)
    Q_PROPERTY(bool hasThermald READ hasThermald NOTIFY infoChanged)

public:
    explicit SystemInfoController(QObject *parent = nullptr);
    ~SystemInfoController() override;

    QString osName() const { return m_osName; }
    QString osId() const { return m_osId; }
    QString kernel() const { return m_kernel; }
    QString hostname() const { return m_hostname; }
    QString cpuModel() const { return m_cpuModel; }
    int logicalCores() const { return m_logicalCores; }
    int physicalCores() const { return m_physicalCores; }
    qulonglong memoryTotalBytes() const { return m_memoryTotalBytes; }
    QVariantList gpuListVariant() const;
    bool hasNvidiaSmi() const { return m_hasNvidiaSmi; }
    bool hasPowerprofilesctl() const { return m_hasPowerprofiles; }
    bool hasGamemode() const { return m_hasGamemode; }
    bool hasFancontrol() const { return m_hasFancontrol; }
    bool hasThermald() const { return m_hasThermald; }

    Q_INVOKABLE QVariantMap asVariantMap() const;
    Q_INVOKABLE void refresh();
    Q_INVOKABLE QString cpuFrequencyInfo() const;

Q_SIGNALS:
    void infoChanged();
    void errorOccurred(const QString &message);

private:
    void collectFromSys();

    QString m_osName;
    QString m_osId;
    QString m_kernel;
    QString m_hostname;
    QString m_cpuModel;
    int m_logicalCores = 0;
    int m_physicalCores = 0;
    qulonglong m_memoryTotalBytes = 0;
    QList<GpuDescriptor> m_gpus;
    bool m_hasNvidiaSmi = false;
    bool m_hasPowerprofiles = false;
    bool m_hasGamemode = false;
    bool m_hasFancontrol = false;
    bool m_hasThermald = false;
};

}  // namespace Luna::Hub

#endif // LUNA_SYSTEM_INFO_CONTROLLER_H

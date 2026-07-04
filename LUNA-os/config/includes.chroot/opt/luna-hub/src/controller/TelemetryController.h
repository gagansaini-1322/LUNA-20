// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2024 Luna OS Project
#pragma once

#include <QObject>
#include <QTimer>
#include <QVariantMap>
#include <QString>

namespace Luna::Hub {

class IpcClient;
class MockTelemetryModel;

class TelemetryController : public QObject {
    Q_OBJECT
    Q_PROPERTY(double   cpuPct        READ cpuPct        NOTIFY telemetryChanged)
    Q_PROPERTY(double   ramPct        READ ramPct        NOTIFY telemetryChanged)
    Q_PROPERTY(double   cpuTemp       READ cpuTemp       NOTIFY telemetryChanged)
    Q_PROPERTY(double   fanRpm        READ fanRpm        NOTIFY telemetryChanged)
    Q_PROPERTY(double   ramUsedGb     READ ramUsedGb     NOTIFY telemetryChanged)
    Q_PROPERTY(double   ramTotalGb    READ ramTotalGb    NOTIFY telemetryChanged)
    Q_PROPERTY(QString  gpuName       READ gpuName       NOTIFY telemetryChanged)
    Q_PROPERTY(double   gpuUtil       READ gpuUtil       NOTIFY telemetryChanged)
    Q_PROPERTY(QString  fpsDisplay    READ fpsDisplay    NOTIFY telemetryChanged)
    Q_PROPERTY(QString  profileName   READ profileName   NOTIFY profileChanged)
    Q_PROPERTY(QString  activeGame    READ activeGame    NOTIFY telemetryChanged)
    Q_PROPERTY(QString  serviceStatus READ serviceStatus NOTIFY statusChanged)
    Q_PROPERTY(bool     mock          READ mock          NOTIFY statusChanged)
    Q_PROPERTY(QVariantList fans      READ fans          NOTIFY telemetryChanged)
    Q_PROPERTY(QVariantList temps     READ temps         NOTIFY telemetryChanged)
    Q_PROPERTY(QVariantList sparklineCpu READ sparklineCpu NOTIFY telemetryChanged)
    Q_PROPERTY(QVariantList sparklineRam READ sparklineRam NOTIFY telemetryChanged)
    Q_PROPERTY(QVariantList sparklineGpu READ sparklineGpu NOTIFY telemetryChanged)
    Q_PROPERTY(QVariantList sparklineFps READ sparklineFps NOTIFY telemetryChanged)

public:
    explicit TelemetryController(QObject* parent = nullptr);
    ~TelemetryController() override;

    double   cpuPct()        const { return m_cpuPct; }
    double   ramPct()        const { return m_ramPct; }
    double   cpuTemp()       const { return m_cpuTemp; }
    double   fanRpm()        const { return m_fanRpm; }
    double   ramUsedGb()     const { return m_ramUsedGb; }
    double   ramTotalGb()    const { return m_ramTotalGb; }
    QString  gpuName()       const { return m_gpuName; }
    double   gpuUtil()       const { return m_gpuUtil; }
    QString  fpsDisplay()    const { return m_fpsDisplay; }
    QString  profileName()   const { return m_profileName; }
    QString  activeGame()    const { return m_activeGame; }
    QString  serviceStatus() const { return m_serviceStatus; }
    bool     mock()          const { return m_useMock; }
    QVariantList fans()      const { return m_fans; }
    QVariantList temps()     const { return m_temps; }
    QVariantList sparklineCpu() const { return m_sparklineCpu; }
    QVariantList sparklineRam() const { return m_sparklineRam; }
    QVariantList sparklineGpu() const { return m_sparklineGpu; }
    QVariantList sparklineFps() const { return m_sparklineFps; }

    Q_INVOKABLE void refreshSnapshot();
    Q_INVOKABLE void startMonitoring();
    Q_INVOKABLE void stopMonitoring();
    Q_INVOKABLE void setRange(int seconds);

signals:
    void telemetryChanged();
    void profileChanged();
    void statusChanged();

private slots:
    void onTick();

private:
    void ingestSnapshot(const QVariantMap& snap);
    void pushSparkline(QVariantList& ring, double value, int maxLen);
    void toggleMock();

    QTimer m_timer;
    IpcClient*           m_ipc    = nullptr;
    MockTelemetryModel*  m_mock   = nullptr;
    bool                 m_useMock = true;

    double  m_cpuPct      = 0.0;
    double  m_ramPct      = 0.0;
    double  m_cpuTemp     = 0.0;
    double  m_fanRpm      = 0.0;
    double  m_ramUsedGb   = 0.0;
    double  m_ramTotalGb  = 0.0;
    double  m_gpuUtil     = 0.0;
    QString m_gpuName     = QStringLiteral("N/A");
    QString m_fpsDisplay  = QStringLiteral("--");
    QString m_profileName = QStringLiteral("balanced");
    QString m_activeGame;
    QString m_serviceStatus = QStringLiteral("disconnected");
    QVariantList m_fans;
    QVariantList m_temps;

    QVariantList m_sparklineCpu;
    QVariantList m_sparklineRam;
    QVariantList m_sparklineGpu;
    QVariantList m_sparklineFps;

    int  m_range = 60;
};

}  // namespace Luna::Hub

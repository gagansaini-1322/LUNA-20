// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2024 Luna OS Project
#include "TelemetryController.h"

#include "../bridge/IpcClient.h"
#include "../model/MockTelemetryModel.h"

#include <QDateTime>
#include <QRandomGenerator>
#include <QDebug>
#include <QtMath>

namespace Luna::Hub {

TelemetryController::TelemetryController(QObject* parent)
    : QObject(parent)
    , m_ipc(new IpcClient(this))
    , m_mock(new MockTelemetryModel(this))
{
    connect(&m_timer, &QTimer::timeout, this, &TelemetryController::onTick);
    m_timer.setInterval(1500);
    m_sparklineCpu.reserve(60);
    m_sparklineRam.reserve(60);
    m_sparklineGpu.reserve(60);
    m_sparklineFps.reserve(60);
}

TelemetryController::~TelemetryController() {
    stopMonitoring();
}

void TelemetryController::startMonitoring() {
    if (m_useMock) {
        m_serviceStatus = QStringLiteral("mock");
    }
    m_timer.start();
    refreshSnapshot();
    emit statusChanged();
}

void TelemetryController::stopMonitoring() {
    m_timer.stop();
}

void TelemetryController::refreshSnapshot() {
    onTick();
}

void TelemetryController::setRange(int seconds) {
    if (seconds < 30)  seconds = 30;
    if (seconds > 900) seconds = 900;
    m_range = seconds;
    emit telemetryChanged();
}

void TelemetryController::toggleMock() {
    m_useMock = !m_useMock;
    emit statusChanged();
}

void TelemetryController::onTick() {
    QVariantMap snap;
    bool ok = false;
    if (!m_useMock && m_ipc) {
        snap = m_ipc->getTelemetrySnapshot();
        ok = !snap.isEmpty() && snap.contains("cpu");
        if (!ok) {
            // Revert to mock to avoid blank dashboards.
            m_useMock = true;
            m_serviceStatus = QStringLiteral("disconnected");
            emit statusChanged();
        }
    }
    if (!ok) {
        snap = m_mock->nextSnapshot();
    } else {
        m_serviceStatus = QStringLiteral("connected");
        emit statusChanged();
    }
    if (!snap.isEmpty()) ingestSnapshot(snap);
}

void TelemetryController::ingestSnapshot(const QVariantMap& snap) {
    m_cpuPct    = snap.value("cpu_pct", 0.0).toDouble();
    m_ramPct    = snap.value("ram_pct", 0.0).toDouble();
    m_cpuTemp   = snap.value("cpu_temp", 0.0).toDouble();
    m_fanRpm    = snap.value("fan_rpm", 0.0).toDouble();
    m_ramUsedGb = snap.value("ram_used_gb", 0.0).toDouble();
    m_ramTotalGb = snap.value("ram_total_gb", 0.0).toDouble();
    m_gpuUtil   = snap.value("gpu_util", 0.0).toDouble();
    m_gpuName   = snap.value("gpu_name", QStringLiteral("N/A")).toString();
    m_activeGame = snap.value("active_game").toString();

    const QVariantMap fps = snap.value("fps").toMap();
    if (!fps.isEmpty()) {
        const double v = fps.value("value", 0.0).toDouble();
        if (v > 0.0) {
            m_fpsDisplay = QString::number(qRound(v));
            pushSparkline(m_sparklineFps, v, m_range);
        } else {
            m_fpsDisplay = QStringLiteral("--");
        }
    }

    pushSparkline(m_sparklineCpu, m_cpuPct, m_range);
    pushSparkline(m_sparklineRam, m_ramPct, m_range);
    pushSparkline(m_sparklineGpu, m_gpuUtil, m_range);

    m_fans  = snap.value("fans").toList();
    m_temps = snap.value("temps").toList();
    emit telemetryChanged();
}

void TelemetryController::pushSparkline(QVariantList& ring, double value, int maxLen) {
    ring.append(value);
    while (ring.size() > maxLen) ring.removeFirst();
}

}  // namespace Luna::Hub

// Luna OS Project
//
// Deterministic mock telemetry. Used as the fallback source when the
// Rust telemetryd is not running. The data shape mirrors the JSON the
// real daemon emits (see state.rs TelemetrySnapshot) so consumers do
// not have to branch on the source.

#ifndef LUNA_MOCK_TELEMETRY_MODEL_H
#define LUNA_MOCK_TELEMETRY_MODEL_H

#include <QObject>
#include <QString>
#include <QVariantMap>

namespace Luna::Hub {

class MockTelemetryModel : public QObject {
    Q_OBJECT

public:
    explicit MockTelemetryModel(QObject *parent = nullptr);
    ~MockTelemetryModel() override;

    // Returns the current fake snapshot. Walks a simple deterministic
    // time-evolving formula so values are stable across the same tick.
    Q_INVOKABLE QVariantMap snapshot() const;
    Q_INVOKABLE QVariantMap systemInfo() const;
    Q_INVOKABLE QString sourceName() const;

    // Allows tests / QML to nudge the starting values without poking
    // the private clock.
    void setSeed(quint64 seed);

private:
    quint64 m_seed = 0xC0FFEEu;
    quint64 m_ticks = 0;
};

}  // namespace Luna::Hub

#endif // LUNA_MOCK_TELEMETRY_MODEL_H

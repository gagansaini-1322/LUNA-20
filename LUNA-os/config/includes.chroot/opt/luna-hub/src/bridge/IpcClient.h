// Luna OS Project
//
// Bidirectional JSON-line bridge to the Rust telemetryd daemon over a
// Unix domain socket. When the daemon is not running, the client
// silently falls back to MockTelemetryModel so that the QML side keeps
// receiving valid snapshots.

#ifndef LUNA_IPC_CLIENT_H
#define LUNA_IPC_CLIENT_H

#include <QByteArray>
#include <QLocalSocket>
#include <QObject>
#include <QPointer>
#include <QString>
#include <QVariantMap>

namespace Luna::Hub {

class MockTelemetryModel;
class QTimer;

class IpcClient : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString connectionState READ connectionState NOTIFY connectionStateChanged)
    Q_PROPERTY(bool usingMockFallback READ usingMockFallback NOTIFY usingMockFallbackChanged)
    Q_PROPERTY(QString source READ source NOTIFY sourceChanged)
    Q_PROPERTY(QString socketPath READ socketPath WRITE setSocketPath NOTIFY socketPathChanged)

public:
    explicit IpcClient(QObject *parent = nullptr);
    ~IpcClient() override;

    bool connectToServer();
    void disconnectFromServer();

    Q_INVOKABLE void requestSnapshot();
    Q_INVOKABLE void submitCommand(const QString &method, const QVariantMap &params = QVariantMap());

    QString connectionState() const { return m_connectionState; }
    bool usingMockFallback() const { return m_usingMock; }
    QString source() const;
    QString socketPath() const { return m_socketPath; }
    void setSocketPath(const QString &path);

    QVariantMap currentSnapshot() const { return m_lastSnapshot; }
    MockTelemetryModel *mockModel() const { return m_mock.data(); }

Q_SIGNALS:
    void connectionStateChanged();
    void usingMockFallbackChanged();
    void sourceChanged();
    void socketPathChanged();
    void snapshotReceived(const QVariantMap &snapshot);
    void errorOccurred(const QString &message);

private:
    void onSocketReadyRead();
    void onSocketError(QLocalSocket::LocalSocketError socketError);
    void onSocketStateChanged(QLocalSocket::LocalSocketState socketState);
    void onMockTick();
    void onPingTick();
    void startMockTick();
    void stopMockTick();
    void setConnectionState(const QString &state);
    void armSocketConnect();
    bool processJsonLine(const QByteArray &line);
    void sendLine(const QByteArray &jsonLine);

    QString m_socketPath = QStringLiteral("/var/run/luna-telemetry.sock");
    QLocalSocket *m_socket = nullptr;
    QPointer<MockTelemetryModel> m_mock;
    QTimer *m_mockTimer = nullptr;
    QTimer *m_reconnectTimer = nullptr;
    QTimer *m_pingTimer = nullptr;
    QByteArray m_buffer;
    QVariantMap m_lastSnapshot;
    bool m_socketConnected = false;
    bool m_usingMock = true;
    QString m_connectionState = QStringLiteral("idle");
    int m_consecutiveFailures = 0;
};

}  // namespace Luna::Hub

#endif // LUNA_IPC_CLIENT_H

// Luna OS Project
//
// IpcClient implementation. JSON line protocol:
//   -> { "id": <u64|null>, "method": "...", "params": { ... } } \n
//   <- { "id": ..., "result": {...} } \n                       OR
//      { "id": ..., "error": "..." } \n

#include "IpcClient.h"

#include "model/MockTelemetryModel.h"

#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonParseError>
#include <QJsonValue>
#include <QMetaObject>
#include <QPointer>
#include <QStringBuilder>
#include <QTimer>
#include <QtGlobal>

#include <exception>
#include <utility>

namespace Luna::Hub {

namespace {

constexpr int kPingIntervalMs = 4000;
constexpr int kReconnectBackoffMs = 5000;
constexpr int kMockTickIntervalMs = 1000;
constexpr int kMaxConsecutiveFailuresBeforeBackoff = 3;

QString stateTextFor(QLocalSocket::LocalSocketState state) {
    switch (state) {
        case QLocalSocket::UnconnectedState: return QStringLiteral("disconnected");
        case QLocalSocket::ConnectingState: return QStringLiteral("connecting");
        case QLocalSocket::ConnectedState: return QStringLiteral("connected");
        case QLocalSocket::ClosingState: return QStringLiteral("closing");
        default: return QStringLiteral("idle");
    }
}

} // namespace

IpcClient::IpcClient(QObject *parent)
    : QObject(parent) {
    m_mock = new MockTelemetryModel(this);
    m_mockTimer = new QTimer(this);
    m_mockTimer->setInterval(kMockTickIntervalMs);
    m_mockTimer->setTimerType(Qt::PreciseTimer);
    QObject::connect(m_mockTimer.data(), &QTimer::timeout,
                      this, &IpcClient::onMockTick);

    m_reconnectTimer = new QTimer(this);
    m_reconnectTimer->setSingleShot(true);
    m_reconnectTimer->setInterval(kReconnectBackoffMs);
    QObject::connect(m_reconnectTimer.data(), &QTimer::timeout,
                      this, [this]() {
                          try {
                              armSocketConnect();
                          } catch (const std::exception &ex) {
                              emit errorOccurred(QString::fromUtf8(ex.what()));
                          } catch (...) {
                              emit errorOccurred(QStringLiteral("reconnect failed (unknown)"));
                          }
                      });

    m_pingTimer = new QTimer(this);
    m_pingTimer->setInterval(kPingIntervalMs);
    QObject::connect(m_pingTimer.data(), &QTimer::timeout,
                      this, &IpcClient::onPingTick);

    m_socket = new QLocalSocket(this);
    m_socket->setReadBufferSize(64 * 1024);
    QObject::connect(m_socket, &QLocalSocket::readyRead,
                     this, &IpcClient::onSocketReadyRead);
    QObject::connect(m_socket, &QLocalSocket::errorOccurred,
                     this, &IpcClient::onSocketError);
    QObject::connect(m_socket, &QLocalSocket::stateChanged,
                     this, &IpcClient::onSocketStateChanged);

    setConnectionState(QStringLiteral("idle"));
    startMockTick();
}

IpcClient::~IpcClient() {
    try {
        if (m_socket && m_socket->state() != QLocalSocket::UnconnectedState) {
            m_socket->abort();
        }
        stopMockTick();
    } catch (...) {
        // never propagate to QML
    }
}

QString IpcClient::source() const {
    return m_usingMock ? QStringLiteral("mock") : QStringLiteral("telemetryd");
}

void IpcClient::setSocketPath(const QString &path) {
    if (path == m_socketPath) {
        return;
    }
    m_socketPath = path;
    emit socketPathChanged();
}

void IpcClient::setConnectionState(const QString &state) {
    if (state == m_connectionState) {
        return;
    }
    m_connectionState = state;
    emit connectionStateChanged();
}

bool IpcClient::connectToServer() {
    armSocketConnect();
    return m_socketConnected;
}

void IpcClient::armSocketConnect() {
    try {
        if (m_socket->state() != QLocalSocket::UnconnectedState) {
            m_socket->abort();
        }
        setConnectionState(QStringLiteral("connecting"));
        m_socket->connectToServer(m_socketPath);
    } catch (const std::exception &ex) {
        emit errorOccurred(QString::fromUtf8(ex.what()));
        setConnectionState(QStringLiteral("error"));
        startMockTick();
    } catch (...) {
        emit errorOccurred(QStringLiteral("socket.connect failed (unknown)"));
        setConnectionState(QStringLiteral("error"));
        startMockTick();
    }
}

void IpcClient::disconnectFromServer() {
    try {
        if (m_socket) {
            m_socket->abort();
        }
        m_socketConnected = false;
        setConnectionState(QStringLiteral("disconnected"));
        startMockTick();
    } catch (...) {
        // swallow
    }
}

void IpcClient::requestSnapshot() {
    if (m_socketConnected) {
        QJsonObject req;
        req.insert(QStringLiteral("method"), QStringLiteral("snapshot.get"));
        req.insert(QStringLiteral("id"), QStringLiteral("snap"));
        req.insert(QStringLiteral("params"), QJsonObject());
        sendLine(QJsonDocument(req).toJson(QJsonDocument::Compact));
    } else if (m_mock) {
        QVariantMap snap = m_mock->snapshot();
        m_lastSnapshot = snap;
        emit snapshotReceived(snap);
    }
}

void IpcClient::submitCommand(const QString &method, const QVariantMap &params) {
    QJsonObject req;
    req.insert(QStringLiteral("method"), method);
    req.insert(QStringLiteral("id"), QStringLiteral("cmd"));
    QJsonObject p;
    for (auto it = params.begin(); it != params.end(); ++it) {
        p.insert(it.key(), QJsonValue::fromVariant(it.value()));
    }
    req.insert(QStringLiteral("params"), p);
    if (m_socketConnected) {
        sendLine(QJsonDocument(req).toJson(QJsonDocument::Compact));
    }
    // If we are running on the mock backend, the command is ignored —
    // callers should inspect State.connectionState before relying on it.
}

void IpcClient::sendLine(const QByteArray &jsonLine) {
    try {
        if (!m_socket) {
            return;
        }
        QByteArray out = jsonLine;
        out.append(QLatin1Char('\n'));
        const qint64 written = m_socket->write(out);
        if (written != out.size()) {
            emit errorOccurred(QStringLiteral("incomplete socket write"));
        }
    } catch (const std::exception &ex) {
        emit errorOccurred(QString::fromUtf8(ex.what()));
    } catch (...) {
        emit errorOccurred(QStringLiteral("sendLine unknown failure"));
    }
}

void IpcClient::onSocketReadyRead() {
    try {
        m_buffer.append(m_socket->readAll());
        int newlineIdx = -1;
        while ((newlineIdx = m_buffer.indexOf(QLatin1Char('\n'))) >= 0) {
            QByteArray line = m_buffer.left(newlineIdx);
            m_buffer.remove(0, newlineIdx + 1);
            line = line.trimmed();
            if (line.isEmpty()) {
                continue;
            }
            if (!processJsonLine(line)) {
                // keep going; the parser may recover next line
            }
        }
    } catch (const std::exception &ex) {
        emit errorOccurred(QStringLiteral("read: ") + QString::fromUtf8(ex.what()));
    } catch (...) {
        emit errorOccurred(QStringLiteral("socket read unknown failure"));
    }
}

bool IpcClient::processJsonLine(const QByteArray &line) {
    QJsonParseError err;
    const QJsonDocument doc = QJsonDocument::fromJson(line, &err);
    if (err.error != QJsonParseError::NoError || !doc.isObject()) {
        emit errorOccurred(QStringLiteral("invalid JSON line from daemon"));
        return false;
    }
    const QJsonObject obj = doc.object();
    if (obj.contains(QStringLiteral("result"))) {
        QVariantMap result = obj.value(QStringLiteral("result")).toObject().toVariantMap();
        m_lastSnapshot = result;
        emit snapshotReceived(result);
        return true;
    }
    if (obj.contains(QStringLiteral("error"))) {
        const QString errText = obj.value(QStringLiteral("error")).toString();
        if (!errText.isEmpty()) {
            emit errorOccurred(errText);
        }
        return false;
    }
    if (obj.contains(QStringLiteral("event"))) {
        // unsolicited events use the same payload shape as `result`.
        QVariantMap result = obj.value(QStringLiteral("payload")).toObject().toVariantMap();
        if (!result.isEmpty()) {
            m_lastSnapshot = result;
            emit snapshotReceived(result);
        }
        return true;
    }
    return true;
}

void IpcClient::onSocketError(QLocalSocket::LocalSocketError socketError) {
    (void)socketError;
    try {
        m_socketConnected = false;
        if (m_usingMock) {
            // already in fallback; ignore
            return;
        }
        m_consecutiveFailures++;
        if (m_consecutiveFailures >= kMaxConsecutiveFailuresBeforeBackoff) {
            m_usingMock = true;
            emit usingMockFallbackChanged();
            emit sourceChanged();
            startMockTick();
        }
        setConnectionState(QStringLiteral("error"));
        emit errorOccurred(QStringLiteral("connection lost: ") + m_socket->errorString());
        // schedule retry
        if (!m_reconnectTimer->isActive()) {
            m_reconnectTimer->start();
        }
    } catch (...) {
        emit errorOccurred(QStringLiteral("socket error handler failed"));
    }
}

void IpcClient::onSocketStateChanged(QLocalSocket::LocalSocketState socketState) {
    try {
        const QString text = stateTextFor(socketState);
        setConnectionState(text);
        if (socketState == QLocalSocket::ConnectedState) {
            m_socketConnected = true;
            m_consecutiveFailures = 0;
            if (m_usingMock) {
                m_usingMock = false;
                emit usingMockFallbackChanged();
                emit sourceChanged();
            }
            stopMockTick();
            m_pingTimer->start();
            // initial sync
            requestSnapshot();
        } else if (socketState == QLocalSocket::UnconnectedState) {
            m_socketConnected = false;
            if (!m_usingMock) {
                m_usingMock = true;
                emit usingMockFallbackChanged();
                emit sourceChanged();
            }
            m_pingTimer->stop();
            startMockTick();
        }
    } catch (const std::exception &ex) {
        emit errorOccurred(QString::fromUtf8(ex.what()));
    } catch (...) {
        emit errorOccurred(QStringLiteral("socketState handler failed"));
    }
}

void IpcClient::onPingTick() {
    if (!m_socketConnected) {
        return;
    }
    sendLine(QStringLiteral("{\"method\":\"ping\"}\n").toUtf8());
}

void IpcClient::startMockTick() {
    if (!m_mockTimer->isActive()) {
        m_mockTimer->start();
    }
}

void IpcClient::stopMockTick() {
    if (m_mockTimer->isActive()) {
        m_mockTimer->stop();
    }
}

void IpcClient::onMockTick() {
    if (m_socketConnected) {
        return;
    }
    if (!m_mock) {
        return;
    }
    try {
        QVariantMap snap = m_mock->snapshot();
        m_lastSnapshot = snap;
        emit snapshotReceived(snap);
    } catch (const std::exception &ex) {
        emit errorOccurred(QStringLiteral("mock tick: ") + QString::fromUtf8(ex.what()));
    } catch (...) {
        emit errorOccurred(QStringLiteral("mock tick unknown failure"));
    }
}

}  // namespace Luna::Hub

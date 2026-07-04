// Luna OS Project
//
// NotificationController implementation. Pure data-controller; the QML
// toast layer mirrors this state.

#include "NotificationController.h"

#include <QDateTime>
#include <QUuid>

#include <exception>

namespace Luna::Hub {

namespace {

QString makeId() {
    return QUuid::createUuid().toString(QUuid::WithoutBraces);
}

QString normalizeLevel(const QString &level) {
    const QString lower = level.trimmed().toLower();
    if (lower == QStringLiteral("success")) return QStringLiteral("success");
    if (lower == QStringLiteral("warning")) return QStringLiteral("warning");
    if (lower == QStringLiteral("error") || lower == QStringLiteral("danger") || lower == QStringLiteral("critical")) {
        return QStringLiteral("error");
    }
    return QStringLiteral("info");
}

} // namespace

NotificationController::NotificationController(QObject *parent)
    : QObject(parent) {
}

NotificationController::~NotificationController() = default;

QString NotificationController::show(const QString &level,
                                    const QString &title,
                                    const QString &body) {
    try {
        Entry e;
        e.id = makeId();
        e.level = normalizeLevel(level);
        e.title = title;
        e.body = body;
        e.timestampIso = QDateTime::currentDateTimeUtc().toString(Qt::ISODate);

        m_history.append(e);
        while (m_history.size() > m_maxHistory) {
            m_history.removeFirst();
        }
        ++m_unread;
        emit notificationAdded(e.id, e.level, e.title, e.body, e.timestampIso);
        emit historyChanged();
        emit unreadCountChanged();
        return e.id;
    } catch (const std::exception &ex) {
        emit errorOccurred(QStringLiteral("show: ") + QString::fromUtf8(ex.what()));
    } catch (...) {
        emit errorOccurred(QStringLiteral("show: unknown failure"));
    }
    return {};
}

void NotificationController::dismiss(const QString &id) {
    try {
        const int before = m_history.size();
        for (int i = 0; i < m_history.size(); ++i) {
            if (m_history.at(i).id == id) {
                m_history.removeAt(i);
                if (m_unread > 0) {
                    --m_unread;
                }
                emit notificationDismissed(id);
                emit historyChanged();
                emit unreadCountChanged();
                return;
            }
        }
        (void)before;
    } catch (const std::exception &ex) {
        emit errorOccurred(QStringLiteral("dismiss: ") + QString::fromUtf8(ex.what()));
    } catch (...) {
        emit errorOccurred(QStringLiteral("dismiss: unknown failure"));
    }
}

void NotificationController::clearHistory() {
    try {
        if (m_history.isEmpty()) {
            return;
        }
        m_history.clear();
        m_unread = 0;
        emit historyChanged();
        emit unreadCountChanged();
    } catch (...) {
        emit errorOccurred(QStringLiteral("clearHistory: unknown failure"));
    }
}

QVariantList NotificationController::historyList() const {
    QVariantList list;
    list.reserve(m_history.size());
    for (const Entry &e : m_history) {
        QVariantMap m;
        m.insert(QStringLiteral("id"), e.id);
        m.insert(QStringLiteral("level"), e.level);
        m.insert(QStringLiteral("title"), e.title);
        m.insert(QStringLiteral("body"), e.body);
        m.insert(QStringLiteral("timestampIso"), e.timestampIso);
        list.append(m);
    }
    return list;
}

QVariantList NotificationController::historyVariantList() const {
    return historyList();
}

}  // namespace Luna::Hub

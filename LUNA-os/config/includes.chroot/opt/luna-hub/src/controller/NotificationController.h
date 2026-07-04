// Luna OS Project
//
// Toast notifications from the QML or controller side. The actual
// presentation surface is part of the QML shell; this controller just
// gathers notifications and forwards them via signals so the view can
// render them.

#ifndef LUNA_NOTIFICATION_CONTROLLER_H
#define LUNA_NOTIFICATION_CONTROLLER_H

#include <QList>
#include <QObject>
#include <QString>
#include <QUuid>
#include <QVariantMap>

namespace Luna::Hub {

class NotificationController : public QObject {
    Q_OBJECT
    Q_PROPERTY(int unreadCount READ unreadCount NOTIFY unreadCountChanged)
    Q_PROPERTY(QVariantList history READ historyVariantList NOTIFY historyChanged)

public:
    explicit NotificationController(QObject *parent = nullptr);
    ~NotificationController() override;

    Q_INVOKABLE QString show(const QString &level,
                             const QString &title,
                             const QString &body = QString());
    Q_INVOKABLE void dismiss(const QString &id);
    Q_INVOKABLE void clearHistory();
    Q_INVOKABLE QVariantList historyList() const;

    int unreadCount() const { return m_unread; }
    QVariantList historyVariantList() const;

Q_SIGNALS:
    void notificationAdded(const QString &id,
                           const QString &level,
                           const QString &title,
                           const QString &body,
                           const QString &timestampIso);
    void notificationDismissed(const QString &id);
    void unreadCountChanged();
    void historyChanged();
    void errorOccurred(const QString &message);

private:
    struct Entry {
        QString id;
        QString level;
        QString title;
        QString body;
        QString timestampIso;
    };

    QList<Entry> m_history;
    int m_unread = 0;
    int m_maxHistory = 64;
};

}  // namespace Luna::Hub

#endif // LUNA_NOTIFICATION_CONTROLLER_H

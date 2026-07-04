// Luna OS Project
//
// Page navigation for the Luna Hub shell. Holds a single QString
// representing the active page id and exposes it via Q_PROPERTY so
// the QML StackView can bind to changes.

#ifndef LUNA_NAVIGATION_CONTROLLER_H
#define LUNA_NAVIGATION_CONTROLLER_H

#include <QObject>
#include <QString>
#include <QStringList>

namespace Luna::Hub {

class NavigationController : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString currentPage READ currentPage NOTIFY currentPageChanged)
    Q_PROPERTY(QString previousPage READ previousPage NOTIFY previousPageChanged)
    Q_PROPERTY(QStringList stack READ stack NOTIFY stackChanged)
    Q_PROPERTY(QStringList knownPages READ knownPages CONSTANT)

public:
    explicit NavigationController(QObject *parent = nullptr);
    ~NavigationController() override;

    QString currentPage() const { return m_current; }
    QString previousPage() const;
    QStringList stack() const { return m_stack; }
    QStringList knownPages() const;

    Q_INVOKABLE void navigate(const QString &pageId);
    Q_INVOKABLE void pop();
    Q_INVOKABLE void setHomePage(const QString &pageId);
    Q_INVOKABLE bool canPop() const;

Q_SIGNALS:
    void currentPageChanged();
    void previousPageChanged();
    void stackChanged();
    void errorOccurred(const QString &message);

private:
    QString m_current = QStringLiteral("dashboard");
    QString m_home = QStringLiteral("dashboard");
    QStringList m_stack;
};

}  // namespace Luna::Hub

#endif // LUNA_NAVIGATION_CONTROLLER_H

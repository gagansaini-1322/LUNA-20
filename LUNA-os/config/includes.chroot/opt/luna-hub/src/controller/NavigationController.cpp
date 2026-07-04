// Luna OS Project
//
// NavigationController implementation.

#include "NavigationController.h"

#include <exception>

namespace Luna::Hub {

namespace {

const QStringList kKnownPages{
    QStringLiteral("dashboard"),
    QStringLiteral("games"),
    QStringLiteral("performance"),
    QStringLiteral("fans"),
    QStringLiteral("lunaBoost"),
    QStringLiteral("settings"),
    QStringLiteral("about"),
};

} // namespace

NavigationController::NavigationController(QObject *parent)
    : QObject(parent) {
}

NavigationController::~NavigationController() = default;

QStringList NavigationController::knownPages() const {
    return kKnownPages;
}

QString NavigationController::previousPage() const {
    if (m_stack.size() >= 2) {
        return m_stack.at(m_stack.size() - 2);
    }
    return QString();
}

void NavigationController::setHomePage(const QString &pageId) {
    try {
        if (pageId.isEmpty() || m_home == pageId) {
            return;
        }
        m_home = pageId;
        m_stack.clear();
        m_stack.append(m_home);
        if (m_current != m_home) {
            m_current = m_home;
            emit currentPageChanged();
        }
        emit stackChanged();
        emit previousPageChanged();
    } catch (...) {
        emit errorOccurred(QStringLiteral("setHomePage failed"));
    }
}

void NavigationController::navigate(const QString &pageId) {
    try {
        const QString target = pageId.trimmed();
        if (target.isEmpty()) {
            return;
        }
        if (target == m_current) {
            return;
        }
        if (m_stack.isEmpty() || m_stack.last() != m_current) {
            m_stack.append(m_current);
        }
        m_current = target;
        emit currentPageChanged();
        emit previousPageChanged();
        emit stackChanged();
    } catch (...) {
        emit errorOccurred(QStringLiteral("navigate failed"));
    }
}

void NavigationController::pop() {
    try {
        if (m_stack.isEmpty()) {
            return;
        }
        const QString next = m_stack.takeLast();
        if (next == m_current) {
            if (!m_stack.isEmpty()) {
                m_current = m_stack.last();
            } else {
                m_current = m_home;
            }
        } else {
            m_current = next;
        }
        emit currentPageChanged();
        emit previousPageChanged();
        emit stackChanged();
    } catch (...) {
        emit errorOccurred(QStringLiteral("pop failed"));
    }
}

bool NavigationController::canPop() const {
    return m_stack.size() > 0;
}

}  // namespace Luna::Hub

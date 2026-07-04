// Luna OS Project
//
// Implementation of /proc and /sys readers. Each call opens its own
// file handle and tolerates the kernel reporting a transient exception
// or missing line — the function simply returns a default on failure.

#include "SysInfo.h"

#include <QDir>
#include <QFile>
#include <QIODevice>
#include <QRegularExpression>
#include <QStringBuilder>
#include <QTextStream>

#include <algorithm>

namespace Luna::Hub {

quint64 CpuTimes::totalBusy() const {
    return user + nice + system + iowait + irq + softirq + steal;
}

quint64 CpuTimes::totalAll() const {
    return totalBusy() + idle;
}

namespace {

QString readAllTrimmed(const QString &path) {
    QFile f(path);
    if (!f.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return {};
    }
    return QString::fromUtf8(f.readAll()).trimmed();
}

QString readFirstLine(const QString &path) {
    QFile f(path);
    if (!f.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return {};
    }
    QTextStream in(&f);
    return in.readLine();
}

bool readLong(const QString &path, qint64 &out) {
    out = 0;
    QFile f(path);
    if (!f.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return false;
    }
    const QByteArray data = f.readAll().trimmed();
    bool ok = false;
    out = data.toLongLong(&ok);
    return ok;
}

QString stripQuotes(QString in) {
    if (in.size() >= 2 && in.startsWith(QLatin1Char('"')) && in.endsWith(QLatin1Char('"'))) {
        return in.mid(1, in.size() - 2);
    }
    return in;
}

} // namespace

QString SysInfo::readCpuModel() {
    QFile f(QStringLiteral("/proc/cpuinfo"));
    if (!f.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return QStringLiteral("Unknown CPU");
    }
    QTextStream in(&f);
    QRegularExpression modelName(QStringLiteral("model name\\s*:\\s*(.*)$"));
    QRegularExpression hardware(QStringLiteral("Hardware\\s*:\\s*(.*)$"));
    QRegularExpression model(QStringLiteral("Model\\s*:\\s*(.*)$"));
    QRegularExpression processor(QStringLiteral("Processor\\s*:\\s*(.*)$"));

    while (!in.atEnd()) {
        const QString line = in.readLine();
        QRegularExpressionMatch m = modelName.match(line);
        if (m.hasMatch() && m.captured(1).trimmed() != QStringLiteral("")) {
            return m.captured(1).trimmed();
        }
        m = hardware.match(line);
        if (m.hasMatch()) {
            return m.captured(1).trimmed();
        }
        m = model.match(line);
        if (m.hasMatch()) {
            return m.captured(1).trimmed();
        }
        m = processor.match(line);
        if (m.hasMatch()) {
            return m.captured(1).trimmed();
        }
    }
    return QStringLiteral("Unknown CPU");
}

int SysInfo::readLogicalCoreCount() {
    QFile f(QStringLiteral("/proc/cpuinfo"));
    if (!f.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return 0;
    }
    QTextStream in(&f);
    int count = 0;
    while (!in.atEnd()) {
        const QString line = in.readLine();
        if (line.startsWith(QStringLiteral("processor"))) {
            ++count;
        }
    }
    return count;
}

QList<int> SysInfo::readOnlineCores() {
    QList<int> result;
    QDir root(QStringLiteral("/sys/devices/system/cpu"));
    if (!root.exists()) {
        return result;
    }
    const QStringList entries = root.entryList({QStringLiteral("cpu[0-9]*")}, QDir::Dirs);
    for (const QString &entry : entries) {
        if (!entry.startsWith(QStringLiteral("cpu"))) {
            continue;
        }
        bool ok = false;
        const int num = QStringView(entry).mid(3).toInt(&ok);
        if (!ok) {
            continue;
        }
        const QString onlinePath = root.absoluteFilePath(entry) + QStringLiteral("/online");
        QFile online(onlinePath);
        if (online.open(QIODevice::ReadOnly | QIODevice::Text)) {
            if (QString::fromUtf8(online.readAll()).trimmed() == QLatin1String("1")) {
                result.append(num);
            }
        } else {
            // cpu0 has no /online — assume it is up whenever its directory exists.
            result.append(num);
        }
    }
    std::sort(result.begin(), result.end());
    return result;
}

CpuTimes SysInfo::readCpuTimesAggregated() {
    CpuTimes out;
    QFile f(QStringLiteral("/proc/stat"));
    if (!f.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return out;
    }
    QTextStream in(&f);
    static const QRegularExpression lineRe(QStringLiteral("^cpu\\s+([0-9]+)\\s+([0-9]+)\\s+([0-9]+)\\s+([0-9]+)"
                                                          "\\s+([0-9]+)\\s+([0-9]+)\\s+([0-9]+)\\s+([0-9]+)"));
    while (!in.atEnd()) {
        const QString line = in.readLine();
        QRegularExpressionMatch m = lineRe.match(line);
        if (m.hasMatch()) {
            out.user = m.captured(1).toULongLong();
            out.nice = m.captured(2).toULongLong();
            out.system = m.captured(3).toULongLong();
            out.idle = m.captured(4).toULongLong();
            out.iowait = m.captured(5).toULongLong();
            out.irq = m.captured(6).toULongLong();
            out.softirq = m.captured(7).toULongLong();
            out.steal = m.captured(8).toULongLong();
            return out;
        }
    }
    return out;
}

MemInfo SysInfo::readMemInfo() {
    MemInfo info;
    QFile f(QStringLiteral("/proc/meminfo"));
    if (!f.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return info;
    }
    QTextStream in(&f);
    while (!in.atEnd()) {
        const QString line = in.readLine();
        const int colon = line.indexOf(QLatin1Char(':'));
        if (colon < 0) {
            continue;
        }
        const QString key = line.left(colon);
        QString valueStr = line.mid(colon + 1).trimmed();
        if (valueStr.endsWith(QLatin1String("kB"), Qt::CaseInsensitive)) {
            valueStr.chop(2);
            valueStr = valueStr.trimmed();
        }
        bool ok = false;
        quint64 value = valueStr.toULongLong(&ok);
        if (!ok) {
            continue;
        }
        if (key == QStringLiteral("MemTotal")) {
            info.totalKb = value;
        } else if (key == QStringLiteral("MemAvailable")) {
            info.availableKb = value;
        } else if (key == QStringLiteral("MemFree")) {
            info.freeKb = value;
        } else if (key == QStringLiteral("Buffers")) {
            info.buffersKb = value;
        } else if (key == QStringLiteral("Cached")) {
            info.cachedKb = value;
        } else if (key == QStringLiteral("Shmem")) {
            info.sharedKb = value;
        } else if (key == QStringLiteral("SwapTotal")) {
            info.swapTotalKb = value;
        } else if (key == QStringLiteral("SwapFree")) {
            info.swapFreeKb = value;
        }
    }
    return info;
}

QString SysInfo::readUptime() {
    return readFirstLine(QStringLiteral("/proc/uptime"));
}

QStringList SysInfo::readLoadAvg() {
    return readFirstLine(QStringLiteral("/proc/loadavg"))
            .split(QRegularExpression(QStringLiteral("\\s+")), Qt::SkipEmptyParts);
}

double SysInfo::readCpuFrequencyMhz(int cpuIndex) {
    const QString path = QStringLiteral("/sys/devices/system/cpu/cpu%1/cpufreq/scaling_cur_freq").arg(cpuIndex);
    qint64 v = 0;
    if (!readLong(path, v)) {
        // Some kernels omit cpufreq when turbo is the only mode. Try cpuinfo_cur_freq asFallback.
        const QString alt = QStringLiteral("/sys/devices/system/cpu/cpu%1/cpufreq/cpuinfo_cur_freq").arg(cpuIndex);
        if (!readLong(alt, v)) {
            return 0.0;
        }
    }
    return static_cast<double>(v) / 1000.0;
}

QList<HwmonEntry> SysInfo::enumerateHwmon() {
    QList<HwmonEntry> entries;
    QDir root(QStringLiteral("/sys/class/hwmon"));
    if (!root.exists()) {
        return entries;
    }
    const QStringList dirs = root.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
    for (const QString &dir : dirs) {
        const QString abs = root.absoluteFilePath(dir);
        HwmonEntry entry;
        entry.path = abs;
        entry.name = readAllTrimmed(abs + QStringLiteral("/name"));

        const QStringList files = QDir(abs).entryList(QDir::Files);
        for (const QString &file : files) {
            if (file.startsWith(QStringLiteral("fan")) && file.endsWith(QStringLiteral("_input"))) {
                entry.fanInputs.append(file);
            } else if (file.startsWith(QStringLiteral("temp")) && file.endsWith(QStringLiteral("_input"))) {
                entry.tempInputs.append(file);
            } else if (file.startsWith(QStringLiteral("pwm")) && file.endsWith(QStringLiteral("_mode"))) {
                // mode files like pwm1_mode describe a control's curve; not used as pwm enable.
                continue;
            } else if (file.startsWith(QStringLiteral("pwm")) && (file.endsWith(QStringLiteral("_enable")) || file.endsWith(QStringLiteral("_mode")))) {
                entry.pwmEnable.append(file);
            } else if (file.startsWith(QStringLiteral("pwm"))) {
                entry.pwmControls.append(file);
            }
        }
        if (!entry.name.isEmpty() || !entry.fanInputs.isEmpty() || !entry.tempInputs.isEmpty()) {
            entries.append(entry);
        }
    }
    return entries;
}

QString SysInfo::readOsReleasePrettyName() {
    QFile f(QStringLiteral("/etc/os-release"));
    if (!f.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return QStringLiteral("Luna OS");
    }
    QTextStream in(&f);
    while (!in.atEnd()) {
        const QString line = in.readLine();
        if (line.startsWith(QStringLiteral("PRETTY_NAME="))) {
            return stripQuotes(line.mid(QStringLiteral("PRETTY_NAME=").size()));
        }
    }
    return QStringLiteral("Luna OS");
}

QString SysInfo::readOsReleaseId() {
    QFile f(QStringLiteral("/etc/os-release"));
    if (!f.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return QStringLiteral("luna");
    }
    QTextStream in(&f);
    while (!in.atEnd()) {
        const QString line = in.readLine();
        if (line.startsWith(QStringLiteral("ID="))) {
            return stripQuotes(line.mid(3));
        }
    }
    return QStringLiteral("luna");
}

QString SysInfo::readKernelRelease() {
    return readFirstLine(QStringLiteral("/proc/sys/kernel/osrelease"));
}

QString SysInfo::readKernelVersion() {
    return readFirstLine(QStringLiteral("/proc/sys/kernel/version"));
}

QString SysInfo::readHostname() {
    return readFirstLine(QStringLiteral("/proc/sys/kernel/hostname"));
}

}  // namespace Luna::Hub

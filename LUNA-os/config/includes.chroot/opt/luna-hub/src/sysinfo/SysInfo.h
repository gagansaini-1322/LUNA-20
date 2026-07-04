// Luna OS Project
//
// Thin wrappers around /proc and /sys filesystems for telemetry consumers.
// The functions are total on purpose: a missing file returns a default value
// rather than throwing, which lines up with the no-throw contract shared
// across the controllers in this directory.

#ifndef LUNA_SYSINFO_H
#define LUNA_SYSINFO_H

#include <QList>
#include <QString>
#include <QStringList>

namespace Luna::Hub {

struct CpuTimes {
    quint64 user = 0;
    quint64 nice = 0;
    quint64 system = 0;
    quint64 idle = 0;
    quint64 iowait = 0;
    quint64 irq = 0;
    quint64 softirq = 0;
    quint64 steal = 0;

    quint64 totalBusy() const;
    quint64 totalAll() const;
};

struct MemInfo {
    quint64 totalKb = 0;
    quint64 availableKb = 0;
    quint64 freeKb = 0;
    quint64 buffersKb = 0;
    quint64 cachedKb = 0;
    quint64 swapTotalKb = 0;
    quint64 swapFreeKb = 0;
    quint64 sharedKb = 0;
};

struct HwmonEntry {
    QString name;
    QString path;
    QStringList fanInputs;
    QStringList tempInputs;
    QStringList pwmControls;
    QStringList pwmEnable;
};

class SysInfo {
public:
    SysInfo() = delete;

    static QString readCpuModel();
    static int readLogicalCoreCount();
    static QList<int> readOnlineCores();
    static CpuTimes readCpuTimesAggregated();
    static MemInfo readMemInfo();
    static QString readUptime();
    static QStringList readLoadAvg();
    static double readCpuFrequencyMhz(int cpuIndex);
    static QList<HwmonEntry> enumerateHwmon();
    static QString readOsReleasePrettyName();
    static QString readOsReleaseId();
    static QString readKernelRelease();
    static QString readKernelVersion();
    static QString readHostname();
};

}  // namespace Luna::Hub

#endif // LUNA_SYSINFO_H

// Luna OS Project
//
// Detects NVIDIA / AMD / Intel GPUs on Linux by inspecting
// /sys/class/drm and shelling out to nvidia-smi. Designed so that QML
// consumers always see the same descriptor shape regardless of vendor.

#ifndef LUNA_GPU_DETECTOR_H
#define LUNA_GPU_DETECTOR_H

#include <QList>
#include <QString>

namespace Luna::Hub {

struct GpuDescriptor {
    int idx = 0;
    QString vendor;     // "nvidia" | "amd" | "intel" | "unknown"
    QString name;
    QString pciSlot;    // e.g. "0000:01:00.0"
    QString driver;
    QString drmPath;
    bool canReadSysFs = true;
};

class GpuDetector {
public:
    GpuDetector() = delete;

    static QList<GpuDescriptor> detectAll();
    static bool hasNvidiaSmi();
    static QList<GpuDescriptor> detectAmd();
    static QList<GpuDescriptor> detectIntel();
    static QList<GpuDescriptor> detectNvidia();
};

}  // namespace Luna::Hub

#endif // LUNA_GPU_DETECTOR_H

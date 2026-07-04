//! Intel iGPU telemetry via sysfs. Intel usually exposes the GPU under
//! `/sys/class/drm/card*/` with vendor `0x8086`. There is no direct
//! `gpu_busy_percent` for older iGPUs; newer ones expose
//! `gt/gt*/rc6` plus `freq/cur_freq` and `media/0/i915_*.status`.

use std::fs;
use std::path::Path;

use crate::state::GpuSnapshot;

const INTEL_VENDOR: &str = "0x8086";

pub fn discover() -> Vec<GpuSnapshot> {
    let mut out = Vec::new();
    let Ok(entries) = fs::read_dir("/sys/class/drm") else {
        return out;
    };
    for entry in entries.flatten() {
        let path = entry.path();
        let Some(name) = path.file_name().and_then(|n| n.to_str()).map(str::to_string) else {
            continue;
        };
        if !name.starts_with("card") || name.contains('-') {
            continue;
        }
        let device = path.join("device");
        let vendor_path = device.join("vendor");
        let vendor_raw = match fs::read_to_string(&vendor_path) {
            Ok(v) => v.trim().to_string(),
            Err(_) => continue,
        };
        if !vendor_raw.eq_ignore_ascii_case(INTEL_VENDOR) {
            continue;
        }
        let idx = name
            .trim_start_matches("card")
            .parse::<u32>()
            .unwrap_or(0);

        let name_str = read_intel_name(&device);
        let util_pct = read_intel_util(&device);
        let power_w = read_intel_power_w(&device);
        let temp_c = read_intel_temp(&device);
        let clock_mhz = read_intel_clock_mhz(&device);

        out.push(GpuSnapshot {
            idx,
            vendor: "intel".to_string(),
            name: name_str,
            util_pct,
            temp_c,
            vram_used_bytes: None,
            vram_total_bytes: None,
            power_w,
            clock_mhz,
        });
    }
    out
}

fn read_intel_name(device: &Path) -> String {
    if let Ok(raw) = fs::read_to_string(device.join("product_name")) {
        let v = raw.trim();
        if !v.is_empty() {
            return v.to_string();
        }
    }
    if let Ok(raw) = fs::read_to_string(device.join("device")) {
        // 0x5917, etc.
        let id = raw.trim().to_string();
        return format!("Intel GPU {id}");
    }
    "Intel GPU".to_string()
}

fn read_intel_util(device: &Path) -> Option<f32> {
    // For cards reporting gpu_busy_percent.
    if let Ok(raw) = fs::read_to_string(device.join("gpu_busy_percent")) {
        if let Ok(v) = raw.trim().parse::<f32>() {
            return Some(v.clamp(0.0, 100.0));
        }
    }
    // Compute 100 - rc6% from gt/gt0/rc6_residency as a coarse proxy.
    if let Ok(rc6_body) = fs::read_to_string(device.join("gt/gt0/rc6_residency_ms")) {
        if let Some(p) = parse_percent_token(&rc6_body) {
            return Some((100.0 - p).clamp(0.0, 100.0));
        }
    }
    None
}

fn parse_percent_token(line: &str) -> Option<f32> {
    let mut it = line.split_whitespace();
    let _ms = it.next()?;
    let pct = it.next()?;
    if let Some(v) = pct.trim_end_matches('%').parse::<f32>().ok() {
        Some(v)
    } else {
        pct.parse::<f32>().ok()
    }
}

fn read_intel_power_w(device: &Path) -> Option<f32> {
    let candidates = ["power1_average", "power1_input"];
    for c in candidates {
        if let Ok(raw) = fs::read_to_string(device.join(c)) {
            if let Ok(uv) = raw.trim().parse::<i64>() {
                if uv >= 0 {
                    return Some(uv as f32 / 1_000_000.0);
                }
            }
        }
    }
    None
}

fn read_intel_temp(device: &Path) -> Option<f32> {
    let hwmon_path = device.join("hwmon");
    let Ok(entries) = fs::read_dir(&hwmon_path) else {
        return None;
    };
    for e in entries.flatten() {
        for idx in 1..=9 {
            let f = e.path().join(format!("temp{idx}_input"));
            if let Ok(raw) = fs::read_to_string(&f) {
                if let Ok(m) = raw.trim().parse::<i64>() {
                    return Some(m as f32 / 1000.0);
                }
            }
        }
    }
    None
}

fn read_intel_clock_mhz(device: &Path) -> Option<u32> {
    if let Ok(raw) = fs::read_to_string(device.join("gt/gt0/freq/cur_freq")) {
        if let Ok(mhz) = raw.trim().parse::<f32>() {
            return Some(mhz as u32);
        }
    }
    if let Ok(raw) = fs::read_to_string(device.join("gt/gt0/cur_freq")) {
        if let Ok(v) = raw.trim().parse::<u32>() {
            return Some(v);
        }
    }
    None
}

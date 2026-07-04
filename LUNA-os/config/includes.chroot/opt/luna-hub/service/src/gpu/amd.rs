//! AMD GPU telemetry via sysfs. The DRM/kms driver exposes a
//! `gpu_busy_percent` file that we read directly. Memory and power
//! readings are best-effort.

use std::fs;
use std::path::Path;

use crate::state::GpuSnapshot;

const AMD_VENDOR: &str = "0x1002";

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
        if !vendor_raw.eq_ignore_ascii_case(AMD_VENDOR) {
            continue;
        }
        let idx = name
            .trim_start_matches("card")
            .parse::<u32>()
            .unwrap_or(0);

        let name_str = read_name(&device).unwrap_or_else(|| "AMD GPU".to_string());
        let util_pct = parse_percent(&device.join("gpu_busy_percent"));
        let power_w = parse_microwatts(&device.join("power1_average"))
            .or_else(|| parse_microwatts(&device.join("power1_input")));
        let power_w = power_w.map(|w| w as f32);
        let vram_used = read_vram_used(&device);
        let vram_total = read_vram_total(&device);
        let temp_c = read_hwmon_temp_for_vendor(&device, AMD_VENDOR);
        let clock_mhz = read_clock_mhz(&device);

        out.push(GpuSnapshot {
            idx,
            vendor: "amd".to_string(),
            name: name_str,
            util_pct,
            temp_c,
            vram_used_bytes: vram_used,
            vram_total_bytes: vram_total,
            power_w,
            clock_mhz,
        });
    }
    out
}

fn read_name(device: &Path) -> Option<String> {
    if let Ok(s) = fs::read_to_string(device.join("product_name")) {
        let v = s.trim();
        if !v.is_empty() {
            return Some(v.to_string());
        }
    }
    if let Ok(s) = fs::read_to_string(device.join("vram vendor")) {
        let v = s.trim();
        if !v.is_empty() {
            return Some(v.to_string());
        }
    }
    None
}

fn parse_percent(p: &Path) -> Option<f32> {
    let raw = fs::read_to_string(p).ok()?;
    let v: f32 = raw.trim().parse().ok()?;
    Some(v.clamp(0.0, 100.0))
}

fn parse_microwatts(p: &Path) -> Option<f64> {
    let raw = fs::read_to_string(p).ok()?;
    let v: i64 = raw.trim().parse().ok()?;
    if v < 0 {
        None
    } else {
        Some(v as f64 / 1_000_000.0)
    }
}

fn read_vram_used(device: &Path) -> Option<u64> {
    let p = device.join("mem_info_vram_used");
    let raw = fs::read_to_string(p).ok()?;
    let v: u64 = raw.trim().parse().ok()?;
    Some(v)
}

fn read_vram_total(device: &Path) -> Option<u64> {
    let p = device.join("mem_info_vram_total");
    let raw = fs::read_to_string(p).ok()?;
    let v: u64 = raw.trim().parse().ok()?;
    Some(v)
}

fn read_clock_mhz(device: &Path) -> Option<u32> {
    if let Ok(raw) = fs::read_to_string(device.join("pp_dpm_sclk")) {
        if let Some(mhz) = parse_highest_freq_mhz(&raw) {
            return Some(mhz);
        }
    }
    if let Ok(raw) = fs::read_to_string(device.join("pp_dpm_mclk")) {
        if let Some(mhz) = parse_highest_freq_mhz(&raw) {
            return Some(mhz);
        }
    }
    None
}

fn parse_highest_freq_mhz(body: &str) -> Option<u32> {
    let mut best: Option<u32> = None;
    for line in body.lines() {
        if let Some(mhz) = parse_freq_mhz_from_line(line) {
            best = match best {
                None => Some(mhz),
                Some(v) => Some(v.max(mhz)),
            };
        }
    }
    best
}

fn parse_freq_mhz_from_line(line: &str) -> Option<u32> {
    if let Some(mhz) = line.split_whitespace().find_map(|t| {
        if t.ends_with("Mhz") {
            t.trim_end_matches("Mhz").parse::<u32>().ok()
        } else if t.ends_with("MHz") {
            t.trim_end_matches("MHz").parse::<u32>().ok()
        } else {
            None
        }
    }) {
        return Some(mhz);
    }
    if let Some(idx) = line.find("Mhz") {
        let prefix = &line[..idx];
        if let Some(token) = prefix.split_whitespace().last() {
            if let Ok(v) = token.parse::<u32>() {
                return Some(v);
            }
        }
    }
    None
}

fn read_hwmon_temp_for_vendor(device: &Path, vendor: &str) -> Option<f32> {
    let hwmon_dir = device.join("hwmon");
    let entries = fs::read_dir(hwmon_dir).ok()?;
    for e in entries.flatten() {
        let name_path = e.path().join("name");
        if let Ok(name) = fs::read_to_string(&name_path) {
            // Some AMD cards report the hwmon name as "amdgpu".
            if name.trim().eq_ignore_ascii_case("amdgpu") || name.trim().is_empty() {
                let _ = vendor;
                for label_idx in 1..=9 {
                    let f = e.path().join(format!("temp{label_idx}_input"));
                    if let Ok(raw) = fs::read_to_string(&f) {
                        if let Ok(m) = raw.trim().parse::<i64>() {
                            return Some(m as f32 / 1000.0);
                        }
                    }
                }
                if let Ok(raw) = fs::read_to_string(e.path().join("temp1_input")) {
                    if let Ok(m) = raw.trim().parse::<i64>() {
                        return Some(m as f32 / 1000.0);
                    }
                }
            }
        }
    }
    None
}

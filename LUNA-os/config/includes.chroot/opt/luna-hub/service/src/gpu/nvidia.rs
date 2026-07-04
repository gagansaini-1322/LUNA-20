//! NVIDIA telemetry using `nvidia-smi`. Never assume it exists; the
//! caller probes the binary first and degrades to `unsupported` when not
//! available.

use std::collections::HashMap;
use std::process::Command;

use crate::state::GpuSnapshot;

pub fn is_available() -> bool {
    binary_in_path("nvidia-smi")
}

fn binary_in_path(cmd: &str) -> bool {
    if let Some(paths) = std::env::var_os("PATH") {
        for path in std::env::split_paths(&paths) {
            if path.join(cmd).is_file() {
                return true;
            }
        }
    }
    false
}

/// Returns one snapshot per GPU in the system. The field order matches
/// `nvidia-smi --query-gpu` semantics. If the call fails, returns `None`.
pub fn sample_all() -> Vec<GpuSnapshot> {
    if !is_available() {
        return Vec::new();
    }
    let output = match Command::new("nvidia-smi")
        .args([
            "--query-gpu=index,name,utilization.gpu,temperature.gpu,memory.used,memory.total,power.draw,clocks.current.sm",
            "--format=csv,noheader,nounits",
        ])
        .output()
    {
        Ok(o) if o.status.success() => o,
        _ => return Vec::new(),
    };

    let stdout = String::from_utf8_lossy(&output.stdout);
    let mut out = Vec::new();
    for line in stdout.lines() {
        if let Some(snap) = parse_line(line) {
            out.push(snap);
        }
    }
    out
}

fn parse_line(line: &str) -> Option<GpuSnapshot> {
    let mut cols = line.split(',').map(str::trim);
    let idx = cols.next()?.parse::<u32>().ok()?;
    let name = cols.next()?.to_string();
    let util = parse_f32(cols.next()?);
    let temp = parse_f32(cols.next()?);
    let vram_used = parse_u64(cols.next()?);
    let vram_total = parse_u64(cols.next()?);
    let power = parse_f32(cols.next()?);
    let clock = parse_u32(cols.next()?);

    Some(GpuSnapshot {
        idx,
        vendor: "nvidia".to_string(),
        name,
        util_pct: util,
        temp_c: temp,
        vram_used_bytes: vram_used.map(|m| m * 1024 * 1024),
        vram_total_bytes: vram_total.map(|m| m * 1024 * 1024),
        power_w: power,
        clock_mhz: clock,
    })
}

fn parse_f32(s: &str) -> Option<f32> {
    if s.eq_ignore_ascii_case("[Not Supported]") || s.eq_ignore_ascii_case("[N/A]") || s == "-" {
        return None;
    }
    s.parse().ok()
}

fn parse_u32(s: &str) -> Option<u32> {
    if s.eq_ignore_ascii_case("[Not Supported]") || s.eq_ignore_ascii_case("[N/A]") || s == "-" {
        return None;
    }
    s.parse().ok()
}

fn parse_u64(s: &str) -> Option<u64> {
    if s.eq_ignore_ascii_case("[Not Supported]") || s.eq_ignore_ascii_case("[N/A]") || s == "-" {
        return None;
    }
    s.parse().ok()
}

/// Returns a static info-style GpuSnapshot using only fields that don't
/// change. Used during SystemInfo assembly.
pub fn static_info() -> Vec<GpuSnapshot> {
    if !is_available() {
        return Vec::new();
    }
    let output = match Command::new("nvidia-smi")
        .args([
            "--query-gpu=index,name,memory.total",
            "--format=csv,noheader,nounits",
        ])
        .output()
    {
        Ok(o) if o.status.success() => o,
        _ => return Vec::new(),
    };
    let stdout = String::from_utf8_lossy(&output.stdout);
    let mut out = Vec::new();
    for line in stdout.lines() {
        let mut cols: Vec<&str> = line.split(',').map(str::trim).collect();
        if cols.len() < 3 {
            continue;
        }
        let idx = cols[0].parse::<u32>().ok()?;
        let name = cols[1].to_string();
        let vram_total = parse_u64(cols[2]).map(|m| m * 1024 * 1024);
        out.push(GpuSnapshot {
            idx,
            vendor: "nvidia".to_string(),
            name,
            util_pct: None,
            temp_c: None,
            vram_used_bytes: None,
            vram_total_bytes: vram_total,
            power_w: None,
            clock_mhz: None,
        });
    }
    out
}

#[allow(dead_code)]
pub fn uuid_map() -> HashMap<String, String> {
    let mut map = HashMap::new();
    if !is_available() {
        return map;
    }
    let output = match Command::new("nvidia-smi")
        .args(["--query-gpu=uuid,name", "--format=csv,noheader"])
        .output()
    {
        Ok(o) if o.status.success() => o,
        _ => return map,
    };
    let stdout = String::from_utf8_lossy(&output.stdout);
    for line in stdout.lines() {
        let mut cols = line.split(',').map(str::trim);
        if let (Some(uuid), Some(name)) = (cols.next(), cols.next()) {
            map.insert(uuid.to_string(), name.to_string());
        }
    }
    map
}

//! GPU collectors. Combines NVIDIA, AMD, and Intel probes into a single
//! aggregated snapshot per tick.

pub mod amd;
pub mod intel;
pub mod nvidia;

use std::fs;

use crate::state::GpuSnapshot;

pub fn sample() -> Vec<GpuSnapshot> {
    let mut out = Vec::new();
    out.extend(nvidia::sample_all());
    out.extend(amd::discover());
    out.extend(intel::discover());
    out.sort_by_key(|g| g.idx);
    dedup_by_card_index(&mut out);
    out
}

pub fn static_info() -> Vec<GpuSnapshot> {
    let mut out = Vec::new();
    out.extend(nvidia::static_info());
    out.extend(amd::discover());
    out.extend(intel::discover());
    out.sort_by_key(|g| g.idx);
    dedup_by_card_index(&mut out);
    out
}

fn dedup_by_card_index(list: &mut Vec<GpuSnapshot>) {
    // If the same `idx` appears from two vendors (e.g. nvidia-smi idx 0
    // matches an Intel iGPU on card0 because index isn't unique), prefer
    // the discrete-nvidia entry first.
    list.sort_by(|a, b| {
        vendor_priority(a.vendor.as_str())
            .cmp(&vendor_priority(b.vendor.as_str()))
            .then_with(|| a.idx.cmp(&b.idx))
    });
    let mut seen = std::collections::HashSet::new();
    list.retain(|g| seen.insert(g.idx));
}

fn vendor_priority(v: &str) -> u32 {
    match v {
        "nvidia" => 0,
        "amd" => 1,
        "intel" => 2,
        _ => 3,
    }
}

pub fn vendor_id_for_path(device_dir: &std::path::Path) -> Option<&'static str> {
    let raw = fs::read_to_string(device_dir.join("vendor")).ok()?;
    let v = raw.trim();
    match v {
        "0x10de" => Some("nvidia"),
        "0x1002" => Some("amd"),
        "0x8086" => Some("intel"),
        _ => None,
    }
}

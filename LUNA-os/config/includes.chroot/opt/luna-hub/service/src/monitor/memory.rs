//! Memory collector. Parses `/proc/meminfo` once per tick.

use std::fs;

use crate::state::MemorySnapshot;

pub fn sample() -> MemorySnapshot {
    let body = match fs::read_to_string("/proc/meminfo") {
        Ok(b) => b,
        Err(_) => {
            return MemorySnapshot {
                used_bytes: 0,
                total_bytes: 0,
                avail_bytes: 0,
                cached_bytes: 0,
                swap_used_bytes: 0,
                swap_total_bytes: 0,
            };
        }
    };

    let mut total = 0u64;
    let mut avail = 0u64;
    let mut cached = 0u64;
    let mut buffers = 0u64;
    let mut free = 0u64;
    let mut swap_total = 0u64;
    let mut swap_free = 0u64;

    for line in body.lines() {
        let mut it = line.split_whitespace();
        let key = it.next().unwrap_or("").trim_end_matches(':');
        if let Some(raw) = it.next() {
            if let Ok(val) = raw.parse::<u64>() {
                let kb = val * 1024;
                match key {
                    "MemTotal" => total = kb,
                    "MemAvailable" => avail = kb,
                    "Cached" => cached = kb,
                    "Buffers" => buffers = kb,
                    "MemFree" => free = kb,
                    "SwapTotal" => swap_total = kb,
                    "SwapFree" => swap_free = kb,
                    _ => {}
                }
            }
        }
    }

    let used = total.saturating_sub(avail).max(total.saturating_sub(free + buffers + cached));
    MemorySnapshot {
        used_bytes: used,
        total_bytes: total,
        avail_bytes: avail,
        cached_bytes: cached,
        swap_used_bytes: swap_total.saturating_sub(swap_free),
        swap_total_bytes: swap_total,
    }
}

pub fn total_bytes() -> u64 {
    sample().total_bytes
}

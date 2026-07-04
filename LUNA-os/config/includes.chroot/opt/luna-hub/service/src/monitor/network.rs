//! Per-interface traffic rate collector.

use std::fs;
use std::path::Path;
use std::time::Instant;

use crate::state::NetworkSnapshot;

pub struct NetStat {
    prev_bytes: Option<(u64, u64, String)>,
    prev_at: Option<Instant>,
}

impl NetStat {
    pub fn new() -> Self {
        Self {
            prev_bytes: None,
            prev_at: None,
        }
    }

    pub fn tick(&mut self) -> NetworkSnapshot {
        let iface = pick_interface().unwrap_or_else(|| "lo".to_string());
        let (rx, tx) = iface_stats(&iface).unwrap_or((0, 0));

        let now = Instant::now();
        let (rx_bps, tx_bps) = match (self.prev_bytes, self.prev_at) {
            (Some((prx, ptx)), Some(t0)) => {
                let dt = now.duration_since(t0).as_secs_f64();
                if dt > 0.001 && ((prx, ptx) != (rx, tx) || (rx, tx) != (0, 0)) {
                    (((rx as f64 - prx as f64) / dt).max(0.0),
                     ((tx as f64 - ptx as f64) / dt).max(0.0))
                } else {
                    (0.0, 0.0)
                }
            }
            _ => (0.0, 0.0),
        };

        self.prev_bytes = Some((rx, tx, iface.clone()));
        self.prev_at = Some(now);

        NetworkSnapshot {
            interface: iface,
            rx_bps,
            tx_bps,
            latency_ms: None,
            packet_loss_pct: None,
        }
    }
}

/// Picks the primary non-loopback, non-virtual up interface. Returns the
/// interface name as found in `/sys/class/net`.
pub fn pick_interface() -> Option<String> {
    let dir = fs::read_dir("/sys/class/net").ok()?;
    let mut entries: Vec<(String, bool)> = dir
        .filter_map(|e| e.ok())
        .filter_map(|e| {
            let name = e.file_name().to_string_lossy().to_string();
            let state = fs::read_to_string(e.path().join("operstate"))
                .ok()
                .map(|s| s.trim().eq_ignore_ascii_case("up"))
                .unwrap_or(false);
            if name == "lo" {
                None
            } else {
                Some((name, state))
            }
        })
        .collect();
    // Prefer "up"; fall back to anything non-loopback.
    entries.sort_by(|a, b| b.1.cmp(&a.1));
    entries.first().map(|(n, _)| n.clone())
}

fn iface_stats(iface: &str) -> Option<(u64, u64)> {
    let rx = fs::read_to_string(Path::new("/sys/class/net").join(iface).join("statistics/rx_bytes"))
        .ok()?
        .trim()
        .parse::<u64>()
        .ok()?;
    let tx = fs::read_to_string(Path::new("/sys/class/net").join(iface).join("statistics/tx_bytes"))
        .ok()?
        .trim()
        .parse::<u64>()
        .ok()?;
    Some((rx, tx))
}

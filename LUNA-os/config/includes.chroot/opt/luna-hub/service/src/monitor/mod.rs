//! Periodic background monitor orchestration. Each subsystem has its
//! own interval; the tick functions return fresh snapshot fragments that
//! populate shared [`crate::runtime::AppState`] storage.

pub mod cpu;
pub mod memory;
pub mod network;
pub mod ring_buffer;

use std::time::Duration;
use tokio::time::sleep;
use tracing::{trace, warn};

use crate::monitor::cpu::CpuStat;
use crate::monitor::network::NetStat;
use crate::runtime::AppState;
use crate::state::TelemetrySnapshot;

#[derive(Debug, Clone, Copy)]
pub struct Intervals {
    pub cpu: Duration,
    pub memory: Duration,
    pub gpu: Duration,
    pub temp: Duration,
    pub fan: Duration,
    pub net: Duration,
    pub game: Duration,
}

impl Default for Intervals {
    fn default() -> Self {
        Self {
            cpu: Duration::from_millis(750),
            memory: Duration::from_millis(1000),
            gpu: Duration::from_millis(1000),
            temp: Duration::from_millis(1500),
            fan: Duration::from_millis(1500),
            net: Duration::from_millis(1000),
            game: Duration::from_millis(2000),
        }
    }
}

/// Drive all collectors and publish fresh snapshots to the IPC channel.
///
/// On any single-subsystem failure we keep going — telemetry must remain
/// defensible even when one provider misbehaves.
pub async fn run_collectors(state: AppState) -> anyhow::Result<()> {
    let mut cpu_stat = CpuStat::new();
    let mut net_stat = NetStat::new();
    let cycle = Intervals::default();
    let interval = cycle.cpu;

    loop {
        sleep(interval).await;
        trace!("collectors tick");

        let mut snap = state.snapshot().await;

        match cpu_stat.tick() {
            c => snap.cpu = c,
        }
        snap.memory = crate::monitor::memory::sample();
        let v = crate::sensor::temperature::list_sensors();
        if !v.is_empty() { snap.temps = v; }
        let v = crate::sensor::fan::list_fans();
        if !v.is_empty() { snap.fans = v; }
        snap.network = net_stat.tick();
        snap.gpus = crate::gpu::sample();
        snap.timestamp_ms = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .map(|d| d.as_millis())
            .unwrap_or(0);
        state.publish(snap).await;
    }
}

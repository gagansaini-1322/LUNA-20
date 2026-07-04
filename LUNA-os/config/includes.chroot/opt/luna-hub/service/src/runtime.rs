// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Runtime context for luna-telemetryd.
//
use std::sync::Arc;

use crate::capability::{CapabilityProbe, SubsystemCapability};
use crate::state::TelemetrySnapshot;
use tokio::sync::{broadcast, RwLock};

/// Default broadcast channel size for telemetry updates.
pub const SNAPSHOT_TX_DEPTH: usize = 8;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum RunMode {
    Foreground,
    Dbus,
}

#[derive(Debug, Clone)]
pub struct RunOptions {
    pub mode: RunMode,
    pub dbus_name: String,
    pub socket_path: String,
    pub cpu_interval_ms: u64,
    pub memory_interval_ms: u64,
    pub gpu_interval_ms: u64,
    pub temp_interval_ms: u64,
    pub fan_interval_ms: u64,
    pub net_interval_ms: u64,
    pub game_interval_ms: u64,
}

impl Default for RunOptions {
    fn default() -> Self {
        Self {
            mode: RunMode::Foreground,
            dbus_name: "io.luna.Telemetry1".to_string(),
            socket_path: "/var/run/luna/telemetry.sock".to_string(),
            cpu_interval_ms: 750,
            memory_interval_ms: 1000,
            gpu_interval_ms: 1000,
            temp_interval_ms: 1500,
            fan_interval_ms: 1500,
            net_interval_ms: 1000,
            game_interval_ms: 2000,
        }
    }
}

#[derive(Clone)]
pub struct AppState {
    inner: Arc<RwLock<AppStateInner>>,
    snapshot_tx: broadcast::Sender<TelemetrySnapshot>,
    capability: Arc<SubsystemCapability>,
}

struct AppStateInner {
    snapshot: TelemetrySnapshot,
    run_options: RunOptions,
}

impl AppState {
    /// Build a new state with the given options and detected capability profile.
    ///
    /// Errors are non-fatal: a subservice that fails capability detection is
    /// simply marked unavailable and skipped at run time.
    pub fn new(options: RunOptions, probe: &CapabilityProbe) -> Self {
        let (tx, _) = broadcast::channel(SNAPSHOT_TX_DEPTH);
        let capability = SubsystemCapability::from_probe(probe);
        let snapshot = TelemetrySnapshot::with_capabilities(&capability);
        let inner = AppStateInner {
            snapshot,
            run_options: options,
        };
        Self {
            inner: Arc::new(RwLock::new(inner)),
            snapshot_tx: tx,
            capability: Arc::new(capability),
        }
    }

    /// Read-only access to current snapshot.
    pub async fn snapshot(&self) -> TelemetrySnapshot {
        self.inner.read().await.snapshot.clone()
    }

    /// Replace snapshot and broadcast to subscribers.
    pub async fn publish(&self, snap: TelemetrySnapshot) {
        {
            let mut guard = self.inner.write().await;
            guard.snapshot = snap.clone();
        }
        // Errors are fine if no subscribers are connected.
        let _ = self.snapshot_tx.send(snap);
    }

    /// Current run options.
    pub async fn run_options(&self) -> RunOptions {
        self.inner.read().await.run_options.clone()
    }

    /// Receiver for live snapshot updates.
    pub fn subscribe(&self) -> broadcast::Receiver<TelemetrySnapshot> {
        self.snapshot_tx.subscribe()
    }

    /// Capability profile for this daemon instance.
    pub fn capability(&self) -> Arc<SubsystemCapability> {
        self.capability.clone()
    }
}

pub struct AppStateBuilder {
    options: RunOptions,
    probe: CapabilityProbe,
}

impl AppStateBuilder {
    pub fn new(options: RunOptions) -> Self {
        Self {
            options,
            probe: CapabilityProbe::default(),
        }
    }

    pub fn with_probe(mut self, probe: CapabilityProbe) -> Self {
        self.probe = probe;
        self
    }

    pub fn build(self) -> AppState {
        AppState::new(self.options, &self.probe)
    }
}

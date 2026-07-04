//! Game runtime detection across Steam, Heroic, and Lutris. Provides a
//! manually-managed queue of game IDs for clients that wish to influence
//! telemetry weighting.

use std::collections::HashMap;
use std::sync::Mutex;
use std::time::{SystemTime, UNIX_EPOCH};

use crate::monitor::ring_buffer::RingBuffer;

pub mod heroic;
pub mod lutris;
pub mod steam;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum GameRuntime {
    Steam,
    Heroic,
    Lutris,
    Manual,
}

impl GameRuntime {
    pub fn name(self) -> &'static str {
        match self {
            GameRuntime::Steam => "steam",
            GameRuntime::Heroic => "heroic",
            GameRuntime::Lutris => "lutris",
            GameRuntime::Manual => "manual",
        }
    }
}

#[derive(Debug, Clone)]
pub struct GameHit {
    pub source: String,
    pub app_id: Option<String>,
    pub title: Option<String>,
    pub pid: u32,
    pub runtime: GameRuntime,
}

#[derive(Debug, Clone)]
pub struct ActiveGameSummary {
    pub source: String,
    pub app_id: Option<String>,
    pub title: Option<String>,
    pub pid: u32,
    pub started_ms: u128,
}

/// Aggregates per-tick detection into an "active game" record with stable
/// identity. Uses a small ring buffer of detections so quick process
/// restarts don't lose track of state.
pub struct ActiveGameTracker {
    history: RingBuffer<ActiveGameSummary>,
    last_app_id: Option<String>,
    last_pid: Option<u32>,
    last_source: Option<String>,
}

impl ActiveGameTracker {
    pub fn new() -> Self {
        Self {
            history: RingBuffer::with_capacity(64),
            last_app_id: None,
            last_pid: None,
            last_source: None,
        }
    }

    pub fn ingest(&mut self, hit: GameHit) -> Option<ActiveGameSummary> {
        let app_id = hit.app_id.clone();
        let key = (app_id.clone(), hit.pid);
        if Some(&key) != self.last_app_id.as_ref().map(|a| (Some(a.clone()), hit.pid)).as_ref() {
            // start of new active game
            if self.last_pid != Some(hit.pid) {
                self.last_pid = Some(hit.pid);
                self.last_app_id = app_id.clone();
                self.last_source = Some(hit.source.clone());
            }
        }

        let summary = ActiveGameSummary {
            source: hit.source,
            app_id,
            title: hit.title,
            pid: hit.pid,
            started_ms: now_ms(),
        };
        self.history.push(summary.clone());
        Some(summary)
    }

    pub fn current(&self) -> Option<ActiveGameSummary> {
        self.history.as_slice().last().cloned()
    }

    pub fn history(&self) -> Vec<ActiveGameSummary> {
        self.history.as_slice().into_iter().cloned().collect()
    }
}

#[derive(Default)]
pub struct ManualQueue {
    inner: Mutex<HashMap<String, ManualEntry>>,
}

#[derive(Debug, Clone)]
pub struct ManualEntry {
    pub id: String,
    pub title: Option<String>,
    pub runtime: String,
    pub added_ms: u128,
}

impl ManualQueue {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn add(&self, id: String, title: Option<String>, runtime: String) -> ManualEntry {
        let entry = ManualEntry {
            id: id.clone(),
            title,
            runtime,
            added_ms: now_ms(),
        };
        let mut g = self.inner.lock().expect("manual queue");
        g.insert(id, entry.clone());
        entry
    }

    pub fn remove(&self, id: &str) -> bool {
        let mut g = self.inner.lock().expect("manual queue");
        g.remove(id).is_some()
    }

    pub fn list(&self) -> Vec<ManualEntry> {
        let g = self.inner.lock().expect("manual queue");
        let mut v: Vec<ManualEntry> = g.values().cloned().collect();
        v.sort_by(|a, b| a.id.cmp(&b.id));
        v
    }
}

pub fn scan_all() -> Vec<GameHit> {
    let mut all = Vec::new();
    all.extend(steam::scan());
    all.extend(heroic::scan());
    all.extend(lutris::scan());
    all
}

pub fn now_ms() -> u128 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_millis())
        .unwrap_or(0)
}

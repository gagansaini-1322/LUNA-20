//! Steam game detection.
//!
//! Steam runs as `steam` (with `-=` style child processes), `gamescope`,
//! `steam-runtime-launch*` and the kernel-level Proton prefixes. We scan
//! running processes for these and report the active game's appid when
//! we can find one.

use std::fs;
use std::path::Path;

use crate::games::{GameHit, GameRuntime};

const STEAM_PROCESS_HINTS: &[&str] = &[
    "steam",
    "steam.sh",
    "steam-runtime-launch-client",
    "steam-runtime-launch*",
    "gamescope",
    "pressure-vessel",
];

pub fn scan() -> Vec<GameHit> {
    let mut hits = Vec::new();
    for entry in fs::read_dir("/proc").into_iter().flatten().flatten() {
        let name = entry.file_name().to_string_lossy().to_string();
        if !name.chars().all(|c| c.is_ascii_digit()) {
            continue;
        }
        let pid: u32 = match name.parse() {
            Ok(v) if v > 0 => v,
            _ => continue,
        };
        let comm = match read_comm(pid) {
            Some(c) => c,
            None => continue,
        };

        if !is_steam_process(&comm) {
            continue;
        }
        let cmdline = read_cmdline(pid).unwrap_or_default();
        let (app_id, title) = extract_game_meta(&cmdline);
        hits.push(GameHit {
            source: "steam".to_string(),
            app_id,
            title,
            pid,
            runtime: GameRuntime::Steam,
        });
    }
    hits
}

pub fn is_steam_process(comm: &str) -> bool {
    let lower = comm.to_ascii_lowercase();
    STEAM_PROCESS_HINTS.iter().any(|h| {
        if h.ends_with('*') {
            lower.starts_with(&h.trim_end_matches('*').to_ascii_lowercase())
        } else {
            lower == h.to_ascii_lowercase()
        }
    })
}

fn read_comm(pid: u32) -> Option<String> {
    fs::read_to_string(Path::new("/proc").join(pid.to_string()).join("comm"))
        .ok()
        .map(|s| s.trim().to_string())
        .filter(|s| !s.is_empty())
}

fn read_cmdline(pid: u32) -> Option<String> {
    let raw = fs::read_to_string(Path::new("/proc").join(pid.to_string()).join("cmdline")).ok()?;
    let bytes: Vec<u8> = raw.bytes().collect();
    if bytes.is_empty() {
        return None;
    }
    Some(
        bytes
            .split(|b| *b == 0)
            .filter_map(|seg| std::str::from_utf8(seg).ok())
            .collect::<Vec<_>>()
            .join(" "),
    )
}

fn extract_game_meta(cmdline: &str) -> (Option<String>, Option<String>) {
    let mut app_id: Option<String> = None;
    for token in cmdline.split_whitespace() {
        if let Some(rest) = token.strip_prefix("-applaunch=") {
            app_id = Some(rest.to_string());
            break;
        }
    }
    // SteamDeck/Gamescope exposes the appid in the gamescope cmdline via `-i`
    // or `steam://rungameid/...`. We surface appid when present.
    if app_id.is_none() {
        for token in cmdline.split_whitespace() {
            if let Some(rest) = token.strip_prefix("steam://rungameid/") {
                app_id = Some(rest.to_string());
                break;
            }
        }
    }
    if app_id.is_none() {
        if let Some(idx) = cmdline.find("steam://rungameid/") {
            let after = &cmdline[idx + "steam://rungameid/".len()..];
            let trimmed: String = after
                .chars()
                .take_while(|c| c.is_ascii_digit())
                .collect();
            if !trimmed.is_empty() {
                app_id = Some(trimmed);
            }
        }
    }
    (app_id, None)
}

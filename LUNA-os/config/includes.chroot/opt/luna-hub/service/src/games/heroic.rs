//! Heroic games launcher detection. We look for `heroic`, `legendary`,
//! and processes with cmdlines containing `heroic-games-launcher`.

use std::fs;
use std::path::Path;

use crate::games::{GameHit, GameRuntime};

const HEROIC_PROCESS_HINTS: &[&str] = &[
    "heroic",
    "legendary",
    "heroic-games-launcher",
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
        let cmdline = read_cmdline(pid).unwrap_or_default();

        let mut source: Option<&str> = None;
        for hint in HEROIC_PROCESS_HINTS {
            if comm.to_ascii_lowercase().contains(&hint.to_ascii_lowercase())
                || cmdline.to_ascii_lowercase().contains(&hint.to_ascii_lowercase())
            {
                source = Some("heroic");
                break;
            }
        }
        let Some(source) = source else { continue };

        // Heroic passes --appName= or -a, with Legendary CLI: `launch <appName>`.
        let app_id = extract_app_id(&cmdline);
        let title = extract_title(&cmdline);

        hits.push(GameHit {
            source: source.to_string(),
            app_id,
            title,
            pid,
            runtime: GameRuntime::Heroic,
        });
    }
    hits
}

fn read_comm(pid: u32) -> Option<String> {
    fs::read_to_string(Path::new("/proc").join(pid.to_string()).join("comm"))
        .ok()
        .map(|s| s.trim().to_string())
        .filter(|s| !s.is_empty())
}

fn read_cmdline(pid: u32) -> Option<String> {
    let raw = fs::read_to_string(Path::new("/proc").join(pid.to_string()).join("cmdline")).ok()?;
    let bytes = raw.bytes().collect::<Vec<u8>>();
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

fn extract_app_id(cmdline: &str) -> Option<String> {
    for token in cmdline.split_whitespace() {
        if let Some(rest) = token
            .strip_prefix("--appName=")
            .or_else(|| token.strip_prefix("-a="))
        {
            if !rest.is_empty() {
                return Some(rest.to_string());
            }
        }
    }
    None
}

fn extract_title(cmdline: &str) -> Option<String> {
    for token in cmdline.split_whitespace() {
        if let Some(rest) = token.strip_prefix("--appTitle=") {
            return Some(rest.to_string());
        }
    }
    None
}

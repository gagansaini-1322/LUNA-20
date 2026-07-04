//! Lutris detection. Lutris is a Python app that spawns game-launched
//! children `lutris-wrapper`, `wine`, `wine-preloader`, `wine64-preloader`,
//! etc. Many of those processes are running when a game is active.

use std::fs;
use std::path::Path;

use crate::games::{GameHit, GameRuntime};

const LUTRIS_HINTS: &[&str] = &[
    "lutris-wrapper",
    "lutris",
    "wine",
    "wine-preloader",
    "wine64-preloader",
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

        if !looks_like_lutris(&comm, &cmdline) {
            continue;
        }
        let app_id = extract_lutris_slug(&cmdline);
        let title = extract_lutris_title(&cmdline);

        hits.push(GameHit {
            source: "lutris".to_string(),
            app_id,
            title,
            pid,
            runtime: GameRuntime::Lutris,
        });
    }
    hits
}

fn looks_like_lutris(comm: &str, cmdline: &str) -> bool {
    let c = comm.to_ascii_lowercase();
    for hint in LUTRIS_HINTS {
        let h = hint.to_ascii_lowercase();
        if c == h
            || c.starts_with(&format!("{h}-"))
            || c.contains(&format!("-{h}"))
            || cmdline.to_ascii_lowercase().contains(&format!("lutris-{hint}"))
        {
            if c.contains("lutris") || cmdline.to_ascii_lowercase().contains("lutris") {
                return true;
            }
        }
    }
    false
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

fn extract_lutris_slug(cmdline: &str) -> Option<String> {
    let lower = cmdline.to_ascii_lowercase();
    if let Some(idx) = lower.find("lutris:") {
        let after = &lower[idx + "lutris:".len()..];
        let slug: String = after
            .chars()
            .take_while(|c| *c != ' ' && *c != '/' && *c != '\n')
            .collect();
        if !slug.is_empty() && slug.chars().all(|c| c.is_ascii_alphanumeric() || c == '-' || c == '_') {
            return Some(slug);
        }
    }
    if let Some(idx) = cmdline.find("--slug=") {
        let after = &cmdline[idx + "--slug=".len()..];
        let slug: String = after
            .chars()
            .take_while(|c| *c != ' ' && *c != '\n')
            .collect();
        if !slug.is_empty() {
            return Some(slug);
        }
    }
    None
}

fn extract_lutris_title(cmdline: &str) -> Option<String> {
    if let Some(idx) = cmdline.find("--title=") {
        let after = &cmdline[idx + "--title=".len()..];
        let title: String = after
            .chars()
            .take_while(|c| *c != ' ' && *c != '\n')
            .collect();
        if !title.is_empty() {
            return Some(title);
        }
    }
    None
}

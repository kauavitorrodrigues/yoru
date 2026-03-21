# Yoru

<div align="center">

### A minimal desktop shell for Wayland

Built with [Quickshell](https://quickshell.org/)

[![License](https://img.shields.io/badge/license-MIT-9ccbfb?style=for-the-badge&labelColor=101418&color=FFFFFF)](LICENSE)

</div>

Yoru is a custom desktop shell for [Hyprland](https://hyprland.org/), built entirely in QML using the Quickshell framework. It provides a clean top bar, an application dock, and a music player widget with audio visualization.

## Screenshots

<div align="center">

| Overview | Player widget |
|:---:|:---:|
| <img src="assets/screenshots/overview.png" alt="Overview" /> | <img src="assets/screenshots/player.png" alt="Player" /> |

</div>

## Repository Structure

```
yoru/
├── shell.qml           # Main entry point
├── modules/            # UI components
│   ├── topbar/         # Top system bar and widgets
│   ├── dock/           # Application dock
│   ├── player/         # Music player widget
│   └── common/         # Shared utilities and algorithms
└── services/           # Singleton state managers
    ├── PlayerService.qml   # MPRIS media state + CAVA integration
    ├── AppSearch.qml       # App discovery and icon resolution
    └── TaskbarApps.qml     # Open window tracking
```

## Features

**Top Bar**
System panel with workspace switcher, clock, RAM usage, network status, and volume control. Volume adjusts with the scroll wheel; left-click opens pavucontrol, right-click opens pw-top.

**Application Dock**
Shows all open applications with window count indicator dots. Left-click cycles through windows; middle-click launches a new instance.

**Music Player**
MPRIS-based player widget for Spotify with album art, scrolling track info, playback controls, a progress bar, and a live audio waveform powered by [CAVA](https://github.com/karlstav/cava).

**App Search**
Fuzzy application search using FuzzySort with a smart icon resolution fallback chain — handles mismatched app IDs, Steam games, and more.

**Workspace Switching**
Hyprland workspace integration with numbered buttons (1–9) dispatched over IPC.

## Installation

> **Arch Linux only** for now.

Clone the repo and run the install script:

```bash
git clone https://github.com/kauavitorrodrigues/yoru
cd yoru
./install.sh
```

The script will:

1. Install `yay` if not present
2. Install all required packages via `pacman` and `yay`
3. Create a persistent virtual **Spotify Sink** in PipeWire — Spotify routes here so CAVA can capture it in isolation, and a loopback forwards the audio back to your real output so you can still hear it
4. Add a WirePlumber rule that automatically routes Spotify to that sink on launch
5. Copy the CAVA config to `~/.config/cava/configs/yoru.conf`
6. Symlink the repo to `~/.config/quickshell/yoru`

Then start Yoru:

```bash
quickshell -p ~/.config/quickshell/yoru
```

Or add it to `hyprland.conf` to launch on startup:

```ini
exec-once = quickshell -p ~/.config/quickshell/yoru
```

### Audio visualization note

After the first Spotify launch post-install, WirePlumber should automatically route it to the **Yoru Spotify Sink**. You should hear audio normally and see the waveform in the player widget.

If something doesn't work:

- **No waveform / can't hear Spotify** — open `pavucontrol`, go to the **Playback** tab, and manually set Spotify's output to *Yoru Spotify Sink*. The loopback will then forward it to your real output.
- **Waveform works but no sound** — the loopback may not have linked correctly. Re-run `./install.sh` and restart Spotify.

> WirePlumber 0.5+ is required for the automatic routing rule. Older setups will need the manual `pavucontrol` step.

## Dependencies

The install script handles all of these automatically on Arch.

| Package | Source | Purpose |
|---------|--------|---------|
| `quickshell-git` | AUR (`yay`) | Shell framework |
| `pipewire` | pacman | Audio backend |
| `wireplumber` | pacman | PipeWire session manager |
| `pipewire-pulse` | pacman | PulseAudio compatibility layer |
| `cava` | pacman | Audio visualizer (waveform) |

**Also required (install manually):**
- [Hyprland](https://hyprland.org/) — Wayland compositor
- `pavucontrol` — volume control GUI
- `foot` — terminal (used for pw-top shortcut)
- JetBrainsMono Nerd Font

## Structure Details

### Modules

| Module | Description |
|--------|-------------|
| `modules/topbar/` | Top bar container and all system widgets |
| `modules/dock/` | Dock with open app list and per-app buttons |
| `modules/player/` | Full player UI — album, info, controls, waveform |
| `modules/common/` | FuzzySort and Levenshtein distance algorithms, date utilities |

### Services

| Service | Description |
|---------|-------------|
| `PlayerService.qml` | Tracks MPRIS state (title, artist, art, play state), runs CAVA subprocess for waveform data at ~60fps |
| `AppSearch.qml` | Fuzzy app search with multi-step icon guessing fallback |
| `TaskbarApps.qml` | Maintains a live map of open windows grouped by app ID |

## Copying

Feel free to copy, modify, and redistribute anything here. Use whatever you find useful — components, logic, structure, all of it.

The only requirement is to keep the copyright notice when distributing substantial portions of the code. See [LICENSE](LICENSE) for the full MIT terms.

## Credits

- [Quickshell](https://quickshell.org/) — shell framework
- [CAVA](https://github.com/karlstav/cava) — console audio visualizer
- [FuzzySort](https://github.com/farzher/fuzzysort) — fuzzy search algorithm
- [end-4](https://github.com/end-4) — dock base derived from [dots-hyprland](https://github.com/end-4/dots-hyprland)

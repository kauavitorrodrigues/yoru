#!/bin/bash
# Yoru — install script
# Arch Linux only. Sets up dependencies, virtual Spotify sink, CAVA config,
# and Quickshell integration.

set -euo pipefail

YORU_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
QS_DIR="$HOME/.config/quickshell/yoru"
YORU_CONF_DIR="$HOME/.config/yoru"
YORU_SETTINGS_FILE="$YORU_CONF_DIR/settings.json"
CAVA_CONF="$HOME/.config/cava/configs/yoru.conf"
PW_CONF_DIR="$HOME/.config/pipewire/pipewire.conf.d"
WP_CONF_DIR="$HOME/.config/wireplumber/wireplumber.conf.d"

# ── colors ────────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
ok()   { echo -e "${GREEN}  ✔${NC}  $*"; }
warn() { echo -e "${YELLOW}  !${NC}  $*"; }
err()  { echo -e "${RED}  ✘${NC}  $*"; exit 1; }
step() { echo -e "\n${GREEN}▶${NC}  $*"; }

# ── arch check ────────────────────────────────────────────────────────────────
check_arch() {
    if ! command -v pacman &>/dev/null; then
        err "Yoru currently only supports Arch Linux."
    fi
}

# ── install dependencies ──────────────────────────────────────────────────────
install_deps() {
    step "Installing dependencies"

    # yay is required for AUR packages
    if ! command -v yay &>/dev/null; then
        warn "yay not found — installing yay from AUR"
        local tmp
        tmp=$(mktemp -d)
        git clone https://aur.archlinux.org/yay.git "$tmp/yay"
        (cd "$tmp/yay" && makepkg -si --noconfirm)
        rm -rf "$tmp"
        ok "yay installed"
    else
        ok "yay"
    fi

    # pacman packages
    local pacman_pkgs=(pipewire wireplumber pipewire-pulse cava)
    local to_install=()
    for pkg in "${pacman_pkgs[@]}"; do
        if pacman -Q "$pkg" &>/dev/null; then
            ok "$pkg"
        else
            to_install+=("$pkg")
        fi
    done
    if (( ${#to_install[@]} )); then
        step "Installing via pacman: ${to_install[*]}"
        sudo pacman -S --needed --noconfirm "${to_install[@]}"
    fi

    # quickshell from AUR
    if command -v quickshell &>/dev/null; then
        ok "quickshell"
    else
        step "Installing quickshell-git from AUR"
        yay -S --needed --noconfirm quickshell-git
        ok "quickshell"
    fi
}

# ── virtual spotify sink (pipewire) ───────────────────────────────────────────
setup_sink() {
    step "Creating virtual Spotify sink"
    mkdir -p "$PW_CONF_DIR"
    cat > "$PW_CONF_DIR/yoru-spotify-sink.conf" <<'EOF'
# Yoru — virtual sink for isolated Spotify audio capture + loopback to speakers
context.objects = [
  { factory = adapter
    args = {
      factory.name     = support.null-audio-sink
      node.name        = spotify_sink
      node.description = "Yoru Spotify Sink"
      media.class      = Audio/Sink
      audio.position   = [FL FR]
    }
  }
]

context.modules = [
  { name = libpipewire-module-loopback
    args = {
      capture.props = {
        node.name           = "capture.yoru_spotify_loopback"
        audio.position      = [FL FR]
        node.target         = "spotify_sink"
        stream.capture.sink = true
      }
      playback.props = {
        node.name        = "playback.yoru_spotify_loopback"
        node.passive     = true
        audio.position   = [FL FR]
      }
    }
  }
]
EOF
    ok "PipeWire config written → $PW_CONF_DIR/yoru-spotify-sink.conf"
}

# ── wireplumber rule: auto-route spotify → virtual sink ───────────────────────
setup_routing() {
    step "Setting up Spotify auto-routing (WirePlumber)"
    mkdir -p "$WP_CONF_DIR"
    cat > "$WP_CONF_DIR/51-yoru-spotify-routing.conf" <<'EOF'
# Yoru — route any Spotify stream to the virtual spotify_sink
wireplumber.settings = {}

monitor.bluez.rules = []

wireplumber.components = []

wireplumber.profiles = {
  main = {}
}

# Intercept node creation and set target for Spotify streams
stream.rules = [
  {
    matches = [
      { application.name = "Spotify" }
      { application.name = "spotify" }
      { application.process.binary = "spotify" }
    ]
    actions = {
      modify-props = {
        target.object = "spotify_sink"
      }
    }
  }
]
EOF
    ok "WirePlumber routing rule written → $WP_CONF_DIR/51-yoru-spotify-routing.conf"
}

# ── restart pipewire stack ────────────────────────────────────────────────────
restart_audio() {
    step "Restarting PipeWire / WirePlumber"
    systemctl --user restart pipewire pipewire-pulse wireplumber 2>/dev/null || {
        warn "Could not restart via systemctl. You may need to log out and back in."
        return
    }
    sleep 2

    if pactl list sinks short 2>/dev/null | grep -q "spotify_sink"; then
        ok "spotify_sink is active"
    else
        warn "Sink not visible yet — it should appear after re-login if it's not here."
    fi
}

# ── cava config ───────────────────────────────────────────────────────────────
setup_cava() {
    step "Installing CAVA config"
    mkdir -p "$(dirname "$CAVA_CONF")"
    cp "$YORU_DIR/.config/cava/cava.conf" "$CAVA_CONF"
    ok "CAVA config → $CAVA_CONF"
}

# ── symlink shell ─────────────────────────────────────────────────────────────
setup_shell() {
    step "Linking Yoru to Quickshell config dir"
    mkdir -p "$(dirname "$QS_DIR")"
    if [[ -e "$QS_DIR" || -L "$QS_DIR" ]]; then
        rm -rf "$QS_DIR"
    fi
    ln -s "$YORU_DIR" "$QS_DIR"
    ok "Linked $YORU_DIR → $QS_DIR"
}

# ── yoru settings ─────────────────────────────────────────────────────────────
setup_settings() {
    step "Preparing Yoru settings storage"
    mkdir -p "$YORU_CONF_DIR"

    if [[ ! -f "$YORU_SETTINGS_FILE" ]]; then
        cat > "$YORU_SETTINGS_FILE" <<'EOF'
{
    "dock": {
        "pinnedApps": []
    }
}
EOF
        ok "Created settings file → $YORU_SETTINGS_FILE"
    else
        ok "Settings file already exists → $YORU_SETTINGS_FILE"
    fi
}

# ── run ───────────────────────────────────────────────────────────────────────
echo -e "\n${GREEN}Yoru installer${NC}"
echo "────────────────────────────────────────"

check_arch
install_deps
setup_sink
setup_routing
restart_audio
setup_cava
setup_shell
setup_settings

echo -e "\n${GREEN}────────────────────────────────────────${NC}"
echo -e "${GREEN}  Done!${NC}  Start Yoru with:\n"
echo -e "    quickshell -p \"$QS_DIR\"\n"
echo -e "  Or set it as your Hyprland shell in hyprland.conf:\n"
echo -e "    exec-once = quickshell -p \"$QS_DIR\"\n"
echo -e "  NOTE: Open Spotify, then check Sound settings (pavucontrol)"
echo -e "  and make sure its output is set to 'Yoru Spotify Sink'."
echo -e "  WirePlumber should do this automatically on next Spotify launch.\n"
echo -e "  Dock pins are persisted in: $YORU_SETTINGS_FILE\n"

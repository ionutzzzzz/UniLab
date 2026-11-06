#!/usr/bin/env bash
set -uo pipefail

# Colors for clean logging
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# --- Path Resolution ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
BACKEND_SCRIPT="$SCRIPT_DIR/backend/UniLab.py"
FRONTEND_DIR="$SCRIPT_DIR/frontend"
BG_SERVER_PID=""

cleanup() {
    if [ -n "$BG_SERVER_PID" ] && kill -0 "$BG_SERVER_PID" 2>/dev/null; then
        log_info "Stopping background backend server (PID $BG_SERVER_PID)..."
        kill "$BG_SERVER_PID" 2>/dev/null || true
    fi
}
trap cleanup EXIT INT TERM

check_internet() {
    log_info "Checking for internet connection..."

    if command -v curl >/dev/null 2>&1; then
        if curl -s --head --connect-timeout 2 https://www.google.com >/dev/null 2>&1; then
            log_success "Internet connection active (cURL)."
            return 0
        fi
    fi

    if command -v timeout >/dev/null 2>&1; then
        if timeout 2 bash -c '</dev/tcp/8.8.8.8/53' >/dev/null 2>&1; then
            log_success "Internet connection active (Bash TCP socket)."
            return 0
        fi
    fi

    log_warn "No internet connection detected."
    return 1
}

check_gui_availability() {
    log_info "Checking for available GUI environments..."

    if [[ "$(uname -s)" == "Darwin" ]]; then
        if [ -z "${SSH_CONNECTION:-}" ]; then
            log_success "Detected macOS Aqua desktop session."
            return 0
        fi
    fi

    if [ -n "${DISPLAY:-}" ]; then
        log_success "Found X11 display target: $DISPLAY"
        return 0
    fi

    if [ -n "${WAYLAND_DISPLAY:-}" ]; then
        log_success "Found Wayland display target: $WAYLAND_DISPLAY"
        return 0
    fi

    if command -v xset >/dev/null 2>&1 && xset q >/dev/null 2>&1; then
        log_success "X server is active and responding."
        return 0
    fi

    if command -v loginctl >/dev/null 2>&1; then
        if loginctl list-sessions --no-legend 2>/dev/null | awk '{print $1}' | xargs -I {} loginctl show-session {} 2>/dev/null | grep -q "Seat=seat0"; then
            log_success "Active graphical seat (seat0) detected via loginctl."
            return 0
        fi
    fi

    return 1
}

detect_flutter_device() {
    case "$(uname -s)" in
        Darwin*) echo "macos" ;;
        Linux*)  echo "linux" ;;
        MINGW*|MSYS*|CYGWIN*) echo "windows" ;;
        *)       echo "linux" ;;
    esac
}

# 1. Check internet and optionally host the web app
if [ -t 0 ] && check_internet; then
    echo -e -n "${BLUE}[PROMPT]${NC} Do you want to host the Flutter web app on port 8081? [y/N]: "
    host_web_choice=""
    read -r -t 10 host_web_choice || true
    echo ""

    if [[ "$host_web_choice" =~ ^[Yy]$ ]]; then
        log_info "Web hosting selected."

        log_info "Starting FastAPI backend server on port 8000..."
        (cd "$SCRIPT_DIR" && PYTHONPATH="$SCRIPT_DIR" UNILAB_API_SERVER=1 MPLBACKEND=Agg python3 -m uvicorn backend.api.main:app --host 127.0.0.1 --port 8000) &
        BG_SERVER_PID=$!

        if [ -d "$FRONTEND_DIR" ]; then
            cd "$FRONTEND_DIR" || exit 1
            if command -v flutter >/dev/null 2>&1; then
                log_info "Building Flutter web app..."
                flutter build web && \
                log_success "Hosting web app at http://localhost:8081" && \
                python3 -m http.server 8081 --directory build/web
                exit 0
            else
                log_warn "Flutter SDK not found! Cannot build the web app."
                exit 1
            fi
        else
            log_warn "Frontend directory $FRONTEND_DIR not found!"
            exit 1
        fi
    else
        log_info "Skipping web hosting..."
    fi
fi

# 2. Standard GUI / Headless Logic
if check_gui_availability; then
    TARGET_DEVICE="$(detect_flutter_device)"
    log_success "GUI detected! Launching Flutter application (-d $TARGET_DEVICE)..."

    if [ -d "$FRONTEND_DIR" ] && command -v flutter >/dev/null 2>&1; then
        cd "$FRONTEND_DIR" || exit 1
        exec flutter run -d "$TARGET_DEVICE"
    else
        log_warn "Flutter SDK or frontend not available. Falling back to Python CLI..."
        if [ -f "$BACKEND_SCRIPT" ]; then
            exec env PYTHONPATH="$SCRIPT_DIR" python3 "$BACKEND_SCRIPT"
        else
            log_warn "Backend script $BACKEND_SCRIPT not found!"
            exit 1
        fi
    fi
else
    log_warn "No GUI or active Display Server detected (Headless/SSH environment)."
    log_info "Launching Python CLI instead..."

    if [ -f "$BACKEND_SCRIPT" ]; then
        exec env PYTHONPATH="$SCRIPT_DIR" python3 "$BACKEND_SCRIPT"
    else
        log_warn "Backend script $BACKEND_SCRIPT not found!"
        exit 1
    fi
fi

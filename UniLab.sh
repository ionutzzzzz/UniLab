#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
# set -e

# Colors for clean logging
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

check_gui_availability() {
    log_info "Checking for available GUI environments..."

    # 1. Check DISPLAY variable (X11)
    if [ -n "$DISPLAY" ]; then
        log_success "Found X11 display target: $DISPLAY"
        return 0
    fi

    # 2. Check WAYLAND_DISPLAY variable (Wayland)
    if [ -n "$WAYLAND_DISPLAY" ]; then
        log_success "Found Wayland display target: $WAYLAND_DISPLAY"
        return 0
    fi

    # 3. Check via xset (verifies if X server is actually reachable)
    if command -v xset >/dev/null 2>&1; then
        if xset q >/dev/null 2>&1; then
            log_success "X server is active and responding."
            return 0
        fi
    fi

    # 4. Check for active desktop environment sessions via loginctl
    if command -v loginctl >/dev/null 2>&1; then
        # Check if any active session has a graphical seat (like seat0)
        if loginctl list-sessions --no-legend | awk '{print $1}' | xargs -I {} loginctl show-session {} | grep -q "Seat=seat0"; then
            log_success "Active graphical seat (seat0) detected via loginctl."
            return 0
        fi
    fi

    # No GUI framework or display target found
    return 1
}

# --- Main Execution Flow ---

if check_gui_availability; then
    log_success "GUI detected! Launching Flutter application..."
    
    # Ensure the frontend directory exists
    if [ -d "frontend" ]; then
        cd frontend || exit 1
        
        # Check if flutter command is available
        if command -v flutter >/dev/null 2>&1; then
            flutter run -d linux
        else
            log_warn "Flutter SDK not found in PATH. Falling back to backend..."
            cd ..
            python3 ./backend/UniLab.py
        fi
    else
        log_warn "Directory 'frontend' not found! Cannot launch Flutter."
        exit 1
    fi
else
    log_warn "No GUI or active Display Server detected (Headless/SSH environment)."
    log_info "Launching Python backend instead..."
    
    # Ensure the backend script exists before running
    if [ -f "./backend/UniLab.py" ]; then
        python3 ./backend/UniLab.py
    else
        log_warn "Backend script ./backend/UniLab.py not found!"
        exit 1
    fi
fi
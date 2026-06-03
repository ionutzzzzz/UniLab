#!/usr/bin/env bash

# Colors for clean logging
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# --- Bulletproof Path Resolution ---
# Dynamically calculate the absolute path to the UniLab root folder
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
BACKEND_SCRIPT="$SCRIPT_DIR/backend/UniLab.py"
FRONTEND_DIR="$SCRIPT_DIR/frontend"

check_internet() {
    log_info "Checking for internet connection..."
    
    # Method 1: Pure Bash TCP Socket (Requires NO external tools, bypasses ICMP blocks)
    # Tries to reach Google DNS (8.8.8.8) on port 53 with a 2-second timeout
    if timeout 2 bash -c '</dev/tcp/8.8.8.8/53' >/dev/null 2>&1; then
        log_success "Internet connection active (Bash TCP socket)."
        return 0
    fi
    
    # Method 2: cURL (If installed)
    if command -v curl >/dev/null 2>&1; then
        if curl -s --head --connect-timeout 2 http://www.google.com >/dev/null 2>&1; then
            log_success "Internet connection active (cURL)."
            return 0
        fi
    fi

    log_warn "No internet connection detected."
    return 1
}

check_gui_availability() {
    log_info "Checking for available GUI environments..."

    if [ -n "$DISPLAY" ]; then
        log_success "Found X11 display target: $DISPLAY"
        return 0
    fi

    if [ -n "$WAYLAND_DISPLAY" ]; then
        log_success "Found Wayland display target: $WAYLAND_DISPLAY"
        return 0
    fi

    if command -v xset >/dev/null 2>&1; then
        if xset q >/dev/null 2>&1; then
            log_success "X server is active and responding."
            return 0
        fi
    fi

    if command -v loginctl >/dev/null 2>&1; then
        if loginctl list-sessions --no-legend | awk '{print $1}' | xargs -I {} loginctl show-session {} | grep -q "Seat=seat0"; then
            log_success "Active graphical seat (seat0) detected via loginctl."
            return 0
        fi
    fi

    return 1
}

# --- Main Execution Flow ---

# 1. Check internet and optionally host the web app
if check_internet; then
    echo -e -n "${BLUE}[PROMPT]${NC} Do you want to host the Flutter web app on port 8081? [y/N]: "
    read -r -t 10 host_web_choice
    echo "" # Add a newline after input
    
    if [[ "$host_web_choice" =~ ^[Yy]$ ]]; then
        log_info "Web hosting selected."
        
        # Start backend in the background using absolute path
        if [ -f "$BACKEND_SCRIPT" ]; then
            log_info "Starting Python backend in the background..."
            python3 "$BACKEND_SCRIPT" &
        else
            log_warn "Backend script $BACKEND_SCRIPT not found. Proceeding without it..."
        fi

        # Build and host frontend
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

# 2. Standard GUI / Headless Logic (Fallback)
if check_gui_availability; then
    log_success "GUI detected! Launching Flutter application..."
    
    if [ -d "$FRONTEND_DIR" ]; then
        cd "$FRONTEND_DIR" || exit 1
        
        if command -v flutter >/dev/null 2>&1; then
            flutter run -d linux
        else
            log_warn "Flutter SDK not found in PATH. Falling back to backend..."
            if [ -f "$BACKEND_SCRIPT" ]; then
                python3 "$BACKEND_SCRIPT"
            else
                log_warn "Backend script $BACKEND_SCRIPT not found!"
                exit 1
            fi
        fi
    else
        log_warn "Frontend directory $FRONTEND_DIR not found!"
        exit 1
    fi
else
    log_warn "No GUI or active Display Server detected (Headless/SSH environment)."
    log_info "Launching Python backend instead..."
    
    if [ -f "$BACKEND_SCRIPT" ]; then
        python3 "$BACKEND_SCRIPT"
    else
        log_warn "Backend script $BACKEND_SCRIPT not found!"
        exit 1
    fi
fi
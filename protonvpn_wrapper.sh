#!/bin/bash

_PROTONVPN_HELPER_UTILS_VERSION="1.0.0"
_PROTONVPN_KEEPALIVE_PID=""
_PROTONVPN_KEEPALIVE_LOG_FILE="/tmp/protonvpn_keepalive.log"
_PROTONVPN_PORT_FILE="/tmp/protonvpn_mapped_port"

protonvpn_help() {
    echo "ProtonVPN CLI Wrapper - Extended functionality for port forwarding keep-alive"
    echo "Version: $_PROTONVPN_HELPER_UTILS_VERSION"
    echo "Source: https://github.com/pjortiz/protonvpn-cli-wrapper"
    echo ""
    echo "Usage: protonvpn COMMAND [ARGS]..."
    echo ""
    echo "commands:"
    echo "  connect           (extended) Starts port-forwarding keep-alive in background after connecting"
    echo "  disconnect        (extended) Stops keep-alive before disconnecting"
    echo "  get-port          Print the current mapped port"
    echo "  keepalive-logs    Follow the live keep-alive log"
    echo "  keepalive-stop    Stop the keep-alive background process"
    echo ""
}

log_info() {
    echo "[$(date '+%T')] [$BASHPID] $1"
}

log_error() {
    echo -e "\a[$(date '+%T')] [$BASHPID] $1" >&2
}


protonvpn_keep_port() {
    local gateway="10.2.0.1"
    local initial_port=""
    local current_port=""

    log_info "Starting NAT-PMP port mapping renewal loop..."
    rm -f "$_PROTONVPN_PORT_FILE"

    while true; do
        local output
        output=$(natpmpc -a 1 0 udp 60 -g "$gateway" 2>&1 && natpmpc -a 1 0 tcp 60 -g "$gateway" 2>&1)

        if [ $? -ne 0 ]; then
            log_error "ERROR: natpmpc failed. VPN may have disconnected."
            rm -f "$_PROTONVPN_PORT_FILE"
            break
        fi

        current_port=$(echo "$output" | grep -oP 'Mapped public port \K\d{1,5}' | tail -1)

        if [ -z "$current_port" ]; then
            log_error "WARNING: Could not parse mapped port (port forwarding may not be enabled)."
            rm -f "$_PROTONVPN_PORT_FILE"
            break
        elif [ -z "$initial_port" ]; then
            initial_port="$current_port"
            echo "$current_port" > "$_PROTONVPN_PORT_FILE"
            log_info "Port mapped: $current_port"
        elif [ "$current_port" != "$initial_port" ]; then
            log_error "WARNING: Port changed! $initial_port -> $current_port"
            initial_port="$current_port"
            echo "$current_port" > "$_PROTONVPN_PORT_FILE"
        else
            log_info "Port OK: $current_port (renewal successful)"
        fi

        sleep 45
    done

    log_info "Port mapping loop exited."
}

protonvpn_kill_keepalive() {
    if [ -n "$_PROTONVPN_KEEPALIVE_PID" ] && kill -0 "$_PROTONVPN_KEEPALIVE_PID" 2>/dev/null; then
        log_info "Stopping keep-alive (PID: $_PROTONVPN_KEEPALIVE_PID)..." | tee -a "$_PROTONVPN_KEEPALIVE_LOG_FILE"
        kill "$_PROTONVPN_KEEPALIVE_PID"
        _PROTONVPN_KEEPALIVE_PID=""
    fi
    # Also catch orphans in case PID was lost (e.g. terminal was closed)
    pkill -f protonvpn_keep_port 2>/dev/null
    rm -f "$_PROTONVPN_PORT_FILE"
}

protonvpn() {
    case "$1" in
        connect)
            command protonvpn connect "${@:2}"
            local exit_code=$?

            if [ $exit_code -eq 0 ]; then
                # Kill any existing keep-alive first
                protonvpn_kill_keepalive

                protonvpn_keep_port >> "$_PROTONVPN_KEEPALIVE_LOG_FILE" 2>&1 &
                _PROTONVPN_KEEPALIVE_PID=$!
                disown $_PROTONVPN_KEEPALIVE_PID
                log_info "Keep-alive started in background (PID: $_PROTONVPN_KEEPALIVE_PID) — run 'protonvpn keepalive-logs' to follow"

                # Wait for port file to appear (up to 10 seconds)
                local waited=0
                while [ ! -f "$_PROTONVPN_PORT_FILE" ] && [ $waited -lt 10 ]; do
                    sleep 1
                    (( waited++ ))
                done

                if [ -f "$_PROTONVPN_PORT_FILE" ]; then
                    log_info "Mapped port: $(cat $_PROTONVPN_PORT_FILE)"
                else
                    log_error "WARNING: Port forwarding unavailable or timed out."
                fi
            fi

            return $exit_code
            ;;

        disconnect)
            protonvpn_kill_keepalive
            command protonvpn disconnect
            ;;

        get-port)
            cat "$_PROTONVPN_PORT_FILE" 2>/dev/null || echo "No port mapped."
            ;;

        keepalive-logs)
            tail -f "$_PROTONVPN_KEEPALIVE_LOG_FILE"
            ;;

        keepalive-stop)
            protonvpn_kill_keepalive
            ;;

        --help|-h)
            command protonvpn --help 2>&1
            echo ""
            echo "*********************************************************************************"
            echo ""
            protonvpn_help
            ;;

        *)
            command protonvpn "$@"
            ;;
    esac
}



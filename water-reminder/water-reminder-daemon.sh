#!/bin/bash

# Water Reminder Daemon Wrapper
# Runs the water reminder in the background as a daemon

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default configuration
PID_FILE="$HOME/.local/share/water-reminder/water-reminder.pid"
LOG_FILE="$HOME/.local/share/water-reminder/water-reminder.log"

# Load configuration if it exists
CONFIG_FILE="$SCRIPT_DIR/config.conf"
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
fi

# Main water reminder script
MAIN_SCRIPT="$SCRIPT_DIR/water-reminder.sh"

# Function to log messages
log_message() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Create log directory if it doesn't exist
    mkdir -p "$(dirname "$LOG_FILE")"
    
    echo "[$timestamp] [DAEMON] $message" >> "$LOG_FILE"
}

# Function to check if daemon is running
is_running() {
    if [[ -f "$PID_FILE" ]]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            return 0
        else
            # Stale PID file
            rm -f "$PID_FILE"
            return 1
        fi
    fi
    return 1
}

# Function to start the daemon
start_daemon() {
    if is_running; then
        local pid=$(cat "$PID_FILE")
        echo "Water reminder daemon is already running (PID: $pid)"
        return 1
    fi
    
    # Check if main script exists
    if [[ ! -f "$MAIN_SCRIPT" ]]; then
        echo "Error: Main script not found at $MAIN_SCRIPT"
        log_message "ERROR: Main script not found at $MAIN_SCRIPT"
        return 1
    fi
    
    # Check if main script is executable
    if [[ ! -x "$MAIN_SCRIPT" ]]; then
        echo "Error: Main script is not executable"
        log_message "ERROR: Main script is not executable"
        return 1
    fi
    
    # Create PID directory if it doesn't exist
    mkdir -p "$(dirname "$PID_FILE")"
    
    # Start the main script in background
    log_message "Starting water reminder daemon"
    nohup "$MAIN_SCRIPT" "$@" > /dev/null 2>&1 &
    local pid=$!
    
    # Save PID
    echo "$pid" > "$PID_FILE"
    
    # Wait a moment to check if the process started successfully
    sleep 2
    if kill -0 "$pid" 2>/dev/null; then
        echo "Water reminder daemon started successfully (PID: $pid)"
        log_message "Daemon started successfully (PID: $pid)"
        return 0
    else
        echo "Failed to start water reminder daemon"
        log_message "ERROR: Failed to start daemon"
        rm -f "$PID_FILE"
        return 1
    fi
}

# Function to stop the daemon
stop_daemon() {
    if ! is_running; then
        echo "Water reminder daemon is not running"
        return 1
    fi
    
    local pid=$(cat "$PID_FILE")
    log_message "Stopping water reminder daemon (PID: $pid)"
    
    # Try graceful shutdown first
    if kill -TERM "$pid" 2>/dev/null; then
        # Wait up to 10 seconds for graceful shutdown
        local count=0
        while [[ $count -lt 10 ]] && kill -0 "$pid" 2>/dev/null; do
            sleep 1
            ((count++))
        done
        
        # If still running, force kill
        if kill -0 "$pid" 2>/dev/null; then
            echo "Graceful shutdown failed, forcing termination..."
            log_message "Graceful shutdown failed, forcing termination"
            kill -KILL "$pid" 2>/dev/null
        fi
    fi
    
    # Clean up PID file
    rm -f "$PID_FILE"
    echo "Water reminder daemon stopped"
    log_message "Daemon stopped"
    return 0
}

# Function to restart the daemon
restart_daemon() {
    echo "Restarting water reminder daemon..."
    stop_daemon
    sleep 2
    start_daemon "$@"
}

# Function to show daemon status
show_status() {
    if is_running; then
        local pid=$(cat "$PID_FILE")
        echo "Water reminder daemon is running (PID: $pid)"
        
        # Show process information
        if command -v ps &> /dev/null; then
            echo "Process details:"
            ps -p "$pid" -o pid,ppid,user,start,time,command 2>/dev/null || echo "Process details unavailable"
        fi
        
        # Show log tail if available
        if [[ -f "$LOG_FILE" ]]; then
            echo ""
            echo "Recent log entries:"
            tail -5 "$LOG_FILE" 2>/dev/null || echo "Log file unavailable"
        fi
        
        return 0
    else
        echo "Water reminder daemon is not running"
        return 1
    fi
}

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 {start|stop|restart|status} [OPTIONS]

Commands:
    start       Start the water reminder daemon
    stop        Stop the water reminder daemon
    restart     Restart the water reminder daemon
    status      Show daemon status

Options (for start/restart):
    -i, --interval MINUTES  Set reminder interval in minutes
    -s, --sound on|off      Enable/disable sound notifications
    -l, --log FILE          Set log file path

Examples:
    $0 start                    # Start daemon with default settings
    $0 start -i 45              # Start with 45-minute intervals
    $0 stop                     # Stop the daemon
    $0 restart -s off           # Restart with sounds disabled
    $0 status                   # Check daemon status

Files:
    PID file: $PID_FILE
    Log file: $LOG_FILE
    Config:   $CONFIG_FILE

EOF
}

# Handle system signals
handle_signal() {
    log_message "Received signal, shutting down daemon"
    stop_daemon
    exit 0
}

# Set up signal handlers
trap handle_signal SIGTERM SIGINT

# Main script logic
case "$1" in
    start)
        shift
        start_daemon "$@"
        ;;
    stop)
        stop_daemon
        ;;
    restart)
        shift
        restart_daemon "$@"
        ;;
    status)
        show_status
        ;;
    *)
        echo "Error: Invalid command '$1'"
        echo ""
        show_usage
        exit 1
        ;;
esac

exit $?
#!/bin/bash

# Water Reminder Control Script
# Unified interface to start, stop, and manage the water reminder service

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default configuration
PID_FILE="$HOME/.local/share/water-reminder/water-reminder.pid"
LOG_FILE="$HOME/.local/share/water-reminder/water-reminder.log"
CONFIG_FILE="$SCRIPT_DIR/config.conf"

# Load configuration if it exists
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
fi

# Daemon script
DAEMON_SCRIPT="$SCRIPT_DIR/water-reminder-daemon.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
print_message() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${NC}"
}

# Function to check if daemon script exists
check_daemon_script() {
    if [[ ! -f "$DAEMON_SCRIPT" ]]; then
        print_message "$RED" "Error: Daemon script not found at $DAEMON_SCRIPT"
        return 1
    fi
    
    if [[ ! -x "$DAEMON_SCRIPT" ]]; then
        print_message "$RED" "Error: Daemon script is not executable"
        return 1
    fi
    
    return 0
}

# Function to start the service
start_service() {
    print_message "$BLUE" "Starting water reminder service..."
    
    if ! check_daemon_script; then
        return 1
    fi
    
    "$DAEMON_SCRIPT" start "$@"
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        print_message "$GREEN" "✓ Water reminder service started successfully"
    else
        print_message "$RED" "✗ Failed to start water reminder service"
    fi
    
    return $exit_code
}

# Function to stop the service
stop_service() {
    print_message "$BLUE" "Stopping water reminder service..."
    
    if ! check_daemon_script; then
        return 1
    fi
    
    "$DAEMON_SCRIPT" stop
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        print_message "$GREEN" "✓ Water reminder service stopped successfully"
    else
        print_message "$YELLOW" "! Water reminder service was not running"
    fi
    
    return $exit_code
}

# Function to restart the service
restart_service() {
    print_message "$BLUE" "Restarting water reminder service..."
    
    if ! check_daemon_script; then
        return 1
    fi
    
    "$DAEMON_SCRIPT" restart "$@"
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        print_message "$GREEN" "✓ Water reminder service restarted successfully"
    else
        print_message "$RED" "✗ Failed to restart water reminder service"
    fi
    
    return $exit_code
}

# Function to show service status
show_status() {
    if ! check_daemon_script; then
        return 1
    fi
    
    print_message "$BLUE" "Water Reminder Service Status"
    echo "================================"
    
    "$DAEMON_SCRIPT" status
    local exit_code=$?
    
    echo ""
    echo "Configuration:"
    echo "  Config file: $CONFIG_FILE"
    echo "  PID file: $PID_FILE"
    echo "  Log file: $LOG_FILE"
    
    if [[ -f "$CONFIG_FILE" ]]; then
        echo "  Reminder interval: ${REMINDER_INTERVAL:-30} minutes"
        echo "  Sound enabled: ${SOUND_ENABLED:-true}"
    fi
    
    return $exit_code
}

# Function to show logs
show_logs() {
    local lines="${1:-20}"
    
    if [[ ! -f "$LOG_FILE" ]]; then
        print_message "$YELLOW" "Log file not found: $LOG_FILE"
        return 1
    fi
    
    print_message "$BLUE" "Recent log entries (last $lines lines):"
    echo "========================================"
    tail -n "$lines" "$LOG_FILE"
}

# Function to follow logs in real-time
follow_logs() {
    if [[ ! -f "$LOG_FILE" ]]; then
        print_message "$YELLOW" "Log file not found: $LOG_FILE"
        print_message "$BLUE" "Waiting for log file to be created..."
    fi
    
    print_message "$BLUE" "Following water reminder logs (Press Ctrl+C to exit):"
    echo "=================================================="
    tail -f "$LOG_FILE" 2>/dev/null
}

# Function to edit configuration
edit_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        print_message "$RED" "Configuration file not found: $CONFIG_FILE"
        return 1
    fi
    
    # Try different editors
    if command -v nano &> /dev/null; then
        nano "$CONFIG_FILE"
    elif command -v vim &> /dev/null; then
        vim "$CONFIG_FILE"
    elif command -v vi &> /dev/null; then
        vi "$CONFIG_FILE"
    else
        print_message "$RED" "No suitable text editor found (nano, vim, or vi)"
        print_message "$BLUE" "Configuration file location: $CONFIG_FILE"
        return 1
    fi
}

# Function to test notification
test_notification() {
    print_message "$BLUE" "Testing water reminder notification..."
    
    # Source the main script to get its functions
    if [[ -f "$SCRIPT_DIR/water-reminder.sh" ]]; then
        # Create a temporary script to test notification
        local test_script="/tmp/test-water-notification.sh"
        cat > "$test_script" << 'EOF'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$1" 2>/dev/null || true

# Override main function to just show one notification
main() {
    check_dependencies
    local message=$(get_random_message)
    show_notification "$message"
    echo "Test notification sent!"
}

main
EOF
        chmod +x "$test_script"
        "$test_script" "$SCRIPT_DIR/water-reminder.sh"
        rm -f "$test_script"
    else
        print_message "$RED" "Main water reminder script not found"
        return 1
    fi
}

# Function to show usage
show_usage() {
    cat << EOF
Water Reminder Control Script v1.0.0

Usage: $0 COMMAND [OPTIONS]

Commands:
    start [OPTIONS]     Start the water reminder service
    stop                Stop the water reminder service
    restart [OPTIONS]   Restart the water reminder service
    status              Show service status and information
    logs [LINES]        Show recent log entries (default: 20 lines)
    follow              Follow log output in real-time
    config              Edit configuration file
    test                Test notification functionality

Options (for start/restart):
    -i, --interval MIN  Set reminder interval in minutes
    -s, --sound on|off  Enable/disable sound notifications
    -l, --log FILE      Set log file path

Examples:
    $0 start                    # Start with default settings
    $0 start -i 45              # Start with 45-minute intervals
    $0 restart -s off           # Restart with sounds disabled
    $0 status                   # Check current status
    $0 logs 50                  # Show last 50 log entries
    $0 test                     # Test notification system

Configuration:
    Edit: $CONFIG_FILE
    
Environment:
    This script requires a Linux desktop environment with:
    - notify-send (libnotify)
    - Audio system (for sound notifications)

EOF
}

# Parse command line arguments
case "$1" in
    start)
        shift
        start_service "$@"
        ;;
    stop)
        stop_service
        ;;
    restart)
        shift
        restart_service "$@"
        ;;
    status)
        show_status
        ;;
    logs)
        shift
        show_logs "$1"
        ;;
    follow)
        follow_logs
        ;;
    config)
        edit_config
        ;;
    test)
        test_notification
        ;;
    -h|--help|help)
        show_usage
        exit 0
        ;;
    -v|--version|version)
        echo "Water Reminder Control Script v1.0.0"
        exit 0
        ;;
    "")
        print_message "$RED" "Error: No command specified"
        echo ""
        show_usage
        exit 1
        ;;
    *)
        print_message "$RED" "Error: Unknown command '$1'"
        echo ""
        show_usage
        exit 1
        ;;
esac

exit $?
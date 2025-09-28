#!/bin/bash

# Water Reminder Script
# Displays desktop notification reminders to drink water

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default configuration
REMINDER_INTERVAL=30
SOUND_ENABLED=true
LOG_FILE="$HOME/.local/share/water-reminder/water-reminder.log"
PID_FILE="$HOME/.local/share/water-reminder/water-reminder.pid"
ICON_PATH="$HOME/.local/share/water-reminder/icons/water-drop.png"
URGENCY="normal"
TIMEOUT=5000

# Default messages
MESSAGES=(
    "💧 Time to drink some water! Stay hydrated! 💧"
    "🚰 Don't forget to hydrate! Your body needs water! 🚰"
    "💦 Water break time! Keep yourself healthy! 💦"
    "🥤 Hydration reminder: Drink a glass of water now! 🥤"
    "💧 Your body is calling for water! Take a sip! 💧"
    "🌊 Stay refreshed! Time for some H2O! 🌊"
    "💦 Reminder: Keep your energy up with water! 💦"
    "🚰 Health tip: Drink water regularly throughout the day! 🚰"
)

# Load configuration if it exists
CONFIG_FILE="$SCRIPT_DIR/config.conf"
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
fi

# Function to log messages
log_message() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Create log directory if it doesn't exist
    mkdir -p "$(dirname "$LOG_FILE")"
    
    echo "[$timestamp] $message" >> "$LOG_FILE"
}

# Function to check if notify-send is available
check_dependencies() {
    if ! command -v notify-send &> /dev/null; then
        echo "Error: notify-send is not installed. Please install libnotify-bin or equivalent package."
        log_message "ERROR: notify-send not found"
        exit 1
    fi
}

# Function to get a random message
get_random_message() {
    local message_count=${#MESSAGES[@]}
    local random_index=$((RANDOM % message_count))
    echo "${MESSAGES[$random_index]}"
}

# Function to display notification
show_notification() {
    local message="$1"
    local notification_args=()
    
    # Add urgency level
    notification_args+=("-u" "$URGENCY")
    
    # Add timeout
    if [[ "$TIMEOUT" -gt 0 ]]; then
        notification_args+=("-t" "$TIMEOUT")
    fi
    
    # Add icon if it exists
    if [[ -f "$ICON_PATH" ]]; then
        notification_args+=("-i" "$ICON_PATH")
    fi
    
    # Add sound if enabled
    if [[ "$SOUND_ENABLED" == "true" ]]; then
        # Try to play a system sound
        if command -v paplay &> /dev/null && [[ -f "/usr/share/sounds/alsa/Front_Right.wav" ]]; then
            paplay "/usr/share/sounds/alsa/Front_Right.wav" 2>/dev/null &
        elif command -v aplay &> /dev/null && [[ -f "/usr/share/sounds/alsa/Front_Right.wav" ]]; then
            aplay "/usr/share/sounds/alsa/Front_Right.wav" 2>/dev/null &
        fi
    fi
    
    # Display notification
    notify-send "${notification_args[@]}" "Water Reminder" "$message"
    
    log_message "Notification sent: $message"
}

# Function to handle graceful shutdown
cleanup() {
    log_message "Water reminder stopped"
    exit 0
}

# Function to handle system suspend/resume
handle_suspend_resume() {
    log_message "System suspend/resume detected, continuing reminders"
}

# Main function
main() {
    log_message "Water reminder started (interval: ${REMINDER_INTERVAL} minutes)"
    
    # Set up signal handlers
    trap cleanup SIGTERM SIGINT
    trap handle_suspend_resume SIGUSR1
    
    # Check dependencies
    check_dependencies
    
    # Main loop
    while true; do
        # Get random message and show notification
        local message=$(get_random_message)
        show_notification "$message"
        
        # Wait for the specified interval (convert minutes to seconds)
        sleep $((REMINDER_INTERVAL * 60))
    done
}

# Show usage information
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    -i, --interval MINUTES  Set reminder interval in minutes (default: 30)
    -s, --sound on|off      Enable/disable sound notifications (default: on)
    -l, --log FILE          Set log file path
    -h, --help              Show this help message
    -v, --version           Show version information

Examples:
    $0                      # Start with default settings
    $0 -i 45               # Remind every 45 minutes
    $0 -s off              # Disable sounds
    $0 -i 20 -s on         # Remind every 20 minutes with sound

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--interval)
            REMINDER_INTERVAL="$2"
            shift 2
            ;;
        -s|--sound)
            if [[ "$2" == "on" || "$2" == "true" ]]; then
                SOUND_ENABLED=true
            elif [[ "$2" == "off" || "$2" == "false" ]]; then
                SOUND_ENABLED=false
            else
                echo "Error: Invalid sound option '$2'. Use 'on' or 'off'."
                exit 1
            fi
            shift 2
            ;;
        -l|--log)
            LOG_FILE="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        -v|--version)
            echo "Water Reminder v1.0.0"
            exit 0
            ;;
        *)
            echo "Error: Unknown option '$1'"
            show_usage
            exit 1
            ;;
    esac
done

# Validate interval
if ! [[ "$REMINDER_INTERVAL" =~ ^[0-9]+$ ]] || [[ "$REMINDER_INTERVAL" -lt 1 ]]; then
    echo "Error: Invalid interval '$REMINDER_INTERVAL'. Must be a positive integer."
    exit 1
fi

# Run the main function
main
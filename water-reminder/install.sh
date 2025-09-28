#!/bin/bash

# Water Reminder Installation Script
# Installs the water reminder system system-wide or for the current user

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Installation paths
SYSTEM_INSTALL_PATH="/usr/local/bin"
SYSTEM_SHARE_PATH="/usr/local/share/water-reminder"
USER_INSTALL_PATH="$HOME/.local/bin"
USER_SHARE_PATH="$HOME/.local/share/water-reminder"

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

# Function to check if running as root
is_root() {
    [[ $EUID -eq 0 ]]
}

# Function to check dependencies
check_dependencies() {
    local missing_deps=()
    
    # Check for notify-send
    if ! command -v notify-send &> /dev/null; then
        missing_deps+=("libnotify-bin")
    fi
    
    # Check for audio system (optional)
    if ! command -v paplay &> /dev/null && ! command -v aplay &> /dev/null; then
        print_message "$YELLOW" "Warning: No audio system found (paplay/aplay). Sound notifications will be disabled."
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        print_message "$RED" "Missing dependencies: ${missing_deps[*]}"
        print_message "$BLUE" "Please install them using:"
        print_message "$BLUE" "  Ubuntu/Debian: sudo apt-get install ${missing_deps[*]}"
        print_message "$BLUE" "  CentOS/RHEL: sudo yum install ${missing_deps[*]// /-}"
        print_message "$BLUE" "  Fedora: sudo dnf install ${missing_deps[*]// /-}"
        print_message "$BLUE" "  Arch: sudo pacman -S ${missing_deps[*]// /-}"
        return 1
    fi
    
    return 0
}

# Function to create water drop icon
create_water_icon() {
    local icon_path="$1"
    local icon_dir="$(dirname "$icon_path")"
    
    # Create icon directory
    mkdir -p "$icon_dir"
    
    # Create a simple SVG water drop icon and convert to PNG if possible
    local svg_content='<?xml version="1.0" encoding="UTF-8"?>
<svg width="64" height="64" viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="waterGradient" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#4FC3F7;stop-opacity:1" />
      <stop offset="50%" style="stop-color:#29B6F6;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#0288D1;stop-opacity:1" />
    </linearGradient>
  </defs>
  <path d="M32 8 C20 20, 8 28, 8 40 C8 48.84, 19.16 56, 32 56 C44.84 56, 56 48.84, 56 40 C56 28, 44 20, 32 8 Z" 
        fill="url(#waterGradient)" stroke="#0277BD" stroke-width="2"/>
  <ellipse cx="24" cy="36" rx="4" ry="6" fill="#B3E5FC" opacity="0.7"/>
  <circle cx="40" cy="42" r="2" fill="#E1F5FE" opacity="0.8"/>
</svg>'
    
    # Try to convert SVG to PNG using available tools
    if command -v convert &> /dev/null; then
        # ImageMagick
        echo "$svg_content" | convert svg:- "$icon_path" 2>/dev/null
    elif command -v rsvg-convert &> /dev/null; then
        # librsvg
        echo "$svg_content" | rsvg-convert -w 64 -h 64 -o "$icon_path" 2>/dev/null
    elif command -v inkscape &> /dev/null; then
        # Inkscape
        local temp_svg="/tmp/water-drop.svg"
        echo "$svg_content" > "$temp_svg"
        inkscape "$temp_svg" --export-png="$icon_path" --export-width=64 --export-height=64 2>/dev/null
        rm -f "$temp_svg"
    else
        # Fallback: create a simple text-based icon (not ideal but works)
        print_message "$YELLOW" "Warning: No SVG conversion tool found. Creating fallback icon."
        
        # Create a simple blue square as fallback
        if command -v convert &> /dev/null; then
            convert -size 64x64 xc:"#29B6F6" "$icon_path" 2>/dev/null
        else
            # Create placeholder file
            echo "Water Drop Icon Placeholder" > "${icon_path}.txt"
            print_message "$YELLOW" "Created placeholder icon file: ${icon_path}.txt"
            return 1
        fi
    fi
    
    if [[ -f "$icon_path" ]]; then
        print_message "$GREEN" "✓ Created water drop icon: $icon_path"
        return 0
    else
        print_message "$YELLOW" "Warning: Could not create icon file"
        return 1
    fi
}

# Function to install files
install_files() {
    local install_path="$1"
    local share_path="$2"
    local is_system="$3"
    
    print_message "$BLUE" "Installing water reminder system..."
    
    # Create directories
    mkdir -p "$install_path" "$share_path" "$share_path/icons"
    
    # Copy main scripts
    local scripts=("water-reminder.sh" "water-reminder-daemon.sh" "water-control.sh")
    for script in "${scripts[@]}"; do
        if [[ -f "$SCRIPT_DIR/$script" ]]; then
            cp "$SCRIPT_DIR/$script" "$install_path/"
            chmod +x "$install_path/$script"
            print_message "$GREEN" "✓ Installed $script"
        else
            print_message "$RED" "✗ Script not found: $script"
            return 1
        fi
    done
    
    # Copy configuration file
    if [[ -f "$SCRIPT_DIR/config.conf" ]]; then
        cp "$SCRIPT_DIR/config.conf" "$share_path/"
        print_message "$GREEN" "✓ Installed configuration file"
    fi
    
    # Create water drop icon
    create_water_icon "$share_path/icons/water-drop.png"
    
    # Update configuration with correct paths
    local config_file="$share_path/config.conf"
    if [[ -f "$config_file" ]]; then
        # Update icon path in config
        sed -i "s|ICON_PATH=.*|ICON_PATH=\"$share_path/icons/water-drop.png\"|" "$config_file"
        # Update other paths
        sed -i "s|LOG_FILE=.*|LOG_FILE=\"\$HOME/.local/share/water-reminder/water-reminder.log\"|" "$config_file"
        sed -i "s|PID_FILE=.*|PID_FILE=\"\$HOME/.local/share/water-reminder/water-reminder.pid\"|" "$config_file"
    fi
    
    # Create symlinks for easy access
    if [[ "$is_system" == "true" ]]; then
        # System-wide installation
        ln -sf "$install_path/water-control.sh" "$install_path/water-reminder" 2>/dev/null || true
        print_message "$GREEN" "✓ Created system-wide command: water-reminder"
    else
        # User installation
        if [[ ":$PATH:" == *":$install_path:"* ]]; then
            ln -sf "$install_path/water-control.sh" "$install_path/water-reminder" 2>/dev/null || true
            print_message "$GREEN" "✓ Created user command: water-reminder"
        else
            print_message "$YELLOW" "Note: $install_path is not in PATH. Add it to use 'water-reminder' command."
        fi
    fi
    
    return 0
}

# Function to setup autostart
setup_autostart() {
    local autostart_dir="$HOME/.config/autostart"
    local desktop_file="$autostart_dir/water-reminder.desktop"
    local control_script=""
    
    # Determine which control script to use
    if [[ -x "/usr/local/bin/water-control.sh" ]]; then
        control_script="/usr/local/bin/water-control.sh"
    elif [[ -x "$HOME/.local/bin/water-control.sh" ]]; then
        control_script="$HOME/.local/bin/water-control.sh"
    else
        print_message "$RED" "Control script not found for autostart setup"
        return 1
    fi
    
    # Create autostart directory
    mkdir -p "$autostart_dir"
    
    # Create desktop entry
    cat > "$desktop_file" << EOF
[Desktop Entry]
Type=Application
Name=Water Reminder
Comment=Reminds you to drink water regularly
Exec=$control_script start
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
StartupNotify=false
Categories=Utility;Health;
Keywords=water;reminder;health;hydration;
EOF
    
    print_message "$GREEN" "✓ Created autostart entry: $desktop_file"
    print_message "$BLUE" "Water reminder will start automatically on login"
}

# Function to uninstall
uninstall() {
    local install_paths=("/usr/local/bin" "$HOME/.local/bin")
    local share_paths=("/usr/local/share/water-reminder" "$HOME/.local/share/water-reminder")
    local scripts=("water-reminder.sh" "water-reminder-daemon.sh" "water-control.sh" "water-reminder")
    
    print_message "$BLUE" "Uninstalling water reminder system..."
    
    # Stop service first
    for path in "${install_paths[@]}"; do
        if [[ -x "$path/water-control.sh" ]]; then
            "$path/water-control.sh" stop 2>/dev/null || true
        fi
    done
    
    # Remove scripts
    for install_path in "${install_paths[@]}"; do
        for script in "${scripts[@]}"; do
            if [[ -f "$install_path/$script" ]]; then
                rm -f "$install_path/$script"
                print_message "$GREEN" "✓ Removed $install_path/$script"
            fi
        done
    done
    
    # Remove share directories
    for share_path in "${share_paths[@]}"; do
        if [[ -d "$share_path" ]]; then
            rm -rf "$share_path"
            print_message "$GREEN" "✓ Removed $share_path"
        fi
    done
    
    # Remove autostart entry
    local autostart_file="$HOME/.config/autostart/water-reminder.desktop"
    if [[ -f "$autostart_file" ]]; then
        rm -f "$autostart_file"
        print_message "$GREEN" "✓ Removed autostart entry"
    fi
    
    print_message "$GREEN" "Water reminder system uninstalled successfully"
}

# Function to show usage
show_usage() {
    cat << EOF
Water Reminder Installation Script v1.0.0

Usage: $0 [OPTIONS] COMMAND

Commands:
    install         Install water reminder system
    uninstall       Remove water reminder system
    check           Check system dependencies

Options:
    --system        Install system-wide (requires sudo)
    --user          Install for current user only (default)
    --autostart     Setup automatic startup on login
    -h, --help      Show this help message

Examples:
    $0 install                  # Install for current user
    sudo $0 install --system    # Install system-wide
    $0 install --autostart      # Install with autostart
    $0 check                    # Check dependencies
    $0 uninstall               # Uninstall

Installation Paths:
    User installation:
      Scripts: $USER_INSTALL_PATH
      Data:    $USER_SHARE_PATH
    
    System installation:
      Scripts: $SYSTEM_INSTALL_PATH
      Data:    $SYSTEM_SHARE_PATH

After installation, use:
    water-reminder start        # Start the service
    water-reminder status       # Check status
    water-reminder --help       # Show help

EOF
}

# Parse command line arguments
SYSTEM_INSTALL=false
SETUP_AUTOSTART=false
COMMAND=""

while [[ $# -gt 0 ]]; do
    case $1 in
        install)
            COMMAND="install"
            shift
            ;;
        uninstall)
            COMMAND="uninstall"
            shift
            ;;
        check)
            COMMAND="check"
            shift
            ;;
        --system)
            SYSTEM_INSTALL=true
            shift
            ;;
        --user)
            SYSTEM_INSTALL=false
            shift
            ;;
        --autostart)
            SETUP_AUTOSTART=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_message "$RED" "Error: Unknown option '$1'"
            show_usage
            exit 1
            ;;
    esac
done

# Main script logic
case "$COMMAND" in
    install)
        print_message "$BLUE" "Water Reminder System Installation"
        print_message "$BLUE" "=================================="
        
        # Check dependencies first
        if ! check_dependencies; then
            print_message "$RED" "Installation aborted due to missing dependencies"
            exit 1
        fi
        
        # Determine installation paths
        if [[ "$SYSTEM_INSTALL" == "true" ]]; then
            if ! is_root; then
                print_message "$RED" "System-wide installation requires root privileges"
                print_message "$BLUE" "Run: sudo $0 install --system"
                exit 1
            fi
            install_files "$SYSTEM_INSTALL_PATH" "$SYSTEM_SHARE_PATH" "true"
        else
            install_files "$USER_INSTALL_PATH" "$USER_SHARE_PATH" "false"
        fi
        
        # Setup autostart if requested
        if [[ "$SETUP_AUTOSTART" == "true" ]]; then
            setup_autostart
        fi
        
        print_message "$GREEN" "✓ Installation completed successfully!"
        print_message "$BLUE" ""
        print_message "$BLUE" "Usage:"
        print_message "$BLUE" "  water-reminder start      # Start the service"
        print_message "$BLUE" "  water-reminder status     # Check status"
        print_message "$BLUE" "  water-reminder --help     # Show help"
        ;;
        
    uninstall)
        print_message "$BLUE" "Water Reminder System Removal"
        print_message "$BLUE" "============================="
        uninstall
        ;;
        
    check)
        print_message "$BLUE" "Checking system dependencies..."
        if check_dependencies; then
            print_message "$GREEN" "✓ All dependencies are satisfied"
        else
            exit 1
        fi
        ;;
        
    "")
        print_message "$RED" "Error: No command specified"
        show_usage
        exit 1
        ;;
        
    *)
        print_message "$RED" "Error: Unknown command '$COMMAND'"
        show_usage
        exit 1
        ;;
esac

exit 0
# Water Reminder System

A comprehensive shell script system for Linux desktop users to remind them to drink water regularly. This system provides desktop notifications with customizable intervals, messages, and settings.

## Features

- **Desktop Notifications**: Beautiful notifications using `notify-send` with custom icons
- **Configurable Intervals**: Set reminder times from 1 minute to several hours
- **Random Messages**: Multiple built-in hydration messages for variety
- **Sound Notifications**: Optional audio alerts with system sounds
- **Daemon Mode**: Runs in the background without interfering with your work
- **PID Management**: Proper process control with start/stop/restart functionality
- **Logging**: Comprehensive logging for tracking reminders and debugging
- **Suspend/Resume Handling**: Gracefully handles system sleep/wake cycles
- **Easy Installation**: Simple installation script for user or system-wide setup
- **Auto-start Support**: Optional automatic startup on user login

## File Structure

```
water-reminder/
├── water-reminder.sh          # Main reminder script
├── water-reminder-daemon.sh   # Daemon wrapper script
├── water-control.sh          # Control script (start/stop/status)
├── install.sh               # Installation script
├── config.conf             # Configuration file
├── README.md              # This documentation
└── icons/                # Custom notification icons
    └── water-drop.txt    # Water drop icon placeholder
```

## Requirements

- Linux desktop environment (GNOME, KDE, XFCE, etc.)
- `notify-send` (libnotify-bin package)
- `bash` shell (version 4.0 or higher)
- Audio system (ALSA/PulseAudio) for sound notifications (optional)

### Installing Dependencies

**Ubuntu/Debian:**
```bash
sudo apt-get install libnotify-bin
```

**CentOS/RHEL:**
```bash
sudo yum install libnotify
```

**Fedora:**
```bash
sudo dnf install libnotify
```

**Arch Linux:**
```bash
sudo pacman -S libnotify
```

## Quick Start

### 1. Installation

**For current user only:**
```bash
./install.sh install
```

**System-wide installation (requires sudo):**
```bash
sudo ./install.sh install --system
```

**With automatic startup:**
```bash
./install.sh install --autostart
```

### 2. Basic Usage

```bash
# Start the water reminder
water-reminder start

# Check status
water-reminder status

# Stop the reminder
water-reminder stop

# Restart with new settings
water-reminder restart

# Show help
water-reminder --help
```

## Configuration

The system uses a configuration file (`config.conf`) with the following options:

### Basic Settings

- **REMINDER_INTERVAL**: Time between reminders in minutes (default: 30)
- **SOUND_ENABLED**: Enable/disable sound notifications (true/false)
- **AUTO_START**: Auto-start on login (true/false)

### Advanced Settings

- **LOG_FILE**: Location of log file
- **PID_FILE**: Location of PID file
- **ICON_PATH**: Path to notification icon
- **URGENCY**: Notification urgency level (low/normal/critical)
- **TIMEOUT**: Notification timeout in milliseconds

### Custom Messages

You can customize the reminder messages by editing the `MESSAGES` array in `config.conf`:

```bash
MESSAGES=(
    "💧 Time to drink some water! Stay hydrated! 💧"
    "🚰 Don't forget to hydrate! Your body needs water! 🚰"
    "💦 Water break time! Keep yourself healthy! 💦"
    # Add your own messages here
)
```

## Command Reference

### Control Script (`water-control.sh`)

The main interface for managing the water reminder service:

```bash
water-reminder COMMAND [OPTIONS]

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
```

### Main Script (`water-reminder.sh`)

The core reminder script (usually run via daemon):

```bash
./water-reminder.sh [OPTIONS]

Options:
  -i, --interval MINUTES  Set reminder interval in minutes
  -s, --sound on|off      Enable/disable sound notifications
  -l, --log FILE          Set log file path
  -h, --help              Show help message
  -v, --version           Show version information
```

### Daemon Script (`water-reminder-daemon.sh`)

Background daemon wrapper:

```bash
./water-reminder-daemon.sh {start|stop|restart|status} [OPTIONS]
```

### Installation Script (`install.sh`)

System installation and setup:

```bash
./install.sh [OPTIONS] COMMAND

Commands:
  install         Install water reminder system
  uninstall       Remove water reminder system completely
  check           Check system dependencies

Options:
  --system        Install system-wide (requires sudo)
  --user          Install for current user only (default)
  --autostart     Setup automatic startup on login
```

## Usage Examples

### Basic Examples

```bash
# Start with default 30-minute intervals
water-reminder start

# Start with custom 45-minute intervals
water-reminder start -i 45

# Start with sound disabled
water-reminder start -s off

# Start with custom interval and no sound
water-reminder start -i 20 -s off
```

### Advanced Examples

```bash
# Install system-wide with autostart
sudo ./install.sh install --system --autostart

# Check what's happening in real-time
water-reminder follow

# Test notifications without starting service
water-reminder test

# View recent activity
water-reminder logs 50

# Edit configuration
water-reminder config
```

## Troubleshooting

### Common Issues

**1. "notify-send not found" error:**
```bash
# Install libnotify
sudo apt-get install libnotify-bin  # Ubuntu/Debian
sudo yum install libnotify          # CentOS/RHEL
```

**2. No notifications appearing:**
```bash
# Test notification system
water-reminder test

# Check if notification daemon is running
ps aux | grep notification
```

**3. Service won't start:**
```bash
# Check status and logs
water-reminder status
water-reminder logs

# Verify dependencies
./install.sh check
```

**4. Notifications appearing but no sound:**
```bash
# Check audio system
pactl info  # PulseAudio
aplay -l    # ALSA

# Test with sound enabled
water-reminder restart -s on
```

### Debug Mode

Enable verbose logging by checking the log file:

```bash
# Follow logs in real-time
water-reminder follow

# View recent entries
water-reminder logs 100
```

### Uninstallation

To completely remove the water reminder system:

```bash
# Stop service first
water-reminder stop

# Uninstall
./install.sh uninstall
```

## System Integration

### Desktop Environment Compatibility

The water reminder system is designed to work with major Linux desktop environments:

- **GNOME**: Full support with native notifications
- **KDE Plasma**: Full support with KDE notification system
- **XFCE**: Full support with notification daemon
- **LXQt/LXDE**: Compatible with notification system
- **i3/Sway**: Works with notification daemon
- **Cinnamon**: Full support
- **MATE**: Full support

### Autostart Configuration

When installed with `--autostart`, the system creates a desktop entry at:
```
~/.config/autostart/water-reminder.desktop
```

To manually enable/disable autostart:
```bash
# Enable
water-reminder config
# Set AUTO_START=true in config file

# Disable
rm ~/.config/autostart/water-reminder.desktop
```

### System Suspend/Resume

The water reminder handles system suspend/resume events gracefully:

- Pauses during system suspend
- Resumes normal operation after wake-up
- Maintains correct timing intervals
- Logs suspend/resume events

## File Locations

### User Installation
```
Scripts:     ~/.local/bin/
Data:        ~/.local/share/water-reminder/
Config:      ~/.local/share/water-reminder/config.conf
Logs:        ~/.local/share/water-reminder/water-reminder.log
PID file:    ~/.local/share/water-reminder/water-reminder.pid
Autostart:   ~/.config/autostart/water-reminder.desktop
```

### System Installation
```
Scripts:     /usr/local/bin/
Data:        /usr/local/share/water-reminder/
Config:      /usr/local/share/water-reminder/config.conf
User logs:   ~/.local/share/water-reminder/water-reminder.log
User PID:    ~/.local/share/water-reminder/water-reminder.pid
```

## Contributing

This water reminder system is designed to be extensible and maintainable. To contribute:

1. Test your changes on multiple desktop environments
2. Ensure backward compatibility with existing configurations
3. Update documentation for new features
4. Follow shell scripting best practices
5. Include error handling and logging

## License

This project is provided as-is for educational and personal use. Feel free to modify and distribute according to your needs.

## Health Benefits

Regular water consumption provides numerous health benefits:

- Maintains proper hydration levels
- Supports cognitive function and focus
- Aids in temperature regulation
- Promotes healthy skin
- Supports kidney function
- Improves energy levels
- Enhances physical performance

**Recommended daily water intake:** 8-10 glasses (2-2.5 liters) for average adults, though individual needs may vary based on activity level, climate, and health conditions.

---

**Version:** 1.0.0  
**Compatibility:** Linux desktop environments with notification support  
**Requirements:** bash 4.0+, libnotify (notify-send)
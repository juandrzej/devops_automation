#!/bin/bash

LOG_FILE="/var/log/system_monitor.log"

# Enhanced CPU temperature detection for Vultr/cloud servers
get_cpu_temp() {
    # Method 1: Check for standard thermal zones
    if [ -f "/sys/class/thermal/thermal_zone0/temp" ]; then
        temp=$(cat /sys/class/thermal/thermal_zone0/temp)
        echo "$((temp/1000))°C"

    # Method 2: Check for Intel/AMD CPU temp via sensors
    elif command -v sensors &>/dev/null; then
        temp=$(sensors | grep -E "Package id|Tdie|Core 0" | awk '{print $4}' | tr -d '+°C' | head -1)
        echo "${temp}°C"

    # Method 3: Check for virtualization-friendly alternatives
    elif [ -d "/sys/class/hwmon" ]; then
        for hwmon in /sys/class/hwmon/hwmon*; do
            if [ -f "$hwmon/temp1_input" ]; then
                temp=$(cat "$hwmon/temp1_input")
                echo "$((temp/1000))°C"
                return
            fi
        done

    # Method 4: Last resort - check for vendor-specific files
    elif [ -f "/sys/class/thermal/cooling_device0/cur_state" ]; then
        cooling_state=$(cat /sys/class/thermal/cooling_device0/cur_state)
        max_state=$(cat /sys/class/thermal/cooling_device0/max_state)
        # Estimate temp based on cooling state (very approximate)
        estimated_temp=$(( 30 + (cooling_state * 50 / max_state) ))
        echo "~${estimated_temp}°C (estimated from cooling device)"

    else
        echo "N/A (No sensor access)"
    fi
}


# Log header with timestamp
{
    echo "===================================================="
    echo "=== System Report - $(date) ==="
    echo "===================================================="

    # Disk Usage
    echo -e "\n[ DISK USAGE ]"
    df -h | grep -v "tmpfs"  # Exclude tmpfs mounts

    # Memory Usage
    echo -e "\n[ MEMORY USAGE ]"
    free -h

    # CPU Temperature with fallback
    echo -e "\n[ CPU TEMPERATURE ]"
    temp_output=$(get_cpu_temp)
    echo "CPU Temp: ${temp_output}"

    # CPU Utilization
    echo -e "\n[ CPU LOAD ]"
    echo "Load Average: $(cat /proc/loadavg | awk '{print $1,$2,$3}')"
    echo "Top CPU Processes:"
    ps aux --sort=-%cpu | head -6 | awk '{printf "%-10s %-10s %-10s %-10s\n", $1, $2, $3, $11}'

    # Top Processes
    echo -e "\n[ TOP MEMORY PROCESSES ]"
    ps aux --sort=-%mem | head -6 | awk '{printf "%-10s %-10s %-10s %-10s\n", $1, $2, $3, $11}'

    echo -e "\n"
} >> "$LOG_FILE"

#!/bin/bash
LOG_FILE="/var/log/system_monitor.log"

echo "=== $(date) ===" >> $LOG_FILE
echo "" >> $LOG_FILE
echo "Disk Usage:" >> $LOG_FILE
df -h >> $LOG_FILE # disk space
echo "" >> $LOG_FILE
echo "Memory Usage:" >> $LOG_FILE
free -h >> $LOG_FILE # RAM usage
echo "" >> $LOG_FILE
echo "Top Processes:" >> $LOG_FILE
ps aux --sort=-%mem | head -5 >> $LOG_FILE # most memory-hungry apps
echo "" >> $LOG_FILE

#!/usr/bin/env bash

# ==========================================================
# Linux System Health Check
# ==========================================================


# ==========================================================
# REPORT CONFIGURATION
# ==========================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
REPORT_DIR="$PROJECT_DIR/reports"

TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
REPORT_FILE="$REPORT_DIR/system_health_${TIMESTAMP}.txt"

mkdir -p "$REPORT_DIR"

# Send all script output to both terminal and timestamped report
exec > >(tee "$REPORT_FILE") 2>&1

# ---------- Configuration ----------
CPU_WARN=70
CPU_CRITICAL=90

MEM_WARN=75
MEM_CRITICAL=90

DISK_WARN=75
DISK_CRITICAL=90

# ---------- Linux System Details ----------
echo "---------------- OS Details ----------------"
echo
echo "Host      : $(hostname)"
echo "Date      : $(date '+%Y-%m-%d %H:%M:%S')"
echo "Uptime    : $(uptime -p)"
echo

# ==========================================================
# 1. CPU UTILIZATION
# ==========================================================

echo "---------------- CPU UTILIZATION ----------------"

CPU_IDLE=$(top -bn1 | awk -F'id,' '/Cpu\(s\)/ {split($1,a,","); print a[length(a)]}' | tr -d ' ')

if [[ -z "$CPU_IDLE" ]]; then
    echo "CPU Usage : Unable to determine"
else
    CPU_USAGE=$(awk "BEGIN {printf \"%.1f\", 100 - $CPU_IDLE}")
    echo "CPU Usage : ${CPU_USAGE}%"

    if (( $(awk "BEGIN {print ($CPU_USAGE >= $CPU_CRITICAL)}") )); then
        echo "Status    : CRITICAL"
    elif (( $(awk "BEGIN {print ($CPU_USAGE >= $CPU_WARN)}") )); then
        echo "Status    : WARNING"
    else
        echo "Status    : PASS"
    fi
fi

echo

# ==========================================================
# 2. MEMORY UTILIZATION
# ==========================================================

echo "---------------- MEMORY UTILIZATION ----------------"

MEM_USAGE=$(free | awk '/Mem:/ {
    printf "%.1f", ($3/$2)*100
}')

echo "Memory Usage : ${MEM_USAGE}%"

if (( $(awk "BEGIN {print ($MEM_USAGE >= $MEM_CRITICAL)}") )); then
    echo "Status       : CRITICAL"
elif (( $(awk "BEGIN {print ($MEM_USAGE >= $MEM_WARN)}") )); then
    echo "Status       : WARNING"
else
    echo "Status       : PASS"
fi

echo
free -h

echo

# ==========================================================
# 3. FILESYSTEM UTILIZATION
# ==========================================================

echo "---------------- FILESYSTEM UTILIZATION ----------------"

FILESYSTEM_CONFIG="$(dirname "$0")/../config/filesystems.conf"

if [[ ! -f "$FILESYSTEM_CONFIG" ]]; then
    echo "ERROR: Filesystem configuration not found:"
    echo "$FILESYSTEM_CONFIG"
else

    printf "%-25s %-8s %-8s %-8s %-8s %s\n" \
        "Filesystem" "Size" "Used" "Avail" "Use%" "Mounted"

    while IFS= read -r mount_point; do

        # Skip blank lines and comments
        [[ -z "$mount_point" || "$mount_point" =~ ^[[:space:]]*# ]] && continue

        # Remove leading/trailing whitespace
        mount_point=$(echo "$mount_point" | xargs)

        # Check whether mount point exists
        if [[ ! -d "$mount_point" ]]; then
            echo "WARNING: Mount point does not exist: $mount_point"
            continue
        fi

        # Get filesystem information for this mount point
        df_output=$(df -hP "$mount_point" | tail -n 1)

        filesystem=$(echo "$df_output" | awk '{print $1}')
        size=$(echo "$df_output" | awk '{print $2}')
        used=$(echo "$df_output" | awk '{print $3}')
        available=$(echo "$df_output" | awk '{print $4}')
        usage=$(echo "$df_output" | awk '{print $5}')

        printf "%-25s %-8s %-8s %-8s %-8s %s\n" \
            "$filesystem" "$size" "$used" "$available" "$usage" "$mount_point"

    done < "$FILESYSTEM_CONFIG"

    echo

    echo "Filesystem Health Status:"

    while IFS= read -r mount_point; do

        # Skip blank lines and comments
        [[ -z "$mount_point" || "$mount_point" =~ ^[[:space:]]*# ]] && continue

        mount_point=$(echo "$mount_point" | xargs)

        [[ ! -d "$mount_point" ]] && continue

        usage=$(df -P "$mount_point" | tail -n 1 | awk '{print $5}')
        usage_value=${usage%\%}

        if [[ "$usage_value" =~ ^[0-9]+$ ]]; then

            if (( usage_value >= DISK_CRITICAL )); then
                status="CRITICAL"
            elif (( usage_value >= DISK_WARN )); then
                status="WARNING"
            else
                status="PASS"
            fi

            printf "%-25s Usage: %-5s Status: %s\n" \
                "$mount_point" "$usage" "$status"
        fi

    done < "$FILESYSTEM_CONFIG"

fi

echo

# ==========================================================
# 4. BACKGROUND / RUNNING PROCESSES
# ==========================================================

echo "---------------- BACKGROUND PROCESSES ----------------"

PROCESS_COUNT=$(ps -e --no-headers | wc -l)

echo "Total Processes : $PROCESS_COUNT"
echo

echo "Top CPU-consuming processes:"
ps -eo pid,user,%cpu,%mem,stat,comm --sort=-%cpu | grep -vE 'COMMAND|ps$' | head -n 10

echo

echo "Top Memory-consuming processes:"
ps -eo pid,user,%cpu,%mem,stat,comm --sort=-%mem | grep -vE 'COMMAND|ps$' | head -n 10

echo

# ==========================================================
# 5. PROCESS STATE SUMMARY
# ==========================================================

echo "---------------- PROCESS STATES ----------------"

ps -eo stat= | awk '
{
    state=substr($1,1,1)

    if (state=="R") running++
    else if (state=="S") sleeping++
    else if (state=="D") waiting++
    else if (state=="Z") zombie++
    else other++
}

END {
    printf "Running      : %d\n", running+0
    printf "Sleeping     : %d\n", sleeping+0
    printf "Waiting (D)  : %d\n", waiting+0
    printf "Zombie       : %d\n", zombie+0
    printf "Other        : %d\n", other+0
}
'

echo

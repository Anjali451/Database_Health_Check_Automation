#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
REPORT_DIR="$PROJECT_DIR/reports"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
REPORT_FILE="$REPORT_DIR/health_check_${TIMESTAMP}.txt"

mkdir -p "$REPORT_DIR"

exec > >(tee "$REPORT_FILE") 2>&1

echo "=========================================================="
echo "                     HEALTH CHECK REPORT                  "
echo "=========================================================="

#=====================System Health Check=======================
"$SCRIPT_DIR/system_check.sh"

#==============DATABASE HEALTH CHECK======================================="

"$SCRIPT_DIR/database_check.sh"

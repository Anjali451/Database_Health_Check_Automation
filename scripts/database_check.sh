#!/bin/bash

# ==========================================================
# DATABASE HEALTH CHECK
# MySQL implementation
# ==========================================================

DB_HOST="172.26.160.1"
DB_PORT="3306"
DB_USER="healthcheck"
DB_NAME="healthcheck_test"
mysql_cmd() {
    mysql --defaults-extra-file="$HOME/.my.cnf" "$@"
}

echo "---------Database Details --------------------------"
echo "Database   : MySQL"
echo "Host       : $DB_HOST"
echo "Port       : $DB_PORT"
echo "Database   : $DB_NAME"
echo "Timestamp  : $(date '+%Y-%m-%d %H:%M:%S')"
echo

# ==========================================================
# DATABASE CONNECTION CHECK
# ==========================================================

echo "---------------- DATABASE CONNECTIONS ----------------"

mysql_cmd \
    -e "
        SELECT
            USER() AS connected_user,
            DATABASE() AS database_name,
            VERSION() AS database_version;
    "

if [[ $? -eq 0 ]]; then
    echo
    echo "Database Connection : PASS"
else
    echo
    echo "Database Connection : FAIL"
    exit 1
fi

echo

# ==========================================================
# 1. ACTIVE CONNECTION COUNT
# ==========================================================

echo "---------------- ACTIVE CONNECTIONS ----------------"

mysql_cmd \
    -e "
        SELECT
            COUNT(*) AS active_connections
        FROM information_schema.processlist;
    "

echo

# ==========================================================
# 2. LOG UTILIZATION
# ==========================================================

echo "---------------- LOG UTILIZATION ----------------"

echo "MySQL does not have a direct equivalent of:"
echo "DB2 SYSIBMADM.LOG_UTILIZATION"
echo

echo "MySQL binary-log information:"

mysql_cmd \
    -N -B \
    -e "
        SELECT
            VARIABLE_VALUE
        FROM performance_schema.global_variables
        WHERE VARIABLE_NAME = 'log_bin';
    " | while read -r LOG_BIN; do

        if [[ "$LOG_BIN" == "ON" ]]; then

            echo "Binary Logging : ENABLED"
            echo

            mysql_cmd \
                -N -B \
                -e "SHOW BINARY LOGS;" |
            awk '
            BEGIN {
                total=0
                count=0
            }
            {
                total += $2
                count++
            }
            END {
                printf "Binary Log Files : %d\n", count
                printf "Total Binary Log Size : %.2f MB\n", total/1024/1024
            }'

            echo
            echo "Log Utilization % : NOT DIRECTLY AVAILABLE"
            echo "Reason             : MySQL does not expose a DB2-style"
            echo "                     percentage utilization metric for"
            echo "                     binary logs."
            echo

        else
            echo "Binary Logging : DISABLED"
            echo
            echo "Log Utilization % : NOT AVAILABLE"
            echo "Reason             : Binary logging is disabled."
        fi
    done

echo


# ==========================================================
# 3. LOCKS
# ==========================================================

echo "---------------- DATABASE LOCKS ----------------"

mysql_cmd \
    -e "
        SELECT
            *
        FROM performance_schema.data_lock_waits;
    "

echo

# ==========================================================
# 4. LAST BACKUP
# ==========================================================

echo "---------------- LAST BACKUP ----------------"

echo "MySQL does not maintain a universal last-backup timestamp"
echo "that can be queried directly like a DB2 backup history."
echo
echo "Last Backup : NOT AVAILABLE FROM MYSQL SERVER METADATA"

echo

# ==========================================================
# 5. RUNSTATS
# ==========================================================

echo "---------------- RUNSTATS / STATISTICS ----------------"

echo "DB2 RUNSTATS : NO DIRECT MYSQL EQUIVALENT"

echo "MySQL table statistics can be refreshed using ANALYZE TABLE."

mysql_cmd \
    -e "
        SELECT
            TABLE_SCHEMA,
            TABLE_NAME,
            TABLE_ROWS,
            UPDATE_TIME
        FROM information_schema.tables
        WHERE TABLE_SCHEMA = '$DB_NAME';
    "

echo

# ==========================================================
# 6. TABLESPACE / STORAGE
# ==========================================================

echo "---------------- TABLESPACE / STORAGE ----------------"

echo "DB2 Tablespace State/Utilization : NO DIRECT MYSQL EQUIVALENT"

mysql_cmd \
    -e "
        SELECT
            TABLE_SCHEMA,
            TABLE_NAME,
	    DATA_LENGTH,
            INDEX_LENGTH,
            ROUND((DATA_LENGTH + INDEX_LENGTH) / 1024 / 1024, 2)
                AS SIZE_MB
        FROM information_schema.tables
        WHERE TABLE_SCHEMA = '$DB_NAME';
    "

echo

# ==========================================================
# 7. LONG RUNNING QUERIES
# ==========================================================

echo "---------------- LONG RUNNING QUERIES ----------------"

mysql_cmd \
    -e "
        SELECT
            ID,
            USER,
            HOST,
            DB,
            COMMAND,
            TIME,
            STATE,
            INFO
        FROM information_schema.processlist
        WHERE DB = '$DB_NAME'
          AND COMMAND <> 'Sleep'
          AND TIME > 30
        ORDER BY TIME DESC;
    "

echo

# ==========================================================
# 8. BACKGROUND DATABASE UTILITIES
# ==========================================================

echo
echo "---------------- DATABASE UTILITIES ----------------"
echo "DB2 utilities such as BACKUP, RESTORE, RUNSTATS and"
echo "LOAD do not have direct equivalents in MySQL processlist."
echo

mysql_cmd -t -e "
SELECT
    ID AS CONNECTION_ID,
    USER AS DB_USER,
    HOST AS CLIENT_HOST,
    DB AS DATABASE_NAME,
    COMMAND,
    TIME AS TIME_SECONDS,
    STATE,
    INFO
FROM information_schema.processlist
WHERE COMMAND <> 'Sleep'
  AND (
      INFO IS NULL
      OR INFO NOT LIKE '%information_schema.processlist%'
  )
ORDER BY TIME DESC;
"

echo
echo "=========================================================="
echo "             DATABASE HEALTH CHECK COMPLETE"
echo "=========================================================="
















# ==========================================================
# DB2 LUW EQUIVALENT COMMANDS
# ==========================================================
#
# Database connectivity:
# db2 connect to <DB_NAME>
# db2 "SELECT CURRENT SERVER, CURRENT USER FROM SYSIBM.SYSDUMMY1"
# db2level
#
# Active applications:
# db2 list applications
# db2 "SELECT APPLICATION_HANDLE, APPLICATION_NAME, AUTHID,
#             APPL_STATUS, CLIENT_IPADDR, CLIENT_PID
#      FROM SYSIBMADM.APPLICATIONS"
#
# Log utilization:
# db2 "SELECT * FROM SYSIBMADM.LOG_UTILIZATION"
#
# Locks:
# db2pd -db <DB_NAME> -locks
# db2 "SELECT * FROM SYSIBMADM.LOCKS_HELD"
# db2 "SELECT * FROM SYSIBMADM.LOCKWAITS"
#
# Last backup:
# db2 list history backup all for <DB_NAME>
#
# RUNSTATS:
# db2 runstats on table <SCHEMA>.<TABLE>
#     with distribution and detailed indexes all
#
# Tablespaces:
# db2 list tablespaces show detail
# db2pd -db <DB_NAME> -tablespaces
#
# Long-running applications / queries:
# db2top -d <DB_NAME>
# db2 list applications
#
# Database utilities:
# db2 list utilities show detail
#
# DB2 processes:
# ps -ef | grep -E 'db2sysc|db2agent|db2fmp|db2bp'
#
# DB2 version:
# db2level
#
# ==========================================================

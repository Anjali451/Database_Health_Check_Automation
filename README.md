# Database Health Check Automation

A shell-based database health-check automation project built in WSL/Linux.

The project currently supports MySQL for actual execution and keeps DB2 LUW equivalent commands documented for future use.

# Architecture

```text
db2-health-automation/
│
├── config/
│   └── filesystems.conf
│
├── reports/
│   └── health_check_YYYYMMDD_HHMMSS.txt
│
└── scripts/
    ├── health_check.sh
    ├── system_check.sh
    └── database_check.sh
```

# Components
- health_check.sh
  - Main script.
  - Runs the system and database health checks.
  - Creates one timestamped combined report.
- system_check.sh
  - Checks CPU utilization.
  - Checks memory utilization.
  - Checks configured filesystem utilization.
  - Checks system, user, and DB2-related processes.
  - Provides a process-state summary.
- database_check.sh
  - Performs MySQL database health checks.
  - Checks database connectivity.
  - Checks active connections.
  - Checks binary-log information.
  - Checks database locks.
  - Reports backup availability.
  - Checks table statistics.
  - Checks MySQL storage information.
  - Checks long-running queries.
  - Checks database utilities/activity.
- config/filesystems.conf
  - Contains the filesystem mount points to monitor.
- reports/
  - Stores timestamped combined health-check reports.

# Requirements
- WSL2
- Ubuntu/Linux
- Bash
- MySQL client
- MySQL Server

The current setup uses a local MySQL Server running on Windows and connects to it from WSL.

# MySQL Credentials

The MySQL client uses ~/.my.cnf so the health-check scripts do not require a password to be entered manually each time.

# How to Run

Go to the project directory: cd ~/projects/health-automation

Run the complete health check: ./scripts/health_check.sh

The results are displayed in the terminal and saved as one timestamped report in: reports/




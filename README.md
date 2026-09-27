# Linux System Health Checker

A Bash-based Linux system health checker that reads system state, compares it against configurable thresholds, generates a human-readable report, records execution details, and returns a meaningful exit code.

## What this project does

The Linux System Health Checker answers a simple operational question:

> Is this Linux machine healthy?

The script checks important system resources, compares them against configurable warning and critical thresholds, displays the results in a readable format, writes execution information to a log, and returns an exit code that another script or monitoring system can use.

## What it checks

The health checker monitors:

* CPU utilisation
* Memory utilisation
* Swap utilisation
* Disk space
* Filesystem inode usage
* Load average relative to CPU count
* System uptime
* Top processes by CPU usage
* Top processes by memory usage
* Zombie processes

## Project structure

```text
linux-system-health-checker/
├── bin/
│   └── health-check.sh
├── conf/
│   └── health.conf
├── logs/
├── reports/
├── state/
├── backups/
├── tests/
│   └── test-health-check.sh
├── .gitignore
└── README.md
```

Runtime data is stored under:

```text
/opt/devopssaini/
```

with the following structure:

```text
/opt/devopssaini/
├── bin/
├── conf/
├── logs/
├── state/
├── backups/
└── reports/
```

## Configuration

Health thresholds are stored separately from the script in:

```text
conf/health.conf
```

Example settings:

```bash
CPU_WARN=75
CPU_CRIT=90

MEM_WARN=80
MEM_CRIT=92

SWAP_WARN=20
SWAP_CRIT=50

DISK_WARN=80
DISK_CRIT=90

INODE_WARN=80
INODE_CRIT=90

LOAD_WARN=1.5
LOAD_CRIT=2.5

TOP_PROCESSES=5
```

Separating configuration from code allows thresholds to be changed without modifying the health-checking logic.

## Installation

Create the runtime directories:

```bash
sudo mkdir -p /opt/devopssaini/{bin,conf,logs,state,backups,reports}
```

Copy the script:

```bash
sudo cp bin/health-check.sh /opt/devopssaini/bin/
```

Copy the configuration:

```bash
sudo cp conf/health.conf /opt/devopssaini/conf/
```

Make the script executable:

```bash
sudo chmod +x /opt/devopssaini/bin/health-check.sh
```

## Usage

### Run the health checker

From the repository:

```bash
./bin/health-check.sh
```

The script prints a health report directly to the terminal.

### Generate a report file

Use:

```bash
./bin/health-check.sh --report
```

A timestamped report will be created under:

```text
/opt/devopssaini/reports/
```

For example:

```text
/opt/devopssaini/reports/health-2026-09-27-130244.txt
```

### Show help

```bash
./bin/health-check.sh --help
```

### Invalid option

An unsupported option is treated as a script/usage error:

```bash
./bin/health-check.sh --invalid-option
```

## Exit codes

The health checker uses exit codes to communicate its result to other programs.

| Exit code | Meaning                        |
| --------: | ------------------------------ |
|         0 | System is healthy              |
|         1 | Warning threshold was crossed  |
|         2 | Critical threshold was crossed |
|         3 | Script or usage failure        |

The script tracks the worst severity found during the run and returns that severity as its exit code.

This means the checker can be used by:

* cron jobs
* monitoring systems
* CI/CD pipelines
* wrapper scripts
* future alerting systems

For example:

```bash
./bin/health-check.sh
echo $?
```

A result of:

```text
0
```

means no configured thresholds were breached.

A result of:

```text
1
```

means at least one warning threshold was crossed.

A result of:

```text
2
```

means at least one critical threshold was crossed.

## Data sources

The checker reads Linux system information directly from `/proc` where appropriate.

### CPU

```text
/proc/stat
```

CPU utilisation is calculated by taking two samples one second apart.

### Memory and swap

```text
/proc/meminfo
```

The checker uses `MemAvailable` when calculating memory utilisation.

### Load average

```text
/proc/loadavg
```

The one-minute load is compared relative to the number of available CPU cores.

### Uptime

```text
/proc/uptime
```

### Disk and inode usage

The checker uses:

```text
df
df -i
```

This allows both disk capacity and inode utilisation to be checked.

### Processes

Process information is collected with:

```text
ps
```

The report displays the top processes by CPU and memory usage.

## Logging

The health checker writes execution information to:

```text
/opt/devopssaini/logs/health-check.log
```

The log records information such as:

* CPU utilisation
* Memory utilisation
* Swap utilisation
* Disk usage
* Load average
* Uptime
* Zombie process count
* Overall severity

## Reports

Generated reports are stored in:

```text
/opt/devopssaini/reports/
```

Example:

```text
health-2026-09-27-130244.txt
```

The report contains:

1. Host information
2. Generation timestamp
3. Resource utilisation
4. Storage information
5. Top CPU processes
6. Top memory processes
7. Summary status

## Testing

Syntax can be checked with:

```bash
bash -n bin/health-check.sh
```

ShellCheck can be used with:

```bash
shellcheck bin/health-check.sh
```

The project also contains a basic test runner:

```bash
./tests/test-health-check.sh
```

The test runner verifies:

* Bash syntax
* Help output
* Invalid option handling
* Valid health-check exit-code range

## Example

A healthy section may look like:

```text
RESOURCE UTILISATION
----------------------------------------------------------
 CPU utilisation        0.2%           [OK]
 Memory used            6.4%           [OK]
 Swap used              0.0%           [OK]
 Load / core            0.01           [OK]
```

A critical disk condition may look like:

```text
Disk /mnt/c            92%            [CRITICAL]
```

The final exit code will then be:

```text
2
```

because a critical threshold was detected.

## Design decisions

### Read Linux state directly

The project reads `/proc` directly instead of depending on interactive tools such as `top` for its primary measurements.

This makes the checks predictable and suitable for automation.

### Two thresholds

Each major resource uses warning and critical thresholds.

For example:

```text
DISK_WARN=80
DISK_CRIT=90
```

This allows the script to distinguish between an early warning and a critical condition.

### Configuration separate from code

Thresholds and operational settings are stored in:

```text
conf/health.conf
```

This means operational behaviour can be changed without rewriting the health-checking logic.

### Exit codes as contracts

The script does not only print information for a human.

It also returns a status that another program can act on.

```text
0 = healthy
1 = warning
2 = critical
3 = script/usage failure
```

## Current environment

This project was developed and tested in a Linux environment running under WSL.

The current test environment has demonstrated real critical conditions, including filesystem usage above the configured `DISK_CRIT` threshold.

That means an exit code of `2` during testing can be an expected result rather than a test failure.

## Future extensions

Possible future improvements include:

* JSON output
* Network connectivity checks
* Certificate expiry checks
* Integration with an alerting system
* Scheduled execution with cron

These extensions are intentionally outside the current core implementation.

## Learning outcomes

This project demonstrates practical Linux and Bash concepts including:

* Bash scripting
* Strict shell execution with `set -euo pipefail`
* Linux `/proc` filesystem
* CPU utilisation calculation
* Memory and swap monitoring
* Disk and inode monitoring
* Load-average interpretation
* Process inspection
* Threshold-based health checks
* Exit-code design
* Logging
* Report generation
* Configuration management
* ShellCheck
* Basic automated testing
* Git and GitHub workflow

## Project status

**Project 1 — Linux System Health Checker: Complete**

The project provides a working Linux health-checking script with configurable thresholds, logging, report generation, process monitoring, meaningful exit codes, basic testing, and Git-based version control.


#!/usr/bin/env bash
#
# health-check.sh
# Reports CPU, memory, swap, disk, inode, load and process health.
# Exit: 0 healthy | 1 warning | 2 critical | 3 script failure
#

set -euo pipefail
IFS=$'\n\t'

SCRIPT_NAME="health-check"
BASE_DIR="/opt/devopssaini"
CONFIG="${BASE_DIR}/conf/health.conf"
LOG_FILE="${BASE_DIR}/logs/${SCRIPT_NAME}.log"

HOSTNAME_S="$(hostname -s)"
STAMP="$(date '+%Y-%m-%d %H:%M:%S')"

# Worst severity seen so far:
# 0 = OK
# 1 = WARNING
# 2 = CRITICAL
OVERALL=0

mkdir -p "${BASE_DIR}/logs" "${BASE_DIR}/reports"

log() {
    local level="$1"
    shift

    local msg="$*"

    printf '%s [%-8s] %s\n' \
        "$(date '+%F %T')" \
        "$level" \
        "$msg" >> "$LOG_FILE"
}

# Raise the overall severity, never lower it.
escalate() {
    (( $1 > OVERALL )) && OVERALL=$1
    return 0
}

# Compare two possibly-floating-point numbers:
# is $1 >= $2 ?
ge() {
    awk -v a="$1" -v b="$2" 'BEGIN { exit !(a >= b) }'
}

# Load configuration if it exists.
if [[ -f "$CONFIG" ]]; then
    # shellcheck source=/dev/null
    source "$CONFIG"
fi

# Defaults if a value wasn't supplied by the configuration.
CPU_WARN="${CPU_WARN:-75}"
CPU_CRIT="${CPU_CRIT:-90}"

MEM_WARN="${MEM_WARN:-80}"
MEM_CRIT="${MEM_CRIT:-92}"

SWAP_WARN="${SWAP_WARN:-20}"
SWAP_CRIT="${SWAP_CRIT:-50}"

DISK_WARN="${DISK_WARN:-80}"
DISK_CRIT="${DISK_CRIT:-90}"

INODE_WARN="${INODE_WARN:-80}"
INODE_CRIT="${INODE_CRIT:-90}"

LOAD_WARN="${LOAD_WARN:-1.5}"
LOAD_CRIT="${LOAD_CRIT:-2.5}"

TOP_PROCESSES="${TOP_PROCESSES:-5}"

main() {
    printf '\n'
    printf '%s\n' '================================================================'
    printf ' DEVOPS SAINI | SYSTEM HEALTH CHECKER\n'
    printf ' Host: %-24s Generated: %s\n' "$HOSTNAME_S" "$STAMP"
    printf '%s\n' '================================================================'
    printf '\n'

    log INFO "health check started"

    printf 'Configuration: %s\n' "$CONFIG"
    printf 'Log file:     %s\n' "$LOG_FILE"
    printf '\n'

    log INFO "configuration loaded"
    log INFO "health check skeleton completed"

    exit "$OVERALL"
}

main "$@"

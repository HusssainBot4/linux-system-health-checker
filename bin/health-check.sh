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

# Terminal color
C_RESET=$'\033[0m'
C_OK=$'\033[0;32m'
C_WARN=$'\033[0;33m'
C_CRIT=$'\033[0;31m'
C_HEAD=$'\033[1;34m'



# Disable colour when output is not a terminal
# (cron, pipes, redirected files, etc.)
if [[ ! -t 1 ]]; then
    C_RESET=''
    C_OK=''
    C_WARN=''
    C_CRIT=''
    C_HEAD=''
fi

section() {
    printf '\n%s%s%s\n' "$C_HEAD" "$1" "$C_RESET"
    printf '%s\n' '----------------------------------------------------------'
}

# status <severity 0|1|2> <label> <value> [detail]
status() {
    local sev="$1"
    local label="$2"
    local value="$3"
    local detail="${4:-}"

    local tag
    local colour

    case "$sev" in
        0)
            tag="OK"
            colour="$C_OK"
            ;;
        1)
            tag="WARNING"
            colour="$C_WARN"
            ;;
        2)
            tag="CRITICAL"
            colour="$C_CRIT"
            ;;
    esac

    printf ' %-22s %-14s %s[%s]%s %s\n' \
        "$label" \
        "$value" \
        "$colour" \
        "$tag" \
        "$C_RESET" \
        "$detail"
}

# bar <percentage> — a 20-character usage bar
bar() {
    local pct=${1%%.*}
    local filled
    local i
    local out=""

    (( pct > 100 )) && pct=100

    filled=$(( pct / 5 ))

    for (( i = 0; i < 20; i++ )); do
        (( i < filled )) && out+="#" || out+="."
    done

    printf '[%s]' "$out"
}

check_cpu() {
    local a b
    local -a f1 f2
    local idle_a idle_b total_a total_b
    local d_total d_idle
    local usage sev

    # First sample
    read -r _ a <<< "$(grep '^cpu ' /proc/stat)"
    read -ra f1 <<< "$a"

    idle_a=$(( f1[3] + f1[4] ))

    total_a=0
    for v in "${f1[@]}"; do
        total_a=$(( total_a + v ))
    done

    sleep 1

    # Second sample
    read -r _ b <<< "$(grep '^cpu ' /proc/stat)"
    read -ra f2 <<< "$b"

    idle_b=$(( f2[3] + f2[4] ))

    total_b=0
    for v in "${f2[@]}"; do
        total_b=$(( total_b + v ))
    done

    # Calculate the change between the two samples.
    d_total=$(( total_b - total_a ))
    d_idle=$(( idle_b - idle_a ))

    (( d_total == 0 )) && d_total=1

    usage=$(awk \
        -v t="$d_total" \
        -v i="$d_idle" \
        'BEGIN { printf "%.1f", (t - i) * 100 / t }')

    sev=0

    if ge "$usage" "$CPU_CRIT"; then
        sev=2
    elif ge "$usage" "$CPU_WARN"; then
        sev=1
    fi

    escalate "$sev"

    status \
        "$sev" \
        "CPU utilisation" \
        "${usage}%" \
        "$(bar "$usage")"

    log INFO "cpu=${usage}% severity=${sev}"
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
    printf '\n%s================================================================%s\n' \
        "$C_HEAD" "$C_RESET"

    printf ' DEVOPS SAINI | SYSTEM HEALTH CHECKER\n'
    printf ' Host: %-24s Generated: %s\n' "$HOSTNAME_S" "$STAMP"

    printf '%s================================================================%s\n' \
        "$C_HEAD" "$C_RESET"

    section "RESOURCE UTILISATION"

    check_cpu

    printf '\n'

    log INFO "health check CPU check completed"

    exit "$OVERALL"
}

main "$@"

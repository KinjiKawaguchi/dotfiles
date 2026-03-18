#!/bin/bash
input=$(cat)

# Nerd Font icons
ICON_GITHUB=""
ICON_BRANCH=""
ICON_FOLDER=""
ICON_MEMORY="󰍛"
ICON_ROBOT="󰚩"
ICON_CLOCK=""
ICON_CALENDAR=""

# Extract JSON fields
MODEL=$(echo "$input" | jq -r '.model.display_name // "unknown"')
DIR=$(echo "$input" | jq -r '.workspace.current_dir // "~"')
CTX_PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)

# Shorten home directory
DIR="${DIR/#$HOME/~}"

# Git info
WORK_DIR=$(echo "$input" | jq -r '.workspace.current_dir // "."')

if git -C "$WORK_DIR" rev-parse --git-dir > /dev/null 2>&1; then
    BRANCH=$(git -C "$WORK_DIR" branch --show-current 2>/dev/null)
    REPO_NAME=$(basename "$(git -C "$WORK_DIR" rev-parse --show-toplevel 2>/dev/null)")

    STAGED=$(git -C "$WORK_DIR" diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
    MODIFIED=$(git -C "$WORK_DIR" diff --numstat 2>/dev/null | wc -l | tr -d ' ')

    DIFF_INFO=""
    [ "$STAGED" -gt 0 ] 2>/dev/null && DIFF_INFO="+${STAGED}"
    [ "$MODIFIED" -gt 0 ] 2>/dev/null && DIFF_INFO="${DIFF_INFO:+$DIFF_INFO }~${MODIFIED}"

    GIT_LINE="${ICON_GITHUB} ${REPO_NAME} │ ${ICON_BRANCH} ${BRANCH}${DIFF_INFO:+ $DIFF_INFO}"
else
    GIT_LINE="${ICON_GITHUB} (no repo)"
fi

# ── Progress bar builder ──
# Usage: make_bar <pct> <width>
make_bar() {
    local pct=$1 width=${2:-15}
    local filled=$(( (pct * width + 50) / 100 ))
    [ "$filled" -gt "$width" ] && filled=$width
    local bar=""
    for ((i = 0; i < width; i++)); do
        if [ "$i" -lt "$filled" ]; then
            bar+="█"
        else
            bar+="░"
        fi
    done
    printf "%s" "$bar"
}

# ── Anthropic Usage API ──
USAGE_CACHE="/tmp/claude-statusline-usage.json"
USAGE_CACHE_MAX_AGE=300

fetch_usage() {
    local acct token response
    # Find the newest Keychain entry (handles duplicate accounts)
    acct=$(security dump-keychain 2>/dev/null \
        | awk '/Claude Code-credentials/{found=1} found && /acct/{print; found=0}' \
        | sed 's/.*<blob>="\(.*\)"/\1/' \
        | while IFS= read -r a; do
            local exp
            exp=$(security find-generic-password -s "Claude Code-credentials" -a "$a" -w 2>/dev/null \
                | jq -r '.claudeAiOauth.expiresAt // 0')
            echo "$exp $a"
          done \
        | sort -rn | head -1 | cut -d' ' -f2-)
    [ -n "$acct" ] || return 1

    token=$(security find-generic-password -s "Claude Code-credentials" -a "$acct" -w 2>/dev/null \
        | jq -r '.claudeAiOauth.accessToken') || return 1
    [ -n "$token" ] && [ "$token" != "null" ] || return 1

    response=$(curl -sf --max-time 3 "https://api.anthropic.com/api/oauth/usage" \
        -H "Authorization: Bearer $token" \
        -H "anthropic-beta: oauth-2025-04-20" \
        -H "Content-Type: application/json" 2>/dev/null) || return 1

    echo "$response" > "$USAGE_CACHE"
}

if [ ! -f "$USAGE_CACHE" ] || [ $(($(date +%s) - $(stat -f %m "$USAGE_CACHE" 2>/dev/null || echo 0))) -gt $USAGE_CACHE_MAX_AGE ]; then
    fetch_usage 2>/dev/null
fi

# Parse usage data
USAGE_5H=""
USAGE_7D=""
RESET_5H_LABEL=""
RESET_7D_LABEL=""

if [ -f "$USAGE_CACHE" ]; then
    USAGE_5H=$(jq -r '.five_hour.utilization // empty' "$USAGE_CACHE" 2>/dev/null | cut -d. -f1)
    USAGE_7D=$(jq -r '.seven_day.utilization // empty' "$USAGE_CACHE" 2>/dev/null | cut -d. -f1)

    # 5-hour reset label
    RESETS_5H=$(jq -r '.five_hour.resets_at // empty' "$USAGE_CACHE" 2>/dev/null)
    if [ -n "$RESETS_5H" ]; then
        RESET_EPOCH=$(date -juf "%Y-%m-%dT%H:%M:%S" "$(echo "$RESETS_5H" | cut -d. -f1 | sed 's/+.*//')" +%s 2>/dev/null)
        if [ -n "$RESET_EPOCH" ]; then
            NOW_EPOCH=$(date +%s)
            REMAINING_SEC=$((RESET_EPOCH - NOW_EPOCH))
            if [ "$REMAINING_SEC" -gt 0 ]; then
                REM_H=$((REMAINING_SEC / 3600))
                REM_M=$(( (REMAINING_SEC % 3600) / 60 ))
                RESET_5H_LABEL="${REM_H}h${REM_M}m"
            fi
        fi
    fi

    # 7-day reset label
    RESETS_7D=$(jq -r '.seven_day.resets_at // empty' "$USAGE_CACHE" 2>/dev/null)
    if [ -n "$RESETS_7D" ]; then
        RESET_EPOCH=$(date -juf "%Y-%m-%dT%H:%M:%S" "$(echo "$RESETS_7D" | cut -d. -f1 | sed 's/+.*//')" +%s 2>/dev/null)
        if [ -n "$RESET_EPOCH" ]; then
            NOW_EPOCH=$(date +%s)
            REMAINING_SEC=$((RESET_EPOCH - NOW_EPOCH))
            if [ "$REMAINING_SEC" -gt 0 ]; then
                REM_D=$((REMAINING_SEC / 86400))
                REM_H=$(( (REMAINING_SEC % 86400) / 3600 ))
                RESET_7D_LABEL="${REM_D}d${REM_H}h"
            fi
        fi
    fi
fi

# Build bars
CTX_BAR=$(make_bar "$CTX_PCT")

# ── Output ──

# Line 1: Directory
echo "${ICON_FOLDER} ${DIR}"

# Line 2: Git info
echo "$GIT_LINE"

# Line 3: Context │ Model
echo "${ICON_MEMORY} $(make_bar "$CTX_PCT") ${CTX_PCT}% │ ${ICON_ROBOT} ${MODEL}"

# Line 4: 5h block │ 7d window │ cache refresh countdown
if [ -n "$USAGE_5H" ] && [ -n "$USAGE_7D" ]; then
    LINE4="${ICON_CLOCK} 5h $(make_bar "$USAGE_5H" 10) ${USAGE_5H}%"
    [ -n "$RESET_5H_LABEL" ] && LINE4+=" ${RESET_5H_LABEL}"
    LINE4+=" │ ${ICON_CALENDAR} 7d $(make_bar "$USAGE_7D" 10) ${USAGE_7D}%"
    [ -n "$RESET_7D_LABEL" ] && LINE4+=" ${RESET_7D_LABEL}"

    if [ -f "$USAGE_CACHE" ]; then
        CACHE_AGE=$(($(date +%s) - $(stat -f %m "$USAGE_CACHE" 2>/dev/null || echo 0)))
        CACHE_REMAINING=$(( USAGE_CACHE_MAX_AGE - CACHE_AGE ))
        [ "$CACHE_REMAINING" -lt 0 ] && CACHE_REMAINING=0
        LINE4+=" │ ↻ $((CACHE_REMAINING / 60))m"
    fi

    echo "$LINE4"
fi

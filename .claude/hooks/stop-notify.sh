#!/bin/bash
# Claude Code Stop hook: play a sound and show a desktop notification.
# Runs on both macOS and Linux.

TITLE="Claude Code"
MESSAGE="入力待ちです"

case "$(uname -s)" in
    Darwin)
        afplay /System/Library/Sounds/Submarine.aiff &
        osascript -e "display notification \"$MESSAGE\" with title \"$TITLE\" sound name \"Submarine\""
        ;;
    Linux)
        if command -v paplay >/dev/null 2>&1; then
            for sound in \
                /usr/share/sounds/freedesktop/stereo/complete.oga \
                /usr/share/sounds/freedesktop/stereo/bell.oga; do
                [ -f "$sound" ] && paplay "$sound" 2>/dev/null & break
            done
        elif command -v aplay >/dev/null 2>&1; then
            [ -f /usr/share/sounds/alsa/Front_Center.wav ] && \
                aplay -q /usr/share/sounds/alsa/Front_Center.wav 2>/dev/null &
        fi

        if command -v notify-send >/dev/null 2>&1; then
            notify-send "$TITLE" "$MESSAGE"
        fi
        ;;
esac

exit 0

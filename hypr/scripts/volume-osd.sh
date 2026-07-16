#!/usr/bin/env bash

# Keep volume control independent from the notification daemon: wpctl runs
# first, and a failed notification can never prevent the volume change.

set -u

sink='@DEFAULT_AUDIO_SINK@'
source='@DEFAULT_AUDIO_SOURCE@'

case "${1:-}" in
  raise)
    wpctl set-volume -l 1 "$sink" 5%+ || exit 1
    device=$sink
    title=Volume
    ;;
  lower)
    wpctl set-volume "$sink" 5%- || exit 1
    device=$sink
    title=Volume
    ;;
  mute)
    wpctl set-mute "$sink" toggle || exit 1
    device=$sink
    title=Volume
    ;;
  mic-mute)
    wpctl set-mute "$source" toggle || exit 1
    device=$source
    title=Microphone
    ;;
  *)
    echo "usage: ${0##*/} raise|lower|mute|mic-mute" >&2
    exit 2
    ;;
esac

# The volume operation has already succeeded, so any OSD failure from here is
# deliberately non-fatal.
state=$(wpctl get-volume "$device") || exit 0
volume=$(awk '{print $2}' <<<"$state")
percent=$(awk -v volume="$volume" 'BEGIN { printf "%.0f", volume * 100 }')

if [[ $state == *MUTED* ]]; then
  body=Muted
  progress=0
else
  body="${percent}%"
  progress=$percent
fi

runtime_dir=${XDG_RUNTIME_DIR:-/tmp}
notification_id_file="${runtime_dir}/volume-osd-${UID}.id"
notification_lock_file="${runtime_dir}/volume-osd-${UID}.lock"

# Repeated volume keys can start several copies at once. Serialize only the
# notification step, then replace the exact server-issued ID from last time.
exec 9>"$notification_lock_file"
flock 9 || exit 0

replace_args=()
if read -r previous_id <"$notification_id_file" 2>/dev/null &&
   [[ $previous_id =~ ^[0-9]+$ ]]; then
  replace_args=(--replace-id="$previous_id")
fi

notification_id=$(notify-send \
  --app-name=volume-osd \
  --print-id \
  "${replace_args[@]}" \
  --expire-time=1200 \
  --transient \
  --hint="int:value:${progress}" \
  "$title" "$body" 2>/dev/null) || exit 0

if [[ $notification_id =~ ^[0-9]+$ ]]; then
  printf '%s\n' "$notification_id" >"$notification_id_file"
fi

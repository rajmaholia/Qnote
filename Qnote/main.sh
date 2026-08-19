#!/usr/bin/env bash

set -uo pipefail

###############################################################################
# Configuration
###############################################################################

ROOT_QNOTE_DIR="$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")"
VAULT="$HOME/QuickCenter/Notes"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/qnote"
STATE_FILE="$STATE_DIR/current_buffer"

WIDTH=800
HEIGHT=700
FONT="JetBrainsMonoNerdFont 16"

#### load scripts
source "$ROOT_QNOTE_DIR/helper.sh"
source "$ROOT_QNOTE_DIR/note_action.sh"
#########################################

#### Avoids ui duplication if the user run the script multiple times .
singleton() {
  local lock="$STATE_DIR/qnote.lock"

  exec 9>"$lock"

  if ! flock -n 9; then
    exit 0
  fi
}

### Execution Entry point
main() {
  mkdir -p "$STATE_DIR"
  singleton

  if [[ ! -f "$STATE_FILE" ]]; then
    touch "$STATE_FILE"
  fi

  case "${1:-}" in
  "--change-buffer") choose_buffer ;;
  "--main-dir") : ;;
  esac

  if [[ ! -s "$STATE_FILE" ]]; then
    choose_buffer
  fi

  RELATIVE_PATH=$(<"$STATE_FILE")
  NOTE_FILE_ABSOLUTE_PATH="$VAULT/$RELATIVE_PATH"

  main_event_loop
}

###############################################################################
# Main Event Loop. Escape to save
###############################################################################
main_event_loop() {
  local CONTENT
  local TMP
  local STATUS

  while true; do
    if CONTENT=$(open_note "$NOTE_FILE_ABSOLUTE_PATH"); then
      STATUS=0
    else
      STATUS=$?
    fi

    case $STATUS in
    0)
      ## Save and Exit
      if save "$NOTE_FILE_ABSOLUTE_PATH" "$CONTENT"; then
        notify-send "QNote" "Saved $RELATIVE_PATH"
      else
        notify-send "Can't save the note."
      fi
      return 0
      ;;

    11)
      ## Create new note
      local name_new_file
      if name_new_file=$(create_new); then
        NOTE_FILE_ABSOLUTE_PATH="$VAULT/$name_new_file"
      else
        notify-send "Error : Unable to create new note."
      fi
      ;;
    12)
      ## Opens a picker winodw to open existing note
      choose_existing
      ;;
    *)
      return 1
      ;;
    esac
  done
}

main "$@"

choose_buffer() {
  local action

  if ! action=$(
    printf "Open Existing Note\nCreate New Note\n" |
      yad \
        --list \
        --title="QNote Buffer" \
        --text="<big><big>Choose a buffer</big></big>" \
        --text-align=center \
        --column="Action" \
        --width=350 \
        --height=100 \
        --separator="" \
        --no-headers
  ); then
    exit 0
  fi

  case "$action" in
  "Open Existing Note")
    choose_existing
    ;;

  "Create New Note")
    create_new
    ;;
  esac
}

choose_existing() {
  local file
  mapfile -t files < <(
    find "$VAULT" \
      -type f \
      -name '*.md' \
      -printf '%P\n' |
      sort
  )
  if ! file=$(
    yad \
      --list \
      --title="Select Buffer" \
      --column="Markdown Files" \
      --width=700 \
      --height=500 \
      --separator="" \
      "${files[@]}"
  ); then
    exit 0
  fi
  [[ -z "$file" ]] && exit 0

  printf "%s" "$file" >"$STATE_FILE"
}

create_new() {
  local name

  if ! name=$(
    yad --entry --ricon=gtk-clear \
      --width=500 \
      --text="<span><big><big><b>My Note's Name</b></big></big></span>"
  ); then
    return 1
  fi
  [[ -z "$name" ]] && return 1

  [[ "$name" != *.md ]] && name="${name}.md"

  mkdir -p "$VAULT/$(dirname "$name")"
  touch "$VAULT/$name"
  printf "%s" "$name" >"$STATE_FILE"

  printf "%s" "$name" # return file name
  return 0
}

save() {
  [[ -z $1 || -z $2 ]] && return 1

  local note_file=$1
  local content_new=$2
  local temp_file

  content_new=$(trim "$content_new")
  ## check the content is changed .

  [[ -f "$note_file" && $(<"$note_file") == "$content_new" ]] && return 0

  temp_file=$(mktemp) || return 1

  trap 'rm -f "$temp_file"' RETURN

  printf '%s' "$content_new" >"$temp_file" || return 1
  mv -- "$temp_file" "$note_file" || return 1

  trap - RETURN
  return 0
}

note_error() {
  local file="$1"
  yad \
    --error \
    --title="QNote" \
    --text="Buffer file does not exist:\n\n$file" \
    --width="$WIDTH" --height="$HEIGHT" \
    --button="Create New:2" \
    --button="Open Existing:3" \
    --button="Cancel:1"
  return $?
}

note_editor() {
  [[ -z $1 || ! -f "$1" ]] && return 1

  local path_note_file="$1"
  local content_new
  local content_original
  local option_code

  local filename="${path_note_file##*/}"
  content_original=$(<"$path_note_file")

  if content_new=$(
    printf "%s" "$content_original" |
      yad \
        --title="QNote - $filename" \
        --text="QNote- $filename" --text-align=center \
        --text-info \
        --editable \
        --width="$WIDTH" --height="$HEIGHT" \
        --fontname="$FONT" \
        --escape-ok --wrap \
        --button="Create New:11" \
        --button="Open Existing:12" \
        --button="Save:0" \
        --button="Cancel:1"
  ); then
    option_code=0
  else
    option_code=$?
  fi
  printf "%s" "$content_new"
  return $option_code
}

open_note() {
  local status_code
  local content=""
  if [[ -z $1 || ! -f "$1" ]]; then
    content=$(note_error "$1")
    status_code=$?
  else
    content=$(note_editor "$1")
    status_code=$?
  fi
  printf "%s" "$content"
  return $status_code
}

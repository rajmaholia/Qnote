info() {
  echo "$1" >&2
}

trim() {
  local s=${1:-}

  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"

  printf '%s' "$s"
}

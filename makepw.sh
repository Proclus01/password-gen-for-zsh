# makepw: cryptographically strong password generator for Zsh
# Usage:
#   makepw                 # one 20-char password
#   makepw 25              # one 25-char password
#   makepw -n 5            # five 20-char passwords
#   makepw -n 5 35         # five 35-char passwords
#   makepw -h|--help       # show help

makepw() {
  emulate -L zsh                       # localize options & use Zsh semantics
  setopt pipefail                      # propagate pipeline failures

  # --- defaults ---
  local -i count=1
  local -i length=20

  # Pin locale for both pattern classes and tr (predictable ASCII classes).
  local LC_ALL=C LANG=C

  # --- usage helper ---
  local _usage=$'makepw: cryptographically strong password generator\n\n'\
'Usage:\n'\
'  makepw                 # one 20-char password\n'\
'  makepw 25              # one 25-char password\n'\
'  makepw -n 5            # five 20-char passwords\n'\
'  makepw -n 5 35         # five 35-char passwords\n'\
'  makepw -h|--help       # show this help\n'

  # --- parse args (backward-compatible) ---
  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    printf '%s' "$_usage"
    return 0
  fi

  if [[ "$1" == "-n" && "$2" == <-> ]]; then
    count=$2
    shift 2
  fi

  if [[ "$1" == <-> ]]; then
    length=$1
    shift
  fi

  if (( $# > 0 )); then
    printf 'makepw: unexpected arguments: %s\n' "$*" >&2
    printf '%s' "$_usage" >&2
    return 2
  fi

  # --- validate ---
  if (( count < 1 )); then
    printf 'makepw: count must be >= 1\n' >&2
    return 1
  fi
  if (( length < 1 )); then
    printf 'makepw: length must be >= 1\n' >&2
    return 1
  fi

  # --- generator ---
  # Allowed set: printable non-space ASCII (letters, digits, punctuation) -> 94 chars.
  # We sample uniformly via /dev/urandom filtered by tr; diversity enforced by rejection.
  local pw
  local -i i
  for (( i = 1; i <= count; i++ )); do
    if (( length >= 4 )); then
      # Rejection sampling: draw until all four classes appear.
      while true; do
        # Sample exactly $length characters from the 94-char set.
        pw=$(tr -dc '[:alnum:][:punct:]' < /dev/urandom | head -c "$length")
        # Ensure we actually got $length characters (belt-and-suspenders).
        (( ${#pw} == length )) || continue
        # Diversity check using POSIX classes in C locale.
        [[ $pw == *[[:upper:]]* ]] || continue
        [[ $pw == *[[:lower:]]* ]] || continue
        [[ $pw == *[[:digit:]]* ]] || continue
        [[ $pw == *[[:punct:]]* ]] || continue
        break
      done
    else
      # For length 1–3, diversity of 4 classes is impossible—just sample uniformly.
      # Loop until we have the requested length (highly likely on first pass).
      while true; do
        pw=$(tr -dc '[:alnum:][:punct:]' < /dev/urandom | head -c "$length")
        (( ${#pw} == length )) && break
      done
    fi

    # PRINT SAFELY: no escape processing; never interpret backslashes, percents, etc.
    printf '%s\n' "$pw"
  done
}

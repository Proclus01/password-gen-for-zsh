# BRIEF INSTRUCTIONS ON USE:

# makepw: cryptographically strong password generator for Zsh
# Usage:
#   makepw                 # one 20-char password
#   makepw 25              # one 25-char password
#   makepw -n 5            # five 20-char passwords
#   makepw -n 5 35         # five 35-char passwords

makepw() {
  emulate -L zsh                      # keep options local and Zsh semantics
  set -o pipefail

  local count=1
  local length=20

  # Parse -n COUNT
  if [[ "$1" == "-n" && "$2" == <-> ]]; then
    count=$2
    shift 2
  fi

  # Trailing LENGTH
  if [[ "$1" == <-> ]]; then
    length=$1
    shift
  fi

  # Validate inputs
  if (( count < 1 )); then
    print -u2 "makepw: count must be >= 1"
    return 1
  fi
  if (( length < 1 )); then
    print -u2 "makepw: length must be >= 1"
    return 1
  fi

  # Allowed character set: all printable non-space ASCII (94 symbols).
  # In C locale, '[:alnum:]' + '[:punct:]' = letters + digits + punctuation.
  # We read from /dev/urandom indefinitely and let head stop after 'length'.
  for ((i=1; i<=count; i++)); do
    local pw=""
    if (( length >= 4 )); then
      # Rejection sampling: generate until diversity constraints are satisfied.
      while true; do
        pw=$(LC_ALL=C tr -dc '[:alnum:][:punct:]' < /dev/urandom | head -c "$length")
        # Diversity checks; Zsh pattern classes are locale-aware; force C.
        if [[ -n "$pw" ]] \
           && [[ "$pw" == *[[:upper:]]* ]] \
           && [[ "$pw" == *[[:lower:]]* ]] \
           && [[ "$pw" == *[[:digit:]]* ]] \
           && [[ "$pw" == *[[:punct:]]* ]]; then
          break
        fi
      done
    else
      # For length 1–3 it is impossible to include all 4 classes.
      # We still sample uniformly from the 94-character set.
      pw=$(LC_ALL=C tr -dc '[:alnum:][:punct:]' < /dev/urandom | head -c "$length")
      # Ensure 'head' delivered the full length (it should, but be safe).
      while [[ ${#pw} -lt $length ]]; do
        pw+=$(LC_ALL=C tr -dc '[:alnum:][:punct:]' < /dev/urandom | head -c $((length - ${#pw})))
      done
    fi
    # Print without interpreting backslashes; avoid echo oddities.
    print -- "$pw"
  done
}
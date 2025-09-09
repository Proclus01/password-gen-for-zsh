# makepw: cryptographically strong password generator for Zsh
# Usage:
#   makepw                   # one 20-char password
#   makepw 25                # one 25-char password
#   makepw -n 5              # five 20-char passwords
#   makepw -n 5 35           # five 35-char passwords
#   makepw --no-punct        # letters+digits only
#   makepw --alnum-only      # same as --no-punct (alias)
#   makepw --avoid-ambiguous # exclude O 0 I l 1 |
#   makepw --clipboard       # (macOS) copy to clipboard with confirmation
#   makepw -h | makepw --help

makepw() {
  emulate -L zsh
  setopt pipefail

  # ---- defaults ----
  local -i count=1
  local -i length=20
  local -i include_punct=1
  local -i avoid_ambiguous=0
  local -i use_clipboard=0

  # Pin locale for predictable ASCII classes
  local LC_ALL=C LANG=C

  # ---- help text ----
  local _usage=$'makepw: cryptographically strong password generator\n\n'\
'Usage:\n'\
'  makepw                   # one 20-char password\n'\
'  makepw 25                # one 25-char password\n'\
'  makepw -n 5              # five 20-char passwords\n'\
'  makepw -n 5 35           # five 35-char passwords\n'\
'  makepw --no-punct        # letters+digits only\n'\
'  makepw --alnum-only      # alias of --no-punct\n'\
'  makepw --avoid-ambiguous # exclude O 0 I l 1 |\n'\
'  makepw --clipboard       # (macOS) copy to clipboard with confirmation\n'\
'  makepw -h | makepw --help\n\n'\
'Notes:\n'\
'  • Do NOT type a pipe (|) between -h and --help. Use either one:\n'\
'      makepw -h\n'\
'      makepw --help\n'

  # ---- parse args (backward-compatible) ----
  while (( $# )); do
    case "$1" in
      -h|--help)
        printf '%s' "$_usage"
        return 0
        ;;
      -n|--count)
        shift
        if [[ "$1" == <-> ]]; then
          count=$1; shift
        else
          printf 'makepw: %s requires an integer\n' "${${(q)0}:--count}" >&2
          return 2
        fi
        ;;
      --length)
        shift
        if [[ "$1" == <-> ]]; then
          length=$1; shift
        else
          printf 'makepw: --length requires an integer\n' >&2
          return 2
        fi
        ;;
      --no-punct|--alnum-only)
        include_punct=0; shift
        ;;
      --avoid-ambiguous)
        avoid_ambiguous=1; shift
        ;;
      --clipboard|--clip)
        use_clipboard=1; shift
        ;;
      --)
        shift; break
        ;;
      <->)  # trailing LENGTH (positional)
        length=$1; shift
        ;;
      *)
        printf 'makepw: unknown option: %s\n' "$1" >&2
        printf 'Tip: use "makepw -h" or "makepw --help" (no pipe "|").\n' >&2
        return 2
        ;;
    esac
  done

  # no extra args expected
  if (( $# > 0 )); then
    printf 'makepw: unexpected arguments: %s\n' "$*" >&2
    return 2
  fi

  # ---- validate ----
  if (( count < 1 )); then
    printf 'makepw: count must be >= 1\n' >&2
    return 1
  fi
  if (( length < 1 )); then
    printf 'makepw: length must be >= 1\n' >&2
    return 1
  fi

  # ---- configuration of character set ----
  local tr_filter
  if (( include_punct )); then
    tr_filter='[:alnum:][:punct:]'   # 94 printable ASCII
  else
    tr_filter='[:alnum:]'            # 62 ASCII letters+digits
  fi

  # Ambiguous characters to exclude (when requested)
  local ambiguous='O0Il1|'

  # Diversity rule: require one of each included class
  local -i need_upper=1 need_lower=1 need_digit=1 need_punct=0
  (( include_punct )) && need_punct=1

  local -i required_classes=$(( need_upper + need_lower + need_digit + need_punct ))
  if (( length < required_classes )); then
    # Too short to satisfy all required classes—fall back to uniform sampling.
    printf 'makepw: note: length (%d) < required classes (%d); diversity check skipped.\n' "$length" "$required_classes" >&2
    need_upper=0; need_lower=0; need_digit=0; need_punct=0
    required_classes=0
  fi

  # ---- generator ----
  local -a pwlist=()
  local pw chunk
  local -i i

  for (( i = 1; i <= count; i++ )); do
    while true; do
      pw=""
      # Fill to exact length with a uniformly filtered stream.
      while (( ${#pw} < length )); do
        # Read a large chunk to amortize syscalls; then filter.
        chunk=$(head -c 32768 /dev/urandom | LC_ALL=C tr -dc "$tr_filter")
        if (( avoid_ambiguous )); then
          # Drop ambiguous characters; top up again if needed.
          chunk=$(printf '%s' "$chunk" | LC_ALL=C tr -d "$ambiguous")
        fi
        pw+="$chunk"
      done
      pw="${pw:0:length}"

      # Diversity checks (only for included classes)
      local -i ok=1
      if (( need_upper )) && [[ $pw != *[[:upper:]]* ]]; then ok=0; fi
      if (( need_lower )) && [[ $pw != *[[:lower:]]* ]]; then ok=0; fi
      if (( need_digit )) && [[ $pw != *[[:digit:]]* ]]; then ok=0; fi
      if (( need_punct )) && [[ $pw != *[[:punct:]]* ]]; then ok=0; fi

      (( ok )) && break
      # else: rejection sampling—draw again
    done

    pwlist+="$pw"
    # Print safely (no escape interpretation)
    printf '%s\n' "$pw"
  done

  # ---- optional clipboard copy (macOS) ----
  if (( use_clipboard )); then
    if command -v pbcopy >/dev/null 2>&1; then
      local joined="${(j:\n:)pwlist}"
      local answer=""
      # Prompt on a TTY; fall back to skipping copy if no TTY.
      if [[ -r /dev/tty ]]; then
        printf 'Copy the generated password(s) to your clipboard? [y/N] ' > /dev/tty
        IFS= read -r answer < /dev/tty || answer=""
      fi
      if [[ $answer == [Yy]* ]]; then
        printf '%s' "$joined" | pbcopy
        printf 'makepw: copied %d password(s) to clipboard.\n' "$count" >&2
      else
        printf 'makepw: skipped clipboard copy.\n' >&2
      fi
    else
      printf 'makepw: --clipboard requested but pbcopy not found on this system.\n' >&2
      return 3
    fi
  fi
}

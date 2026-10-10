#!/usr/bin/env bash
# Usage: ./tests/run_smoke_tests.sh [--static] [--dist DIR]
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST="$ROOT_DIR/dist"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --static)
      DIST="$ROOT_DIR/dist-static"
      shift
      ;;
    --dist)
      DIST="$(cd "$2" && pwd)"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

NANO="$DIST/bin/nano"
TMP="$(mktemp -d)"
export HOME="$TMP/home"
mkdir -p "$HOME"
trap 'rm -rf "$TMP"' EXIT

pass() { echo "ok: $*"; }
fail() {
  echo "FAIL: $*" >&2
  exit 1
}

version="$("$NANO" --version | head -n 1)"
echo "$version" | grep -q '^ GNU nano, version ' || fail "nano --version: $version"
pass "$version"

# edits a file (with python3 at hand) in a pseudo terminal with no terminfo database reachable, so nano must draw with the
# entries compiled into ncurses: types a line, saves with ^O, confirms with Enter, quits with ^X.
if command -v python3 >/dev/null; then
python3 - "$NANO" "$TMP/out.txt" <<'PY' || fail "editing a file"
import os, pty, sys, time

nano, path = sys.argv[1:3]
env = dict(os.environ, TERM="xterm-256color", TERMINFO="/nonexistent", TERMINFO_DIRS="/nonexistent")
pid, fd = pty.fork()
if pid == 0:
    os.execve(nano, [nano, "--ignorercfiles", path], env)

def feed(data, wait=0.5):
    time.sleep(wait)
    os.write(fd, data)

feed(b"hello-from-nano\n", 1.0)
feed(b"\x0f", 0.5)  # ^O
feed(b"\r", 0.5)
feed(b"\x18", 0.5)  # ^X
# drains the output until nano exits
deadline = time.time() + 10
while time.time() < deadline:
    try:
        if not os.read(fd, 65536):
            break
    except OSError:
        break
_, status = os.waitpid(pid, 0)
sys.exit(0 if os.WIFEXITED(status) and os.WEXITSTATUS(status) == 0 else 1)
PY
  grep -q '^hello-from-nano$' "$TMP/out.txt" || fail "file not written by nano"
  pass "edit and save in a terminal without terminfo"
else
  echo "skipped: editing a file, python3 is missing"
fi

# the syntax definitions and their include line for ~/.nanorc
ls "$DIST"/share/nano/*.nanorc >/dev/null 2>&1 || fail "no syntax definitions"
pass "syntax definitions"

if [ "$(uname -s)" = Linux ] && ! LC_ALL=C grep -a -q 'ld-musl' "$NANO"; then
  max="$(LC_ALL=C grep -aoh 'GLIBC_2\.[0-9]*' "$NANO" | sort -uV | tail -n 1)" || true
  if [ -n "$max" ]; then
    [ "$(printf '%s\n' "$max" GLIBC_2.17 | sort -V | tail -n 1)" = GLIBC_2.17 ] \
      || fail "needs $max, newer than GLIBC_2.17"
    pass "glibc floor ($max)"
  fi
fi

echo "all smoke tests passed"

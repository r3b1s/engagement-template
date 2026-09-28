#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Enable the Nix CLI and flakes in nix.conf.

Usage:
  ./nix-setup.sh [--system | --user]

  --system  Configure /etc/nix/nix.conf (default; requires root/sudo)
  --user    Configure $XDG_CONFIG_HOME/nix/nix.conf, or ~/.config/nix/nix.conf
  -h, --help

The script preserves other settings and existing experimental features. It
backs up the config before changing it. No daemon restart is normally needed.
EOF
}

mode=system
while (($#)); do
  case "$1" in
    --system) mode=system ;;
    --user) mode=user ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

if ! command -v python3 >/dev/null 2>&1; then
  echo "This script requires Python 3 to safely preserve the existing config." >&2
  exit 1
fi

if [[ "$mode" == system ]]; then
  config=/etc/nix/nix.conf
  if (( EUID != 0 )); then
    if ! command -v sudo >/dev/null 2>&1; then
      echo "System-wide configuration requires root. Re-run as root or install sudo." >&2
      exit 1
    fi
    script_path=$(realpath "$0")
    exec sudo -- "$script_path" --system
  fi
else
  config="${XDG_CONFIG_HOME:-$HOME/.config}/nix/nix.conf"
fi

python3 - "$config" <<'PY'
from datetime import datetime
from pathlib import Path
import os
import re
import shutil
import sys
import tempfile

path = Path(sys.argv[1])
path.parent.mkdir(parents=True, exist_ok=True)
original = path.read_text() if path.exists() else ""
lines = original.splitlines(keepends=True)
pattern = re.compile(r"^\s*experimental-features\s*=\s*(.*?)\s*(?:#.*)?$")
features = {"nix-command", "flakes"}
first_match = None
kept = []

for line in lines:
    match = pattern.match(line.rstrip("\r\n"))
    if match:
        if first_match is None:
            first_match = len(kept)
        features.update(match.group(1).split())
    else:
        kept.append(line)

newline = "\r\n" if "\r\n" in original else "\n"
setting = "experimental-features = " + " ".join(sorted(features)) + newline
if first_match is None:
    if kept and not kept[-1].endswith(("\n", "\r")):
        kept[-1] += newline
    new_text = "".join(kept) + setting
else:
    kept.insert(first_match, setting)
    new_text = "".join(kept)

if new_text == original:
    print(f"Already configured: {path}")
    raise SystemExit(0)

if path.exists():
    stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    backup = path.with_name(path.name + ".bak-" + stamp)
    shutil.copy2(path, backup)
    print(f"Backup: {backup}")

mode = path.stat().st_mode & 0o777 if path.exists() else 0o644
fd, temporary = tempfile.mkstemp(prefix=path.name + ".", dir=path.parent)
try:
    with os.fdopen(fd, "w") as output:
        output.write(new_text)
        output.flush()
        os.fsync(output.fileno())
    os.chmod(temporary, mode)
    os.replace(temporary, path)
finally:
    if os.path.exists(temporary):
        os.unlink(temporary)

print(f"Enabled nix-command and flakes in {path}")
PY

if command -v nix >/dev/null 2>&1; then
  if nix flake --help >/dev/null 2>&1; then
    echo "Verified: 'nix flake' is available."
  else
    echo "Config updated. Start a new shell and check Nix installation/configuration if 'nix flake' is still unavailable." >&2
  fi
else
  echo "Config updated. Nix was not found on PATH, so availability could not be checked."
fi

#!/usr/bin/env python3
"""Stage an updated greeter and keep the previous installation intact."""

import os
from pathlib import Path
import subprocess
import sys
import tempfile


def main():
    if len(sys.argv) != 3:
        raise ValueError("expected themes directory and shared data directory")
    themes, data = (Path(arg) for arg in sys.argv[1:])
    if not themes.is_absolute() or not themes.is_dir() or not data.is_absolute():
        raise ValueError("directories must exist and be absolute")
    destination = themes / "notch-lock"
    backup = themes / "notch-lock-backup"
    if destination.is_symlink() or not destination.is_dir():
        raise ValueError("installed notch-lock must be a real directory")
    if backup.exists() or backup.is_symlink():
        raise ValueError("backup already exists; refusing to overwrite it")
    link = destination / "theme.conf.user"
    if not link.is_symlink() or os.readlink(link) != str(data / "theme.conf.user"):
        raise ValueError("installed shared configuration link differs; refusing update")
    staging = Path(tempfile.mkdtemp(prefix=".notch-update-", dir=themes))
    installer = Path(__file__).resolve().parent / "install-sddm-theme.py"
    subprocess.run([sys.executable, str(installer), str(staging), str(data)], check=True)
    backup.mkdir(mode=0o755)
    os.chmod(backup, 0o755)
    destination.rename(backup / "notch-lock")
    try:
        (staging / "notch-lock").rename(destination)
    except OSError:
        (backup / "notch-lock").rename(destination)
        raise
    staging.rmdir()
    print("Updated notch-lock; previous theme saved at", backup / "notch-lock")
    print("SDDM was not restarted.")


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        print(f"SDDM update failed: {error}", file=sys.stderr)
        sys.exit(1)

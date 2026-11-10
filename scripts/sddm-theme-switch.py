#!/usr/bin/env python3
"""Select or disable the notch theme override without editing existing config."""

import os
from pathlib import Path
import sys


CONTENT = "[Theme]\nCurrent=notch-lock\n"


def main():
    if len(sys.argv) != 3 or sys.argv[1] not in ("activate", "restore"):
        raise ValueError("expected activate|restore and an absolute config directory")
    action = sys.argv[1]
    directory = Path(sys.argv[2])
    if not directory.is_absolute() or not directory.is_dir():
        raise ValueError("config directory must exist and be absolute")
    override = directory / "zz-notch-lock.conf"
    backup_dir = directory.with_name(directory.name + "-notch-backups")
    disabled = backup_dir / "zz-notch-lock.conf"
    if action == "activate":
        with override.open("x") as output:
            output.write(CONTENT)
        os.chmod(override, 0o644)
        print("Created notch-lock override; SDDM was not restarted.")
    else:
        if override.is_symlink() or not override.is_file() or override.read_text() != CONTENT:
            raise ValueError("override is missing or differs; refusing to alter it")
        # SDDM reads every regular file in its config directory, regardless of extension.
        backup_dir.mkdir(mode=0o700, exist_ok=True)
        if backup_dir.is_symlink() or not backup_dir.is_dir():
            raise ValueError("backup directory is not a real directory")
        # Preserve the exact override outside that directory; never replace one.
        os.link(override, disabled, follow_symlinks=False)
        override.unlink()
        print("Disabled notch-lock override; SDDM was not restarted.")


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError) as error:
        print(f"SDDM switch failed: {error}", file=sys.stderr)
        sys.exit(1)

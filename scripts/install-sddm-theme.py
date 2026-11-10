#!/usr/bin/env python3
"""Copy the notch greeter as a separate theme, without activating it."""

import os
from pathlib import Path
import shutil
import sys


def main():
    if len(sys.argv) != 3:
        raise ValueError("expected themes directory and shared data directory")
    themes = Path(sys.argv[1])
    data = Path(sys.argv[2])
    if not themes.is_absolute() or not data.is_absolute():
        raise ValueError("directories must be absolute paths")
    if not themes.is_dir() or not (data / "theme.conf.user").is_file():
        raise ValueError("themes directory or shared configuration is missing")
    source = Path(__file__).resolve().parent.parent / "sddm/notch"
    files = ("Main.qml", "metadata.desktop", "theme.conf", "icons/rotate-ccw.svg",
             "icons/keyboard.svg", "icons/power.svg", "icons/chevron-left.svg",
             "icons/LICENSE", "shaders/keyboard.frag.qsb")
    for name in files:
        path = source / name
        if path.is_symlink() or not path.is_file():
            raise ValueError("theme source is missing or is a symbolic link: " + name)
    destination = themes / "notch-lock"
    # mkdir is exclusive: an existing theme (including a symlink) is never replaced.
    destination.mkdir(mode=0o755)
    (destination / "icons").mkdir(mode=0o755)
    (destination / "shaders").mkdir(mode=0o755)
    os.chmod(destination, 0o755)
    os.chmod(destination / "icons", 0o755)
    os.chmod(destination / "shaders", 0o755)
    for name in files:
        target = destination / name
        shutil.copyfile(source / name, target)
        os.chmod(target, 0o644)
    (destination / "theme.conf.user").symlink_to(data / "theme.conf.user")
    print("Installed notch-lock without changing the active SDDM theme:", destination)


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError) as error:
        print(f"SDDM theme installation failed: {error}", file=sys.stderr)
        sys.exit(1)

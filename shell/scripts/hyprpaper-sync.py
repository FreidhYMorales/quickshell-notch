#!/usr/bin/env python3
"""Prepare an atomic hyprpaper startup configuration from a saved snapshot."""

import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile


def main():
    if len(sys.argv) != 3:
        raise ValueError("expected state directory and wallpaper snapshot")
    directory = Path(sys.argv[1])
    snapshot = json.loads(sys.argv[2])
    fallback = snapshot["fallback"]
    screens = snapshot["perScreen"]
    if not isinstance(fallback, str) or not isinstance(screens, dict):
        raise ValueError("invalid wallpaper snapshot")
    directory.mkdir(parents=True, exist_ok=True)
    cache = directory / "hyprpaper-frames"
    cache.mkdir(exist_ok=True)

    def render(path):
        source = Path(path)
        if not source.is_absolute() or not source.is_file():
            raise ValueError("wallpaper is missing: " + path)
        if source.suffix.lower() in (".gif", ".mp4", ".webm", ".mkv", ".mov", ".avi", ".m4v"):
            info = source.stat()
            key = hashlib.sha256((str(source) + str(info.st_mtime_ns) + str(info.st_size)).encode()).hexdigest()
            frame = cache / (key + ".png")
            if not frame.is_file():
                with tempfile.NamedTemporaryFile(dir=cache, suffix=".png", delete=False) as temp:
                    temporary = Path(temp.name)
                try:
                    subprocess.run(["ffmpeg", "-nostdin", "-hide_banner", "-loglevel", "error", "-y", "-i", str(source), "-frames:v", "1", str(temporary)], check=True, timeout=120)
                    os.replace(temporary, frame)
                finally:
                    temporary.unlink(missing_ok=True)
            source = frame
        result = str(source)
        if any(char in result for char in "\n\r{}"):
            raise ValueError("unsupported wallpaper path")
        return result

    entries = []
    if fallback:
        entries.append(("", render(fallback)))
    for screen, path in sorted(screens.items()):
        if not isinstance(screen, str) or not isinstance(path, str) or any(c in screen for c in "\n\r{}"):
            raise ValueError("invalid screen mapping")
        entries.append((screen, render(path)))
    if not entries:
        raise ValueError("no wallpaper configured")
    contents = "".join("wallpaper {\n    monitor = " + screen + "\n    path = " + path + "\n}\n" for screen, path in entries)
    with tempfile.NamedTemporaryFile(mode="w", dir=directory, delete=False) as config:
        temporary = Path(config.name)
        try:
            config.write(contents)
            config.flush()
            os.replace(temporary, directory / "hyprpaper.conf")
        finally:
            temporary.unlink(missing_ok=True)


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, KeyError, TypeError, subprocess.SubprocessError) as error:
        print("hyprpaper sync:", error, file=sys.stderr)
        sys.exit(1)

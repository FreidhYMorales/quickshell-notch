#!/usr/bin/env python3
"""Publish a single immutable wallpaper and its palette for a greeter."""

import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import stat
import sys
import tempfile


def publish(image, palette_arg, output, notch_width=None):
    if not output.is_absolute() or output.is_symlink():
        raise ValueError("output must be an absolute, non-symlink directory")
    if notch_width is not None and not 80 <= notch_width <= 4096:
        raise ValueError("invalid notch width")
    info = output.stat()
    if not stat.S_ISDIR(info.st_mode) or info.st_uid != os.getuid() or info.st_mode & 0o022:
        raise ValueError("output must be owned by this user and not group/other writable")
    if output.resolve() != output:
        raise ValueError("output path must not contain symlinks or relative components")
    suffix = image.suffix.lower()
    if suffix not in (".png", ".jpg", ".jpeg", ".webp", ".gif", ".mp4", ".mkv", ".webm", ".mov", ".avi", ".m4v"):
        raise ValueError("unsupported background format")
    colors = json.loads(palette_arg if palette_arg.startswith("{") else Path(palette_arg).read_text())["colors"]
    accent, foreground = colors["primary"]["hex"], colors["on_surface"]["hex"]
    if not all(isinstance(value, str) and re.fullmatch(r"#[a-fA-F0-9]{6}", value) for value in (accent, foreground)):
        raise ValueError("invalid palette")

    fd = os.open(output / ".publish.lock", os.O_WRONLY | os.O_CREAT | os.O_NOFOLLOW | os.O_NONBLOCK, 0o600)
    with os.fdopen(fd, "w") as lock:
        if not stat.S_ISREG(os.fstat(lock.fileno()).st_mode):
            raise ValueError("lock must be a regular file")
        fcntl.flock(lock, fcntl.LOCK_EX)
        staged = None
        manifest = None
        try:
            digest = hashlib.sha256()
            with tempfile.NamedTemporaryFile(dir=output, prefix=".stage-", delete=False) as dest:
                staged = Path(dest.name)
                with image.open("rb") as source:
                    while chunk := source.read(1024 * 1024):
                        digest.update(chunk)
                        dest.write(chunk)
                os.fchmod(dest.fileno(), 0o640)
            name = "background-" + digest.hexdigest() + suffix
            background = output / name
            try:
                os.link(staged, background, follow_symlinks=False)
            except FileExistsError:
                fd = os.open(background, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
                with os.fdopen(fd, "rb") as existing:
                    existing_info = os.fstat(existing.fileno())
                    if not stat.S_ISREG(existing_info.st_mode) or existing_info.st_mode & 0o777 != 0o640:
                        raise ValueError("existing background has unsafe type or permissions")
                    existing_hash = hashlib.sha256()
                    while chunk := existing.read(1024 * 1024):
                        existing_hash.update(chunk)
                    if existing_hash.digest() != digest.digest():
                        raise ValueError("existing background does not match its name")
            staged.unlink()
            staged = None
            with tempfile.NamedTemporaryFile(mode="w", dir=output, prefix=".stage-", delete=False) as dest:
                manifest = Path(dest.name)
                value = {"version": 1, "background": name, "accent": accent, "foreground": foreground}
                # Optional: the greeter falls back to its theme preset.
                if notch_width is not None:
                    value["notchWidth"] = notch_width
                json.dump(value, dest)
                dest.write("\n")
                os.fchmod(dest.fileno(), 0o640)
            target = output / "visual.json"
            if target.is_symlink():
                raise ValueError("manifest must not be a symlink")
            os.replace(manifest, target)
            manifest = None
        finally:
            if staged is not None:
                staged.unlink(missing_ok=True)
            if manifest is not None:
                manifest.unlink(missing_ok=True)


if __name__ == "__main__":
    try:
        if len(sys.argv) not in (4, 5):
            raise ValueError("expected image, colors.json, output directory and optional notch width")
        notch_width = int(sys.argv[4]) if len(sys.argv) == 5 else None
        publish(Path(sys.argv[1]), sys.argv[2], Path(sys.argv[3]), notch_width)
    except (OSError, ValueError, KeyError, TypeError) as error:
        print(f"greetd sync: {error}", file=sys.stderr)
        sys.exit(1)

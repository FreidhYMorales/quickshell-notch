#!/usr/bin/env python3
"""Stage a greeter image and matugen palette in a user-writable directory."""

import json
import hashlib
import fcntl
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
from urllib.parse import unquote, urlparse


def main():
    if len(sys.argv) != 4:
        raise ValueError("expected image, colors.json and output directory")
    image = Path(sys.argv[1])
    palette_arg = sys.argv[2]
    output = Path(sys.argv[3])
    output.mkdir(parents=True, exist_ok=True)
    output = output.resolve()
    fd = os.open(output / ".publish.lock", os.O_WRONLY | os.O_CREAT | os.O_NOFOLLOW, 0o600)
    with os.fdopen(fd, "w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        publish(image, palette_arg, output)


def publish(image, palette_arg, output):
    suffix = image.suffix.lower()
    images = (".png", ".jpg", ".jpeg", ".webp")
    videos = (".mp4", ".mkv", ".webm", ".mov", ".avi", ".m4v")
    if suffix not in images + videos + (".gif",):
        raise ValueError("unsupported background format")
    media_kind = "image" if suffix in images else "video"
    colors = json.loads(palette_arg if palette_arg.startswith("{") else Path(palette_arg).read_text())["colors"]
    primary = colors["primary"]["hex"]
    foreground = colors["on_surface"]["hex"]
    if not all(isinstance(x, str) and re.fullmatch(r"#[0-9a-fA-F]{6}", x) for x in (primary, foreground)):
        raise ValueError("invalid palette")
    # Each configuration points to an immutable image. Replacing the config
    # is then the single publication point for the image/palette pair.
    digest = hashlib.sha256()
    with tempfile.NamedTemporaryFile(dir=output, delete=False) as staged:
        staged_path = Path(staged.name)
        try:
            if suffix == ".gif":
                subprocess.run(["ffmpeg", "-nostdin", "-hide_banner", "-loglevel", "error", "-y", "-i", str(image), "-an", "-vf", "pad=ceil(iw/2)*2:ceil(ih/2)*2", "-pix_fmt", "yuv420p", "-movflags", "+faststart", "-f", "mp4", str(staged_path)], check=True, timeout=120)
                staged.seek(0)
                while chunk := staged.read(1024 * 1024):
                    digest.update(chunk)
            else:
                with image.open("rb") as source:
                    while chunk := source.read(1024 * 1024):
                        digest.update(chunk)
                        staged.write(chunk)
            os.fchmod(staged.fileno(), 0o640)
        except BaseException:
            staged_path.unlink(missing_ok=True)
            raise
    current = None
    config_file = output / "theme.conf.user"
    if config_file.exists():
        for line in config_file.read_text().splitlines():
            if line.startswith("background="):
                parsed = urlparse(line[len("background="):])
                if parsed.scheme == "file":
                    candidate = Path(unquote(parsed.path))
                    if candidate in (output / "background-a", output / "background-b"):
                        current = candidate
                break
    # Reuse the active slot for identical bytes; otherwise replace the
    # inactive slot, leaving the current config's image untouched.
    identical = current and not current.is_symlink() and current.is_file() and current.stat().st_mode & 0o777 == 0o640 and hashlib.sha256(current.read_bytes()).digest() == digest.digest()
    background = current if identical else output / ("background-b" if current == output / "background-a" else "background-a")
    if identical:
        staged_path.unlink()
    else:
        os.replace(staged_path, background)
    with tempfile.NamedTemporaryFile(mode="w", dir=output, delete=False) as config:
        config_path = Path(config.name)
        try:
            config.write(f"[General]\nbackground={background.as_uri()}\nsourceWallpaper={image.resolve().as_uri()}\nmediaKind={media_kind}\naccent={primary}\nforeground={foreground}\n")
            os.fchmod(config.fileno(), 0o640)
        except BaseException:
            config_path.unlink(missing_ok=True)
            raise
    os.replace(config_path, config_file)


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, KeyError, TypeError, json.JSONDecodeError, subprocess.SubprocessError) as error:
        print(f"SDDM sync: {error}", file=sys.stderr)
        sys.exit(1)

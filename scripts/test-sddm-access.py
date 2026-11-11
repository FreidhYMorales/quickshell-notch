#!/usr/bin/env python3
"""Test shared SDDM data permissions in an isolated temporary directory.

Run via sudo from a regular user session. Does not install or activate a theme.
"""

import json
import os
from pathlib import Path
import pwd
import shutil
import subprocess
import struct
import sys
import tempfile
import zlib


def as_user(account):
    def drop():
        os.initgroups(account.pw_name, account.pw_gid)
        os.setgid(account.pw_gid)
        os.setuid(account.pw_uid)
    return drop


def test_png():
    def chunk(kind, data):
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data))
    return b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", 1, 1, 8, 2, 0, 0, 0)) + chunk(b"IDAT", zlib.compress(b"\x00\x11\x22\x33")) + chunk(b"IEND", b"")


def main():
    if os.geteuid() != 0 or not os.environ.get("SUDO_UID"):
        raise ValueError("run this test with sudo from your normal user")
    user = pwd.getpwuid(int(os.environ["SUDO_UID"]))
    greeter = pwd.getpwnam("sddm")
    script = Path(__file__).resolve().parent.parent / "shell/scripts/sddm-sync.py"
    palette = json.dumps({"colors": {"primary": {"hex": "#123456"}, "on_surface": {"hex": "#abcdef"}}})
    with tempfile.TemporaryDirectory(prefix="notch-sddm-access-") as temp:
        base = Path(temp)
        os.chmod(base, 0o711)
        image = base / "fixture.png"
        image.write_bytes(test_png())
        os.chown(image, user.pw_uid, user.pw_gid)
        os.chmod(image, 0o600)
        data = base / "data"
        data.mkdir()
        os.chown(data, user.pw_uid, greeter.pw_gid)
        os.chmod(data, 0o2750)
        subprocess.run([sys.executable, str(script), str(image), palette, str(data)], preexec_fn=as_user(user), check=True, timeout=15)
        config = data / "theme.conf.user"
        check = "import pathlib,sys; from urllib.parse import urlparse,unquote; p=pathlib.Path(sys.argv[1]); c=p.read_text(); b=next(x[11:] for x in c.splitlines() if x.startswith('background=')); assert pathlib.Path(unquote(urlparse(b).path)).read_bytes().startswith(b'\\x89PNG'); assert 'accent=#123456' in c"
        subprocess.run([sys.executable, "-c", check, str(config)], preexec_fn=as_user(greeter), check=True, timeout=15)
        print("PASS: user published and sddm read the isolated background and palette")
        theme = base / "theme"
        shutil.copytree(script.parent.parent.parent / "sddm/notch", theme, ignore=shutil.ignore_patterns("theme.conf.user", "background.jpg"))
        qml = theme / "Main.qml"
        text = qml.read_text()
        marker = "NOTCH_GREETER_CONFIG="
        text = text.replace("    id: root\n", '    id: root\n    Component.onCompleted: console.log("' + marker + '" + config.accent + "," + config.foreground)\n', 1)
        text = text.replace("                source: config.background\n", '                source: config.background\n                onStatusChanged: if (status === Image.Ready) console.log("NOTCH_IMAGE_READY")\n', 1)
        text = text.replace("            VideoOutput {\n                id: backgroundVideo", '            Connections {\n                target: backgroundVideo.videoSink\n                property int frames: 0\n                function onVideoFrameChanged() {\n                    if (backgroundPlayer.playbackState === MediaPlayer.PlayingState && ++frames === 2) console.log("NOTCH_VIDEO_FRAMES")\n                }\n            }\n\n            VideoOutput {\n                id: backgroundVideo', 1)
        qml.write_text(text)
        (theme / "theme.conf.user").symlink_to(config)
        runtime = base / "runtime"
        runtime.mkdir(mode=0o700)
        os.chown(runtime, greeter.pw_uid, greeter.pw_gid)
        env = {"PATH": os.defpath, "HOME": str(base), "XDG_RUNTIME_DIR": str(runtime), "QT_QPA_PLATFORM": "offscreen", "NO_COLOR": "1"}
        try:
            result = subprocess.run(["sddm-greeter-qt6", "--test-mode", "--theme", str(theme)], preexec_fn=as_user(greeter), env=env, capture_output=True, timeout=5)
            output = result.stdout + result.stderr
        except subprocess.TimeoutExpired as error:
            output = (error.stdout or b"") + (error.stderr or b"")
        if (marker + "#123456,#abcdef").encode() not in output.lower().replace(marker.encode().lower(), marker.encode()):
            raise ValueError("greeter did not report expected configuration: " + output.decode(errors="replace")[-2000:])
        if b"NOTCH_IMAGE_READY" not in output:
            raise ValueError("greeter did not decode the shared PNG: " + output.decode(errors="replace")[-2000:])
        print("PASS: isolated sddm greeter loaded the shared palette")
        print("PASS: isolated sddm greeter decoded the shared PNG")
        fixtures = base / "fixtures"
        fixtures.mkdir(mode=0o700)
        os.chown(fixtures, user.pw_uid, user.pw_gid)
        video = fixtures / "fixture.mp4"
        subprocess.run(["ffmpeg", "-nostdin", "-hide_banner", "-loglevel", "error", "-f", "lavfi", "-i", "testsrc=size=32x32:rate=10", "-t", "2", "-pix_fmt", "yuv420p", "-c:v", "libx264", str(video)], preexec_fn=as_user(user), check=True, timeout=15)
        subprocess.run([sys.executable, str(script), str(video), palette, str(data)], preexec_fn=as_user(user), check=True, timeout=15)
        try:
            result = subprocess.run(["sddm-greeter-qt6", "--test-mode", "--theme", str(theme)], preexec_fn=as_user(greeter), env=env, capture_output=True, timeout=8)
            output = result.stdout + result.stderr
        except subprocess.TimeoutExpired as error:
            output = (error.stdout or b"") + (error.stderr or b"")
        if b"NOTCH_VIDEO_FRAMES" not in output:
            raise ValueError("greeter did not decode two video frames: " + output.decode(errors="replace")[-2000:])
        print("PASS: isolated sddm greeter decoded video frames")


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, KeyError, subprocess.SubprocessError) as error:
        print(f"SDDM access test failed: {error}", file=sys.stderr)
        sys.exit(1)

from __future__ import annotations

import json
import shutil
import subprocess
import tempfile
from pathlib import Path

MAX_DURATION_SECONDS = 20.0

class VideoProcessingError(RuntimeError):
    pass

class VideoFrameExtractor:
    def __init__(self, ffmpeg: str | None = None, ffprobe: str | None = None):
        self.ffmpeg = ffmpeg or shutil.which("ffmpeg")
        self.ffprobe = ffprobe or shutil.which("ffprobe")

    def duration(self, path: str) -> float | None:
        if not self.ffprobe:
            return None
        try:
            result = subprocess.run([self.ffprobe, "-v", "error", "-show_entries", "format=duration", "-of", "json", path], capture_output=True, text=True, timeout=10, check=True)
            return float(json.loads(result.stdout)["format"]["duration"])
        except (OSError, subprocess.SubprocessError, KeyError, TypeError, ValueError, json.JSONDecodeError) as exc:
            raise VideoProcessingError("Impossible de lire la durée de la vidéo") from exc

    def extract(self, path: str, count: int = 5) -> list[bytes]:
        if not self.ffmpeg:
            raise VideoProcessingError("Le traitement vidéo n'est pas disponible sur ce serveur")
        temp_dir = Path(tempfile.mkdtemp(prefix="nalvium-frames-"))
        try:
            output = temp_dir / "frame-%02d.jpg"
            subprocess.run([self.ffmpeg, "-v", "error", "-i", path, "-vf", f"fps={count}/1", "-frames:v", str(count), "-q:v", "3", str(output)], capture_output=True, timeout=30, check=True)
            frames = [item.read_bytes() for item in sorted(temp_dir.glob("frame-*.jpg"))]
            if not frames:
                raise VideoProcessingError("Aucune image exploitable n'a pu être extraite")
            return frames
        except (OSError, subprocess.SubprocessError) as exc:
            raise VideoProcessingError("La vidéo n'a pas pu être analysée") from exc
        finally:
            shutil.rmtree(temp_dir, ignore_errors=True)

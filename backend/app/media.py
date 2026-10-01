from __future__ import annotations

import io
import os
import uuid
from pathlib import Path
from PIL import Image, ImageOps

ALLOWED_MIME = {"image/jpeg", "image/png", "image/webp"}
DOCUMENT_MIME = {"application/pdf", *ALLOWED_MIME}
VIDEO_MIME = {"video/mp4", "video/quicktime", "video/webm", "video/x-m4v"}
AUDIO_MIME = {"audio/wav", "audio/x-wav", "audio/mpeg", "audio/mp4", "audio/m4a", "audio/webm", "audio/ogg"}
MAX_BYTES = 8 * 1024 * 1024
MAX_VIDEO_BYTES = 50 * 1024 * 1024
MAX_AUDIO_BYTES = 10 * 1024 * 1024
MAX_DIMENSION = 2048

class MediaError(ValueError):
    def __init__(self, message: str, status_code: int = 415):
        super().__init__(message)
        self.status_code = status_code

class LocalPrivateMediaStore:
    """Local development provider; files live outside any public web root."""
    def __init__(self, root: str | None = None):
        self.root = Path(root or os.getenv("NALVIUM_MEDIA_DIR", "var/media"))
        self.root.mkdir(parents=True, exist_ok=True)

    def save_image(self, data: bytes, declared_mime: str | None) -> dict:
        if declared_mime not in ALLOWED_MIME:
            raise MediaError("Type MIME non pris en charge")
        if len(data) > MAX_BYTES:
            raise MediaError("Fichier trop volumineux", 413)
        try:
            with Image.open(io.BytesIO(data)) as original:
                image = ImageOps.exif_transpose(original).convert("RGB")
                image.thumbnail((MAX_DIMENSION, MAX_DIMENSION), Image.Resampling.LANCZOS)
                media_id = str(uuid.uuid4())
                path = self.root / f"{media_id}.jpg"
                image.save(path, format="JPEG", quality=84, optimize=True)
        except Exception as exc:
            raise MediaError("Image invalide ou illisible") from exc
        return {"id": media_id, "path": str(path), "media_type": "image/jpeg", "private": True}

    def save_public_image_copy(self, data: bytes) -> dict:
        """Create a sanitized derived image; it is exposed only through community ACLs."""
        media = self.save_image(data, "image/jpeg")
        media["private"] = False
        media["community_copy"] = True
        return media

    def read(self, media_id: str) -> bytes:
        for path in self.root.glob(f"{media_id}.*"):
            if path.is_file():
                return path.read_bytes()
        raise MediaError("Média introuvable")

    def save_document(self, data: bytes, declared_mime: str | None, filename: str | None = None) -> dict:
        if declared_mime not in DOCUMENT_MIME:
            raise MediaError("Type de document non pris en charge")
        if len(data) > MAX_BYTES * 2:
            raise MediaError("Fichier trop volumineux", 413)
        if declared_mime == "application/pdf" and not data.startswith(b"%PDF"):
            raise MediaError("PDF invalide ou illisible")
        media_id = str(uuid.uuid4())
        extension = "pdf" if declared_mime == "application/pdf" else "jpg"
        path = self.root / f"{media_id}.{extension}"
        if declared_mime.startswith("image/"):
            try:
                with Image.open(io.BytesIO(data)) as original:
                    image = ImageOps.exif_transpose(original).convert("RGB")
                    image.thumbnail((MAX_DIMENSION, MAX_DIMENSION), Image.Resampling.LANCZOS)
                    image.save(path, format="JPEG", quality=84, optimize=True)
                    declared_mime = "image/jpeg"
            except Exception as exc:
                raise MediaError("Image invalide ou illisible") from exc
        else:
            path.write_bytes(data)
        return {"id": media_id, "path": str(path), "media_type": declared_mime, "private": True, "original_filename": filename}

    def save_video(self, data: bytes, declared_mime: str | None, filename: str | None = None) -> dict:
        if declared_mime not in VIDEO_MIME:
            raise MediaError("Type vidéo non pris en charge")
        if len(data) > MAX_VIDEO_BYTES:
            raise MediaError("Cette vidéo est trop volumineuse", 413)
        media_id = str(uuid.uuid4())
        extension = {"video/quicktime": "mov", "video/webm": "webm", "video/x-m4v": "m4v"}.get(declared_mime, "mp4")
        path = self.root / f"{media_id}.{extension}"
        path.write_bytes(data)
        return {"id": media_id, "path": str(path), "media_type": declared_mime, "private": True, "original_filename": filename, "byte_size": len(data)}

    def save_audio(self, data: bytes, declared_mime: str | None, filename: str | None = None) -> dict:
        if declared_mime not in AUDIO_MIME:
            raise MediaError("Format audio non pris en charge")
        if len(data) > MAX_AUDIO_BYTES:
            raise MediaError("Cet enregistrement est trop volumineux", 413)
        media_id = str(uuid.uuid4())
        extension = "m4a" if declared_mime in {"audio/mp4", "audio/m4a"} else "wav" if "wav" in declared_mime else "audio"
        path = self.root / f"{media_id}.{extension}"
        path.write_bytes(data)
        return {"id": media_id, "path": str(path), "media_type": declared_mime, "private": True, "original_filename": filename, "byte_size": len(data)}

    def delete(self, media_id: str) -> None:
        for path in self.root.glob(f"{media_id}.*"):
            if path.exists():
                path.unlink()

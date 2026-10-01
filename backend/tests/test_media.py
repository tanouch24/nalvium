import io
from PIL import Image
from app.media import LocalPrivateMediaStore

def test_image_is_reoriented_and_exif_not_preserved(tmp_path):
    image = Image.new("RGB", (20, 10), (100, 40, 20))
    exif = Image.Exif()
    exif[34853] = {2: (48, 51, 0), 4: (2, 20, 0)}
    raw = io.BytesIO()
    image.save(raw, format="JPEG", exif=exif)
    store = LocalPrivateMediaStore(str(tmp_path))
    saved = store.save_image(raw.getvalue(), "image/jpeg")
    with Image.open(saved["path"]) as clean:
        assert clean.size == (20, 10)
        assert not clean.getexif().get(34853)
    store.delete(saved["id"])
    assert not (tmp_path / f"{saved['id']}.jpg").exists()

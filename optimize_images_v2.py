from pathlib import Path
from PIL import Image

IMAGE_DIR = Path("assets/images")

JPEG_MAX = 1600
PNG_MAX = 1200
JPEG_QUALITY = 84

for path in IMAGE_DIR.iterdir():
    if not path.is_file():
        continue

    ext = path.suffix.lower()

    if ext not in [".jpg", ".jpeg", ".png"]:
        continue

    try:
        with Image.open(path) as img:

            original_size = path.stat().st_size
            w, h = img.size

            if ext in [".jpg", ".jpeg"]:
                max_size = JPEG_MAX
            else:
                max_size = PNG_MAX

            scale = min(
                max_size / w,
                max_size / h,
                1.0
            )

            new_size = (
                round(w * scale),
                round(h * scale)
            )

            if new_size != (w, h):
                img = img.resize(
                    new_size,
                    Image.Resampling.LANCZOS
                )

            if ext in [".jpg", ".jpeg"]:

                if img.mode != "RGB":
                    img = img.convert("RGB")

                img.save(
                    path,
                    "JPEG",
                    quality=JPEG_QUALITY,
                    optimize=True,
                    progressive=True
                )

            else:

                if img.mode not in ("RGB", "RGBA"):
                    img = img.convert("RGBA")

                img.save(
                    path,
                    "PNG",
                    optimize=True,
                    compress_level=9
                )

            new_size_bytes = path.stat().st_size

            print(
                f"{path.name}: "
                f"{original_size / 1024 / 1024:.2f} MB → "
                f"{new_size_bytes / 1024 / 1024:.2f} MB"
            )

    except Exception as e:
        print(f"Ошибка {path.name}: {e}")

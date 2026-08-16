from pathlib import Path
from PIL import Image
import shutil

IMAGE_DIR = Path("assets/images")

# Максимальный размер фотографии для мобильного приложения.
# Для карточек каталога этого более чем достаточно.
MAX_WIDTH = 1600
MAX_HEIGHT = 1600

JPEG_QUALITY = 84

processed = 0
skipped = 0
before_total = 0
after_total = 0

for path in IMAGE_DIR.iterdir():

    if not path.is_file():
        continue

    if path.suffix.lower() not in [".jpg", ".jpeg", ".png"]:
        skipped += 1
        continue

    before = path.stat().st_size
    before_total += before

    try:
        with Image.open(path) as img:

            original_format = img.format
            width, height = img.size

            # Уменьшаем только слишком большие изображения.
            scale = min(
                MAX_WIDTH / width,
                MAX_HEIGHT / height,
                1.0
            )

            new_size = (
                round(width * scale),
                round(height * scale)
            )

            if new_size != (width, height):
                img = img.resize(
                    new_size,
                    Image.Resampling.LANCZOS
                )

            if path.suffix.lower() in [".jpg", ".jpeg"]:

                # JPEG не поддерживает альфа-канал.
                if img.mode not in ("RGB", "L"):
                    background = Image.new("RGB", img.size, "white")
                    if "A" in img.getbands():
                        background.paste(
                            img,
                            mask=img.getchannel("A")
                        )
                    else:
                        background.paste(img)
                    img = background
                else:
                    img = img.convert("RGB")

                img.save(
                    path,
                    "JPEG",
                    quality=JPEG_QUALITY,
                    optimize=True,
                    progressive=True
                )

            else:

                # PNG оставляем PNG, чтобы не менять расширение
                # и не ломать существующие ссылки в Flutter.
                if img.mode not in ("RGB", "RGBA"):
                    img = img.convert("RGBA")

                img.save(
                    path,
                    "PNG",
                    optimize=True
                )

        after = path.stat().st_size
        after_total += after

        saved = before - after

        print(
            f"{path.name:40} "
            f"{before/1024/1024:6.2f} MB → "
            f"{after/1024/1024:6.2f} MB "
            f"(−{saved/1024/1024:6.2f} MB)"
        )

        processed += 1

    except Exception as e:
        print(f"ERROR: {path.name}: {e}")

print()
print("=" * 70)
print(f"Обработано: {processed}")
print(f"Пропущено:  {skipped}")
print(f"Было:       {before_total/1024/1024:.2f} MB")
print(f"Стало:      {after_total/1024/1024:.2f} MB")
print(
    f"Экономия:   "
    f"{(before_total-after_total)/1024/1024:.2f} MB "
    f"({(1-after_total/before_total)*100:.1f}%)"
)
print("=" * 70)

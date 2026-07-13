#!/usr/bin/env bash
set -euo pipefail

ASSETS_DIR="${ASSETS_DIR:-assets}"
OUTPUT_DIR="${OUTPUT_DIR:-output}"

IMAGE="$ASSETS_DIR/image.jpg"
AUDIO="$ASSETS_DIR/audio.mp3"
CAPTION_FILE="$ASSETS_DIR/caption.txt"
FONT="$ASSETS_DIR/font.ttf"
DEFAULT_FONT="/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"

for f in "$IMAGE" "$AUDIO" "$CAPTION_FILE"; do
  if [ ! -f "$f" ]; then
    echo "File mancante: $f" >&2
    exit 1
  fi
done

if [ ! -f "$FONT" ]; then
  FONT="$DEFAULT_FONT"
fi
if [ ! -f "$FONT" ]; then
  FONT=$(fc-match --format=%{file} sans-bold 2>/dev/null || true)
fi
if [ -z "$FONT" ] || [ ! -f "$FONT" ]; then
  echo "Nessun font trovato. Aggiungi assets/font.ttf oppure installa un font di sistema." >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"
OUTPUT="$OUTPUT_DIR/reel.mp4"

ffmpeg -y \
  -loop 1 -i "$IMAGE" \
  -stream_loop -1 -i "$AUDIO" \
  -filter_complex "[0:v]scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,setsar=1,drawtext=fontfile=${FONT}:textfile=${CAPTION_FILE}:fontcolor=white:fontsize=58:line_spacing=10:x=(w-text_w)/2:y=h-500:box=1:boxcolor=black@0.55:boxborderw=24[v]" \
  -map "[v]" -map 1:a \
  -t 15 \
  -c:v libx264 -profile:v high -pix_fmt yuv420p -r 30 \
  -c:a aac -b:a 128k \
  -movflags +faststart \
  "$OUTPUT"

echo "Video generato: $OUTPUT"

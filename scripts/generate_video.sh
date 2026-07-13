#!/usr/bin/env bash
set -euo pipefail

ASSETS_DIR="${ASSETS_DIR:-assets}"
OUTPUT_DIR="${OUTPUT_DIR:-output}"

IMAGE="$ASSETS_DIR/image.jpg"
AUDIO="$ASSETS_DIR/audio.mp3"
QUOTE_FILE="$ASSETS_DIR/quote.txt"
AUTHOR_FILE="$ASSETS_DIR/author.txt"
CUSTOM_FONT="$ASSETS_DIR/font.ttf"

for f in "$IMAGE" "$AUDIO" "$QUOTE_FILE"; do
  if [ ! -f "$f" ]; then
    echo "File mancante: $f" >&2
    exit 1
  fi
done

FONT_QUOTE="$CUSTOM_FONT"
if [ ! -f "$FONT_QUOTE" ]; then
  FONT_QUOTE=$(fc-match --format=%{file} "Open Sans:bold" 2>/dev/null || true)
fi
if [ -z "$FONT_QUOTE" ] || [ ! -f "$FONT_QUOTE" ]; then
  FONT_QUOTE=$(fc-match --format=%{file} "sans-serif:bold" 2>/dev/null || true)
fi
if [ -z "$FONT_QUOTE" ] || [ ! -f "$FONT_QUOTE" ]; then
  echo "Nessun font per l'aforisma trovato. Aggiungi assets/font.ttf oppure installa un font sans-serif di sistema." >&2
  exit 1
fi

FONT_AUTHOR=$(fc-match --format=%{file} "Open Sans" 2>/dev/null || true)
if [ -z "$FONT_AUTHOR" ] || [ ! -f "$FONT_AUTHOR" ]; then
  FONT_AUTHOR=$(fc-match --format=%{file} "sans-serif" 2>/dev/null || true)
fi
if [ -z "$FONT_AUTHOR" ] || [ ! -f "$FONT_AUTHOR" ]; then
  echo "Nessun font per l'autore trovato. Installa un font sans-serif di sistema." >&2
  exit 1
fi

AUTHOR_TEXT=""
if [ -f "$AUTHOR_FILE" ]; then
  AUTHOR_TEXT="$(cat "$AUTHOR_FILE")"
fi

mkdir -p "$OUTPUT_DIR"
OUTPUT="$OUTPUT_DIR/reel.mp4"

FILTER="[0:v]scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,setsar=1[bg];"
FILTER+="[bg]drawtext=fontfile=${FONT_QUOTE}:textfile=${QUOTE_FILE}:fontcolor=white:fontsize=58:line_spacing=10:x=(w-text_w)/2:y=780[q]"

if [ -n "$AUTHOR_TEXT" ]; then
  FILTER+=";[q]drawtext=fontfile=${FONT_AUTHOR}:textfile=${AUTHOR_FILE}:fontcolor=white:fontsize=36:x=(w-text_w)/2:y=1060[v]"
else
  FILTER+=";[q]null[v]"
fi

ffmpeg -y \
  -loop 1 -i "$IMAGE" \
  -stream_loop -1 -i "$AUDIO" \
  -filter_complex "$FILTER" \
  -map "[v]" -map 1:a \
  -t 15 \
  -c:v libx264 -profile:v high -pix_fmt yuv420p -r 30 \
  -c:a aac -b:a 128k \
  -movflags +faststart \
  "$OUTPUT"

echo "Video generato: $OUTPUT"

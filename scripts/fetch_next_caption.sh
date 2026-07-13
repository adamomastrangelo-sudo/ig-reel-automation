#!/usr/bin/env bash
set -euo pipefail

: "${SHEET_CSV_URL:?Devi impostare SHEET_CSV_URL (URL pubblico CSV del Google Sheet)}"

ASSETS_DIR="${ASSETS_DIR:-assets}"
STATE_DIR="${STATE_DIR:-state}"
STATE_FILE="$STATE_DIR/queue_index.txt"
CSV_FILE="$STATE_DIR/queue.csv"
QUOTE_FILE="$ASSETS_DIR/quote.txt"
AUTHOR_FILE="$ASSETS_DIR/author.txt"
QUOTE_Y_FILE="$ASSETS_DIR/quote_y.txt"
AUTHOR_Y_FILE="$ASSETS_DIR/author_y.txt"
CAPTION_FILE="$ASSETS_DIR/caption.txt"

mkdir -p "$STATE_DIR"

echo "Scarico il foglio testi..."
curl -sSfL "$SHEET_CSV_URL" -o "$CSV_FILE"

if [ ! -f "$STATE_FILE" ]; then
  echo "0" > "$STATE_FILE"
fi

python3 - "$CSV_FILE" "$STATE_FILE" "$QUOTE_FILE" "$AUTHOR_FILE" "$QUOTE_Y_FILE" "$AUTHOR_Y_FILE" "$CAPTION_FILE" <<'PYEOF'
import csv
import sys
import textwrap

csv_path, state_path, quote_path, author_path, quote_y_path, author_y_path, caption_path = sys.argv[1:8]

with open(csv_path, newline="", encoding="utf-8") as f:
    reader = csv.reader(f)
    all_rows = [row for row in reader if row]

# La prima riga e' sempre l'intestazione e viene scartata.
# Colonna A = testo dell'aforisma, colonna B = autore.
data_rows = []
for row in all_rows[1:]:
    quote = row[0].strip() if len(row) > 0 else ""
    author = row[1].strip() if len(row) > 1 else ""
    if quote:
        data_rows.append((quote, author))

if not data_rows:
    print("Errore: nessun testo trovato nel foglio (oltre all'intestazione)", file=sys.stderr)
    sys.exit(1)

with open(state_path, encoding="utf-8") as f:
    index = int(f.read().strip() or "0")

index = index % len(data_rows)
quote, author = data_rows[index]

# ffmpeg drawtext non va a capo da solo: il testo va spezzato qui in righe
# che stiano nella larghezza del video (1080px) con il font/dimensione usati
# in generate_video.sh (Open Sans bold, 58px). WRAP_CHARS e' una stima
# prudente (larga) della larghezza media dei caratteri, per non sforare mai
# i bordi anche con lettere maiuscole/larghe.
WRAP_CHARS = 24
wrapped_quote = textwrap.fill(quote, width=WRAP_CHARS)
num_lines = len(wrapped_quote.splitlines()) or 1

with open(quote_path, "w", encoding="utf-8") as f:
    f.write(wrapped_quote)

with open(author_path, "w", encoding="utf-8") as f:
    f.write(author)

# Posizionamento verticale dinamico: l'aforisma e l'autore vengono centrati
# come blocco unico, cosi' un aforisma lungo (piu' righe) non finisce
# sovrapposto al nome dell'autore.
QUOTE_LINE_PITCH = 76
AUTHOR_LINE_HEIGHT = 46
GAP_BETWEEN = 50
TARGET_CENTER_Y = 900

quote_block_height = num_lines * QUOTE_LINE_PITCH

if author:
    total_height = quote_block_height + GAP_BETWEEN + AUTHOR_LINE_HEIGHT
    quote_y = int(TARGET_CENTER_Y - total_height / 2)
    author_y = quote_y + quote_block_height + GAP_BETWEEN
else:
    quote_y = int(TARGET_CENTER_Y - quote_block_height / 2)
    author_y = 0

with open(quote_y_path, "w", encoding="utf-8") as f:
    f.write(str(quote_y))

with open(author_y_path, "w", encoding="utf-8") as f:
    f.write(str(author_y))

with open(caption_path, "w", encoding="utf-8") as f:
    if author:
        f.write(f"{quote}\n\n— {author}")
    else:
        f.write(quote)

next_index = (index + 1) % len(data_rows)
with open(state_path, "w", encoding="utf-8") as f:
    f.write(str(next_index))

print(f"Usata la riga {index + 1}/{len(data_rows)}. Autore: {author!r}. Righe aforisma: {num_lines}. Prossimo indice: {next_index}")
PYEOF

echo "Aforisma:"
cat "$QUOTE_FILE"
echo
echo "Autore: $(cat "$AUTHOR_FILE")"

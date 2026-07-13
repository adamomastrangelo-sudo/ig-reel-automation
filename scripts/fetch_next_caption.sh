#!/usr/bin/env bash
set -euo pipefail

: "${SHEET_CSV_URL:?Devi impostare SHEET_CSV_URL (URL pubblico CSV del Google Sheet)}"

ASSETS_DIR="${ASSETS_DIR:-assets}"
STATE_DIR="${STATE_DIR:-state}"
STATE_FILE="$STATE_DIR/queue_index.txt"
CSV_FILE="$STATE_DIR/queue.csv"
QUOTE_FILE="$ASSETS_DIR/quote.txt"
AUTHOR_FILE="$ASSETS_DIR/author.txt"
CAPTION_FILE="$ASSETS_DIR/caption.txt"

mkdir -p "$STATE_DIR"

echo "Scarico il foglio testi..."
curl -sSfL "$SHEET_CSV_URL" -o "$CSV_FILE"

if [ ! -f "$STATE_FILE" ]; then
  echo "0" > "$STATE_FILE"
fi

python3 - "$CSV_FILE" "$STATE_FILE" "$QUOTE_FILE" "$AUTHOR_FILE" "$CAPTION_FILE" <<'PYEOF'
import csv
import sys

csv_path, state_path, quote_path, author_path, caption_path = sys.argv[1:6]

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

with open(quote_path, "w", encoding="utf-8") as f:
    f.write(quote)

with open(author_path, "w", encoding="utf-8") as f:
    f.write(author)

with open(caption_path, "w", encoding="utf-8") as f:
    if author:
        f.write(f"{quote}\n\n— {author}")
    else:
        f.write(quote)

next_index = (index + 1) % len(data_rows)
with open(state_path, "w", encoding="utf-8") as f:
    f.write(str(next_index))

print(f"Usata la riga {index + 1}/{len(data_rows)}. Autore: {author!r}. Prossimo indice: {next_index}")
PYEOF

echo "Aforisma: $(cat "$QUOTE_FILE")"
echo "Autore: $(cat "$AUTHOR_FILE")"

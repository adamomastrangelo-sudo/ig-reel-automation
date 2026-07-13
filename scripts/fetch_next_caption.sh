#!/usr/bin/env bash
set -euo pipefail

: "${SHEET_CSV_URL:?Devi impostare SHEET_CSV_URL (URL pubblico CSV del Google Sheet)}"

ASSETS_DIR="${ASSETS_DIR:-assets}"
STATE_DIR="${STATE_DIR:-state}"
STATE_FILE="$STATE_DIR/queue_index.txt"
CSV_FILE="$STATE_DIR/queue.csv"
CAPTION_FILE="$ASSETS_DIR/caption.txt"

mkdir -p "$STATE_DIR"

echo "Scarico il foglio testi..."
curl -sSfL "$SHEET_CSV_URL" -o "$CSV_FILE"

if [ ! -f "$STATE_FILE" ]; then
  echo "0" > "$STATE_FILE"
fi

python3 - "$CSV_FILE" "$STATE_FILE" "$CAPTION_FILE" <<'PYEOF'
import csv
import sys

csv_path, state_path, caption_path = sys.argv[1], sys.argv[2], sys.argv[3]

with open(csv_path, newline="", encoding="utf-8") as f:
    reader = csv.reader(f)
    all_rows = [row[0].strip() for row in reader if row]

# La prima riga e' sempre l'intestazione e viene scartata.
data_rows = [r for r in all_rows[1:] if r]

if not data_rows:
    print("Errore: nessun testo trovato nel foglio (oltre all'intestazione)", file=sys.stderr)
    sys.exit(1)

with open(state_path, encoding="utf-8") as f:
    index = int(f.read().strip() or "0")

index = index % len(data_rows)
testo = data_rows[index]

with open(caption_path, "w", encoding="utf-8") as f:
    f.write(testo)

next_index = (index + 1) % len(data_rows)
with open(state_path, "w", encoding="utf-8") as f:
    f.write(str(next_index))

print(f"Usato testo alla riga {index + 1}/{len(data_rows)}. Prossimo indice: {next_index}")
PYEOF

echo "Caption aggiornata: $(cat "$CAPTION_FILE")"

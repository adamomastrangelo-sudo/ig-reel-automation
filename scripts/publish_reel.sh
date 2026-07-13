#!/usr/bin/env bash
set -euo pipefail

: "${IG_USER_ID:?Devi impostare IG_USER_ID}"
: "${IG_ACCESS_TOKEN:?Devi impostare IG_ACCESS_TOKEN}"
: "${VIDEO_URL:?Devi impostare VIDEO_URL (url pubblico del video)}"

CAPTION="${CAPTION:-}"
API_VERSION="${API_VERSION:-v23.0}"
BASE="https://graph.instagram.com/${API_VERSION}"

echo "Controllo quota pubblicazioni residue nelle ultime 24h..."
quota=$(curl -sS -G "${BASE}/${IG_USER_ID}/content_publishing_limit" \
  --data-urlencode "access_token=${IG_ACCESS_TOKEN}")
echo "Quota: $quota"

echo "Creo il contenitore media (REELS)..."
create_resp=$(curl -sS -X POST "${BASE}/${IG_USER_ID}/media" \
  --data-urlencode "media_type=REELS" \
  --data-urlencode "video_url=${VIDEO_URL}" \
  --data-urlencode "caption=${CAPTION}" \
  --data-urlencode "access_token=${IG_ACCESS_TOKEN}")
echo "Risposta creazione: $create_resp"

creation_id=$(echo "$create_resp" | python3 -c "import sys,json; print(json.load(sys.stdin).get('id',''))")
if [ -z "$creation_id" ]; then
  echo "Errore: nessun creation_id ricevuto" >&2
  exit 1
fi
echo "Container creato: $creation_id. Attendo elaborazione..."

status="IN_PROGRESS"
attempts=0
max_attempts=30
while [ "$status" != "FINISHED" ]; do
  attempts=$((attempts + 1))
  if [ "$attempts" -gt "$max_attempts" ]; then
    echo "Timeout: il video non è FINISHED dopo $max_attempts tentativi (5 minuti)" >&2
    exit 1
  fi
  sleep 10
  status_resp=$(curl -sS -G "${BASE}/${creation_id}" \
    --data-urlencode "fields=status_code" \
    --data-urlencode "access_token=${IG_ACCESS_TOKEN}")
  status=$(echo "$status_resp" | python3 -c "import sys,json; print(json.load(sys.stdin).get('status_code',''))")
  echo "Tentativo $attempts: stato = $status"
  if [ "$status" = "ERROR" ]; then
    echo "Errore nell'elaborazione del media: $status_resp" >&2
    exit 1
  fi
done

echo "Pubblico il reel..."
publish_resp=$(curl -sS -X POST "${BASE}/${IG_USER_ID}/media_publish" \
  --data-urlencode "creation_id=${creation_id}" \
  --data-urlencode "access_token=${IG_ACCESS_TOKEN}")
echo "Risposta pubblicazione: $publish_resp"

media_id=$(echo "$publish_resp" | python3 -c "import sys,json; print(json.load(sys.stdin).get('id',''))" 2>/dev/null || true)
if [ -z "$media_id" ]; then
  echo "Errore: pubblicazione non riuscita" >&2
  exit 1
fi

echo "Reel pubblicato con successo. Media ID: $media_id"

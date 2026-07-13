# ig-reel-automation

Pubblica automaticamente un Reel di 15 secondi (immagine fissa + testo fisso + musica di sottofondo) sull'account Instagram Business `profondamente.it`, tramite GitHub Actions. Sostituisce il flusso precedentemente costruito su n8n.

## Come funziona

- **`.github/workflows/publish.yml`**: schedulato (cron), genera il video con ffmpeg, lo pubblica come asset di una GitHub Release (hosting pubblico gratuito, necessario perché la Graph API scarica il video da un URL, non accetta upload diretto), poi lo pubblica su Instagram tramite le tre fasi della Graph API (creazione contenitore, polling, pubblicazione).
- **`.github/workflows/refresh-token.yml`**: schedulato settimanalmente, rinnova il token long-lived Instagram (valido 60 giorni) prima che scada, e aggiorna da solo il secret del repo. Non richiede mai intervento manuale finché il workflow continua a girare.
- **`scripts/generate_video.sh`**: genera `output/reel.mp4` da `assets/image.jpg` + `assets/audio.mp3` + `assets/caption.txt`, 9:16, H.264/AAC, 15 secondi.
- **`scripts/publish_reel.sh`**: chiama la Graph API (`graph.instagram.com`) per pubblicare un video già hostato pubblicamente.

## Setup iniziale (una tantum)

### 1. Asset fissi
Vedi [`assets/README.md`](assets/README.md): aggiungi `image.jpg`, `audio.mp3`, `caption.txt` (e opzionalmente `font.ttf`), poi fai commit/push.

### 2. Secrets del repo
Vai su **Settings → Secrets and variables → Actions → New repository secret** e crea:

| Nome | Valore |
|---|---|
| `IG_USER_ID` | l'Instagram User ID numerico |
| `IG_ACCESS_TOKEN` | il token long-lived Instagram (scade ogni 60 giorni, si rinnova da solo) |
| `GH_PAT` | un fine-grained Personal Access Token con permesso **Secrets: Read and write** limitato a questo repo, usato dal workflow di rinnovo per aggiornare `IG_ACCESS_TOKEN` |

### 3. Cadenza
Modifica la riga `cron:` in `.github/workflows/publish.yml` per cambiare frequenza/orario di pubblicazione. Puoi anche lanciare un run manuale da **Actions → Genera e pubblica Reel → Run workflow**.

## Se il token smette di funzionare del tutto

Il rinnovo automatico (`ig_refresh_token`) non richiede mai una nuova autorizzazione, **a patto che** il workflow giri almeno una volta ogni 60 giorni. Se per qualche motivo il collegamento con l'app viene revocato (es. ruolo Tester rimosso, permessi ritirati manualmente), serve rifare manualmente il flusso OAuth completo:

1. Apri `https://www.instagram.com/oauth/authorize?client_id=<APP_ID>&redirect_uri=<REDIRECT_URI>&response_type=code&scope=instagram_business_basic,instagram_business_content_publish`
2. Approva, copia il parametro `code` dal redirect
3. `POST https://api.instagram.com/oauth/access_token` con `client_id`, `client_secret`, `grant_type=authorization_code`, `redirect_uri`, `code` → token short-lived
4. `GET https://graph.instagram.com/access_token?grant_type=ig_exchange_token&client_secret=...&access_token=...` → token long-lived
5. Aggiorna il secret `IG_ACCESS_TOKEN` con il nuovo valore

Nota: il token generato dal pulsante rapido "Genera token d'accesso" nella dashboard Meta **non è idoneo** allo scambio long-lived (fallisce con "Session key invalid"): serve sempre il flusso OAuth completo sopra descritto.

## Limiti noti

- Rate limit: 50 pubblicazioni ogni 24 ore per account (verificabile con `GET /{ig-user-id}/content_publishing_limit`, controllato automaticamente da `publish_reel.sh` prima di ogni pubblicazione).
- L'audio va incorporato nel video prima dell'upload: la Graph API non dà accesso alla libreria musicale di Instagram.

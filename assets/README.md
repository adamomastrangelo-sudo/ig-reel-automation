# Asset fissi

**Nota:** `image.jpg` e `audio.mp3` presenti ora sono segnaposto generati automaticamente per testare la pipeline (sfondo grigio con scritta "PLACEHOLDER", tono a 440Hz). Sostituiscili con i file veri prima di attivare la pubblicazione reale.


Metti qui i file che l'automazione userà a ogni esecuzione (vengono committati nel repo, quindi restano stabili finché non li sostituisci):

- `image.jpg` — l'immagine fissa di sfondo (qualsiasi risoluzione, viene adattata automaticamente al formato 9:16)
- `audio.mp3` — la traccia audio royalty-free di cui hai i diritti d'uso (se più corta di 15 secondi viene ripetuta automaticamente in loop)
- `quote.txt`, `author.txt`, `author_underline_width.txt`, `caption.txt` — **non vanno modificati a mano**: vengono sovrascritti automaticamente a ogni esecuzione con l'aforisma/autore presi dal Google Sheet (vedi [`../README.md`](../README.md#coda-testi-google-sheet))
- `font.ttf` (opzionale) — un font TrueType serif per il testo dell'aforisma; se non lo aggiungi viene usato un font di sistema di default (DejaVu Serif Bold). Il nome dell'autore usa sempre DejaVu Sans Bold, non è personalizzabile da qui.

Per cambiare immagine o audio in futuro, basta sostituire questi file e fare commit/push: la prossima esecuzione schedulata userà automaticamente le versioni nuove. Per cambiare i testi, si aggiungono righe al Google Sheet, non a questo repo.

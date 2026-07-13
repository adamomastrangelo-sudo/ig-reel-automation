# Asset fissi

Metti qui i file che l'automazione userà a ogni esecuzione (vengono committati nel repo, quindi restano stabili finché non li sostituisci):

- `image.jpg` — l'immagine fissa di sfondo (qualsiasi risoluzione, viene adattata automaticamente al formato 9:16)
- `audio.mp3` — la traccia audio royalty-free di cui hai i diritti d'uso (se più corta di 15 secondi viene ripetuta automaticamente in loop)
- `quote.txt`, `author.txt`, `caption.txt` — **non vanno modificati a mano**: vengono sovrascritti automaticamente a ogni esecuzione con l'aforisma/autore presi dal Google Sheet (vedi [`../README.md`](../README.md#coda-testi-google-sheet))
- `font.ttf` (opzionale) — un font TrueType per il testo dell'aforisma (bold); se non lo aggiungi viene usato Open Sans di sistema. Il nome dell'autore usa sempre Open Sans (peso normale, dimensione più piccola), non è personalizzabile da qui.

Per cambiare immagine o audio in futuro, basta sostituire questi file e fare commit/push: la prossima esecuzione schedulata userà automaticamente le versioni nuove. Per cambiare i testi, si aggiungono righe al Google Sheet, non a questo repo.

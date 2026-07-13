# Asset fissi

Metti qui i file che l'automazione userà a ogni esecuzione (vengono committati nel repo, quindi restano stabili finché non li sostituisci):

- `image.jpg` — l'immagine fissa di sfondo (qualsiasi risoluzione, viene adattata automaticamente al formato 9:16)
- `audio.mp3` — la traccia audio royalty-free di cui hai i diritti d'uso (se più corta di 15 secondi viene ripetuta automaticamente in loop)
- `caption.txt` — il testo fisso sovrimpresso sul video, e anche la caption del post pubblicato
- `font.ttf` (opzionale) — un font TrueType per il testo; se non lo aggiungi viene usato un font di sistema di default (DejaVu Sans Bold)

Per cambiare immagine, audio o testo in futuro, basta sostituire questi file e fare commit/push: la prossima esecuzione schedulata userà automaticamente le versioni nuove.

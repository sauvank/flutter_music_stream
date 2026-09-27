# Feuille de route

## Livré

- [x] Bibliothèque locale, tags, pochettes, favoris, playlists et déduplication SHA-256.
- [x] Lecture mobile en arrière-plan avec commandes système.
- [x] Profils WebDAV/HTTP et import JSON MusicStream/ComicStream sécurisé.
- [x] Navigation distante et téléchargement de morceaux ou dossiers entiers.
- [x] File native persistante avec progression, notifications, pause, reprise et nouvelle tentative.
- [x] Écoute directe d’un fichier distant et import récursif d’un dossier local.
- [x] Affichage distant fiable des tags et pochettes par échantillonnage HTTP.
- [x] Lecture aléatoire et répétition de la file ou du morceau.
- [x] Fondus configurables à la lecture, la pause et la navigation.
- [x] Navigation et import de morceaux ou dossiers depuis un serveur FTP passif.
- [x] Détection manuelle des nouveaux albums sur les serveurs configurés.
- [x] File de lecture visible et modifiable : lire ensuite, ajouter en fin, sélectionner, réordonner et retirer.
- [x] Volume applicatif persistant et historique des morceaux réellement écoutés.

## En cours

- [ ] Paroles locales `.lrc` et LRCLIB, synchronisées avec la lecture.

## À venir

- [ ] Description et réorganisation manuelle des playlists.
- [ ] Choix explicite du thème et localisation multilingue.
- [ ] Scan de la médiathèque de l’appareil et widget d’accueil Android.
- [ ] Traduction facultative des paroles avec consentement réseau explicite.
- [ ] Synchronisation chiffrée des métadonnées entre appareils.

## Différé

- [ ] Égaliseur : attendre une implémentation cohérente Android/iOS. `just_audio 0.10.6` ne fournit actuellement qu’un égaliseur Android; ne pas exposer un réglage sans effet sur iOS.

## Décision ouverte

- Déterminer si HTTP non chiffré doit rester autorisé globalement sur Android ou être limité par une configuration réseau fournie hors dépôt.
- Définir si le scan de la médiathèque doit compléter les imports privés ou devenir une source distincte sur Android.

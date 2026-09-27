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

## En cours

- [ ] Choisir une stratégie d’égaliseur multiplateforme et ajouter les fondus.

## À venir

- [ ] Serveurs FTP et détection de nouveaux albums.
- [ ] Synchronisation chiffrée des métadonnées entre appareils.

## Décision ouverte

- Déterminer si HTTP non chiffré doit rester autorisé globalement sur Android ou être limité par une configuration réseau fournie hors dépôt.
- L’égaliseur fourni par `just_audio` est Android uniquement; définir l’expérience iOS avant de l’exposer dans l’interface.

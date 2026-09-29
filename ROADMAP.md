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
- [x] Déduplication des téléchargements de dossiers imbriqués, limitation des transferts par serveur et état local complet/partiel/absent des dossiers.
- [x] Suppression individuelle ou globale des téléchargements serveur sans effacer les imports locaux.
- [x] Détection manuelle des nouveaux albums sur les serveurs configurés.
- [x] File de lecture visible et modifiable : lire ensuite, ajouter en fin, sélectionner, réordonner et retirer.
- [x] Volume applicatif persistant et historique des morceaux réellement écoutés.
- [x] Paroles `.lrc` locales et LRCLIB, synchronisées avec la lecture, recherche automatique après accord et traduction à la demande avec cache privé.
- [x] Premier passage de performance pour les grandes bibliothèques et les files de téléchargement volumineuses.
- [x] Badge de disponibilité locale des morceaux dans le navigateur serveur.
- [x] Description et réorganisation manuelle des playlists.

## En cours

- [ ] Mesurer les temps de démarrage, de défilement et d'import sur appareil avec une grande bibliothèque; traiter les points chauds restants. Démarrage mesuré et corrigé sur Galaxy S24 (≈300 morceaux, 0,7–0,95 s); défilement de la bibliothèque mesuré sans point chaud (≈2 200 images : construction médiane 2,5 ms, rendu médian 4 ms, 11 images au-delà de 16 ms, surtout au premier passage). L'import reste à mesurer.

## À venir

- [ ] Choix explicite du thème et localisation multilingue.
- [ ] Scan de la médiathèque de l’appareil et widget d’accueil Android.
- [ ] Synchronisation chiffrée des métadonnées entre appareils.

## Différé

- [ ] Égaliseur : attendre une implémentation cohérente Android/iOS. `just_audio 0.10.6` ne fournit actuellement qu’un égaliseur Android; ne pas exposer un réglage sans effet sur iOS.

## Décision ouverte

- Déterminer si HTTP non chiffré doit rester autorisé globalement sur Android ou être limité par une configuration réseau fournie hors dépôt.
- Définir si le scan de la médiathèque doit compléter les imports privés ou devenir une source distincte sur Android.

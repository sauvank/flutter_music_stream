# Contexte actif

MusicStream est un lecteur Flutter local-first pour Android/iOS. Les fichiers importés sont copiés dans le stockage privé, identifiés par SHA-256 et enrichis avec `audio_metadata_reader`.

## État courant

- La version publiée correspond à `version` dans `pubspec.yaml` et au dernier tag Git; éviter de recopier ce numéro ici afin que le script de release ne rende pas le contexte obsolète.
- Les profils WebDAV/HTTP peuvent être importés par fichier JSON ou copier-coller. Les mots de passe vont directement dans `FlutterSecureStorage`.
- `DownloadQueueProvider` utilise `background_downloader` 8.9.5 pour les téléchargements natifs persistants, puis remet les fichiers terminés à `LibraryProvider` pour déduplication et lecture des tags.
- Android autorise explicitement le trafic HTTP car les profils serveur acceptent `http://`. Kotlin est fixé à 1.9.20 pour la compatibilité du plugin avec Flutter 3.27/AGP 8.1.
- La file affiche progression, cause d’échec, pause, reprise, annulation et nouvelle tentative.
- `PlayerProvider.playRemote` lit un fichier serveur avec ses en-têtes d’authentification sans l’ajouter à la bibliothèque.
- Le sélecteur d’import propose des fichiers ou un dossier; un dossier est parcouru récursivement et filtré par extension audio.
- `RemoteAudioMetadataService` construit un fichier creux de taille réelle à partir des plages HTTP de tête et, pour MP4/M4A/AAC, de fin. Deux requêtes au maximum s’exécutent simultanément.
- `PlayerProvider` expose l’aléatoire et les cycles de répétition natifs de `just_audio`; l’écran de lecture affiche leurs états actifs.
- Les actions « Tout lire » passent par `PlayerProvider.playAll`, qui désactive la répétition du morceau avant de charger la file; la répétition de toute la file reste conservée.
- `PlayerProvider` applique un fondu aux actions lancées dans l’application (lecture, pause, morceau précédent/suivant). La durée 0/250/500/1000 ms est persistée par `PlaybackSettingsService`; les commandes système pilotées directement par `just_audio_background` ne passent pas par ce fondu.

## Contraintes

- Ne jamais commiter le JSON serveur privé ni aucun secret, chemin personnel ou adresse privée réelle.
- `server_profiles.private.json` et `*.private.md` restent ignorés localement.
- Avant livraison : `flutter analyze`, `flutter test`, contrôle émulateur, puis seulement sur demande explicite commit/bump/push.

## Problème actif

La lecture distante authentifiée, le téléchargement HTTP en arrière-plan, l’indexation finale, le sélecteur récursif de dossier, l’extraction distante des pochettes et les modes aléatoire/répétition ont été validés sur un appareil Android physique. Les fondus doivent encore être contrôlés sur appareil. L’égaliseur natif disponible est Android uniquement; ne pas l’exposer avant une décision multiplateforme.

Architecture détaillée : [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md). Travaux futurs : [ROADMAP.md](ROADMAP.md).

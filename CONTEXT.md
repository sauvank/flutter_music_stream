# Contexte actif

MusicStream est un lecteur Flutter local-first pour Android/iOS. Les fichiers importés sont copiés dans le stockage privé, identifiés par SHA-256 et enrichis avec `audio_metadata_reader`.

## État courant

- Version Git publiée : `0.1.7+8`; les fonctionnalités serveur récentes sont encore non commitées à la demande de l’utilisateur.
- Les profils WebDAV/HTTP peuvent être importés par fichier JSON ou copier-coller. Les mots de passe vont directement dans `FlutterSecureStorage`.
- `DownloadQueueProvider` utilise `background_downloader` 8.9.5 pour les téléchargements natifs persistants, puis remet les fichiers terminés à `LibraryProvider` pour déduplication et lecture des tags.
- Android autorise explicitement le trafic HTTP car les profils serveur acceptent `http://`. Kotlin est fixé à 1.9.20 pour la compatibilité du plugin avec Flutter 3.27/AGP 8.1.
- La file affiche progression, cause d’échec, pause, reprise, annulation et nouvelle tentative.
- `PlayerProvider.playRemote` lit un fichier serveur avec ses en-têtes d’authentification sans l’ajouter à la bibliothèque.
- Le sélecteur d’import propose des fichiers ou un dossier; un dossier est parcouru récursivement et filtré par extension audio.

## Contraintes

- Ne jamais commiter le JSON serveur privé ni aucun secret, chemin personnel ou adresse privée réelle.
- `server_profiles.private.json` et `*.private.md` restent ignorés localement.
- Avant livraison : `flutter analyze`, `flutter test`, contrôle émulateur, puis seulement sur demande explicite commit/bump/push.

## Problème actif

La lecture distante authentifiée, le téléchargement HTTP en arrière-plan, l’indexation finale et le sélecteur récursif de dossier ont été validés sur un appareil Android physique. L’extraction partielle des tags et pochettes distants reste à fiabiliser pour tous les formats.

Architecture détaillée : [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md). Travaux futurs : [ROADMAP.md](ROADMAP.md).

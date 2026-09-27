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
- `PlayerProvider` maintient sa file en phase avec la playlist mutable de `just_audio`. La feuille « À suivre » permet sélection, réorganisation et retrait; les menus de morceau proposent « Lire ensuite » et l’ajout en fin. « Lire ensuite » désactive l’aléatoire afin de garantir la position demandée.
- Les actions « Tout lire » passent par `PlayerProvider.playAll`, qui désactive la répétition du morceau avant de charger la file; la répétition de toute la file reste conservée.
- `PlayerProvider` applique un fondu aux actions lancées dans l’application (lecture, pause, morceau précédent/suivant). La durée 0/250/500/1000 ms est persistée par `PlaybackSettingsService`; les commandes système pilotées directement par `just_audio_background` ne passent pas par ce fondu.
- Le volume applicatif est persisté par `PlaybackSettingsService` et sert de cible aux fondus. `PlayerProvider` cumule uniquement les petites avancées continues de la position pendant la lecture : après 30 secondes, ou la moitié d’un titre plus court, `LibraryProvider` date l’écoute et incrémente son compteur. La vue Historique trie ces pistes par dernière écoute; un saut dans la piste ne suffit pas à l’alimenter.
- `LyricsDocument` parse les horodatages `.lrc` (y compris timestamps multiples et décalage) et repère la ligne active. `LyricsService` copie les fichiers voisins lors d’un import local ou un `.lrc` choisi manuellement dans `lyrics/<empreinte de l’ID>.lrc`; l’empreinte évite de placer les URI des pistes distantes dans les noms de fichier. Il ne contacte LRCLIB que sur action explicite dans la feuille Paroles. Un résultat synchronisé ou texte est mis en cache dans le stockage privé. Le lecteur surligne et suit la ligne active, avec toucher pour avancer.
- Deux projets servent de références fonctionnelles locales : `../comic_reader_app` pour FTP et synchronisation chiffrée, et `https://github.com/sauvank/pinnard_music_v5` pour l’expérience lecteur (file, volume, historique, paroles, playlists, scan Android, widget, thèmes et traductions). Réutiliser les concepts, pas les données ni les secrets.
- Le FTP passif ne place jamais les identifiants dans l’URI. HTTP/WebDAV conservent la lecture directe et la file native en arrière-plan; un morceau FTP doit d’abord être téléchargé et importé dans le stockage privé.
- `ServerScanService` conserve localement une empreinte SHA-256 des URI distantes sans paramètres ni fragments. Le premier scan crée la référence; les suivants regroupent les ajouts par dossier parent. Le scan reste manuel pour éviter une connexion réseau surprise, notamment en FTP non chiffré.

## Contraintes

- Ne jamais commiter le JSON serveur privé ni aucun secret, chemin personnel ou adresse privée réelle.
- `server_profiles.private.json` et `*.private.md` restent ignorés localement.
- Avant livraison : `flutter analyze`, `flutter test`, puis commit conventionnel et publication patch via le script du projet.

## Problème actif

La lecture distante authentifiée, le téléchargement HTTP en arrière-plan, l’indexation finale, le sélecteur récursif de dossier, l’extraction distante des pochettes, les modes aléatoire/répétition, les fondus, le volume applicatif, l’historique et l’adaptation verticale de l’écran Lecture ont été validés sur un Galaxy S24 sous Android 16. Le FTP et la nouvelle feuille Paroles doivent encore être contrôlés sur appareil. L’égaliseur est différé tant qu’aucune solution Android/iOS cohérente n’est disponible.

Architecture détaillée : [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md). Travaux futurs : [ROADMAP.md](ROADMAP.md).

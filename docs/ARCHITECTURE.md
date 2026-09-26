# Architecture

```text
lib/
├── main.dart
├── models/music_playlist.dart
├── models/music_track.dart
├── models/server_profile.dart
├── models/remote_audio_entry.dart
├── providers/
│   ├── library_provider.dart
│   ├── player_provider.dart
│   └── server_provider.dart
├── services/
│   ├── audio_metadata_service.dart
│   ├── library_service.dart
│   ├── playlist_service.dart
│   ├── remote_server_service.dart
│   └── server_profile_service.dart
├── screens/
│   ├── home_screen.dart
│   ├── library_screen.dart
│   ├── now_playing_screen.dart
│   ├── servers_screen.dart
│   └── settings_screen.dart
└── widgets/
    └── track_artwork.dart
```

`LibraryService` copie les imports dans le répertoire privé, calcule leur empreinte et sérialise l’index. `AudioMetadataService` lit les tags avec `audio_metadata_reader`; les pochettes intégrées sont extraites dans `artwork/` et leur URI privée est conservée avec la piste. Les anciennes entrées sont enrichies une seule fois lors de leur premier chargement après migration. `PlaylistService` persiste séparément les playlists, qui ne référencent les morceaux que par leur empreinte. `LibraryProvider` expose recherche, favoris, progression et opérations de playlist. L’écran de bibliothèque construit les regroupements artistes, albums et genres ainsi que les files personnalisées à partir de cette source unique. `PlayerProvider` possède l’unique instance `AudioPlayer`, construit la file, transmet la pochette aux contrôles système et fournit l’état aux écrans.

`HomeScreen` porte le fond, le mini-lecteur et la navigation commune. Il utilise une barre flottante compacte sur téléphone et un `NavigationRail` sur les fenêtres d’au moins 840 pixels logiques. Les écrans Bibliothèque, Serveurs, Lecture et Réglages partagent les mêmes surfaces arrondies, dégradés, titres expressifs et marges réservées aux contrôles persistants.

Sur Android, le projet utilise encore AGP 8.1 avec Flutter 3.27. Les bibliothèques JNI sont donc empaquetées en mode legacy/compressé, voie de compatibilité officielle pour les appareils à pages mémoire de 16 Kio tant qu’une montée coordonnée de Flutter, AGP et Gradle n’est pas réalisée. Le retour prédictif Android est activé dans le manifeste.

`ServerProfileService` conserve uniquement les profils non sensibles dans les préférences et délègue les mots de passe à `FlutterSecureStorage`. `RemoteServerService` comprend WebDAV `PROPFIND`, les index HTTP JSON et les auto-index HTML. Les téléchargements rejoignent le stockage privé avant indexation, comme un import local. Le FTP devra converger vers les mêmes modèles.

Les secrets de production ne transitent jamais dans Git. La CI consomme seulement les secrets de l’environnement GitHub et détruit les fichiers temporaires dans une étape exécutée systématiquement.

Le script `scripts/sync_music_rclone_crypt.sh` est un outil d'exploitation externe à l'application Flutter. Il maintient une copie chiffrée de la bibliothèque audio avec un remote rclone `crypt` configuré localement. Ses contrôles bloquent les racines système, les sources indisponibles ou sans audio et les exécutions miroir non confirmées. Ce miroir des fichiers ne doit pas être confondu avec la synchronisation applicative des métadonnées décrite dans la feuille de route.

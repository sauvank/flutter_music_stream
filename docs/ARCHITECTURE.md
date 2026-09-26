# Architecture

```text
lib/
├── main.dart
├── models/music_track.dart
├── models/server_profile.dart
├── models/remote_audio_entry.dart
├── providers/
│   ├── library_provider.dart
│   ├── player_provider.dart
│   └── server_provider.dart
├── services/
│   ├── library_service.dart
│   ├── remote_server_service.dart
│   └── server_profile_service.dart
└── screens/
    ├── home_screen.dart
    ├── library_screen.dart
    ├── now_playing_screen.dart
    ├── servers_screen.dart
    └── settings_screen.dart
```

`LibraryService` copie les imports dans le répertoire privé, calcule leur empreinte et sérialise l’index. `LibraryProvider` expose recherche, favoris et progression. `PlayerProvider` possède l’unique instance `AudioPlayer`, construit la file et fournit l’état aux écrans.

`ServerProfileService` conserve uniquement les profils non sensibles dans les préférences et délègue les mots de passe à `FlutterSecureStorage`. `RemoteServerService` comprend WebDAV `PROPFIND`, les index HTTP JSON et les auto-index HTML. Les téléchargements rejoignent le stockage privé avant indexation, comme un import local. Le FTP devra converger vers les mêmes modèles.

Les secrets de production ne transitent jamais dans Git. La CI consomme seulement les secrets de l’environnement GitHub et détruit les fichiers temporaires dans une étape exécutée systématiquement.

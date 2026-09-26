# Architecture

```text
lib/
├── main.dart
├── models/music_track.dart
├── providers/
│   ├── library_provider.dart
│   └── player_provider.dart
├── services/library_service.dart
└── screens/
    ├── home_screen.dart
    ├── library_screen.dart
    ├── now_playing_screen.dart
    └── settings_screen.dart
```

`LibraryService` copie les imports dans le répertoire privé, calcule leur empreinte et sérialise l’index. `LibraryProvider` expose recherche, favoris et progression. `PlayerProvider` possède l’unique instance `AudioPlayer`, construit la file et fournit l’état aux écrans.

Les futures sources WebDAV, HTTP et FTP devront converger vers le même modèle `MusicTrack`. Les téléchargements rejoindront le stockage privé avant indexation, comme un import local.

Les secrets de production ne transitent jamais dans Git. La CI consomme seulement les secrets de l’environnement GitHub et détruit les fichiers temporaires dans une étape exécutée systématiquement.

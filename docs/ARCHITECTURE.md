# Architecture

```text
lib/
├── main.dart
├── models/music_playlist.dart
├── models/music_track.dart
├── models/server_profile.dart
├── models/remote_audio_entry.dart
├── models/remote_audio_metadata.dart
├── providers/
│   ├── download_queue_provider.dart
│   ├── library_provider.dart
│   ├── player_provider.dart
│   └── server_provider.dart
├── services/
│   ├── audio_metadata_service.dart
│   ├── library_service.dart
│   ├── playlist_service.dart
│   ├── remote_server_service.dart
│   ├── remote_audio_metadata_service.dart
│   └── server_profile_service.dart
├── screens/
│   ├── home_screen.dart
│   ├── library_screen.dart
│   ├── now_playing_screen.dart
│   ├── servers_screen.dart
│   └── settings_screen.dart
└── widgets/
    ├── import_music_sheet.dart
    └── track_artwork.dart
```

`LibraryService` copie les imports de fichiers ou de dossiers récursifs dans le répertoire privé, calcule leur empreinte et sérialise l’index. `AudioMetadataService` lit les tags avec `audio_metadata_reader`; les pochettes intégrées sont extraites dans `artwork/` et leur URI privée est conservée avec la piste. Les anciennes entrées sont enrichies une seule fois lors de leur premier chargement après migration. `PlaylistService` persiste séparément les playlists, qui ne référencent les morceaux que par leur empreinte. `LibraryProvider` expose recherche, favoris, progression et opérations de playlist. L’écran de bibliothèque construit les regroupements artistes, albums et genres ainsi que les files personnalisées à partir de cette source unique. `PlayerProvider` possède l’unique instance `AudioPlayer`, construit la file locale ou une source distante temporaire avec ses en-têtes d’authentification, transmet la pochette aux contrôles système et pilote l’aléatoire ainsi que les trois états de répétition.

`HomeScreen` porte le fond, le mini-lecteur et la navigation commune. Il utilise une barre flottante compacte sur téléphone et un `NavigationRail` sur les fenêtres d’au moins 840 pixels logiques. Les écrans Bibliothèque, Serveurs, Lecture et Réglages partagent les mêmes surfaces arrondies, dégradés, titres expressifs et marges réservées aux contrôles persistants.

`PlayerProvider` centralise la file `just_audio` et les commandes de lecture. Il réalise les fondus applicatifs par paliers de volume annulables afin qu’une commande rapide remplace proprement la précédente. `PlaybackSettingsService` persiste leur durée dans `SharedPreferences`. Les commandes multimédias système restent gérées directement par `just_audio_background`.

Sur Android, le projet utilise encore AGP 8.1 avec Flutter 3.27. Les bibliothèques JNI sont donc empaquetées en mode legacy/compressé, voie de compatibilité officielle pour les appareils à pages mémoire de 16 Kio tant qu’une montée coordonnée de Flutter, AGP et Gradle n’est pas réalisée. Le retour prédictif Android est activé dans le manifeste.

`ServerProfileService` conserve uniquement les profils non sensibles dans les préférences et délègue les mots de passe à `FlutterSecureStorage`. `ServerProvider` accepte aussi un fichier JSON ou du JSON collé contenant un profil ou une liste sous la clé `servers`, dans le schéma MusicStream ou dans le schéma historique de ComicStream. Un éventuel mot de passe importé est extrait puis placé directement dans le coffre; il n’est jamais conservé avec le profil. `RemoteServerService` comprend WebDAV `PROPFIND`, les index HTTP JSON, les auto-index HTML et délègue le FTP passif à `FtpService`.

`ServerScanService` compare à la demande l’inventaire récursif avec une référence stockée dans `SharedPreferences`. Il ne conserve que des empreintes SHA-256 des URI normalisées sans paramètres ni fragments, regroupe les ajouts par dossier parent et supprime la référence avec le profil. Le premier passage initialise la référence sans annoncer toute la bibliothèque comme nouvelle; aucun scan réseau n’est lancé automatiquement.

Le FTP utilise une connexion de contrôle explicite avec authentification, mode binaire, EPSV avec repli PASV, puis MLSD avec repli LIST. Les URI FTP ne contiennent jamais les identifiants. Comme les composants natifs de lecture et de téléchargement de fond ne gèrent pas FTP, ces morceaux sont téléchargés au premier plan dans un fichier temporaire, puis importés et dédupliqués par `LibraryService` avant lecture locale.

`DownloadQueueProvider` confie les fichiers à `background_downloader`, dont la file native persiste lorsque l’interface passe en arrière-plan. Les tâches conservent leurs en-têtes d’authentification uniquement dans le stockage privé de l’application. Une fois un fichier terminé, `LibraryService` le déplace dans `music/`, calcule son empreinte, le déduplique et extrait ses tags. Android autorise le trafic non chiffré pour rester compatible avec les profils HTTP explicitement pris en charge. Le FTP devra converger vers les mêmes modèles.

`RemoteAudioMetadataService` ne télécharge pas le morceau complet pour remplir la liste distante. Il demande la tête du fichier et, pour les conteneurs MP4/M4A/AAC, sa fin, puis les place aux bons offsets dans un fichier creux ayant la taille logique originale. Cela permet au lecteur de tags de parcourir les atomes et métadonnées sans stocker les données audio intermédiaires. La concurrence est limitée à deux morceaux.

Les secrets de production ne transitent jamais dans Git. La CI consomme seulement les secrets de l’environnement GitHub et détruit les fichiers temporaires dans une étape exécutée systématiquement.

Le script `scripts/sync_music_rclone_crypt.sh` est un outil d'exploitation externe à l'application Flutter. Il maintient une copie chiffrée de la bibliothèque audio avec un remote rclone `crypt` configuré localement. Ses contrôles bloquent les racines système, les sources indisponibles ou sans audio et les exécutions miroir non confirmées. Ce miroir des fichiers ne doit pas être confondu avec la synchronisation applicative des métadonnées décrite dans la feuille de route.

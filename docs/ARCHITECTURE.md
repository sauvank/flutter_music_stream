# Architecture

```text
lib/
├── main.dart
├── l10n/ (app_fr.arb, app_en.arb, l10n.dart, generated/)
├── models/music_playlist.dart
├── models/music_track.dart
├── models/lyrics_document.dart
├── models/server_profile.dart
├── models/remote_audio_entry.dart
├── models/remote_audio_metadata.dart
├── providers/
│   ├── appearance_provider.dart
│   ├── download_queue_provider.dart
│   ├── library_provider.dart
│   ├── player_provider.dart
│   └── server_provider.dart
├── services/
│   ├── appearance_settings_service.dart
│   ├── audio_access.dart
│   ├── audio_metadata_service.dart
│   ├── device_media_service.dart
│   ├── home_widget_service.dart
│   ├── library_service.dart
│   ├── lyrics_service.dart
│   ├── lyrics_translation_service.dart
│   ├── playlist_service.dart
│   ├── remote_server_service.dart
│   ├── remote_audio_metadata_service.dart
│   └── server_profile_service.dart
├── screens/
│   ├── home_screen.dart
│   ├── library_screen.dart
│   ├── now_playing_screen.dart
│   ├── lyrics_sheet.dart
│   ├── servers_screen.dart
│   └── settings_screen.dart
└── widgets/
    ├── import_music_sheet.dart
    └── track_artwork.dart
```

`LibraryService` copie les imports de fichiers ou de dossiers récursifs dans le répertoire privé, calcule leur empreinte et sérialise l’index. `AudioMetadataService` lit les tags avec `audio_metadata_reader`; les pochettes intégrées sont extraites dans `artwork/` et leur URI privée est conservée avec la piste. Les anciennes entrées sont enrichies une seule fois lors de leur premier chargement après migration. `AppearanceSettingsService` persiste le mode de thème et la langue, exposés à `MaterialApp` par `AppearanceProvider`. Les écrans lisent leurs textes via `context.l10n` (code généré par `gen-l10n`); `main()` résout aussi la langue hors de l’arbre de widgets pour le canal audio et les notifications de `DownloadQueueProvider`, reconfigurées à chaque changement de langue. La synchronisation chiffrée (`lib/services/sync/`, `SyncProvider`) exporte l’état de `LibraryProvider`, le fusionne avec le fichier chiffré du serveur WebDAV puis réapplique le résultat. Le widget d’accueil Android est natif : `HomeWidgetService` transmet l’état de lecture à `MainActivity` par canal de méthode, et `PlayerWidgetProvider` dessine le widget et relaie ses boutons au récepteur média d’`audio_service`. `DeviceMediaService` liste les fichiers audio du stockage partagé; `LibraryProvider.scanDeviceMedia` les synchronise comme source `deviceMedia` lue sur place; les supprimer ne touche jamais au fichier et mémorise son URI pour que les scans l’ignorent, et `AudioAccess` centralise la permission audio Android. `LibraryService.removeOrphanFiles` purge au démarrage les copies privées non référencées avant la reprise des téléchargements. `PlaylistService` persiste séparément les playlists, qui ne référencent les morceaux que par leur empreinte; la description est facultative et absente du JSON lorsqu’elle est vide, ce qui garde les anciens enregistrements compatibles. `LibraryProvider.movePlaylistTrack` déplace un morceau selon les index visibles de `tracksForPlaylist` et purge au passage les références orphelines. `LibraryProvider` expose recherche, favoris, progression, historique d’écoute et opérations de playlist. L’écran de bibliothèque construit les regroupements artistes, albums et genres ainsi que les files personnalisées à partir de cette source unique. `PlayerProvider` possède l’unique instance `AudioPlayer`, construit la file locale ou une source distante temporaire avec ses en-têtes d’authentification, transmet la pochette aux contrôles système et pilote l’aléatoire ainsi que les trois états de répétition.

Les gros index sont sérialisés dans un isolate et les écritures successives sont ordonnées. La progression de lecture, sauvegardée toutes les cinq secondes, est écrite dans une petite table séparée (`music_positions_v1`) plutôt que de réencoder tout l’index; elle est replacée sur les pistes au chargement et effacée par la sauvegarde complète suivante. `LibraryProvider` mémorise ses vues dérivées (filtre, historique, index par identifiant) jusqu’à la prochaine notification. `PlayerProvider` publie les ticks de position via `positionListenable` sans notifier ses écouteurs, si bien que seuls la barre du mini-lecteur, le curseur de lecture et les paroles synchronisées se reconstruisent en continu. L'écran ne calcule l'historique et les groupes que pour l'onglet actif. Les URI de morceaux téléchargés sont conservées dans un ensemble partagé pour les indicateurs des dossiers distants; le décodeur des pochettes reçoit la taille affichée lorsqu'elle est connue.

L’écran de bibliothèque possède une sélection multiple locale (`_TrackSelection`) : un appui long sélectionne un morceau, la barre flottante propose lecture suivante, ajout à la file, ajout groupé à une playlist en une seule écriture et suppression, et le retour système quitte la sélection. Hors de cet écran (collections, playlists), l’appui long ouvre le menu d’options du morceau. La lecture aléatoire mélange une copie de la liste et désactive le mode aléatoire natif afin que la file affichée corresponde à l’ordre d’écoute. L’import local traite chaque fichier indépendamment : un échec n’interrompt pas la sélection, et `LibraryProvider.importProgress` alimente la barre de progression avant le bilan affiché en fin d’import. L’écran Lecture lit l’état favori dans `LibraryProvider`, car la file conserve des instantanés des pistes. La suppression d’un profil serveur demande une confirmation. `LibraryProvider` trie la vue « Tous les morceaux » avec des clés sans accents précalculées (titre, artiste puis album, album, ou date d’ajout), départage par disque et numéro de piste, et mémorise le choix dans `SharedPreferences`.

L’écoute distante construit une file complète : le bouton d’un fichier lit le dossier courant à partir de ce morceau, et « Lire le dossier » réutilise l’inventaire récursif mis en cache par `ServerProvider`, trié par chemin. `PlayerProvider.playRemoteQueue` remplace chaque fichier déjà importé par sa piste locale (via `LibraryProvider.trackForSourceUri`) et n’ajoute les en-têtes d’authentification qu’aux sources distantes. Le FTP reste exclu de l’écoute directe.

La suppression des téléchargements retire aussi leurs fichiers privés, pochettes et références de playlists; les imports locaux ne sont pas inclus dans l’action globale. Les anciennes pistes sans origine marquée demandent un choix explicite.

`HomeScreen` porte le fond, le mini-lecteur et la navigation commune. Il mémorise les onglets visités pour que le retour système revienne au précédent, après avoir laissé le navigateur de serveur remonter d’un dossier et la bibliothèque quitter sa sélection. Le mini-lecteur accepte un glissement horizontal pour changer de morceau et vertical pour ouvrir Lecture; l’onglet Serveurs affiche le nombre de téléchargements actifs. Il utilise une barre flottante compacte sur téléphone et un `NavigationRail` sur les fenêtres d’au moins 840 pixels logiques. Les écrans Bibliothèque, Serveurs, Lecture et Réglages partagent les mêmes surfaces arrondies, dégradés, titres expressifs et marges réservées aux contrôles persistants.

`PlayerProvider` centralise la file `just_audio` et les commandes de lecture. Sa liste de `MusicTrack` reste synchronisée avec la playlist mutable native pour insérer, ajouter, déplacer ou retirer une source sans reconstruire la lecture en cours. L’action « Lire ensuite » désactive l’aléatoire avant insertion afin que la prochaine piste soit déterministe. Le provider réalise aussi les fondus applicatifs par paliers de volume annulables afin qu’une commande rapide remplace proprement la précédente. `PlaybackSettingsService` persiste leur durée et le volume applicatif dans `SharedPreferences`; ce volume devient la cible des fondus. L’historique ne compte que les petits deltas continus de position pendant une lecture active et valide une écoute après 30 secondes au plus, ou à mi-parcours pour un titre court, ce qui exclut les simples sauts. Les commandes multimédias système restent gérées directement par `just_audio_background`.

`LyricsDocument` transforme les lignes `.lrc` horodatées en positions triées et conserve aussi un texte non synchronisé. `LyricsService` stocke les paroles sous `lyrics/` avec un nom dérivé de l’empreinte SHA-256 de l’identifiant du morceau, copie les fichiers voisins lors d’un import local et peut recevoir un fichier choisi dans l’écran Lecture. `LyricsSheet` demande une seule fois l’accord pour la recherche automatique sur LRCLIB à son ouverture; le choix persiste dans `SharedPreferences` et reste modifiable dans Réglages. Après accord, `PlayerProvider` lance une recherche à chaque nouveau morceau dépourvu de paroles en cache. Le service essaie `/api/get` puis `/api/search` en conservant seulement une correspondance exacte de titre et d’artiste, identifie l’application, respecte la réponse `429` et met en cache les paroles. `LyricsTranslationService` envoie des lots de lignes à MyMemory uniquement après sélection d’une langue, préserve les horodatages et garde la traduction dans le stockage privé. `LyricsSheet` suit la position de `PlayerProvider`, surligne la ligne active et permet de s’y déplacer par toucher.

Sur Android, le projet utilise encore AGP 8.1 avec Flutter 3.27. Les bibliothèques JNI sont donc empaquetées en mode legacy/compressé, voie de compatibilité officielle pour les appareils à pages mémoire de 16 Kio tant qu’une montée coordonnée de Flutter, AGP et Gradle n’est pas réalisée. Le retour prédictif Android est activé dans le manifeste.

`ServerProfileService` conserve uniquement les profils non sensibles dans les préférences et délègue les mots de passe à `FlutterSecureStorage`. `ServerProvider` accepte aussi un fichier JSON ou du JSON collé contenant un profil ou une liste sous la clé `servers`, dans le schéma MusicStream ou dans le schéma historique de ComicStream. Un éventuel mot de passe importé est extrait puis placé directement dans le coffre; il n’est jamais conservé avec le profil. `RemoteServerService` comprend WebDAV `PROPFIND`, les index HTTP JSON, les auto-index HTML et délègue le FTP passif à `FtpService`. Il compare les chemins WebDAV décodés pour écarter le dossier courant et accepte les noms de dossiers et fichiers contenant un signe `%` littéral, sans imposer un second décodage invalide.

`ServerScanService` compare à la demande l’inventaire récursif avec une référence stockée dans `SharedPreferences`. Il ne conserve que des empreintes SHA-256 des URI normalisées sans paramètres ni fragments, regroupe les ajouts par dossier parent et supprime la référence avec le profil. Le premier passage initialise la référence sans annoncer toute la bibliothèque comme nouvelle; aucun scan réseau n’est lancé automatiquement.

Le FTP utilise une connexion de contrôle explicite avec authentification, mode binaire, EPSV avec repli PASV, puis MLSD avec repli LIST. Les URI FTP ne contiennent jamais les identifiants. Comme les composants natifs de lecture et de téléchargement de fond ne gèrent pas FTP, ces morceaux sont téléchargés au premier plan dans un fichier temporaire, puis importés et dédupliqués par `LibraryService` avant lecture locale.

`DownloadQueueProvider` confie les fichiers à `background_downloader`, dont la file native persiste lorsque l’interface passe en arrière-plan. Son initialisation native est lancée sans être attendue au démarrage; la chaîne d’ajout commence par elle. L’ajout à la file est sérialisé pour éviter les doublons entre dossiers imbriqués et le moteur limite les transferts à deux par hôte. Les tâches conservent leurs en-têtes d’authentification uniquement dans le stockage privé de l’application. Une fois un fichier terminé, `LibraryService` le déplace dans `music/`, calcule son empreinte, le déduplique et extrait ses tags. L’URI d’origine est conservée sur la piste pour afficher la disponibilité complète ou partielle d’un dossier; les inventaires des dossiers visibles sont mis en cache et calculés un à un. Android autorise le trafic non chiffré pour rester compatible avec les profils HTTP explicitement pris en charge.

La feuille des téléchargements, ouverte depuis la liste des serveurs ou le navigateur, relance les échecs, efface les tâches annulées et les téléchargements terminés déjà importés, et annule en une fois les transferts actifs après confirmation. `ServerProvider.breadcrumbs` expose le chemin depuis la racine; le navigateur l’affiche en fil d’Ariane et propose un filtre local au-delà de quinze entrées.

Les événements de progression groupent les relectures de la base de tâches à 300 ms; les lectures simultanées sont fusionnées. Les changements de statut déclenchent une lecture immédiate.

Chaque ligne de piste distante consulte l'ensemble des URI source conservées par `LibraryProvider`. Une URI reconnue affiche un badge de présence locale et masque l'action de téléchargement; l'ensemble est actualisé après import et suppression.

`RemoteAudioMetadataService` ne télécharge pas le morceau complet pour remplir la liste distante. Il demande la tête du fichier et, pour les conteneurs MP4/M4A/AAC, sa fin, puis les place aux bons offsets dans un fichier creux ayant la taille logique originale. Cela permet au lecteur de tags de parcourir les atomes et métadonnées sans stocker les données audio intermédiaires. La concurrence est limitée à deux morceaux.

Les secrets de production ne transitent jamais dans Git. La CI consomme seulement les secrets de l’environnement GitHub et détruit les fichiers temporaires dans une étape exécutée systématiquement.

Le script `scripts/sync_music_rclone_crypt.sh` est un outil d'exploitation externe à l'application Flutter. Il maintient une copie chiffrée de la bibliothèque audio avec un remote rclone `crypt` configuré localement. Ses contrôles bloquent les racines système, les sources indisponibles ou sans audio et les exécutions miroir non confirmées. Ce miroir des fichiers ne doit pas être confondu avec la synchronisation applicative des métadonnées décrite dans la feuille de route.

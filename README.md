# MusicStream

MusicStream est un lecteur de musique personnel construit avec Flutter. Il transpose à la musique l'approche local-first de ComicStream : bibliothèque locale, lecture hors connexion et prise en charge de serveurs personnels sans envoyer les fichiers audio vers un service tiers.

## État actuel

- import multiple de fichiers ou de dossiers entiers en MP3, M4A, AAC, FLAC, OGG, OPUS et WAV ;
- copie dans le stockage privé de l’application et déduplication SHA-256 ;
- bibliothèque persistante avec recherche et favoris ;
- lecture des tags audio, pochettes intégrées et durée à l’import ;
- navigation par morceaux, artistes, albums et genres ;
- création et modification de playlists locales ;
- lecture, pause, navigation dans la file, reprise, aléatoire et répétition ;
- interface Material 3 expressive, mini-lecteur et écran de lecture immersif ;
- navigation adaptative avec barre flottante sur téléphone et rail sur grand écran ;
- lecture Android/iOS en arrière-plan avec notification et commandes système ;
- profils WebDAV et HTTP importables par JSON ComicStream ou MusicStream, avec mot de passe transféré dans le coffre sécurisé de l’OS ;
- navigation distante et téléchargement de morceaux ou dossiers entiers dans une file persistante en arrière-plan, avec progression, pause et reprise ;
- écoute directe d’un morceau distant avant son téléchargement ;
- thèmes clair et sombre Material 3.

Le FTP et la synchronisation chiffrée multi-appareils sont documentés dans la feuille de route. Ils ne sont pas présentés comme déjà livrés.

## Miroir chiffré avec rclone

Le script `scripts/sync_music_rclone_crypt.sh` adapte à la musique le miroir rclone de ComicStream. Il synchronise la bibliothèque vers un remote `crypt` déjà configuré et refuse les sources système, absentes, vides ou ne contenant aucun format audio pris en charge.

Configurez d'abord le backend de stockage et son remote `crypt` avec `rclone config`, puis vérifiez toujours le résultat avec une simulation :

```bash
./scripts/sync_music_rclone_crypt.sh --dry-run /media/music music_crypt:
./scripts/sync_music_rclone_crypt.sh /media/music music_crypt:
```

La seconde commande demande de saisir `SYNCHRONISER`, car `rclone sync` supprime sur la destination les fichiers qui n'existent plus dans la source. Pour une exécution automatisée après validation, utilisez `--yes`. Les variables `MUSIC_SOURCE_PATH` et `RCLONE_DESTINATION` permettent de définir les valeurs par défaut sans versionner de configuration locale.

## Démarrage

```bash
flutter pub get
flutter run
```

Validation complète :

```bash
flutter analyze
flutter test
```

## Plateformes

Android 6 (API 23) ou plus récent et iOS sont les cibles prioritaires. Linux, macOS et Windows disposent du même socle Flutter. Le Web nécessitera un stockage d’import spécifique avant d’être considéré comme pris en charge.

## Sécurité

Le dépôt est privé, mais il reste maintenu comme s'il pouvait devenir public : aucun mot de passe, jeton, certificat, configuration Firebase réelle ou clé de signature n’y est stocké. Consultez [docs/SECRETS.md](docs/SECRETS.md) avant de configurer une CI ou un backend.

## Licence

Le projet est distribué sous licence MIT.

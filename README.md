# MusicStream

MusicStream est un lecteur de musique personnel open source construit avec Flutter. Il privilégie une bibliothèque locale, une lecture hors connexion et une architecture prête à accueillir les serveurs personnels de ComicStream sans envoyer les fichiers audio vers un service tiers.

## État actuel

- import multiple de fichiers MP3, M4A, AAC, FLAC, OGG, OPUS et WAV ;
- copie dans le stockage privé de l’application et déduplication SHA-256 ;
- bibliothèque persistante avec recherche et favoris ;
- lecture des tags audio, pochettes intégrées et durée à l’import ;
- navigation par morceaux, artistes, albums et genres ;
- lecture, pause, navigation dans la file et reprise ;
- mini-lecteur et écran de lecture adaptatif ;
- lecture Android/iOS en arrière-plan avec notification et commandes système ;
- profils WebDAV et HTTP avec mot de passe dans le coffre sécurisé de l’OS ;
- navigation distante et téléchargement des morceaux pour l’écoute hors ligne ;
- thèmes clair et sombre Material 3.

Le FTP, les playlists et la synchronisation chiffrée multi-appareils sont documentés dans la feuille de route. Ils ne sont pas présentés comme déjà livrés.

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

Le dépôt est public. Aucun mot de passe, jeton, certificat, configuration Firebase réelle ou clé de signature n’y est stocké. Consultez [docs/SECRETS.md](docs/SECRETS.md) avant de configurer une CI ou un backend.

## Licence

Le projet est distribué sous licence MIT.

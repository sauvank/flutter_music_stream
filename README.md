# MusicStream

MusicStream est un lecteur de musique personnel open source construit avec Flutter. Il privilégie une bibliothèque locale, une lecture hors connexion et une architecture prête à accueillir les serveurs personnels de ComicStream sans envoyer les fichiers audio vers un service tiers.

## État actuel

- import multiple de fichiers MP3, M4A, AAC, FLAC, OGG, OPUS et WAV ;
- copie dans le stockage privé de l’application et déduplication SHA-256 ;
- bibliothèque persistante avec recherche et favoris ;
- lecture, pause, navigation dans la file et reprise ;
- mini-lecteur et écran de lecture adaptatif ;
- lecture Android/iOS en arrière-plan avec notification et commandes système ;
- thèmes clair et sombre Material 3.

Les connexions WebDAV, HTTP et FTP, les métadonnées embarquées, les playlists et la synchronisation chiffrée multi-appareils sont documentées dans la feuille de route. Elles ne sont pas présentées comme déjà livrées.

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

Android et iOS sont les cibles prioritaires. Linux, macOS et Windows disposent du même socle Flutter. Le Web nécessitera un stockage d’import spécifique avant d’être considéré comme pris en charge.

## Sécurité

Le dépôt est public. Aucun mot de passe, jeton, certificat, configuration Firebase réelle ou clé de signature n’y est stocké. Consultez [docs/SECRETS.md](docs/SECRETS.md) avant de configurer une CI ou un backend.

## Licence

Le projet est distribué sous licence MIT.

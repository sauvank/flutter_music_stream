# MusicStream

MusicStream est un lecteur de musique personnel construit avec Flutter. Il transpose à la musique l'approche local-first de ComicStream : bibliothèque locale, lecture hors connexion et prise en charge de serveurs personnels sans envoyer les fichiers audio vers un service tiers.

## État actuel

- import multiple de fichiers ou de dossiers entiers en MP3, M4A, AAC, FLAC, OGG, OPUS et WAV, avec progression et bilan (ajoutés, déjà présents, échecs) ;
- copie dans le stockage privé de l’application et déduplication SHA-256 ;
- bibliothèque persistante avec recherche, favoris et tri mémorisé par titre, artiste, album ou date d’ajout ; appui long pour sélectionner plusieurs morceaux et les lire ensuite, les ajouter à la file ou à une playlist, ou les supprimer ;
- grands catalogues : index traité hors de l’interface, rafraîchissement regroupé des téléchargements et pochettes adaptées à leur taille d’affichage ;
- lecture des tags audio, pochettes intégrées et durée à l’import ;
- navigation par morceaux, artistes, albums et genres ;
- médiathèque du téléphone en option, lue sur place sans copie ;
- visualiseur du son en direct sur la pochette (permission micro demandée à l’activation, rien n’est enregistré) et barres animées dans le widget ;
- diffusion vers un autre appareil (Bluetooth, dont Alexa appairée) depuis le sélecteur de sortie audio d’Android ;
- widget d’écran d’accueil Android avec les commandes de lecture ;
- synchronisation chiffrée de bout en bout des favoris, écoutes et playlists via votre serveur WebDAV ;
- thème système, clair ou sombre au choix ; interface en français ou en anglais ;
- création et modification de playlists locales avec description facultative et ordre personnalisable par glisser-déposer ; lecture aléatoire des morceaux, favoris, collections et playlists ;
- mini-lecteur à gestes (glisser pour changer de morceau, vers le haut pour ouvrir Lecture), repère du morceau en cours dans les listes et retour système vers l’onglet précédent ;
- lecture, pause, file visible et réorganisable, « lire ensuite », reprise, aléatoire, répétition, volume persistant et fondus configurables ;
- historique local des morceaux réellement écoutés, classé par écoute récente ;
- paroles `.lrc` synchronisées importées avec les fichiers locaux ou manuellement depuis Lecture ; recherche LRCLIB automatique après accord, conservée hors connexion, et traduction à la demande ;
- interface Material 3 expressive, mini-lecteur et écran de lecture immersif ;
- navigation adaptative avec barre flottante sur téléphone et rail sur grand écran ;
- lecture Android/iOS en arrière-plan avec notification et commandes système ;
- profils WebDAV, HTTP et FTP importables par JSON ComicStream ou MusicStream, avec mot de passe transféré dans le coffre sécurisé de l’OS ;
- navigation distante et téléchargement de morceaux ou dossiers entiers, avec état local explicite sous chaque dossier (vert si complet, orange si partiel) ; HTTP/WebDAV utilisent une file persistante en arrière-plan, limitée à deux transferts simultanés par serveur, tandis que FTP importe au premier plan ;
- badge « Sur le téléphone » à la place du bouton de téléchargement pour les morceaux distants déjà importés ;
- file de téléchargement accessible depuis la liste des serveurs, badge du nombre de transferts actifs sur l’onglet Serveurs, relance des échecs, nettoyage des terminés et annulation groupée ;
- navigation distante avec fil d’Ariane cliquable et filtre des dossiers volumineux ;
- suppression des téléchargements serveur depuis le menu d’un morceau ou globalement depuis la bibliothèque ;
- détection à la demande des nouveaux albums d’un serveur, après création d’une référence locale ;
- écoute directe d’un morceau ou d’un dossier distant (récursif, dans l’ordre des chemins) avant son téléchargement ; les morceaux déjà importés sont lus depuis le téléphone ;
- thèmes clair et sombre Material 3.

La synchronisation chiffrée multi-appareils est documentée dans la feuille de route et n’est pas présentée comme déjà livrée.

Au premier morceau sans paroles, l’écran Paroles demande si la recherche automatique doit être activée. Une fois activée, elle transmet à LRCLIB le titre, l’artiste et, s’ils sont connus, l’album et la durée au changement de morceau lorsqu’aucune parole n’est en cache. Ce choix peut être modifié dans Réglages ; la recherche manuelle reste disponible. Les paroles récupérées sont enregistrées dans le stockage privé. Choisir une langue pour la traduction envoie les paroles à MyMemory ; la traduction est ensuite conservée localement.

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

Sur Android, un décodeur logiciel embarqué complète le lecteur natif pour les M4A ALAC et les formats AAC/FLAC absents des décodeurs de l’appareil. Il fonctionne aussi pour la lecture HTTP/WebDAV, sans conversion préalable des fichiers. Les autres plateformes conservent leur lecteur existant. Compilation et tests natifs : [décodeur Android](android/audio_decoder/README.md).

## Sécurité

Le dépôt est privé, mais il reste maintenu comme s'il pouvait devenir public : aucun mot de passe, jeton, certificat, configuration Firebase réelle ou clé de signature n’y est stocké. Consultez [docs/SECRETS.md](docs/SECRETS.md) avant de configurer une CI ou un backend.

## Licence

Le projet est distribué sous licence MIT.

L’extension Android Media3 est sous Apache 2.0 et sa bibliothèque FFmpeg sous LGPL 2.1 ou ultérieure ; leurs licences et les instructions de reconstruction sont fournies dans [android/audio_decoder](android/audio_decoder/README.md).

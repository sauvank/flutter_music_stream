# Tests et mesures

## Tests unitaires

`flutter analyze` puis `flutter test` (131 tests, ~16 s).
`flutter test --coverage` reste bloqué au chargement sous WSL (connexion au VM service, même symptôme que `watchPerformance`) : problème d'environnement, pas des tests.

## Benchmarks sur appareil (`integration_test/`)

Mode profile, sur un émulateur de test (jamais le téléphone principal : `flutter drive` désinstalle l'app à la fin). L'APK doit être construit avec la cible du test, puis passé à `flutter drive` :

```sh
flutter build apk --profile --target=integration_test/<test>.dart --target-platform android-x64
flutter drive -d emulator-5554 --profile --driver=test_driver/perf_driver.dart \
  --target=integration_test/<test>.dart --use-application-binary=build/app/outputs/flutter-apk/app-profile.apk
```

Les résumés sont écrits dans `build/perf/*.json`. L'installation réinitialise les permissions : accorder `READ_MEDIA_AUDIO` et `POST_NOTIFICATIONS` (`pm grant`) dès que le paquet apparaît.

- `perf_test.dart` : défilement de la bibliothèque, recherche, changement d'onglet, écran Lecture. Active la médiathèque de l'appareil (pousser des MP3 dans `/sdcard/Music` d'abord).
- `download_test.dart` : « Tout télécharger » sur un WebDAV local (`rclone serve webdav <dossier> --addr 127.0.0.1:8090 --read-only` + `adb reverse tcp:8090 tcp:8090`), avec défilement continu de l'UI pendant la charge.

Les timings de frames sont collectés via `addTimingsCallback` : `binding.watchPerformance` exige le VM service, inaccessible ici.

## Références (2026-10-09, émulateur Pixel 7 Pro API 37 x86_64, WHPX)

Les temps de raster d'un émulateur ne valent pas ceux d'un appareil réel ; comparer seulement des mesures faites sur le même appareil.

| Scénario | Résultat |
|---|---|
| Démarrage à froid (release, bibliothèque vide) | 0,9–1,5 s |
| Scan médiathèque, 490 fichiers | ~4 s |
| Défilement 490 morceaux | build p90 2,5 ms ; frames raster hors budget 26–43/648 (255/640 avant l'animation d'entrée limitée au premier écran) |
| 3 000 téléchargements WebDAV (40 Ko) | 3 000/3 000 indexés, 0 échec, ~615 s (4,9 fichiers/s), PSS max ~300 Mo |

Pistes mesurées sans gain sur le débit des téléchargements : `enqueueAll` par lots (le coût ~45 ms/tâche est interne au plugin) et file d'attente à 6 transferts simultanés au lieu de 2 par hôte (4,4 fichiers/s, UI plus saccadée). Le plafond vient du coût fixe par fichier : statut natif, SHA-256, déplacement, sauvegarde complète de l'index (volontairement attendue pour ne jamais perdre un fichier déplacé).

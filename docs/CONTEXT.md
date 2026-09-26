# Contexte produit — MusicStream

MusicStream transpose l’expérience de ComicStream à une bibliothèque musicale personnelle : importer ou récupérer ses morceaux, les conserver hors connexion et les écouter sur mobile ou ordinateur.

## Principes

- Local-first : l’application fonctionne sans compte et sans serveur.
- Aucun fichier audio, chemin local ou secret n’est envoyé par défaut.
- Les pistes sont identifiées par SHA-256 afin de dédupliquer les imports et, à terme, synchroniser uniquement les métadonnées.
- Les identifiants de serveurs devront être stockés dans le coffre sécurisé du système.
- Toute synchronisation future chiffrera les données côté client.
- Android cible au minimum l’API 23, exigée par le coffre sécurisé, tout en couvrant la cible principale Android 8.

## Version 0.1

La bibliothèque importe des formats audio courants dans le stockage privé de l’application. Elle lit leurs tags ID3, MP4 ou Vorbis, extrait les pochettes dans un répertoire privé et utilise le nom de fichier comme repli. Les morceaux peuvent être parcourus par artiste, album ou genre. Elle persiste l’état favori et la position de reprise, actualisée pendant l’écoute. Le moteur `just_audio` fournit la file et `just_audio_background` les commandes système.

Les profils WebDAV et HTTP séparent les métadonnées non sensibles, conservées dans les préférences, des mots de passe placés dans le coffre sécurisé du système. L’utilisateur parcourt les dossiers distants et choisit les morceaux à copier hors ligne. La diffusion directe, le FTP, les playlists et les comptes ne sont pas encore implémentés.

## Journal de continuité

### 2026-09-26 — Reprise de la refonte visuelle en cours

- État initial vérifié sur `main` à la version `0.1.3+4`, avec une refonte non commitée de la bibliothèque, du mini-lecteur, de l’écran de lecture et des pochettes.
- Migration de lecture des tags en cours constatée de `audiotags` vers `audio_metadata_reader`, avec les fichiers d’enregistrement desktop et les dépendances déjà régénérés dans l’arbre de travail.
- Aucun secret ni chemin personnel n’a été trouvé dans les changements inspectés.
- Les cinq sources Dart modifiées ont été passées dans `dart format`; trois nécessitaient une normalisation de mise en forme.
- Validation intermédiaire réussie : `flutter analyze` ne remonte aucun problème et `flutter test` réussit les 3 tests existants.
- Revue fonctionnelle effectuée : les commandes purement décoratives (options, file, minuteur et filtre) ont été retirées afin que chaque contrôle visible ait un comportement réel.
- `docs/ARCHITECTURE.md` a été corrigé pour référencer le lecteur de tags effectivement utilisé, `audio_metadata_reader`; le README et la feuille de route décrivent déjà correctement le périmètre livré.
- Validation finale après correction réussie : `flutter analyze` ne remonte aucun problème et `flutter test` réussit les 3 tests existants.
- Contrôle de livraison réussi : `git diff --check` est propre et la recherche de motifs sensibles dans les ajouts ne trouve aucun secret, chemin personnel ou réseau privé réel.
- Livraison prévue conformément aux directives du dépôt : commit fonctionnel Conventional Commit, puis `./scripts/bump_and_push.sh patch`, qui doit produire la version `0.1.4+5`, le tag `v0.1.4` et pousser les deux commits sur `origin/main`.
- Retour utilisateur avant livraison : la validation doit impérativement être faite sur l’émulateur déjà lancé et la refonte doit s’appuyer sur un audit des meilleures pratiques actuelles des lecteurs de musique modernes. Le commit et le bump sont donc suspendus jusqu’à validation visuelle réelle.
- Nouvelle suite prévue : étudier les références UX actuelles, exécuter l’application sur l’émulateur, capturer et inspecter les écrans principaux, corriger les problèmes de rendu et d’interaction, puis reprendre les validations techniques et la livraison.
- Audit UX actuel effectué à partir des recommandations Material 3 Expressive/adaptatives, des directives Apple pour la lecture audio et des interfaces récentes Apple Music, Spotify et YouTube Music : priorité à la pochette, aux contrôles essentiels, au mouvement utile, à une navigation compacte et à des dispositions réellement adaptatives.
- L’ancienne interface installée a été capturée, puis la branche locale a été compilée et déployée avec succès sur `emulator-5554` (`1440 × 3120`, densité `560`).
- Au premier lancement, Android signale que l’APK de débogage n’est pas entièrement compatible avec les pages mémoire de 16 Kio (`libdatastore_shared_counter.so` et `libflutter.so`). Ce point technique doit être diagnostiqué après l’audit visuel.
- Captures des quatre onglets vides inspectées sur l’émulateur : la bibliothèque et l’état sans lecture suivent la nouvelle direction, mais Serveurs et Réglages conservent l’ancien langage visuel. Le bouton d’ajout de serveur est en outre masqué par la barre de navigation flottante.
- Décision : étendre le même système visuel aux écrans Serveurs et Réglages, corriger les marges basses, puis importer des fichiers audio temporaires uniquement dans l’émulateur afin de contrôler les états bibliothèque pleine, collections, mini-lecteur et lecture en cours.
- Serveurs et Réglages ont été harmonisés avec les en-têtes, cartes, dégradés et états vides de la bibliothèque; la barre d’état adopte désormais des icônes sombres en thème clair et claires en thème sombre.
- Une navigation adaptative a été ajoutée : barre flottante compacte sur téléphone et rail latéral étendu sur grand écran. La variante tablette a été contrôlée sur l’émulateur redimensionné temporairement en `2560 × 1600`, puis celui-ci a été remis à sa taille native.
- Six MP3 de test temporaires avec tags et pochettes ont été générés sous `/tmp`, copiés uniquement dans l’émulateur et importés via le sélecteur Android. Les vues morceaux, artistes, albums, le mini-lecteur et l’écran de lecture ont été capturés et inspectés.
- Défaut trouvé en situation réelle : le mini-lecteur recouvrait les commandes dans l’onglet Lecture. Il est désormais masqué uniquement dans cet onglet.
- Diagnostic 16 Kio : le projet utilise Flutter `3.27.4` et AGP `8.1.0`. Selon la documentation Android, AGP `8.5.1+` aligne les bibliothèques natives non compressées; pour les versions antérieures, le chemin de compatibilité officiel consiste à activer le packaging JNI legacy/compressé.
- `android/app/build.gradle` active donc `jniLibs.useLegacyPackaging = true`. Une reconstruction et une réinstallation propres doivent encore confirmer la disparition de l’avertissement sur l’émulateur 16 Kio.
- Le journal Android a également signalé l’absence d’activation du retour prédictif; `android:enableOnBackInvokedCallback="true"` a été ajouté à l’application pour intégrer le comportement de navigation Android moderne.
- Reconstruction complète effectuée après `flutter clean` : l’APK de débogage a été produit avec les bibliothèques `.so` compressées (`Defl:N`), puis l’ancienne installation a été supprimée et remplacée sur l’émulateur.
- Validation 16 Kio réussie : après réinstallation propre, l’application atteint la bibliothèque vide sans dialogue de compatibilité et reste le processus au premier plan. Les données musicales de test de l’application ont été supprimées avec cette réinstallation; les fichiers sources temporaires restent uniquement dans le dossier Download de l’émulateur et sous `/tmp` sur la machine.
- `README.md`, `docs/ARCHITECTURE.md` et `docs/ROADMAP.md` ont été alignés sur l’interface expressive, la navigation adaptative et le choix de packaging Android.
- Validation technique finale réussie après toutes les corrections : les sept sources Dart sont correctement formatées, `flutter analyze` ne remonte aucun problème et `flutter test` réussit les 3 tests.
- Contrôle final de livraison réussi : `git diff --check` est propre et aucune donnée sensible, adresse privée réelle ou chemin personnel n’est présent dans les ajouts. La refonte est prête pour le commit fonctionnel et le bump patch `0.1.4+5`.

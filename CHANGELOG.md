# Historique

## Modifications récentes

- CI Android : initialisation des outils SDK avec `android-actions/setup-android@v3` avant l’installation du NDK dans les trois workflows, pour corriger `sdkmanager: command not found` sur les runners GitHub.

- Mise à jour Android : remplacement du manifeste Firebase par la disponibilité fournie par Google Play via un canal natif. Conservation du dialogue et du refus par build; échecs et délai maximal de 5 s silencieux. Tests du service couvrant disponibilité, refus, réponses invalides, erreurs et expiration. Ancien manifeste conservé pour les versions déjà installées.

- CI Android : installation explicite du NDK 27.0.12077973 avant les builds APK/AAB dans les trois workflows. Le décodeur résout désormais `ndk/<ndkVersion>` dans le SDK configuré et signale la commande d’installation si nécessaire, à la place du getter historique qui échouait sur les runners GitHub avec « NDK is not installed ».

- Android : ajout du décodage logiciel M4A ALAC, AAC et FLAC avec l’extension officielle Media3/FFmpeg, en complément des décodeurs système. Conservation du lecteur, des files et des commandes en arrière-plan. Compilation reproductible pour ARMv7, ARM64 et x86_64, avec alignement 16 Ko ; le contrôle préalable FLAC tient désormais compte du décodeur embarqué. Tests natifs AAC/ALAC ajoutés avec des sons synthétiques.

- Lecture FLAC sur un appareil sans décodeur FLAC (ex. tablette Huawei sous Android 8.0, qui n’a qu’un encodeur FLAC) : l’app affichait « lecture » en silence. `AudioCodecSupport` interroge `MediaCodecList` (méthode `canDecode` du canal `com.sauvank.musicstream/output`); `PlayerProvider` met alors en pause et publie `unsupportedFormat`, que `HomeScreen` affiche en bandeau (« FLAC non lisible sur cet appareil… »). Aucun décodeur logiciel n’est embarqué : le FLAC reste illisible sur ces appareils.
- La synchronisation transporte aussi les serveurs, mots de passe compris, dans l’enveloppe chiffrée de bout en bout (`SyncServer`, `ServerProvider.syncSnapshot/applySync`, `ServerSyncJournal`). Un serveur est identifié par type+adresse+utilisateur, pas par son id; les suppressions se propagent par pierres tombales datées. Windows : l’envoi Firestore n’utilise plus `runTransaction` (callbacks hors du thread plateforme, cause probable du plantage à la synchro).
- Formulaire « Ajouter un serveur » refait en feuille modale (comme la synchro) : erreurs de saisie visibles, œil pour le mot de passe, test de connexion avant l’enregistrement (second appui = enregistrer quand même), saisie sans correction automatique. Message « Mise à jour disponible » (lien Google Play) au lancement sur Android, piloté par `hosting/version.json` (`latestBuild`, à relever seulement une fois la version publiée sur Play) via `UpdateCheckService`.
- Source de démo pour la revue Google Play (rejet « mur de connexion ») : `hosting/demo/` (5 morceaux synthétisés par ffmpeg, index HTML lisible par le mode HTTP) et texte d’accès dans `docs/PLAY_REVIEW.md`. Déploiement manuel : `firebase deploy --only hosting`.
- Pages mémoire de 16 Ko (exigence Google Play) : `libbarhopper_v3.so` et `libimage_processing_util_jni.so`, ajoutées par `mobile_scanner`, n’étaient pas alignées. Chaîne de build modernisée (AGP 8.7.3, Gradle 8.9, Kotlin 2.1.0), `mobile_scanner` ^6.0.11, retrait du contournement `useLegacyPackaging`. Toutes les bibliothèques arm64-v8a et x86_64 de l’AAB sont maintenant alignées sur 16 Ko (vérifié avec `readelf`); les ABI 32 bits ne sont pas concernées.
- Mise en page PC : lignes de morceaux en colonnes titre/artiste/album au-delà de 620 px, écran Lecture limité à 560 px, écrans Serveurs et Réglages limités à 1000 et 760 px, raccourcis clavier (espace lecture/pause, flèches ±10 s, Ctrl+flèches piste précédente/suivante, touches média), réglage « Médiathèque de l’appareil » masqué hors Android. Vérifié par un aperçu Linux en 1440×900 (`flutter build linux` exige `libsecret-1-dev`).
- Connexion d’un ordinateur par QR code : l’ordinateur affiche un code (id aléatoire de 128 bits), le téléphone connecté via Google le scanne (`mobile_scanner` 6.0.2, la 6.0.11 exige un AGP 8.6) puis dépose son jeton Google (≈1 h) dans `pairings/{id}` (règles Firestore dédiées, lecture par id seulement, suppression par l’ordinateur après usage, pas de TTL : il exige la facturation Google Cloud). Permission CAMERA ajoutée; politique de confidentialité mise à jour.
- Windows : connexion e-mail/mot de passe pour la synchronisation (app Web Firebase « MusicStream Desktop », configuration injectée au build par `--dart-define=FIREBASE_DESKTOP_CONFIG_B64`, secret GitHub du même nom). Le bouton Google est masqué sur Windows et Linux, `google_sign_in` n’y existant pas. Installateurs `.exe` et `.msi` joints aux releases. Non testé sur PC.
- Écran Lecture : le nom de l’artiste (en couleur) ouvre la liste de tous ses morceaux de la bibliothèque, avec lecture d’un titre, « tout lire » et aléatoire (`showArtistTracks`).
- Version Windows : le service audio d’arrière-plan n’est initialisé que sur Android, iOS et macOS, `just_audio_windows` fournit le moteur audio; le workflow `build_and_release.yml` joint APK signés et zip Windows à la release GitHub de chaque tag. Build Windows non testé sur machine.
- v0.1.63 : la reprise de session recharge bien le morceau en cours (le premier événement d’index 0 émis au chargement de la file écrasait le morceau sauvegardé ; ignoré via `_restoreIndex`). Passe d’ergonomie vérifiée sur Galaxy S24.
- Synchronisation par compte Firebase (projet dédié) : connexion Google ou e-mail/mot de passe (création de compte, mot de passe oublié), enveloppe AES-256-GCM inchangée stockée dans Firestore `users/{uid}` avec contrôle de révision transactionnel, règles limitant chaque compte à son document (vérifiées par REST : 403 sur un autre document, un champ en clair ou sans authentification). Remplace la synchronisation WebDAV. Config Firebase hors dépôt (`docs/SETUP.md`). FlutterFire fixé à la génération compatible Kotlin 1.9.
- Identité visuelle : icône adaptive Android (dégradé violet→rose, glyphe égaliseur, variante monochrome pour les icônes à thème), PNG anciens formats et iOS, logo de démarrage, fond du splash Android 12+, et icône blanche dédiée pour la notification de lecture. Tout est généré par `scripts/generate_branding.py` à partir d’une seule géométrie, d’après `assets/branding/reference_sheet.jpg`.
- Recherche : insensible aux accents (« beyonce » trouve « Beyoncé »), bouton pour effacer, playlists correspondantes affichées au-dessus des morceaux et filtrées dans l’onglet Playlists, et 8 recherches récentes (`recent_searches_v1`) proposées quand le champ vide a le focus. Une recherche est retenue à la validation ou quand on lance un résultat.
- Écran Lecture teinté par la pochette : `ColorScheme.fromImageProvider` (sur une miniature 96 px, cache de 64 schémas) colore le fond en dégradé et les contrôles, avec une transition de 600 ms entre morceaux. Sans pochette, les couleurs de l’app restent.
- L’écran Lecture apparaît en glissant vers le haut avec un fondu (380 ms) à chaque ouverture, au lieu d’un changement d’onglet sec.
- Écran Lecture : tirer vers le bas depuis le haut revient à l’onglet précédent, et glisser la pochette à gauche/droite change de morceau.
- Retours haptiques : lecture/pause, précédent/suivant et aléatoire (écran Lecture et mini-lecteur), glissement du mini-lecteur, début d’un déplacement dans la file ou une playlist, retrait d’un morceau par glissement.
- Reprise de session : la file et le morceau en cours sont mémorisés (`playback_queue_v1`) et rechargés en pause au lancement, à la dernière position connue. Seuls les morceaux encore dans la bibliothèque reviennent (les flux serveur exigent leurs identifiants).
- Minuterie de sommeil (icône lune de l’écran Lecture) : 15 à 90 min avec un fondu de 8 s avant la pause, ou pause à la fin naturelle du morceau (un saut manuel ne la déclenche pas). Le compte à rebours s’affiche sous « Lecture en cours ».
- Vignettes de playlist : bouton de lecture aléatoire directement sur la pochette.
- Playlist : glisser un morceau vers la gauche le retire, et un message « Annuler » le remet à sa place (`LibraryProvider.restoreTrackToPlaylist`). Le retrait par le menu propose aussi l’annulation.
- Dans une playlist, toucher un morceau lance la lecture et ouvre l’écran Lecture (`HomeScreen.openNowPlaying` ferme la page playlist puis sélectionne l’onglet).
- Synchronisation chiffrée : bouton pour afficher la phrase secrète tapée ; message dédié quand le serveur refuse l’écriture (HTTP 401/403, cas d’un compte AList sans « Gérer WebDAV ») ; cause de l’échec (méthode et code HTTP) ajoutée aux autres erreurs ; l’activation est annulée si la première synchronisation échoue, au lieu d’afficher « Active » sans jamais synchroniser.
- Ajout d’un bouton « Ajouter à une playlist » dans l’écran Lecture, qui réutilise la feuille de choix de la bibliothèque. Vérifié sur Galaxy S24.
- Correction du bouton lecture masqué par la barre de navigation : la pochette réserve plus de place et rétrécit encore d’une ligne quand le titre passe sur deux lignes. Vérifié sur Galaxy S24.
- Correction du visualiseur qui disparaissait au changement de morceau : l’écran sortant arrêtait la capture du nouveau, et la vérification tardive de l’autorisation ne relançait pas la capture.
- Ajout d’un visualiseur en direct par-dessus la pochette (écran Lecture) : 24 bandes du spectre réel de la session audio de l’app (`android.media.audiofx.Visualizer`), activé d’un toucher. Android impose la permission micro, mais rien n’est enregistré. La capture ne tourne que si l’onglet est visible, l’app au premier plan et la musique en lecture. Le widget d’accueil affiche des barres animées pendant la lecture. Vérifié sur Galaxy S24.
- Ajout d’un bouton « Diffuser sur un autre appareil » dans l’écran Lecture : il ouvre le sélecteur de sortie audio d’Android (Bluetooth, dont un Echo appairé, et appareils compatibles), via `androidx.mediarouter`. Vérifié sur Galaxy S24.
- Correction : supprimer un morceau de la médiathèque du téléphone le retire désormais de MusicStream (listes, « Ajoutés récemment ») au lieu d’être ignoré en silence. Le fichier d’origine est conservé et son URI est mémorisée (`device_media_hidden_v1`) pour que les scans suivants ne le réimportent pas.
- Ajout de la synchronisation chiffrée (Réglages › Connexions) : favoris, écoutes et playlists chiffrés en AES-256-GCM avec une clé PBKDF2-SHA256 dérivée d’une phrase secrète, stockés dans `musicstream-sync.json` sur un serveur WebDAV choisi. Fusion par dernière modification, suppressions de playlists propagées, envoi conditionné par ETag. Vérifié sur Galaxy S24 avec un serveur WebDAV local (activation en 3,7 s).
- Correction du bouton de la feuille de synchronisation sous la barre de navigation et du libellé « WebDAV » coupé dans l’ajout de serveur.
- Ajout d’un widget d’accueil Android 4×1 : pochette, titre, artiste et boutons précédent/lecture/suivant, ajoutable depuis Réglages › Lecture. Quand l’application n’est pas lancée, les boutons l’ouvrent. Vérifié sur Galaxy S24.
- Ajout de la médiathèque de l’appareil (Réglages › Bibliothèque), désactivée par défaut : les morceaux déjà présents sur le téléphone sont lus sur place, sans copie, jamais supprimés par l’application, et retirés de la bibliothèque si la source est désactivée. Les doublons évidents des imports privés sont ignorés; un scan en arrière-plan a lieu au démarrage si l’accès est accordé. 720 morceaux indexés en 17 s sur Galaxy S24.
- FTP vérifié sur Galaxy S24 (serveur passif de test) : navigation, téléchargement d’un fichier et d’un dossier avec déduplication, référence et détection d’un nouvel album.
- Correction du clavier qui se rouvrait après un dialogue : le champ de recherche de l’onglet Bibliothèque, masqué mais vivant, reprenait le focus. Le focus est libéré au changement d’onglet et au toucher hors du champ.
- « Artiste inconnu » traduit dans la liste des fichiers distants; titre de l’écran Serveurs et sélecteur WebDAV/HTTP/FTP qui ne se coupent plus en plein mot; icône distincte pour l’import JSON.
- Import manuel d’un `.lrc`, affichage synchronisé et saut à une ligne vérifiés sur Galaxy S24.
- Correction du bouton d’import resté en chargement après le nettoyage des orphelins au démarrage (v0.1.36).
- La notification de lecture système traduit « Artiste inconnu » et « Album inconnu » selon la langue.
- Correction de l’import de dossier sur Android 13+ : sans `READ_MEDIA_AUDIO`, le dossier paraissait vide. La permission est déclarée et demandée avant l’import, avec accès aux réglages en cas de refus.
- Nettoyage au démarrage des copies privées qu’aucun morceau ne référence (import ou téléchargement interrompu), avec garde-fous contre un index illisible.
- Mesure de l’import sur Galaxy S24 : 40 fichiers de 3 min (146 Mo) en 2,6 s, soit ~55 ms d’empreinte, 8 ms de copie et 3 ms de tags par fichier, sans image figée au-delà de 50 ms.
- Vérification sur Galaxy S24 de la description et du réordonnancement des playlists, persistés après redémarrage.
- Localisation de l’interface en français et en anglais (fichiers ARB, `gen-l10n`), avec choix Système/Français/English dans Réglages; notifications de téléchargement et canal audio traduits. Vérifié sur Galaxy S24.
- Ajout d’un choix de thème Système/Clair/Sombre dans Réglages, persisté et vérifié sur Galaxy S24 après redémarrage.
- Mesure du défilement de la bibliothèque sur Galaxy S24 (332 morceaux) : construction médiane 2,5 ms, rendu médian 4 ms, aucune saccade durable; pas d'optimisation nécessaire.
- Démarrage à froid accéléré : l’initialisation du gestionnaire natif de téléchargements (0,7 à 1,4 s mesurées sur Galaxy S24) ne bloque plus le premier affichage; démarrage mesuré de 1,2–1,7 s à 0,71–0,95 s avec environ 300 morceaux.
- Ajout d’une description facultative aux playlists (dialogue « Modifier ») et d’un mode « Réorganiser l’ordre » par glisser-déposer, persisté immédiatement.
- Remplacement du bouton de téléchargement des pistes serveur déjà importées par un badge « Sur le téléphone »; mise à jour immédiate après import.
- Réduction des ralentissements avec une grande bibliothèque : sérialisation de l'index hors du thread UI et ordonnée, actualisations de téléchargements regroupées, calculs d'onglets évités et pochettes décodées à la taille utile.
- Correction de l’inventaire WebDAV de dossiers contenant des fichiers dont le nom inclut `%`, validée par un ajout de dossier à la file sur Android. Les erreurs de dossier indiquent maintenant la phase et le code HTTP éventuel.
- Disponibilité des dossiers distants rendue explicite : libellé vert si tous les morceaux sont présents, compteur orange si seule une partie l’est, aucun pictogramme si aucun n’est présent.
- Téléchargements de dossiers imbriqués dédupliqués et limités à deux transferts simultanés par serveur; affichage de la disponibilité des morceaux par dossier et retour Android interne à l’application.
- Suppression individuelle ou globale des morceaux téléchargés, avec traitement explicite des anciennes pistes sans origine connue.
- Correction de la navigation WebDAV lorsque les liens d’un dossier utilisent un encodage différent ou contiennent un signe `%` ; vérifiée sur Android physique.
- Affichage des noms de dossiers distants sur une seule ligne, avec troncature des noms trop longs.
- Recherche automatique LRCLIB au changement de morceau après accord persistant, repli sur la recherche exacte et traduction MyMemory à la demande avec cache privé et horodatages préservés; accord, recherche automatique, affichage et traduction vérifiés sur Galaxy S24.
- Validation sur Galaxy S24 de l’ouverture de la feuille Paroles et de ses actions visibles; démarrage confirmé sur l’émulateur Android API 35.
- Ajout des paroles `.lrc` locales, de la recherche LRCLIB explicite, du cache privé et de l’affichage synchronisé dans l’écran Lecture.
- Ajout d’un volume applicatif persistant, correctement respecté par les fondus, et d’un historique local qui ne valide un morceau qu’après une écoute effective.
- Validation sur Galaxy S24 sous Android 16 du volume persistant, des fondus, de l’historique après écoute réelle et de l’adaptation verticale de l’écran Lecture.
- Ajout d’une file de lecture visible et réorganisable avec sélection, retrait, « Lire ensuite » et ajout en fin depuis chaque morceau.
- Ajout d’un scan manuel des serveurs qui crée une référence locale puis signale les nouveaux morceaux regroupés par album.
- Adaptation de l’écran de lecture aux téléphones peu hauts afin que le bouton principal ne passe plus derrière la barre de navigation.
- Ajout des profils FTP passifs, de leur import JSON, de la navigation distante et du téléchargement/import de morceaux ou dossiers.
- Correction de « Tout lire » afin qu’un ancien mode de répétition du morceau ne rejoue plus indéfiniment la première piste de la file.
- Ajout de fondus configurables et persistants à la lecture, la pause et la navigation entre morceaux.
- Ajout de l’import de profils serveur par fichier JSON ou texte collé, compatible MusicStream et ComicStream, avec séparation immédiate du mot de passe.
- Ajout du téléchargement de dossiers distants entiers.
- Ajout d’une file native persistante en arrière-plan avec notifications, progression, pause, reprise, annulation et nouvelle tentative.
- Indexation automatique des fichiers terminés avec déduplication, tags et pochettes.
- Affichage distant préparé pour le titre, l’artiste et la pochette; l’extraction partielle reste à fiabiliser.
- Autorisation Android du trafic HTTP pour les serveurs personnels non TLS.
- Ajout de l’écoute directe d’un morceau serveur avant téléchargement.
- Ajout de l’import récursif d’un dossier musical local.
- Validation sur Android physique de la lecture serveur authentifiée, du téléchargement pendant que l’app est en arrière-plan, de l’indexation avec pochette et de la sélection d’un dossier imbriqué.
- Fiabilisation des tags distants avec des échantillons creux tête/fin, limitation à deux requêtes simultanées et test HTTP M4A dédié.
- Ajout des commandes de lecture aléatoire et de répétition désactivée/file/morceau, validées sur Android physique.

Les versions publiées restent décrites par les tags Git.

- Fix: `.m4b` (audiobooks) added to `LibraryService.supportedExtensions`, so WebDAV/HTTP/FTP listings, imports and device scan now include them.

- Feat: audiobook mode. `MusicTrack.chapters`/`isAudiobook` (M4B or genre Audiobook), M4B `chpl` chapters read at import, "Livres audio" library tab with progress bars, Now Playing chapter label/list, chapter prev/next, ±30 s, speed 0.75–2x, position saved immediately on pause.

- Fix: server file rows show a progress loader instead of the download icon while a download is queued, running or being imported.

- Feat: audiobook resume position synced (latest save wins per track, `SyncTrackState.positionMs/positionAt`, `SyncJournal.positionTimes`). Fix: Now Playing controls stay centred for audiobooks.

- Change: audiobook sync positions are no longer applied silently by a sync. Opening an audiobook (`playWithPositionCheck`, `lib/widgets/audiobook_position_gate.dart`) compares with the synced position and asks: ignore / keep here (publishes local as newest) / resume from sync. Same flow as Comics Stream's `SyncedReaderGate`.

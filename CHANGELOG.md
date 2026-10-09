# Historique

## Modifications récentes

- Ajout de morceaux à une playlist : page plein écran au lieu d’une liste à cocher brute, avec recherche (sans accents), pochettes, vue par albums (une case coche tout l’album, état partiel affiché, album dépliable) et compteur ; les nouveaux morceaux s’ajoutent dans l’ordre où ils ont été cochés.

- Troisième passe (tour scripté des fenêtres) :
  - livre audio en plusieurs fichiers : progression et temps restant sur tout le livre, bouton « chapitre suivant/précédent » qui passe au fichier voisin ;
  - navigateur serveur : dans un sous-dossier, le bouton télécharge ce dossier (« Télécharger ce dossier ») au lieu de tout le serveur ;
  - médiathèque du téléphone : un fichier doublonné par une copie importée/téléchargée ensuite est oublié au scan suivant (sauf favori ou playlist) ;
  - bibliothèque vide sans grand titre (le bouton « Ajouter ma musique » passait sous la navigation) ; bouton « Reprendre » en icône sur téléphone ; « Serveurs personnels » mentionne FTP.

- Repasse UI après un tour complet sur 8 profils d’écran (360×640 à 1920×1080, texte ×1,3/×1,5, tablettes, PC) :
  - correctif : une file restaurée au lancement jouait son premier morceau au lieu de celui affiché, y compris depuis la notification ou un casque (cause du « Chapitre 1 » inattendu) ;
  - Lecture : pochette adaptée à la hauteur et à la taille du texte, commandes toujours visibles ; « Album/Genre inconnu » masqués ; volume sans retour à la ligne ;
  - pages album/artiste/playlist : mini-lecteur présent, titre lisible ;
  - lignes de morceau plus compactes sur téléphone ; menu « Voir l’album », « Voir l’artiste » ; suppression masquée pour la musique du téléphone ;
  - favoris vides : message dédié ; « Aléatoire » en icône (titre « Tous les morceaux » sur une ligne) ; libellés de navigation bornés en taille ;
  - Serveurs : sans grand titre (le bouton d’ajout n’est plus sous le mini-lecteur), actions du serveur dans un menu ⋮, icône de file de téléchargement distincte, titre à l’import JSON ;
  - Réglages : sans grand titre, tuiles d’information non cliquables sans fond, « Serveurs personnels » ouvre l’onglet, version affichée ;
  - ondes du son : explication avant la demande d’autorisation « enregistrer de l’audio » ;
  - adresse du compte de synchro sur sa propre ligne.

- Parcours revus après l’audit UX :
  - livres audio regroupés par livre (album + auteur), avec la progression sur tous les chapitres, une section « En cours d’écoute » et un bouton « Reprendre » ; les chapitres d’un même livre s’enchaînent dans l’ordre naturel, sans aléatoire ;
  - recherche globale : artistes, albums, livres audio, playlists et morceaux, quel que soit l’onglet, avec « Aucun résultat pour « … » » ;
  - en-tête compact quand la bibliothèque n’est pas vide ;
  - « Ajoutés récemment » montre des albums ;
  - onglets réordonnés (Albums et Artistes visibles), rangée estompée au bord ;
  - « Ajouter de la musique » propose la musique du téléphone et les serveurs ;
  - « Supprimer les téléchargements » passe dans un menu ⋮ ;
  - Retour : vers la Bibliothèque, puis annule recherche, filtre favoris et vue, puis quitte l’app (la lecture continue) ; avant, il ne quittait jamais depuis la Bibliothèque ;
  - téléchargements réessayés 6 fois au lieu de 3 (erreurs 500 intermittentes d’alist/TeraBox).

- Performances : l’animation d’entrée des listes de la bibliothèque ne joue plus que sur le premier écran (frames de rendu hors budget au défilement de 255 à ~35 sur 640). Ajout des benchmarks `integration_test` (UI et 3 000 téléchargements WebDAV), voir `docs/TESTING.md`.

- CI accélérée : fusion de `build_and_release.yml` dans `release.yml` (une seule installation par job, builds Android/Windows en parallèle, APK universel tiré de l’AAB, APK x86_64 séparé abandonné), suppression du build debug de `ci.yml`, CI ignorée sur les bumps de version, caches Gradle/Flutter remplis sur `main` par `warm-cache.yml`. Environ 50 → 20 minutes facturées par version.

- Validation physique du correctif des téléchargements sur Galaxy S24 : lot local de 1 500 MP3 distincts, tous téléchargés et indexés, progression en arrière-plan et navigation fonctionnelles, données conservées après arrêt/relance. Aucun crash/ANR ni erreur d’indexation observé; intégrité de trois fichiers contrôlée. Test réalisé dans l’application séparée, sans modifier les données Play.

- Stabilité des gros téléchargements : moteur `background_downloader` 9.5.5, service Android `dataSync`, rafraîchissements regroupés sur 500 ms et lecture des tags/pochettes dans un isolate. Outils Android alignés (AGP 8.9.2, Gradle 8.11.1); installation de test indépendante facultative. Tests de rafales de 1 500 événements, de file volumineuse et de métadonnées hors du thread UI.

- Interface serveur : bouton « Tout télécharger » sur une ligne dédiée pleine largeur dans la carte, au lieu du sous-titre comprimé par les actions. Libellé court français/anglais dans le navigateur, description complète en infobulle et une seule ligne avec ellipse si le texte est agrandi. Tests à 320 px et texte ×2 pour les deux emplacements.

- Refonte des téléchargements : feuille redimensionnable, accès permanent, filtres et compteurs, fichiers en cours avant les fichiers en attente, pourcentage/taille/dossier, erreurs HTTP lisibles et actions explicites. Préparation des dossiers indépendante de l’écran, sans dialogue bloquant; bouton de téléchargement du serveur entier, accès capturés pour continuer après navigation, FTP suivi au premier plan. « Terminés » compte les transferts achevés même pendant l’indexation; relecture différée après les callbacks natifs pour éviter un dernier état périmé. Une nouvelle tentative acceptée retire l’ancien échec; le nettoyage conserve la musique. Tests d’interaction, préparation, tri, erreurs et petit écran avec texte agrandi ajoutés.

- Correction d’une course PC → téléphone : une position de livre audio enregistrée pendant l’envoi réseau n’est plus écrasée par l’ancien instantané appliqué à la fin de la synchronisation; la passe différée peut ensuite publier la position récente.

- Refonte de la synchronisation : détection du compte chiffré avant saisie (une seule phrase pour déverrouiller, confirmation seulement à la création), aucune réécriture distante si la fusion n’a rien changé, trois nouvelles tentatives en cas de conflit, reprise automatique avec délai croissant hors ligne, historique des changements inclus et chiffré dans l’enveloppe partagée, compteurs d’écoutes par appareil et horloges logiques observant les valeurs distantes. L’association QR peut maintenant transmettre la clé au PC dans une enveloppe AES-GCM protégée par un secret aléatoire du QR; Firestore ne stocke que cette enveloppe chiffrée. Les règles Firestore correspondantes ont été compilées et déployées.

- Activation de la synchronisation : un appareil qui rejoint un compte contenant déjà une enveloppe chiffrée ne demande désormais la phrase secrète qu'une seule fois. La confirmation reste affichée uniquement lors de la création de la première enveloppe sur un compte vide.

- Publication Google Play : passage du `minSdk` de 23 à 24 dans l'application et le décodeur Android, exigé par la protection automatique Play. Le workflow utilise aussi l'entrée `tracks` actuelle de l'action d'envoi au lieu de l'ancien `track` déprécié.

- Historique de synchronisation : correction de `JsonUnsupportedObjectError` sur PC lorsque l'enveloppe contient des suppressions de playlists ou de serveurs. Le résumé convertit désormais leurs horodatages `DateTime` en chaînes ISO avant comparaison JSON; un second passage après suppression est couvert par test.

- Livres audio : toucher un livre dans la liste conserve désormais un signet situé dans les 30 dernières secondes. Seule la fin réelle (dernière seconde) déclenche un redémarrage à `0:00`, ce qui aligne ce chemin avec la reprise depuis le mini-lecteur.

- Synchronisation PC → téléphone : une publication de position demandée pendant une autre synchronisation est désormais rejouée au lieu d'être perdue, et l'ouverture d'un livre audio vérifie la position distante même si une synchronisation tourne déjà. Ajout d'un historique local des 30 dernières synchronisations réussies (10 affichées), avec date, catégories modifiées et détail des positions de livres audio envoyées ou reçues.

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

- Feat: audiobook sync now automatic like Comics Stream: position published when the app is left (HomeScreen lifecycle) or an audiobook is paused (`SyncProvider.publishPosition`); on resume with an idle audiobook the position is compared and the keep/resume dialog shown. Superseded: everything now syncs automatically (see next entry).

- Feat: full automatic sync (`SyncProvider.startAutoSync/autoSync`): at launch, 3 s after any change to favorites/playlists/servers/play counts/audiobook positions (signature compare, no network when idle), on leaving or resuming the app, and on audiobook pause. Add-to-playlist sheet now has a "Nouvelle playlist" row.

- Rework: audiobook mode. Audiobooks left out of music views (`LibraryProvider.tracks`) and played alone; Now Playing `_AudiobookPanel` with a chapter-relative slider, chapter title (generic "Chapitre N" not repeated), whole-book percent and time left at current speed, controls split in two rows; speed persisted and applied to audiobooks only (music stays 1x); 3 s rewind on resume; finished books restart; sleep timer "end of chapter".

- Fix (critical): startup hang on v0.1.90 (`setSpeed` sent before the restored queue loaded blocked the first frame; speed now applied after loading and only when it changes). Fix: an audiobook bookmark was overwritten with 0:00 at launch (idle player counted as a pause); positions are now saved only on a real pause, while playing, or on an explicit seek.

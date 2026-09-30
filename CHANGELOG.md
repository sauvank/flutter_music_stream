# Historique

## Modifications récentes

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

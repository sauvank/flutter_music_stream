# Historique

## Modifications récentes

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

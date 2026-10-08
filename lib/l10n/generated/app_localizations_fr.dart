import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get downloadEntireServer => 'Télécharger tout le serveur';

  @override
  String get downloadAll => 'Tout télécharger';

  @override
  String downloadPreparing(String name) {
    return 'Préparation de « $name »… Vous pouvez continuer à naviguer.';
  }

  @override
  String get downloadPreparingShort => 'Préparation des téléchargements…';

  @override
  String get downloadPreparationHint =>
      'L’analyse continue pendant que vous naviguez. Les fichiers déjà présents seront ignorés.';

  @override
  String get downloadFtpHint =>
      'Vous pouvez naviguer dans MusicStream. Gardez l’application ouverte pendant les transferts FTP.';

  @override
  String downloadWaitingSummary(int waiting, int paused) {
    return '$waiting en attente · $paused en pause';
  }

  @override
  String downloadHttpError(int code) {
    return 'Le serveur a répondu avec une erreur HTTP $code. Vous pouvez réessayer.';
  }

  @override
  String downloadQueueActive(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count téléchargements en cours',
      one: '$count téléchargement en cours',
    );
    return '$_temp0';
  }

  @override
  String downloadQueueSummary(int finished, int failed) {
    String _temp0 = intl.Intl.pluralLogic(
      finished,
      locale: localeName,
      other: '$finished terminés',
      one: '$finished terminé',
    );
    return '$_temp0 · $failed à réessayer';
  }

  @override
  String get downloadNeedsAttention => 'Des téléchargements à réessayer';

  @override
  String get downloadManage => 'Suivre les transferts et gérer l’historique';

  @override
  String get downloadActionFailed =>
      'Action impossible pour le moment. Réessayez dans quelques instants.';

  @override
  String get downloadBackgroundHint =>
      'Vous pouvez fermer cette fenêtre : les téléchargements continuent.';

  @override
  String get downloadQueueActions => 'Gérer la file';

  @override
  String get downloadFilterAll => 'Tout';

  @override
  String get downloadFilterActive => 'En cours';

  @override
  String get downloadFilterFailed => 'Échecs';

  @override
  String get downloadFilterFinished => 'Terminés';

  @override
  String get downloadQueueUpToDate => 'Aucun transfert en attente';

  @override
  String get downloadClearHistory => 'Nettoyer l’historique';

  @override
  String get downloadEmptyFilter => 'Rien dans cette catégorie';

  @override
  String get downloadEmptyFilterHint =>
      'Consultez les autres catégories pour retrouver vos téléchargements.';

  @override
  String get downloadEmptyHint =>
      'Téléchargez un morceau ou un dossier depuis vos serveurs pour l’écouter hors ligne. Retrouvez ici vos transferts HTTP/WebDAV.';

  @override
  String get downloadBrowseServers => 'Parcourir les serveurs';

  @override
  String get downloadShowAll => 'Tout afficher';

  @override
  String get downloadIndexing => 'Ajout à la bibliothèque…';

  @override
  String get downloadTransferComplete => 'Transfert terminé';

  @override
  String get downloadMoreActions => 'Options du téléchargement';

  @override
  String get downloadMissingHint =>
      'Ce fichier n’est plus disponible à cette adresse sur le serveur.';

  @override
  String get downloadFailedHint =>
      'Vérifiez votre connexion et l’accès au serveur, puis réessayez.';

  @override
  String get downloadViewQueue => 'Voir les téléchargements';

  @override
  String get downloadHistoryHint =>
      'Le nettoyage retire les transferts terminés ou annulés de cette liste. Vos morceaux sont conservés.';

  @override
  String get actionNext => 'Suivant';

  @override
  String get actionPause => 'Pause';

  @override
  String get actionPlay => 'Lire';

  @override
  String get actionPrevious => 'Précédent';

  @override
  String get addFavorite => 'Ajouter aux favoris';

  @override
  String get addMyMusic => 'Ajouter ma musique';

  @override
  String get addServer => 'Ajouter un serveur';

  @override
  String get addToPlaylist => 'Ajouter à une playlist';

  @override
  String get addToQueue => 'Ajouter à la file';

  @override
  String addTrackTitle(String title) {
    return 'Ajouter « $title »';
  }

  @override
  String get addTracks => 'Ajouter des morceaux';

  @override
  String addTracksTitle(String tracks) {
    return 'Ajouter $tracks';
  }

  @override
  String addedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ajoutés',
      one: '$count ajouté',
    );
    return '$_temp0';
  }

  @override
  String addedToPlaylist(int count, String playlist) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count morceaux ajoutés à « $playlist ».',
      one: '$count morceau ajouté à « $playlist ».',
    );
    return '$_temp0';
  }

  @override
  String addedToQueue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ajoutés à la file.',
      one: 'Ajouté à la file.',
    );
    return '$_temp0';
  }

  @override
  String get allOnPhone => 'Tout sur le téléphone';

  @override
  String get allTracks => 'Tous les morceaux';

  @override
  String alreadyDownloading(String name) {
    return '$name est déjà en cours de téléchargement.';
  }

  @override
  String get audioChannelName => 'Lecture audio';

  @override
  String get audioOutput => 'Diffuser sur un autre appareil';

  @override
  String get audioOutputUnavailable =>
      'Impossible d’ouvrir le choix de sortie audio.';

  @override
  String get audioPermissionDenied =>
      'MusicStream a besoin d’accéder à vos fichiers audio pour importer un dossier.';

  @override
  String get automaticLyrics => 'Paroles automatiques';

  @override
  String get automaticLyricsHint =>
      'Pendant la lecture, envoie les métadonnées du morceau à LRCLIB si ses paroles ne sont pas déjà enregistrées.';

  @override
  String get availableOffline => 'Disponible hors connexion';

  @override
  String get availableOfflineHint =>
      'Vos morceaux restent dans le stockage privé de l’app';

  @override
  String baselineBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count morceaux mémorisés.',
      one: '$count morceau mémorisé.',
    );
    return '$_temp0 Les prochains scans signaleront uniquement les nouveautés.';
  }

  @override
  String get baselineCreated => 'Référence créée';

  @override
  String get cancel => 'Annuler';

  @override
  String get cancelAll => 'Tout annuler';

  @override
  String cancelAllBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count téléchargements en cours ou en attente seront annulés.',
      one: '$count téléchargement en cours ou en attente sera annulé.',
    );
    return '$_temp0 Les morceaux déjà importés sont conservés.';
  }

  @override
  String get cancelAllTitle => 'Tout annuler ?';

  @override
  String get chooseJsonFile => 'Choisir un fichier JSON';

  @override
  String get clearFilter => 'Effacer le filtre';

  @override
  String get clearFinished => 'Effacer les terminés';

  @override
  String get clearRecentSearches => 'Effacer';

  @override
  String get clearSearch => 'Effacer la recherche';

  @override
  String get clearSelection => 'Annuler la sélection';

  @override
  String get close => 'Fermer';

  @override
  String collectionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count collections',
      one: '$count collection',
    );
    return '$_temp0';
  }

  @override
  String get connectCollectionBody =>
      'Parcourez un serveur WebDAV, HTTP ou FTP, puis gardez vos morceaux préférés hors connexion.';

  @override
  String get connectCollectionTitle => 'Connectez votre\ncollection';

  @override
  String get continueAction => 'Continuer';

  @override
  String get continueInBackground => 'Continuer en arrière-plan';

  @override
  String get create => 'Créer';

  @override
  String get createPlaylist => 'Créer une playlist';

  @override
  String get delete => 'Supprimer';

  @override
  String deleteDownloadsBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Les $count morceaux sélectionnés seront supprimés de MusicStream sur ce téléphone.',
      one:
          'Le morceau sélectionné sera supprimé de MusicStream sur ce téléphone.',
    );
    return '$_temp0';
  }

  @override
  String get deleteDownloadsTitle => 'Supprimer les téléchargements ?';

  @override
  String get deleteDownloadsTooltip =>
      'Supprimer les téléchargements du téléphone';

  @override
  String get deleteFailed => 'Suppression impossible. Réessayez.';

  @override
  String get deleteFromPhone => 'Supprimer du téléphone';

  @override
  String get deleteIncludesLegacy =>
      'Cela inclut les anciens morceaux que vous avez choisis.';

  @override
  String get deleteKeepsLocal => 'Les imports locaux sont conservés.';

  @override
  String deletePlaylistBody(String name) {
    return '« $name » sera supprimée. Vos morceaux seront conservés.';
  }

  @override
  String get deletePlaylistTitle => 'Supprimer la playlist ?';

  @override
  String deleteServerBody(String name) {
    return '« $name », son mot de passe enregistré et sa référence de nouveaux albums seront supprimés. Les morceaux déjà téléchargés restent dans la bibliothèque.';
  }

  @override
  String get deleteServerTitle => 'Supprimer ce serveur ?';

  @override
  String deleteTracksBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Les morceaux et leurs fichiers associés seront supprimés de MusicStream sur ce téléphone. Les fichiers d’origine sont conservés.',
      one:
          'Le morceau et ses fichiers associés seront supprimés de MusicStream sur ce téléphone. Le fichier d’origine est conservé.',
    );
    return '$_temp0';
  }

  @override
  String deleteTracksTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Supprimer ces $count morceaux ?',
      one: 'Supprimer ce morceau ?',
    );
    return '$_temp0';
  }

  @override
  String deletedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count morceaux supprimés du téléphone.',
      one: '$count morceau supprimé du téléphone.',
    );
    return '$_temp0';
  }

  @override
  String get description => 'Description';

  @override
  String get deviceMedia => 'Médiathèque de l’appareil';

  @override
  String deviceMediaCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count morceaux du téléphone',
      one: '$count morceau du téléphone',
    );
    return '$_temp0';
  }

  @override
  String get deviceMediaHint =>
      'Ajoute les morceaux déjà présents sur le téléphone, sans les copier.';

  @override
  String get deviceMediaPermission =>
      'MusicStream a besoin d’accéder à vos fichiers audio pour lire la médiathèque du téléphone.';

  @override
  String get deviceMediaRescan => 'Rechercher à nouveau';

  @override
  String get deviceMediaScanning => 'Recherche des morceaux du téléphone…';

  @override
  String deviceMediaSummary(int added, int removed) {
    return '$added ajouté(s) · $removed retiré(s)';
  }

  @override
  String get deviceTrackBadge => 'Sur l’appareil';

  @override
  String get disconnect => 'Déconnecter';

  @override
  String get done => 'Terminer';

  @override
  String get download => 'Télécharger';

  @override
  String get downloadFailed => 'Téléchargement impossible.';

  @override
  String get downloadFolder => 'Télécharger tout le dossier';

  @override
  String downloadProgress(int current, int total) {
    return 'Téléchargement $current / $total';
  }

  @override
  String downloadTitle(String name) {
    return 'Télécharger « $name »';
  }

  @override
  String downloadingTracks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Téléchargement de $count morceaux…',
      one: 'Téléchargement de $count morceau…',
    );
    return '$_temp0';
  }

  @override
  String get downloads => 'Téléchargements';

  @override
  String get edit => 'Modifier';

  @override
  String get editPlaylist => 'Modifier la playlist';

  @override
  String get emptyHeadline => 'Votre musique mérite\nun bel écrin.';

  @override
  String get emptyHistoryBody =>
      'Les morceaux suffisamment écoutés apparaîtront ici.';

  @override
  String get emptyHistoryTitle => 'Votre historique est encore vide';

  @override
  String get emptyLibraryBody =>
      'Ajoutez vos morceaux : ils restent privés, disponibles hors connexion et classés automatiquement.';

  @override
  String get emptyLibraryTitle => 'Donnez vie à\nvotre bibliothèque';

  @override
  String get emptyPlayerHint =>
      'Choisissez un morceau dans votre bibliothèque pour commencer.';

  @override
  String get emptyPlayerTitle => 'Prêt à vibrer ?';

  @override
  String get emptyPlaylist => 'Cette playlist est vide';

  @override
  String get emptyPlaylistsBody =>
      'Regroupez vos morceaux pour les retrouver et les lire dans l’ordre.';

  @override
  String get emptyPlaylistsTitle => 'Créez votre première playlist';

  @override
  String get enable => 'Activer';

  @override
  String get encryptedSync => 'Synchronisation chiffrée';

  @override
  String get encryptedSyncHint =>
      'Métadonnées uniquement, jamais vos fichiers audio';

  @override
  String get enrichLibrary => 'Enrichir la bibliothèque';

  @override
  String fadeMilliseconds(int milliseconds) {
    return '$milliseconds ms';
  }

  @override
  String get fadeOff => 'Non';

  @override
  String get fadeSecond => '1 s';

  @override
  String get fades => 'Fondus de lecture';

  @override
  String get fadesHint => 'Adoucit lecture, pause et changements de morceau';

  @override
  String get favorites => 'Favoris';

  @override
  String get fileReadFailed => 'Impossible de lire ce fichier.';

  @override
  String get filterFolder => 'Filtrer ce dossier';

  @override
  String get folder => 'Dossier';

  @override
  String folderConnectionLost(String stage) {
    return 'Connexion interrompue pendant $stage du dossier.';
  }

  @override
  String folderFailed(String stage) {
    return 'Impossible de terminer $stage du dossier.';
  }

  @override
  String folderHttpError(int status, String stage) {
    return 'Le serveur a renvoyé une erreur HTTP $status pendant $stage du dossier.';
  }

  @override
  String folderQueued(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count morceaux ajoutés.',
      one: '$count morceau ajouté.',
    );
    return '$_temp0 Vous pouvez fermer cette fenêtre : le téléchargement continue en arrière-plan.';
  }

  @override
  String get folderReadFailed => 'Impossible de lire le contenu du dossier.';

  @override
  String get folderTooLarge => 'Le dossier contient trop de morceaux.';

  @override
  String get ftpAddress => 'Adresse FTP';

  @override
  String get ftpUnencrypted =>
      'FTP transmet les identifiants et les fichiers sans chiffrement.';

  @override
  String get goodAfternoon => 'Bon après-midi';

  @override
  String get goodEvening => 'Bonsoir';

  @override
  String get goodMorning => 'Bonjour';

  @override
  String get headline => 'Qu’avez-vous envie\nd’écouter ?';

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String get privacyPolicyHint =>
      'Découvrez comment MusicStream traite vos données';

  @override
  String get pairSignInWithPhone => 'Se connecter avec le téléphone';

  @override
  String get pairQrTitle => 'Scannez avec votre téléphone';

  @override
  String get pairQrHint =>
      'Sur votre téléphone, ouvrez Réglages → Synchronisation chiffrée → Connecter un ordinateur, puis scannez ce code. Si la synchro est déjà activée sur le téléphone, le PC sera aussi déverrouillé automatiquement.';

  @override
  String get pairWaiting => 'En attente du téléphone…';

  @override
  String get pairConnectComputer => 'Connecter un ordinateur';

  @override
  String get pairConnectComputerHint =>
      'Scannez le QR code affiché sur l’ordinateur. Si la synchro est déverrouillée, sa clé sera transmise chiffrée.';

  @override
  String get pairScanTitle => 'Scanner le QR code';

  @override
  String get pairConfirmTitle => 'Connecter cet ordinateur ?';

  @override
  String get pairConfirmBody =>
      'Il sera connecté à votre compte et, si la synchro est déverrouillée, recevra sa clé chiffrée. Continuez seulement si vous l’avez demandé sur votre propre ordinateur.';

  @override
  String get pairConfirm => 'Connecter';

  @override
  String get pairDone => 'Ordinateur connecté.';

  @override
  String get pairGoogleOnly =>
      'Disponible uniquement avec un compte connecté via Google.';

  @override
  String get pairInvalidCode => 'Ce code n’est pas un code MusicStream.';

  @override
  String get pairExpired => 'Le code a expiré. Réessayez.';

  @override
  String get pairFailed => 'La connexion a échoué. Réessayez.';

  @override
  String get hidePassphrase => 'Masquer la phrase secrète';

  @override
  String get homeWidget => 'Widget d’accueil';

  @override
  String get homeWidgetAdd => 'Ajouter';

  @override
  String get homeWidgetHint =>
      'Morceau en cours et commandes de lecture sur l’écran d’accueil.';

  @override
  String get homeWidgetUnsupported =>
      'Votre écran d’accueil ne permet pas l’ajout direct : ajoutez le widget MusicStream depuis la liste des widgets.';

  @override
  String get httpAddress => 'Adresse HTTPS ou HTTP';

  @override
  String get identifiedDownloads => 'Téléchargements identifiés';

  @override
  String get importAction => 'Importer';

  @override
  String importAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count morceaux ajoutés',
      one: '$count morceau ajouté',
    );
    return '$_temp0';
  }

  @override
  String get importChooseFiles => 'Choisir des fichiers';

  @override
  String get importChooseFilesHint => 'Sélectionner un ou plusieurs morceaux';

  @override
  String get importChooseFolder => 'Choisir un dossier';

  @override
  String get importChooseFolderHint =>
      'Importer récursivement tous les morceaux du dossier';

  @override
  String get importFailed => 'Import impossible. Réessayez.';

  @override
  String importFailures(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count échecs',
      one: '$count échec',
    );
    return '$_temp0';
  }

  @override
  String get importJsonFile => 'Importer un fichier JSON';

  @override
  String get importLrc => 'Importer .lrc';

  @override
  String importProgress(int completed, int total) {
    return 'Import $completed / $total…';
  }

  @override
  String get importSheetTitle => 'Ajouter de la musique';

  @override
  String importSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count déjà présents',
      one: '$count déjà présent',
    );
    return '$_temp0';
  }

  @override
  String get importTracks => 'Importer des morceaux';

  @override
  String get importTracksFirst =>
      'Importez d’abord des morceaux dans la bibliothèque.';

  @override
  String get importing => 'Import en cours…';

  @override
  String get includeLegacy => 'Inclure les anciens';

  @override
  String get invalidJson => 'Le contenu JSON est invalide.';

  @override
  String get language => 'Langue';

  @override
  String get languageHint => 'Suivre l’appareil ou choisir une langue';

  @override
  String legacyTracksBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count morceaux ajoutés avant cette version n’indiquent pas leur origine.',
      one:
          '$count morceau ajouté avant cette version n’indique pas son origine.',
    );
    return '$_temp0 Ne les incluez que si vous savez qu’ils viennent tous du serveur : un ancien import local serait aussi supprimé.';
  }

  @override
  String get legacyTracksTitle => 'Anciens morceaux';

  @override
  String get libraryUpToDate => 'Bibliothèque à jour';

  @override
  String get localByDefault => 'Local par défaut';

  @override
  String get localByDefaultHint =>
      'Aucun fichier, chemin local ou secret envoyé';

  @override
  String get lyrics => 'Paroles';

  @override
  String get lyricsAutoBody =>
      'Pour les morceaux sans paroles enregistrées, MusicStream enverra son titre, son artiste, son album et sa durée à LRCLIB dès leur lecture. Ce choix reste modifiable dans Réglages.';

  @override
  String get lyricsAutoTitle => 'Trouver les paroles automatiquement ?';

  @override
  String get lyricsEmpty =>
      'Aucune parole trouvée. Importez un fichier .lrc ou relancez la recherche.';

  @override
  String get lyricsImportEmpty => 'Le fichier de paroles est vide.';

  @override
  String get lyricsImportFailed => 'Impossible d’importer ce fichier .lrc.';

  @override
  String get lyricsMissingMetadata =>
      'Le titre et l’artiste sont nécessaires pour chercher des paroles.';

  @override
  String get lyricsNotFoundOnline => 'Aucune parole trouvée sur LRCLIB.';

  @override
  String lyricsOf(String title) {
    return 'Paroles de $title';
  }

  @override
  String get lyricsPrivacyHint =>
      'La recherche envoie le titre, l’artiste, l’album et la durée à LRCLIB.';

  @override
  String lyricsRateLimitAfter(String time) {
    return 'LRCLIB limite les demandes. Réessayez après $time.';
  }

  @override
  String get lyricsRateLimitLater =>
      'LRCLIB limite temporairement les demandes. Réessayez plus tard.';

  @override
  String lyricsRateLimitSeconds(int seconds) {
    return 'LRCLIB limite les demandes. Réessayez dans $seconds secondes.';
  }

  @override
  String get lyricsReadFailed => 'Impossible de lire les paroles enregistrées.';

  @override
  String get lyricsSearchFailed =>
      'Recherche impossible. Vérifiez la connexion et réessayez.';

  @override
  String get lyricsSynchronized =>
      'Synchronisées avec la lecture • touchez une ligne pour avancer';

  @override
  String get lyricsUnsynchronized => 'Paroles non synchronisées';

  @override
  String get modeAlbums => 'Albums';

  @override
  String get modeArtists => 'Artistes';

  @override
  String get modeGenres => 'Genres';

  @override
  String get modeHistory => 'Historique';

  @override
  String get modePlaylists => 'Playlists';

  @override
  String get modeTracks => 'Morceaux';

  @override
  String get moreActions => 'Plus d’actions';

  @override
  String get name => 'Nom';

  @override
  String get navLibrary => 'Bibliothèque';

  @override
  String get navPlayer => 'Lecture';

  @override
  String get navServers => 'Serveurs';

  @override
  String get navSettings => 'Réglages';

  @override
  String get newAlbums => 'Nouveaux albums';

  @override
  String get newPlaylist => 'Nouvelle playlist';

  @override
  String newTracksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nouveaux morceaux :',
      one: '$count nouveau morceau :',
    );
    return '$_temp0';
  }

  @override
  String get noCompatibleTracks => 'Aucun morceau compatible dans ce dossier.';

  @override
  String get noDownloads => 'Aucun téléchargement.';

  @override
  String get noFilterMatch => 'Aucun élément ne correspond au filtre.';

  @override
  String noNewTracks(int count) {
    return 'Aucun nouveau morceau parmi les $count éléments analysés.';
  }

  @override
  String get noResults => 'Aucun résultat';

  @override
  String get noResultsHint =>
      'Essayez un autre titre, artiste, album ou genre.';

  @override
  String get notNow => 'Pas maintenant';

  @override
  String get nothingNewToDownload => 'Aucun nouveau téléchargement à ajouter.';

  @override
  String get nothingPlaying => 'Aucun morceau en lecture.';

  @override
  String notificationCompleteBody(String finished) {
    return '$finished morceau(x) disponible(s) hors ligne';
  }

  @override
  String get notificationCompleteTitle => 'Téléchargement terminé';

  @override
  String notificationErrorBody(String failed, String total) {
    return '$failed échec(s) sur $total';
  }

  @override
  String get notificationErrorTitle => 'Téléchargement incomplet';

  @override
  String get notificationPausedTitle => 'Téléchargement en pause';

  @override
  String get notificationRunningTitle => 'Téléchargement de musique';

  @override
  String get nowPlayingLabel => 'EN COURS DE LECTURE';

  @override
  String offlineCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count morceaux disponibles hors connexion',
      one: '$count morceau disponible hors connexion',
    );
    return '$_temp0';
  }

  @override
  String get onPhone => 'Sur le téléphone';

  @override
  String get openSettings => 'Réglages';

  @override
  String get original => 'Original';

  @override
  String partlyOnPhone(int available, int total) {
    return '$available/$total sur le téléphone';
  }

  @override
  String get password => 'Mot de passe';

  @override
  String get pasteConfiguration => 'Coller une configuration';

  @override
  String get pasteJson => 'Coller le contenu JSON';

  @override
  String get pause => 'Mettre en pause';

  @override
  String get personalServers => 'Serveurs personnels';

  @override
  String get personalServersHint =>
      'WebDAV et HTTP, avec identifiants dans le coffre système';

  @override
  String get pickMusicFolder => 'Choisir un dossier de musique';

  @override
  String get playAll => 'Tout lire';

  @override
  String get playCollection => 'Lire la collection';

  @override
  String get playFolder => 'Lire le dossier';

  @override
  String get playNext => 'Lire ensuite';

  @override
  String get playThisFolder => 'Lire ce dossier';

  @override
  String get playingNext => 'Lecture suivante.';

  @override
  String playlistCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count playlists',
      one: '$count playlist',
    );
    return '$_temp0';
  }

  @override
  String get playlistTracks => 'Morceaux de la playlist';

  @override
  String get preparingPlayback => 'Préparation de la lecture…';

  @override
  String queueButton(int count) {
    return 'File de lecture ($count)';
  }

  @override
  String queuedForDownload(String name) {
    return '$name ajouté aux téléchargements en arrière-plan.';
  }

  @override
  String queueingTracks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ajout de $count morceaux à la file…',
      one: 'Ajout de $count morceau à la file…',
    );
    return '$_temp0';
  }

  @override
  String get recentSearches => 'Recherches récentes';

  @override
  String get recentlyAdded => 'Ajoutés récemment';

  @override
  String get recentlyPlayed => 'Écoutés récemment';

  @override
  String get removeFavorite => 'Retirer des favoris';

  @override
  String get removeFromPlaylist => 'Retirer de la playlist';

  @override
  String get removeFromQueue => 'Retirer de la file';

  @override
  String get removedFromPlaylist => 'Retiré de la playlist.';

  @override
  String get reorder => 'Réorganiser l’ordre';

  @override
  String get reorderHint => 'Faites glisser les poignées pour changer l’ordre.';

  @override
  String get repeatOff => 'Désactiver la répétition';

  @override
  String get repeatQueue => 'Répéter la file';

  @override
  String get repeatTrack => 'Répéter ce morceau';

  @override
  String get resume => 'Reprendre';

  @override
  String get retry => 'Réessayer';

  @override
  String get retryFailed => 'Réessayer les échecs';

  @override
  String get save => 'Enregistrer';

  @override
  String get scanFailed => 'Impossible d’analyser ce serveur pour le moment.';

  @override
  String get scanNewAlbums => 'Rechercher de nouveaux albums';

  @override
  String get scanningFolder => 'Analyse du dossier…';

  @override
  String get searchAgain => 'Relancer la recherche';

  @override
  String get searchHint => 'Rechercher dans votre musique';

  @override
  String get sectionAppearance => 'APPARENCE';

  @override
  String get sectionConnections => 'CONNEXIONS';

  @override
  String get sectionLibrary => 'BIBLIOTHÈQUE';

  @override
  String get sectionPlayback => 'LECTURE';

  @override
  String get sectionPrivacy => 'CONFIDENTIALITÉ';

  @override
  String get selectAll => 'Tout sélectionner';

  @override
  String selectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sélectionnés',
      one: '$count sélectionné',
    );
    return '$_temp0';
  }

  @override
  String get serverAlreadyConfigured => 'Ce serveur est déjà configuré.';

  @override
  String get serverConnectionFailed =>
      'Connexion impossible. Vérifiez l’adresse et les identifiants.';

  @override
  String get serverRoot => 'Racine du serveur';

  @override
  String get serversHeadline => 'Votre musique,\noù qu’elle vive.';

  @override
  String serversImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count serveurs importés.',
      one: '$count serveur importé.',
    );
    return '$_temp0';
  }

  @override
  String get settingsHeadline => 'À votre rythme.';

  @override
  String get settingsTagline =>
      'Une bibliothèque privée, locale et prête à vous suivre.';

  @override
  String get settingsTitle => 'Réglages';

  @override
  String get showAll => 'Afficher tout';

  @override
  String get showPassphrase => 'Afficher la phrase secrète';

  @override
  String get showVisualizer => 'Afficher les ondes du son';

  @override
  String get shuffle => 'Aléatoire';

  @override
  String get shuffleDisable => 'Désactiver la lecture aléatoire';

  @override
  String get shuffleEnable => 'Activer la lecture aléatoire';

  @override
  String get shufflePlay => 'Lecture aléatoire';

  @override
  String sizeKilobytes(String size) {
    return '$size Ko';
  }

  @override
  String sizeMegabytes(String size) {
    return '$size Mo';
  }

  @override
  String get sleepTimer => 'Minuterie de sommeil';

  @override
  String get sleepTimerAtTrackEnd => 'Pause à la fin du morceau';

  @override
  String get sleepTimerEndOfTrack => 'À la fin du morceau';

  @override
  String sleepTimerMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get sleepTimerOff => 'Désactivée';

  @override
  String sleepTimerRemaining(String time) {
    return 'Pause dans $time';
  }

  @override
  String get sortAlbum => 'Album';

  @override
  String get sortArtist => 'Artiste';

  @override
  String sortBy(String sort) {
    return 'Trier par $sort';
  }

  @override
  String get sortRecent => 'Ajout récent';

  @override
  String get sortTitle => 'Titre';

  @override
  String sourceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sources',
      one: '$count source',
    );
    return '$_temp0';
  }

  @override
  String get stageFtp => 'le transfert FTP';

  @override
  String get stageInventory => 'l’inventaire';

  @override
  String get stageQueue => 'la mise en file';

  @override
  String get statusCanceled => 'Annulé';

  @override
  String get statusComplete => 'Disponible hors ligne';

  @override
  String get statusEnqueued => 'En attente';

  @override
  String get statusFailed => 'Échec du téléchargement';

  @override
  String statusFailedWithReason(String reason) {
    return 'Échec : $reason';
  }

  @override
  String get statusNotFound => 'Fichier introuvable';

  @override
  String get statusPaused => 'En pause';

  @override
  String get statusRunning => 'Téléchargement en cours';

  @override
  String get statusWaitingToRetry => 'Nouvelle tentative en attente';

  @override
  String get streamFailed => 'Lecture depuis le serveur impossible.';

  @override
  String get streamFromServer => 'Écouter depuis le serveur';

  @override
  String get supportedFormats => 'MP3, M4A, M4B, AAC, FLAC, OGG, OPUS et WAV';

  @override
  String get syncActive => 'Active';

  @override
  String get syncAuthEmailInUse => 'Un compte existe déjà avec cette adresse.';

  @override
  String get syncAuthFailed => 'Connexion impossible.';

  @override
  String get syncAuthInvalidCredentials => 'E-mail ou mot de passe incorrect.';

  @override
  String get syncAuthInvalidEmail => 'Adresse e-mail invalide.';

  @override
  String get syncAuthNetwork => 'Pas de connexion réseau.';

  @override
  String get syncAuthTooManyRequests =>
      'Trop de tentatives. Réessayez plus tard.';

  @override
  String get syncAuthWeakPassword =>
      'Mot de passe trop faible (6 caractères minimum).';

  @override
  String get syncConflict =>
      'Un autre appareil synchronise en même temps. Réessayez.';

  @override
  String get syncCreateAccount => 'Créer un compte';

  @override
  String get syncDisable => 'Désactiver sur cet appareil';

  @override
  String get syncDone => 'Synchronisation terminée.';

  @override
  String get syncEmail => 'Adresse e-mail';

  @override
  String get syncEnable => 'Activer et synchroniser';

  @override
  String get syncExistingPassphraseStep =>
      'Entrez la phrase secrète déjà utilisée sur vos autres appareils pour déchiffrer les données de ce compte.';

  @override
  String get syncExplanation =>
      'Favoris, écoutes, playlists et serveurs (avec leurs mots de passe) sont chiffrés sur cet appareil avec votre phrase secrète, puis enregistrés sur votre compte MusicStream. Le serveur ne voit jamais leur contenu, et vos fichiers audio ne sont jamais envoyés.';

  @override
  String get syncFailed =>
      'Synchronisation impossible. Vérifiez votre connexion.';

  @override
  String get syncForgotPassword => 'Mot de passe oublié ?';

  @override
  String get syncHistoryEmpty => 'Aucune synchronisation enregistrée.';

  @override
  String syncHistoryFavorites(int count) {
    return 'Favoris modifiés : $count';
  }

  @override
  String get syncHistoryNoChanges => 'Aucune modification';

  @override
  String syncHistoryPlays(int count) {
    return 'Historique d’écoute modifié : $count';
  }

  @override
  String get syncHistoryPlaylists => 'Playlists modifiées';

  @override
  String syncHistoryPositionDownloaded(String title, String position) {
    return 'Position reçue : $title — $position';
  }

  @override
  String syncHistoryPositionUploaded(String title, String position) {
    return 'Position envoyée : $title — $position';
  }

  @override
  String get syncHistoryServers => 'Serveurs modifiés';

  @override
  String get syncHistoryTitle => 'Synchronisations récentes';

  @override
  String syncLastRun(String date) {
    return 'Dernière synchronisation : $date';
  }

  @override
  String get syncNever => 'Jamais synchronisé';

  @override
  String get syncNow => 'Synchroniser maintenant';

  @override
  String get syncOr => 'ou';

  @override
  String get syncPassphrase => 'Phrase secrète';

  @override
  String get syncPassphraseConfirm => 'Confirmer la phrase secrète';

  @override
  String get syncPassphraseHint =>
      'Au moins 8 caractères. Utilisez la même sur chaque appareil : elle ne peut pas être récupérée.';

  @override
  String get syncPassphraseMismatch =>
      'Les deux phrases secrètes ne correspondent pas.';

  @override
  String get syncPassphraseStep =>
      'Choisissez la phrase secrète qui chiffre vos données. Elle est distincte du mot de passe du compte et sert sur chaque appareil.';

  @override
  String get syncPassphraseTooShort => 'Utilisez au moins 8 caractères.';

  @override
  String get syncPassword => 'Mot de passe';

  @override
  String get syncResetSent => 'E-mail de réinitialisation envoyé.';

  @override
  String get syncSignIn => 'Se connecter';

  @override
  String get syncSignInGoogle => 'Continuer avec Google';

  @override
  String get syncSignOut => 'Se déconnecter';

  @override
  String syncSignedInAs(String account) {
    return 'Connecté : $account';
  }

  @override
  String get syncTitle => 'Synchronisation chiffrée';

  @override
  String get syncUnlock => 'Déchiffrer et synchroniser';

  @override
  String get syncUnavailable =>
      'La synchronisation n’est pas configurée dans cette version de l’application.';

  @override
  String get syncWrongPassphrase =>
      'Cette phrase secrète n’ouvre pas les données synchronisées de ce compte.';

  @override
  String get theme => 'Thème';

  @override
  String get themeDark => 'Sombre';

  @override
  String get themeHint => 'Suivre l’appareil ou imposer un mode';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeSystem => 'Système';

  @override
  String trackCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count morceaux',
      one: '$count morceau',
    );
    return '$_temp0';
  }

  @override
  String get trackOptions => 'Options du morceau';

  @override
  String tracksSortedBy(String tracks, String sort) {
    return '$tracks · $sort';
  }

  @override
  String get translate => 'Traduire';

  @override
  String get translateLyricsHint =>
      'Les paroles seront envoyées à MyMemory. La traduction sera gardée sur cet appareil.';

  @override
  String get translateLyricsTitle => 'Traduire les paroles';

  @override
  String get translationFailed =>
      'Traduction impossible. Vérifiez la connexion et réessayez.';

  @override
  String translationLanguage(String language) {
    return 'Traduction : $language';
  }

  @override
  String get translationLineTooLong => 'Une ligne est trop longue à traduire.';

  @override
  String get translationRateLimited =>
      'MyMemory limite temporairement les traductions. Réessayez plus tard.';

  @override
  String get translationUnavailable =>
      'Traduction impossible (réseau ou service indisponible).';

  @override
  String get undo => 'Annuler';

  @override
  String get unknownAlbum => 'Album inconnu';

  @override
  String get unknownArtist => 'Artiste inconnu';

  @override
  String get unknownGenre => 'Genre inconnu';

  @override
  String get untitledTrack => 'Piste sans titre';

  @override
  String get upNext => 'À suivre';

  @override
  String get usernameOptional => 'Utilisateur (facultatif)';

  @override
  String volumePercent(int percent) {
    return '$percent %';
  }

  @override
  String get widgetIdle => 'Aucun morceau en lecture';

  @override
  String get yourFavorites => 'Vos favoris';

  @override
  String get yourLibrary => 'VOTRE BIBLIOTHÈQUE';

  @override
  String get yourPlaylists => 'Vos playlists';

  @override
  String get yourSources => 'VOS SOURCES';

  @override
  String get serverNameRequired => 'Saisissez un nom pour ce serveur';

  @override
  String get serverAddressInvalidHttp =>
      'Saisissez une adresse commençant par http:// ou https://, sans utilisateur ni mot de passe';

  @override
  String get serverAddressInvalidFtp =>
      'Saisissez une adresse commençant par ftp://, sans utilisateur ni mot de passe';

  @override
  String get showPassword => 'Afficher le mot de passe';

  @override
  String get hidePassword => 'Masquer le mot de passe';

  @override
  String get testingConnection => 'Test de la connexion…';

  @override
  String get connectionTestFailed =>
      'Serveur injoignable. Vérifiez l’adresse et les identifiants, ou enregistrez quand même.';

  @override
  String connectionTestFailedStatus(int status) {
    return 'Le serveur a répondu HTTP $status. Vérifiez l’adresse et les identifiants, ou enregistrez quand même.';
  }

  @override
  String get saveAnyway => 'Enregistrer quand même';

  @override
  String get updateAvailableTitle => 'Mise à jour disponible';

  @override
  String get updateAvailableBody =>
      'Une nouvelle version de MusicStream est disponible sur Google Play. Mettez à jour pour profiter des dernières corrections et nouveautés.';

  @override
  String get updateAction => 'Mettre à jour';

  @override
  String get updateLater => 'Plus tard';

  @override
  String get addServerHint =>
      'Connectez un serveur WebDAV, HTTP ou FTP. La connexion est testée avant l’enregistrement.';

  @override
  String get saveAndTest => 'Tester et enregistrer';

  @override
  String unsupportedFlac(String title) {
    return 'FLAC non lisible sur cet appareil : « $title » a été mis en pause. Essayez un fichier MP3, AAC ou Opus.';
  }

  @override
  String get modeAudiobooks => 'Livres audio';

  @override
  String get chapters => 'Chapitres';

  @override
  String chapterDefault(int number) {
    return 'Chapitre $number';
  }

  @override
  String get rewind30 => 'Reculer de 30 secondes';

  @override
  String get forward30 => 'Avancer de 30 secondes';

  @override
  String get playbackSpeed => 'Vitesse de lecture';

  @override
  String get audiobooksEmpty =>
      'Aucun livre audio. Les fichiers M4B et les genres « Audiobook » apparaissent ici.';

  @override
  String get syncPositionTitle => 'Progression trouvée sur un autre appareil';

  @override
  String syncPositionBody(String title) {
    return '« $title » a une autre position dans la synchronisation.';
  }

  @override
  String syncPositionRemote(String position, String date) {
    return 'Synchronisation : $position\n$date';
  }

  @override
  String syncPositionLocal(String position, String date) {
    return 'Cet appareil : $position\n$date';
  }

  @override
  String get syncPositionNoDate => 'date inconnue';

  @override
  String get syncPositionIgnore => 'Ignorer';

  @override
  String get syncPositionKeepLocal => 'Garder ici';

  @override
  String get syncPositionUseRemote => 'Reprendre depuis la synchro';

  @override
  String chapterPosition(int number, int total) {
    return 'Chapitre $number/$total';
  }

  @override
  String audiobookOverall(int percent, String remaining) {
    return '$percent % du livre · $remaining restantes';
  }

  @override
  String get previousChapter => 'Chapitre précédent';

  @override
  String get nextChapter => 'Chapitre suivant';

  @override
  String get sleepTimerEndOfChapter => 'Fin du chapitre';

  @override
  String get sleepTimerEndOfBook => 'Fin du livre';
}

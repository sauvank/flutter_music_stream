import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr')
  ];

  /// No description provided for @actionNext.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get actionNext;

  /// No description provided for @actionPause.
  ///
  /// In fr, this message translates to:
  /// **'Pause'**
  String get actionPause;

  /// No description provided for @actionPlay.
  ///
  /// In fr, this message translates to:
  /// **'Lire'**
  String get actionPlay;

  /// No description provided for @actionPrevious.
  ///
  /// In fr, this message translates to:
  /// **'Précédent'**
  String get actionPrevious;

  /// No description provided for @addFavorite.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter aux favoris'**
  String get addFavorite;

  /// No description provided for @addMyMusic.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter ma musique'**
  String get addMyMusic;

  /// No description provided for @addServer.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un serveur'**
  String get addServer;

  /// No description provided for @addToPlaylist.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter à une playlist'**
  String get addToPlaylist;

  /// No description provided for @addToQueue.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter à la file'**
  String get addToQueue;

  /// No description provided for @addTrackTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter « {title} »'**
  String addTrackTitle(String title);

  /// No description provided for @addTracks.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter des morceaux'**
  String get addTracks;

  /// No description provided for @addTracksTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter {tracks}'**
  String addTracksTitle(String tracks);

  /// No description provided for @addedCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} ajouté} other{{count} ajoutés}}'**
  String addedCount(int count);

  /// No description provided for @addedToPlaylist.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} morceau ajouté à « {playlist} ».} other{{count} morceaux ajoutés à « {playlist} ».}}'**
  String addedToPlaylist(int count, String playlist);

  /// No description provided for @addedToQueue.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{Ajouté à la file.} other{Ajoutés à la file.}}'**
  String addedToQueue(int count);

  /// No description provided for @allOnPhone.
  ///
  /// In fr, this message translates to:
  /// **'Tout sur le téléphone'**
  String get allOnPhone;

  /// No description provided for @allTracks.
  ///
  /// In fr, this message translates to:
  /// **'Tous les morceaux'**
  String get allTracks;

  /// No description provided for @alreadyDownloading.
  ///
  /// In fr, this message translates to:
  /// **'{name} est déjà en cours de téléchargement.'**
  String alreadyDownloading(String name);

  /// No description provided for @audioChannelName.
  ///
  /// In fr, this message translates to:
  /// **'Lecture audio'**
  String get audioChannelName;

  /// No description provided for @audioPermissionDenied.
  ///
  /// In fr, this message translates to:
  /// **'MusicStream a besoin d’accéder à vos fichiers audio pour importer un dossier.'**
  String get audioPermissionDenied;

  /// No description provided for @automaticLyrics.
  ///
  /// In fr, this message translates to:
  /// **'Paroles automatiques'**
  String get automaticLyrics;

  /// No description provided for @automaticLyricsHint.
  ///
  /// In fr, this message translates to:
  /// **'Pendant la lecture, envoie les métadonnées du morceau à LRCLIB si ses paroles ne sont pas déjà enregistrées.'**
  String get automaticLyricsHint;

  /// No description provided for @availableOffline.
  ///
  /// In fr, this message translates to:
  /// **'Disponible hors connexion'**
  String get availableOffline;

  /// No description provided for @availableOfflineHint.
  ///
  /// In fr, this message translates to:
  /// **'Vos morceaux restent dans le stockage privé de l’app'**
  String get availableOfflineHint;

  /// No description provided for @baselineBody.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} morceau mémorisé.} other{{count} morceaux mémorisés.}} Les prochains scans signaleront uniquement les nouveautés.'**
  String baselineBody(int count);

  /// No description provided for @baselineCreated.
  ///
  /// In fr, this message translates to:
  /// **'Référence créée'**
  String get baselineCreated;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @cancelAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout annuler'**
  String get cancelAll;

  /// No description provided for @cancelAllBody.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} téléchargement en cours ou en attente sera annulé.} other{{count} téléchargements en cours ou en attente seront annulés.}} Les morceaux déjà importés sont conservés.'**
  String cancelAllBody(int count);

  /// No description provided for @cancelAllTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tout annuler ?'**
  String get cancelAllTitle;

  /// No description provided for @chooseJsonFile.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un fichier JSON'**
  String get chooseJsonFile;

  /// No description provided for @clearFilter.
  ///
  /// In fr, this message translates to:
  /// **'Effacer le filtre'**
  String get clearFilter;

  /// No description provided for @clearFinished.
  ///
  /// In fr, this message translates to:
  /// **'Effacer les terminés'**
  String get clearFinished;

  /// No description provided for @clearSelection.
  ///
  /// In fr, this message translates to:
  /// **'Annuler la sélection'**
  String get clearSelection;

  /// No description provided for @close.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get close;

  /// No description provided for @collectionCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} collection} other{{count} collections}}'**
  String collectionCount(int count);

  /// No description provided for @comingSoon.
  ///
  /// In fr, this message translates to:
  /// **'Bientôt'**
  String get comingSoon;

  /// No description provided for @connectCollectionBody.
  ///
  /// In fr, this message translates to:
  /// **'Parcourez un serveur WebDAV, HTTP ou FTP, puis gardez vos morceaux préférés hors connexion.'**
  String get connectCollectionBody;

  /// No description provided for @connectCollectionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Connectez votre\ncollection'**
  String get connectCollectionTitle;

  /// No description provided for @continueAction.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get continueAction;

  /// No description provided for @continueInBackground.
  ///
  /// In fr, this message translates to:
  /// **'Continuer en arrière-plan'**
  String get continueInBackground;

  /// No description provided for @create.
  ///
  /// In fr, this message translates to:
  /// **'Créer'**
  String get create;

  /// No description provided for @createPlaylist.
  ///
  /// In fr, this message translates to:
  /// **'Créer une playlist'**
  String get createPlaylist;

  /// No description provided for @delete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get delete;

  /// No description provided for @deleteDownloadsBody.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{Le morceau sélectionné sera supprimé de MusicStream sur ce téléphone.} other{Les {count} morceaux sélectionnés seront supprimés de MusicStream sur ce téléphone.}}'**
  String deleteDownloadsBody(int count);

  /// No description provided for @deleteDownloadsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer les téléchargements ?'**
  String get deleteDownloadsTitle;

  /// No description provided for @deleteDownloadsTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer les téléchargements du téléphone'**
  String get deleteDownloadsTooltip;

  /// No description provided for @deleteFailed.
  ///
  /// In fr, this message translates to:
  /// **'Suppression impossible. Réessayez.'**
  String get deleteFailed;

  /// No description provided for @deleteFromPhone.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer du téléphone'**
  String get deleteFromPhone;

  /// No description provided for @deleteIncludesLegacy.
  ///
  /// In fr, this message translates to:
  /// **'Cela inclut les anciens morceaux que vous avez choisis.'**
  String get deleteIncludesLegacy;

  /// No description provided for @deleteKeepsLocal.
  ///
  /// In fr, this message translates to:
  /// **'Les imports locaux sont conservés.'**
  String get deleteKeepsLocal;

  /// No description provided for @deletePlaylistBody.
  ///
  /// In fr, this message translates to:
  /// **'« {name} » sera supprimée. Vos morceaux seront conservés.'**
  String deletePlaylistBody(String name);

  /// No description provided for @deletePlaylistTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la playlist ?'**
  String get deletePlaylistTitle;

  /// No description provided for @deleteServerBody.
  ///
  /// In fr, this message translates to:
  /// **'« {name} », son mot de passe enregistré et sa référence de nouveaux albums seront supprimés. Les morceaux déjà téléchargés restent dans la bibliothèque.'**
  String deleteServerBody(String name);

  /// No description provided for @deleteServerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce serveur ?'**
  String get deleteServerTitle;

  /// No description provided for @deleteTracksBody.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{Le morceau et ses fichiers associés seront supprimés de MusicStream sur ce téléphone. Le fichier d’origine est conservé.} other{Les morceaux et leurs fichiers associés seront supprimés de MusicStream sur ce téléphone. Les fichiers d’origine sont conservés.}}'**
  String deleteTracksBody(int count);

  /// No description provided for @deleteTracksTitle.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{Supprimer ce morceau ?} other{Supprimer ces {count} morceaux ?}}'**
  String deleteTracksTitle(int count);

  /// No description provided for @deletedCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} morceau supprimé du téléphone.} other{{count} morceaux supprimés du téléphone.}}'**
  String deletedCount(int count);

  /// No description provided for @description.
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @disconnect.
  ///
  /// In fr, this message translates to:
  /// **'Déconnecter'**
  String get disconnect;

  /// No description provided for @done.
  ///
  /// In fr, this message translates to:
  /// **'Terminer'**
  String get done;

  /// No description provided for @download.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger'**
  String get download;

  /// No description provided for @downloadFailed.
  ///
  /// In fr, this message translates to:
  /// **'Téléchargement impossible.'**
  String get downloadFailed;

  /// No description provided for @downloadFolder.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger tout le dossier'**
  String get downloadFolder;

  /// No description provided for @downloadProgress.
  ///
  /// In fr, this message translates to:
  /// **'Téléchargement {current} / {total}'**
  String downloadProgress(int current, int total);

  /// No description provided for @downloadTitle.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger « {name} »'**
  String downloadTitle(String name);

  /// No description provided for @downloadingTracks.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{Téléchargement de {count} morceau…} other{Téléchargement de {count} morceaux…}}'**
  String downloadingTracks(int count);

  /// No description provided for @downloads.
  ///
  /// In fr, this message translates to:
  /// **'Téléchargements'**
  String get downloads;

  /// No description provided for @edit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get edit;

  /// No description provided for @editPlaylist.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la playlist'**
  String get editPlaylist;

  /// No description provided for @emptyHeadline.
  ///
  /// In fr, this message translates to:
  /// **'Votre musique mérite\nun bel écrin.'**
  String get emptyHeadline;

  /// No description provided for @emptyHistoryBody.
  ///
  /// In fr, this message translates to:
  /// **'Les morceaux suffisamment écoutés apparaîtront ici.'**
  String get emptyHistoryBody;

  /// No description provided for @emptyHistoryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre historique est encore vide'**
  String get emptyHistoryTitle;

  /// No description provided for @emptyLibraryBody.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez vos morceaux : ils restent privés, disponibles hors connexion et classés automatiquement.'**
  String get emptyLibraryBody;

  /// No description provided for @emptyLibraryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Donnez vie à\nvotre bibliothèque'**
  String get emptyLibraryTitle;

  /// No description provided for @emptyPlayerHint.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez un morceau dans votre bibliothèque pour commencer.'**
  String get emptyPlayerHint;

  /// No description provided for @emptyPlayerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Prêt à vibrer ?'**
  String get emptyPlayerTitle;

  /// No description provided for @emptyPlaylist.
  ///
  /// In fr, this message translates to:
  /// **'Cette playlist est vide'**
  String get emptyPlaylist;

  /// No description provided for @emptyPlaylistsBody.
  ///
  /// In fr, this message translates to:
  /// **'Regroupez vos morceaux pour les retrouver et les lire dans l’ordre.'**
  String get emptyPlaylistsBody;

  /// No description provided for @emptyPlaylistsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Créez votre première playlist'**
  String get emptyPlaylistsTitle;

  /// No description provided for @enable.
  ///
  /// In fr, this message translates to:
  /// **'Activer'**
  String get enable;

  /// No description provided for @encryptedSync.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisation chiffrée'**
  String get encryptedSync;

  /// No description provided for @encryptedSyncHint.
  ///
  /// In fr, this message translates to:
  /// **'Métadonnées uniquement, jamais vos fichiers audio'**
  String get encryptedSyncHint;

  /// No description provided for @enrichLibrary.
  ///
  /// In fr, this message translates to:
  /// **'Enrichir la bibliothèque'**
  String get enrichLibrary;

  /// No description provided for @fadeMilliseconds.
  ///
  /// In fr, this message translates to:
  /// **'{milliseconds} ms'**
  String fadeMilliseconds(int milliseconds);

  /// No description provided for @fadeOff.
  ///
  /// In fr, this message translates to:
  /// **'Non'**
  String get fadeOff;

  /// No description provided for @fadeSecond.
  ///
  /// In fr, this message translates to:
  /// **'1 s'**
  String get fadeSecond;

  /// No description provided for @fades.
  ///
  /// In fr, this message translates to:
  /// **'Fondus de lecture'**
  String get fades;

  /// No description provided for @fadesHint.
  ///
  /// In fr, this message translates to:
  /// **'Adoucit lecture, pause et changements de morceau'**
  String get fadesHint;

  /// No description provided for @favorites.
  ///
  /// In fr, this message translates to:
  /// **'Favoris'**
  String get favorites;

  /// No description provided for @fileReadFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de lire ce fichier.'**
  String get fileReadFailed;

  /// No description provided for @filterFolder.
  ///
  /// In fr, this message translates to:
  /// **'Filtrer ce dossier'**
  String get filterFolder;

  /// No description provided for @folder.
  ///
  /// In fr, this message translates to:
  /// **'Dossier'**
  String get folder;

  /// No description provided for @folderConnectionLost.
  ///
  /// In fr, this message translates to:
  /// **'Connexion interrompue pendant {stage} du dossier.'**
  String folderConnectionLost(String stage);

  /// No description provided for @folderFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de terminer {stage} du dossier.'**
  String folderFailed(String stage);

  /// No description provided for @folderHttpError.
  ///
  /// In fr, this message translates to:
  /// **'Le serveur a renvoyé une erreur HTTP {status} pendant {stage} du dossier.'**
  String folderHttpError(int status, String stage);

  /// No description provided for @folderQueued.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} morceau ajouté.} other{{count} morceaux ajoutés.}} Vous pouvez fermer cette fenêtre : le téléchargement continue en arrière-plan.'**
  String folderQueued(int count);

  /// No description provided for @folderReadFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de lire le contenu du dossier.'**
  String get folderReadFailed;

  /// No description provided for @folderTooLarge.
  ///
  /// In fr, this message translates to:
  /// **'Le dossier contient trop de morceaux.'**
  String get folderTooLarge;

  /// No description provided for @ftpAddress.
  ///
  /// In fr, this message translates to:
  /// **'Adresse FTP'**
  String get ftpAddress;

  /// No description provided for @ftpUnencrypted.
  ///
  /// In fr, this message translates to:
  /// **'FTP transmet les identifiants et les fichiers sans chiffrement.'**
  String get ftpUnencrypted;

  /// No description provided for @goodAfternoon.
  ///
  /// In fr, this message translates to:
  /// **'Bon après-midi'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In fr, this message translates to:
  /// **'Bonsoir'**
  String get goodEvening;

  /// No description provided for @goodMorning.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour'**
  String get goodMorning;

  /// No description provided for @headline.
  ///
  /// In fr, this message translates to:
  /// **'Qu’avez-vous envie\nd’écouter ?'**
  String get headline;

  /// No description provided for @httpAddress.
  ///
  /// In fr, this message translates to:
  /// **'Adresse HTTPS ou HTTP'**
  String get httpAddress;

  /// No description provided for @identifiedDownloads.
  ///
  /// In fr, this message translates to:
  /// **'Téléchargements identifiés'**
  String get identifiedDownloads;

  /// No description provided for @importAction.
  ///
  /// In fr, this message translates to:
  /// **'Importer'**
  String get importAction;

  /// No description provided for @importAdded.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} morceau ajouté} other{{count} morceaux ajoutés}}'**
  String importAdded(int count);

  /// No description provided for @importChooseFiles.
  ///
  /// In fr, this message translates to:
  /// **'Choisir des fichiers'**
  String get importChooseFiles;

  /// No description provided for @importChooseFilesHint.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner un ou plusieurs morceaux'**
  String get importChooseFilesHint;

  /// No description provided for @importChooseFolder.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un dossier'**
  String get importChooseFolder;

  /// No description provided for @importChooseFolderHint.
  ///
  /// In fr, this message translates to:
  /// **'Importer récursivement tous les morceaux du dossier'**
  String get importChooseFolderHint;

  /// No description provided for @importFailed.
  ///
  /// In fr, this message translates to:
  /// **'Import impossible. Réessayez.'**
  String get importFailed;

  /// No description provided for @importFailures.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} échec} other{{count} échecs}}'**
  String importFailures(int count);

  /// No description provided for @importJsonFile.
  ///
  /// In fr, this message translates to:
  /// **'Importer un fichier JSON'**
  String get importJsonFile;

  /// No description provided for @importLrc.
  ///
  /// In fr, this message translates to:
  /// **'Importer .lrc'**
  String get importLrc;

  /// No description provided for @importProgress.
  ///
  /// In fr, this message translates to:
  /// **'Import {completed} / {total}…'**
  String importProgress(int completed, int total);

  /// No description provided for @importSheetTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter de la musique'**
  String get importSheetTitle;

  /// No description provided for @importSkipped.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} déjà présent} other{{count} déjà présents}}'**
  String importSkipped(int count);

  /// No description provided for @importTracks.
  ///
  /// In fr, this message translates to:
  /// **'Importer des morceaux'**
  String get importTracks;

  /// No description provided for @importTracksFirst.
  ///
  /// In fr, this message translates to:
  /// **'Importez d’abord des morceaux dans la bibliothèque.'**
  String get importTracksFirst;

  /// No description provided for @importing.
  ///
  /// In fr, this message translates to:
  /// **'Import en cours…'**
  String get importing;

  /// No description provided for @includeLegacy.
  ///
  /// In fr, this message translates to:
  /// **'Inclure les anciens'**
  String get includeLegacy;

  /// No description provided for @invalidJson.
  ///
  /// In fr, this message translates to:
  /// **'Le contenu JSON est invalide.'**
  String get invalidJson;

  /// No description provided for @language.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get language;

  /// No description provided for @languageHint.
  ///
  /// In fr, this message translates to:
  /// **'Suivre l’appareil ou choisir une langue'**
  String get languageHint;

  /// No description provided for @legacyTracksBody.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} morceau ajouté avant cette version n’indique pas son origine.} other{{count} morceaux ajoutés avant cette version n’indiquent pas leur origine.}} Ne les incluez que si vous savez qu’ils viennent tous du serveur : un ancien import local serait aussi supprimé.'**
  String legacyTracksBody(int count);

  /// No description provided for @legacyTracksTitle.
  ///
  /// In fr, this message translates to:
  /// **'Anciens morceaux'**
  String get legacyTracksTitle;

  /// No description provided for @libraryUpToDate.
  ///
  /// In fr, this message translates to:
  /// **'Bibliothèque à jour'**
  String get libraryUpToDate;

  /// No description provided for @localByDefault.
  ///
  /// In fr, this message translates to:
  /// **'Local par défaut'**
  String get localByDefault;

  /// No description provided for @localByDefaultHint.
  ///
  /// In fr, this message translates to:
  /// **'Aucun fichier, chemin local ou secret envoyé'**
  String get localByDefaultHint;

  /// No description provided for @lyrics.
  ///
  /// In fr, this message translates to:
  /// **'Paroles'**
  String get lyrics;

  /// No description provided for @lyricsAutoBody.
  ///
  /// In fr, this message translates to:
  /// **'Pour les morceaux sans paroles enregistrées, MusicStream enverra son titre, son artiste, son album et sa durée à LRCLIB dès leur lecture. Ce choix reste modifiable dans Réglages.'**
  String get lyricsAutoBody;

  /// No description provided for @lyricsAutoTitle.
  ///
  /// In fr, this message translates to:
  /// **'Trouver les paroles automatiquement ?'**
  String get lyricsAutoTitle;

  /// No description provided for @lyricsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune parole trouvée. Importez un fichier .lrc ou relancez la recherche.'**
  String get lyricsEmpty;

  /// No description provided for @lyricsImportEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Le fichier de paroles est vide.'**
  String get lyricsImportEmpty;

  /// No description provided for @lyricsImportFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d’importer ce fichier .lrc.'**
  String get lyricsImportFailed;

  /// No description provided for @lyricsMissingMetadata.
  ///
  /// In fr, this message translates to:
  /// **'Le titre et l’artiste sont nécessaires pour chercher des paroles.'**
  String get lyricsMissingMetadata;

  /// No description provided for @lyricsNotFoundOnline.
  ///
  /// In fr, this message translates to:
  /// **'Aucune parole trouvée sur LRCLIB.'**
  String get lyricsNotFoundOnline;

  /// No description provided for @lyricsOf.
  ///
  /// In fr, this message translates to:
  /// **'Paroles de {title}'**
  String lyricsOf(String title);

  /// No description provided for @lyricsPrivacyHint.
  ///
  /// In fr, this message translates to:
  /// **'La recherche envoie le titre, l’artiste, l’album et la durée à LRCLIB.'**
  String get lyricsPrivacyHint;

  /// No description provided for @lyricsRateLimitAfter.
  ///
  /// In fr, this message translates to:
  /// **'LRCLIB limite les demandes. Réessayez après {time}.'**
  String lyricsRateLimitAfter(String time);

  /// No description provided for @lyricsRateLimitLater.
  ///
  /// In fr, this message translates to:
  /// **'LRCLIB limite temporairement les demandes. Réessayez plus tard.'**
  String get lyricsRateLimitLater;

  /// No description provided for @lyricsRateLimitSeconds.
  ///
  /// In fr, this message translates to:
  /// **'LRCLIB limite les demandes. Réessayez dans {seconds} secondes.'**
  String lyricsRateLimitSeconds(int seconds);

  /// No description provided for @lyricsReadFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de lire les paroles enregistrées.'**
  String get lyricsReadFailed;

  /// No description provided for @lyricsSearchFailed.
  ///
  /// In fr, this message translates to:
  /// **'Recherche impossible. Vérifiez la connexion et réessayez.'**
  String get lyricsSearchFailed;

  /// No description provided for @lyricsSynchronized.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisées avec la lecture • touchez une ligne pour avancer'**
  String get lyricsSynchronized;

  /// No description provided for @lyricsUnsynchronized.
  ///
  /// In fr, this message translates to:
  /// **'Paroles non synchronisées'**
  String get lyricsUnsynchronized;

  /// No description provided for @modeAlbums.
  ///
  /// In fr, this message translates to:
  /// **'Albums'**
  String get modeAlbums;

  /// No description provided for @modeArtists.
  ///
  /// In fr, this message translates to:
  /// **'Artistes'**
  String get modeArtists;

  /// No description provided for @modeGenres.
  ///
  /// In fr, this message translates to:
  /// **'Genres'**
  String get modeGenres;

  /// No description provided for @modeHistory.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get modeHistory;

  /// No description provided for @modePlaylists.
  ///
  /// In fr, this message translates to:
  /// **'Playlists'**
  String get modePlaylists;

  /// No description provided for @modeTracks.
  ///
  /// In fr, this message translates to:
  /// **'Morceaux'**
  String get modeTracks;

  /// No description provided for @moreActions.
  ///
  /// In fr, this message translates to:
  /// **'Plus d’actions'**
  String get moreActions;

  /// No description provided for @name.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get name;

  /// No description provided for @navLibrary.
  ///
  /// In fr, this message translates to:
  /// **'Bibliothèque'**
  String get navLibrary;

  /// No description provided for @navPlayer.
  ///
  /// In fr, this message translates to:
  /// **'Lecture'**
  String get navPlayer;

  /// No description provided for @navServers.
  ///
  /// In fr, this message translates to:
  /// **'Serveurs'**
  String get navServers;

  /// No description provided for @navSettings.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get navSettings;

  /// No description provided for @newAlbums.
  ///
  /// In fr, this message translates to:
  /// **'Nouveaux albums'**
  String get newAlbums;

  /// No description provided for @newPlaylist.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle playlist'**
  String get newPlaylist;

  /// No description provided for @newTracksCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} nouveau morceau :} other{{count} nouveaux morceaux :}}'**
  String newTracksCount(int count);

  /// No description provided for @noCompatibleTracks.
  ///
  /// In fr, this message translates to:
  /// **'Aucun morceau compatible dans ce dossier.'**
  String get noCompatibleTracks;

  /// No description provided for @noDownloads.
  ///
  /// In fr, this message translates to:
  /// **'Aucun téléchargement.'**
  String get noDownloads;

  /// No description provided for @noFilterMatch.
  ///
  /// In fr, this message translates to:
  /// **'Aucun élément ne correspond au filtre.'**
  String get noFilterMatch;

  /// No description provided for @noNewTracks.
  ///
  /// In fr, this message translates to:
  /// **'Aucun nouveau morceau parmi les {count} éléments analysés.'**
  String noNewTracks(int count);

  /// No description provided for @noResults.
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat'**
  String get noResults;

  /// No description provided for @noResultsHint.
  ///
  /// In fr, this message translates to:
  /// **'Essayez un autre titre, artiste, album ou genre.'**
  String get noResultsHint;

  /// No description provided for @notNow.
  ///
  /// In fr, this message translates to:
  /// **'Pas maintenant'**
  String get notNow;

  /// No description provided for @nothingNewToDownload.
  ///
  /// In fr, this message translates to:
  /// **'Aucun nouveau téléchargement à ajouter.'**
  String get nothingNewToDownload;

  /// No description provided for @nothingPlaying.
  ///
  /// In fr, this message translates to:
  /// **'Aucun morceau en lecture.'**
  String get nothingPlaying;

  /// No description provided for @notificationCompleteBody.
  ///
  /// In fr, this message translates to:
  /// **'{finished} morceau(x) disponible(s) hors ligne'**
  String notificationCompleteBody(String finished);

  /// No description provided for @notificationCompleteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Téléchargement terminé'**
  String get notificationCompleteTitle;

  /// No description provided for @notificationErrorBody.
  ///
  /// In fr, this message translates to:
  /// **'{failed} échec(s) sur {total}'**
  String notificationErrorBody(String failed, String total);

  /// No description provided for @notificationErrorTitle.
  ///
  /// In fr, this message translates to:
  /// **'Téléchargement incomplet'**
  String get notificationErrorTitle;

  /// No description provided for @notificationPausedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Téléchargement en pause'**
  String get notificationPausedTitle;

  /// No description provided for @notificationRunningTitle.
  ///
  /// In fr, this message translates to:
  /// **'Téléchargement de musique'**
  String get notificationRunningTitle;

  /// No description provided for @nowPlayingLabel.
  ///
  /// In fr, this message translates to:
  /// **'EN COURS DE LECTURE'**
  String get nowPlayingLabel;

  /// No description provided for @offlineCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} morceau disponible hors connexion} other{{count} morceaux disponibles hors connexion}}'**
  String offlineCount(int count);

  /// No description provided for @onPhone.
  ///
  /// In fr, this message translates to:
  /// **'Sur le téléphone'**
  String get onPhone;

  /// No description provided for @openSettings.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get openSettings;

  /// No description provided for @original.
  ///
  /// In fr, this message translates to:
  /// **'Original'**
  String get original;

  /// No description provided for @partlyOnPhone.
  ///
  /// In fr, this message translates to:
  /// **'{available}/{total} sur le téléphone'**
  String partlyOnPhone(int available, int total);

  /// No description provided for @password.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get password;

  /// No description provided for @pasteConfiguration.
  ///
  /// In fr, this message translates to:
  /// **'Coller une configuration'**
  String get pasteConfiguration;

  /// No description provided for @pasteJson.
  ///
  /// In fr, this message translates to:
  /// **'Coller le contenu JSON'**
  String get pasteJson;

  /// No description provided for @pause.
  ///
  /// In fr, this message translates to:
  /// **'Mettre en pause'**
  String get pause;

  /// No description provided for @personalServers.
  ///
  /// In fr, this message translates to:
  /// **'Serveurs personnels'**
  String get personalServers;

  /// No description provided for @personalServersHint.
  ///
  /// In fr, this message translates to:
  /// **'WebDAV et HTTP, avec identifiants dans le coffre système'**
  String get personalServersHint;

  /// No description provided for @pickMusicFolder.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un dossier de musique'**
  String get pickMusicFolder;

  /// No description provided for @playAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout lire'**
  String get playAll;

  /// No description provided for @playCollection.
  ///
  /// In fr, this message translates to:
  /// **'Lire la collection'**
  String get playCollection;

  /// No description provided for @playFolder.
  ///
  /// In fr, this message translates to:
  /// **'Lire le dossier'**
  String get playFolder;

  /// No description provided for @playNext.
  ///
  /// In fr, this message translates to:
  /// **'Lire ensuite'**
  String get playNext;

  /// No description provided for @playThisFolder.
  ///
  /// In fr, this message translates to:
  /// **'Lire ce dossier'**
  String get playThisFolder;

  /// No description provided for @playingNext.
  ///
  /// In fr, this message translates to:
  /// **'Lecture suivante.'**
  String get playingNext;

  /// No description provided for @playlistCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} playlist} other{{count} playlists}}'**
  String playlistCount(int count);

  /// No description provided for @playlistTracks.
  ///
  /// In fr, this message translates to:
  /// **'Morceaux de la playlist'**
  String get playlistTracks;

  /// No description provided for @preparingPlayback.
  ///
  /// In fr, this message translates to:
  /// **'Préparation de la lecture…'**
  String get preparingPlayback;

  /// No description provided for @queueButton.
  ///
  /// In fr, this message translates to:
  /// **'File de lecture ({count})'**
  String queueButton(int count);

  /// No description provided for @queuedForDownload.
  ///
  /// In fr, this message translates to:
  /// **'{name} ajouté aux téléchargements en arrière-plan.'**
  String queuedForDownload(String name);

  /// No description provided for @queueingTracks.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{Ajout de {count} morceau à la file…} other{Ajout de {count} morceaux à la file…}}'**
  String queueingTracks(int count);

  /// No description provided for @recentlyAdded.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutés récemment'**
  String get recentlyAdded;

  /// No description provided for @recentlyPlayed.
  ///
  /// In fr, this message translates to:
  /// **'Écoutés récemment'**
  String get recentlyPlayed;

  /// No description provided for @removeFavorite.
  ///
  /// In fr, this message translates to:
  /// **'Retirer des favoris'**
  String get removeFavorite;

  /// No description provided for @removeFromPlaylist.
  ///
  /// In fr, this message translates to:
  /// **'Retirer de la playlist'**
  String get removeFromPlaylist;

  /// No description provided for @removeFromQueue.
  ///
  /// In fr, this message translates to:
  /// **'Retirer de la file'**
  String get removeFromQueue;

  /// No description provided for @reorder.
  ///
  /// In fr, this message translates to:
  /// **'Réorganiser l’ordre'**
  String get reorder;

  /// No description provided for @reorderHint.
  ///
  /// In fr, this message translates to:
  /// **'Faites glisser les poignées pour changer l’ordre.'**
  String get reorderHint;

  /// No description provided for @repeatOff.
  ///
  /// In fr, this message translates to:
  /// **'Désactiver la répétition'**
  String get repeatOff;

  /// No description provided for @repeatQueue.
  ///
  /// In fr, this message translates to:
  /// **'Répéter la file'**
  String get repeatQueue;

  /// No description provided for @repeatTrack.
  ///
  /// In fr, this message translates to:
  /// **'Répéter ce morceau'**
  String get repeatTrack;

  /// No description provided for @resume.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre'**
  String get resume;

  /// No description provided for @retry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;

  /// No description provided for @retryFailed.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer les échecs'**
  String get retryFailed;

  /// No description provided for @save.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get save;

  /// No description provided for @scanFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d’analyser ce serveur pour le moment.'**
  String get scanFailed;

  /// No description provided for @scanNewAlbums.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher de nouveaux albums'**
  String get scanNewAlbums;

  /// No description provided for @scanningFolder.
  ///
  /// In fr, this message translates to:
  /// **'Analyse du dossier…'**
  String get scanningFolder;

  /// No description provided for @searchAgain.
  ///
  /// In fr, this message translates to:
  /// **'Relancer la recherche'**
  String get searchAgain;

  /// No description provided for @searchHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher dans votre musique'**
  String get searchHint;

  /// No description provided for @sectionAppearance.
  ///
  /// In fr, this message translates to:
  /// **'APPARENCE'**
  String get sectionAppearance;

  /// No description provided for @sectionConnections.
  ///
  /// In fr, this message translates to:
  /// **'CONNEXIONS'**
  String get sectionConnections;

  /// No description provided for @sectionPlayback.
  ///
  /// In fr, this message translates to:
  /// **'LECTURE'**
  String get sectionPlayback;

  /// No description provided for @sectionPrivacy.
  ///
  /// In fr, this message translates to:
  /// **'CONFIDENTIALITÉ'**
  String get sectionPrivacy;

  /// No description provided for @selectAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout sélectionner'**
  String get selectAll;

  /// No description provided for @selectedCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} sélectionné} other{{count} sélectionnés}}'**
  String selectedCount(int count);

  /// No description provided for @serverAlreadyConfigured.
  ///
  /// In fr, this message translates to:
  /// **'Ce serveur est déjà configuré.'**
  String get serverAlreadyConfigured;

  /// No description provided for @serverConnectionFailed.
  ///
  /// In fr, this message translates to:
  /// **'Connexion impossible. Vérifiez l’adresse et les identifiants.'**
  String get serverConnectionFailed;

  /// No description provided for @serverRoot.
  ///
  /// In fr, this message translates to:
  /// **'Racine du serveur'**
  String get serverRoot;

  /// No description provided for @serversHeadline.
  ///
  /// In fr, this message translates to:
  /// **'Votre musique,\noù qu’elle vive.'**
  String get serversHeadline;

  /// No description provided for @serversImported.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} serveur importé.} other{{count} serveurs importés.}}'**
  String serversImported(int count);

  /// No description provided for @settingsHeadline.
  ///
  /// In fr, this message translates to:
  /// **'À votre rythme.'**
  String get settingsHeadline;

  /// No description provided for @settingsTagline.
  ///
  /// In fr, this message translates to:
  /// **'Une bibliothèque privée, locale et prête à vous suivre.'**
  String get settingsTagline;

  /// No description provided for @settingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get settingsTitle;

  /// No description provided for @showAll.
  ///
  /// In fr, this message translates to:
  /// **'Afficher tout'**
  String get showAll;

  /// No description provided for @shuffle.
  ///
  /// In fr, this message translates to:
  /// **'Aléatoire'**
  String get shuffle;

  /// No description provided for @shuffleDisable.
  ///
  /// In fr, this message translates to:
  /// **'Désactiver la lecture aléatoire'**
  String get shuffleDisable;

  /// No description provided for @shuffleEnable.
  ///
  /// In fr, this message translates to:
  /// **'Activer la lecture aléatoire'**
  String get shuffleEnable;

  /// No description provided for @shufflePlay.
  ///
  /// In fr, this message translates to:
  /// **'Lecture aléatoire'**
  String get shufflePlay;

  /// No description provided for @sizeKilobytes.
  ///
  /// In fr, this message translates to:
  /// **'{size} Ko'**
  String sizeKilobytes(String size);

  /// No description provided for @sizeMegabytes.
  ///
  /// In fr, this message translates to:
  /// **'{size} Mo'**
  String sizeMegabytes(String size);

  /// No description provided for @sortAlbum.
  ///
  /// In fr, this message translates to:
  /// **'Album'**
  String get sortAlbum;

  /// No description provided for @sortArtist.
  ///
  /// In fr, this message translates to:
  /// **'Artiste'**
  String get sortArtist;

  /// No description provided for @sortBy.
  ///
  /// In fr, this message translates to:
  /// **'Trier par {sort}'**
  String sortBy(String sort);

  /// No description provided for @sortRecent.
  ///
  /// In fr, this message translates to:
  /// **'Ajout récent'**
  String get sortRecent;

  /// No description provided for @sortTitle.
  ///
  /// In fr, this message translates to:
  /// **'Titre'**
  String get sortTitle;

  /// No description provided for @sourceCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} source} other{{count} sources}}'**
  String sourceCount(int count);

  /// No description provided for @stageFtp.
  ///
  /// In fr, this message translates to:
  /// **'le transfert FTP'**
  String get stageFtp;

  /// No description provided for @stageInventory.
  ///
  /// In fr, this message translates to:
  /// **'l’inventaire'**
  String get stageInventory;

  /// No description provided for @stageQueue.
  ///
  /// In fr, this message translates to:
  /// **'la mise en file'**
  String get stageQueue;

  /// No description provided for @statusCanceled.
  ///
  /// In fr, this message translates to:
  /// **'Annulé'**
  String get statusCanceled;

  /// No description provided for @statusComplete.
  ///
  /// In fr, this message translates to:
  /// **'Disponible hors ligne'**
  String get statusComplete;

  /// No description provided for @statusEnqueued.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get statusEnqueued;

  /// No description provided for @statusFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec du téléchargement'**
  String get statusFailed;

  /// No description provided for @statusFailedWithReason.
  ///
  /// In fr, this message translates to:
  /// **'Échec : {reason}'**
  String statusFailedWithReason(String reason);

  /// No description provided for @statusNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Fichier introuvable'**
  String get statusNotFound;

  /// No description provided for @statusPaused.
  ///
  /// In fr, this message translates to:
  /// **'En pause'**
  String get statusPaused;

  /// No description provided for @statusRunning.
  ///
  /// In fr, this message translates to:
  /// **'Téléchargement en cours'**
  String get statusRunning;

  /// No description provided for @statusWaitingToRetry.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle tentative en attente'**
  String get statusWaitingToRetry;

  /// No description provided for @streamFailed.
  ///
  /// In fr, this message translates to:
  /// **'Lecture depuis le serveur impossible.'**
  String get streamFailed;

  /// No description provided for @streamFromServer.
  ///
  /// In fr, this message translates to:
  /// **'Écouter depuis le serveur'**
  String get streamFromServer;

  /// No description provided for @supportedFormats.
  ///
  /// In fr, this message translates to:
  /// **'MP3, M4A, AAC, FLAC, OGG, OPUS et WAV'**
  String get supportedFormats;

  /// No description provided for @theme.
  ///
  /// In fr, this message translates to:
  /// **'Thème'**
  String get theme;

  /// No description provided for @themeDark.
  ///
  /// In fr, this message translates to:
  /// **'Sombre'**
  String get themeDark;

  /// No description provided for @themeHint.
  ///
  /// In fr, this message translates to:
  /// **'Suivre l’appareil ou imposer un mode'**
  String get themeHint;

  /// No description provided for @themeLight.
  ///
  /// In fr, this message translates to:
  /// **'Clair'**
  String get themeLight;

  /// No description provided for @themeSystem.
  ///
  /// In fr, this message translates to:
  /// **'Système'**
  String get themeSystem;

  /// No description provided for @trackCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} morceau} other{{count} morceaux}}'**
  String trackCount(int count);

  /// No description provided for @trackOptions.
  ///
  /// In fr, this message translates to:
  /// **'Options du morceau'**
  String get trackOptions;

  /// No description provided for @tracksSortedBy.
  ///
  /// In fr, this message translates to:
  /// **'{tracks} · {sort}'**
  String tracksSortedBy(String tracks, String sort);

  /// No description provided for @translate.
  ///
  /// In fr, this message translates to:
  /// **'Traduire'**
  String get translate;

  /// No description provided for @translateLyricsHint.
  ///
  /// In fr, this message translates to:
  /// **'Les paroles seront envoyées à MyMemory. La traduction sera gardée sur cet appareil.'**
  String get translateLyricsHint;

  /// No description provided for @translateLyricsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Traduire les paroles'**
  String get translateLyricsTitle;

  /// No description provided for @translationFailed.
  ///
  /// In fr, this message translates to:
  /// **'Traduction impossible. Vérifiez la connexion et réessayez.'**
  String get translationFailed;

  /// No description provided for @translationLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Traduction : {language}'**
  String translationLanguage(String language);

  /// No description provided for @translationLineTooLong.
  ///
  /// In fr, this message translates to:
  /// **'Une ligne est trop longue à traduire.'**
  String get translationLineTooLong;

  /// No description provided for @translationRateLimited.
  ///
  /// In fr, this message translates to:
  /// **'MyMemory limite temporairement les traductions. Réessayez plus tard.'**
  String get translationRateLimited;

  /// No description provided for @translationUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Traduction impossible (réseau ou service indisponible).'**
  String get translationUnavailable;

  /// No description provided for @unknownAlbum.
  ///
  /// In fr, this message translates to:
  /// **'Album inconnu'**
  String get unknownAlbum;

  /// No description provided for @unknownArtist.
  ///
  /// In fr, this message translates to:
  /// **'Artiste inconnu'**
  String get unknownArtist;

  /// No description provided for @unknownGenre.
  ///
  /// In fr, this message translates to:
  /// **'Genre inconnu'**
  String get unknownGenre;

  /// No description provided for @untitledTrack.
  ///
  /// In fr, this message translates to:
  /// **'Piste sans titre'**
  String get untitledTrack;

  /// No description provided for @upNext.
  ///
  /// In fr, this message translates to:
  /// **'À suivre'**
  String get upNext;

  /// No description provided for @usernameOptional.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateur (facultatif)'**
  String get usernameOptional;

  /// No description provided for @volumePercent.
  ///
  /// In fr, this message translates to:
  /// **'{percent} %'**
  String volumePercent(int percent);

  /// No description provided for @yourFavorites.
  ///
  /// In fr, this message translates to:
  /// **'Vos favoris'**
  String get yourFavorites;

  /// No description provided for @yourLibrary.
  ///
  /// In fr, this message translates to:
  /// **'VOTRE BIBLIOTHÈQUE'**
  String get yourLibrary;

  /// No description provided for @yourPlaylists.
  ///
  /// In fr, this message translates to:
  /// **'Vos playlists'**
  String get yourPlaylists;

  /// No description provided for @yourSources.
  ///
  /// In fr, this message translates to:
  /// **'VOS SOURCES'**
  String get yourSources;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}

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

  /// No description provided for @downloadEntireServer.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger tout le serveur'**
  String get downloadEntireServer;

  /// No description provided for @downloadAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout télécharger'**
  String get downloadAll;

  /// No description provided for @downloadPreparing.
  ///
  /// In fr, this message translates to:
  /// **'Préparation de « {name} »… Vous pouvez continuer à naviguer.'**
  String downloadPreparing(String name);

  /// No description provided for @downloadPreparingShort.
  ///
  /// In fr, this message translates to:
  /// **'Préparation des téléchargements…'**
  String get downloadPreparingShort;

  /// No description provided for @downloadPreparationHint.
  ///
  /// In fr, this message translates to:
  /// **'L’analyse continue pendant que vous naviguez. Les fichiers déjà présents seront ignorés.'**
  String get downloadPreparationHint;

  /// No description provided for @downloadFtpHint.
  ///
  /// In fr, this message translates to:
  /// **'Vous pouvez naviguer dans MusicStream. Gardez l’application ouverte pendant les transferts FTP.'**
  String get downloadFtpHint;

  /// No description provided for @downloadWaitingSummary.
  ///
  /// In fr, this message translates to:
  /// **'{waiting} en attente · {paused} en pause'**
  String downloadWaitingSummary(int waiting, int paused);

  /// No description provided for @downloadHttpError.
  ///
  /// In fr, this message translates to:
  /// **'Le serveur a répondu avec une erreur HTTP {code}. Vous pouvez réessayer.'**
  String downloadHttpError(int code);

  /// No description provided for @downloadQueueActive.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} téléchargement en cours} other{{count} téléchargements en cours}}'**
  String downloadQueueActive(int count);

  /// No description provided for @downloadQueueSummary.
  ///
  /// In fr, this message translates to:
  /// **'{finished, plural, one{{finished} terminé} other{{finished} terminés}} · {failed} à réessayer'**
  String downloadQueueSummary(int finished, int failed);

  /// No description provided for @downloadNeedsAttention.
  ///
  /// In fr, this message translates to:
  /// **'Des téléchargements à réessayer'**
  String get downloadNeedsAttention;

  /// No description provided for @downloadManage.
  ///
  /// In fr, this message translates to:
  /// **'Suivre les transferts et gérer l’historique'**
  String get downloadManage;

  /// No description provided for @downloadActionFailed.
  ///
  /// In fr, this message translates to:
  /// **'Action impossible pour le moment. Réessayez dans quelques instants.'**
  String get downloadActionFailed;

  /// No description provided for @downloadBackgroundHint.
  ///
  /// In fr, this message translates to:
  /// **'Vous pouvez fermer cette fenêtre : les téléchargements continuent.'**
  String get downloadBackgroundHint;

  /// No description provided for @downloadQueueActions.
  ///
  /// In fr, this message translates to:
  /// **'Gérer la file'**
  String get downloadQueueActions;

  /// No description provided for @downloadFilterAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout'**
  String get downloadFilterAll;

  /// No description provided for @downloadFilterActive.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get downloadFilterActive;

  /// No description provided for @downloadFilterFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échecs'**
  String get downloadFilterFailed;

  /// No description provided for @downloadFilterFinished.
  ///
  /// In fr, this message translates to:
  /// **'Terminés'**
  String get downloadFilterFinished;

  /// No description provided for @downloadQueueUpToDate.
  ///
  /// In fr, this message translates to:
  /// **'Aucun transfert en attente'**
  String get downloadQueueUpToDate;

  /// No description provided for @downloadClearHistory.
  ///
  /// In fr, this message translates to:
  /// **'Nettoyer l’historique'**
  String get downloadClearHistory;

  /// No description provided for @downloadEmptyFilter.
  ///
  /// In fr, this message translates to:
  /// **'Rien dans cette catégorie'**
  String get downloadEmptyFilter;

  /// No description provided for @downloadEmptyFilterHint.
  ///
  /// In fr, this message translates to:
  /// **'Consultez les autres catégories pour retrouver vos téléchargements.'**
  String get downloadEmptyFilterHint;

  /// No description provided for @downloadEmptyHint.
  ///
  /// In fr, this message translates to:
  /// **'Téléchargez un morceau ou un dossier depuis vos serveurs pour l’écouter hors ligne. Retrouvez ici vos transferts HTTP/WebDAV.'**
  String get downloadEmptyHint;

  /// No description provided for @downloadBrowseServers.
  ///
  /// In fr, this message translates to:
  /// **'Parcourir les serveurs'**
  String get downloadBrowseServers;

  /// No description provided for @downloadShowAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout afficher'**
  String get downloadShowAll;

  /// No description provided for @downloadIndexing.
  ///
  /// In fr, this message translates to:
  /// **'Ajout à la bibliothèque…'**
  String get downloadIndexing;

  /// No description provided for @downloadTransferComplete.
  ///
  /// In fr, this message translates to:
  /// **'Transfert terminé'**
  String get downloadTransferComplete;

  /// No description provided for @downloadMoreActions.
  ///
  /// In fr, this message translates to:
  /// **'Options du téléchargement'**
  String get downloadMoreActions;

  /// No description provided for @downloadMissingHint.
  ///
  /// In fr, this message translates to:
  /// **'Ce fichier n’est plus disponible à cette adresse sur le serveur.'**
  String get downloadMissingHint;

  /// No description provided for @downloadFailedHint.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez votre connexion et l’accès au serveur, puis réessayez.'**
  String get downloadFailedHint;

  /// No description provided for @downloadViewQueue.
  ///
  /// In fr, this message translates to:
  /// **'Voir les téléchargements'**
  String get downloadViewQueue;

  /// No description provided for @downloadHistoryHint.
  ///
  /// In fr, this message translates to:
  /// **'Le nettoyage retire les transferts terminés ou annulés de cette liste. Vos morceaux sont conservés.'**
  String get downloadHistoryHint;

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

  /// No description provided for @audioOutput.
  ///
  /// In fr, this message translates to:
  /// **'Diffuser sur un autre appareil'**
  String get audioOutput;

  /// No description provided for @audioOutputUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d’ouvrir le choix de sortie audio.'**
  String get audioOutputUnavailable;

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

  /// No description provided for @clearRecentSearches.
  ///
  /// In fr, this message translates to:
  /// **'Effacer'**
  String get clearRecentSearches;

  /// No description provided for @clearSearch.
  ///
  /// In fr, this message translates to:
  /// **'Effacer la recherche'**
  String get clearSearch;

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

  /// No description provided for @deviceMedia.
  ///
  /// In fr, this message translates to:
  /// **'Médiathèque de l’appareil'**
  String get deviceMedia;

  /// No description provided for @deviceMediaCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} morceau du téléphone} other{{count} morceaux du téléphone}}'**
  String deviceMediaCount(int count);

  /// No description provided for @deviceMediaHint.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute les morceaux déjà présents sur le téléphone, sans les copier.'**
  String get deviceMediaHint;

  /// No description provided for @deviceMediaPermission.
  ///
  /// In fr, this message translates to:
  /// **'MusicStream a besoin d’accéder à vos fichiers audio pour lire la médiathèque du téléphone.'**
  String get deviceMediaPermission;

  /// No description provided for @deviceMediaRescan.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher à nouveau'**
  String get deviceMediaRescan;

  /// No description provided for @deviceMediaScanning.
  ///
  /// In fr, this message translates to:
  /// **'Recherche des morceaux du téléphone…'**
  String get deviceMediaScanning;

  /// No description provided for @deviceMediaSummary.
  ///
  /// In fr, this message translates to:
  /// **'{added} ajouté(s) · {removed} retiré(s)'**
  String deviceMediaSummary(int added, int removed);

  /// No description provided for @deviceTrackBadge.
  ///
  /// In fr, this message translates to:
  /// **'Sur l’appareil'**
  String get deviceTrackBadge;

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

  /// No description provided for @privacyPolicy.
  ///
  /// In fr, this message translates to:
  /// **'Politique de confidentialité'**
  String get privacyPolicy;

  /// No description provided for @privacyPolicyHint.
  ///
  /// In fr, this message translates to:
  /// **'Découvrez comment MusicStream traite vos données'**
  String get privacyPolicyHint;

  /// No description provided for @pairSignInWithPhone.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter avec le téléphone'**
  String get pairSignInWithPhone;

  /// No description provided for @pairQrTitle.
  ///
  /// In fr, this message translates to:
  /// **'Scannez avec votre téléphone'**
  String get pairQrTitle;

  /// No description provided for @pairQrHint.
  ///
  /// In fr, this message translates to:
  /// **'Sur votre téléphone, ouvrez Réglages → Synchronisation chiffrée → Connecter un ordinateur, puis scannez ce code. Si la synchro est déjà activée sur le téléphone, le PC sera aussi déverrouillé automatiquement.'**
  String get pairQrHint;

  /// No description provided for @pairWaiting.
  ///
  /// In fr, this message translates to:
  /// **'En attente du téléphone…'**
  String get pairWaiting;

  /// No description provided for @pairConnectComputer.
  ///
  /// In fr, this message translates to:
  /// **'Connecter un ordinateur'**
  String get pairConnectComputer;

  /// No description provided for @pairConnectComputerHint.
  ///
  /// In fr, this message translates to:
  /// **'Scannez le QR code affiché sur l’ordinateur. Si la synchro est déverrouillée, sa clé sera transmise chiffrée.'**
  String get pairConnectComputerHint;

  /// No description provided for @pairScanTitle.
  ///
  /// In fr, this message translates to:
  /// **'Scanner le QR code'**
  String get pairScanTitle;

  /// No description provided for @pairConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Connecter cet ordinateur ?'**
  String get pairConfirmTitle;

  /// No description provided for @pairConfirmBody.
  ///
  /// In fr, this message translates to:
  /// **'Il sera connecté à votre compte et, si la synchro est déverrouillée, recevra sa clé chiffrée. Continuez seulement si vous l’avez demandé sur votre propre ordinateur.'**
  String get pairConfirmBody;

  /// No description provided for @pairConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Connecter'**
  String get pairConfirm;

  /// No description provided for @pairDone.
  ///
  /// In fr, this message translates to:
  /// **'Ordinateur connecté.'**
  String get pairDone;

  /// No description provided for @pairGoogleOnly.
  ///
  /// In fr, this message translates to:
  /// **'Disponible uniquement avec un compte connecté via Google.'**
  String get pairGoogleOnly;

  /// No description provided for @pairInvalidCode.
  ///
  /// In fr, this message translates to:
  /// **'Ce code n’est pas un code MusicStream.'**
  String get pairInvalidCode;

  /// No description provided for @pairExpired.
  ///
  /// In fr, this message translates to:
  /// **'Le code a expiré. Réessayez.'**
  String get pairExpired;

  /// No description provided for @pairFailed.
  ///
  /// In fr, this message translates to:
  /// **'La connexion a échoué. Réessayez.'**
  String get pairFailed;

  /// No description provided for @hidePassphrase.
  ///
  /// In fr, this message translates to:
  /// **'Masquer la phrase secrète'**
  String get hidePassphrase;

  /// No description provided for @homeWidget.
  ///
  /// In fr, this message translates to:
  /// **'Widget d’accueil'**
  String get homeWidget;

  /// No description provided for @homeWidgetAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get homeWidgetAdd;

  /// No description provided for @homeWidgetHint.
  ///
  /// In fr, this message translates to:
  /// **'Morceau en cours et commandes de lecture sur l’écran d’accueil.'**
  String get homeWidgetHint;

  /// No description provided for @homeWidgetUnsupported.
  ///
  /// In fr, this message translates to:
  /// **'Votre écran d’accueil ne permet pas l’ajout direct : ajoutez le widget MusicStream depuis la liste des widgets.'**
  String get homeWidgetUnsupported;

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
  /// **'Ajoute tous les morceaux du dossier et de ses sous-dossiers'**
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
  /// **'Essayez un autre titre, artiste ou album.'**
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
  /// **'WebDAV, HTTP et FTP, avec identifiants dans le coffre système'**
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

  /// No description provided for @recentSearches.
  ///
  /// In fr, this message translates to:
  /// **'Recherches récentes'**
  String get recentSearches;

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

  /// No description provided for @removedFromPlaylist.
  ///
  /// In fr, this message translates to:
  /// **'Retiré de la playlist.'**
  String get removedFromPlaylist;

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

  /// No description provided for @sectionLibrary.
  ///
  /// In fr, this message translates to:
  /// **'BIBLIOTHÈQUE'**
  String get sectionLibrary;

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

  /// No description provided for @showPassphrase.
  ///
  /// In fr, this message translates to:
  /// **'Afficher la phrase secrète'**
  String get showPassphrase;

  /// No description provided for @showVisualizer.
  ///
  /// In fr, this message translates to:
  /// **'Afficher les ondes du son'**
  String get showVisualizer;

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

  /// No description provided for @sleepTimer.
  ///
  /// In fr, this message translates to:
  /// **'Minuterie de sommeil'**
  String get sleepTimer;

  /// No description provided for @sleepTimerAtTrackEnd.
  ///
  /// In fr, this message translates to:
  /// **'Pause à la fin du morceau'**
  String get sleepTimerAtTrackEnd;

  /// No description provided for @sleepTimerEndOfTrack.
  ///
  /// In fr, this message translates to:
  /// **'À la fin du morceau'**
  String get sleepTimerEndOfTrack;

  /// No description provided for @sleepTimerMinutes.
  ///
  /// In fr, this message translates to:
  /// **'{minutes} min'**
  String sleepTimerMinutes(int minutes);

  /// No description provided for @sleepTimerOff.
  ///
  /// In fr, this message translates to:
  /// **'Désactivée'**
  String get sleepTimerOff;

  /// No description provided for @sleepTimerRemaining.
  ///
  /// In fr, this message translates to:
  /// **'Pause dans {time}'**
  String sleepTimerRemaining(String time);

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
  /// **'MP3, M4A, M4B, AAC, FLAC, OGG, OPUS et WAV'**
  String get supportedFormats;

  /// No description provided for @syncActive.
  ///
  /// In fr, this message translates to:
  /// **'Active'**
  String get syncActive;

  /// No description provided for @syncAuthEmailInUse.
  ///
  /// In fr, this message translates to:
  /// **'Un compte existe déjà avec cette adresse.'**
  String get syncAuthEmailInUse;

  /// No description provided for @syncAuthFailed.
  ///
  /// In fr, this message translates to:
  /// **'Connexion impossible.'**
  String get syncAuthFailed;

  /// No description provided for @syncAuthInvalidCredentials.
  ///
  /// In fr, this message translates to:
  /// **'E-mail ou mot de passe incorrect.'**
  String get syncAuthInvalidCredentials;

  /// No description provided for @syncAuthInvalidEmail.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail invalide.'**
  String get syncAuthInvalidEmail;

  /// No description provided for @syncAuthNetwork.
  ///
  /// In fr, this message translates to:
  /// **'Pas de connexion réseau.'**
  String get syncAuthNetwork;

  /// No description provided for @syncAuthTooManyRequests.
  ///
  /// In fr, this message translates to:
  /// **'Trop de tentatives. Réessayez plus tard.'**
  String get syncAuthTooManyRequests;

  /// No description provided for @syncAuthWeakPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe trop faible (6 caractères minimum).'**
  String get syncAuthWeakPassword;

  /// No description provided for @syncConflict.
  ///
  /// In fr, this message translates to:
  /// **'Un autre appareil synchronise en même temps. Réessayez.'**
  String get syncConflict;

  /// No description provided for @syncCreateAccount.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get syncCreateAccount;

  /// No description provided for @syncDisable.
  ///
  /// In fr, this message translates to:
  /// **'Désactiver sur cet appareil'**
  String get syncDisable;

  /// No description provided for @syncDone.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisation terminée.'**
  String get syncDone;

  /// No description provided for @syncEmail.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail'**
  String get syncEmail;

  /// No description provided for @syncEnable.
  ///
  /// In fr, this message translates to:
  /// **'Activer et synchroniser'**
  String get syncEnable;

  /// No description provided for @syncExistingPassphraseStep.
  ///
  /// In fr, this message translates to:
  /// **'Entrez la phrase secrète déjà utilisée sur vos autres appareils pour déchiffrer les données de ce compte.'**
  String get syncExistingPassphraseStep;

  /// No description provided for @syncExplanation.
  ///
  /// In fr, this message translates to:
  /// **'Favoris, écoutes, playlists et serveurs (avec leurs mots de passe) sont chiffrés sur cet appareil avec votre phrase secrète, puis enregistrés sur votre compte MusicStream. Le serveur ne voit jamais leur contenu, et vos fichiers audio ne sont jamais envoyés.'**
  String get syncExplanation;

  /// No description provided for @syncFailed.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisation impossible. Vérifiez votre connexion.'**
  String get syncFailed;

  /// No description provided for @syncForgotPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ?'**
  String get syncForgotPassword;

  /// No description provided for @syncHistoryEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune synchronisation enregistrée.'**
  String get syncHistoryEmpty;

  /// No description provided for @syncHistoryFavorites.
  ///
  /// In fr, this message translates to:
  /// **'Favoris modifiés : {count}'**
  String syncHistoryFavorites(int count);

  /// No description provided for @syncHistoryNoChanges.
  ///
  /// In fr, this message translates to:
  /// **'Aucune modification'**
  String get syncHistoryNoChanges;

  /// No description provided for @syncHistoryPlays.
  ///
  /// In fr, this message translates to:
  /// **'Historique d’écoute modifié : {count}'**
  String syncHistoryPlays(int count);

  /// No description provided for @syncHistoryPlaylists.
  ///
  /// In fr, this message translates to:
  /// **'Playlists modifiées'**
  String get syncHistoryPlaylists;

  /// No description provided for @syncHistoryPositionDownloaded.
  ///
  /// In fr, this message translates to:
  /// **'Position reçue : {title} — {position}'**
  String syncHistoryPositionDownloaded(String title, String position);

  /// No description provided for @syncHistoryPositionUploaded.
  ///
  /// In fr, this message translates to:
  /// **'Position envoyée : {title} — {position}'**
  String syncHistoryPositionUploaded(String title, String position);

  /// No description provided for @syncHistoryServers.
  ///
  /// In fr, this message translates to:
  /// **'Serveurs modifiés'**
  String get syncHistoryServers;

  /// No description provided for @syncHistoryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisations récentes'**
  String get syncHistoryTitle;

  /// No description provided for @syncLastRun.
  ///
  /// In fr, this message translates to:
  /// **'Dernière synchronisation : {date}'**
  String syncLastRun(String date);

  /// No description provided for @syncNever.
  ///
  /// In fr, this message translates to:
  /// **'Jamais synchronisé'**
  String get syncNever;

  /// No description provided for @syncNow.
  ///
  /// In fr, this message translates to:
  /// **'Synchroniser maintenant'**
  String get syncNow;

  /// No description provided for @syncOr.
  ///
  /// In fr, this message translates to:
  /// **'ou'**
  String get syncOr;

  /// No description provided for @syncPassphrase.
  ///
  /// In fr, this message translates to:
  /// **'Phrase secrète'**
  String get syncPassphrase;

  /// No description provided for @syncPassphraseConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer la phrase secrète'**
  String get syncPassphraseConfirm;

  /// No description provided for @syncPassphraseHint.
  ///
  /// In fr, this message translates to:
  /// **'Au moins 8 caractères. Utilisez la même sur chaque appareil : elle ne peut pas être récupérée.'**
  String get syncPassphraseHint;

  /// No description provided for @syncPassphraseMismatch.
  ///
  /// In fr, this message translates to:
  /// **'Les deux phrases secrètes ne correspondent pas.'**
  String get syncPassphraseMismatch;

  /// No description provided for @syncPassphraseStep.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez la phrase secrète qui chiffre vos données. Elle est distincte du mot de passe du compte et sert sur chaque appareil.'**
  String get syncPassphraseStep;

  /// No description provided for @syncPassphraseTooShort.
  ///
  /// In fr, this message translates to:
  /// **'Utilisez au moins 8 caractères.'**
  String get syncPassphraseTooShort;

  /// No description provided for @syncPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get syncPassword;

  /// No description provided for @syncResetSent.
  ///
  /// In fr, this message translates to:
  /// **'E-mail de réinitialisation envoyé.'**
  String get syncResetSent;

  /// No description provided for @syncSignIn.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get syncSignIn;

  /// No description provided for @syncSignInGoogle.
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec Google'**
  String get syncSignInGoogle;

  /// No description provided for @syncSignOut.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get syncSignOut;

  /// No description provided for @syncSignedInAs.
  ///
  /// In fr, this message translates to:
  /// **'Connecté : {account}'**
  String syncSignedInAs(String account);

  /// No description provided for @syncTitle.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisation chiffrée'**
  String get syncTitle;

  /// No description provided for @syncUnlock.
  ///
  /// In fr, this message translates to:
  /// **'Déchiffrer et synchroniser'**
  String get syncUnlock;

  /// No description provided for @syncUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'La synchronisation n’est pas configurée dans cette version de l’application.'**
  String get syncUnavailable;

  /// No description provided for @syncWrongPassphrase.
  ///
  /// In fr, this message translates to:
  /// **'Cette phrase secrète n’ouvre pas les données synchronisées de ce compte.'**
  String get syncWrongPassphrase;

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

  /// No description provided for @undo.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get undo;

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

  /// No description provided for @widgetIdle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun morceau en lecture'**
  String get widgetIdle;

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

  /// No description provided for @serverNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez un nom pour ce serveur'**
  String get serverNameRequired;

  /// No description provided for @serverAddressInvalidHttp.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez une adresse commençant par http:// ou https://, sans utilisateur ni mot de passe'**
  String get serverAddressInvalidHttp;

  /// No description provided for @serverAddressInvalidFtp.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez une adresse commençant par ftp://, sans utilisateur ni mot de passe'**
  String get serverAddressInvalidFtp;

  /// No description provided for @showPassword.
  ///
  /// In fr, this message translates to:
  /// **'Afficher le mot de passe'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In fr, this message translates to:
  /// **'Masquer le mot de passe'**
  String get hidePassword;

  /// No description provided for @testingConnection.
  ///
  /// In fr, this message translates to:
  /// **'Test de la connexion…'**
  String get testingConnection;

  /// No description provided for @connectionTestFailed.
  ///
  /// In fr, this message translates to:
  /// **'Serveur injoignable. Vérifiez l’adresse et les identifiants, ou enregistrez quand même.'**
  String get connectionTestFailed;

  /// No description provided for @connectionTestFailedStatus.
  ///
  /// In fr, this message translates to:
  /// **'Le serveur a répondu HTTP {status}. Vérifiez l’adresse et les identifiants, ou enregistrez quand même.'**
  String connectionTestFailedStatus(int status);

  /// No description provided for @saveAnyway.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer quand même'**
  String get saveAnyway;

  /// No description provided for @updateAvailableTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mise à jour disponible'**
  String get updateAvailableTitle;

  /// No description provided for @updateAvailableBody.
  ///
  /// In fr, this message translates to:
  /// **'Une nouvelle version de MusicStream est disponible sur Google Play. Mettez à jour pour profiter des dernières corrections et nouveautés.'**
  String get updateAvailableBody;

  /// No description provided for @updateAction.
  ///
  /// In fr, this message translates to:
  /// **'Mettre à jour'**
  String get updateAction;

  /// No description provided for @updateLater.
  ///
  /// In fr, this message translates to:
  /// **'Plus tard'**
  String get updateLater;

  /// No description provided for @addServerHint.
  ///
  /// In fr, this message translates to:
  /// **'Connectez un serveur WebDAV, HTTP ou FTP. La connexion est testée avant l’enregistrement.'**
  String get addServerHint;

  /// No description provided for @saveAndTest.
  ///
  /// In fr, this message translates to:
  /// **'Tester et enregistrer'**
  String get saveAndTest;

  /// No description provided for @unsupportedFlac.
  ///
  /// In fr, this message translates to:
  /// **'FLAC non lisible sur cet appareil : « {title} » a été mis en pause. Essayez un fichier MP3, AAC ou Opus.'**
  String unsupportedFlac(String title);

  /// No description provided for @modeAudiobooks.
  ///
  /// In fr, this message translates to:
  /// **'Livres audio'**
  String get modeAudiobooks;

  /// No description provided for @chapters.
  ///
  /// In fr, this message translates to:
  /// **'Chapitres'**
  String get chapters;

  /// No description provided for @chapterDefault.
  ///
  /// In fr, this message translates to:
  /// **'Chapitre {number}'**
  String chapterDefault(int number);

  /// No description provided for @rewind30.
  ///
  /// In fr, this message translates to:
  /// **'Reculer de 30 secondes'**
  String get rewind30;

  /// No description provided for @forward30.
  ///
  /// In fr, this message translates to:
  /// **'Avancer de 30 secondes'**
  String get forward30;

  /// No description provided for @playbackSpeed.
  ///
  /// In fr, this message translates to:
  /// **'Vitesse de lecture'**
  String get playbackSpeed;

  /// No description provided for @audiobooksEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun livre audio. Les fichiers M4B et les genres « Audiobook » apparaissent ici.'**
  String get audiobooksEmpty;

  /// No description provided for @syncPositionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Progression trouvée sur un autre appareil'**
  String get syncPositionTitle;

  /// No description provided for @syncPositionBody.
  ///
  /// In fr, this message translates to:
  /// **'« {title} » a une autre position dans la synchronisation.'**
  String syncPositionBody(String title);

  /// No description provided for @syncPositionRemote.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisation : {position}\n{date}'**
  String syncPositionRemote(String position, String date);

  /// No description provided for @syncPositionLocal.
  ///
  /// In fr, this message translates to:
  /// **'Cet appareil : {position}\n{date}'**
  String syncPositionLocal(String position, String date);

  /// No description provided for @syncPositionNoDate.
  ///
  /// In fr, this message translates to:
  /// **'date inconnue'**
  String get syncPositionNoDate;

  /// No description provided for @syncPositionIgnore.
  ///
  /// In fr, this message translates to:
  /// **'Ignorer'**
  String get syncPositionIgnore;

  /// No description provided for @syncPositionKeepLocal.
  ///
  /// In fr, this message translates to:
  /// **'Garder ici'**
  String get syncPositionKeepLocal;

  /// No description provided for @syncPositionUseRemote.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre depuis la synchro'**
  String get syncPositionUseRemote;

  /// No description provided for @chapterPosition.
  ///
  /// In fr, this message translates to:
  /// **'Chapitre {number}/{total}'**
  String chapterPosition(int number, int total);

  /// No description provided for @audiobookOverall.
  ///
  /// In fr, this message translates to:
  /// **'{percent} % du livre · {remaining} restantes'**
  String audiobookOverall(int percent, String remaining);

  /// No description provided for @previousChapter.
  ///
  /// In fr, this message translates to:
  /// **'Chapitre précédent'**
  String get previousChapter;

  /// No description provided for @nextChapter.
  ///
  /// In fr, this message translates to:
  /// **'Chapitre suivant'**
  String get nextChapter;

  /// No description provided for @sleepTimerEndOfChapter.
  ///
  /// In fr, this message translates to:
  /// **'Fin du chapitre'**
  String get sleepTimerEndOfChapter;

  /// No description provided for @sleepTimerEndOfBook.
  ///
  /// In fr, this message translates to:
  /// **'Fin du livre'**
  String get sleepTimerEndOfBook;

  /// No description provided for @noResultsFor.
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat pour « {query} »'**
  String noResultsFor(String query);

  /// No description provided for @audiobookChapters.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} chapitre} other{{count} chapitres}}'**
  String audiobookChapters(int count);

  /// No description provided for @audiobookBookCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} livre} other{{count} livres}}'**
  String audiobookBookCount(int count);

  /// No description provided for @audiobookProgress.
  ///
  /// In fr, this message translates to:
  /// **'{percent} % écouté'**
  String audiobookProgress(int percent);

  /// No description provided for @audiobookResume.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre'**
  String get audiobookResume;

  /// No description provided for @audiobookListen.
  ///
  /// In fr, this message translates to:
  /// **'Écouter'**
  String get audiobookListen;

  /// No description provided for @audiobookFinished.
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get audiobookFinished;

  /// No description provided for @audiobooksInProgress.
  ///
  /// In fr, this message translates to:
  /// **'En cours d’écoute'**
  String get audiobooksInProgress;

  /// No description provided for @audiobooksAll.
  ///
  /// In fr, this message translates to:
  /// **'Tous les livres'**
  String get audiobooksAll;

  /// No description provided for @importDeviceMedia.
  ///
  /// In fr, this message translates to:
  /// **'Musique du téléphone'**
  String get importDeviceMedia;

  /// No description provided for @importDeviceMediaEnabled.
  ///
  /// In fr, this message translates to:
  /// **'Déjà activée : rechercher les nouveaux morceaux'**
  String get importDeviceMediaEnabled;

  /// No description provided for @importFromServer.
  ///
  /// In fr, this message translates to:
  /// **'Depuis un serveur'**
  String get importFromServer;

  /// No description provided for @importFromServerHint.
  ///
  /// In fr, this message translates to:
  /// **'WebDAV, HTTP ou FTP : écouter en ligne ou télécharger'**
  String get importFromServerHint;

  /// No description provided for @libraryMoreOptions.
  ///
  /// In fr, this message translates to:
  /// **'Plus d’options'**
  String get libraryMoreOptions;

  /// No description provided for @deleteDownloadsMenu.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer les téléchargements…'**
  String get deleteDownloadsMenu;

  /// No description provided for @syncSignedIn.
  ///
  /// In fr, this message translates to:
  /// **'Connecté'**
  String get syncSignedIn;

  /// No description provided for @variousArtists.
  ///
  /// In fr, this message translates to:
  /// **'Artistes divers'**
  String get variousArtists;

  /// No description provided for @albumCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} album} other{{count} albums}}'**
  String albumCount(int count);

  /// No description provided for @artistCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} artiste} other{{count} artistes}}'**
  String artistCount(int count);

  /// No description provided for @genreCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} genre} other{{count} genres}}'**
  String genreCount(int count);

  /// No description provided for @favoritesEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun favori pour l’instant'**
  String get favoritesEmpty;

  /// No description provided for @favoritesEmptyHint.
  ///
  /// In fr, this message translates to:
  /// **'Touchez ♡ sur un morceau pour le retrouver ici.'**
  String get favoritesEmptyHint;

  /// No description provided for @goToAlbum.
  ///
  /// In fr, this message translates to:
  /// **'Voir l’album'**
  String get goToAlbum;

  /// No description provided for @goToArtist.
  ///
  /// In fr, this message translates to:
  /// **'Voir l’artiste'**
  String get goToArtist;

  /// No description provided for @importServersTitle.
  ///
  /// In fr, this message translates to:
  /// **'Importer des serveurs'**
  String get importServersTitle;

  /// No description provided for @importServersHint.
  ///
  /// In fr, this message translates to:
  /// **'Fichier ou texte JSON exporté depuis MusicStream ou préparé à la main.'**
  String get importServersHint;

  /// No description provided for @serverMoreOptions.
  ///
  /// In fr, this message translates to:
  /// **'Options du serveur'**
  String get serverMoreOptions;

  /// No description provided for @continueLabel.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get continueLabel;

  /// No description provided for @visualizerPermissionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Afficher les ondes du son'**
  String get visualizerPermissionTitle;

  /// No description provided for @visualizerPermissionBody.
  ///
  /// In fr, this message translates to:
  /// **'Pour dessiner les ondes, Android demande l’autorisation « enregistrer de l’audio ». MusicStream n’utilise pas le micro : il analyse seulement le son qu’il joue, sans rien enregistrer ni envoyer.'**
  String get visualizerPermissionBody;

  /// No description provided for @downloadThisFolder.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger ce dossier'**
  String get downloadThisFolder;

  /// No description provided for @pickerHeading.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter à la playlist'**
  String get pickerHeading;

  /// No description provided for @pickerSearch.
  ///
  /// In fr, this message translates to:
  /// **'Titre, artiste ou album'**
  String get pickerSearch;

  /// No description provided for @pickerSelected.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun sélectionné} one{{count} sélectionné} other{{count} sélectionnés}}'**
  String pickerSelected(int count);

  /// No description provided for @pickerAdd.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{Ajouter {count}} other{Ajouter {count}}}'**
  String pickerAdd(int count);
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

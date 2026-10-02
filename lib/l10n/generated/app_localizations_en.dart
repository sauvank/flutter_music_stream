import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get actionNext => 'Next';

  @override
  String get actionPause => 'Pause';

  @override
  String get actionPlay => 'Play';

  @override
  String get actionPrevious => 'Previous';

  @override
  String get addFavorite => 'Add to favorites';

  @override
  String get addMyMusic => 'Add my music';

  @override
  String get addServer => 'Add a server';

  @override
  String get addToPlaylist => 'Add to playlist';

  @override
  String get addToQueue => 'Add to queue';

  @override
  String addTrackTitle(String title) {
    return 'Add “$title”';
  }

  @override
  String get addTracks => 'Add tracks';

  @override
  String addTracksTitle(String tracks) {
    return 'Add $tracks';
  }

  @override
  String addedCount(int count) {
    return '$count added';
  }

  @override
  String addedToPlaylist(int count, String playlist) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tracks added to “$playlist”.',
      one: '$count track added to “$playlist”.',
    );
    return '$_temp0';
  }

  @override
  String addedToQueue(int count) {
    return 'Added to queue.';
  }

  @override
  String get allOnPhone => 'All on this phone';

  @override
  String get allTracks => 'All tracks';

  @override
  String alreadyDownloading(String name) {
    return '$name is already downloading.';
  }

  @override
  String get audioChannelName => 'Audio playback';

  @override
  String get audioOutput => 'Play on another device';

  @override
  String get audioOutputUnavailable => 'Couldn’t open the audio output picker.';

  @override
  String get audioPermissionDenied =>
      'MusicStream needs access to your audio files to import a folder.';

  @override
  String get automaticLyrics => 'Automatic lyrics';

  @override
  String get automaticLyricsHint =>
      'During playback, sends the track’s metadata to LRCLIB when its lyrics are not saved yet.';

  @override
  String get availableOffline => 'Available offline';

  @override
  String get availableOfflineHint =>
      'Your tracks stay in the app’s private storage';

  @override
  String baselineBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tracks recorded.',
      one: '$count track recorded.',
    );
    return '$_temp0 Future scans will only report new additions.';
  }

  @override
  String get baselineCreated => 'Baseline created';

  @override
  String get cancel => 'Cancel';

  @override
  String get cancelAll => 'Cancel all';

  @override
  String cancelAllBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count running or pending downloads will be canceled.',
      one: '$count running or pending download will be canceled.',
    );
    return '$_temp0 Tracks already imported are kept.';
  }

  @override
  String get cancelAllTitle => 'Cancel everything?';

  @override
  String get chooseJsonFile => 'Choose a JSON file';

  @override
  String get clearFilter => 'Clear filter';

  @override
  String get clearFinished => 'Clear finished';

  @override
  String get clearRecentSearches => 'Clear';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get clearSelection => 'Clear selection';

  @override
  String get close => 'Close';

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
      'Browse a WebDAV, HTTP or FTP server, then keep your favorite tracks offline.';

  @override
  String get connectCollectionTitle => 'Connect your\ncollection';

  @override
  String get continueAction => 'Continue';

  @override
  String get continueInBackground => 'Continue in background';

  @override
  String get create => 'Create';

  @override
  String get createPlaylist => 'Create a playlist';

  @override
  String get delete => 'Delete';

  @override
  String deleteDownloadsBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'The $count selected tracks will be deleted from MusicStream on this phone.',
      one: 'The selected track will be deleted from MusicStream on this phone.',
    );
    return '$_temp0';
  }

  @override
  String get deleteDownloadsTitle => 'Delete downloads?';

  @override
  String get deleteDownloadsTooltip => 'Remove downloads from this phone';

  @override
  String get deleteFailed => 'Deletion failed. Please try again.';

  @override
  String get deleteFromPhone => 'Delete from phone';

  @override
  String get deleteIncludesLegacy =>
      'This includes the older tracks you chose.';

  @override
  String get deleteKeepsLocal => 'Local imports are kept.';

  @override
  String deletePlaylistBody(String name) {
    return '“$name” will be deleted. Your tracks will be kept.';
  }

  @override
  String get deletePlaylistTitle => 'Delete playlist?';

  @override
  String deleteServerBody(String name) {
    return '“$name”, its saved password and its new-album baseline will be deleted. Tracks already downloaded stay in the library.';
  }

  @override
  String get deleteServerTitle => 'Delete this server?';

  @override
  String deleteTracksBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'The tracks and their related files will be deleted from MusicStream on this phone. The original files are kept.',
      one:
          'The track and its related files will be deleted from MusicStream on this phone. The original file is kept.',
    );
    return '$_temp0';
  }

  @override
  String deleteTracksTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete these $count tracks?',
      one: 'Delete this track?',
    );
    return '$_temp0';
  }

  @override
  String deletedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tracks deleted from this phone.',
      one: '$count track deleted from this phone.',
    );
    return '$_temp0';
  }

  @override
  String get description => 'Description';

  @override
  String get deviceMedia => 'Device media';

  @override
  String deviceMediaCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tracks from this phone',
      one: '$count track from this phone',
    );
    return '$_temp0';
  }

  @override
  String get deviceMediaHint =>
      'Adds the tracks already on this phone, without copying them.';

  @override
  String get deviceMediaPermission =>
      'MusicStream needs access to your audio files to read this phone’s media.';

  @override
  String get deviceMediaRescan => 'Scan again';

  @override
  String get deviceMediaScanning => 'Looking for tracks on this phone…';

  @override
  String deviceMediaSummary(int added, int removed) {
    return '$added added · $removed removed';
  }

  @override
  String get deviceTrackBadge => 'On device';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get done => 'Done';

  @override
  String get download => 'Download';

  @override
  String get downloadFailed => 'Download failed.';

  @override
  String get downloadFolder => 'Download the whole folder';

  @override
  String downloadProgress(int current, int total) {
    return 'Downloading $current / $total';
  }

  @override
  String downloadTitle(String name) {
    return 'Download “$name”';
  }

  @override
  String downloadingTracks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Downloading $count tracks…',
      one: 'Downloading $count track…',
    );
    return '$_temp0';
  }

  @override
  String get downloads => 'Downloads';

  @override
  String get edit => 'Edit';

  @override
  String get editPlaylist => 'Edit playlist';

  @override
  String get emptyHeadline => 'Your music deserves\na beautiful home.';

  @override
  String get emptyHistoryBody =>
      'Tracks you listen to long enough will show up here.';

  @override
  String get emptyHistoryTitle => 'Your history is still empty';

  @override
  String get emptyLibraryBody =>
      'Add your tracks: they stay private, available offline and organized automatically.';

  @override
  String get emptyLibraryTitle => 'Bring your\nlibrary to life';

  @override
  String get emptyPlayerHint =>
      'Pick a track from your library to get started.';

  @override
  String get emptyPlayerTitle => 'Ready to groove?';

  @override
  String get emptyPlaylist => 'This playlist is empty';

  @override
  String get emptyPlaylistsBody =>
      'Group your tracks to find them and play them in order.';

  @override
  String get emptyPlaylistsTitle => 'Create your first playlist';

  @override
  String get enable => 'Turn on';

  @override
  String get encryptedSync => 'Encrypted sync';

  @override
  String get encryptedSyncHint => 'Metadata only, never your audio files';

  @override
  String get enrichLibrary => 'Grow your library';

  @override
  String fadeMilliseconds(int milliseconds) {
    return '$milliseconds ms';
  }

  @override
  String get fadeOff => 'Off';

  @override
  String get fadeSecond => '1 s';

  @override
  String get fades => 'Playback fades';

  @override
  String get fadesHint => 'Smooths play, pause and track changes';

  @override
  String get favorites => 'Favorites';

  @override
  String get fileReadFailed => 'Unable to read this file.';

  @override
  String get filterFolder => 'Filter this folder';

  @override
  String get folder => 'Folder';

  @override
  String folderConnectionLost(String stage) {
    return 'Connection lost during $stage of the folder.';
  }

  @override
  String folderFailed(String stage) {
    return 'Unable to finish $stage of the folder.';
  }

  @override
  String folderHttpError(int status, String stage) {
    return 'The server returned HTTP error $status during $stage of the folder.';
  }

  @override
  String folderQueued(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tracks added.',
      one: '$count track added.',
    );
    return '$_temp0 You can close this window: the download continues in the background.';
  }

  @override
  String get folderReadFailed => 'Unable to read the folder contents.';

  @override
  String get folderTooLarge => 'The folder contains too many tracks.';

  @override
  String get ftpAddress => 'FTP address';

  @override
  String get ftpUnencrypted =>
      'FTP sends credentials and files without encryption.';

  @override
  String get goodAfternoon => 'Good afternoon';

  @override
  String get goodEvening => 'Good evening';

  @override
  String get goodMorning => 'Good morning';

  @override
  String get headline => 'What would you like\nto hear?';

  @override
  String get hidePassphrase => 'Hide passphrase';

  @override
  String get homeWidget => 'Home screen widget';

  @override
  String get homeWidgetAdd => 'Add';

  @override
  String get homeWidgetHint =>
      'Current track and playback controls on your home screen.';

  @override
  String get homeWidgetUnsupported =>
      'Your launcher cannot add it directly: add the MusicStream widget from the widget list.';

  @override
  String get httpAddress => 'HTTPS or HTTP address';

  @override
  String get identifiedDownloads => 'Identified downloads';

  @override
  String get importAction => 'Import';

  @override
  String importAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tracks added',
      one: '$count track added',
    );
    return '$_temp0';
  }

  @override
  String get importChooseFiles => 'Choose files';

  @override
  String get importChooseFilesHint => 'Select one or more tracks';

  @override
  String get importChooseFolder => 'Choose a folder';

  @override
  String get importChooseFolderHint =>
      'Import every track in the folder and its subfolders';

  @override
  String get importFailed => 'Import failed. Please try again.';

  @override
  String importFailures(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count failures',
      one: '$count failure',
    );
    return '$_temp0';
  }

  @override
  String get importJsonFile => 'Import a JSON file';

  @override
  String get importLrc => 'Import .lrc';

  @override
  String importProgress(int completed, int total) {
    return 'Importing $completed / $total…';
  }

  @override
  String get importSheetTitle => 'Add music';

  @override
  String importSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count already present',
      one: '$count already present',
    );
    return '$_temp0';
  }

  @override
  String get importTracks => 'Import tracks';

  @override
  String get importTracksFirst => 'Import some tracks into the library first.';

  @override
  String get importing => 'Importing…';

  @override
  String get includeLegacy => 'Include older ones';

  @override
  String get invalidJson => 'The JSON content is invalid.';

  @override
  String get language => 'Language';

  @override
  String get languageHint => 'Follow the device or pick a language';

  @override
  String legacyTracksBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tracks added before this version have no recorded origin.',
      one: '$count track added before this version has no recorded origin.',
    );
    return '$_temp0 Only include them if you know they all come from the server: an older local import would be deleted too.';
  }

  @override
  String get legacyTracksTitle => 'Older tracks';

  @override
  String get libraryUpToDate => 'Library up to date';

  @override
  String get localByDefault => 'Local by default';

  @override
  String get localByDefaultHint => 'No files, local paths or secrets are sent';

  @override
  String get lyrics => 'Lyrics';

  @override
  String get lyricsAutoBody =>
      'For tracks without saved lyrics, MusicStream will send their title, artist, album and duration to LRCLIB when they play. You can change this in Settings.';

  @override
  String get lyricsAutoTitle => 'Find lyrics automatically?';

  @override
  String get lyricsEmpty =>
      'No lyrics found. Import an .lrc file or search again.';

  @override
  String get lyricsImportEmpty => 'The lyrics file is empty.';

  @override
  String get lyricsImportFailed => 'Unable to import this .lrc file.';

  @override
  String get lyricsMissingMetadata =>
      'A title and an artist are required to search for lyrics.';

  @override
  String get lyricsNotFoundOnline => 'No lyrics found on LRCLIB.';

  @override
  String lyricsOf(String title) {
    return 'Lyrics for $title';
  }

  @override
  String get lyricsPrivacyHint =>
      'Searching sends the title, artist, album and duration to LRCLIB.';

  @override
  String lyricsRateLimitAfter(String time) {
    return 'LRCLIB is limiting requests. Try again after $time.';
  }

  @override
  String get lyricsRateLimitLater =>
      'LRCLIB is temporarily limiting requests. Try again later.';

  @override
  String lyricsRateLimitSeconds(int seconds) {
    return 'LRCLIB is limiting requests. Try again in $seconds seconds.';
  }

  @override
  String get lyricsReadFailed => 'Unable to read the saved lyrics.';

  @override
  String get lyricsSearchFailed =>
      'Search failed. Check your connection and try again.';

  @override
  String get lyricsSynchronized =>
      'Synced with playback • tap a line to jump to it';

  @override
  String get lyricsUnsynchronized => 'Unsynced lyrics';

  @override
  String get modeAlbums => 'Albums';

  @override
  String get modeArtists => 'Artists';

  @override
  String get modeGenres => 'Genres';

  @override
  String get modeHistory => 'History';

  @override
  String get modePlaylists => 'Playlists';

  @override
  String get modeTracks => 'Tracks';

  @override
  String get moreActions => 'More actions';

  @override
  String get name => 'Name';

  @override
  String get navLibrary => 'Library';

  @override
  String get navPlayer => 'Playing';

  @override
  String get navServers => 'Servers';

  @override
  String get navSettings => 'Settings';

  @override
  String get newAlbums => 'New albums';

  @override
  String get newPlaylist => 'New playlist';

  @override
  String newTracksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new tracks:',
      one: '$count new track:',
    );
    return '$_temp0';
  }

  @override
  String get noCompatibleTracks => 'No compatible tracks in this folder.';

  @override
  String get noDownloads => 'No downloads.';

  @override
  String get noFilterMatch => 'Nothing matches the filter.';

  @override
  String noNewTracks(int count) {
    return 'No new tracks among the $count items scanned.';
  }

  @override
  String get noResults => 'No results';

  @override
  String get noResultsHint => 'Try another title, artist, album or genre.';

  @override
  String get notNow => 'Not now';

  @override
  String get nothingNewToDownload => 'Nothing new to download.';

  @override
  String get nothingPlaying => 'Nothing is playing.';

  @override
  String notificationCompleteBody(String finished) {
    return '$finished track(s) available offline';
  }

  @override
  String get notificationCompleteTitle => 'Download complete';

  @override
  String notificationErrorBody(String failed, String total) {
    return '$failed failed out of $total';
  }

  @override
  String get notificationErrorTitle => 'Download incomplete';

  @override
  String get notificationPausedTitle => 'Download paused';

  @override
  String get notificationRunningTitle => 'Downloading music';

  @override
  String get nowPlayingLabel => 'NOW PLAYING';

  @override
  String offlineCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tracks available offline',
      one: '$count track available offline',
    );
    return '$_temp0';
  }

  @override
  String get onPhone => 'On this phone';

  @override
  String get openSettings => 'Settings';

  @override
  String get original => 'Original';

  @override
  String partlyOnPhone(int available, int total) {
    return '$available/$total on this phone';
  }

  @override
  String get password => 'Password';

  @override
  String get pasteConfiguration => 'Paste a configuration';

  @override
  String get pasteJson => 'Paste JSON content';

  @override
  String get pause => 'Pause';

  @override
  String get personalServers => 'Personal servers';

  @override
  String get personalServersHint =>
      'WebDAV and HTTP, with credentials in the system keystore';

  @override
  String get pickMusicFolder => 'Choose a music folder';

  @override
  String get playAll => 'Play all';

  @override
  String get playCollection => 'Play collection';

  @override
  String get playFolder => 'Play folder';

  @override
  String get playNext => 'Play next';

  @override
  String get playThisFolder => 'Play this folder';

  @override
  String get playingNext => 'Playing next.';

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
  String get playlistTracks => 'Playlist tracks';

  @override
  String get preparingPlayback => 'Preparing playback…';

  @override
  String queueButton(int count) {
    return 'Play queue ($count)';
  }

  @override
  String queuedForDownload(String name) {
    return '$name added to background downloads.';
  }

  @override
  String queueingTracks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Adding $count tracks to the queue…',
      one: 'Adding $count track to the queue…',
    );
    return '$_temp0';
  }

  @override
  String get recentSearches => 'Recent searches';

  @override
  String get recentlyAdded => 'Recently added';

  @override
  String get recentlyPlayed => 'Recently played';

  @override
  String get removeFavorite => 'Remove from favorites';

  @override
  String get removeFromPlaylist => 'Remove from playlist';

  @override
  String get removeFromQueue => 'Remove from queue';

  @override
  String get removedFromPlaylist => 'Removed from playlist.';

  @override
  String get reorder => 'Reorder';

  @override
  String get reorderHint => 'Drag the handles to change the order.';

  @override
  String get repeatOff => 'Turn off repeat';

  @override
  String get repeatQueue => 'Repeat queue';

  @override
  String get repeatTrack => 'Repeat this track';

  @override
  String get resume => 'Resume';

  @override
  String get retry => 'Retry';

  @override
  String get retryFailed => 'Retry failed';

  @override
  String get save => 'Save';

  @override
  String get scanFailed => 'Unable to scan this server right now.';

  @override
  String get scanNewAlbums => 'Look for new albums';

  @override
  String get scanningFolder => 'Scanning folder…';

  @override
  String get searchAgain => 'Search again';

  @override
  String get searchHint => 'Search your music';

  @override
  String get sectionAppearance => 'APPEARANCE';

  @override
  String get sectionConnections => 'CONNECTIONS';

  @override
  String get sectionLibrary => 'LIBRARY';

  @override
  String get sectionPlayback => 'PLAYBACK';

  @override
  String get sectionPrivacy => 'PRIVACY';

  @override
  String get selectAll => 'Select all';

  @override
  String selectedCount(int count) {
    return '$count selected';
  }

  @override
  String get serverAlreadyConfigured => 'This server is already configured.';

  @override
  String get serverConnectionFailed =>
      'Connection failed. Check the address and credentials.';

  @override
  String get serverRoot => 'Server root';

  @override
  String get serversHeadline => 'Your music,\nwherever it lives.';

  @override
  String serversImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count servers imported.',
      one: '$count server imported.',
    );
    return '$_temp0';
  }

  @override
  String get settingsHeadline => 'At your own pace.';

  @override
  String get settingsTagline => 'A private, local library ready to follow you.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get showAll => 'Show all';

  @override
  String get showPassphrase => 'Show passphrase';

  @override
  String get showVisualizer => 'Show sound waves';

  @override
  String get shuffle => 'Shuffle';

  @override
  String get shuffleDisable => 'Turn off shuffle';

  @override
  String get shuffleEnable => 'Turn on shuffle';

  @override
  String get shufflePlay => 'Shuffle play';

  @override
  String sizeKilobytes(String size) {
    return '$size KB';
  }

  @override
  String sizeMegabytes(String size) {
    return '$size MB';
  }

  @override
  String get sleepTimer => 'Sleep timer';

  @override
  String get sleepTimerAtTrackEnd => 'Pausing at the end of the track';

  @override
  String get sleepTimerEndOfTrack => 'At the end of the track';

  @override
  String sleepTimerMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get sleepTimerOff => 'Off';

  @override
  String sleepTimerRemaining(String time) {
    return 'Pausing in $time';
  }

  @override
  String get sortAlbum => 'Album';

  @override
  String get sortArtist => 'Artist';

  @override
  String sortBy(String sort) {
    return 'Sort by $sort';
  }

  @override
  String get sortRecent => 'Recently added';

  @override
  String get sortTitle => 'Title';

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
  String get stageFtp => 'the FTP transfer';

  @override
  String get stageInventory => 'the listing';

  @override
  String get stageQueue => 'queueing';

  @override
  String get statusCanceled => 'Canceled';

  @override
  String get statusComplete => 'Available offline';

  @override
  String get statusEnqueued => 'Waiting';

  @override
  String get statusFailed => 'Download failed';

  @override
  String statusFailedWithReason(String reason) {
    return 'Failed: $reason';
  }

  @override
  String get statusNotFound => 'File not found';

  @override
  String get statusPaused => 'Paused';

  @override
  String get statusRunning => 'Downloading';

  @override
  String get statusWaitingToRetry => 'Waiting to retry';

  @override
  String get streamFailed => 'Unable to play from the server.';

  @override
  String get streamFromServer => 'Stream from the server';

  @override
  String get supportedFormats => 'MP3, M4A, AAC, FLAC, OGG, OPUS and WAV';

  @override
  String get syncActive => 'On';

  @override
  String get syncConflict =>
      'Another device is syncing at the same time. Try again.';

  @override
  String get syncDisable => 'Turn off on this device';

  @override
  String get syncDone => 'Sync complete.';

  @override
  String get syncEnable => 'Turn on and sync';

  @override
  String get syncExplanation =>
      'Favorites, plays and playlists are encrypted on this phone with your passphrase, then stored in a file on your WebDAV server. The server never sees their content, and your audio files are never sent.';

  @override
  String get syncFailed => 'Sync failed. Check the connection to the server.';

  @override
  String syncLastRun(String date) {
    return 'Last synced: $date';
  }

  @override
  String get syncNeedsWebdav => 'Add a WebDAV server in the Servers tab first.';

  @override
  String get syncNever => 'Never synced';

  @override
  String get syncNow => 'Sync now';

  @override
  String get syncPassphrase => 'Passphrase';

  @override
  String get syncPassphraseConfirm => 'Confirm passphrase';

  @override
  String get syncPassphraseHint =>
      'At least 8 characters. Use the same one on every device: it cannot be recovered.';

  @override
  String get syncPassphraseMismatch => 'The two passphrases do not match.';

  @override
  String get syncPassphraseTooShort => 'Use at least 8 characters.';

  @override
  String get syncServer => 'Server';

  @override
  String get syncServerMissing =>
      'The sync server no longer exists. Turn sync off and on again.';

  @override
  String get syncTitle => 'Encrypted sync';

  @override
  String syncWriteForbidden(int status) {
    return 'The server refuses to write the sync file (HTTP $status). This account can read but not write over WebDAV: allow writing on the server (AList: “Webdav manage” permission), then try again.';
  }

  @override
  String get syncWrongPassphrase =>
      'This passphrase does not open this server’s sync file.';

  @override
  String get theme => 'Theme';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeHint => 'Follow the device or force a mode';

  @override
  String get themeLight => 'Light';

  @override
  String get themeSystem => 'System';

  @override
  String trackCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tracks',
      one: '$count track',
    );
    return '$_temp0';
  }

  @override
  String get trackOptions => 'Track options';

  @override
  String tracksSortedBy(String tracks, String sort) {
    return '$tracks · $sort';
  }

  @override
  String get translate => 'Translate';

  @override
  String get translateLyricsHint =>
      'The lyrics will be sent to MyMemory. The translation is kept on this device.';

  @override
  String get translateLyricsTitle => 'Translate lyrics';

  @override
  String get translationFailed =>
      'Translation failed. Check your connection and try again.';

  @override
  String translationLanguage(String language) {
    return 'Translation: $language';
  }

  @override
  String get translationLineTooLong => 'A line is too long to translate.';

  @override
  String get translationRateLimited =>
      'MyMemory is temporarily limiting translations. Try again later.';

  @override
  String get translationUnavailable =>
      'Translation failed (network or service unavailable).';

  @override
  String get undo => 'Undo';

  @override
  String get unknownAlbum => 'Unknown album';

  @override
  String get unknownArtist => 'Unknown artist';

  @override
  String get unknownGenre => 'Unknown genre';

  @override
  String get untitledTrack => 'Untitled track';

  @override
  String get upNext => 'Up next';

  @override
  String get usernameOptional => 'Username (optional)';

  @override
  String volumePercent(int percent) {
    return '$percent%';
  }

  @override
  String get widgetIdle => 'Nothing playing';

  @override
  String get yourFavorites => 'Your favorites';

  @override
  String get yourLibrary => 'YOUR LIBRARY';

  @override
  String get yourPlaylists => 'Your playlists';

  @override
  String get yourSources => 'YOUR SOURCES';
}

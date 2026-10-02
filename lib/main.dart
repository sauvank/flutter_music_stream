import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';

import 'providers/appearance_provider.dart';
import 'providers/library_provider.dart';
import 'providers/download_queue_provider.dart';
import 'providers/player_provider.dart';
import 'providers/server_provider.dart';
import 'providers/sync_provider.dart';
import 'screens/home_screen.dart';
import 'services/appearance_settings_service.dart';
import 'services/audio_access.dart';
import 'services/home_widget_service.dart';
import 'services/library_service.dart';
import 'services/lyrics_service.dart';
import 'services/playlist_service.dart';
import 'services/playback_settings_service.dart';
import 'services/remote_server_service.dart';
import 'services/server_profile_service.dart';
import 'services/sync/sync_account.dart';
import 'services/sync/sync_remote.dart';
import 'services/sync/sync_service.dart';
import 'l10n/l10n.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appearanceSettings = AppearanceSettingsService();
  final appearance = AppearanceProvider(
    appearanceSettings,
    themeMode: await appearanceSettings.loadThemeMode(),
    locale: await appearanceSettings.loadLocale(),
  );
  // Native notifications are configured outside the widget tree.
  AppLocalizations localizations() => lookupAppLocalizations(
        appearance.locale ??
            basicLocaleListResolution(
              WidgetsBinding.instance.platformDispatcher.locales,
              AppLocalizations.supportedLocales,
            ),
      );
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.sauvank.musicstream.audio',
    androidNotificationChannelName: localizations().audioChannelName,
    androidNotificationOngoing: true,
    // A white glyph: the launcher icon would render as a blank square.
    androidNotificationIcon: 'drawable/ic_stat_musicstream',
  );
  final library = LibraryProvider(LibraryService(), PlaylistService());
  final downloads = DownloadQueueProvider(library);
  final servers = ServerProvider(
    ServerProfileService(),
    RemoteServerService(),
  );
  final playbackSettings = PlaybackSettingsService();
  final fadeDuration = await playbackSettings.loadFadeDuration();
  final volume = await playbackSettings.loadVolume();
  final savedQueue = await playbackSettings.loadQueue();
  await library.load();
  // The native downloader takes up to a second to start; keep it off the
  // first frame. Orphan cleanup runs first so resumed downloads cannot race
  // with it.
  unawaited(library
      .removeOrphanFiles()
      .then((_) => downloads.initialize(localizations()))
      .then((_) async {
    // Picks up files added to the phone since the last launch.
    if (library.deviceMediaEnabled && await AudioAccess.granted()) {
      await library.scanDeviceMedia();
    }
  }).catchError((Object error) {
    debugPrint('Startup background work failed: $error');
  }));
  appearance.addListener(
    () => downloads.configureNotifications(localizations()),
  );
  await servers.load();
  final firebaseReady = await _initializeFirebase();
  final sync = SyncProvider(
    SyncService(),
    firebaseReady ? FirestoreSyncRemote() : const _NoSyncRemote(),
    firebaseReady ? FirebaseSyncAccount() : const UnavailableSyncAccount(),
    library,
  );
  await sync.load();
  runApp(MusicStreamApp(
    library: library,
    downloads: downloads,
    servers: servers,
    sync: sync,
    appearance: appearance,
    localizations: localizations,
    playbackSettings: playbackSettings,
    fadeDuration: fadeDuration,
    volume: volume,
    savedQueue: savedQueue,
  ));
}

class MusicStreamApp extends StatelessWidget {
  const MusicStreamApp({
    super.key,
    required this.library,
    required this.downloads,
    required this.servers,
    required this.sync,
    required this.appearance,
    required this.localizations,
    required this.playbackSettings,
    required this.fadeDuration,
    required this.volume,
    this.savedQueue,
  });
  final LibraryProvider library;
  final DownloadQueueProvider downloads;
  final ServerProvider servers;
  final SyncProvider sync;
  final AppearanceProvider appearance;
  final AppLocalizations Function() localizations;
  final PlaybackSettingsService playbackSettings;
  final Duration fadeDuration;
  final double volume;
  final ({List<String> trackIds, String? currentId})? savedQueue;

  /// Reloads the last session paused. Streams from servers need their
  /// credentials, so only tracks still in the library come back.
  PlayerProvider _restoreQueue(PlayerProvider player) {
    final saved = savedQueue;
    if (saved != null) {
      unawaited(player
          .restoreQueue(library.tracksByIds(saved.trackIds), saved.currentId)
          .catchError((Object error) {
        debugPrint('Queue restore failed: $error');
      }));
    }
    return player;
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: library),
          ChangeNotifierProvider.value(value: downloads),
          ChangeNotifierProvider.value(value: servers),
          ChangeNotifierProvider.value(value: sync),
          ChangeNotifierProvider.value(value: appearance),
          ChangeNotifierProvider(
            create: (_) => _restoreQueue(PlayerProvider(
              onPositionChanged: library.savePosition,
              onTrackListened: library.recordPlayed,
              onCurrentTrackChanged: (track) async {
                try {
                  final lyrics = LyricsService.shared;
                  if (await lyrics.automaticSearchPreference() != true) return;
                  if (await lyrics.load(track.id) != null) return;
                  await lyrics.searchOnline(track);
                } catch (_) {
                  // Automatic enrichment must never interrupt playback.
                }
              },
              displayMetadata: (value) => localizations().metadata(value),
              onNowPlayingChanged: (track, playing) {
                final l10n = localizations();
                const HomeWidgetService().update(
                  title: track?.title,
                  artist: track == null ? null : l10n.metadata(track.artist),
                  artworkUri: track?.artworkUri,
                  playing: playing,
                  idleTitle: l10n.widgetIdle,
                );
              },
              fadeDuration: fadeDuration,
              volume: volume,
              onFadeDurationChanged: playbackSettings.saveFadeDuration,
              onVolumeChanged: playbackSettings.saveVolume,
              onQueueChanged: (ids, currentId) => unawaited(
                  playbackSettings.saveQueue(ids, currentId)),
            )),
          ),
        ],
        child: Builder(
          builder: (context) => MaterialApp(
            title: 'MusicStream',
            debugShowCheckedModeBanner: false,
            themeMode: context.select<AppearanceProvider, ThemeMode>(
              (appearance) => appearance.themeMode,
            ),
            locale: context.select<AppearanceProvider, Locale?>(
              (appearance) => appearance.locale,
            ),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            theme: _theme(Brightness.light),
            darkTheme: _theme(Brightness.dark),
            home: const HomeScreen(),
          ),
        ),
      );

  ThemeData _theme(Brightness brightness) {
    final colors = ColorScheme.fromSeed(
      seedColor: const Color(0xFF7C4DFF),
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: colors,
      useMaterial3: true,
      scaffoldBackgroundColor: brightness == Brightness.dark
          ? const Color(0xFF0D0C12)
          : const Color(0xFFF8F6FC),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colors.surfaceContainerHighest.withValues(alpha: .55),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

/// Builds without the local Firebase config still run, without account
/// sync. Native config comes from google-services.json / the plist.
Future<bool> _initializeFirebase() async {
  try {
    await Firebase.initializeApp();
    return true;
  } catch (error) {
    debugPrint('Firebase unavailable, sync disabled: $error');
    return false;
  }
}

class _NoSyncRemote implements SyncRemote {
  const _NoSyncRemote();

  @override
  Future<RemoteSyncFile?> download(String uid) =>
      Future.error(StateError('Sync unavailable'));

  @override
  Future<void> upload(
    String uid,
    Map<String, Object?> envelope, {
    required RemoteSyncFile? replacing,
  }) =>
      Future.error(StateError('Sync unavailable'));
}

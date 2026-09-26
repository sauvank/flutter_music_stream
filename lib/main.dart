import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';

import 'providers/library_provider.dart';
import 'providers/player_provider.dart';
import 'providers/server_provider.dart';
import 'screens/home_screen.dart';
import 'services/library_service.dart';
import 'services/remote_server_service.dart';
import 'services/server_profile_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.sauvank.musicstream.audio',
    androidNotificationChannelName: 'Lecture audio',
    androidNotificationOngoing: true,
  );
  final library = LibraryProvider(LibraryService());
  final servers = ServerProvider(
    ServerProfileService(),
    RemoteServerService(),
  );
  await library.load();
  await servers.load();
  runApp(MusicStreamApp(library: library, servers: servers));
}

class MusicStreamApp extends StatelessWidget {
  const MusicStreamApp({
    super.key,
    required this.library,
    required this.servers,
  });
  final LibraryProvider library;
  final ServerProvider servers;

  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: library),
          ChangeNotifierProvider.value(value: servers),
          ChangeNotifierProvider(
            create: (_) =>
                PlayerProvider(onPositionChanged: library.savePosition),
          ),
        ],
        child: MaterialApp(
          title: 'MusicStream',
          debugShowCheckedModeBanner: false,
          themeMode: ThemeMode.system,
          theme: _theme(Brightness.light),
          darkTheme: _theme(Brightness.dark),
          home: const HomeScreen(),
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

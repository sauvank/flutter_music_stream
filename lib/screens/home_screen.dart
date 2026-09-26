import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/player_provider.dart';
import '../widgets/track_artwork.dart';
import 'library_screen.dart';
import 'now_playing_screen.dart';
import 'servers_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    const screens = [
      LibraryScreen(),
      ServersScreen(),
      NowPlayingScreen(),
      SettingsScreen(),
    ];
    final dark = Theme.of(context).brightness == Brightness.dark;
    final overlay =
        dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => constraints.maxWidth >= 840
            ? _wideLayout(context, screens, dark)
            : _compactLayout(context, screens, dark),
      ),
    );
  }

  Widget _compactLayout(
    BuildContext context,
    List<Widget> screens,
    bool dark,
  ) =>
      Scaffold(
        extendBody: true,
        backgroundColor: Colors.transparent,
        body: _Background(
          dark: dark,
          child: SafeArea(
            bottom: false,
            child: IndexedStack(index: _index, children: screens),
          ),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_index != 2)
                _MiniPlayer(onOpen: () => setState(() => _index = 2)),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHigh
                      .withValues(alpha: .96),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: dark ? .3 : .1),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: NavigationBar(
                    height: 72,
                    backgroundColor: Colors.transparent,
                    indicatorColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    labelBehavior:
                        NavigationDestinationLabelBehavior.onlyShowSelected,
                    selectedIndex: _index,
                    onDestinationSelected: (value) =>
                        setState(() => _index = value),
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(Icons.headphones_outlined),
                        selectedIcon: Icon(Icons.headphones_rounded),
                        label: 'Bibliothèque',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.cloud_outlined),
                        selectedIcon: Icon(Icons.cloud_rounded),
                        label: 'Serveurs',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.play_circle_outline_rounded),
                        selectedIcon: Icon(Icons.play_circle_fill_rounded),
                        label: 'Lecture',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.tune_rounded),
                        selectedIcon: Icon(Icons.tune_rounded),
                        label: 'Réglages',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _wideLayout(
    BuildContext context,
    List<Widget> screens,
    bool dark,
  ) =>
      Scaffold(
        backgroundColor: Colors.transparent,
        body: _Background(
          dark: dark,
          child: SafeArea(
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHigh
                          .withValues(alpha: .94),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: NavigationRail(
                      backgroundColor: Colors.transparent,
                      extended: MediaQuery.sizeOf(context).width >= 1100,
                      selectedIndex: _index,
                      onDestinationSelected: (value) =>
                          setState(() => _index = value),
                      leading: const Padding(
                        padding: EdgeInsets.only(top: 12, bottom: 20),
                        child: CircleAvatar(
                          radius: 23,
                          child: Icon(Icons.graphic_eq_rounded),
                        ),
                      ),
                      destinations: const [
                        NavigationRailDestination(
                          icon: Icon(Icons.headphones_outlined),
                          selectedIcon: Icon(Icons.headphones_rounded),
                          label: Text('Bibliothèque'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.cloud_outlined),
                          selectedIcon: Icon(Icons.cloud_rounded),
                          label: Text('Serveurs'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.play_circle_outline_rounded),
                          selectedIcon: Icon(Icons.play_circle_fill_rounded),
                          label: Text('Lecture'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.tune_rounded),
                          selectedIcon: Icon(Icons.tune_rounded),
                          label: Text('Réglages'),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      IndexedStack(index: _index, children: screens),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                            child: _index == 2
                                ? const SizedBox.shrink()
                                : _MiniPlayer(
                                    onOpen: () => setState(() => _index = 2),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _Background extends StatelessWidget {
  const _Background({required this.dark, required this.child});
  final bool dark;
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: dark
                ? const [Color(0xFF090A12), Color(0xFF121124)]
                : const [Color(0xFFF8F7FF), Color(0xFFF0F6FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: child,
      );
}

class _MiniPlayer extends StatelessWidget {
  const _MiniPlayer({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final track = player.current;
    if (track == null) return const SizedBox.shrink();
    final duration = player.duration.inMilliseconds;
    final progress = duration <= 0
        ? 0.0
        : (player.position.inMilliseconds / duration).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primaryContainer,
                  Theme.of(context).colorScheme.tertiaryContainer,
                ],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
                  child: Row(
                    children: [
                      TrackArtwork(
                        track: track,
                        size: 50,
                        borderRadius: BorderRadius.circular(17),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              track.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              track.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: player.playing ? 'Pause' : 'Lire',
                        onPressed: player.toggle,
                        icon: Icon(player.playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded),
                      ),
                      IconButton(
                        tooltip: 'Suivant',
                        onPressed: player.hasNext ? player.next : null,
                        icon: const Icon(Icons.skip_next_rounded),
                      ),
                    ],
                  ),
                ),
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 3,
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

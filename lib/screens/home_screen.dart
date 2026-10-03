import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/download_queue_provider.dart';
import '../providers/player_provider.dart';
import '../providers/server_provider.dart';
import '../widgets/track_artwork.dart';
import 'library_screen.dart';
import 'now_playing_screen.dart';
import 'servers_screen.dart';
import 'settings_screen.dart';
import '../l10n/l10n.dart';
import '../services/update_check_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static final _nowPlayingRequests = ValueNotifier<int>(0);

  /// Closes the pages pushed over the tabs and shows Now Playing.
  static void openNowPlaying(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    _nowPlayingRequests.value++;
  }

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _library = GlobalKey<LibraryScreenState>();
  int _index = 0;
  // Visited tabs, most recent last, so back returns where the user was.
  final List<int> _visited = [];

  @override
  void initState() {
    super.initState();
    HomeScreen._nowPlayingRequests.addListener(_showNowPlaying);
    if (Platform.isAndroid) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _offerUpdate());
    }
  }

  Future<void> _offerUpdate() async {
    final service = UpdateCheckService();
    final build = await service.pendingUpdate();
    if (build == null || !mounted) return;
    final update = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.updateAvailableTitle),
        content: Text(context.l10n.updateAvailableBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.updateLater),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.updateAction),
          ),
        ],
      ),
    );
    if (update == true) {
      await launchUrl(
        Uri.parse(UpdateCheckService.storeUrl),
        mode: LaunchMode.externalApplication,
      );
    } else {
      await service.dismiss(build);
    }
  }

  @override
  void dispose() {
    HomeScreen._nowPlayingRequests.removeListener(_showNowPlaying);
    super.dispose();
  }

  void _showNowPlaying() => _select(2);

  void _select(int value) {
    if (value == _index) return;
    // Tabs stay alive in an IndexedStack: a focused field on a hidden tab
    // would otherwise reopen the keyboard whenever a dialog closes.
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _visited
        ..remove(_index)
        ..add(_index);
      _index = value;
    });
  }

  void _handleBack() {
    if (_index == 0 && (_library.currentState?.handleBack() ?? false)) return;
    if (_index == 1) {
      final servers = context.read<ServerProvider>();
      if (servers.selected != null) {
        if (servers.canGoBack) {
          servers.goBack();
        } else {
          servers.disconnect();
        }
        return;
      }
    }
    _visited.remove(_index);
    if (_visited.isNotEmpty) {
      setState(() => _index = _visited.removeLast());
    } else if (_index != 0) {
      setState(() => _index = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      LibraryScreen(key: _library),
      const ServersScreen(),
      // Hidden, it must not keep the live visualizer running.
      TickerMode(
        enabled: _index == 2,
        child: _RiseOnShow(
          visible: _index == 2,
          child: NowPlayingScreen(onClose: () {
            // A single pull may report several times; close only once.
            if (_index == 2) _handleBack();
          }),
        ),
      ),
      const SettingsScreen(),
    ];
    final dark = Theme.of(context).brightness == Brightness.dark;
    final overlay =
        dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
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
              if (_index != 2) _MiniPlayer(onOpen: () => _select(2)),
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
                    onDestinationSelected: _select,
                    destinations: [
                      NavigationDestination(
                        icon: const Icon(Icons.headphones_outlined),
                        selectedIcon: const Icon(Icons.headphones_rounded),
                        label: context.l10n.navLibrary,
                      ),
                      NavigationDestination(
                        icon: const _DownloadsBadge(
                            child: Icon(Icons.cloud_outlined)),
                        selectedIcon: const _DownloadsBadge(
                            child: Icon(Icons.cloud_rounded)),
                        label: context.l10n.navServers,
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.play_circle_outline_rounded),
                        selectedIcon:
                            const Icon(Icons.play_circle_fill_rounded),
                        label: context.l10n.navPlayer,
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.tune_rounded),
                        selectedIcon: const Icon(Icons.tune_rounded),
                        label: context.l10n.navSettings,
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
      _DesktopShortcuts(
          child: Scaffold(
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
                      onDestinationSelected: _select,
                      leading: const Padding(
                        padding: EdgeInsets.only(top: 12, bottom: 20),
                        child: CircleAvatar(
                          radius: 23,
                          child: Icon(Icons.graphic_eq_rounded),
                        ),
                      ),
                      destinations: [
                        NavigationRailDestination(
                          icon: const Icon(Icons.headphones_outlined),
                          selectedIcon: const Icon(Icons.headphones_rounded),
                          label: Text(context.l10n.navLibrary),
                        ),
                        NavigationRailDestination(
                          icon: const _DownloadsBadge(
                              child: Icon(Icons.cloud_outlined)),
                          selectedIcon: const _DownloadsBadge(
                              child: Icon(Icons.cloud_rounded)),
                          label: Text(context.l10n.navServers),
                        ),
                        NavigationRailDestination(
                          icon: const Icon(Icons.play_circle_outline_rounded),
                          selectedIcon:
                              const Icon(Icons.play_circle_fill_rounded),
                          label: Text(context.l10n.navPlayer),
                        ),
                        NavigationRailDestination(
                          icon: const Icon(Icons.tune_rounded),
                          selectedIcon: const Icon(Icons.tune_rounded),
                          label: Text(context.l10n.navSettings),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      IndexedStack(index: _index, children: [
                        for (final (i, screen) in screens.indexed)
                          Align(
                            alignment: Alignment.topCenter,
                            child: ConstrainedBox(
                              // Settings and server cards stay readable instead
                              // of stretching across the whole window.
                              constraints: BoxConstraints(
                                maxWidth: switch (i) {
                                  1 => 1000,
                                  3 => 760,
                                  _ => double.infinity,
                                },
                              ),
                              child: screen,
                            ),
                          ),
                      ]),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                            child: _index == 2
                                ? const SizedBox.shrink()
                                : _MiniPlayer(onOpen: () => _select(2)),
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
      ));
}

/// Keyboard control for desktop windows: space plays or pauses, the arrows
/// seek by 10 seconds, and Ctrl+arrows change track. Text fields keep their
/// own keys because shortcuts only fire when nothing editable has focus.
class _DesktopShortcuts extends StatelessWidget {
  const _DesktopShortcuts({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final player = context.read<PlayerProvider>();
    bool typing() =>
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<EditableText>() !=
        null;
    void seekBy(int seconds) {
      final target = player.position + Duration(seconds: seconds);
      player.seek(target < Duration.zero ? Duration.zero : target);
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.space): () {
          if (!typing()) player.toggle();
        },
        const SingleActivator(LogicalKeyboardKey.arrowRight): () {
          if (!typing()) seekBy(10);
        },
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () {
          if (!typing()) seekBy(-10);
        },
        const SingleActivator(LogicalKeyboardKey.arrowRight, control: true):
            player.next,
        const SingleActivator(LogicalKeyboardKey.arrowLeft, control: true):
            player.previous,
        const SingleActivator(LogicalKeyboardKey.mediaPlayPause): player.toggle,
        const SingleActivator(LogicalKeyboardKey.mediaTrackNext): player.next,
        const SingleActivator(LogicalKeyboardKey.mediaTrackPrevious):
            player.previous,
      },
      child: Focus(autofocus: true, child: child),
    );
  }
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

/// Shows the number of running or queued downloads on the Servers tab.
class _DownloadsBadge extends StatelessWidget {
  const _DownloadsBadge({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final active =
        context.select<DownloadQueueProvider, int>((d) => d.activeCount);
    return Badge(
      isLabelVisible: active > 0,
      label: Text('$active'),
      child: child,
    );
  }
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        // Swipe sideways to change track, swipe up to open Now Playing.
        child: GestureDetector(
          onHorizontalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0;
            if (velocity < -300 && player.hasNext) {
              HapticFeedback.lightImpact();
              player.next();
            } else if (velocity > 300 && player.hasPrevious) {
              HapticFeedback.lightImpact();
              player.previous();
            }
          },
          onVerticalDragEnd: (details) {
            if ((details.primaryVelocity ?? 0) < -300) onOpen();
          },
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
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700),
                              ),
                              Text(
                                context.l10n.metadata(track.artist),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: player.playing
                              ? context.l10n.actionPause
                              : context.l10n.actionPlay,
                          onPressed: () => _tap(player.toggle),
                          icon: Icon(player.playing
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded),
                        ),
                        IconButton(
                          tooltip: context.l10n.actionNext,
                          onPressed:
                              player.hasNext ? () => _tap(player.next) : null,
                          icon: const Icon(Icons.skip_next_rounded),
                        ),
                      ],
                    ),
                  ),
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(24),
                    ),
                    child: ValueListenableBuilder<Duration>(
                      valueListenable: player.positionListenable,
                      builder: (context, position, _) =>
                          LinearProgressIndicator(
                        value: duration <= 0
                            ? 0.0
                            : (position.inMilliseconds / duration)
                                .clamp(0.0, 1.0),
                        minHeight: 3,
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Slides its child up into place each time its tab becomes visible, so
/// Now Playing seems to rise from the mini player.
class _RiseOnShow extends StatefulWidget {
  const _RiseOnShow({required this.visible, required this.child});
  final bool visible;
  final Widget child;

  @override
  State<_RiseOnShow> createState() => _RiseOnShowState();
}

class _RiseOnShowState extends State<_RiseOnShow>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
    value: widget.visible ? 1 : 0,
  );
  late final _curve =
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
  late final _offset =
      Tween(begin: const Offset(0, .12), end: Offset.zero).animate(_curve);

  @override
  void didUpdateWidget(_RiseOnShow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _curve,
        child: SlideTransition(position: _offset, child: widget.child),
      );
}

/// Playback buttons answer with a light tap, like system media controls.
void _tap(Future<void> Function() action) {
  HapticFeedback.lightImpact();
  action();
}

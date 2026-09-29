import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/appearance_provider.dart';
import '../providers/library_provider.dart';
import '../services/audio_access.dart';
import '../services/home_widget_service.dart';
import '../providers/sync_provider.dart';
import '../widgets/sync_sheet.dart';
import '../providers/player_provider.dart';
import '../services/playback_settings_service.dart';
import '../services/lyrics_service.dart';
import '../widgets/import_music_sheet.dart';
import '../l10n/l10n.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 190),
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF7043), Color(0xFFFFCA28)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.tune_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MUSICSTREAM',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          letterSpacing: 1.8,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  Text(
                    context.l10n.settingsTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 30),
          Text(
            context.l10n.settingsHeadline,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.6,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.settingsTagline,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 28),
          _SectionLabel(context.l10n.sectionAppearance),
          const SizedBox(height: 8),
          const _ThemeModeTile(),
          const SizedBox(height: 12),
          const _LanguageTile(),
          const SizedBox(height: 22),
          _SectionLabel(context.l10n.sectionLibrary),
          const SizedBox(height: 8),
          const _DeviceMediaTile(),
          const SizedBox(height: 14),
          _ActionCard(
            icon: Icons.library_add_rounded,
            colors: const [Color(0xFF7C4DFF), Color(0xFFEC407A)],
            title: context.l10n.enrichLibrary,
            subtitle: context.l10n.supportedFormats,
            actionLabel: context.l10n.importAction,
            onTap: () => showMusicImportSheet(context),
          ),
          const SizedBox(height: 26),
          _SectionLabel(context.l10n.sectionPlayback),
          const SizedBox(height: 8),
          const _FadeSettingsTile(),
          if (Platform.isAndroid) ...[
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.widgets_outlined),
              title: Text(context.l10n.homeWidget),
              subtitle: Text(context.l10n.homeWidgetHint),
              trailing: FilledButton.tonal(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final unsupported = context.l10n.homeWidgetUnsupported;
                  if (!await const HomeWidgetService().requestPin()) {
                    messenger.showSnackBar(
                      SnackBar(content: Text(unsupported)),
                    );
                  }
                },
                child: Text(context.l10n.homeWidgetAdd),
              ),
            ),
          ],
          const SizedBox(height: 26),
          _SectionLabel(context.l10n.sectionConnections),
          const SizedBox(height: 8),
          _InfoTile(
            icon: Icons.cloud_outlined,
            title: context.l10n.personalServers,
            subtitle: context.l10n.personalServersHint,
          ),
          Builder(builder: (context) {
            final sync = context.watch<SyncProvider>();
            return _InfoTile(
              icon: Icons.sync_lock_outlined,
              title: context.l10n.encryptedSync,
              subtitle: sync.enabled
                  ? syncStatusText(context, sync)
                  : context.l10n.encryptedSyncHint,
              badge: sync.enabled ? context.l10n.syncActive : null,
              onTap: () => showSyncSheet(context),
            );
          }),
          const SizedBox(height: 22),
          _SectionLabel(context.l10n.sectionPrivacy),
          const SizedBox(height: 8),
          const _AutomaticLyricsTile(),
          _InfoTile(
            icon: Icons.shield_outlined,
            title: context.l10n.localByDefault,
            subtitle: context.l10n.localByDefaultHint,
          ),
          _InfoTile(
            icon: Icons.offline_pin_rounded,
            title: context.l10n.availableOffline,
            subtitle: context.l10n.availableOfflineHint,
          ),
        ],
      );
}

class _ThemeModeTile extends StatelessWidget {
  const _ThemeModeTile();

  @override
  Widget build(BuildContext context) {
    final appearance = context.watch<AppearanceProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.palette_outlined),
          title: Text(context.l10n.theme),
          subtitle: Text(context.l10n.themeHint),
        ),
        SegmentedButton<ThemeMode>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: ThemeMode.system,
              label: Text(context.l10n.themeSystem),
            ),
            ButtonSegment(
              value: ThemeMode.light,
              label: Text(context.l10n.themeLight),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              label: Text(context.l10n.themeDark),
            ),
          ],
          selected: {appearance.themeMode},
          onSelectionChanged: (selection) =>
              appearance.setThemeMode(selection.single),
        ),
      ],
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile();

  @override
  Widget build(BuildContext context) {
    final appearance = context.watch<AppearanceProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.translate_rounded),
          title: Text(context.l10n.language),
          subtitle: Text(context.l10n.languageHint),
        ),
        SegmentedButton<String>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: '', label: Text(context.l10n.themeSystem)),
            // Language names stay in their own language.
            const ButtonSegment(value: 'fr', label: Text('Français')),
            const ButtonSegment(value: 'en', label: Text('English')),
          ],
          selected: {appearance.locale?.languageCode ?? ''},
          onSelectionChanged: (selection) => appearance.setLocale(
            selection.single.isEmpty ? null : Locale(selection.single),
          ),
        ),
      ],
    );
  }
}

class _DeviceMediaTile extends StatelessWidget {
  const _DeviceMediaTile();

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    final enabled = library.deviceMediaEnabled;
    final scanning = enabled && library.isImporting;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.phone_android_rounded),
          title: Text(context.l10n.deviceMedia),
          subtitle: Text(enabled
              ? scanning
                  ? context.l10n.deviceMediaScanning
                  : context.l10n.deviceMediaCount(library.deviceTrackCount)
              : context.l10n.deviceMediaHint),
          value: enabled,
          onChanged: library.isImporting || library.isDeleting
              ? null
              : (value) => _toggle(context, value),
        ),
        if (enabled)
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: TextButton.icon(
              onPressed: scanning ? null : () => _scan(context),
              icon: scanning
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
              label: Text(context.l10n.deviceMediaRescan),
            ),
          ),
      ],
    );
  }

  Future<void> _toggle(BuildContext context, bool value) async {
    final library = context.read<LibraryProvider>();
    if (!value) {
      await library.setDeviceMediaEnabled(false);
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    if (!await AudioAccess.request()) {
      messenger.showSnackBar(SnackBar(
        content: Text(l10n.deviceMediaPermission),
        action: SnackBarAction(
          label: l10n.openSettings,
          onPressed: AudioAccess.openSettings,
        ),
      ));
      return;
    }
    await library.setDeviceMediaEnabled(true);
    if (context.mounted) await _scan(context);
  }

  Future<void> _scan(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final summary = await context.read<LibraryProvider>().scanDeviceMedia();
    if (summary == null) return;
    messenger.showSnackBar(SnackBar(
      content: Text(l10n.deviceMediaSummary(summary.added, summary.removed)),
    ));
  }
}

class _AutomaticLyricsTile extends StatefulWidget {
  const _AutomaticLyricsTile();

  @override
  State<_AutomaticLyricsTile> createState() => _AutomaticLyricsTileState();
}

class _AutomaticLyricsTileState extends State<_AutomaticLyricsTile> {
  bool? _enabled;

  @override
  void initState() {
    super.initState();
    LyricsService.shared.automaticSearchPreference().then((value) {
      if (mounted) setState(() => _enabled = value ?? false);
    });
  }

  @override
  Widget build(BuildContext context) => SwitchListTile(
        title: Text(context.l10n.automaticLyrics),
        subtitle: Text(context.l10n.automaticLyricsHint),
        value: _enabled ?? false,
        onChanged: _enabled == null
            ? null
            : (value) async {
                await LyricsService.shared.setAutomaticSearch(value);
                if (mounted) setState(() => _enabled = value);
              },
      );
}

class _FadeSettingsTile extends StatelessWidget {
  const _FadeSettingsTile();

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainer
            .withValues(alpha: .56),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const CircleAvatar(child: Icon(Icons.multitrack_audio_rounded)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.fades,
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.fadesHint,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<Duration>(
              value: player.fadeDuration,
              borderRadius: BorderRadius.circular(16),
              onChanged: (duration) {
                if (duration != null) player.setFadeDuration(duration);
              },
              items: PlaybackSettingsService.supportedFadeDurations
                  .map(
                    (duration) => DropdownMenuItem(
                      value: duration,
                      child: Text(_fadeLabel(context, duration)),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _fadeLabel(BuildContext context, Duration duration) =>
      switch (duration.inMilliseconds) {
        0 => context.l10n.fadeOff,
        1000 => context.l10n.fadeSecond,
        final milliseconds => context.l10n.fadeMilliseconds(milliseconds),
      };
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.colors,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });

  final IconData icon;
  final List<Color> colors;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(30),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(gradient: LinearGradient(colors: colors)),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .16),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: .8),
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white),
                    const SizedBox(height: 3),
                    Text(
                      actionLabel,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.5,
              fontWeight: FontWeight.w900,
              color: Theme.of(context).colorScheme.primary,
            ),
      );
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badge,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Material(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainer
              .withValues(alpha: .56),
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
              child: Row(
                children: [
                  CircleAvatar(child: Icon(icon)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style:
                                const TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(subtitle,
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(badge!,
                          style: Theme.of(context).textTheme.labelSmall),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
}

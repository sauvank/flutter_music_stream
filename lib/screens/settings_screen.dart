import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/player_provider.dart';
import '../services/playback_settings_service.dart';
import '../services/lyrics_service.dart';
import '../widgets/import_music_sheet.dart';

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
                    'Réglages',
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
            'À votre rythme.',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.6,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Une bibliothèque privée, locale et prête à vous suivre.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 28),
          const _SectionLabel('LECTURE'),
          const SizedBox(height: 8),
          const _FadeSettingsTile(),
          const SizedBox(height: 22),
          _ActionCard(
            icon: Icons.library_add_rounded,
            colors: const [Color(0xFF7C4DFF), Color(0xFFEC407A)],
            title: 'Enrichir la bibliothèque',
            subtitle: 'MP3, M4A, AAC, FLAC, OGG, OPUS et WAV',
            actionLabel: 'Importer',
            onTap: () => showMusicImportSheet(context),
          ),
          const SizedBox(height: 26),
          const _SectionLabel('CONNEXIONS'),
          const SizedBox(height: 8),
          const _InfoTile(
            icon: Icons.cloud_outlined,
            title: 'Serveurs personnels',
            subtitle:
                'WebDAV et HTTP, avec identifiants dans le coffre système',
          ),
          const _InfoTile(
            icon: Icons.sync_lock_outlined,
            title: 'Synchronisation chiffrée',
            subtitle: 'Métadonnées uniquement, jamais vos fichiers audio',
            badge: 'Bientôt',
          ),
          const SizedBox(height: 22),
          const _SectionLabel('CONFIDENTIALITÉ'),
          const SizedBox(height: 8),
          const _AutomaticLyricsTile(),
          const _InfoTile(
            icon: Icons.shield_outlined,
            title: 'Local par défaut',
            subtitle: 'Aucun fichier, chemin local ou secret envoyé',
          ),
          const _InfoTile(
            icon: Icons.offline_pin_rounded,
            title: 'Disponible hors connexion',
            subtitle: 'Vos morceaux restent dans le stockage privé de l’app',
          ),
        ],
      );
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
        title: const Text('Paroles automatiques'),
        subtitle: const Text(
            'Pendant la lecture, envoie les métadonnées du morceau à LRCLIB si ses paroles ne sont pas déjà enregistrées.'),
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
                const Text(
                  'Fondus de lecture',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  'Adoucit lecture, pause et changements de morceau',
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
                      child: Text(_fadeLabel(duration)),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _fadeLabel(Duration duration) => switch (duration.inMilliseconds) {
        0 => 'Non',
        1000 => '1 s',
        final milliseconds => '$milliseconds ms',
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
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .surfaceContainer
                .withValues(alpha: .56),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              CircleAvatar(child: Icon(icon)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
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
      );
}

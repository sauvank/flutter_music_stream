import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';

import '../models/lyrics_document.dart';
import '../models/music_track.dart';
import '../providers/player_provider.dart';
import '../services/lyrics_service.dart';
import '../services/lyrics_translation_service.dart';

class LyricsSheet extends StatefulWidget {
  const LyricsSheet({super.key, required this.track, this.service});

  final MusicTrack track;
  final LyricsService? service;

  @override
  State<LyricsSheet> createState() => _LyricsSheetState();
}

class _LyricsSheetState extends State<LyricsSheet> {
  late final LyricsService _service;
  final ScrollController _scrollController = ScrollController();
  LyricsDocument? _lyrics;
  LyricsDocument? _translation;
  String? _translationLanguage;
  String? _message;
  bool _busy = true;
  bool _translating = false;
  int _lastActive = -2;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? LyricsService.shared;
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final lyrics = await _service.load(widget.track.id);
      if (!mounted) return;
      setState(() {
        _lyrics = lyrics;
        _busy = false;
      });
      if (lyrics != null) return;
      final automatic = await _service.automaticSearchPreference();
      if (!mounted) return;
      if (automatic == true) {
        await _search();
      } else if (automatic == null) {
        final accepted = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Trouver les paroles automatiquement ?'),
            content: const Text(
              'Pour les morceaux sans paroles enregistrées, '
              'MusicStream enverra son titre, son artiste, son album et sa '
              'durée à LRCLIB dès leur lecture. Ce choix reste modifiable '
              'dans Réglages.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Pas maintenant'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Activer'),
              ),
            ],
          ),
        );
        if (!mounted) return;
        await _service.setAutomaticSearch(accepted == true);
        if (accepted == true && mounted) await _search();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _message = 'Impossible de lire les paroles enregistrées.';
        _busy = false;
      });
    }
  }

  Future<void> _import() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final imported = await _service.importFile(widget.track.id);
      if (!mounted) return;
      if (imported) {
        _lyrics = await _service.load(widget.track.id);
        _translation = null;
        _translationLanguage = null;
        _lastActive = -2;
      }
    } on FormatException catch (error) {
      _message = error.message;
    } catch (_) {
      _message = 'Impossible d’importer ce fichier .lrc.';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _search() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final lyrics = await _service.searchOnline(widget.track);
      if (!mounted) return;
      if (lyrics == null) {
        _message = 'Aucune parole trouvée sur LRCLIB.';
      } else {
        _lyrics = lyrics;
        _translation = null;
        _translationLanguage = null;
        _lastActive = -2;
      }
    } on LyricsRateLimitException catch (error) {
      _message = error.toString();
    } on FormatException catch (error) {
      _message = error.message;
    } catch (_) {
      _message = 'Recherche impossible. Vérifiez la connexion et réessayez.';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _chooseTranslation() async {
    final language = await showModalBottomSheet<MapEntry<String, String>>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          children: [
            const ListTile(
              title: Text('Traduire les paroles'),
              subtitle: Text('Les paroles seront envoyées à MyMemory. '
                  'La traduction sera gardée sur cet appareil.'),
            ),
            for (final entry in LyricsTranslationService.languages.entries)
              ListTile(
                title: Text(entry.key),
                onTap: () => Navigator.pop(context, entry),
              ),
          ],
        ),
      ),
    );
    if (language == null || !mounted || _lyrics == null) return;
    setState(() {
      _translating = true;
      _message = null;
    });
    try {
      final original = _lyrics!;
      final translated = await LyricsTranslationService.shared
          .translate(widget.track.id, original, language.value);
      if (!mounted || !identical(_lyrics, original)) return;
      setState(() {
        _translation = translated;
        _translationLanguage = language.key;
        _lastActive = -2;
      });
    } on FormatException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } on DioException catch (error) {
      if (mounted) {
        setState(() => _message = error.response?.statusCode == 429
            ? 'MyMemory limite temporairement les traductions. Réessayez plus tard.'
            : 'Traduction impossible (réseau ou service indisponible).');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _message =
            'Traduction impossible. Vérifiez la connexion et réessayez.');
      }
    } finally {
      if (mounted) setState(() => _translating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final displayed = _translation ?? _lyrics;
    final active = player.current?.id == widget.track.id
        ? displayed?.activeLineAt(player.position) ?? -1
        : -1;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Column(
          children: [
            Text(
              'Paroles de ${widget.track.title}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _busy || _translating ? null : _import,
                  icon: const Icon(Icons.upload_file_rounded),
                  label: const Text('Importer .lrc'),
                ),
                FilledButton.tonalIcon(
                  onPressed: _busy || _translating ? null : _search,
                  icon: const Icon(Icons.travel_explore_rounded),
                  label: const Text('Relancer la recherche'),
                ),
                if (_lyrics != null)
                  OutlinedButton.icon(
                    onPressed:
                        _busy || _translating ? null : _chooseTranslation,
                    icon: const Icon(Icons.translate_rounded),
                    label: const Text('Traduire'),
                  ),
                if (_translation != null)
                  TextButton(
                    onPressed: () => setState(() {
                      _translation = null;
                      _translationLanguage = null;
                    }),
                    child: const Text('Original'),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _translationLanguage == null
                  ? 'La recherche envoie le titre, l’artiste, l’album et la durée à LRCLIB.'
                  : 'Traduction : $_translationLanguage',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_message!, textAlign: TextAlign.center),
              ),
            const SizedBox(height: 12),
            Expanded(
              child: _busy || _translating
                  ? const Center(child: CircularProgressIndicator())
                  : displayed == null
                      ? const Center(
                          child: Text(
                            'Aucune parole trouvée. Importez un fichier .lrc ou relancez la recherche.',
                            textAlign: TextAlign.center,
                          ),
                        )
                      : displayed.synchronized
                          ? LayoutBuilder(
                              builder: (context, constraints) => _timedLyrics(
                                context,
                                displayed,
                                active,
                                constraints.maxHeight,
                              ),
                            )
                          : SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  displayed.plainText,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(height: 1.65),
                                ),
                              ),
                            ),
            ),
            if (_lyrics != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _lyrics!.synchronized
                      ? 'Synchronisées avec la lecture • touchez une ligne pour avancer'
                      : 'Paroles non synchronisées',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _timedLyrics(BuildContext context, LyricsDocument displayed,
      int active, double viewportHeight) {
    if (active != _lastActive) {
      _lastActive = active;
      if (active >= 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_scrollController.hasClients) return;
          final target = active * 72.0 - viewportHeight / 2 + 36;
          _scrollController.animateTo(
            target.clamp(0, _scrollController.position.maxScrollExtent),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      }
    }
    return ListView.builder(
      controller: _scrollController,
      itemCount: displayed.lines.length,
      itemExtent: 72,
      itemBuilder: (context, index) {
        final line = displayed.lines[index];
        final selected = index == active;
        return InkWell(
          onTap: () => context.read<PlayerProvider>().seek(line.time),
          child: Center(
            child: Text(
              line.text.isEmpty ? '♪' : line.text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w500,
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        );
      },
    );
  }
}

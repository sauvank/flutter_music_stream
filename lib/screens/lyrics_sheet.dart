import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/lyrics_document.dart';
import '../models/music_track.dart';
import '../providers/player_provider.dart';
import '../services/lyrics_service.dart';

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
  String? _message;
  bool _busy = true;
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

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final active = player.current?.id == widget.track.id
        ? _lyrics?.activeLineAt(player.position) ?? -1
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
                  onPressed: _busy ? null : _import,
                  icon: const Icon(Icons.upload_file_rounded),
                  label: const Text('Importer .lrc'),
                ),
                FilledButton.tonalIcon(
                  onPressed: _busy ? null : _search,
                  icon: const Icon(Icons.travel_explore_rounded),
                  label: const Text('Chercher sur LRCLIB'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'La recherche envoie le titre, l’artiste, l’album et la durée à LRCLIB.',
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
              child: _busy
                  ? const Center(child: CircularProgressIndicator())
                  : _lyrics == null
                      ? const Center(
                          child: Text(
                            'Importez un fichier .lrc ou lancez une recherche sur LRCLIB.',
                            textAlign: TextAlign.center,
                          ),
                        )
                      : _lyrics!.synchronized
                          ? LayoutBuilder(
                              builder: (context, constraints) => _timedLyrics(
                                context,
                                active,
                                constraints.maxHeight,
                              ),
                            )
                          : SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  _lyrics!.plainText,
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

  Widget _timedLyrics(BuildContext context, int active, double viewportHeight) {
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
      itemCount: _lyrics!.lines.length,
      itemExtent: 72,
      itemBuilder: (context, index) {
        final line = _lyrics!.lines[index];
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

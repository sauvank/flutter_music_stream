import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';

import '../models/lyrics_document.dart';
import '../models/music_track.dart';
import '../providers/player_provider.dart';
import '../services/lyrics_service.dart';
import '../services/lyrics_translation_service.dart';
import '../l10n/l10n.dart';

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
            title: Text(context.l10n.lyricsAutoTitle),
            content: Text(context.l10n.lyricsAutoBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(context.l10n.notNow),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(context.l10n.enable),
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
        _message = context.l10n.lyricsReadFailed;
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
    } on FormatException {
      if (mounted) _message = context.l10n.lyricsImportEmpty;
    } catch (_) {
      if (mounted) _message = context.l10n.lyricsImportFailed;
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
        _message = context.l10n.lyricsNotFoundOnline;
      } else {
        _lyrics = lyrics;
        _translation = null;
        _translationLanguage = null;
        _lastActive = -2;
      }
    } on LyricsRateLimitException catch (error) {
      if (mounted) _message = _rateLimitMessage(error);
    } on FormatException {
      if (mounted) _message = context.l10n.lyricsMissingMetadata;
    } catch (_) {
      if (mounted) _message = context.l10n.lyricsSearchFailed;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _rateLimitMessage(LyricsRateLimitException error) {
    final l10n = context.l10n;
    final seconds = int.tryParse(error.retryAfter ?? '');
    if (seconds != null) return l10n.lyricsRateLimitSeconds(seconds);
    return error.retryAfter == null
        ? l10n.lyricsRateLimitLater
        : l10n.lyricsRateLimitAfter(error.retryAfter!);
  }

  Future<void> _chooseTranslation() async {
    final language = await showModalBottomSheet<MapEntry<String, String>>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          children: [
            ListTile(
              title: Text(context.l10n.translateLyricsTitle),
              subtitle: Text(context.l10n.translateLyricsHint),
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
    } on FormatException {
      if (mounted) {
        setState(() => _message = context.l10n.translationLineTooLong);
      }
    } on DioException catch (error) {
      if (mounted) {
        setState(() => _message = error.response?.statusCode == 429
            ? context.l10n.translationRateLimited
            : context.l10n.translationUnavailable);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _message = context.l10n.translationFailed);
      }
    } finally {
      if (mounted) setState(() => _translating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCurrent = context.select<PlayerProvider, bool>(
      (player) => player.current?.id == widget.track.id,
    );
    final displayed = _translation ?? _lyrics;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Column(
          children: [
            Text(
              context.l10n.lyricsOf(widget.track.title),
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
                  label: Text(context.l10n.importLrc),
                ),
                FilledButton.tonalIcon(
                  onPressed: _busy || _translating ? null : _search,
                  icon: const Icon(Icons.travel_explore_rounded),
                  label: Text(context.l10n.searchAgain),
                ),
                if (_lyrics != null)
                  OutlinedButton.icon(
                    onPressed:
                        _busy || _translating ? null : _chooseTranslation,
                    icon: const Icon(Icons.translate_rounded),
                    label: Text(context.l10n.translate),
                  ),
                if (_translation != null)
                  TextButton(
                    onPressed: () => setState(() {
                      _translation = null;
                      _translationLanguage = null;
                    }),
                    child: Text(context.l10n.original),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _translationLanguage == null
                  ? context.l10n.lyricsPrivacyHint
                  : context.l10n.translationLanguage(_translationLanguage!),
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
                      ? Center(
                          child: Text(
                            context.l10n.lyricsEmpty,
                            textAlign: TextAlign.center,
                          ),
                        )
                      : displayed.synchronized
                          ? LayoutBuilder(
                              builder: (context, constraints) =>
                                  ValueListenableBuilder<Duration>(
                                valueListenable: context
                                    .read<PlayerProvider>()
                                    .positionListenable,
                                builder: (context, position, _) => _timedLyrics(
                                  context,
                                  displayed,
                                  isCurrent
                                      ? displayed.activeLineAt(position)
                                      : -1,
                                  constraints.maxHeight,
                                ),
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
                      ? context.l10n.lyricsSynchronized
                      : context.l10n.lyricsUnsynchronized,
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/music_track.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../providers/sync_provider.dart';

enum _PositionChoice { ignore, keepLocal, useRemote }

/// Starts [track], first offering to resume from another device when an
/// audiobook has a newer synced position there.
Future<void> playWithPositionCheck(
  BuildContext context,
  MusicTrack track,
  List<MusicTrack> queue,
) async {
  final library = context.read<LibraryProvider>();
  final player = context.read<PlayerProvider>();
  final sync = context.read<SyncProvider?>();
  var start = track;
  final proposal =
      track.isAudiobook ? await sync?.positionProposal(track) : null;
  if (proposal != null && context.mounted) {
    final choice = await _ask(context, track, proposal);
    switch (choice) {
      case _PositionChoice.useRemote:
        await sync!.adoptRemotePosition(track.id, proposal);
        start = library.trackById(track.id) ?? track;
      case _PositionChoice.keepLocal:
        await sync!.keepLocalPosition(track.id);
      case _PositionChoice.ignore:
        break;
    }
  }
  final index = queue.indexWhere((item) => item.id == track.id);
  final updated = [...queue];
  if (index >= 0) updated[index] = start;
  await player.playTrack(start, updated);
}

Future<_PositionChoice> _ask(
  BuildContext context,
  MusicTrack track,
  PositionProposal proposal,
) async {
  final l10n = context.l10n;
  final material = MaterialLocalizations.of(context);
  String date(DateTime? value) {
    if (value == null) return l10n.syncPositionNoDate;
    final local = value.toLocal();
    return '${material.formatMediumDate(local)} '
        '${material.formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
  }

  String clock(int ms) {
    final value = Duration(milliseconds: ms);
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    return '${value.inHours}:$minutes:$seconds';
  }

  final choice = await showDialog<_PositionChoice>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.syncPositionTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.syncPositionBody(track.title)),
          const SizedBox(height: 16),
          Text(l10n.syncPositionRemote(
              clock(proposal.remoteMs), date(proposal.remoteAt))),
          const SizedBox(height: 8),
          Text(l10n.syncPositionLocal(
              clock(proposal.localMs), date(proposal.localAt))),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(dialogContext).pop(_PositionChoice.ignore),
          child: Text(l10n.syncPositionIgnore),
        ),
        OutlinedButton(
          onPressed: () =>
              Navigator.of(dialogContext).pop(_PositionChoice.keepLocal),
          child: Text(l10n.syncPositionKeepLocal),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(dialogContext).pop(_PositionChoice.useRemote),
          child: Text(l10n.syncPositionUseRemote),
        ),
      ],
    ),
  );
  return choice ?? _PositionChoice.ignore;
}

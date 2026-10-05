import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/music_track.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../providers/sync_provider.dart';

enum _PositionChoice { ignore, keepLocal, useRemote }

/// Offers to resume from another device when [track], an audiobook, has a
/// newer synced position there. Returns the track with the chosen position.
Future<MusicTrack> resolveAudiobookPosition(
  BuildContext context,
  MusicTrack track,
) async {
  final library = context.read<LibraryProvider>();
  final sync = context.read<SyncProvider?>();
  if (!track.isAudiobook || sync == null) return track;
  // The queue's copy of the track keeps the position it was loaded with.
  track = library.trackById(track.id) ?? track;
  final proposal = await sync.positionProposal(track);
  if (proposal == null) return track;
  if (!context.mounted) return track;
  final choice = await _ask(context, track, proposal);
  switch (choice) {
    case _PositionChoice.useRemote:
      await sync.adoptRemotePosition(track.id, proposal);
      return library.trackById(track.id) ?? track;
    case _PositionChoice.keepLocal:
      await sync.keepLocalPosition(track.id);
    case _PositionChoice.ignore:
      break;
  }
  return track;
}

/// Starts [track], first resolving a conflicting synced audiobook position.
Future<void> playWithPositionCheck(
  BuildContext context,
  MusicTrack track,
  List<MusicTrack> queue,
) async {
  final player = context.read<PlayerProvider>();
  final start = await resolveAudiobookPosition(context, track);
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

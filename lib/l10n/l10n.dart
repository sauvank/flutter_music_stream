import 'package:flutter/widgets.dart';

import '../models/music_track.dart';
import 'generated/app_localizations.dart';

export 'generated/app_localizations.dart';

extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

extension StoredMetadataLabels on AppLocalizations {
  /// Translates the placeholders stored for tracks with missing tags.
  String metadata(String value) => switch (value) {
        MusicTrack.unknownArtist => unknownArtist,
        MusicTrack.unknownAlbum => unknownAlbum,
        MusicTrack.unknownGenre => unknownGenre,
        MusicTrack.untitled => untitledTrack,
        _ => value,
      };
}

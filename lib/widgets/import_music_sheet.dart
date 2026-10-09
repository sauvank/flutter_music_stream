import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/library_provider.dart';
import '../screens/home_screen.dart';
import '../services/audio_access.dart';
import '../l10n/l10n.dart';

enum _ImportSource { device, files, directory, server }

Future<void> showMusicImportSheet(BuildContext context) async {
  final library = context.read<LibraryProvider>();
  final source = await showModalBottomSheet<_ImportSource>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Text(
                context.l10n.importSheetTitle,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            // The phone's own music needs no copy and no picker: offered first.
            if (Platform.isAndroid)
              ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.phone_android_rounded),
                ),
                title: Text(context.l10n.importDeviceMedia),
                subtitle: Text(library.deviceMediaEnabled
                    ? context.l10n.importDeviceMediaEnabled
                    : context.l10n.deviceMediaHint),
                onTap: () => Navigator.pop(context, _ImportSource.device),
              ),
            ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.audio_file_rounded),
              ),
              title: Text(context.l10n.importChooseFiles),
              subtitle: Text(context.l10n.importChooseFilesHint),
              onTap: () => Navigator.pop(context, _ImportSource.files),
            ),
            ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.folder_copy_rounded),
              ),
              title: Text(context.l10n.importChooseFolder),
              subtitle: Text(context.l10n.importChooseFolderHint),
              onTap: () => Navigator.pop(context, _ImportSource.directory),
            ),
            ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.cloud_rounded),
              ),
              title: Text(context.l10n.importFromServer),
              subtitle: Text(context.l10n.importFromServerHint),
              onTap: () => Navigator.pop(context, _ImportSource.server),
            ),
          ],
        ),
      ),
    ),
  );
  if (source == null || !context.mounted) return;
  switch (source) {
    case _ImportSource.device:
      return library.deviceMediaEnabled
          ? scanDeviceMedia(context)
          : enableDeviceMedia(context);
    case _ImportSource.server:
      return HomeScreen.openServers(context);
    case _ImportSource.files:
    case _ImportSource.directory:
  }
  final messenger = ScaffoldMessenger.of(context);
  final l10n = context.l10n;
  if (source == _ImportSource.directory && !await AudioAccess.request()) {
    messenger.showSnackBar(SnackBar(
      content: Text(l10n.audioPermissionDenied),
      action: SnackBarAction(
        label: l10n.openSettings,
        onPressed: AudioAccess.openSettings,
      ),
    ));
    return;
  }
  try {
    final summary = source == _ImportSource.files
        ? await library.importFiles()
        : await library.importDirectory(dialogTitle: l10n.pickMusicFolder);
    if (summary == null) return;
    messenger.showSnackBar(
        SnackBar(content: Text(importSummaryText(l10n, summary))));
  } catch (_) {
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.importFailed)),
    );
  }
}

String importSummaryText(AppLocalizations l10n, LocalImportSummary summary) {
  final parts = [
    l10n.importAdded(summary.added),
    if (summary.skipped > 0) l10n.importSkipped(summary.skipped),
    if (summary.failed > 0) l10n.importFailures(summary.failed),
  ];
  return parts.join(' · ');
}

/// Turns on the phone's media library, asking for audio access, then scans.
Future<void> enableDeviceMedia(BuildContext context) async {
  final library = context.read<LibraryProvider>();
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
  if (context.mounted) await scanDeviceMedia(context);
}

Future<void> scanDeviceMedia(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = context.l10n;
  final summary = await context.read<LibraryProvider>().scanDeviceMedia();
  if (summary == null) return;
  messenger.showSnackBar(SnackBar(
    content: Text(l10n.deviceMediaSummary(summary.added, summary.removed)),
  ));
}

class RemoteAudioEntry {
  const RemoteAudioEntry({
    required this.name,
    required this.uri,
    required this.isDirectory,
    this.size,
  });

  final String name;
  final Uri uri;
  final bool isDirectory;
  final int? size;
}

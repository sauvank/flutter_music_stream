class RemoteAudioMetadata {
  const RemoteAudioMetadata({
    required this.title,
    required this.artist,
    this.album,
    this.artworkPath,
  });

  final String title;
  final String artist;
  final String? album;
  final String? artworkPath;
}

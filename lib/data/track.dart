/// One playable track: bundled with the app or picked from the device.
class Track {
  const Track({required this.title, required this.path, this.isAsset = true});

  final String title;

  /// An asset path ('assets/audio/test.mp3') or an absolute file path.
  final String path;
  final bool isAsset;
}

/// Tracks bundled with the app. Real, licensed tracks replace these later.
const bundledTracks = <Track>[
  Track(title: 'Test track 1', path: 'assets/audio/test.mp3'),
  Track(title: 'Test track 2', path: 'assets/audio/test2.mp3'),
];
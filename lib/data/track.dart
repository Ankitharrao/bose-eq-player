/// One playable track: bundled with the app or picked from the device.
class Track {
  const Track({required this.title, required this.path, this.isAsset = true});

  final String title;

  /// An asset path ('assets/audio/test.mp3') or, for a device track, the
  /// original file's content:// URI.
  final String path;
  final bool isAsset;
}

/// Tracks bundled with the app. "Three Bands" is original, synthesized by
/// `tool/make_demo_track.py` and public domain (CC0), so it is safe to ship.
/// Its kick and bass, chords, and hats and bells sit in the Low, Mid and High
/// bands, so each slider is easy to hear.
const bundledTracks = <Track>[
  Track(title: 'Three Bands', path: 'assets/audio/three_bands.m4a'),
];

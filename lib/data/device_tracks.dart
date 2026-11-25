import 'package:file_picker/file_picker.dart';

import 'track.dart';

/// Opens the system file picker for audio files and returns them as tracks.
/// Returns an empty list if the user cancels.
///
/// On Android the picker copies each chosen file into the app's cache and
/// returns that copy's path, so no storage permission is needed. Copies last
/// for the app session; picked tracks are not remembered across restarts.
Future<List<Track>> pickDeviceTracks() async {
  final files = await FilePicker.pickFiles(type: FileType.audio);
  return [
    for (final file in files)
      if (file.path case final path?)
        Track(title: _titleFrom(file.name), path: path, isAsset: false),
  ];
}

/// "My Song.final.mp3" -> "My Song.final"
String _titleFrom(String fileName) {
  final dot = fileName.lastIndexOf('.');
  return dot > 0 ? fileName.substring(0, dot) : fileName;
}

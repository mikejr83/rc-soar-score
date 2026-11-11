import 'dart:typed_data';

/// The web build has no embedded server to make a contest file, and the import
/// journeys are native-only and never run here (see
/// `exchange_files_native.dart`).
Future<Uint8List> contestFromAnotherInstallation(String name) async =>
    Uint8List(0);

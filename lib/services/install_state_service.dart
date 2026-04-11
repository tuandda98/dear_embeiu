import 'dart:io';

import 'package:path_provider/path_provider.dart';

class InstallStateService {
  InstallStateService({
    Future<Directory> Function()? markerDirectoryProvider,
  }) : _markerDirectoryProvider =
           markerDirectoryProvider ?? getApplicationSupportDirectory;

  static const String _markerFileName = '.app_install_marker';

  final Future<Directory> Function() _markerDirectoryProvider;

  Future<bool> handleFreshInstall({
    required Future<void> Function() onFreshInstall,
  }) async {
    final markerFile = await _getMarkerFile();
    if (await markerFile.exists()) {
      return false;
    }

    await onFreshInstall();
    await markerFile.parent.create(recursive: true);
    await markerFile.writeAsString(DateTime.now().toIso8601String());
    return true;
  }

  Future<File> _getMarkerFile() async {
    final directory = await _markerDirectoryProvider();
    return File('${directory.path}/$_markerFileName');
  }
}


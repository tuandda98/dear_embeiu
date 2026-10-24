import 'dart:io';

import 'package:path_provider/path_provider.dart';

class InstallStateService {
  InstallStateService({
    Future<Directory> Function()? markerDirectoryProvider,
  }) : _markerDirectoryProvider =
           markerDirectoryProvider ?? getApplicationSupportDirectory;

  static const String _markerFileName = '.app_install_marker';

  /// True for the whole process when THIS launch created the install marker
  /// (brand-new install / reinstall). Set by main() right after
  /// [handleFreshInstall]; lets features tell "fresh install" apart from
  /// "upgraded from a build that didn't have my flag yet" (feature tour).
  static bool isFreshInstallLaunch = false;

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


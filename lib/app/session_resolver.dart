import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/couple_provider.dart';
import '../providers/photo_provider.dart';
import 'app_routes.dart';

/// Decides where a just-launched (or just-authenticated) user should land:
/// initialises auth, loads couple + photo state, then returns the target route.
///
/// Pure async work — it never touches [Navigator] or `mounted`, so the caller
/// stays in control of navigation. Providers are read synchronously up front,
/// before the first `await`, so it is safe to call across async gaps.
class SessionResolver {
  const SessionResolver._();

  static Future<String> resolveStartRoute(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final coupleProvider = context.read<CoupleProvider>();
    final photoProvider = context.read<PhotoProvider>();

    if (!authProvider.isInitialized) {
      await authProvider.initialize();
    }

    if (!authProvider.isAuthenticated) {
      await photoProvider.clearForSignOut();
      return AppRoutes.guest;
    }

    final currentUser = authProvider.currentUser;
    await coupleProvider.loadCoupleForUser(currentUser);
    final hasCoupleData =
        currentUser?.hasCouple == true && coupleProvider.hasCoupleData;

    if (hasCoupleData) {
      await photoProvider.syncForUser(currentUser);
    } else {
      await photoProvider.clearForSignOut();
    }

    return hasCoupleData ? AppRoutes.home : AppRoutes.setup;
  }
}

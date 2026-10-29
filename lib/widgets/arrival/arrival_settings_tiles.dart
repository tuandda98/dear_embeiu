import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../providers/arrival_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/couple_provider.dart';
import '../../services/notification_settings_service.dart';
import '../../services/push_notification_service.dart';
import '../../theme/app_colors.dart';
import '../icon_badge.dart';
import 'arrival_format.dart';

// Settings rows of feature arrival (design §7): Thông báo → "Khi người ấy
// đến nơi", Chung → "Về đến nhà" subtitle.

/// "Đang báo cho Thảo: Nhà và 2 nơi khác" · "Đang tắt" · "Tạm thời chỉ báo
/// bằng tay" (design §7).
String arrivalSettingsSubtitle(BuildContext context) {
  final l10n = context.l10n;
  final arrival = context.read<ArrivalProvider>();
  if (!arrival.myShare) return l10n.arrivalSettingsOff;
  if (arrival.autoRemoteOff) return l10n.arrivalMineRemoteOff;
  final couple = context.read<CoupleProvider>().couple;
  final partner = couple == null
      ? l10n.reactionPartnerFallback
      : ArrivalFormat.partnerName(
          l10n,
          couple,
          context.read<AuthProvider>().currentUser?.id,
        );
  return l10n.arrivalSettingsSharing(
    partner,
    ArrivalFormat.places(l10n, arrival.places),
  );
}

/// "Khi người ấy đến nơi" — `pushArrival` on this device's doc (D16). Mute
/// only stops the push; the Home card still updates.
class ArrivalPushTile extends StatefulWidget {
  const ArrivalPushTile({super.key, this.load, this.save});

  /// Test seams; default = `NotificationSettingsService` + re-register the
  /// device so the CF sees the new `pushArrival`.
  final Future<bool> Function()? load;
  final Future<void> Function(bool value)? save;

  @override
  State<ArrivalPushTile> createState() => _ArrivalPushTileState();
}

class _ArrivalPushTileState extends State<ArrivalPushTile> {
  bool _enabled = true;

  @override
  void initState() {
    super.initState();
    (widget.load ?? NotificationSettingsService.instance.arrivalPushEnabled)()
        .then((v) {
          if (mounted) setState(() => _enabled = v);
        });
  }

  Future<void> _onChanged(bool value) async {
    HapticFeedback.selectionClick();
    setState(() => _enabled = value);
    final save = widget.save;
    if (save != null) {
      await save(value);
      return;
    }
    await NotificationSettingsService.instance.set(
      NotificationSettingsService.keyArrival,
      value,
    );
    await PushNotificationService.instance.refreshDeviceRegistration();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final couple = context.watch<CoupleProvider>().couple;
    final partner = couple == null
        ? l10n.reactionPartnerFallback
        : ArrivalFormat.partnerName(
            l10n,
            couple,
            context.read<AuthProvider>().currentUser?.id,
          );
    return SwitchListTile.adaptive(
      key: const ValueKey('arrival-push-switch'),
      value: _enabled,
      onChanged: _onChanged,
      activeThumbColor: AppColors.accentRose,
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      secondary: const IconBadge(IconsaxPlusLinear.home_2),
      title: Text(
        l10n.arrivalSettingsPushTitle,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          l10n.arrivalSettingsPushSub(partner),
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

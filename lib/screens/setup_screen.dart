import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../app/app_routes.dart';
import '../l10n/l10n.dart';
import '../providers/auth_provider.dart';
import '../providers/couple_provider.dart';
import '../providers/photo_provider.dart';
import '../models/couple.dart';
import '../services/couple_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/blocking_loading_overlay.dart';
import '../widgets/content_card.dart';
import '../widgets/eyebrow_chip.dart';
import '../widgets/glass_card.dart';
import '../widgets/invite_action_buttons.dart';
import '../widgets/love_lottie.dart';
import '../widgets/shared_couple_photo_view.dart';

enum _SetupMode { create, join }

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  late final TextEditingController _person1Controller;
  late final TextEditingController _person2Controller;
  late final TextEditingController _inviteCodeController;

  DateTime? _selectedDate;
  String? _couplePhotoPath;
  bool _didPrefill = false;
  _SetupMode _mode = _SetupMode.create;

  @override
  void initState() {
    super.initState();
    _person1Controller = TextEditingController();
    _person2Controller = TextEditingController();
    _inviteCodeController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrefill) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final coupleProvider = context.read<CoupleProvider>();
    final currentUser = authProvider.currentUser;
    final existingCouple = coupleProvider.couple;

    if (existingCouple != null) {
      _person1Controller.text = existingCouple.person1Name;
      _person2Controller.text = existingCouple.person2Name;
      _selectedDate = existingCouple.anniversaryDate;
      _couplePhotoPath = existingCouple.couplePhotoPath;
    } else {
      if (currentUser != null && currentUser.displayName.trim().isNotEmpty) {
        _person1Controller.text = currentUser.displayName.trim();
      }
      // Carry the love date the user already set in guest mode into the very
      // first couple they create, so the single-player → account funnel doesn't
      // make them re-pick it. Best-effort & purely local: ignore any read miss.
      _selectedDate ??= _readGuestAnniversary();
    }

    _didPrefill = true;
  }

  @override
  void dispose() {
    _person1Controller.dispose();
    _person2Controller.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  /// Reads the anniversary the user picked in guest mode (Hive `guest_settings`,
  /// key `anniversary` as ms-since-epoch). Synchronous & guarded: only when the
  /// guest box is already open (it is whenever the user passed through the guest
  /// landing); returns null otherwise so cold-starting straight into setup is
  /// unaffected. Keep these keys in sync with [GuestCounterScreen].
  DateTime? _readGuestAnniversary() {
    const boxName = 'guest_settings';
    const anniversaryKey = 'anniversary';
    if (!Hive.isBoxOpen(boxName)) {
      return null;
    }
    final millis = Hive.box(boxName).get(anniversaryKey);
    return millis is int
        ? DateTime.fromMillisecondsSinceEpoch(millis)
        : null;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().subtract(const Duration(days: 365)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (!mounted || picked == null) {
      return;
    }

    HapticFeedback.selectionClick();
    setState(() => _selectedDate = picked);
  }

  Future<void> _pickPhoto() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 92,
    );

    if (!mounted || pickedFile == null) {
      return;
    }

    setState(() => _couplePhotoPath = pickedFile.path);
  }

  Future<void> _submitCreateOrUpdate() async {
    HapticFeedback.lightImpact();
    final authProvider = context.read<AuthProvider>();
    final coupleProvider = context.read<CoupleProvider>();
    final photoProvider = context.read<PhotoProvider>();
    final currentUser = authProvider.currentUser;
    final existingCouple = coupleProvider.couple;
    final isEditing = currentUser?.hasCouple == true && existingCouple != null;
    final l10n = context.l10n;

    if (currentUser == null) {
      HapticFeedback.heavyImpact();
      _showSnack(l10n.setupErrorNoAccount);
      return;
    }

    final person1 = _person1Controller.text.trim();
    final person2 = _person2Controller.text.trim();
    if (person1.isEmpty || person2.isEmpty || _selectedDate == null) {
      HapticFeedback.heavyImpact();
      _showSnack(l10n.setupErrorFillRequired);
      return;
    }

    if (isEditing && !_hasPendingChanges(existingCouple, person1, person2, _selectedDate!)) {
      _showSnack(l10n.setupNoChangesToSaveMsg);
      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.pop();
      }
      return;
    }

    try {
      final navigator = Navigator.of(context);
      final CoupleActionResult result = isEditing
          ? await coupleProvider.updateCouple(
              currentUser: currentUser,
              person1: person1,
              person2: person2,
              anniversary: _selectedDate!,
              photoPath: _couplePhotoPath,
            )
          : await coupleProvider.createCouple(
              currentUser: currentUser,
              person1: person1,
              person2: person2,
              anniversary: _selectedDate!,
              photoPath: _couplePhotoPath,
            );

      if (!isEditing) {
        await authProvider.updateCurrentUser(result.updatedUser);
        await photoProvider.syncForUser(result.updatedUser);
      }

      if (!mounted) {
        return;
      }

      if (!isEditing) {
        await _showInviteCodeDialog(
          result.couple.coupleCode ?? result.updatedUser.inviteCode,
        );
        if (result.warningMessage != null && mounted) {
          _showSnack(result.warningMessage!);
        }
        // A brand-new couple: route through the auth gate so SessionResolver
        // wires the realtime couple watch + love-note / daily-question /
        // reaction / streak watchers. Going straight to /home skipped all that,
        // so the creator never saw their partner join (couple stayed
        // waiting_partner, the invite code stayed stuck on Home, and notes
        // couldn't sync) until a manual app restart.
        navigator.pushNamedAndRemoveUntil(AppRoutes.authGate, (route) => false);
      } else {
        // Editing is membership-neutral (the realtime watchers are already
        // wired from the live session) — just return to wherever opened setup.
        _showSnack(_resolveCoupleResultMessage(result));
        if (navigator.canPop()) {
          navigator.pop();
        } else {
          navigator.pushReplacementNamed(AppRoutes.home);
        }
      }
    } on CoupleException catch (e) {
      _showSnack(e.message);
    } catch (e) {
      if (!mounted) return;
      _showSnack(context.l10n.setupErrorSaveCouple('$e'));
    }
  }

  bool _hasPendingChanges(
    Couple existing,
    String person1,
    String person2,
    DateTime anniversary,
  ) {
    if (person1 != existing.person1Name.trim()) return true;
    if (person2 != existing.person2Name.trim()) return true;
    if (anniversary.year != existing.anniversaryDate.year ||
        anniversary.month != existing.anniversaryDate.month ||
        anniversary.day != existing.anniversaryDate.day) {
      return true;
    }
    if ((_couplePhotoPath ?? '') != (existing.couplePhotoPath ?? '')) return true;
    return false;
  }

  Future<void> _submitJoin() async {
    HapticFeedback.lightImpact();
    final authProvider = context.read<AuthProvider>();
    final coupleProvider = context.read<CoupleProvider>();
    final photoProvider = context.read<PhotoProvider>();
    final currentUser = authProvider.currentUser;
    final l10n = context.l10n;

    if (currentUser == null) {
      HapticFeedback.heavyImpact();
      _showSnack(l10n.setupErrorNoAccountShort);
      return;
    }

    final inviteCode = _inviteCodeController.text.trim();
    if (inviteCode.isEmpty) {
      HapticFeedback.heavyImpact();
      _showSnack(l10n.setupErrorNoInviteCode);
      return;
    }

    try {
      final result = await coupleProvider.joinCoupleByCode(
        currentUser: currentUser,
        inviteCode: inviteCode,
      );
      await authProvider.updateCurrentUser(result.updatedUser);
      await photoProvider.syncForUser(result.updatedUser);

      if (!mounted) {
        return;
      }

      // Khoảnh khắc ghép đôi thành công (feature lottie-moments). Tự bỏ qua nếu
      // chưa có file animation → giữ nguyên luồng snack + điều hướng như cũ.
      await _showJoinCelebration();
      if (!mounted) return;

      _showSnack(result.message ?? l10n.setupSuccessConnected);
      // Route through the auth gate so SessionResolver wires the realtime
      // couple + love-note / daily-question / reaction / streak watchers — same
      // reason as create. Going straight to /home skipped that wiring, so the
      // joiner's notes/streak/reactions wouldn't sync until a manual restart.
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.authGate,
        (route) => false,
      );
    } on CoupleException catch (e) {
      _showSnack(e.message);
    } catch (e) {
      if (!mounted) return;
      _showSnack(context.l10n.setupErrorJoinCouple('$e'));
    }
  }

  /// Hiện animation ăn mừng ghép đôi (feature lottie-moments), tự đóng sau
  /// ~1.9s rồi mới điều hướng. Bỏ qua sạch nếu chưa bundle file của slot
  /// (tránh dialog trống) → luồng cũ giữ nguyên.
  Future<void> _showJoinCelebration() async {
    if (!mounted) return;
    try {
      await rootBundle.load(LoveLottieSlot.coupleJoined.asset);
    } catch (_) {
      return; // chưa có file animation → không hiện gì
    }
    if (!mounted) return;

    // Bắt NavigatorState đồng bộ TRƯỚC await để không dùng BuildContext qua
    // async gap (lint use_build_context_synchronously).
    final navigator = Navigator.of(context, rootNavigator: true);
    final dialogClosed = showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (_) => const Center(
        child: LoveLottie(
          slot: LoveLottieSlot.coupleJoined,
          height: 220,
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 1900));
    if (navigator.canPop()) {
      navigator.pop();
    }
    await dialogClosed;
  }

  Future<void> _showInviteCodeDialog(String inviteCode) async {
    final l10n = context.l10n;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(l10n.inviteCodeDialogTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.inviteCodeDialogContent),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  inviteCode,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.continueBtn),
            ),
          ],
        );
      },
    );
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _resolveCoupleResultMessage(CoupleActionResult result) {
    if (result.warningMessage != null && result.message != null) {
      return '${result.message}\n${result.warningMessage}';
    }

    return result.warningMessage ?? result.message ?? '';
  }

  // Locale-aware display format (design-unify C6, decision D3 — display-only:
  // the stored DateTime is untouched, only how it reads on screen changes).
  String _formatDate(DateTime date) {
    return DateFormat(context.l10n.fullDateFormat).format(date);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final coupleProvider = context.watch<CoupleProvider>();
    final photoProvider = context.watch<PhotoProvider>();
    final currentUser = authProvider.currentUser;
    final existingCouple = coupleProvider.couple;
    final isEditing = currentUser?.hasCouple == true && existingCouple != null;
    final editingCouple = isEditing ? existingCouple : null;
    final hasInviteCode = currentUser?.hasInviteCode == true;
    final isBusy = coupleProvider.isLoading || photoProvider.isLoading;
    final loadingMessage = coupleProvider.isLoading
        ? coupleProvider.loadingMessage
        : photoProvider.loadingMessage;

    return Scaffold(
      body: BlockingLoadingOverlay(
        isVisible: isBusy,
        message: loadingMessage,
        child: Container(
          decoration: const BoxDecoration(gradient: AppColors.secondaryGradient),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(authProvider, coupleProvider, isEditing),
                      const SizedBox(height: 24),
                      if (hasInviteCode) ...[
                        _buildInviteCard(
                          inviteCode: currentUser!.inviteCode,
                          coupleCode: existingCouple?.coupleCode,
                          hasCreatedCoupleSpace: currentUser.hasCouple,
                          isWaitingForPartner: editingCouple?.isWaitingForPartner ?? false,
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (!isEditing) _buildModeSelector(),
                      if (!isEditing) const SizedBox(height: 16),
                      if (isEditing || _mode == _SetupMode.create)
                        _buildCreateCard(
                          existingCouple: editingCouple,
                          isEditing: isEditing,
                          isLoading: coupleProvider.isLoading,
                        )
                      else
                        _buildJoinCard(
                          authProvider: authProvider,
                          isLoading: coupleProvider.isLoading,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    AuthProvider authProvider,
    CoupleProvider coupleProvider,
    bool isEditing,
  ) {
    final l10n = context.l10n;
    final title = isEditing ? l10n.setupEditTitle : l10n.setupCreateTitle;
    final subtitle = isEditing
        ? l10n.setupEditSectionDesc
        : l10n.setupCreateSectionDesc;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Header-sync vòng 5: boxed eyebrow chip, light-surface navy-ink
            // recolor of the original (user request 2026-06-11).
            EyebrowChip(
              label:
                  isEditing ? l10n.editCoupleBadge : l10n.coupleOnboardingBadge,
              icon: isEditing ? LucideIcons.pencil : Icons.favorite_rounded,
            ),
            const Spacer(),
            if (!isEditing)
              Tooltip(
                message: l10n.signOutBtn,
                child: InkWell(
                  onTap: () async {
                    await authProvider.signOut();
                    if (mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        AppRoutes.authGate,
                        (route) => false,
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    // Header ink vòng 4 (2026-06-11): navy ink on a near-solid
                    // white pill (same .72 fill as the light row tiles) — the
                    // frosted-glass + white-text version failed contrast.
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.white.withValues(alpha: 0.65)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.logOut, size: 13, color: AppColors.textPrimary.withValues(alpha: 0.85)),
                        const SizedBox(width: 6),
                        Text(
                          l10n.signOutBtn,
                          style: TextStyle(
                            color: AppColors.textPrimary.withValues(alpha: 0.85),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Text(title, style: AppTheme.pageTitleStyle()),
        const SizedBox(height: 10),
        Text(subtitle, style: AppTheme.pageSubtitleStyle()),
        if (coupleProvider.errorMessage != null) ...[
          const SizedBox(height: 12),
          // Light card + dark ink (design-unify C6) — white text on a thin
          // warning tint failed contrast on the blush gradient.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.30)),
            ),
            child: Text(
              coupleProvider.errorMessage!,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildModeSelector() {
    final l10n = context.l10n;
    final isCreate = _mode == _SetupMode.create;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        const padding = 4.0;
        final pillWidth = (totalWidth - padding * 2) / 2;

        return Container(
          height: 48,
          padding: const EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.white.withValues(alpha: 0.18)),
          ),
          child: Stack(
            children: [
              // Sliding pill
              AnimatedPositioned(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeInOutCubic,
                left: isCreate ? 0 : pillWidth,
                top: 0,
                bottom: 0,
                width: pillWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              // Tab labels on top
              Row(
                children: [
                  _buildModeTabLabel(
                    label: l10n.setupTabCreate,
                    icon: LucideIcons.plusCircle,
                    selected: isCreate,
                    onTap: () => setState(() => _mode = _SetupMode.create),
                  ),
                  _buildModeTabLabel(
                    label: l10n.setupTabJoin,
                    icon: LucideIcons.link,
                    selected: !isCreate,
                    onTap: () => setState(() => _mode = _SetupMode.join),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModeTabLabel({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      // InkWell (not a bare GestureDetector) so the tap ripples — white .12 on
      // the dark-ish glass track (design-unify C6 / A8 ripple rule). The
      // sliding pill underneath is untouched.
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.white.withValues(alpha: 0.12),
          highlightColor: Colors.transparent,
          child: SizedBox.expand(
            child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  icon,
                  key: ValueKey('$icon-$selected'),
                  size: 15,
                  // Header ink vòng 4: unselected tab reads navy .60 — white
                  // type on the glass track failed contrast on blush.
                  color: selected
                      ? AppColors.accentRose
                      : AppColors.textPrimary.withValues(alpha: 0.60),
                ),
              ),
              const SizedBox(width: 6),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOutCubic,
                style: TextStyle(
                  color: selected
                      ? AppColors.textPrimary
                      : AppColors.textPrimary.withValues(alpha: 0.60),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                child: Text(label),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInviteCard({
    required String inviteCode,
    String? coupleCode,
    required bool hasCreatedCoupleSpace,
    required bool isWaitingForPartner,
  }) {
    final l10n = context.l10n;

    // When waiting for partner: show the couple-level code (not personal
    // inviteCode), falling back to inviteCode for legacy couples that predate
    // the coupleCode field. When not waiting, show the personal inviteCode as
    // before (still useful for the partner to check their own code).
    final displayCode =
        isWaitingForPartner ? (coupleCode ?? inviteCode) : inviteCode;

    final title = !hasCreatedCoupleSpace
        ? l10n.yourInviteCodeTitle
        : isWaitingForPartner
            ? l10n.setupWaitingCoupleCodeTitle
            : l10n.inviteCodeTiedToAccount;

    // Couple-active branch: `inviteCodeTiedToAccount` already serves as the
    // title — repeating it as the description read as a copy bug, so that
    // branch renders no description at all (vòng 4).
    final String? description = !hasCreatedCoupleSpace
        ? l10n.inviteCodeDialogContent
        : isWaitingForPartner
            ? l10n.setupCoupleCodeDesc
            : null;

    final statusIcon = isWaitingForPartner
        ? LucideIcons.hourglass
        : hasCreatedCoupleSpace
            ? Icons.favorite_rounded
            : LucideIcons.keyRound;

    final statusColor = isWaitingForPartner
        ? AppColors.warning
        : hasCreatedCoupleSpace
            ? AppColors.accentRose
            : AppColors.textSecondary;

    // Cụm Copy/Share chỉ có nghĩa khi couple đang chờ partner: mã mời còn
    // join được. Khi couple đã active (đã tạo space & không còn waiting),
    // ẩn cụm nút vì không ai join bằng mã này nữa.
    final showInviteActions = !hasCreatedCoupleSpace || isWaitingForPartner;

    // Header ink vòng 4 (2026-06-11): solid white ContentCard + navy/rose ink
    // — the glass card with white type failed contrast on the blush gradient.
    return ContentCard(
      radius: 24,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, size: 14, color: statusColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            displayCode,
            style: const TextStyle(
              color: AppColors.accentLoveDeep,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
            ),
          ),
          if (showInviteActions) ...[
            const SizedBox(height: 10),
            InviteActionButtons(code: displayCode, onDark: false),
          ],
          if (description != null) ...[
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
          // Rejoin hint: remind both members they can use this code to
          // reconnect if one leaves, so they don't lose access.
          if (isWaitingForPartner) ...[
            const SizedBox(height: 10),
            Divider(
              thickness: 0.5,
              color: AppColors.textPrimary.withValues(alpha: 0.10),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  LucideIcons.info,
                  size: 12,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.setupCoupleCodeRejoinHint,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCreateCard({
    Couple? existingCouple,
    required bool isEditing,
    required bool isLoading,
  }) {
    final l10n = context.l10n;
    final hasPhoto = _couplePhotoPath != null &&
        _couplePhotoPath!.isNotEmpty &&
        File(_couplePhotoPath!).existsSync();
    final hasSyncedPhoto = existingCouple?.couplePhotoUrl?.trim().isNotEmpty == true;

    return SizedBox(
      width: double.infinity,
      child: GlassCard(
        borderRadius: 28,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.sectionAboutCouple,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          _buildFieldBlock(
            label: l10n.yourNameLabel,
            child: TextField(
              controller: _person1Controller,
              decoration: _inputDecoration(
                hint: l10n.yourNameHint,
                icon: LucideIcons.user,
              ),
            ),
          ),
          const SizedBox(height: 14),
          _buildFieldBlock(
            label: l10n.partnerNameLabel,
            child: TextField(
              controller: _person2Controller,
              decoration: _inputDecoration(
                hint: l10n.partnerNameHint,
                icon: Icons.favorite_rounded,
              ),
            ),
          ),
          const SizedBox(height: 14),
          _buildFieldBlock(
            label: l10n.anniversaryLabel,
            child: InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(20),
              child: Ink(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.9),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.calendar, color: AppColors.accentCoral),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedDate == null
                            ? l10n.anniversaryHint
                            : _formatDate(_selectedDate!),
                        style: TextStyle(
                          color: _selectedDate == null
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(LucideIcons.chevronRight),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _buildFieldBlock(
            label: l10n.couplePhotoLabel,
            child: InkWell(
              onTap: _pickPhoto,
              borderRadius: BorderRadius.circular(20),
              child: Ink(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.9),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.image, color: AppColors.info),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            hasPhoto ? l10n.couplePhotoSelected : l10n.couplePhotoHint,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (hasPhoto || hasSyncedPhoto) ...[
                      const SizedBox(height: 14),
                      Center(
                        child: _buildCircularPhotoPreview(
                          hasPhoto: hasPhoto,
                          existingCouple: existingCouple,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Primary CTA token (design-unify B10): pill r999, height 52, rose.
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: isLoading ? null : _submitCreateOrUpdate,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accentRose,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              icon: isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AppColors.white,
                      ),
                    )
                  : Icon(isEditing ? LucideIcons.save : Icons.favorite_rounded),
              label: Text(
                isEditing ? l10n.saveChangesBtn : l10n.createOurSpaceBtn,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildJoinCard({
    required AuthProvider authProvider,
    required bool isLoading,
  }) {
    final l10n = context.l10n;

    return SizedBox(
      width: double.infinity,
      child: GlassCard(
        borderRadius: 28,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.useInviteCodeTitle,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          _buildFieldBlock(
            label: l10n.theirInviteCodeLabel,
            child: TextField(
              controller: _inviteCodeController,
              textCapitalization: TextCapitalization.characters,
              decoration: _inputDecoration(
                hint: l10n.theirInviteCodeHint,
                icon: LucideIcons.lock,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Primary CTA token (design-unify B10): pill r999, height 52, rose.
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: isLoading ? null : _submitJoin,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accentRose,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              icon: isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AppColors.white,
                      ),
                    )
                  : const Icon(LucideIcons.link),
              label: Text(
                l10n.joinBtn,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildFieldBlock({
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.accentRose,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildCircularPhotoPreview({
    required bool hasPhoto,
    required Couple? existingCouple,
  }) {
    return Container(
      width: 118,
      height: 118,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.white.withValues(alpha: 0.78),
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.92),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppColors.accentRose.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColorFiltered(
              colorFilter: const ColorFilter.matrix([
                1, 0, 0, 0, 10,
                0, 1, 0, 0, 10,
                0, 0, 1, 0, 10,
                0, 0, 0, 1, 0,
              ]),
              child: hasPhoto
                  ? Image.file(
                      File(_couplePhotoPath!),
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      // 100px slot → decode at ~3x DPR, not the full-res source.
                      cacheWidth: (100 *
                              MediaQuery.of(context).devicePixelRatio)
                          .round(),
                    )
                  : SharedCouplePhotoView(
                      localPath: existingCouple?.couplePhotoPath,
                      remoteUrl: existingCouple?.couplePhotoUrl,
                      fit: BoxFit.cover,
                      decodeWidth: (100 *
                              MediaQuery.of(context).devicePixelRatio)
                          .round(),
                    ),
            ),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.white.withValues(alpha: 0.14),
                    Colors.transparent,
                    AppColors.white.withValues(alpha: 0.06),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      floatingLabelBehavior: FloatingLabelBehavior.never,
      prefixIcon: Icon(icon, color: AppColors.accentRose),
      filled: true,
      fillColor: AppColors.white.withValues(alpha: 0.92),
      hintStyle: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: AppColors.white.withValues(alpha: 0.9)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: AppColors.accentRose.withValues(alpha: 0.45),
          width: 1.2,
        ),
      ),
    );
  }
}

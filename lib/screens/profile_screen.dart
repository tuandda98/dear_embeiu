import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../app/app_routes.dart';
import '../l10n/l10n.dart';
import '../models/couple.dart';
import '../providers/auth_provider.dart';
import '../providers/couple_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/photo_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_couple_name.dart';
import '../widgets/shared_couple_photo_view.dart';
import 'setup_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.bottomInset = 0});

  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Consumer2<CoupleProvider, PhotoProvider>(
        builder: (context, coupleProvider, photoProvider, _) {
          final authProvider = context.watch<AuthProvider>();
          final currentUser = authProvider.currentUser;

          if (coupleProvider.couple == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final couple = coupleProvider.couple!;
          final photoCount = photoProvider.photoCount;
          final totalDays = _daysTogether(couple.anniversaryDate);
          final years = totalDays ~/ 365;
          final months = (totalDays % 365) ~/ 30;
          final nextAnniversary = _getNextAnniversary(couple.anniversaryDate);
          final daysUntilAnniversary = _daysUntil(nextAnniversary);

          return Container(
            decoration: const BoxDecoration(
              gradient: AppColors.secondaryGradient,
            ),
            child: SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPageHeader(context),
                    const SizedBox(height: 20),
                    _buildHeroCard(
                      context,
                      couple: couple,
                      daysUntilAnniversary: daysUntilAnniversary,
                    ),
                    const SizedBox(height: 18),
                    _buildStatsSection(
                      context,
                      years: years,
                      months: months,
                      totalDays: totalDays,
                      photoCount: photoCount,
                    ),
                    const SizedBox(height: 18),
                    _buildCoupleInfoSection(
                      context,
                      couple: couple,
                      inviteCode: currentUser?.inviteCode,
                      daysUntilAnniversary: daysUntilAnniversary,
                    ),
                    const SizedBox(height: 18),
                    _buildActionsSection(context),
                    const SizedBox(height: 18),
                    _buildLanguageSection(context),
                    const SizedBox(height: 12),
                    _buildSignOutButton(context),
                    const SizedBox(height: 18),
                    _buildDangerZone(
                      context,
                      isUsingFirebase: authProvider.isUsingFirebase,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPageHeader(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity( 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.white.withOpacity( 0.18)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 14,
                color: AppColors.white.withOpacity( 0.92),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.loveProfileBadge,
                style: AppTheme.pageEyebrowStyle(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          l10n.profileTitle,
          style: AppTheme.pageTitleStyle(),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.profileSubtitle,
          style: AppTheme.pageSubtitleStyle(),
        ),
      ],
    );
  }

  Widget _buildHeroCard(
    BuildContext context, {
    required Couple couple,
    required int daysUntilAnniversary,
  }) {
    final l10n = context.l10n;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.white.withOpacity( 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity( 0.14),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: AppColors.accentRose.withOpacity( 0.12),
            blurRadius: 42,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            Positioned.fill(
              child: (couple.couplePhotoPath?.trim().isNotEmpty == true ||
                      couple.couplePhotoUrl?.trim().isNotEmpty == true)
                  ? Transform.scale(
                      scale: 1.04,
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 0.6, sigmaY: 0.6),
                        child: SharedCouplePhotoView(
                          localPath: couple.couplePhotoPath,
                          remoteUrl: couple.couplePhotoUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  : DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.accentRose.withOpacity( 0.88),
                            AppColors.primaryGradientEnd.withOpacity( 0.94),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _initials(couple),
                          style: TextStyle(
                            color: AppColors.white.withOpacity( 0.94),
                            fontSize: 56,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
            ),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: const Alignment(-0.62, -0.86),
                                radius: 1.05,
                                colors: [
                                  AppColors.white.withOpacity( 0.16),
                                  AppColors.accentRose.withOpacity( 0.14),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.28, 0.78],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: -36,
                          right: -26,
                          child: Container(
                            width: 170,
                            height: 170,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  AppColors.primaryGradientEnd.withOpacity( 0.34),
                                  AppColors.accentRose.withOpacity( 0.18),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.black.withOpacity( 0.02),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                                  Colors.black.withOpacity( 0.08),
                                  Colors.black.withOpacity( 0.22),
                                  Colors.black.withOpacity( 0.68),
                    ],
                                stops: const [0.0, 0.34, 1.0],
                  ),
                ),
              ),
            ),
                        Positioned(
                          left: 22,
                          right: 22,
                          bottom: 108,
                          child: Container(
                            height: 72,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  AppColors.accentRose.withOpacity( 0.10),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                        ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGlassPill(
                    icon: Icons.auto_awesome_rounded,
                                isProminent: true,
                    label: daysUntilAnniversary == 0
                        ? l10n.todayIsAnniversaryProfile
                        : l10n.daysUntilAnniversaryProfile(daysUntilAnniversary),
                  ),
                              const SizedBox(height: 106),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildAvatarBadge(couple),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.ourStoryBadge,
                              style: TextStyle(
                                color: AppColors.white.withOpacity( 0.72),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            AnimatedCoupleName(
                              person1Name: couple.person1Name,
                              person2Name: couple.person2Name,
                              spacing: 8,
                              runSpacing: 6,
                              heartSize: 26,
                              heartColor: AppColors.white,
                              textStyle: TextStyle(
                                color: AppColors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                height: 1.02,
                                letterSpacing: -0.7,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity( 0.24),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.daysOfUsSince(_formatDate(couple.anniversaryDate)),
                              style: TextStyle(
                                color: AppColors.white.withOpacity( 0.82),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(
    BuildContext context, {
    required int years,
    required int months,
    required int totalDays,
    required int photoCount,
  }) {
    final l10n = context.l10n;

    return _buildSectionCard(
      title: l10n.journeySnapshotTitle,
      subtitle: l10n.journeySnapshotSubtitle,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildModernStatCard(
                  icon: Icons.favorite_rounded,
                  value: '$years',
                  label: l10n.yearsTogether,
                  color: AppColors.accentRose,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildModernStatCard(
                  icon: Icons.calendar_month_rounded,
                  value: '$months',
                  label: l10n.monthsRemaining,
                  color: AppColors.accentCoral,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildModernStatCard(
                  icon: Icons.today_rounded,
                  value: '$totalDays',
                  label: l10n.totalDaysLabel,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildModernStatCard(
                  icon: Icons.photo_library_rounded,
                  value: '$photoCount',
                  label: l10n.memoriesSavedLabel,
                  color: AppColors.accentGold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoupleInfoSection(
    BuildContext context, {
    required Couple couple,
    required String? inviteCode,
    required int daysUntilAnniversary,
  }) {
    final l10n = context.l10n;

    return _buildSectionCard(
      title: l10n.infoAndRhythmTitle,
      subtitle: l10n.infoAndRhythmSubtitle,
      child: Column(
        children: [
          _buildDetailTile(
            icon: Icons.calendar_today_rounded,
            title: l10n.loveStartDateLabel,
            value: _formatDate(couple.anniversaryDate),
            tint: AppColors.accentRose,
          ),
          const SizedBox(height: 12),
          _buildDetailTile(
            icon: Icons.celebration_rounded,
            title: l10n.upcomingMilestoneLabel,
            value: daysUntilAnniversary == 0
                ? l10n.todaySpecialMsg
                : l10n.daysUntilNextMsg(daysUntilAnniversary),
            tint: AppColors.accentGold,
          ),
          if (inviteCode != null && inviteCode.trim().isNotEmpty && couple.isWaitingForPartner) ...[
            const SizedBox(height: 12),
            _buildDetailTile(
              icon: Icons.password_rounded,
              title: l10n.yourInviteCodeLabel,
              value: inviteCode,
              tint: AppColors.warning,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionsSection(BuildContext context) {
    final l10n = context.l10n;

    return _buildSectionCard(
      title: l10n.customizeProfileTitle,
      subtitle: l10n.customizeProfileSubtitle,
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () {
            final coupleProvider = context.read<CoupleProvider>();
            final currentUser = context.read<AuthProvider>().currentUser;
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (context) => const SetupScreen()))
                .then((_) {
              coupleProvider.loadCoupleForUser(currentUser);
            });
          },
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accentRose,
            foregroundColor: AppColors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          icon: const Icon(Icons.edit_rounded),
          label: Text(l10n.editOurStoryBtn),
        ),
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context) {
    final l10n = context.l10n;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showSignOutDialog(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          side: BorderSide(color: AppColors.white.withOpacity(0.60)),
          backgroundColor: AppColors.white.withOpacity(0.22),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        icon: const Icon(Icons.logout_rounded),
        label: Text(
          l10n.signOutBtn,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildLanguageSection(BuildContext context) {
    final l10n = context.l10n;
    final localeProvider = context.watch<LocaleProvider>();
    final currentLocale = localeProvider.locale;

    return _buildSectionCard(
      title: l10n.languageTitle,
      subtitle: l10n.languageSubtitle,
      child: Column(
        children: [
          _buildLanguageOption(
            context,
            label: l10n.languageSystem,
            description: l10n.languageSystemDesc,
            isSelected: currentLocale == null,
            onTap: () => localeProvider.useSystemLocale(),
          ),
          const SizedBox(height: 10),
          _buildLanguageOption(
            context,
            label: l10n.languageEnglish,
            description: 'English',
            isSelected: currentLocale?.languageCode == 'en',
            onTap: () => localeProvider.setLocale(const Locale('en')),
          ),
          const SizedBox(height: 10),
          _buildLanguageOption(
            context,
            label: l10n.languageVietnamese,
            description: 'Tiếng Việt',
            isSelected: currentLocale?.languageCode == 'vi',
            onTap: () => localeProvider.setLocale(const Locale('vi')),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context, {
    required String label,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentRose.withOpacity( 0.10)
              : AppColors.white.withOpacity( 0.72),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? AppColors.accentRose.withOpacity( 0.28)
                : AppColors.white.withOpacity( 0.6),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.accentRose,
                size: 22,
              )
            else
              Icon(
                Icons.radio_button_unchecked_rounded,
                color: AppColors.textSecondary.withOpacity( 0.4),
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerZone(
    BuildContext context, {
    required bool isUsingFirebase,
  }) {
    final l10n = context.l10n;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.error.withOpacity(0.14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.delete_sweep_rounded, color: AppColors.error),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.dataManagementTitle,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.dataManagementDesc,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Warning context FIRST — user reads before acting
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.error.withOpacity(0.14)),
            ),
            child: Text(
              l10n.clearDataNote,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Firebase-specific: clear local cache (low severity)
          if (isUsingFirebase) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showClearLocalDialog(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: BorderSide(color: AppColors.textSecondary.withOpacity(0.22)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.cleaning_services_rounded, size: 18),
                label: Text(l10n.clearLocalDataBtn),
              ),
            ),
            const SizedBox(height: 10),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.warning.withOpacity(0.18)),
              ),
              child: Text(
                l10n.localFallbackWarning,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.45),
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Leave Couple (medium severity — outlined)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showLeaveCoupleDialog(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(color: AppColors.error.withOpacity(0.30)),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.exit_to_app_rounded, size: 18),
              label: Text(l10n.leaveCoupleBtn),
            ),
          ),

          // Divider separating medium vs high severity
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                Expanded(child: Divider(color: AppColors.error.withOpacity(0.15), height: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'Không thể hoàn tác',
                    style: TextStyle(
                      color: AppColors.error.withOpacity(0.50),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: AppColors.error.withOpacity(0.15), height: 1)),
              ],
            ),
          ),

          // Delete Account (highest severity — filled red)
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _showDeleteAccountDialog(context),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.delete_forever_rounded, size: 18),
              label: Text(
                l10n.deleteAccountBtn,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity( 0.84),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.white.withOpacity( 0.82)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity( 0.045),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _buildModernStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity( 0.10),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity( 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity( 0.78),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailTile({
    required IconData icon,
    required String title,
    required String value,
    required Color tint,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity( 0.72),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: tint.withOpacity( 0.10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: tint.withOpacity( 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: tint, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassPill({
    required IconData icon,
    required String label,
    bool isProminent = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isProminent ? 14 : 12,
        vertical: isProminent ? 12 : 10,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isProminent
              ? [
                  AppColors.white.withOpacity( 0.26),
                  AppColors.accentRose.withOpacity( 0.18),
                ]
              : [
                  AppColors.white.withOpacity( 0.18),
                  AppColors.white.withOpacity( 0.10),
                ],
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isProminent
              ? AppColors.white.withOpacity( 0.32)
              : AppColors.white.withOpacity( 0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity( isProminent ? 0.12 : 0.08),
            blurRadius: isProminent ? 16 : 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isProminent ? 24 : 22,
            height: isProminent ? 24 : 22,
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity( isProminent ? 0.20 : 0.14),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.white.withOpacity( 0.20)),
            ),
            child: Icon(
              icon,
              color: AppColors.white,
              size: isProminent ? 14 : 12,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.white.withOpacity( 0.95),
                fontSize: isProminent ? 12.5 : 12,
                fontWeight: isProminent ? FontWeight.w700 : FontWeight.w600,
                letterSpacing: isProminent ? 0.12 : 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarBadge(Couple couple) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.white.withOpacity( 0.96),
            AppColors.white.withOpacity( 0.36),
          ],
        ),
        border: Border.all(color: AppColors.white.withOpacity( 0.38), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity( 0.22),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: ClipOval(
          child: SharedCouplePhotoView(
            localPath: couple.couplePhotoPath,
            remoteUrl: couple.couplePhotoUrl,
            fit: BoxFit.cover,
            placeholder: Container(
              decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
              child: Center(
                child: Text(
                  _initials(couple),
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _initials(Couple couple) {
    final first = couple.person1Name.trim().isNotEmpty
        ? couple.person1Name.trim().characters.first.toUpperCase()
        : 'A';
    final second = couple.person2Name.trim().isNotEmpty
        ? couple.person2Name.trim().characters.first.toUpperCase()
        : 'B';
    return '$first$second';
  }

  int _daysTogether(DateTime anniversaryDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(
      anniversaryDate.year,
      anniversaryDate.month,
      anniversaryDate.day,
    );
    return today.difference(start).inDays;
  }

  DateTime _getNextAnniversary(DateTime anniversaryDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var next = DateTime(now.year, anniversaryDate.month, anniversaryDate.day);

    if (!next.isAfter(today)) {
      next = DateTime(now.year + 1, anniversaryDate.month, anniversaryDate.day);
    }

    return next;
  }

  int _daysUntil(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return date.difference(today).inDays;
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  void _showClearLocalDialog(BuildContext context) {
    final l10n = context.l10n;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.clearLocalDialogTitle),
        content: Text(l10n.clearLocalDialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await Future.wait([
                context.read<CoupleProvider>().clearLocalCache(),
                context.read<PhotoProvider>().clearLocalCache(),
              ]);

              if (!context.mounted) {
                return;
              }

              ScaffoldMessenger.of(context)
                ..clearSnackBars()
                ..showSnackBar(
                  SnackBar(
                    content: Text(l10n.localDataClearedMsg),
                  ),
                );
            },
            child: Text(
              l10n.clearLocalActionBtn,
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final l10n = context.l10n;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n.deleteAccountDialogTitle,
          style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w800),
        ),
        content: Text(l10n.deleteAccountDialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);

              final authProvider = context.read<AuthProvider>();
              final errorCode = await authProvider.deleteAccount();

              if (!context.mounted) return;

              if (errorCode == null) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.authGate,
                  (route) => false,
                );
              } else if (errorCode == 'requires-recent-login') {
                ScaffoldMessenger.of(context)
                  ..clearSnackBars()
                  ..showSnackBar(
                    SnackBar(content: Text(l10n.deleteAccountRequiresReloginMsg)),
                  );
              } else {
                ScaffoldMessenger.of(context)
                  ..clearSnackBars()
                  ..showSnackBar(SnackBar(content: Text(errorCode)));
              }
            },
            child: Text(
              l10n.deleteAccountConfirmBtn,
              style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    final l10n = context.l10n;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.signOutDialogTitle),
        content: Text(l10n.signOutDialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AuthProvider>().signOut();
              if (!context.mounted) return;
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.authGate,
                (route) => false,
              );
            },
            child: Text(l10n.signOutConfirmBtn),
          ),
        ],
      ),
    );
  }

  void _showLeaveCoupleDialog(BuildContext context) {
    final l10n = context.l10n;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.leaveCoupleDialogTitle),
        content: Text(l10n.leaveCoupleDialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              final authProvider = context.read<AuthProvider>();
              final currentUser = authProvider.currentUser;

              if (currentUser == null) {
                Navigator.pop(context);
                return;
              }

              final updatedUser = await context.read<CoupleProvider>().leaveCouple(
                    currentUser: currentUser,
                  );
              await authProvider.updateCurrentUser(updatedUser);
              await context.read<PhotoProvider>().syncForUser(updatedUser);

              if (!context.mounted) {
                return;
              }

              Navigator.pop(context);
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.setup,
                (route) => false,
              );
            },
            child: Text(
              l10n.leaveCoupleActionBtn,
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

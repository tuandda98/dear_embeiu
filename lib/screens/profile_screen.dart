import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/couple.dart';
import '../providers/auth_provider.dart';
import '../providers/couple_provider.dart';
import '../providers/photo_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_couple_name.dart';
import '../widgets/blocking_loading_overlay.dart';
import '../widgets/shared_couple_photo_view.dart';
import 'settings_screen.dart';

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
          final isBusy = coupleProvider.isLoading || photoProvider.isLoading;
          final busyMessage = coupleProvider.isLoading
              ? coupleProvider.loadingMessage
              : photoProvider.loadingMessage;

          if (coupleProvider.couple == null) {
            return BlockingLoadingOverlay(
              isVisible: isBusy,
              message: busyMessage,
              child: const Center(child: CircularProgressIndicator()),
            );
          }

          final couple = coupleProvider.couple!;
          final photoCount = photoProvider.photoCount;
          final totalDays = _daysTogether(couple.anniversaryDate);
          final years = totalDays ~/ 365;
          final months = (totalDays % 365) ~/ 30;
          final nextAnniversary = _getNextAnniversary(couple.anniversaryDate);
          final daysUntilAnniversary = _daysUntil(nextAnniversary);

          return BlockingLoadingOverlay(
            isVisible: isBusy,
            message: busyMessage,
            child: Container(
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
                      _buildSettingsTile(context),
                    ],
                  ),
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
            color: AppColors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.white.withValues(alpha: 0.18)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 14,
                color: AppColors.white.withValues(alpha: 0.92),
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
        border: Border.all(color: AppColors.white.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: AppColors.accentRose.withValues(alpha: 0.12),
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
                            AppColors.accentRose.withValues(alpha: 0.88),
                            AppColors.primaryGradientEnd.withValues(alpha: 0.94),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _initials(couple),
                          style: TextStyle(
                            color: AppColors.white.withValues(alpha: 0.94),
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
                                  AppColors.white.withValues(alpha: 0.16),
                                  AppColors.accentRose.withValues(alpha: 0.14),
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
                                  AppColors.primaryGradientEnd.withValues(alpha: 0.34),
                                  AppColors.accentRose.withValues(alpha: 0.18),
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
                                  Colors.black.withValues(alpha: 0.02),
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
                                  Colors.black.withValues(alpha: 0.08),
                                  Colors.black.withValues(alpha: 0.22),
                                  Colors.black.withValues(alpha: 0.68),
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
                                  AppColors.accentRose.withValues(alpha: 0.10),
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
                                color: AppColors.white.withValues(alpha: 0.72),
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
                                    color: Colors.black.withValues(alpha: 0.24),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.daysOfUsSince(
                                _formatDate(context, couple.anniversaryDate),
                              ),
                              style: TextStyle(
                                color: AppColors.white.withValues(alpha: 0.82),
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
            value: _formatDate(context, couple.anniversaryDate),
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

  /// Single full-width tile that opens the app-wide Settings screen. Replaces
  /// the reminders/language/danger/edit sections that moved into Settings.
  Widget _buildSettingsTile(BuildContext context) {
    final l10n = context.l10n;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppColors.accentRose.withValues(alpha: 0.10),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.accentRose.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.settings_rounded,
                color: AppColors.accentRose,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.settingsTitle,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.settingsProfileTileSubtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
          ],
        ),
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
        color: AppColors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.82)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
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
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.78),
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
        color: AppColors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: tint.withValues(alpha: 0.10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
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
                  AppColors.white.withValues(alpha: 0.26),
                  AppColors.accentRose.withValues(alpha: 0.18),
                ]
              : [
                  AppColors.white.withValues(alpha: 0.18),
                  AppColors.white.withValues(alpha: 0.10),
                ],
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isProminent
              ? AppColors.white.withValues(alpha: 0.32)
              : AppColors.white.withValues(alpha: 0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isProminent ? 0.12 : 0.08),
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
              color: AppColors.white.withValues(alpha: isProminent ? 0.20 : 0.14),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.white.withValues(alpha: 0.20)),
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
                color: AppColors.white.withValues(alpha: 0.95),
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
            AppColors.white.withValues(alpha: 0.96),
            AppColors.white.withValues(alpha: 0.36),
          ],
        ),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.38), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
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

  String _formatDate(BuildContext context, DateTime date) {
    return DateFormat(context.l10n.fullDateFormat).format(date);
  }

}

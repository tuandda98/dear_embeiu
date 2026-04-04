import 'dart:ui';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/couple.dart';
import '../models/counter_data.dart';
import '../models/photo.dart';
import '../providers/couple_provider.dart';
import '../providers/photo_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/counter_card.dart';
import '../widgets/couple_info_card.dart';
import 'profile_screen.dart';
import 'gallery_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const double _floatingNavHeight = 84;
  static const double _floatingNavMaxWidth = 284;
  static const double _floatingNavMargin = 14;
  static const double _floatingNavSpacing = 18;
  static const double _floatingNavInnerPadding = 8;
  static const double _floatingNavGlowSize = 46;
  static const double _floatingNavItemHorizontalPadding = 2;
  static const double _floatingNavLabelSpacing = 4;
  static const double _floatingNavGlowVerticalOffset = 8;

  static const List<_NavigationItem> _navigationItems = [
    _NavigationItem(
      icon: Icons.favorite_border_rounded,
      selectedIcon: Icons.favorite_rounded,
      label: 'Trang chủ',
      color: AppColors.accentRose,
    ),
    _NavigationItem(
      icon: Icons.photo_library_outlined,
      selectedIcon: Icons.photo_library_rounded,
      label: 'Thư viện',
      color: AppColors.accentRose,
    ),
    _NavigationItem(
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      label: 'Hồ sơ',
      color: AppColors.accentRose,
    ),
  ];

  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset =
        mediaQuery.padding.bottom +
        _floatingNavHeight +
        (_floatingNavMargin * 2) +
        _floatingNavSpacing;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Consumer2<CoupleProvider, PhotoProvider>(
        builder: (context, coupleProvider, photoProvider, _) {
          if (coupleProvider.couple == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final couple = coupleProvider.couple!;
          final counterData = CounterData.calculateFromAnniversary(
            couple.anniversaryDate,
          );

          return Stack(
            children: [
              Container(
                decoration: BoxDecoration(gradient: AppColors.secondaryGradient),
                child: SafeArea(
                  bottom: false,
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: [
                      _buildHomeTab(
                        couple,
                        counterData,
                        photoProvider.sortedPhotos,
                        bottomInset,
                      ),
                      GalleryScreen(bottomInset: bottomInset),
                      ProfileScreen(bottomInset: bottomInset),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: _floatingNavMargin,
                right: _floatingNavMargin,
                bottom: mediaQuery.padding.bottom + _floatingNavMargin,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: _floatingNavMaxWidth),
                    child: _buildFloatingNavigationBar(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFloatingNavigationBar() {
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return AnimatedSlide(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      offset: isKeyboardVisible ? const Offset(0, 1.2) : Offset.zero,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        opacity: isKeyboardVisible ? 0 : 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                height: _floatingNavHeight,
                padding: const EdgeInsets.all(_floatingNavInnerPadding),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.white.withValues(alpha: 0.16),
                      AppColors.white.withValues(alpha: 0.04),
                    ],
                  ),
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.10),
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final itemWidth =
                        constraints.maxWidth / _navigationItems.length;
                    final glowCenter = (itemWidth * _selectedIndex) + (itemWidth / 2);
                    final glowLeft = glowCenter - (_floatingNavGlowSize / 2);
                    final glowTop =
                        ((constraints.maxHeight - _floatingNavGlowSize) / 2) -
                        _floatingNavGlowVerticalOffset;

                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeOutBack,
                          left: glowLeft,
                          top: glowTop,
                          child: Container(
                            width: _floatingNavGlowSize,
                            height: _floatingNavGlowSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _navigationItems[_selectedIndex].color
                                  .withValues(alpha: 0.24),
                              border: Border.all(
                                color: _navigationItems[_selectedIndex].color
                                    .withValues(alpha: 0.28),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _navigationItems[_selectedIndex].color
                                      .withValues(alpha: 0.06),
                                  blurRadius: 12,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Row(
                          children: List.generate(_navigationItems.length, (index) {
                            final item = _navigationItems[index];
                            final isSelected = index == _selectedIndex;

                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: _floatingNavItemHorizontalPadding,
                                ),
                                child: _buildNavigationItem(
                                  item: item,
                                  index: index,
                                  isSelected: isSelected,
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationItem({
    required _NavigationItem item,
    required int index,
    required bool isSelected,
  }) {
    return Tooltip(
      message: item.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('bottom-nav-$index'),
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            if (_selectedIndex == index) {
              return;
            }

            setState(() => _selectedIndex = index);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedScale(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    scale: isSelected ? 1.16 : 1,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      width: isSelected ? 40 : 36,
                      height: isSelected ? 40 : 36,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.white.withValues(alpha: 0.10)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(
                                color: AppColors.white.withValues(alpha: 0.16),
                              )
                            : null,
                      ),
                      child: Icon(
                        isSelected ? (item.selectedIcon ?? item.icon) : item.icon,
                        size: 20,
                        color: isSelected
                            ? AppColors.white
                            : AppColors.white.withValues(alpha: 0.90),
                      ),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      final slideAnimation = Tween<Offset>(
                        begin: const Offset(0, 0.18),
                        end: Offset.zero,
                      ).animate(animation);

                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: slideAnimation,
                          child: child,
                        ),
                      );
                    },
                    child: isSelected
                        ? Padding(
                            key: ValueKey('bottom-nav-label-$index'),
                            padding: const EdgeInsets.only(
                              top: _floatingNavLabelSpacing,
                            ),
                            child: Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                height: 1,
                              ),
                            ),
                          )
                        : SizedBox(
                            key: ValueKey('bottom-nav-label-hidden-$index'),
                            height: 0,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildHomeTab(
    Couple couple,
    CounterData counterData,
    List<Photo> photos,
    double bottomInset,
  ) {
    final totalDays = _getTotalDays(couple.anniversaryDate);
    final nextAnniversary = _getNextAnniversary(couple.anniversaryDate);
    final daysUntilAnniversary = _daysUntil(nextAnniversary);
    final nextMilestone = _getNextMilestone(totalDays);
    final progressToMilestone = totalDays / nextMilestone;
    final recentPhotos = photos.take(5).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                        SizedBox(width: 8),
                        Text(
                          'LOVE HOME',
                          style: AppTheme.pageEyebrowStyle(),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Trang Chủ',
                    style: AppTheme.pageTitleStyle(),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Lưu giữ từng ngày hạnh phúc của hai bạn',
                    style: AppTheme.pageSubtitleStyle(),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.white.withOpacity(0.18),
                  ),
                ),
                child: Icon(Icons.favorite_rounded, color: AppColors.white),
              ),
            ],
          ),
          SizedBox(height: 20),
          _buildHeroSection(
            couple: couple,
            totalDays: totalDays,
            daysUntilAnniversary: daysUntilAnniversary,
          ),
          SizedBox(height: 20),
          CounterCard(
            years: counterData.years,
            months: counterData.months,
            days: counterData.days,
            subtitle: 'Bắt đầu từ ${_formatDate(couple.anniversaryDate)}',
            footer: daysUntilAnniversary == 0
                ? 'Hôm nay là ngày kỷ niệm của hai bạn ✨'
                : 'Còn $daysUntilAnniversary ngày nữa tới kỷ niệm tiếp theo',
          ),
          SizedBox(height: 20),
          _buildSectionTitle(
            title: 'Khám phá nhanh',
            subtitle: 'Các lối tắt để bạn xem kỷ niệm nhanh hơn',
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.photo_library_rounded,
                  title: 'Thư viện',
                  subtitle: 'Xem toàn bộ ảnh',
                  color: AppColors.accentRose,
                  onTap: () => setState(() => _selectedIndex = 1),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.person_rounded,
                  title: 'Hồ sơ',
                  subtitle: 'Cập nhật thông tin',
                  color: AppColors.accentCoral,
                  onTap: () => setState(() => _selectedIndex = 2),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.auto_awesome_rounded,
                  title: 'Cột mốc',
                  subtitle: _milestoneLabel(nextMilestone),
                  color: AppColors.accentGold,
                  onTap: () {},
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          CoupleInfoCard(
            person1Name: couple.person1Name,
            person2Name: couple.person2Name,
            couplePhotoPath: couple.couplePhotoPath,
            onTap: () => setState(() => _selectedIndex = 2),
          ),
          SizedBox(height: 20),
          _buildSectionTitle(
            title: 'Bảng thông tin tình yêu',
            subtitle: 'Những con số đáng nhớ của hai bạn',
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInsightCard(
                  icon: Icons.today_rounded,
                  title: 'Tổng ngày',
                  value: '$totalDays',
                  hint: 'ngày bên nhau',
                  color: AppColors.accentRose,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildInsightCard(
                  icon: Icons.photo_camera_back_rounded,
                  title: 'Kho ảnh',
                  value: '${photos.length}',
                  hint: 'khoảnh khắc',
                  color: AppColors.accentCoral,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInsightCard(
                  icon: Icons.event_available_rounded,
                  title: 'Kỷ niệm tới',
                  value: '$daysUntilAnniversary',
                  hint: 'ngày nữa',
                  color: AppColors.info,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildInsightCard(
                  icon: Icons.workspace_premium_rounded,
                  title: 'Mục tiêu gần',
                  value: '$nextMilestone',
                  hint: 'ngày',
                  color: AppColors.accentGold,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          _buildSectionTitle(
            title: 'Tiến trình cột mốc',
            subtitle: 'Bạn đang tiến gần tới dấu mốc đẹp tiếp theo',
          ),
          SizedBox(height: 12),
          _buildMilestoneSection(
            totalDays: totalDays,
            nextMilestone: nextMilestone,
            progress: progressToMilestone.clamp(0, 1),
          ),
          SizedBox(height: 20),
          _buildQuoteCard(totalDays, couple),
          SizedBox(height: 20),
          _buildSectionTitle(
            title: 'Kỷ niệm gần đây',
            subtitle: photos.isEmpty
                ? 'Chưa có ảnh nào, hãy bắt đầu thêm những khoảnh khắc đẹp'
                : 'Một vài khoảnh khắc mới nhất trong thư viện của hai bạn',
            actionLabel: photos.isEmpty ? null : 'Xem tất cả',
            onActionTap: photos.isEmpty
                ? null
                : () => setState(() => _selectedIndex = 1),
          ),
          SizedBox(height: 12),
          _buildRecentPhotosSection(recentPhotos),
          SizedBox(height: 20),
          _buildTimelineCard(totalDays, couple, photos.length),
        ],
      ),
    );
  }

  Widget _buildHeroSection({
    required Couple couple,
    required int totalDays,
    required int daysUntilAnniversary,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.wb_sunny_rounded,
                    color: AppColors.white,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chào ${couple.person1Name} & ${couple.person2Name}',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Hôm nay là một ngày đẹp để nhìn lại hành trình yêu thương.',
                        style: TextStyle(
                          color: AppColors.white.withOpacity(0.82),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildHeroBadge(
                Icons.favorite_rounded,
                '$totalDays ngày yêu nhau',
              ),
              _buildHeroBadge(
                Icons.celebration_rounded,
                daysUntilAnniversary == 0
                    ? 'Đến ngày kỷ niệm rồi'
                    : '$daysUntilAnniversary ngày nữa tới kỷ niệm',
              ),
              _buildHeroBadge(
                Icons.calendar_month_rounded,
                _formatDate(couple.anniversaryDate),
              ),
            ],
          ),
        ],
      ),
    ));
  }

  Widget _buildHeroBadge(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.white.withOpacity(0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.white, size: 16),
          SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: AppColors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle({
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onActionTap,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.sectionTitleStyle(),
              ),
              SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTheme.sectionSubtitleStyle(),
              ),
            ],
          ),
        ),
        if (actionLabel != null && onActionTap != null)
          TextButton(
            onPressed: onActionTap,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.white,
              padding: EdgeInsets.zero,
            ),
            child: Text(actionLabel),
          ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color),
            ),
            SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard({
    required IconData icon,
    required String title,
    required String value,
    required String hint,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 6),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                  text: '  $hint',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneSection({
    required int totalDays,
    required int nextMilestone,
    required double progress,
  }) {
    final daysLeft = nextMilestone - totalDays;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accentGold.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.workspace_premium_rounded,
                  color: AppColors.accentGold,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mốc tiếp theo: ${_milestoneLabel(nextMilestone)}',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      daysLeft <= 0
                          ? 'Hai bạn vừa chạm một cột mốc thật đẹp ✨'
                          : 'Chỉ còn $daysLeft ngày nữa là chạm cột mốc tiếp theo.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: AppColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentRose),
            ),
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$totalDays ngày',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}% hoàn thành',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteCard(int totalDays, Couple couple) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.white.withOpacity(0.24),
            AppColors.white.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.white.withOpacity(0.18)),
      ),
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.format_quote_rounded, color: AppColors.white),
              SizedBox(width: 8),
              Text(
                'Love note',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            '"$totalDays ngày không chỉ là thời gian, mà là từng lần cùng nhau trưởng thành, dịu dàng và chọn ở lại bên nhau."',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.55,
            ),
          ),
          SizedBox(height: 12),
          Text(
            '— ${couple.person1Name} & ${couple.person2Name}',
            style: TextStyle(
              color: AppColors.white.withOpacity(0.82),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentPhotosSection(List<Photo> photos) {
    if (photos.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.photo_library_outlined,
              color: AppColors.textSecondary.withOpacity(0.5),
              size: 42,
            ),
            SizedBox(height: 12),
            Text(
              'Thêm vài bức ảnh đầu tiên để biến trang chủ thành một cuốn nhật ký tình yêu.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 176,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        separatorBuilder: (_, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final photo = photos[index];
          return GestureDetector(
            onTap: () => setState(() => _selectedIndex = 1),
            child: Container(
              width: 140,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    File(photo.path).existsSync()
                        ? Image.file(
                            File(photo.path),
                            fit: BoxFit.cover,
                          )
                        : Container(color: AppColors.surfaceLight),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            photo.caption?.trim().isNotEmpty == true
                                ? photo.caption!
                                : 'Khoảnh khắc #${index + 1}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            _formatDate(photo.uploadDate),
                            style: TextStyle(
                              color: AppColors.white.withOpacity(0.82),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildTimelineCard(int totalDays, Couple couple, int photoCount) {
    final currentMonthiversary = totalDays ~/ 30;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tóm tắt hành trình',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 16),
          _buildTimelineItem(
            icon: Icons.favorite_rounded,
            title: 'Bắt đầu yêu nhau',
            subtitle: '${couple.person1Name} và ${couple.person2Name} chính thức bắt đầu vào ${_formatDate(couple.anniversaryDate)}',
            color: AppColors.accentRose,
          ),
          SizedBox(height: 14),
          _buildTimelineItem(
            icon: Icons.calendar_view_month_rounded,
            title: 'Đã đi qua $currentMonthiversary tháng kỷ niệm',
            subtitle: 'Mỗi tháng là thêm một lớp ký ức và sự thấu hiểu dành cho nhau.',
            color: AppColors.accentCoral,
          ),
          SizedBox(height: 14),
          _buildTimelineItem(
            icon: Icons.collections_rounded,
            title: '$photoCount kỷ niệm đã được lưu lại',
            subtitle: 'Thư viện đang dần trở thành album riêng của hai bạn.',
            color: AppColors.info,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.14),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  int _getTotalDays(DateTime anniversaryDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(
      anniversaryDate.year,
      anniversaryDate.month,
      anniversaryDate.day,
    );
    return today.difference(start).inDays;
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
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

  int _getNextMilestone(int totalDays) {
    const milestones = [30, 50, 100, 180, 365, 500, 730, 1000, 1500, 2000, 3000];
    for (final milestone in milestones) {
      if (totalDays < milestone) {
        return milestone;
      }
    }
    return ((totalDays ~/ 500) + 1) * 500;
  }

  String _milestoneLabel(int days) {
    if (days % 365 == 0) {
      return '${days ~/ 365} năm';
    }
    if (days < 365 && days % 30 == 0) {
      return '${days ~/ 30} tháng';
    }
    return '$days ngày';
  }
}

class _NavigationItem {
  const _NavigationItem({
    required this.icon,
    this.selectedIcon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final Color color;
}


import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Hero counter card — the emotional centerpiece of the home screen.
/// Large serif numerals on a Sunset Romance gradient with a soft radial glow.
class CounterCard extends StatelessWidget {
  final int years;
  final int months;
  final int days;
  final VoidCallback? onTap;
  final String title;
  final String? subtitle;
  final String? footer;

  /// When provided, the card displays a single hero number (total days)
  /// instead of the years/months/days breakdown.
  final int? totalDays;

  const CounterCard({
    super.key,
    required this.years,
    required this.months,
    required this.days,
    this.totalDays,
    this.onTap,
    this.title = 'You\'ve been together for',
    this.subtitle,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: AppColors.sunsetRomance,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.sunset1.withOpacity( 0.32),
              blurRadius: 32,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              _buildGlow(alignment: Alignment.topLeft, opacity: 0.45),
              _buildGlow(alignment: Alignment.bottomRight, opacity: 0.25),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 26, 24, 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildHeartBadge(),
                    const SizedBox(height: 14),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.white.withOpacity( 0.92),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (totalDays != null)
                      _buildHeroNumber(totalDays!)
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildCounterItem(years, 'years'),
                          _buildDivider(),
                          _buildCounterItem(months, 'months'),
                          _buildDivider(),
                          _buildCounterItem(days, 'days'),
                        ],
                      ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 18),
                      Text(
                        subtitle!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.white.withOpacity( 0.88),
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                    if (footer != null) ...[
                      const SizedBox(height: 18),
                      _buildFooterPill(footer!),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeartBadge() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.white.withOpacity( 0.22),
        border: Border.all(color: AppColors.white.withOpacity( 0.45)),
        boxShadow: [
          BoxShadow(
            color: AppColors.white.withOpacity( 0.35),
            blurRadius: 22,
          ),
        ],
      ),
      child: const Icon(
        Icons.favorite_rounded,
        color: AppColors.white,
        size: 22,
      ),
    );
  }

  Widget _buildHeroNumber(int days) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 220,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(60),
            boxShadow: [
              BoxShadow(
                color: AppColors.white.withOpacity( 0.55),
                blurRadius: 48,
              ),
            ],
          ),
        ),
        Text(
          '$days',
          style: AppTheme.dayCountStyle(),
        ),
      ],
    );
  }

  Widget _buildCounterItem(int value, String label) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: AppTheme.displaySerif(
            size: 44,
            color: AppColors.white,
            weight: FontWeight.w500,
            letterSpacing: -1,
            height: 1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: AppColors.white.withOpacity( 0.85),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 38,
      color: AppColors.white.withOpacity( 0.32),
    );
  }

  Widget _buildFooterPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity( 0.20),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.white.withOpacity( 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.favorite_rounded,
            color: AppColors.white,
            size: 14,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlow({required Alignment alignment, required double opacity}) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Align(
          alignment: alignment,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.white.withOpacity( opacity),
                  AppColors.white.withOpacity( 0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CounterCard extends StatelessWidget {
  final int years;
  final int months;
  final int days;
  final VoidCallback? onTap;

  const CounterCard({
    Key? key,
    required this.years,
    required this.months,
    required this.days,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppColors.counterGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentRose.withOpacity(0.3),
              blurRadius: 12,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            children: [
              Text(
                'Chúng mình đã bên nhau',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCounterItem(years, 'Năm'),
                  _buildDivider(),
                  _buildCounterItem(months, 'Tháng'),
                  _buildDivider(),
                  _buildCounterItem(days, 'Ngày'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCounterItem(int value, String label) {
    return Column(
      children: [
        Text(
          value.toString().padLeft(2, '0'),
          style: TextStyle(
            color: AppColors.white,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: AppColors.white.withOpacity(0.9),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 50,
      color: AppColors.white.withOpacity(0.3),
    );
  }
}


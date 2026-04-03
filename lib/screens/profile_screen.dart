import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/couple_provider.dart';
import '../providers/photo_provider.dart';
import '../theme/app_colors.dart';
import 'setup_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.bottomInset = 0});

  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text('Hồ Sơ'),
        backgroundColor: AppColors.white,
        elevation: 0,
      ),
      body: Consumer<CoupleProvider>(
        builder: (context, coupleProvider, _) {
          if (coupleProvider.couple == null) {
            return Center(child: CircularProgressIndicator());
          }

          final couple = coupleProvider.couple!;
          final photoCount = context.watch<PhotoProvider>().photoCount;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset),
            child: Column(
              children: [
                // Couple Profile Card
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Names
                      Text(
                        '${couple.person1Name} 💕 ${couple.person2Name}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20),
                      // Anniversary Date
                      _buildInfoItem(
                        icon: Icons.calendar_today,
                        label: 'Ngày yêu nhau',
                        value:
                            '${couple.anniversaryDate.day}/${couple.anniversaryDate.month}/${couple.anniversaryDate.year}',
                      ),
                      SizedBox(height: 16),
                      // Total Photos
                      _buildInfoItem(
                        icon: Icons.photo,
                        label: 'Tổng ảnh',
                        value: '$photoCount ảnh',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                // Stats
                _buildStatsGrid(couple, photoCount),
                SizedBox(height: 32),
                // Action Buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => SetupScreen(),
                        ),
                      ).then((_) {
                        // Reload couple data after returning
                        context.read<CoupleProvider>().loadCouple();
                      });
                    },
                    icon: Icon(Icons.edit),
                    label: Text('Chỉnh Sửa Thông Tin'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentRose,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showResetDialog(context),
                    icon: Icon(Icons.refresh),
                    label: Text('Đặt Lại Dữ Liệu'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(color: AppColors.error),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.all(12),
          child: Icon(
            icon,
            color: AppColors.accentRose,
            size: 20,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(dynamic couple, int photoCount) {
    final birthdayDiff = DateTime.now().difference(couple.anniversaryDate);
    final totalDays = birthdayDiff.inDays;
    final years = totalDays ~/ 365;
    final months = (totalDays % 365) ~/ 30;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          ),
        ],
      ),
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thống Kê',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.favorite,
                  value: '$years',
                  label: 'Năm',
                  color: AppColors.accentRose,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.calendar_month,
                  value: '$months',
                  label: 'Tháng',
                  color: AppColors.accentCoral,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.photo,
                  value: '$photoCount',
                  label: 'Ảnh',
                  color: AppColors.accentGold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác Nhận'),
        content: Text('Bạn có chắc muốn đặt lại toàn bộ dữ liệu?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              context.read<CoupleProvider>().resetCouple();
              Navigator.pop(context);
            },
            child: Text('Xóa', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}


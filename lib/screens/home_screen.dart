import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/counter_data.dart';
import '../providers/couple_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/counter_card.dart';
import '../widgets/couple_info_card.dart';
import 'profile_screen.dart';
import 'gallery_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<CoupleProvider>(
        builder: (context, coupleProvider, _) {
          if (coupleProvider.couple == null) {
            return Center(child: CircularProgressIndicator());
          }

          final couple = coupleProvider.couple!;
          final counterData = CounterData.calculateFromAnniversary(couple.anniversaryDate);

          return Container(
            decoration: BoxDecoration(gradient: AppColors.secondaryGradient),
            child: SafeArea(
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  // Home Tab
                  _buildHomeTab(couple, counterData),
                  // Gallery Tab
                  GalleryScreen(),
                  // Profile Tab
                  ProfileScreen(),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: AppColors.white,
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() => _selectedIndex = index);
          },
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Trang chủ',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.photo_library),
              label: 'Thư viện',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Hồ sơ',
            ),
          ],
          selectedItemColor: AppColors.accentRose,
          unselectedItemColor: AppColors.textSecondary.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildHomeTab(dynamic couple, CounterData counterData) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(height: 20),
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kỷ Niệm',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Icon(Icons.favorite, color: AppColors.white, size: 24),
            ],
          ),
          SizedBox(height: 24),
          // Counter Card
          CounterCard(
            years: counterData.years,
            months: counterData.months,
            days: counterData.days,
          ),
          SizedBox(height: 24),
          // Couple Info Card
          CoupleInfoCard(
            person1Name: couple.person1Name,
            person2Name: couple.person2Name,
            couplePhotoPath: couple.couplePhotoPath,
          ),
          SizedBox(height: 24),
          // Quick Stats
          Container(
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.white.withOpacity(0.2),
              ),
            ),
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                _buildStatItem(
                  icon: Icons.calendar_today,
                  title: 'Tổng cộng',
                  value: '${counterData.years * 365 + counterData.months * 30 + counterData.days} ngày',
                ),
                SizedBox(height: 16),
                Container(
                  height: 1,
                  color: AppColors.white.withOpacity(0.2),
                ),
                SizedBox(height: 16),
                _buildStatItem(
                  icon: Icons.favorite,
                  title: 'Trạng thái',
                  value: 'Yêu nhau 💕',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.white, size: 20),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: AppColors.white,
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
}


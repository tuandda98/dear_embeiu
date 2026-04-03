import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../models/couple.dart';
import '../providers/couple_provider.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({Key? key}) : super(key: key);

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  late TextEditingController _person1Controller;
  late TextEditingController _person2Controller;
  DateTime? _selectedDate;
  String? _couplePhotoPath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _person1Controller = TextEditingController();
    _person2Controller = TextEditingController();
  }

  @override
  void dispose() {
    _person1Controller.dispose();
    _person2Controller.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(Duration(days: 365)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickPhoto() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _couplePhotoPath = pickedFile.path;
      });
    }
  }

  Future<void> _saveCoupleData() async {
    if (_person1Controller.text.isEmpty ||
        _person2Controller.text.isEmpty ||
        _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng điền đầy đủ thông tin')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? savedPhotoPath;
      if (_couplePhotoPath != null) {
        savedPhotoPath = await StorageService.savePhotoFile(_couplePhotoPath!);
      }

      await context.read<CoupleProvider>().saveCouple(
            _person1Controller.text,
            _person2Controller.text,
            _selectedDate!,
            photoPath: savedPhotoPath,
          );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.secondaryGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  SizedBox(height: 20),
                  Icon(
                    Icons.favorite,
                    size: 64,
                    color: AppColors.white,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Kỷ Niệm Của Chúng Mình',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Lưu giữ những khoảnh khắc đặc biệt',
                    style: TextStyle(
                      color: AppColors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 40),
                  // Person 1 Name
                  _buildTextField(
                    controller: _person1Controller,
                    label: 'Tên người 1',
                    icon: Icons.person,
                  ),
                  SizedBox(height: 16),
                  // Person 2 Name
                  _buildTextField(
                    controller: _person2Controller,
                    label: 'Tên người 2',
                    icon: Icons.person,
                  ),
                  SizedBox(height: 16),
                  // Anniversary Date
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.white.withOpacity(0.3),
                        ),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: AppColors.white,
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedDate == null
                                  ? 'Chọn ngày yêu nhau'
                                  : 'Ngày: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  // Photo Picker
                  GestureDetector(
                    onTap: _pickPhoto,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.white.withOpacity(0.3),
                        ),
                      ),
                      padding: EdgeInsets.all(20),
                      child: Column(
                        children: [
                          if (_couplePhotoPath != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(_couplePhotoPath!),
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            )
                          else
                            Icon(
                              Icons.image,
                              color: AppColors.white,
                              size: 48,
                            ),
                          SizedBox(height: 12),
                          Text(
                            _couplePhotoPath == null
                                ? 'Chọn ảnh đôi'
                                : 'Đã chọn ảnh',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 40),
                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveCoupleData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentRose,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: AppColors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Bắt Đầu Nào',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      style: TextStyle(color: AppColors.white),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: TextStyle(color: AppColors.white.withOpacity(0.6)),
        prefixIcon: Icon(icon, color: AppColors.white),
        filled: true,
        fillColor: AppColors.white.withOpacity(0.15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}


import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../app/app_routes.dart';
import '../providers/auth_provider.dart';
import '../providers/couple_provider.dart';
import '../providers/photo_provider.dart';
import '../models/couple.dart';
import '../services/couple_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
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
    } else if (currentUser != null && currentUser.displayName.trim().isNotEmpty) {
      _person1Controller.text = currentUser.displayName.trim();
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
    final authProvider = context.read<AuthProvider>();
    final coupleProvider = context.read<CoupleProvider>();
    final photoProvider = context.read<PhotoProvider>();
    final currentUser = authProvider.currentUser;
    final existingCouple = coupleProvider.couple;
    final isEditing = currentUser?.hasCouple == true && existingCouple != null;

    if (currentUser == null) {
      _showSnack('Không tìm thấy tài khoản hiện tại. Bạn đăng nhập lại nhé.');
      return;
    }

    final person1 = _person1Controller.text.trim();
    final person2 = _person2Controller.text.trim();
    if (person1.isEmpty || person2.isEmpty || _selectedDate == null) {
      _showSnack('Vui lòng điền đầy đủ tên hai bạn và ngày kỷ niệm.');
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

      await authProvider.updateCurrentUser(result.updatedUser);
      await photoProvider.syncForUser(result.updatedUser);

      if (!mounted) {
        return;
      }

      if (!isEditing) {
        await _showInviteCodeDialog(result.updatedUser.inviteCode);
      } else {
        _showSnack(result.message ?? 'Đã cập nhật thông tin cặp đôi.');
      }

      if (navigator.canPop()) {
        navigator.pop();
      } else {
        navigator.pushReplacementNamed(AppRoutes.home);
      }
    } on CoupleException catch (e) {
      _showSnack(e.message);
    } catch (e) {
      _showSnack('Không thể lưu thông tin cặp đôi: $e');
    }
  }

  Future<void> _submitJoin() async {
    final authProvider = context.read<AuthProvider>();
    final coupleProvider = context.read<CoupleProvider>();
    final photoProvider = context.read<PhotoProvider>();
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      _showSnack('Không tìm thấy tài khoản hiện tại.');
      return;
    }

    final inviteCode = _inviteCodeController.text.trim();
    if (inviteCode.isEmpty) {
      _showSnack('Bạn hãy nhập mã mời trước nhé.');
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

      _showSnack(result.message ?? 'Kết nối thành công rồi 💞');
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    } on CoupleException catch (e) {
      _showSnack(e.message);
    } catch (e) {
      _showSnack('Không thể tham gia cặp đôi: $e');
    }
  }

  Future<void> _showInviteCodeDialog(String inviteCode) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Mã mời tài khoản của bạn'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mã mời này gắn trực tiếp với tài khoản của bạn. Gửi nó cho người còn lại để họ đăng nhập bằng tài khoản riêng và nhập vào màn hình tham gia cặp đôi.',
              ),
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
              child: const Text('Tiếp tục'),
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

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final coupleProvider = context.watch<CoupleProvider>();
    final currentUser = authProvider.currentUser;
    final existingCouple = coupleProvider.couple;
    final isEditing = currentUser?.hasCouple == true && existingCouple != null;
    final editingCouple = isEditing ? existingCouple : null;
    final hasInviteCode = currentUser?.hasInviteCode == true;

    return Scaffold(
      body: Container(
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
    );
  }

  Widget _buildHeader(
    AuthProvider authProvider,
    CoupleProvider coupleProvider,
    bool isEditing,
  ) {
    final title = isEditing
        ? 'Cập nhật thông tin cặp đôi'
        : 'Tạo hoặc tham gia cặp đôi';
    final subtitle = isEditing
        ? 'Bạn có thể chỉnh lại tên, ngày yêu và ảnh đôi. Mã mời cá nhân của bạn vẫn giữ nguyên theo tài khoản.'
        : 'Mỗi người đăng nhập bằng tài khoản riêng và có một mã mời gắn với tài khoản đó. Một người tạo không gian cặp đôi, người còn lại nhập mã để kết nối.';

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
                isEditing ? Icons.edit_rounded : Icons.favorite_rounded,
                size: 14,
                color: AppColors.white.withValues(alpha: 0.92),
              ),
              const SizedBox(width: 8),
              Text(
                isEditing ? 'EDIT COUPLE' : 'COUPLE ONBOARDING',
                style: AppTheme.pageEyebrowStyle(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(title, style: AppTheme.pageTitleStyle()),
        const SizedBox(height: 10),
        Text(subtitle, style: AppTheme.pageSubtitleStyle(alpha: 0.84)),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.white.withValues(alpha: 0.18)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: authProvider.isUsingFirebase
                      ? AppColors.success.withValues(alpha: 0.16)
                      : AppColors.warning.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  authProvider.isUsingFirebase
                      ? Icons.cloud_done_rounded
                      : Icons.usb_off_rounded,
                  color: authProvider.isUsingFirebase
                      ? AppColors.success
                      : AppColors.warning,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authProvider.authSourceLabel,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      authProvider.isUsingFirebase
                          ? 'Tài khoản, mã mời và dữ liệu couple sẽ được lưu trên Firestore để hai người dùng hai máy khác nhau vẫn kết nối được.'
                          : 'Bạn đang ở local fallback mode. Mã mời tài khoản vẫn được tạo, nhưng trải nghiệm ghép cặp chủ yếu phù hợp để test trong cùng môi trường local.',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                    if (coupleProvider.errorMessage != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        coupleProvider.errorMessage!,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModeSelector() {
    return Row(
      children: [
        Expanded(
          child: ChoiceChip(
            label: const Text('Tạo cặp đôi'),
            selected: _mode == _SetupMode.create,
            onSelected: (_) => setState(() => _mode = _SetupMode.create),
            selectedColor: AppColors.white,
            labelStyle: TextStyle(
              color: _mode == _SetupMode.create
                  ? AppColors.textPrimary
                  : AppColors.white,
              fontWeight: FontWeight.w700,
            ),
            backgroundColor: AppColors.white.withValues(alpha: 0.12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ChoiceChip(
            label: const Text('Nhập mã mời'),
            selected: _mode == _SetupMode.join,
            onSelected: (_) => setState(() => _mode = _SetupMode.join),
            selectedColor: AppColors.white,
            labelStyle: TextStyle(
              color: _mode == _SetupMode.join
                  ? AppColors.textPrimary
                  : AppColors.white,
              fontWeight: FontWeight.w700,
            ),
            backgroundColor: AppColors.white.withValues(alpha: 0.12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
        ),
      ],
    );
  }

  Widget _buildInviteCard({
    required String inviteCode,
    required bool hasCreatedCoupleSpace,
    required bool isWaitingForPartner,
  }) {
    final title = !hasCreatedCoupleSpace
        ? 'Mã mời tài khoản của bạn'
        : isWaitingForPartner
            ? 'Gửi mã này cho người ấy'
            : 'Mã mời gắn với tài khoản bạn';

    final description = !hasCreatedCoupleSpace
        ? 'Mã này đã gắn với tài khoản của bạn ngay khi đăng ký. Hãy tạo không gian cặp đôi trước, rồi gửi mã này cho người còn lại.'
        : isWaitingForPartner
            ? 'Người kia chỉ cần đăng nhập bằng tài khoản riêng rồi nhập mã này để kết nối vào không gian cặp đôi của bạn.'
            : 'Hai bạn đã kết nối thành công. Nếu sau này đặt lại couple, bạn vẫn có thể tiếp tục dùng mã mời tài khoản này.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              title,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
              inviteCode,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
              description,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateCard({
    Couple? existingCouple,
    required bool isEditing,
    required bool isLoading,
  }) {
    final hasPhoto = _couplePhotoPath != null &&
        _couplePhotoPath!.isNotEmpty &&
        File(_couplePhotoPath!).existsSync();
    final hasSyncedPhoto = existingCouple?.couplePhotoUrl?.trim().isNotEmpty == true;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin cặp đôi',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isEditing
                ? 'Chỉnh lại dữ liệu chung của cả hai. Nếu dùng Firebase, thông tin sẽ được lưu chung trên cloud.'
                : 'Bạn tạo không gian cặp đôi trước, sau đó người kia đăng nhập bằng tài khoản riêng và nhập mã mời tài khoản của bạn để kết nối.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _person1Controller,
            decoration: _inputDecoration(
              label: 'Tên người thứ nhất',
              hint: 'Ví dụ: Anh',
              icon: Icons.person_rounded,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _person2Controller,
            decoration: _inputDecoration(
              label: 'Tên người thứ hai',
              hint: 'Ví dụ: Em',
              icon: Icons.favorite_rounded,
            ),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(20),
            child: Ink(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_rounded, color: AppColors.accentCoral),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedDate == null
                          ? 'Chọn ngày yêu nhau'
                          : _formatDate(_selectedDate!),
                      style: TextStyle(
                        color: _selectedDate == null
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: _pickPhoto,
            borderRadius: BorderRadius.circular(20),
            child: Ink(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.image_rounded, color: AppColors.info),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          hasPhoto ? 'Đã chọn ảnh đôi' : 'Chọn ảnh đôi (tuỳ chọn)',
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
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: SizedBox(
                        height: 180,
                        width: double.infinity,
                        child: hasPhoto
                            ? Image.file(
                                File(_couplePhotoPath!),
                                fit: BoxFit.cover,
                              )
                            : SharedCouplePhotoView(
                                localPath: existingCouple?.couplePhotoPath,
                                remoteUrl: existingCouple?.couplePhotoUrl,
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isLoading ? null : _submitCreateOrUpdate,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accentRose,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
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
                  : Icon(isEditing ? Icons.save_rounded : Icons.favorite_rounded),
              label: Text(
                isEditing ? 'Lưu thay đổi' : 'Tạo không gian cặp đôi',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinCard({
    required AuthProvider authProvider,
    required bool isLoading,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nhập mã mời',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            authProvider.isUsingFirebase
                ? 'Nhập mã mời gắn với tài khoản của người ấy để tham gia vào không gian cặp đôi mà họ đã tạo.'
                : 'Ở local fallback mode, mã mời vẫn hoạt động theo dữ liệu local hiện có trên thiết bị hoặc môi trường test.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _inviteCodeController,
            textCapitalization: TextCapitalization.characters,
            decoration: _inputDecoration(
              label: 'Mã mời của người ấy',
              hint: 'Ví dụ: A7B9KD',
              icon: Icons.password_rounded,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isLoading ? null : _submitJoin,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accentRose,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
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
                  : const Icon(Icons.link_rounded),
              label: const Text(
                'Tham gia cặp đôi',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.accentRose),
      filled: true,
      fillColor: AppColors.white.withValues(alpha: 0.92),
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


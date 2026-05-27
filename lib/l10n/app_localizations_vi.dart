// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get cancel => 'Hủy';

  @override
  String get save => 'Lưu';

  @override
  String get delete => 'Xóa';

  @override
  String get edit => 'Chỉnh sửa';

  @override
  String get continueBtn => 'Tiếp tục';

  @override
  String get keep => 'Giữ lại';

  @override
  String get splashTagline => 'Câu chuyện của chúng mình';

  @override
  String get splashSubtitle => 'Đếm từng ngày bên nhau';

  @override
  String get checkingSession => 'Đang kiểm tra phiên đăng nhập...';

  @override
  String get loginTitle => 'Chào mừng trở lại';

  @override
  String get loginSubtitle => 'Đăng nhập để tiếp tục đếm từng ngày bên nhau.';

  @override
  String get loginLocalFallback =>
      'Đang dùng local fallback — Firebase sẽ được kết nối sau.';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailHint => 'you@example.com';

  @override
  String get emailRequired => 'Vui lòng nhập email';

  @override
  String get emailInvalid => 'Email không hợp lệ';

  @override
  String get passwordLabel => 'Mật khẩu';

  @override
  String get passwordHint => 'Ít nhất 6 ký tự';

  @override
  String get passwordRequired => 'Vui lòng nhập mật khẩu';

  @override
  String get passwordTooShort => 'Mật khẩu cần ít nhất 6 ký tự';

  @override
  String get signIn => 'Đăng nhập';

  @override
  String get newHere => 'Chưa có tài khoản?';

  @override
  String get createAccountLink => 'Tạo tài khoản';

  @override
  String get registerTitle => 'Bắt đầu\ncâu chuyện tình';

  @override
  String get registerSubtitle => 'Tạo tài khoản để lưu giữ từng ngày bên nhau.';

  @override
  String get registerLocalFallback =>
      'Đang dùng local fallback — Firebase sẽ được kết nối sau.';

  @override
  String get displayNameLabel => 'Tên hiển thị';

  @override
  String get displayNameHint => 'Tên của bạn';

  @override
  String get displayNameRequired => 'Vui lòng nhập tên hiển thị';

  @override
  String get displayNameTooShort => 'Tên quá ngắn';

  @override
  String get confirmPasswordLabel => 'Xác nhận mật khẩu';

  @override
  String get confirmPasswordHint => 'Nhập lại mật khẩu';

  @override
  String get confirmPasswordRequired => 'Vui lòng xác nhận mật khẩu';

  @override
  String get passwordsMismatch => 'Mật khẩu chưa khớp';

  @override
  String get createAccountBtn => 'Tạo tài khoản';

  @override
  String get alreadyWithUs => 'Đã có tài khoản?';

  @override
  String get backToSignIn => 'Quay lại đăng nhập';

  @override
  String get setupCreateTitle => 'Bắt đầu\ncâu chuyện của hai mình';

  @override
  String get setupEditTitle => 'Chỉnh sửa\ncâu chuyện của hai mình';

  @override
  String get setupTabCreate => 'Tạo mới';

  @override
  String get setupTabJoin => 'Tham gia bằng mã';

  @override
  String get inviteCodeDialogTitle => 'Mã mời tài khoản của bạn';

  @override
  String get inviteCodeDialogContent =>
      'Mã mời này gắn trực tiếp với tài khoản của bạn. Gửi nó cho người còn lại để họ đăng nhập bằng tài khoản riêng và nhập vào màn hình tham gia cặp đôi.';

  @override
  String get sectionAboutCouple => 'Thông tin cặp đôi';

  @override
  String get setupEditSectionDesc =>
      'Chỉnh sửa thông tin chung — tên, ngày kỷ niệm, ảnh đôi.';

  @override
  String get setupCreateSectionDesc =>
      'Tạo không gian trước, sau đó chia sẻ mã mời với người ấy.';

  @override
  String get yourNameLabel => 'Tên của bạn';

  @override
  String get yourNameHint => 'VD: Anh';

  @override
  String get partnerNameLabel => 'Tên người ấy';

  @override
  String get partnerNameHint => 'VD: Em';

  @override
  String get anniversaryLabel => 'Ngày kỷ niệm';

  @override
  String get anniversaryHint => 'Chọn ngày bắt đầu';

  @override
  String get couplePhotoLabel => 'Ảnh đôi';

  @override
  String get couplePhotoHint => 'Thêm ảnh đôi (tùy chọn)';

  @override
  String get couplePhotoSelected => 'Đã chọn ảnh';

  @override
  String get saveChangesBtn => 'Lưu thay đổi';

  @override
  String get createOurSpaceBtn => 'Tạo không gian của hai mình';

  @override
  String get useInviteCodeTitle => 'Dùng mã mời';

  @override
  String get theirInviteCodeLabel => 'Mã mời của người ấy';

  @override
  String get theirInviteCodeHint => 'VD: A7B9KD';

  @override
  String get joinBtn => 'Tham gia';

  @override
  String get yourInviteCodeTitle => 'Mã mời của bạn';

  @override
  String get sendToPartnerHint => 'Gửi mã này cho người ấy';

  @override
  String get inviteCodeTiedToAccount => 'Mã gắn với tài khoản bạn';

  @override
  String get setupErrorNoAccount =>
      'Không tìm thấy tài khoản. Bạn đăng nhập lại nhé.';

  @override
  String get setupErrorFillRequired =>
      'Vui lòng điền đầy đủ tên hai bạn và ngày kỷ niệm.';

  @override
  String setupErrorSaveCouple(String error) {
    return 'Không thể lưu thông tin cặp đôi: $error';
  }

  @override
  String get setupErrorNoAccountShort => 'Không tìm thấy tài khoản.';

  @override
  String get setupErrorNoInviteCode => 'Bạn hãy nhập mã mời trước nhé.';

  @override
  String setupErrorJoinCouple(String error) {
    return 'Không thể tham gia cặp đôi: $error';
  }

  @override
  String get setupSuccessConnected => 'Kết nối thành công rồi 💞';

  @override
  String get navHome => 'Trang chủ';

  @override
  String get navMemories => 'Kỷ niệm';

  @override
  String get navProfile => 'Hồ sơ';

  @override
  String get ourStoryBadge => 'CÂU CHUYỆN CỦA CHÚNG MÌNH';

  @override
  String get helloGreeting => 'Xin chào,';

  @override
  String get homeSubtitle =>
      'Hôm nay là ngày tốt để nhìn lại câu chuyện tình yêu.';

  @override
  String get youveBeenTogetherFor => 'HAI BẠN ĐÃ BÊN NHAU';

  @override
  String daysOfUsSince(String date) {
    return 'ngày · từ $date';
  }

  @override
  String get todayIsAnniversary => 'Hôm nay là ngày kỷ niệm của hai bạn ✨';

  @override
  String daysUntilNextAnniversary(int count) {
    return 'Còn $count ngày tới kỷ niệm tiếp theo';
  }

  @override
  String get quickMomentsTitle => 'Khoảnh khắc nhanh';

  @override
  String get quickMomentsSubtitle =>
      'Lối tắt để xem lại câu chuyện của hai bạn';

  @override
  String get memoriesCardTitle => 'Kỷ niệm';

  @override
  String get viewAllPhotos => 'Xem tất cả ảnh';

  @override
  String get profileCardTitle => 'Hồ sơ';

  @override
  String get updateInfo => 'Cập nhật thông tin';

  @override
  String get milestoneCardTitle => 'Cột mốc';

  @override
  String get loveInNumbersTitle => 'Tình yêu qua con số';

  @override
  String get loveInNumbersSubtitle =>
      'Những thống kê nhỏ từ hành trình của hai bạn';

  @override
  String get daysTogether => 'Ngày bên nhau';

  @override
  String get daysUnit => 'ngày';

  @override
  String get memoriesSaved => 'Kỷ niệm đã lưu';

  @override
  String get photosUnit => 'ảnh';

  @override
  String get nextAnniversaryLabel => 'Kỷ niệm tiếp theo';

  @override
  String get daysAway => 'ngày nữa';

  @override
  String get nextMilestoneTitle => 'Cột mốc tiếp theo';

  @override
  String get milestoneProgressTitle => 'Tiến trình cột mốc';

  @override
  String get milestoneProgressSubtitle =>
      'Nhẹ nhàng tiến về con số ngọt ngào tiếp theo';

  @override
  String get recentMemoriesTitle => 'Kỷ niệm gần đây';

  @override
  String get addPhotosPrompt => 'Thêm vài ảnh để bắt đầu thư tình của hai bạn';

  @override
  String get latestMomentsSubtitle =>
      'Một vài khoảnh khắc mới nhất của hai bạn';

  @override
  String get seeAll => 'Xem tất cả';

  @override
  String get addPhotosEmpty =>
      'Thêm vài ảnh để bắt đầu lấp đầy bức thư tình này.';

  @override
  String get yourStorySoFar => 'Câu chuyện của hai bạn';

  @override
  String get whenItAllBegan => 'Khi tất cả bắt đầu';

  @override
  String whenItAllBeganSubtitle(String name1, String name2, String date) {
    return '$name1 & $name2 vào $date';
  }

  @override
  String monthiversaries(int count) {
    return '$count tháng kỷ niệm';
  }

  @override
  String get monthiversaryDesc =>
      'Mỗi tháng là thêm một lớp hiểu biết và trìu mến.';

  @override
  String memoriesCaptured(int count) {
    return '$count kỷ niệm đã lưu';
  }

  @override
  String get memoriesCapturedDesc =>
      'Thư viện của hai bạn đang trở thành một album nhỏ xinh.';

  @override
  String get loveNoteLabel => 'Ghi chú tình yêu';

  @override
  String loveNoteQuote(int count) {
    return '\"$count ngày không chỉ là thời gian — đó là từng khoảnh khắc nhẹ nhàng, từng lựa chọn ở lại, từng điều nhỏ bé chúng mình chia sẻ.\"';
  }

  @override
  String get milestoneReached => 'Hai bạn vừa đạt một cột mốc đẹp ✨';

  @override
  String onlyDaysUntilMilestone(int count) {
    return 'Chỉ còn $count ngày tới cột mốc tiếp theo.';
  }

  @override
  String nextMilestonePrefix(String label) {
    return 'Tiếp: $label';
  }

  @override
  String daysCountLabel(int count) {
    return '$count ngày';
  }

  @override
  String percentThere(String percent) {
    return '$percent% rồi';
  }

  @override
  String milestoneYearsOne(int count) {
    return '$count năm';
  }

  @override
  String milestoneYearsMany(int count) {
    return '$count năm';
  }

  @override
  String milestoneMonthsOne(int count) {
    return '$count tháng';
  }

  @override
  String milestoneMonthsMany(int count) {
    return '$count tháng';
  }

  @override
  String milestoneDaysLabel(int count) {
    return '$count ngày';
  }

  @override
  String get privateGalleryBadge => 'THƯ VIỆN RIÊNG TƯ';

  @override
  String get galleryTitle => 'Thư Viện Ảnh';

  @override
  String get gallerySubtitle =>
      'Vuốt lên nhẹ để gọi lại nhanh khung đăng ảnh và quản lý kỷ niệm.';

  @override
  String get addCaptionTitle => 'Thêm chú thích';

  @override
  String get addCaptionHint => 'Viết vài dòng về khoảnh khắc này...';

  @override
  String get addCaptionOptionalTitle => 'Thêm chú thích (tùy chọn)';

  @override
  String get addCaptionOptionalHint => 'Viết điều gì đó thật đáng nhớ...';

  @override
  String get editCaptionTitle => 'Chỉnh sửa chú thích';

  @override
  String get editCaptionHint => 'Khoảnh khắc này đáng nhớ thế nào?';

  @override
  String get deletePhotoTitle => 'Xóa ảnh này?';

  @override
  String get deletePhotoContent =>
      'Khoảnh khắc này sẽ bị xóa khỏi nhật ký của hai bạn.';

  @override
  String get keepPhotoBtn => 'Giữ lại';

  @override
  String get deletePhotoBtn => 'Xóa';

  @override
  String postedByLabel(String name) {
    return 'Đăng bởi $name';
  }

  @override
  String momentsCount(int count) {
    return '$count khoảnh khắc';
  }

  @override
  String daysTogetherCount(int count) {
    return '$count ngày bên nhau';
  }

  @override
  String get privateFeedLabel => 'Feed riêng của hai bạn';

  @override
  String get postNewPhotoBtn => 'Đăng ảnh mới';

  @override
  String get addMultipleBtn => 'Thêm nhiều';

  @override
  String get addNewMemoryTitle => 'Thêm một kỷ niệm mới hôm nay';

  @override
  String get whatNewToday => 'hôm nay có gì mới?';

  @override
  String get composerSubtitle =>
      'Biến thư viện thành một newfeed tình yêu thật riêng tư và đáng nhớ.';

  @override
  String compactCaption(int count) {
    return '$count khoảnh khắc · Vuốt thêm để bung khung đăng ảnh';
  }

  @override
  String get todayInLoveBadge => 'HÔM NAY TRONG TÌNH YÊU';

  @override
  String get storyStripBadge => 'DẢI STORY';

  @override
  String get memoriesTodayTitle => 'Kỷ niệm hôm nay';

  @override
  String get recentPhotosTitle => 'Ảnh gần đây';

  @override
  String get memoriesTodaySubtitle =>
      'Những khoảnh khắc được lưu đúng ngày này, dịu dàng và rất riêng.';

  @override
  String get recentPhotosSubtitle =>
      'Một dải story nhỏ để xem nhanh những khoảnh khắc mới nhất của hai bạn.';

  @override
  String get memoryBadge => 'Kỷ niệm';

  @override
  String get newBadge => 'Mới';

  @override
  String momentLabel(int number) {
    return 'Khoảnh khắc #$number';
  }

  @override
  String get editCaptionAction => 'Chỉnh sửa chú thích';

  @override
  String get deletePhotoAction => 'Xóa ảnh';

  @override
  String get editAction => 'Chỉnh sửa';

  @override
  String get deleteAction => 'Xóa';

  @override
  String get startNewfeedTitle => 'Bắt đầu tạo newfeed kỷ niệm';

  @override
  String get postFirstMomentOf => 'Hãy đăng khoảnh khắc đầu tiên của';

  @override
  String get emptyFeedContent =>
      'Khi thêm ảnh, thư viện này sẽ trở thành một newfeed tình yêu riêng tư với những dòng thời gian thật dễ nhìn và cảm xúc.';

  @override
  String get postFirstPhotoBtn => 'Đăng ảnh đầu tiên';

  @override
  String get photoAddedSuccess => 'Thêm ảnh thành công!';

  @override
  String get photoAddError => 'Không thể đăng ảnh lúc này.';

  @override
  String multiplePhotosAdded(int count) {
    return 'Đã thêm $count ảnh!';
  }

  @override
  String get captionUpdatedSuccess => 'Đã cập nhật chú thích';

  @override
  String get captionUpdateError => 'Không thể cập nhật chú thích.';

  @override
  String get photoDeletedSuccess => 'Đã xóa ảnh';

  @override
  String get photoDeleteError => 'Không thể xóa ảnh lúc này.';

  @override
  String get youTwoLabel => 'Hai bạn';

  @override
  String get syncingLibrary => 'Đang đồng bộ thư viện...';

  @override
  String get uploadingPhoto => 'Đang đăng ảnh...';

  @override
  String get deletingPhoto => 'Đang xóa ảnh...';

  @override
  String get updatingCaption => 'Đang cập nhật chú thích...';

  @override
  String get feedDateFormat => 'dd \'thg\' MM • HH:mm';

  @override
  String momentNumberFallback(int index) {
    return 'Khoảnh khắc #$index';
  }

  @override
  String get loveProfileBadge => 'HỒ SƠ TÌNH YÊU';

  @override
  String get profileTitle => 'Hồ sơ của hai bạn';

  @override
  String get profileSubtitle =>
      'Một góc riêng để nhìn lại hành trình yêu nhau, cột mốc và album kỷ ức của hai bạn.';

  @override
  String get todayIsAnniversaryProfile => 'Hôm nay là ngày kỷ niệm ✨';

  @override
  String daysUntilAnniversaryProfile(int count) {
    return 'Còn $count ngày tới kỷ niệm tiếp theo';
  }

  @override
  String khoanhKhacCount(int count) {
    return '$count khoảnh khắc';
  }

  @override
  String get privateDiaryLabel => 'Nhật ký riêng tư';

  @override
  String get loveMilestonesLabel => 'Mốc yêu thương';

  @override
  String get journeySnapshotTitle => 'Bức tranh hành trình';

  @override
  String get journeySnapshotSubtitle =>
      'Các con số nổi bật của mối quan hệ được trình bày gọn gàng, hiện đại và dễ nhìn.';

  @override
  String get yearsTogether => 'Năm bên nhau';

  @override
  String get monthsRemaining => 'Tháng lẻ';

  @override
  String get totalDaysLabel => 'Tổng số ngày';

  @override
  String get memoriesSavedLabel => 'Khoảnh khắc lưu';

  @override
  String get infoAndRhythmTitle => 'Thông tin & nhịp sống';

  @override
  String get infoAndRhythmSubtitle =>
      'Một cách nhìn rõ ràng hơn về ngày bắt đầu, album và cột mốc sắp tới.';

  @override
  String get loveStartDateLabel => 'Ngày yêu nhau';

  @override
  String get yourInviteCodeLabel => 'Mã mời tài khoản của bạn';

  @override
  String get dayStreakLabel => 'Chuỗi ngày bên nhau';

  @override
  String dayStreakValue(int count) {
    return '$count ngày và vẫn đang tiếp tục';
  }

  @override
  String get memoryAlbumLabel => 'Thư viện kỷ niệm';

  @override
  String memoryAlbumValue(int count) {
    return '$count ảnh đang được lưu trong album riêng';
  }

  @override
  String get upcomingMilestoneLabel => 'Cột mốc gần nhất';

  @override
  String get todaySpecialMsg => 'Hôm nay là ngày thật đặc biệt của hai bạn';

  @override
  String daysUntilNextMsg(int count) {
    return 'Còn $count ngày nữa tới kỷ niệm tiếp theo';
  }

  @override
  String get customizeProfileTitle => 'Tùy chỉnh hồ sơ';

  @override
  String get customizeProfileSubtitle =>
      'Cập nhật tên, ngày yêu và ảnh đôi để trang hồ sơ luôn phản ánh đúng hành trình hiện tại.';

  @override
  String get editOurStoryBtn => 'Chỉnh sửa câu chuyện';

  @override
  String get proTipLabel => 'Mẹo nhỏ';

  @override
  String get proTipContent =>
      'Một ảnh đôi sáng, cận mặt và có nhiều khoảng thở sẽ giúp phần hero ở hồ sơ trông sang hơn hẳn.';

  @override
  String get dataManagementTitle => 'Quản lý dữ liệu';

  @override
  String get dataManagementDesc =>
      'Một người chỉ được xóa cache trên máy này hoặc rời khỏi couple. Muốn xóa dữ liệu chung, cả hai phải cùng xác nhận.';

  @override
  String get clearLocalDataBtn => 'Xóa dữ liệu trên máy này';

  @override
  String get localFallbackWarning =>
      'App đang ở local fallback nên chưa hỗ trợ xóa cache riêng an toàn. Bạn có thể rời khỏi couple local hiện tại nếu muốn làm mới.';

  @override
  String get leaveCoupleBtn => 'Rời khỏi couple';

  @override
  String get clearDataNote =>
      'Xóa toàn bộ dữ liệu chung hiện chưa cho phép từ một phía. Ở sprint sau, mình sẽ đổi sang flow cần cả hai cùng xác nhận.';

  @override
  String get clearLocalDialogTitle => 'Xóa dữ liệu trên máy này';

  @override
  String get clearLocalDialogContent =>
      'Thao tác này chỉ xóa cache trên thiết bị hiện tại. Dữ liệu chung trên Firebase vẫn được giữ nguyên và sẽ tải lại khi cần.';

  @override
  String get clearLocalActionBtn => 'Xóa local';

  @override
  String get leaveCoupleDialogTitle => 'Rời khỏi couple';

  @override
  String get leaveCoupleDialogContent =>
      'Bạn sẽ rời khỏi không gian couple hiện tại. Người còn lại vẫn giữ dữ liệu chung. Bạn không thể xóa toàn bộ dữ liệu chung chỉ từ một phía.';

  @override
  String get leaveCoupleActionBtn => 'Rời khỏi couple';

  @override
  String get localDataClearedMsg =>
      'Đã xóa dữ liệu local trên máy này. Dữ liệu chung trên cloud vẫn được giữ nguyên.';

  @override
  String get languageTitle => 'Ngôn ngữ';

  @override
  String get languageSubtitle => 'Chọn ngôn ngữ hiển thị của ứng dụng';

  @override
  String get languageSystem => 'Theo hệ thống';

  @override
  String get languageSystemDesc => 'Theo ngôn ngữ thiết bị';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageVietnamese => 'Tiếng Việt';

  @override
  String get loadingCoupleInfo => 'Đang tải thông tin cặp đôi...';

  @override
  String get savingCoupleSpace => 'Đang lưu không gian cặp đôi...';

  @override
  String get connectingCouple => 'Đang kết nối cặp đôi...';

  @override
  String get updatingCoupleInfo => 'Đang cập nhật thông tin cặp đôi...';

  @override
  String get welcomeBackBadge => 'CHÀO MỪNG TRỞ LẠI';

  @override
  String get createAccountBadge => 'TẠO TÀI KHOẢN';

  @override
  String get loveHomeBadge => 'TRANG CHỦ';

  @override
  String get coupleOnboardingBadge => 'BẮT ĐẦU';

  @override
  String get editCoupleBadge => 'CHỈNH SỬA';

  @override
  String get deleteAccountBtn => 'Xóa tài khoản';

  @override
  String get deleteAccountTitle => 'Xóa tài khoản';

  @override
  String get deleteAccountDesc => 'Xóa vĩnh viễn tài khoản và toàn bộ dữ liệu của bạn';

  @override
  String get deleteAccountDialogTitle => 'Xóa tài khoản?';

  @override
  String get deleteAccountDialogContent =>
      'Hành động này không thể hoàn tác. Toàn bộ dữ liệu của bạn bao gồm ảnh và thông tin cặp đôi sẽ bị xóa vĩnh viễn.';

  @override
  String get deleteAccountConfirmBtn => 'Xóa vĩnh viễn';

  @override
  String get deleteAccountSuccessMsg => 'Tài khoản đã được xóa';

  @override
  String get deleteAccountRequiresReloginMsg =>
      'Vui lòng đăng xuất, đăng nhập lại và thử lại để xác nhận danh tính';

  @override
  String get privacyPolicyLabel => 'Chính sách bảo mật';

  @override
  String get privacyDisclosure =>
      'Bằng cách tạo tài khoản, bạn đồng ý với Chính sách bảo mật của chúng tôi. Chúng tôi thu thập email, tên hiển thị và ảnh bạn chia sẻ để cung cấp dịch vụ.';

  String get signOutBtn => 'Đăng xuất';

  String get signOutDialogTitle => 'Đăng xuất?';

  String get signOutDialogContent => 'Bạn có chắc muốn đăng xuất khỏi tài khoản không?';

  String get signOutConfirmBtn => 'Đăng xuất';

  String get agreeToPrivacyPolicy => 'Tôi đồng ý với Chính sách bảo mật';

  String get mustAgreeToPrivacyPolicy => 'Vui lòng đồng ý với chính sách bảo mật để tiếp tục';

  @override
  String get setupNoChangesToSaveMsg => 'Không có gì thay đổi để lưu.';

  @override
  String get inviteCodeCopiedMsg => 'Đã sao chép mã mời';

  @override
  String get copyBtn => 'Sao chép';
}

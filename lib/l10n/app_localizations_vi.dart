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
  String get addMemoryCta => 'Thêm kỷ niệm';

  @override
  String get addMemoryCtaSubtitle => 'Đăng một tấm ảnh mới cho cả hai cùng xem';

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
  String onThisDayTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count năm trước',
    );
    return 'Ngày này $_temp0 💞';
  }

  @override
  String get onThisDaySubtitle => 'Một kỷ niệm đúng vào ngày này';

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
  String loveNoteFromPartner(String name) {
    return 'Lời nhắn từ $name';
  }

  @override
  String loveNoteEmptyFromPartner(String name) {
    return 'Chưa có lời nhắn từ $name';
  }

  @override
  String get loveNoteWriteCta => 'Viết lời nhắn';

  @override
  String get loveNoteEditCta => 'Sửa lời nhắn';

  @override
  String get loveNoteWaitingPartner =>
      'Mời người ấy để cùng để lại lời nhắn cho nhau.';

  @override
  String get loveNoteSheetTitle => 'Lời nhắn của bạn';

  @override
  String get loveNoteSheetHint => 'Viết điều gì đó ngọt ngào cho người ấy…';

  @override
  String loveNoteCharCount(int count) {
    return '$count/140';
  }

  @override
  String get loveNoteSaved => 'Đã gửi lời nhắn 💞';

  @override
  String get loveNoteHistoryCta => 'Xem lại lời nhắn cũ';

  @override
  String get loveNoteHistoryTitle => 'Nhật ký lời nhắn';

  @override
  String get loveNoteHistorySubtitle =>
      'Tất cả những lời hai bạn đã để lại cho nhau.';

  @override
  String get loveNoteHistoryEmpty =>
      'Chưa có lời nhắn nào được lưu. Những lời hai bạn gửi nhau sẽ được giữ ở đây.';

  @override
  String get loveNoteJustNow => 'vừa xong';

  @override
  String loveNoteMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count phút trước',
      one: '1 phút trước',
    );
    return '$_temp0';
  }

  @override
  String loveNoteHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giờ trước',
      one: '1 giờ trước',
    );
    return '$_temp0';
  }

  @override
  String loveNoteDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ngày trước',
      one: '1 ngày trước',
    );
    return '$_temp0';
  }

  @override
  String get reactionHint => 'Thả tim cho khoảnh khắc này';

  @override
  String get reactionYouLabel => 'Bạn';

  @override
  String get reactionAddTooltip => 'Thả tim';

  @override
  String get reactionChangeTooltip => 'Đổi cảm xúc';

  @override
  String get reactionRemoveTooltip => 'Gỡ cảm xúc';

  @override
  String get reactionErrorRetry => 'Chưa thả được tim, thử lại nhé';

  @override
  String reactionPartnerReacted(String name, String emoji) {
    return '$name đã thả $emoji';
  }

  @override
  String get reactionBothLabel => 'Cả hai đã thả tim 💞';

  @override
  String get dailyQuestionLabel => 'Câu hỏi hôm nay';

  @override
  String get dailyQuestionHint => 'Viết câu trả lời của bạn…';

  @override
  String dailyQuestionCharCount(int count) {
    return '$count/280';
  }

  @override
  String get dailyQuestionSend => 'Gửi';

  @override
  String get dailyQuestionYourAnswerLabel => 'Câu trả lời của bạn';

  @override
  String dailyQuestionAnsweredWaiting(String name) {
    return 'Đã trả lời ✓ — đang chờ $name';
  }

  @override
  String dailyQuestionPartnerAnswerLabel(String name) {
    return 'Câu trả lời của $name';
  }

  @override
  String get dailyQuestionWaitingPartner =>
      'Sẽ mở khoá khi người ấy tham gia và trả lời nhé.';

  @override
  String get dailyQuestionRevealHint =>
      'Cả hai đã trả lời — cùng xem hai bạn đã nói gì nhé 💞';

  @override
  String get dailyQuestionSent => 'Đã gửi câu trả lời của bạn 💞';

  @override
  String get journalEntryCta => 'Xem lại nhật ký';

  @override
  String get journalScreenTitle => 'Nhật ký câu hỏi';

  @override
  String get journalScreenSubtitle => 'Những câu hỏi hai bạn đã cùng trả lời.';

  @override
  String get journalSettingsTile => 'Nhật ký câu hỏi';

  @override
  String get journalSettingsSection => 'Kỷ niệm';

  @override
  String get journalYourAnswerLabel => 'CÂU TRẢ LỜI CỦA BẠN';

  @override
  String journalPartnerAnswerLabel(String name) {
    return 'CÂU TRẢ LỜI CỦA $name';
  }

  @override
  String get journalLoadMore => 'Xem thêm';

  @override
  String get journalEmptyTitle => 'Chưa có kỷ niệm câu hỏi nào';

  @override
  String get journalEmptyBody =>
      'Khi cả hai cùng trả lời câu hỏi trong ngày, khoảnh khắc đó sẽ được lưu vào đây.';

  @override
  String get journalEmptyCta => 'Trả lời câu hôm nay';

  @override
  String get journalEmptyNoPartnerBody =>
      'Mời người ấy để cùng nhau bắt đầu viết nhật ký.';

  @override
  String get journalEmptyNoPartnerCta => 'Mời người ấy';

  @override
  String get journalErrorTitle => 'Chưa tải được nhật ký';

  @override
  String get journalRetry => 'Thử lại';

  @override
  String get loveNoteYourNoteLabel => 'LỜI NHẮN CỦA BẠN';

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
  String get reportPhotoAction => 'Báo cáo ảnh';

  @override
  String get reportPhotoTitle => 'Báo cáo ảnh';

  @override
  String get reportPhotoSubtitle => 'Cho chúng tôi biết vấn đề với ảnh này.';

  @override
  String get reportReasonInappropriate => 'Nội dung không phù hợp';

  @override
  String get reportReasonSpam => 'Spam hoặc lừa đảo';

  @override
  String get reportReasonOther => 'Khác';

  @override
  String get reportCancel => 'Huỷ';

  @override
  String get reportSentConfirm => 'Đã gửi báo cáo, cảm ơn bạn.';

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
  String uploadingPhotoProgress(int current, int total) {
    return 'Đang đăng $current/$total...';
  }

  @override
  String get deletingPhoto => 'Đang xóa ảnh...';

  @override
  String get updatingCaption => 'Đang cập nhật chú thích...';

  @override
  String get galleryLoadErrorTitle => 'Chưa tải được ảnh';

  @override
  String get galleryLoadErrorSubtitle =>
      'Kỷ niệm của bạn vẫn an toàn — chỉ là chưa kết nối tới được lúc này.';

  @override
  String get galleryRetryBtn => 'Thử lại';

  @override
  String multiPhotosResultPartial(int success, int total, int failed) {
    return 'Đã đăng $success/$total, $failed ảnh lỗi';
  }

  @override
  String get feedDateFormat => 'dd \'thg\' MM • HH:mm';

  @override
  String get fullDateFormat => 'd \'thg\' M, y';

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
  String get leaveCoupleDeleteAllTitle =>
      'Xoá vĩnh viễn không gian của hai người?';

  @override
  String get leaveCoupleDeleteAllContent =>
      'Bạn là thành viên cuối cùng. Khi rời đi, TẤT CẢ kỷ niệm chung — ảnh, lời nhắn, nhật ký câu hỏi — sẽ bị xoá vĩnh viễn và KHÔNG THỂ khôi phục.';

  @override
  String get leaveCoupleDeleteAllBtn => 'Xoá tất cả';

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
  String get setupNoChangesToSaveMsg => 'Không có gì thay đổi để lưu.';

  @override
  String get inviteCodeCopiedMsg => 'Đã sao chép mã mời';

  @override
  String get copyBtn => 'Sao chép';

  @override
  String get shareBtn => 'Chia sẻ';

  @override
  String inviteShareMessage(String code) {
    return 'Mình muốn lưu giữ kỷ niệm cùng bạn trên Dear Embeiu 💞\nNhập mã mời này để ghép đôi với mình nhé: $code';
  }

  @override
  String get remindersTitle => 'Nhắc nhở yêu thương';

  @override
  String get remindersSubtitle =>
      'Những lời nhắc nhẹ nhàng để câu chuyện thêm đong đầy';

  @override
  String get remindersToggleLabel => 'Nhắc cột mốc & kỷ niệm';

  @override
  String get remindersToggleDesc =>
      'Tự nhắc các cột mốc & kỷ niệm bạn chọn. Cần bật để dùng \"Lời nhắc của chúng mình\".';

  @override
  String get remindersTimeLabel => 'Giờ nhắc';

  @override
  String get remindersPermissionDeniedMsg =>
      'Hãy bật thông báo trong Cài đặt để nhận lời nhắc.';

  @override
  String get dailyQuestionReminderTitle => 'Nhắc trả lời câu hỏi';

  @override
  String get dailyQuestionReminderSubtitle =>
      'Một lời nhắc nhẹ mỗi ngày để hai bạn cùng trả lời.';

  @override
  String get dailyQuestionReminderTimeLabel => 'Nhắc lúc';

  @override
  String get dailyQuestionReminderNotifTitle => 'Câu hỏi hôm nay đang chờ 💌';

  @override
  String get dailyQuestionReminderNotifBody =>
      'Ghé trả lời để mở khoá câu trả lời của người ấy nhé.';

  @override
  String get reminderDailyTitle => 'Thêm một ngày của chúng mình 💕';

  @override
  String get reminderDailyBody =>
      'Mở Dear Embeiu và cùng đếm thêm một ngày bên nhau nhé.';

  @override
  String get reminderMilestoneApproachingTitle => 'Sắp đến cột mốc rồi 💕';

  @override
  String reminderMilestoneApproachingBody(int count, String milestone) {
    return 'Còn $count ngày nữa là đến cột mốc $milestone!';
  }

  @override
  String get reminderMilestoneTodayTitle => 'Đã đến cột mốc 🎉';

  @override
  String reminderMilestoneTodayBody(String milestone) {
    return 'Hôm nay chúng mình chạm mốc $milestone rồi 💕';
  }

  @override
  String get reminderAnniversaryTitle => 'Chúc mừng kỷ niệm 🎉';

  @override
  String get reminderAnniversaryBody =>
      'Hôm nay hãy cùng mừng thêm một năm yêu thương 💕';

  @override
  String get reminderInactivityTitle => 'Nhớ những khoảnh khắc 💭';

  @override
  String get reminderInactivityBody =>
      'Đã lâu rồi — cùng thêm một kỷ niệm mới nhé 💕';

  @override
  String get remindersV2MilestoneEntryTitle => 'Cột mốc & kỷ niệm';

  @override
  String get remindersV2MilestoneEntrySubtitle => 'Chọn cột mốc muốn được nhắc';

  @override
  String remindersV2MilestoneCountBadge(int count) {
    return '$count mốc';
  }

  @override
  String get remindersV2MilestoneScreenTitle => 'Cột mốc & kỷ niệm';

  @override
  String get remindersV2MilestoneScreenCaption =>
      'Chọn cột mốc muốn được nhắc và giờ nhắc.';

  @override
  String remindersV2MilestoneNext(String date) {
    return 'Sắp tới: $date';
  }

  @override
  String remindersV2MilestoneNextWithLabel(String label, String date) {
    return 'Sắp tới: $label · $date';
  }

  @override
  String get remindersV2MilestonePast => 'Đã qua';

  @override
  String get remindersV2MilestonePending => 'Sẽ tính khi tới ngày kỷ niệm';

  @override
  String remindersV2MilestoneDaysLabel(int count) {
    return '$count ngày';
  }

  @override
  String remindersV2MilestoneYearsLabel(int count) {
    return '$count năm';
  }

  @override
  String get milestoneEvery100Title => 'Mỗi 100 ngày';

  @override
  String get milestoneEvery100Desc => 'Ăn mừng mỗi 100 ngày bên nhau';

  @override
  String get milestone520Title => '520 ngày';

  @override
  String get milestone520Desc => '\"Anh yêu em\" — mốc 520 ngày';

  @override
  String get milestone1000Title => '1000 ngày';

  @override
  String get milestone1000Desc => 'Tròn 1000 ngày yêu nhau';

  @override
  String get milestone1314Title => '1314 ngày';

  @override
  String get milestone1314Desc => '\"Yêu trọn đời\" — mốc 1314 ngày';

  @override
  String get milestoneHalfYearTitle => 'Nửa năm yêu nhau';

  @override
  String get milestoneHalfYearDesc => 'Tròn 6 tháng bên nhau';

  @override
  String get milestoneYearlyTitle => 'Kỷ niệm hằng năm';

  @override
  String get milestoneYearlyDesc => 'Mỗi năm tròn ngày yêu nhau';

  @override
  String get milestoneInactivityTitle => 'Lâu chưa đăng ảnh';

  @override
  String get milestoneInactivityDesc => 'Nhắc nhẹ khi 7 ngày chưa có ảnh mới';

  @override
  String get milestoneInactivitySub => 'Nhắc khi vắng ảnh 7 ngày';

  @override
  String get settingsTitle => 'Cài đặt';

  @override
  String get settingsProfileTileSubtitle => 'Nhắc nhở, ngôn ngữ, tài khoản';

  @override
  String get settingsRemindersModuleTitle => 'Nhắc nhở';

  @override
  String get settingsRemindersModuleSubtitle =>
      'Cột mốc, kỷ niệm & lời nhắc riêng';

  @override
  String get settingsAccountModuleTitle => 'Tài khoản & dữ liệu';

  @override
  String get settingsAccountModuleSubtitle => 'Câu chuyện, dữ liệu & tài khoản';

  @override
  String get settingsAnalyticsTitle => 'Chia sẻ dữ liệu sử dụng';

  @override
  String get settingsAnalyticsSubtitle =>
      'Giúp cải thiện app bằng dữ liệu ẩn danh. Không bao giờ thu thập nội dung riêng tư của bạn.';

  @override
  String get settingsEditStorySubtitle => 'Đổi tên, ngày yêu, ảnh đại diện';

  @override
  String get settingsDefaultTimeLabel => 'Giờ mặc định';

  @override
  String get settingsDefaultTimeSubtitle =>
      'Áp dụng cho mốc chưa đặt giờ riêng';

  @override
  String settingsMilestoneUsesDefault(String time) {
    return 'Theo mặc định · $time';
  }

  @override
  String get settingsMilestoneCustomTimeReset => 'Về giờ mặc định';

  @override
  String get remindersV2ForceOpenTitle => 'Bật nhắc nhở để tiếp tục';

  @override
  String get remindersV2ForceOpenBody =>
      'Bạn cần bật \"Nhắc cột mốc & kỷ niệm\" để tạo và nhận lời nhắc riêng của hai bạn.';

  @override
  String get remindersV2ForceOpenConfirm => 'Bật';

  @override
  String get remindersV2ForceOpenLater => 'Để sau';

  @override
  String get remindersV2ForceOpenDeniedMsg =>
      'Chưa cấp quyền thông báo. Hãy bật thông báo trong Cài đặt để tiếp tục.';

  @override
  String get languageSearchHint => 'Tìm ngôn ngữ';

  @override
  String get customRemindersEntryTitle => 'Lời nhắc của chúng mình';

  @override
  String get customRemindersEntrySubtitle => 'Tự tạo mốc riêng của hai bạn';

  @override
  String get customRemindersScreenTitle => 'Lời nhắc của chúng mình';

  @override
  String customRemindersCount(int count) {
    return '$count/20';
  }

  @override
  String customRemindersNextFire(String date) {
    return 'Sắp tới: $date';
  }

  @override
  String get customRemindersDisabledLabel => 'Đã tắt';

  @override
  String get customRemindersFabTooltip => 'Thêm lời nhắc';

  @override
  String get customRemindersItemMenuEdit => 'Sửa';

  @override
  String get customRemindersItemMenuDelete => 'Xoá';

  @override
  String get customRemindersEmptyTitle => 'Chưa có lời nhắc nào';

  @override
  String get customRemindersEmptyBody =>
      'Tạo mốc riêng của hai bạn: sinh nhật, monthsary, ngày đặc biệt…';

  @override
  String get customRemindersEmptyCta => 'Tạo lời nhắc đầu tiên';

  @override
  String get customRemindersOffTitle => 'Lời nhắc đang tắt';

  @override
  String get customRemindersOffBody =>
      'Hãy bật \"Nhắc nhớ yêu thương\" ở trang Hồ sơ để các lời nhắc có hiệu lực.';

  @override
  String get customRemindersOffCta => 'Bật lời nhắc';

  @override
  String get customRemindersLimitMsg =>
      'Bạn đã đạt tối đa 20 lời nhắc. Hãy xoá bớt để thêm mới.';

  @override
  String get customRemindersAddTitle => 'Lời nhắc mới';

  @override
  String get customRemindersEditTitle => 'Sửa lời nhắc';

  @override
  String get customRemindersSave => 'Lưu';

  @override
  String get customRemindersCancel => 'Huỷ';

  @override
  String get customRemindersSavedMsg => 'Đã lưu lời nhắc 💌';

  @override
  String get customRemindersNameLabel => 'Tên lời nhắc';

  @override
  String get customRemindersNameRequiredMark => '*';

  @override
  String get customRemindersNameHint => 'vd: Sinh nhật em';

  @override
  String get customRemindersNoteLabel => 'Ghi chú (tuỳ chọn)';

  @override
  String get customRemindersNoteHint => 'Lời yêu thương kèm theo…';

  @override
  String get customRemindersDateLabel => 'Ngày';

  @override
  String get customRemindersTimeLabel => 'Giờ';

  @override
  String get customRemindersRepeatLabel => 'Lặp lại';

  @override
  String get customRemindersRepeatOnce => 'Một lần';

  @override
  String get customRemindersRepeatDaily => 'Hằng ngày';

  @override
  String get customRemindersRepeatWeekly => 'Hằng tuần';

  @override
  String get customRemindersRepeatMonthly => 'Hằng tháng';

  @override
  String get customRemindersRepeatYearly => 'Hằng năm';

  @override
  String customRemindersMetaOnce(String date, String time) {
    return 'Một lần · $date · $time';
  }

  @override
  String customRemindersMetaDaily(String time) {
    return 'Hằng ngày · $time';
  }

  @override
  String customRemindersMetaWeekly(String weekday, String time) {
    return 'Hằng tuần · $weekday · $time';
  }

  @override
  String customRemindersMetaMonthly(int day, String time) {
    return 'Hằng tháng · ngày $day · $time';
  }

  @override
  String customRemindersMetaYearly(String dayMonth, String time) {
    return 'Hằng năm · $dayMonth · $time';
  }

  @override
  String get customRemindersNameError => 'Hãy đặt tên cho lời nhắc';

  @override
  String get customRemindersPastDateWarning =>
      'Ngày đã qua rồi — chọn ngày khác';

  @override
  String get customRemindersDeleteSectionHint => 'Không thể hoàn tác';

  @override
  String get customRemindersDeleteButton => 'Xoá lời nhắc';

  @override
  String get customRemindersDeleteDialogTitle => 'Xoá lời nhắc này?';

  @override
  String customRemindersDeleteDialogBody(String name) {
    return '\"$name\" sẽ bị xoá và không nhắc bạn nữa.';
  }

  @override
  String get customRemindersDeleteConfirm => 'Xoá';

  @override
  String get customRemindersDeletedMsg => 'Đã xoá lời nhắc';

  @override
  String get customRemindersNotifBodyFallback =>
      'Một mốc đáng nhớ của hai bạn 💞';

  @override
  String get agreeToPrivacyPolicy => 'Tôi đồng ý với Chính sách bảo mật';

  @override
  String get appTitle => 'Kỷ Niệm Của Chúng Mình';

  @override
  String get authAccountNotFound => 'Không tìm thấy tài khoản với email này.';

  @override
  String get authConfigNotFound =>
      'Firebase Authentication của project này chưa được bật hoặc chưa bật Email/Password. Bạn vào Firebase Console > Authentication > Sign-in method > Email/Password để bật lên.';

  @override
  String get authEmailAlreadyUsed => 'Email này đã được sử dụng rồi.';

  @override
  String get authEmailPasswordNotEnabled =>
      'Firebase Authentication chưa được cấu hình đầy đủ cho Email/Password. Bạn vào Firebase Console > Authentication > Sign-in method và bật Email/Password nhé.';

  @override
  String get authFirebaseAuthGeneric => 'Đã có lỗi Firebase Auth xảy ra.';

  @override
  String get authFirebaseUserCreateFailed =>
      'Không tạo được người dùng Firebase.';

  @override
  String get authFirestoreGeneric => 'Đã có lỗi Firestore xảy ra.';

  @override
  String get authFirestorePermissionDenied =>
      'Firestore đang chặn quyền ghi dữ liệu người dùng. Hãy kiểm tra Firestore Rules của project đang kết nối và cho phép user đã đăng nhập tạo/ghi `users/<uid>` cùng `invite_codes/<code>` của chính họ.';

  @override
  String get authFirestoreUnavailable =>
      'Firestore hiện chưa khả dụng hoặc mạng không ổn định. Bạn thử lại sau ít phút nhé.';

  @override
  String get authInvalidCredential => 'Email hoặc mật khẩu chưa đúng.';

  @override
  String get authInvalidEmail => 'Email chưa hợp lệ.';

  @override
  String get authInviteCodeGenerateFailed =>
      'Không thể tạo mã mời mới, bạn thử lại sau nhé.';

  @override
  String get authInviteCodeUnavailable =>
      'Không thể tạo mã mời cho tài khoản lúc này, bạn thử lại nhé.';

  @override
  String get authNetworkError =>
      'Không có kết nối mạng ổn định để đăng nhập Firebase.';

  @override
  String get authSessionNotReady =>
      'Phiên đăng nhập Firebase chưa sẵn sàng. Bạn thử đăng nhập lại giúp mình nhé.';

  @override
  String get authSessionUnavailable =>
      'Không thể lấy phiên đăng nhập Firebase.';

  @override
  String get authTooManyRequests =>
      'Bạn thử lại sau ít phút nhé, hiện có quá nhiều yêu cầu đăng nhập.';

  @override
  String get authWeakPassword =>
      'Mật khẩu còn yếu, bạn chọn mật khẩu mạnh hơn nhé.';

  @override
  String get authWrongPassword => 'Mật khẩu chưa đúng, bạn kiểm tra lại nhé.';

  @override
  String get bootstrapAndroidNotReady =>
      'Firebase Android chưa sẵn sàng. Kiểm tra lại `android/app/google-services.json` và package name của app.';

  @override
  String get bootstrapIosNotConfigured =>
      'Bạn đang chạy iOS nhưng project chưa có `GoogleService-Info.plist`, nên app đang rơi về local fallback.';

  @override
  String get bootstrapLinuxNotConfigured =>
      'Firebase cho Linux chưa được cấu hình nên app đang chạy local fallback.';

  @override
  String get bootstrapMacosNotConfigured =>
      'Firebase cho macOS chưa được cấu hình nên app đang chạy local fallback.';

  @override
  String get bootstrapPlatformNotConfigured =>
      'Firebase chưa được cấu hình cho platform hiện tại nên app đang chạy local fallback.';

  @override
  String get bootstrapWebNotConfigured =>
      'Firebase chưa được cấu hình cho Web nên app đang chạy local fallback.';

  @override
  String get bootstrapWindowsNotConfigured =>
      'Firebase cho Windows chưa được cấu hình nên app đang chạy local fallback.';

  @override
  String get coupleAlreadyInCouple => 'Tài khoản này đã thuộc một cặp đôi rồi.';

  @override
  String get coupleAlreadyInThisCouple => 'Bạn đã ở trong cặp đôi này rồi.';

  @override
  String get coupleCannotUseOwnCode =>
      'Bạn không thể nhập mã mời của chính mình.';

  @override
  String get coupleCodeNoLongerValid =>
      'Mã mời này không còn trỏ tới một cặp đôi hợp lệ nữa.';

  @override
  String get coupleCodeNotFoundLocal =>
      'Không tìm thấy mã kết nối trong local fallback.';

  @override
  String get coupleEnterCodeFirst => 'Bạn hãy nhập mã kết nối trước nhé.';

  @override
  String get coupleFirebaseUnavailable =>
      'Firebase hiện chưa khả dụng hoặc mạng chưa ổn định. Bạn thử lại sau ít phút nhé.';

  @override
  String get coupleFull => 'Cặp đôi này đã đủ 2 người rồi.';

  @override
  String get coupleFullLocal => 'Cặp đôi local này đã đủ 2 người rồi.';

  @override
  String get coupleInviteCodeInvalid =>
      'Mã mời không hợp lệ hoặc không còn tồn tại.';

  @override
  String get coupleJoinGeneric => 'Không thể kết nối bằng mã mời lúc này.';

  @override
  String get coupleJoinPermissionDenied =>
      'Không thể kết nối bằng mã mời này. Có thể không gian cặp đôi đã thay đổi hoặc không còn hợp lệ — bạn nhờ người ấy tạo lại mã mời, hoặc đăng xuất/đăng nhập lại rồi thử nhé.';

  @override
  String get coupleMatchedLocal => 'Đã ghép cặp trong local fallback mode.';

  @override
  String get coupleNoDataToUpdate => 'Chưa có thông tin cặp đôi để cập nhật.';

  @override
  String get coupleNotFoundForCode =>
      'Không tìm thấy cặp đôi tương ứng với mã này.';

  @override
  String get coupleOnboardingBadge => 'BẮT ĐẦU';

  @override
  String get couplePartnerHasNoSpace =>
      'Người ấy đã có mã mời riêng nhưng chưa tạo không gian cặp đôi để bạn tham gia.';

  @override
  String get couplePhotoUploadGeneric =>
      'Ảnh đôi chưa upload được lên Firebase Storage.';

  @override
  String get couplePhotoUploadPermission =>
      'Ảnh đôi chưa upload được lên Firebase Storage. Mình vẫn lưu thông tin cặp đôi trước, bạn deploy `storage.rules` rồi thử đổi ảnh lại sau nhé.';

  @override
  String get couplePhotoUploadSessionInvalid =>
      'Ảnh đôi chưa upload được vì phiên đăng nhập Firebase không còn hợp lệ.';

  @override
  String get couplePhotoUploadUnavailable =>
      'Ảnh đôi chưa upload được vì Firebase Storage hoặc mạng đang tạm thời không ổn định.';

  @override
  String get coupleSaveGeneric => 'Không thể lưu thông tin cặp đôi lúc này.';

  @override
  String get coupleSavePermissionDenied =>
      'Không thể lưu thông tin cặp đôi do quyền truy cập bị từ chối. Dữ liệu có thể đang ở trạng thái không hợp lệ — bạn thử đăng xuất/đăng nhập lại rồi thử lại nhé.';

  @override
  String get coupleSessionExpiredJoin =>
      'Phiên đăng nhập đã hết hạn. Bạn đăng nhập lại rồi thử kết nối lại nhé.';

  @override
  String get coupleSessionInvalid =>
      'Phiên đăng nhập Firebase không còn hợp lệ. Bạn đăng nhập lại giúp mình nhé.';

  @override
  String get coupleSessionNotReadyRelogin =>
      'Phiên đăng nhập Firebase chưa sẵn sàng. Bạn đăng xuất rồi đăng nhập lại giúp mình nhé.';

  @override
  String get coupleSpaceInvalidRegenerate =>
      'Mã mời này đang trỏ tới một không gian cặp đôi không còn hợp lệ. Bạn nhờ người ấy tạo lại mã mời rồi thử lại nhé.';

  @override
  String get coupleUpdatedSuccess => 'Đã cập nhật thông tin cặp đôi.';

  @override
  String get coupleUserNotFoundForCreate =>
      'Không tìm thấy người dùng hiện tại để tạo cặp đôi.';

  @override
  String get createAccountBadge => 'TẠO TÀI KHOẢN';

  @override
  String get defaultDisplayName => 'Người dùng mới';

  @override
  String get deleteAccountBtn => 'Xóa tài khoản';

  @override
  String get deleteAccountConfirmBtn => 'Xóa vĩnh viễn';

  @override
  String get deleteAccountDesc =>
      'Xóa vĩnh viễn tài khoản và toàn bộ dữ liệu của bạn';

  @override
  String get deleteAccountDialogContent =>
      'Hành động này không thể hoàn tác. Toàn bộ dữ liệu của bạn bao gồm ảnh và thông tin cặp đôi sẽ bị xóa vĩnh viễn.';

  @override
  String get deleteAccountDialogTitle => 'Xóa tài khoản?';

  @override
  String get deleteAccountFailed =>
      'Hiện chưa thể xoá tài khoản. Vui lòng thử lại.';

  @override
  String get deleteAccountRequiresReloginMsg =>
      'Vui lòng đăng xuất, đăng nhập lại và thử lại để xác nhận danh tính';

  @override
  String get deleteAccountReauthTitle => 'Xác minh đó là bạn';

  @override
  String get deleteAccountReauthBody =>
      'Vì lý do bảo mật, hãy nhập lại mật khẩu để xoá tài khoản vĩnh viễn.';

  @override
  String get deleteAccountSessionExpiredMsg =>
      'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại rồi xoá tài khoản.';

  @override
  String get deleteAccountSuccessMsg => 'Tài khoản đã được xóa';

  @override
  String get deleteAccountTitle => 'Xóa tài khoản';

  @override
  String get editCoupleBadge => 'CHỈNH SỬA';

  @override
  String get galleryEditCaptionTooltip => 'Sửa chú thích';

  @override
  String get galleryEmptySubtitle => 'Thêm ảnh để bắt đầu tạo kỷ niệm';

  @override
  String get galleryEmptyTitle => 'Chưa có ảnh nào';

  @override
  String get galleryRecordTodayMoment => 'Ghi lại khoảnh khắc hôm nay';

  @override
  String get galleryTodayBadge => 'Hôm nay';

  @override
  String get galleryTodayEmptySubtitle =>
      'Đừng để ngày này trôi qua không dấu vết.';

  @override
  String get galleryTodayEmptyTitle => 'Hôm nay chưa có khoảnh khắc nào';

  @override
  String get homeWaitingPartnerSubtitle =>
      'Chia sẻ mã mời với người ấy để bắt đầu hành trình cùng nhau.';

  @override
  String get homeWaitingPartnerTitle => 'Chờ bạn đồng hành';

  @override
  String get leavingCouple => 'Đang rời cặp đôi...';

  @override
  String get loveHomeBadge => 'TRANG CHỦ';

  @override
  String get mustAgreeToPrivacyPolicy =>
      'Vui lòng đồng ý với chính sách bảo mật để tiếp tục';

  @override
  String get photoConnectCoupleFirst =>
      'Bạn cần kết nối couple trước khi đăng ảnh.';

  @override
  String get photoFileNotFoundStorage =>
      'Không tìm thấy file ảnh trên Firebase Storage.';

  @override
  String get photoFirebaseUnavailable =>
      'Firebase hiện chưa khả dụng hoặc mạng chưa ổn định.';

  @override
  String get photoNotFoundToPost => 'Không tìm thấy ảnh để đăng.';

  @override
  String get photoStorageUnauthorized =>
      'Firebase Storage đang từ chối thao tác với ảnh này.';

  @override
  String get photoSyncGeneric => 'Không thể đồng bộ ảnh lúc này.';

  @override
  String get photoSyncPermissionDenied =>
      'Bạn chưa có quyền đồng bộ ảnh. Hãy kiểm tra `firestore.rules` và `storage.rules` trên Firebase.';

  @override
  String get photoSyncSessionExpired =>
      'Phiên đăng nhập Firebase đã hết hạn. Bạn đăng nhập lại giúp mình nhé.';

  @override
  String get posterNameFallback => 'Người ấy';

  @override
  String get privacyDisclosure =>
      'Bằng cách tạo tài khoản, bạn đồng ý với Chính sách bảo mật của chúng tôi. Chúng tôi thu thập email, tên hiển thị và ảnh bạn chia sẻ để cung cấp dịch vụ.';

  @override
  String get privacyPolicyLabel => 'Chính sách bảo mật';

  @override
  String get profileDangerIrreversible => 'Không thể hoàn tác';

  @override
  String get pushPhotoChannelDescription =>
      'Thông báo khi người ấy đăng ảnh mới.';

  @override
  String get pushPhotoChannelName => 'Ảnh mới từ người ấy';

  @override
  String get signOutBtn => 'Đăng xuất';

  @override
  String get signOutConfirmBtn => 'Đăng xuất';

  @override
  String get signOutDialogContent =>
      'Bạn có chắc muốn đăng xuất khỏi tài khoản không?';

  @override
  String get signOutDialogTitle => 'Đăng xuất?';

  @override
  String get signOutFailedMsg =>
      'Không thể đăng xuất. Vui lòng kiểm tra kết nối và thử lại.';

  @override
  String get welcomeBackBadge => 'CHÀO MỪNG TRỞ LẠI';

  @override
  String counterDuration(int years, int months, int days) {
    return '$years năm, $months tháng, $days ngày';
  }

  @override
  String coupleLoadError(String error) {
    return 'Không thể tải thông tin cặp đôi: $error';
  }

  @override
  String coupleSyncError(String error) {
    return 'Không thể đồng bộ thông tin cặp đôi: $error';
  }

  @override
  String galleryMonthLabel(String month, String year) {
    String _temp0 = intl.Intl.selectLogic(month, {
      '1': 'Tháng 01 • $year',
      '2': 'Tháng 02 • $year',
      '3': 'Tháng 03 • $year',
      '4': 'Tháng 04 • $year',
      '5': 'Tháng 05 • $year',
      '6': 'Tháng 06 • $year',
      '7': 'Tháng 07 • $year',
      '8': 'Tháng 08 • $year',
      '9': 'Tháng 09 • $year',
      '10': 'Tháng 10 • $year',
      '11': 'Tháng 11 • $year',
      '12': 'Tháng 12 • $year',
      'other': 'Tháng $month • $year',
    });
    return '$_temp0';
  }

  @override
  String galleryTodayMomentsCount(int count) {
    return '$count khoảnh khắc hôm nay';
  }

  @override
  String homeCounterStartFrom(String date) {
    return 'Bắt đầu từ $date';
  }

  @override
  String get guestTryWithoutLogin => 'Dùng thử không cần đăng nhập';

  @override
  String get guestLoginDivider => 'hoặc';

  @override
  String get guestModeBadge => 'Chế độ dùng thử';

  @override
  String get guestCounterTitle => 'Đếm ngày yêu';

  @override
  String get guestCounterSubtitle =>
      'Nhập ngày hai bạn bắt đầu để xem đã bên nhau bao lâu.';

  @override
  String get guestEmptyTitle => 'Bắt đầu đếm ngày yêu của bạn';

  @override
  String get guestEmptyBody =>
      'Chọn ngày kỷ niệm để xem hai bạn đã bên nhau bao lâu rồi.';

  @override
  String get guestPickDate => 'Chọn ngày kỷ niệm';

  @override
  String get guestChangeDate => 'Đổi ngày kỷ niệm';

  @override
  String guestCounterStartFrom(String date) {
    return 'Bắt đầu từ $date';
  }

  @override
  String get guestCtaTitle => 'Muốn lưu kỷ niệm cùng người ấy?';

  @override
  String get guestCtaBody => 'Đăng nhập để ghép đôi & lưu ảnh chung.';

  @override
  String get guestCtaSignIn => 'Đăng nhập';

  @override
  String get guestCtaRegister => 'Đăng ký';

  @override
  String get streakChipNoStreak => 'Bắt đầu chuỗi cùng nhau';

  @override
  String get streakChipRestart => 'Cùng bắt đầu chuỗi mới nhé 🌱';

  @override
  String streakChipActiveToday(int n) {
    return '$n ngày kết nối · hôm nay xong rồi ✨';
  }

  @override
  String streakChipInProgress(int n) {
    return '$n ngày kết nối · tới lượt hôm nay 🌸';
  }

  @override
  String streakChipAtRisk(int n) {
    return 'Chuỗi $n ngày đang chờ hai đứa 🫶';
  }

  @override
  String get streakSheetUnit => 'ngày kết nối liên tiếp';

  @override
  String get streakSheetNoStreakTitle => 'Thắp ngọn lửa đầu tiên';

  @override
  String get streakSheetNoStreakBody =>
      'Mỗi ngày hai đứa cùng trả lời câu hỏi là chuỗi lại dài thêm. Cùng bắt đầu nhé 💞';

  @override
  String get streakSheetActiveTitle => 'Hai đứa đang giữ lửa 💞';

  @override
  String get streakSheetActiveBody =>
      'Hôm nay xong rồi đó! Hẹn gặp ở câu hỏi ngày mai nha.';

  @override
  String get streakSheetInProgressTitle => 'Chuỗi vẫn đang cháy 🌸';

  @override
  String streakSheetInProgressBody(int n) {
    return 'Trả lời câu hỏi hôm nay để hai đứa cùng nối tiếp chuỗi $n ngày nhé 💞';
  }

  @override
  String get streakSheetAtRiskTitle => 'Còn một nhịp đệm thôi 🫶';

  @override
  String streakSheetAtRiskBody(int n) {
    return 'Hôm qua hai đứa lỡ một nhịp — không sao cả! Trả lời hôm nay là chuỗi $n ngày tiếp tục liền.';
  }

  @override
  String get streakSheetRestartBody =>
      'Chuỗi cũ khép lại rồi, nhưng mỗi ngày mới là một khởi đầu. Cùng thắp lại nào 🌱';

  @override
  String streakSheetRecord(int m) {
    return 'Kỷ lục của hai đứa: $m ngày 🌟';
  }

  @override
  String streakNextMilestone(int n, int m) {
    return 'Còn $n ngày tới mốc $m 🎉';
  }

  @override
  String get streakCtaAnswerNow => 'Trả lời ngay';

  @override
  String get streakCtaKeepGoing => 'Giữ chuỗi nhé';

  @override
  String get streakMilestone3Title => '3 ngày rồi đó! 🌸';

  @override
  String get streakMilestone3Body =>
      'Khởi đầu thật đáng yêu. Hai đứa đang làm tốt lắm 💞';

  @override
  String get streakMilestone7Title => 'Trọn một tuần! ✨';

  @override
  String get streakMilestone7Body =>
      '7 ngày liền hai đứa không lỡ nhịp nào. Tự hào ghê!';

  @override
  String get streakMilestone30Title => '30 ngày bên nhau mỗi ngày! 🔥';

  @override
  String get streakMilestone30Body =>
      'Một tháng giữ lửa — đây là thói quen của hai đứa rồi đấy 💞';

  @override
  String get streakMilestone100Title => '100 ngày! 💯';

  @override
  String get streakMilestone100Body =>
      'Trăm ngày cùng nhau trả lời, cùng nhau lớn lên. Hiếm cặp nào làm được như hai đứa 🌟';

  @override
  String get streakMilestone365Title => 'Tròn một năm! 👑';

  @override
  String get streakMilestone365Body =>
      '365 ngày không lỡ một nhịp kết nối. Đây là chuyện tình của riêng hai đứa 💞👑';

  @override
  String streakJournalSummary(int n, int m) {
    return 'Chuỗi hiện tại $n ngày · Dài nhất $m';
  }

  @override
  String get streakJournalSummaryNone =>
      'Cùng trả lời mỗi ngày để bắt đầu chuỗi nhé 🌸';

  @override
  String get forgotPasswordLink => 'Quên mật khẩu?';

  @override
  String get forgotPasswordBadge => 'KHÔI PHỤC TRUY CẬP';

  @override
  String get forgotPasswordTitle => 'Quên mật khẩu?';

  @override
  String get forgotPasswordSubtitle =>
      'Nhập email của bạn, mình sẽ gửi liên kết để đặt lại mật khẩu.';

  @override
  String get forgotPasswordEmailHeading => 'Email';

  @override
  String get forgotPasswordSendBtn => 'Gửi email đặt lại';

  @override
  String get forgotPasswordBackToLogin => 'Quay lại đăng nhập';

  @override
  String get forgotPasswordSentTitle => 'Kiểm tra hộp thư';

  @override
  String forgotPasswordSentBody(String email) {
    return 'Đã gửi liên kết đặt lại mật khẩu tới $email. Mở mail và bấm vào liên kết để đặt lại. Nhớ kiểm tra cả mục spam nhé.';
  }

  @override
  String get forgotPasswordResendLink => 'Không nhận được? Gửi lại';

  @override
  String get forgotPasswordNetworkError =>
      'Không gửi được email. Kiểm tra kết nối mạng rồi thử lại nhé.';

  @override
  String get forgotPasswordLocalFallback =>
      'Tính năng này cần kết nối mạng. Bạn kết nối internet rồi thử lại nhé.';

  @override
  String get verifyEmailBadge => 'XÁC THỰC EMAIL';

  @override
  String get verifyEmailTitle => 'Xác thực email của bạn';

  @override
  String verifyEmailSubtitle(String email) {
    return 'Mình đã gửi liên kết xác thực tới $email.';
  }

  @override
  String get verifyEmailBody =>
      'Mở email, bấm vào liên kết xác thực, rồi quay lại đây và bấm \"Tôi đã xác thực\".';

  @override
  String get verifyEmailCheckBtn => 'Tôi đã xác thực';

  @override
  String get verifyEmailResend => 'Gửi lại email';

  @override
  String verifyEmailResendCountdown(String time) {
    return 'Gửi lại sau $time';
  }

  @override
  String get verifyEmailNotYet =>
      'Chưa thấy xác thực — bạn kiểm tra lại hộp thư rồi thử lại nhé.';

  @override
  String get verifyEmailSuccess => 'Đã xác thực! Đang đưa bạn vào...';

  @override
  String get verifyEmailResendError =>
      'Không gửi lại được email. Kiểm tra kết nối rồi thử lại nhé.';

  @override
  String get setupWaitingCoupleCodeTitle =>
      'Gửi mã này cho người ấy để ghép đôi';

  @override
  String get setupCoupleCodeDesc =>
      'Đây là mã ghép đôi của hai bạn. Cả hai đều dùng mã này để kết nối lại nếu cần.';

  @override
  String get setupCoupleCodeRejoinHint =>
      'Lưu mã lại — bạn có thể dùng nó để quay lại không gian này bất cứ lúc nào.';

  @override
  String get galleryNeedsCoupleToUpload =>
      'Bạn cần ghép đôi trước để đăng ảnh chung nhé 💞';
}

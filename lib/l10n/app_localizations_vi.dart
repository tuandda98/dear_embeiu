// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get back => 'Quay lại';

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
  String setupEditTitle(String me, String partner) {
    return 'Chỉnh sửa câu chuyện của\n$me ❤️ $partner';
  }

  @override
  String get setupEditTitleGeneric => 'Chỉnh sửa\ncâu chuyện của chúng mình';

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
  String get navChat => 'Trò chuyện';

  @override
  String get navMemories => 'Kỷ niệm';

  @override
  String get navProfile => 'Hồ sơ';

  @override
  String get chatBadge => 'CHUYỆN CỦA CHÚNG MÌNH';

  @override
  String get chatHeaderSubtitle => 'Nơi chúng mình nói đủ thứ chuyện trên đời.';

  @override
  String get chatEmptyHint =>
      'Chưa có tin nhắn nào — gửi lời đầu tiên cho người ấy nhé 💬';

  @override
  String get chatComposerHint => 'Nhắn gì đó cho người ấy…';

  @override
  String get chatSendFailed => 'Chưa gửi được tin nhắn. Thử lại nhé.';

  @override
  String get chatSendSemantics => 'Gửi tin nhắn';

  @override
  String get chatSending => 'Đang gửi…';

  @override
  String get chatStatusSent => 'Đã gửi';

  @override
  String get chatStatusDelivered => 'Đã nhận';

  @override
  String get chatStatusRead => 'Đã xem';

  @override
  String get lunarSectionTitle => 'Lịch âm';

  @override
  String lunarDateLabel(int month, int day) {
    return '$day tháng $month Âm';
  }

  @override
  String get lunarTodayLabel => 'Hôm nay';

  @override
  String get lunarNextNewMoon => 'Mồng 1 tới';

  @override
  String get lunarNextFullMoon => 'Ngày rằm tới';

  @override
  String get lunarReminderToggle => 'Nhắc theo ngày âm lịch';

  @override
  String get lunarReminderToggleSub => 'Vào ngày & giờ bạn chọn';

  @override
  String get lunarNewMoonNotifTitle => 'Mồng một âm lịch 🌙';

  @override
  String get lunarNewMoonNotifBody => 'Hôm nay là ngày mồng một âm lịch.';

  @override
  String get lunarFullMoonNotifTitle => 'Ngày rằm 🌕';

  @override
  String get lunarFullMoonNotifBody => 'Hôm nay là ngày rằm (15 âm lịch).';

  @override
  String lunarOtherDayNotifTitle(int day) {
    return 'Ngày $day âm lịch 🌙';
  }

  @override
  String lunarOtherDayNotifBody(int day) {
    return 'Hôm nay là ngày $day âm lịch.';
  }

  @override
  String get lunarCalendarBadge => 'LỊCH ÂM';

  @override
  String get lunarOpenCalendar => 'Mở lịch âm';

  @override
  String get lunarRemindDaysLabel => 'Ngày nhắc (âm lịch)';

  @override
  String get lunarRemindTimesLabel => 'Giờ nhắc';

  @override
  String get lunarAddTime => 'Thêm giờ';

  @override
  String get chatUnreadDotSemantics => 'Có tin nhắn mới';

  @override
  String get chatWaitingPartnerTitle => 'Còn thiếu một người nè';

  @override
  String get chatWaitingPartnerBody =>
      'Mời người ấy ghép đôi để bắt đầu cuộc trò chuyện riêng của chúng mình.';

  @override
  String get chatWaitingPartnerCta => 'Mời ghép đôi';

  @override
  String get ourStoryBadge => 'CÂU CHUYỆN CỦA CHÚNG MÌNH';

  @override
  String get helloGreeting => 'Xin chào,';

  @override
  String get homeSubtitle =>
      'Hôm nay là ngày tốt để nhìn lại câu chuyện tình yêu.';

  @override
  String get homeGreetingMorning => 'Chào buổi sáng,';

  @override
  String get homeGreetingAfternoon => 'Chào buổi chiều,';

  @override
  String get homeGreetingEvening => 'Chào buổi tối,';

  @override
  String get homeGreetingNight => 'Khuya rồi đó,';

  @override
  String get homeGreetingTeaser1 => 'Gửi người ấy một cái ôm thật chặt 🤗';

  @override
  String get homeGreetingTeaser2 => 'Hôm nay đã nói yêu người ấy chưa? 💕';

  @override
  String get homeGreetingTeaser3 => 'Gửi người ấy một tấm ảnh xinh nhé 📸';

  @override
  String get homeGreetingTeaser4 => 'Người ấy đang chờ tin của bạn đó 🕊️';

  @override
  String get homeGreetingTeaser5 => 'Đừng quên câu hỏi hôm nay nha ✨';

  @override
  String get homeGreetingTeaser6 => 'Một lời ngọt ngào cho người ấy nào 🍯';

  @override
  String get homeGreetingTeaser7 => 'Nói một lời cảm ơn nhỏ xíu hôm nay nhé 💞';

  @override
  String get homeGreetingTeaser8 =>
      'Một khoảnh khắc bình yên bên nhau là đủ rồi 🍃';

  @override
  String get homeGreetingTeaser9 => 'Một ngày thật đẹp để yêu thương 💖';

  @override
  String get homeGreetingTeaser10 => 'Nhắn người ấy là bạn đang nhớ họ nha 💭';

  @override
  String get homeGreetingTeaser11 =>
      'Cùng nhau viết tiếp chuyện tình của chúng mình ✍️';

  @override
  String get homeGreetingTeaser12 => 'Cùng nhau giữ chuỗi ngày yêu nhé 🔥';

  @override
  String get homeTodaySectionTitle => 'Hôm nay của chúng mình';

  @override
  String get dailyTapToAnswer => 'Chạm để trả lời…';

  @override
  String dailyPartnerAnsweredTeaser(String name) {
    return '$name đã trả lời rồi đó 👀';
  }

  @override
  String get dailyAnswerToReveal =>
      'Trả lời để mở khoá câu trả lời của người ấy';

  @override
  String get dailyBothAnsweredToday => 'Hôm nay cả hai đã trả lời';

  @override
  String get dailyReadAgain => 'Đọc lại';

  @override
  String get dailyCollapse => 'Thu gọn';

  @override
  String loveNoteSealedTitle(String name) {
    return 'Lời nhắn mới từ $name';
  }

  @override
  String get loveNoteSealedTap => 'Chạm để mở 💌';

  @override
  String get loveNoteNewBadge => 'MỚI';

  @override
  String get loveNoteComposeCta => 'Soạn tin nhắn';

  @override
  String loveNoteSheetTitleTo(String name) {
    return 'Gửi lời nhắn cho $name';
  }

  @override
  String get journalLinkShort => 'Nhật ký';

  @override
  String milestoneNextLabel(String label) {
    return 'Cột mốc $label';
  }

  @override
  String milestoneDaysLeft(int count) {
    return 'còn $count ngày';
  }

  @override
  String get milestoneTodayLabel => 'hôm nay 🎉';

  @override
  String onThisDayShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count năm trước 💞',
    );
    return '$_temp0';
  }

  @override
  String get counterBgSwipeHint => 'Vuốt ngang để đổi ảnh nền';

  @override
  String get dailyQuestionPairedFirst =>
      'Ghép đôi xong là chúng mình sẽ cùng trả lời một câu hỏi như vầy mỗi ngày 💞';

  @override
  String get loveNoteHistoryLinkShort => 'Lời nhắn cũ';

  @override
  String get loveNoteReplyCta => 'Nhắn lại…';

  @override
  String get loveNoteSendFirstCta => 'Gửi lời nhắn đầu tiên…';

  @override
  String get loveNoteStartChat =>
      'Chưa có lời nhắn nào — gửi cho nhau lời đầu tiên nhé 💌';

  @override
  String get loveNoteYouLabel => 'Bạn';

  @override
  String notificationBellLabel(int count) {
    return 'Thông báo, $count chưa đọc';
  }

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
  String cinemaCardSemantics(String caption, int index, int total) {
    return 'Kỷ niệm: $caption, ảnh $index trên $total. Chạm để xem toàn màn hình.';
  }

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
  String get daysUnit => 'Ngày';

  @override
  String get hoursShort => 'giờ';

  @override
  String get minutesShort => 'phút';

  @override
  String get secondsShort => 'giây';

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
  String get loveNoteSendFailed => 'Chưa gửi được lời nhắn — thử lại nhé.';

  @override
  String get loveNoteHistoryCta => 'Xem lại lời nhắn cũ';

  @override
  String get loveNoteHistoryTitle => 'Nhật ký lời nhắn';

  @override
  String get loveNoteHistorySubtitle =>
      'Tất cả những lời hai bạn đã để lại cho nhau.';

  @override
  String get loveNoteHistoryBadge => 'LỜI NHẮN YÊU THƯƠNG';

  @override
  String get loveNoteHistoryHeaderSubtitle =>
      'Tất cả lời nhắn hai bạn đã gửi nhau.';

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
  String get reactionBothShort => 'Cả hai đã thả tim';

  @override
  String reactionWaitingPartner(String name) {
    return 'Đang chờ $name cùng thả tim…';
  }

  @override
  String get reactionWaitingPartnerGeneric => 'Đang chờ người ấy cùng thả tim…';

  @override
  String get reactionPartnerFallback => 'Người ấy';

  @override
  String get moodCardTitle => 'Tâm trạng hôm nay';

  @override
  String get moodMatched => 'Chúng mình cùng một tâm trạng 💞';

  @override
  String get moodShareCta => 'Chia sẻ tâm trạng';

  @override
  String get moodUpdateCta => 'Đổi tâm trạng';

  @override
  String get moodNotSharedYou => 'Chạm để chia sẻ';

  @override
  String moodPartnerEmpty(String name) {
    return '$name chưa chia sẻ hôm nay';
  }

  @override
  String get moodSheetTitle => 'Hôm nay bạn thế nào?';

  @override
  String get moodNoteHint => 'Thêm đôi lời (không bắt buộc)';

  @override
  String get moodSaveCta => 'Lưu tâm trạng';

  @override
  String get moodHappy => 'Vui';

  @override
  String get moodLoved => 'Hạnh phúc';

  @override
  String get moodMissing => 'Nhớ';

  @override
  String get moodCalm => 'Bình yên';

  @override
  String get moodMeh => 'Bình thường';

  @override
  String get moodTired => 'Mệt';

  @override
  String get moodSad => 'Buồn';

  @override
  String get moodStressed => 'Căng thẳng';

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
  String get journalBadge => 'NHẬT KÝ CÂU HỎI';

  @override
  String get journalHeaderSubtitle => 'Những câu hỏi hai bạn đã cùng trả lời.';

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
  String get privateGalleryBadge => 'THƯ VIỆN ẢNH';

  @override
  String get galleryTitle => 'Thư viện ảnh';

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
  String get postNewPhotoBtn => 'Chụp hình';

  @override
  String get addMultipleBtn => 'Thêm hình';

  @override
  String get cameraUnavailable =>
      'Không mở được camera. Hãy thử lại hoặc kiểm tra quyền camera (máy ảo không có camera — dùng điện thoại thật nhé).';

  @override
  String get galleryDraftTitle => 'Xem trước & đăng';

  @override
  String get galleryDraftCaptionHint =>
      'Thêm chú thích chung (không bắt buộc)…';

  @override
  String get galleryDraftEmpty => 'Đã bỏ hết ảnh.';

  @override
  String galleryDraftPostBtn(int count) {
    return 'Đăng $count ảnh';
  }

  @override
  String get createPostTitle => 'Kỷ niệm mới';

  @override
  String get createPostBadge => 'KỶ NIỆM MỚI';

  @override
  String createPostAuthorMeta(String name, String when) {
    return 'Đăng bởi $name · $when';
  }

  @override
  String get today => 'Hôm nay';

  @override
  String get createPostCaptionHint => 'Hôm nay của hai bạn có gì?…';

  @override
  String get createPostAddMore => 'Thêm ảnh';

  @override
  String get createPostAddFromLibrary => 'Thêm ảnh từ thư viện';

  @override
  String createPostPhotoCount(int count) {
    return '$count ảnh';
  }

  @override
  String get createPostBtn => 'Đăng';

  @override
  String get createPostRemovePhoto => 'Gỡ ảnh';

  @override
  String get createPostDiscardTitle => 'Bỏ kỷ niệm này?';

  @override
  String get createPostDiscardMessage =>
      'Phần chú thích chúng mình vừa viết sẽ không được lưu.';

  @override
  String get createPostDiscardConfirm => 'Bỏ';

  @override
  String get createPostDiscardKeep => 'Tiếp tục soạn';

  @override
  String get addNewMemoryTitle => 'Thêm một kỷ niệm mới hôm nay';

  @override
  String get whatNewToday => 'hôm nay có gì mới?';

  @override
  String get composerSubtitle =>
      'Để thư viện thành một newfeed tình yêu thật riêng tư và đáng nhớ.';

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
  String get photoOptionsTitle => 'Tùy chọn ảnh';

  @override
  String get replacePhotoAction => 'Đổi ảnh khác';

  @override
  String get galleryReplacePhotoTooltip => 'Đổi ảnh khác';

  @override
  String get replacingPhoto => 'Đang cập nhật ảnh...';

  @override
  String get photoUpdatedSuccess => 'Đã cập nhật ảnh';

  @override
  String get photoUpdateError => 'Chưa cập nhật được ảnh, thử lại nhé.';

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
  String get yearsTogether => 'Năm';

  @override
  String get monthsRemaining => 'Tháng';

  @override
  String get totalDaysLabel => 'Tổng số ngày';

  @override
  String get totalHoursLabel => 'Tổng số giờ';

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
  String get profileChipDaysLabel => 'ngày bên nhau';

  @override
  String get profileChipAnniversaryLabel => 'ngày tới kỷ niệm';

  @override
  String get profileChipAnniversaryTodayLabel => 'kỷ niệm là hôm nay!';

  @override
  String get profileChipPhotosLabel => 'kỷ niệm đã lưu';

  @override
  String get profileMemoryChestTitle => 'Tủ kỷ niệm';

  @override
  String get profileStreakTile => 'Chuỗi kết nối';

  @override
  String get settingsSectionAccount => 'Tài khoản';

  @override
  String get settingsSectionNotifications => 'Thông báo';

  @override
  String get settingsSectionGeneral => 'Chung';

  @override
  String get settingsPushGroupLabel => 'Đẩy từ người ấy';

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
  String get leaveCoupleError =>
      'Chưa rời khỏi couple được lúc này. Kiểm tra kết nối mạng rồi thử lại nhé.';

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
      'Nhắc cả hai cùng trả lời mỗi ngày, đồng bộ trên cả hai máy.';

  @override
  String get dailyQuestionReminderTimeLabel => 'Nhắc lúc';

  @override
  String get dailyQuestionReminderTimesLabel => 'Giờ nhắc';

  @override
  String get dailyQuestionReminderAddTime => 'Thêm giờ nhắc';

  @override
  String dailyQuestionReminderRemoveTime(String time) {
    return 'Xoá giờ nhắc $time';
  }

  @override
  String get dailyQuestionReminderNotifTitle => 'Câu hỏi hôm nay đang chờ 💌';

  @override
  String get dailyQuestionReminderNotifBody =>
      'Ghé trả lời để mở khoá câu trả lời của người ấy nhé.';

  @override
  String get dailyQuestionReminderNotifBodyAlt1 =>
      'Hôm nay chúng mình có một câu hỏi mới — bạn trả lời trước nha 💞';

  @override
  String get dailyQuestionReminderNotifBodyAlt2 =>
      'Một câu hỏi nhỏ đang đợi chúng mình, ghé trả lời nhé 🌸';

  @override
  String get dqPartnerOnlyNudgeTitle => 'Chỉ còn người ấy nữa thôi 💌';

  @override
  String get dailyQuestionReminderEndOfDayHint =>
      'Nếu cuối ngày câu hỏi vẫn chưa xong, chúng mình được nhắc thêm lúc 21:00 — và cả 22:00, 23:00 nếu bạn vẫn chưa trả lời.';

  @override
  String get dqEndOfDayNudgeTitle => 'Ngày sắp khép lại rồi 🌙';

  @override
  String get dqEndOfDayNudgeBody =>
      'Câu hỏi hôm nay vẫn đang chờ — ghé trả lời trước khi hết ngày nhé.';

  @override
  String get dqEndOfDayNudgePartnerBody =>
      'Người ấy chưa trả lời câu hỏi hôm nay — nhắc một câu cho kịp nhé.';

  @override
  String get dqStreakWarningTitle => 'Sắp lỡ mất chuỗi rồi! 🔥';

  @override
  String dqStreakWarningBody(int days) {
    return 'Sắp hết ngày rồi. Trả lời câu hỏi để giữ chuỗi $days ngày của chúng mình nhé!';
  }

  @override
  String dqStreakWarningPartnerBody(int days) {
    return 'Người ấy chưa trả lời. Nhắc nhẹ một câu để khỏi đứt chuỗi $days ngày nhé!';
  }

  @override
  String get dqStreakWarningStartBody =>
      'Sắp hết ngày rồi! Trả lời câu hỏi để mở chuỗi mới cho chúng mình nhé.';

  @override
  String get dqStreakWarningStartPartnerBody =>
      'Người ấy chưa trả lời. Nhắc một câu để chúng mình cùng bắt đầu chuỗi nhé.';

  @override
  String get dqStreakWarningFinalTitle => 'Còn chưa đầy 1 tiếng nữa thôi! ⏳';

  @override
  String dqStreakWarningFinalBody(int days) {
    return 'Trả lời ngay để chuỗi $days ngày của chúng mình không đứt nhé 🔥';
  }

  @override
  String get dqStreakWarningFinalStartBody =>
      'Trả lời ngay để chúng mình mở chuỗi mới trước khi hết ngày nhé 🌱';

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
  String get milestoneBadge => 'NHỮNG NGÀY ĐẶC BIỆT';

  @override
  String get milestoneHeaderSubtitle =>
      'Chọn cột mốc muốn được nhắc và đặt giờ riêng.';

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
  String get settingsBadge => 'TUỲ CHỈNH ỨNG DỤNG';

  @override
  String get settingsHeaderSubtitle =>
      'Nhắc nhở, thông báo, ngôn ngữ và tài khoản của hai bạn.';

  @override
  String get settingsProfileTileSubtitle => 'Nhắc nhở, ngôn ngữ, tài khoản';

  @override
  String get settingsRemindersModuleTitle => 'Nhắc nhở';

  @override
  String get settingsRemindersModuleSubtitle =>
      'Cột mốc, kỷ niệm & lời nhắc riêng';

  @override
  String get settingsRemindersEntryTitle => 'Lời nhắc';

  @override
  String get settingsRemindersEntrySubtitle =>
      'Cột mốc, kỷ niệm và lời nhắc riêng của hai bạn';

  @override
  String get remindersHubBadge => 'LỜI NHẮC';

  @override
  String get remindersHubTitle => 'Lời nhắc của chúng mình';

  @override
  String get remindersHubSubtitle =>
      'Cột mốc, kỷ niệm và những lời nhắc riêng — tất cả ở một nơi.';

  @override
  String get remindersHubMilestonesSection => 'Cột mốc & kỷ niệm';

  @override
  String get remindersHubMilestonesSectionSub =>
      'Chọn cột mốc muốn được nhắc và đặt giờ riêng.';

  @override
  String get remindersHubCustomSection => 'Lời nhắc của chúng mình';

  @override
  String get remindersHubCustomSectionSub =>
      'Tự tạo lời nhắc cho những dịp riêng của hai bạn.';

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
  String get settingsNotifTypesTitle => 'Loại thông báo';

  @override
  String get settingsNotifTypesSubtitle =>
      'Tắt loại push bạn không muốn bị làm phiền. Chúng vẫn xuất hiện trong trung tâm thông báo.';

  @override
  String get settingsNotifTypePhoto => 'Ảnh mới';

  @override
  String get settingsNotifTypePhotoSubtitle => 'Khi người ấy đăng ảnh mới';

  @override
  String get settingsNotifTypeReaction => 'Thả tim ảnh';

  @override
  String get settingsNotifTypeReactionSubtitle =>
      'Khi người ấy thả cảm xúc vào ảnh của bạn';

  @override
  String get settingsNotifTypeDailyQuestion => 'Câu hỏi hôm nay';

  @override
  String get settingsNotifTypeDailyQuestionSubtitle =>
      'Khi người ấy trả lời câu hỏi hôm nay';

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
  String get customRemindersBadge => 'MỐC RIÊNG CỦA HAI BẠN';

  @override
  String get customRemindersHeaderSubtitle =>
      'Tự tạo lời nhắc cho những dịp riêng của hai bạn.';

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
  String get customRemindersAddAnother => 'Thêm lời nhắc';

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
  String get customReminderFormBadge => 'LỜI NHẮC RIÊNG';

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
  String get customRemindersNotifyPartnerLabel => 'Cũng nhắc người ấy';

  @override
  String get customRemindersNotifyPartnerSubtitle =>
      'Người ấy cũng nhận lời nhắc này vào đúng giờ';

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
  String get customRemindersUndoLabel => 'Hoàn tác';

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
  String get editCoupleBadge => 'HỒ SƠ CẶP ĐÔI';

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
      'Mỗi tấm ảnh là một kỷ niệm chung của nhau.';

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
  String get galleryEndOfFeed =>
      'Đã hết kỷ niệm 💕, hãy tạo thêm kỷ niệm mới cùng nhau nhé';

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
    return '$n ngày kết nối · hôm nay xong rồi';
  }

  @override
  String streakChipInProgress(int n) {
    return '$n ngày kết nối · tới lượt hôm nay 🌸';
  }

  @override
  String streakChipAtRisk(int n) {
    return 'Chuỗi $n ngày đang chờ chúng mình 🫶';
  }

  @override
  String get streakSheetUnit => 'ngày kết nối liên tiếp';

  @override
  String get streakSheetNoStreakTitle => 'Thắp ngọn lửa đầu tiên';

  @override
  String get streakSheetNoStreakBody =>
      'Mỗi ngày chúng mình cùng trả lời câu hỏi là chuỗi lại dài thêm. Cùng bắt đầu nhé 💞';

  @override
  String get streakSheetActiveTitle => 'Chúng mình đang giữ lửa 💞';

  @override
  String get streakSheetActiveBody =>
      'Hôm nay xong rồi đó! Hẹn gặp ở câu hỏi ngày mai nha.';

  @override
  String get streakSheetInProgressTitle => 'Chuỗi vẫn đang cháy 🌸';

  @override
  String streakSheetInProgressBody(int n) {
    return 'Trả lời câu hỏi hôm nay để chúng mình cùng nối tiếp chuỗi $n ngày nhé 💞';
  }

  @override
  String get streakSheetAtRiskTitle => 'Còn một nhịp đệm thôi 🫶';

  @override
  String streakSheetAtRiskBody(int n) {
    return 'Hôm qua chúng mình lỡ một nhịp — không sao cả! Trả lời hôm nay là chuỗi $n ngày tiếp tục liền.';
  }

  @override
  String get streakSheetRestartBody =>
      'Chuỗi cũ khép lại rồi, nhưng mỗi ngày mới là một khởi đầu. Cùng thắp lại nào 🌱';

  @override
  String streakSheetRecord(int m) {
    return 'Kỷ lục của chúng mình: $m ngày 🌟';
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
      'Khởi đầu thật đáng yêu. Chúng mình đang làm tốt lắm 💞';

  @override
  String get streakMilestone7Title => 'Trọn một tuần! ✨';

  @override
  String get streakMilestone7Body =>
      '7 ngày liền chúng mình không lỡ nhịp nào. Tự hào ghê!';

  @override
  String get streakMilestone30Title => '30 ngày bên nhau mỗi ngày! 🔥';

  @override
  String get streakMilestone30Body =>
      'Một tháng giữ lửa — đây là thói quen của chúng mình rồi đấy 💞';

  @override
  String get streakMilestone100Title => '100 ngày! 💯';

  @override
  String get streakMilestone100Body =>
      'Trăm ngày cùng nhau trả lời, cùng nhau lớn lên. Hiếm cặp nào làm được như chúng mình 🌟';

  @override
  String get streakMilestone365Title => 'Tròn một năm! 👑';

  @override
  String get streakMilestone365Body =>
      '365 ngày không lỡ một nhịp kết nối. Đây là chuyện tình của riêng chúng mình 💞👑';

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

  @override
  String get notifCenterTitle => 'Thông báo';

  @override
  String get notifCenterBadge => 'TIN MỚI CỦA HAI BẠN';

  @override
  String get notifCenterEmptyTitle => 'Chưa có thông báo';

  @override
  String get notifCenterEmptyBody =>
      'Hoạt động của hai bạn sẽ xuất hiện ở đây.';

  @override
  String get notifGroupToday => 'Hôm nay';

  @override
  String get notifGroupEarlier => 'Trước đó';

  @override
  String notifUnreadCount(int count) {
    return '$count chưa đọc';
  }

  @override
  String get notifAllCaughtUp => 'Hai bạn đã xem hết rồi 💛';

  @override
  String get notifMarkAllRead => 'Đánh dấu đã đọc';

  @override
  String get notifClearAll => 'Xoá tất cả';

  @override
  String get notifClearAllConfirmTitle => 'Xoá tất cả thông báo?';

  @override
  String get notifClearAllConfirmBody =>
      'Bạn sẽ không xem lại được những thông báo này.';

  @override
  String get notifDismiss => 'Xoá';

  @override
  String get notifGeneric => 'Bạn có thông báo mới';

  @override
  String notifPhotoPosted(String name) {
    return '$name vừa đăng ảnh mới';
  }

  @override
  String notifPhotoReaction(String name, String emoji) {
    return '$name đã thả $emoji vào ảnh của bạn';
  }

  @override
  String notifPartnerJoined(String name) {
    return '$name đã ghép đôi cùng bạn';
  }

  @override
  String notifPartnerLeft(String name) {
    return '$name đã rời khỏi không gian chung';
  }

  @override
  String notifLoveNote(String name) {
    return '$name vừa để lại lời nhắn';
  }

  @override
  String notifDailyQuestion(String name) {
    return '$name đã trả lời câu hỏi hôm nay';
  }

  @override
  String notifDailyQuestionBoth(String name) {
    return 'Bạn và $name đã trả lời câu hỏi hôm nay 💞';
  }

  @override
  String notifChatMessage(String name) {
    return '$name vừa gửi cho bạn một tin nhắn 💬';
  }

  @override
  String get forceUpdateBadge => 'CẬP NHẬT';

  @override
  String get forceUpdateTitle => 'Đã có bản cập nhật mới';

  @override
  String get forceUpdateBody =>
      'Phiên bản bạn đang dùng đã cũ rồi. Cập nhật lên bản mới nhất để tiếp tục lưu giữ kỷ niệm cùng người ấy nhé.';

  @override
  String get forceUpdateButton => 'Cập nhật ngay';

  @override
  String get counterBgBadge => 'ẢNH NỀN';

  @override
  String get counterBgTitle => 'Ảnh nền thẻ đếm';

  @override
  String get counterBgSubtitleAll =>
      'Chọn ảnh được dùng làm nền thẻ đếm ngày. Bỏ trống thì xoay vòng tất cả ảnh.';

  @override
  String counterBgSubtitleCount(int count) {
    return 'Đã chọn $count ảnh làm nền thẻ đếm.';
  }

  @override
  String get counterBgCoverLabel => 'Ảnh đại diện';

  @override
  String get counterBgEmptyTitle => 'Chưa có ảnh nào';

  @override
  String get counterBgEmptyBody =>
      'Hãy thêm vài kỷ niệm vào thư viện trước nhé.';

  @override
  String get settingsCounterBgTitle => 'Ảnh nền thẻ đếm';

  @override
  String get settingsCounterBgSubtitle => 'Chọn ảnh hiện trên thẻ đếm ngày';

  @override
  String get counterBgSave => 'Lưu';

  @override
  String get counterBgSavedMsg => 'Đã lưu ảnh nền thẻ đếm 💕';

  @override
  String get counterBgDiscardTitle => 'Bỏ thay đổi?';

  @override
  String get counterBgDiscardBody =>
      'Bạn có thay đổi chưa lưu. Thoát mà không lưu nhé?';

  @override
  String get counterBgDiscardLeave => 'Thoát';

  @override
  String get settingsChatBgTitle => 'Ảnh nền đoạn chat';

  @override
  String get settingsChatBgSubtitle => 'Chọn một ảnh làm nền cuộc trò chuyện';

  @override
  String get chatBgBadge => 'ẢNH NỀN CHAT';

  @override
  String get chatBgTitle => 'Ảnh nền đoạn chat';

  @override
  String get chatBgSubtitle =>
      'Chọn một ảnh làm nền cuộc trò chuyện, hoặc giữ nền mặc định.';

  @override
  String get chatBgFilterHint =>
      'Chỉ hiện ảnh dọc, độ phân giải cao — phủ kín màn hình mà không bị cắt hay vỡ nét.';

  @override
  String get chatBgNoneLabel => 'Mặc định';

  @override
  String get chatBgMeasuring => 'Đang lọc ảnh…';

  @override
  String get chatBgNoneValidTitle => 'Chưa có ảnh phù hợp';

  @override
  String get chatBgNoneValidBody =>
      'Hãy thêm ảnh dọc, sắc nét vào thư viện — ảnh ngang hoặc độ phân giải thấp không dùng làm nền chat được.';

  @override
  String get chatBgSavedMsg => 'Đã lưu ảnh nền chat 💕';

  @override
  String get journeyTrailTitle => 'Hành trình của chúng mình';

  @override
  String milestoneTrailNext(int days, String label) {
    return 'Còn $days ngày tới $label';
  }

  @override
  String get milestoneTrailAllDone =>
      'Hai bạn đã chinh phục mọi cột mốc rồi 🎉';

  @override
  String get profileAchievementsTitle => 'Huy hiệu của chúng mình';

  @override
  String get badgeStreakLabel => 'ngày chuỗi';

  @override
  String get badgeRecordLabel => 'kỷ lục';

  @override
  String get badgeMemoriesLabel => 'kỷ niệm';

  @override
  String get badgeJournalLabel => 'nhật ký';

  @override
  String get profileRecordsTitle => 'Kỷ lục của chúng mình';

  @override
  String get profileRecordLongestStreak => 'Chuỗi dài nhất';

  @override
  String get profileRecordDaysTogether => 'Ngày bên nhau';

  @override
  String get profileRecordTotalMemories => 'Tổng kỷ niệm';

  @override
  String get profileRecordJournalEntries => 'Câu hỏi đã trả lời';

  @override
  String get profileRecordStreakMilestones => 'Cột mốc chuỗi đạt';

  @override
  String profileJournalCountLabel(String count) {
    return '$count câu';
  }

  @override
  String get profileMemoriesTitle => 'Kỷ niệm của chúng mình';

  @override
  String profileMemoriesCountLabel(String count) {
    return '$count kỷ niệm';
  }

  @override
  String profileMemoriesNextLabel(String count, String milestone) {
    return 'Còn $count ảnh nữa tới mốc $milestone';
  }

  @override
  String get loveTreeBadge => 'CÂY TÌNH YÊU';

  @override
  String get loveTreeStage0 => 'Hạt mầm';

  @override
  String get loveTreeStage1 => 'Mầm non';

  @override
  String get loveTreeStage2 => 'Cây non';

  @override
  String get loveTreeStage3 => 'Cây xanh';

  @override
  String get loveTreeStage4 => 'Nở rộ';

  @override
  String loveTreeFlowerCount(int count) {
    return '$count bông hoa đã nở';
  }

  @override
  String get loveTreeFlowerCountZero => 'Chưa có bông nào — hãy cùng vun đắp';

  @override
  String get loveTreeSeedSubtitle => 'Hành trình của hai bạn bắt đầu từ đây 🌱';

  @override
  String get loveTreeBloomSubtitle => 'Cây của hai bạn đang rực rỡ ✨';

  @override
  String loveTreeNewBloomBanner(int count) {
    return 'Cây vừa nở $count bông mới 🌸';
  }

  @override
  String get loveTreeNewBloomBannerOne => 'Cây vừa nở một bông mới 🌸';

  @override
  String get loveTreeNurtureTitle => 'Cùng vun đắp';

  @override
  String get loveTreeNurtureStreakTitle => 'Giữ chuỗi mỗi ngày';

  @override
  String get loveTreeNurtureStreakBody => 'Trả lời câu hỏi để chuỗi không đứt';

  @override
  String get loveTreeNurturePhotoTitle => 'Thêm một kỷ niệm';

  @override
  String get loveTreeNurturePhotoBody => 'Mỗi tấm ảnh là một bông hoa mới';

  @override
  String get loveTreeNurtureTalkTitle => 'Cùng trò chuyện hôm nay';

  @override
  String get loveTreeNurtureTalkBody => 'Những khoảnh khắc nhỏ nuôi cây lớn';

  @override
  String get loveTreeMilestonesTitle => 'Cột mốc';

  @override
  String loveTreeMilestoneDays(int count) {
    return '$count ngày bên nhau';
  }

  @override
  String loveTreeMilestoneStreak(int count) {
    return 'Chuỗi $count ngày';
  }

  @override
  String loveTreeMilestonePhotos(int count) {
    return '$count ảnh kỷ niệm';
  }

  @override
  String get loveTreeMilestoneBloomed => 'đã nở';

  @override
  String loveTreeMilestoneDaysLeft(int count) {
    return 'còn $count ngày';
  }

  @override
  String loveTreeMilestoneStreakLeft(int count) {
    return 'còn $count ngày chuỗi';
  }

  @override
  String loveTreeMilestonePhotosLeft(int count) {
    return 'còn $count ảnh';
  }

  @override
  String get loveTreeMilestoneAllDone => 'đã đủ 🌟';

  @override
  String get loveTreeWaitingTitle => 'Cây đang chờ cả hai';

  @override
  String get loveTreeWaitingBody =>
      'Cây sẽ lớn khi cả hai cùng có mặt. Mời người ấy tham gia nhé 💌';

  @override
  String get loveTreeWaitingCta => 'Mời người ấy';

  @override
  String get loveTreeNoCoupleBody =>
      'Hãy kết nối với người ấy để bắt đầu trồng cây 🌱';

  @override
  String get loveTreeCoachTooltip => 'Chạm để xem khoảnh khắc 🌸';

  @override
  String get loveTreeTapHint => 'Chạm vào mỗi bông để xem kỷ niệm';

  @override
  String loveTreeMomentDaysTitle(int count) {
    return '$count ngày bên nhau';
  }

  @override
  String loveTreeMomentPhotosTitle(int count) {
    return 'Kỷ niệm thứ $count';
  }

  @override
  String loveTreeMomentStreakTitle(int count) {
    return 'Kỷ lục chuỗi $count ngày';
  }

  @override
  String loveTreeMomentBloomedOn(String date) {
    return 'Nở ngày $date';
  }

  @override
  String loveTreeMomentPhotoTakenOn(String date) {
    return 'Đăng ngày $date';
  }

  @override
  String get loveTreeMomentDaysCopy =>
      'Mỗi ngày bên nhau là một cánh hoa nở 🌸';

  @override
  String get loveTreeMomentPhotosCopy =>
      'Một khoảnh khắc hai đứa đã cùng lưu giữ 💞';

  @override
  String get loveTreeMomentStreakCopy =>
      'Kỷ lục các bạn từng cùng nhau giữ. Bắt đầu chuỗi mới để vượt nó nhé 🔥';

  @override
  String get loveTreeMomentViewInGallery => 'Xem trong Thư viện';

  @override
  String loveTreeLockedDays(int count) {
    return 'Còn $count ngày nữa để nở 🌱';
  }

  @override
  String loveTreeLockedPhotos(int count) {
    return 'Còn $count kỷ niệm nữa để nở 🌱';
  }

  @override
  String loveTreeLockedStreak(int count) {
    return 'Còn $count ngày chuỗi nữa để nở 🌱';
  }

  @override
  String get loveTreeLockedPhotosCta => 'Thêm kỷ niệm';

  @override
  String get loveTreeLockedStreakCta => 'Trả lời hôm nay';

  @override
  String get loveTreeShareButton => 'Khoe cây';

  @override
  String loveTreeShareStats(String days, String flowers) {
    return '$days ngày bên nhau · $flowers bông hoa';
  }

  @override
  String get loveTreeShareTagline => 'Cây tình yêu của chúng mình 🌳';

  @override
  String get loveTreeShareTaglineSeed => 'Cây vừa gieo mầm 🌱';

  @override
  String loveTreeShareMessage(String flowers, String days) {
    return 'Cây tình yêu của chúng mình đã nở $flowers bông hoa sau $days ngày 🌳💞 — vun cây cùng người ấy trên Dear Embeiu.';
  }

  @override
  String get loveTreeShareFailed => 'Không tạo được thẻ, thử lại nhé';

  @override
  String get partnerReminderNotifBody => 'Người ấy nhắc bạn 💌';

  @override
  String notifAnswerReaction(String name, String emoji) {
    return '$name đã thả $emoji cho câu trả lời của bạn';
  }

  @override
  String get answerReactionHint => 'Thả cảm xúc cho câu trả lời của người ấy';

  @override
  String get answerReactionAddTooltip => 'Thả cảm xúc';

  @override
  String get answerReactionRemoveTooltip => 'Bỏ cảm xúc';

  @override
  String get answerReactionErrorRetry => 'Chưa gửi được, thử lại nhé';
}

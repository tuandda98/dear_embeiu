// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get loveTreeShareFirstDay => 'Ngày đầu tiên bên nhau';

  @override
  String get loveTreeShareMessageSeed =>
      'Cây tình yêu của chúng mình vừa nảy mầm 🌱💞 — vun cây cùng người ấy trên Dear Embeiu.';

  @override
  String get sleepTheirClock => 'Giờ bên ấy';

  @override
  String get sleepManualSemantics => '(ghi tay)';

  @override
  String get moodSaveFailed => 'Chưa lưu được tâm trạng, thử lại nhé';

  @override
  String get setPasswordTitle => 'Đặt mật khẩu';

  @override
  String get setPasswordSubtitle => 'Để đăng nhập bằng email trên máy khác';

  @override
  String setPasswordBody(String email) {
    return 'Đặt xong, bạn đăng nhập bằng $email và mật khẩu này trên iPhone hay Android đều được.';
  }

  @override
  String setPasswordConfirmNote(String provider) {
    return '$provider có thể hỏi lại để xác nhận đó là bạn.';
  }

  @override
  String setPasswordDone(String email) {
    return 'Đã đặt mật khẩu. Trên máy khác, bạn đăng nhập bằng $email nhé.';
  }

  @override
  String get setPasswordAlreadySet => 'Tài khoản này đã có mật khẩu rồi.';

  @override
  String get setPasswordEmailTaken =>
      'Email này đang thuộc một tài khoản khác nên chưa đặt được mật khẩu.';

  @override
  String get setPasswordWrongGoogleAccount =>
      'Đó là một tài khoản Google khác. Bạn chọn đúng tài khoản đang dùng cho Dear Embeiu rồi thử lại nhé.';

  @override
  String get setPasswordFailed => 'Chưa đặt được mật khẩu. Bạn thử lại nhé.';

  @override
  String get setPasswordAppleIdMismatch =>
      'Máy này đang dùng một Apple ID khác. Bạn mở app trên máy dùng Apple ID của tài khoản này để đặt mật khẩu nhé.';

  @override
  String get showPassword => 'Hiện mật khẩu';

  @override
  String get hidePassword => 'Ẩn mật khẩu';

  @override
  String get badgeCareLabel => 'lời quan tâm';

  @override
  String get careTimelineBadge => 'LỜI QUAN TÂM';

  @override
  String get careTimelineSeeAll => 'Xem tất cả';

  @override
  String get careTimelineYesterday => 'Hôm qua';

  @override
  String get careTimelineEmptyTitle => 'Chưa có lời quan tâm nào';

  @override
  String get careTimelineEmptyBody =>
      'Mỗi lời nhắn nhỏ chúng mình gửi nhau sẽ nằm lại ở đây, xếp theo từng ngày.';

  @override
  String get careTimelineEmptyCta => 'Gửi lời quan tâm đầu tiên';

  @override
  String get careTimelineLoadError => 'Chưa tải được dòng thời gian.';

  @override
  String get aiQuestionsTitle => 'Câu hỏi do AI soạn riêng';

  @override
  String get aiQuestionsSubtitle =>
      'AI đọc câu trả lời 30 ngày gần nhất của cả hai rồi soạn câu hỏi riêng cho chúng mình. Những câu trả lời này chỉ dùng để soạn câu hỏi, không dùng để huấn luyện AI. Tắt lúc nào cũng được.';

  @override
  String get aiQuestionsDialogTitle => 'Bật câu hỏi do AI soạn?';

  @override
  String get aiQuestionsDialogBody =>
      'Cài đặt này dùng chung cho cả hai: người ấy cũng sẽ thấy câu hỏi do AI soạn. AI chỉ đọc câu trả lời 30 ngày gần nhất để soạn câu hỏi. Những câu trả lời này không dùng để huấn luyện AI. Bạn tắt lúc nào cũng được. Câu hỏi AI bắt đầu từ ngày mai.';

  @override
  String get aiQuestionsDialogConfirm => 'Bật';

  @override
  String get introSkip => 'Bỏ qua';

  @override
  String get introNext => 'Tiếp';

  @override
  String get introStart => 'Bắt đầu';

  @override
  String get introSlide1Badge => 'ĐẾM NGÀY YÊU';

  @override
  String get introSlide1Title => 'Đếm từng ngày yêu';

  @override
  String get introSlide1Body =>
      'Chúng mình cùng xem đã bên nhau bao lâu, chạm từng cột mốc và ngắm cây tình yêu lớn lên mỗi ngày.';

  @override
  String get introSlide2Badge => 'MỖI NGÀY';

  @override
  String get introSlide2Title => 'Kỷ niệm & câu hỏi mỗi ngày';

  @override
  String get introSlide2Body =>
      'Thư viện ảnh chung, câu hỏi mỗi ngày cho cả hai, chuỗi ngày kết nối và góc trò chuyện riêng của chúng mình.';

  @override
  String get introSlide3Badge => 'CẦN CẢ HAI';

  @override
  String get introSlide3Title => 'Cần cả hai';

  @override
  String get introSlide3Body =>
      'Dear Embeiu là không gian của 2 người. Bạn tạo mã mời, người ấy tải app (iOS/Android) và nhập mã là xong.';

  @override
  String get featureTourBadge => 'CÓ GÌ MỚI';

  @override
  String featureTourVersionTitle(String version) {
    return 'Phiên bản $version';
  }

  @override
  String get featureTourGotIt => 'Đã hiểu';

  @override
  String get featureTourSettingsTile => 'Có gì mới';

  @override
  String get featureTourSettingsTileSub => 'Xem lại những tính năng mới nhất';

  @override
  String get featureTourCareTitle => 'Gửi quan tâm';

  @override
  String get featureTourCareBody =>
      'Soạn một lời nhắn ngắn, người ấy nhận thông báo ngay.';

  @override
  String get featureTourQuestionsTitle => 'Câu hỏi mỗi ngày mới mẻ hơn';

  @override
  String get featureTourQuestionsBody =>
      'Câu hỏi đổi theo tuần, tháng và tâm trạng, có hôm còn rủ chúng mình nhìn lại câu trả lời cũ. Muốn AI soạn câu hỏi riêng thì bật trong Cài đặt.';

  @override
  String get featureTourInviteTitle => 'Mời người ấy dễ hơn';

  @override
  String get featureTourInviteBody =>
      'Chia sẻ link tải app kèm mã mời, có hướng dẫn từng bước.';

  @override
  String get homeWaitingBadge => 'CHỜ NGƯỜI ẤY';

  @override
  String get homeWaitingStep1Title => 'Gửi lời mời';

  @override
  String get homeWaitingStep1Desc =>
      'Gửi mã qua tin nhắn, hoặc cho người ấy quét mã QR nếu đang ở cạnh nhau.';

  @override
  String get homeWaitingStep1Cta => 'Gửi cho người ấy 💌';

  @override
  String get homeWaitingStep1Copy => 'Sao chép mã';

  @override
  String get homeWaitingStep2Title => 'Người ấy tải app và đăng ký';

  @override
  String get homeWaitingStep2Desc =>
      'Người ấy cần cài Dear Embeiu (iOS/Android), đăng ký rồi chọn <Tham gia bằng mã>.';

  @override
  String get homeWaitingStep3Title => 'Nhập mã là xong';

  @override
  String get homeWaitingStep3Desc =>
      'Ghép xong app tự chuyển, bạn sẽ nhận thông báo.';

  @override
  String get homeWaitingMeanwhileTitle => 'Trong lúc chờ, bạn vẫn có thể:';

  @override
  String get homeWaitingMeanwhileItem1 => 'Đặt ngày yêu';

  @override
  String get homeWaitingMeanwhileItem2 => 'Thêm kỷ niệm';

  @override
  String get homeWaitingMeanwhileItem3 => 'Trả lời câu hỏi hôm nay';

  @override
  String get homeWaitingMeanwhileFooter => 'Người ấy vào sẽ thấy hết.';

  @override
  String get inviteFollowUpTitle => 'Người ấy chưa vào nè 💌';

  @override
  String get inviteFollowUpBody24h =>
      'Gửi lại lời mời cho người ấy nha, chỉ mất 10 giây';

  @override
  String get inviteFollowUpBody72h =>
      'Kỷ niệm của chúng mình đang đợi người ấy. Nhắc người ấy tải app nhé';

  @override
  String get inviteQrBtn => 'Mã QR';

  @override
  String get inviteQrTitle => 'Cho người ấy quét mã này';

  @override
  String get inviteQrBody =>
      'Người ấy mở Camera, hướng vào mã là tới trang tải Dear Embeiu, có sẵn mã mời của bạn.';

  @override
  String get inviteQrFallback =>
      'Không quét được? Đọc mã này cho người ấy nhập.';

  @override
  String get inviteQrDone => 'Xong';

  @override
  String inviteQrSemantics(String code) {
    return 'Mã QR mời ghép đôi, mã $code';
  }

  @override
  String get clipboardInviteTitle => 'Nhập mã từ lời mời?';

  @override
  String get clipboardInviteBody =>
      'Link mời bạn mở có mã này. Ghép đôi là vào chung không gian với người ấy.';

  @override
  String get clipboardInviteJoin => 'Ghép đôi ngay';

  @override
  String get clipboardInviteSkip => 'Bỏ qua';

  @override
  String get inviteFollowUpTitle2h => 'Gửi lời mời cho người ấy nhé 💌';

  @override
  String get inviteFollowUpBody2h =>
      'Đang ở cạnh nhau thì cho người ấy quét mã QR, ở xa thì gửi qua tin nhắn. Mất chừng 10 giây thôi.';

  @override
  String get back => 'Quay lại';

  @override
  String get cancel => 'Huỷ';

  @override
  String get save => 'Lưu';

  @override
  String get delete => 'Xoá';

  @override
  String get edit => 'Chỉnh sửa';

  @override
  String get continueBtn => 'Tiếp tục';

  @override
  String get splashTagline => 'Câu chuyện của chúng mình';

  @override
  String get splashSubtitle => 'Đếm từng ngày bên nhau';

  @override
  String get checkingSession => 'Đang kiểm tra phiên đăng nhập...';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailHint => 'you@example.com';

  @override
  String get emailRequired => 'Bạn chưa nhập email';

  @override
  String get emailInvalid => 'Email không hợp lệ';

  @override
  String get passwordLabel => 'Mật khẩu';

  @override
  String get passwordHint => 'Ít nhất 6 ký tự';

  @override
  String get passwordRequired => 'Bạn chưa nhập mật khẩu';

  @override
  String get passwordTooShort => 'Mật khẩu cần ít nhất 6 ký tự';

  @override
  String get signIn => 'Đăng nhập';

  @override
  String get newHere => 'Chưa có tài khoản?';

  @override
  String get createAccountLink => 'Tạo tài khoản';

  @override
  String get displayNameLabel => 'Tên hiển thị';

  @override
  String get displayNameHint => 'Tên của bạn';

  @override
  String get displayNameRequired => 'Bạn chưa nhập tên hiển thị';

  @override
  String get displayNameTooShort => 'Tên quá ngắn';

  @override
  String get confirmPasswordLabel => 'Xác nhận mật khẩu';

  @override
  String get confirmPasswordHint => 'Nhập lại mật khẩu';

  @override
  String get confirmPasswordRequired => 'Bạn chưa nhập lại mật khẩu';

  @override
  String get passwordsMismatch => 'Mật khẩu chưa khớp';

  @override
  String get createAccountBtn => 'Tạo tài khoản';

  @override
  String get alreadyWithUs => 'Đã có tài khoản?';

  @override
  String get backToSignIn => 'Quay lại đăng nhập';

  @override
  String get setupCreateTitle => 'Bắt đầu\ncâu chuyện của chúng mình';

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
  String get inviteCodeDialogTitle => 'Mã mời của bạn';

  @override
  String get inviteCodeDialogContent =>
      'Mã này gắn với tài khoản của bạn. Gửi mã cho người ấy. Người ấy chỉ cần đăng nhập tài khoản riêng rồi nhập mã ở mục <Tham gia bằng mã>.';

  @override
  String get sectionAboutCouple => 'Thông tin cặp đôi';

  @override
  String get setupEditSectionDesc =>
      'Chỉnh sửa thông tin chung: tên, ngày kỷ niệm, ảnh đôi.';

  @override
  String get setupCreateSectionDesc =>
      'Tạo không gian trước, rồi gửi mã mời cho người ấy.';

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
  String get couplePhotoHint => 'Thêm ảnh đôi (tuỳ chọn)';

  @override
  String get couplePhotoSelected => 'Đã chọn ảnh';

  @override
  String get saveChangesBtn => 'Lưu thay đổi';

  @override
  String get createOurSpaceBtn => 'Tạo không gian của chúng mình';

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
  String get inviteCodeTiedToAccount => 'Mã gắn với tài khoản bạn';

  @override
  String get setupErrorNoAccount =>
      'Không tìm thấy tài khoản. Bạn đăng nhập lại nhé.';

  @override
  String get setupErrorFillRequired =>
      'Điền đủ tên hai bạn và ngày kỷ niệm nhé.';

  @override
  String get setupErrorSaveCouple =>
      'Chưa lưu được thông tin cặp đôi. Bạn thử lại nhé.';

  @override
  String get setupErrorNoAccountShort => 'Không tìm thấy tài khoản.';

  @override
  String get setupErrorNoInviteCode => 'Bạn hãy nhập mã mời trước nhé.';

  @override
  String get setupErrorJoinCouple => 'Chưa ghép đôi được. Bạn thử lại nhé.';

  @override
  String get setupSuccessConnected => 'Ghép đôi thành công rồi 💞';

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
  String get chatEmptyHint =>
      'Chưa có tin nhắn nào, gửi lời đầu tiên cho người ấy nhé 💬';

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
  String get homeGreetingMorning => 'Chào buổi sáng,';

  @override
  String get homeGreetingAfternoon => 'Chào buổi chiều,';

  @override
  String get homeGreetingEvening => 'Chào buổi tối,';

  @override
  String get homeGreetingNight => 'Khuya rồi đó,';

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
    return 'Còn $count ngày nữa là tới ngày kỷ niệm';
  }

  @override
  String get addMemoryCta => 'Thêm kỷ niệm';

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
  String get recentMemoriesTitle => 'Kỷ niệm gần đây';

  @override
  String get addPhotosPrompt => 'Ảnh hai bạn đăng sẽ hiện ở đây';

  @override
  String get seeAll => 'Xem tất cả';

  @override
  String get addPhotosEmpty =>
      'Chạm vào khung ảnh bên dưới để đăng tấm đầu tiên.';

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
  String get reactionRemoveTooltip => 'Gỡ cảm xúc';

  @override
  String get reactionErrorRetry => 'Chưa thả được tim, thử lại nhé';

  @override
  String get dailyQuestionSubmitError =>
      'Chưa gửi được câu trả lời, thử lại nhé.';

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
      'Người ấy nhập mã mời và trả lời xong là mở khoá nhé.';

  @override
  String get dailyQuestionSent => 'Đã gửi câu trả lời của bạn 💞';

  @override
  String get journalBadge => 'NHẬT KÝ CÂU HỎI';

  @override
  String get journalYourAnswerLabel => 'CÂU TRẢ LỜI CỦA BẠN';

  @override
  String journalPartnerAnswerLabel(String name) {
    return 'CÂU TRẢ LỜI CỦA $name';
  }

  @override
  String get journalLoadMore => 'Xem thêm';

  @override
  String get journalEmptyTitle => 'Nhật ký còn trống';

  @override
  String get journalEmptyBody =>
      'Ngày nào cả hai cùng trả lời, câu hỏi và hai câu trả lời hôm đó sẽ nằm ở đây.';

  @override
  String get journalEmptyCta => 'Trả lời câu hôm nay';

  @override
  String get journalEmptyNoPartnerBody =>
      'Mời người ấy vào để chúng mình cùng viết nhật ký nhé.';

  @override
  String get journalEmptyNoPartnerCta => 'Mời người ấy';

  @override
  String get journalErrorTitle => 'Chưa tải được nhật ký';

  @override
  String get journalRetry => 'Thử lại';

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
  String get addCaptionOptionalTitle => 'Thêm chú thích (tuỳ chọn)';

  @override
  String get addCaptionOptionalHint => 'Viết vài dòng về tấm ảnh này...';

  @override
  String get editCaptionTitle => 'Chỉnh sửa chú thích';

  @override
  String get editCaptionHint => 'Lúc chụp tấm này có chuyện gì?';

  @override
  String get deletePhotoTitle => 'Xoá ảnh này?';

  @override
  String get deletePhotoContent => 'Cả hai bạn sẽ không còn thấy ảnh này nữa.';

  @override
  String get keepPhotoBtn => 'Giữ lại';

  @override
  String get deletePhotoBtn => 'Xoá';

  @override
  String postedByLabel(String name) {
    return '$name đăng';
  }

  @override
  String momentsCount(int count) {
    return '$count khoảnh khắc';
  }

  @override
  String get privateFeedLabel => 'Chỉ hai bạn xem được';

  @override
  String get postNewPhotoBtn => 'Chụp hình';

  @override
  String get addMultipleBtn => 'Thêm hình';

  @override
  String get cameraUnavailable =>
      'Chưa mở được camera. Bạn thử lại hoặc vào Cài đặt của máy, bật quyền camera cho app nhé.';

  @override
  String get createPostBadge => 'KỶ NIỆM MỚI';

  @override
  String createPostAuthorMeta(String name, String when) {
    return '$name đăng · $when';
  }

  @override
  String get today => 'Hôm nay';

  @override
  String get createPostCaptionHint => 'Hôm nay hai bạn có gì mới?…';

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
  String get createPostDiscardMessage => 'Chú thích bạn vừa viết sẽ mất luôn.';

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
      'Chụp một tấm, viết vài dòng là có thêm một kỷ niệm.';

  @override
  String compactCaption(int count) {
    return '$count khoảnh khắc · Cuộn lên đầu để bung khung đăng ảnh';
  }

  @override
  String get editCaptionAction => 'Chỉnh sửa chú thích';

  @override
  String get deletePhotoAction => 'Xoá ảnh';

  @override
  String get reportPhotoAction => 'Báo cáo ảnh';

  @override
  String get reportPhotoTitle => 'Báo cáo ảnh';

  @override
  String get reportPhotoSubtitle => 'Ảnh này có gì không ổn?';

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
  String get startNewfeedTitle => 'Bắt đầu lưu giữ kỷ niệm';

  @override
  String get postFirstMomentOf => 'Hãy đăng khoảnh khắc đầu tiên của';

  @override
  String get emptyFeedContent =>
      'Mỗi tấm ảnh hai bạn đăng sẽ hiện ở đây, kèm ngày giờ và chú thích.';

  @override
  String get postFirstPhotoBtn => 'Đăng ảnh đầu tiên';

  @override
  String get photoAddedSuccess => 'Đã thêm ảnh!';

  @override
  String get photoAddError => 'Chưa đăng được ảnh, thử lại nhé.';

  @override
  String multiplePhotosAdded(int count) {
    return 'Đã thêm $count ảnh!';
  }

  @override
  String get captionUpdatedSuccess => 'Đã cập nhật chú thích';

  @override
  String get captionUpdateError => 'Chưa lưu được chú thích, thử lại nhé.';

  @override
  String get photoDeletedSuccess => 'Đã xoá ảnh';

  @override
  String get photoDeleteError => 'Chưa xoá được ảnh, thử lại nhé.';

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
  String get deletingPhoto => 'Đang xoá ảnh...';

  @override
  String get updatingCaption => 'Đang cập nhật chú thích...';

  @override
  String get photoOptionsTitle => 'Tuỳ chọn ảnh';

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
      'Kỷ niệm vẫn còn nguyên, chỉ là lúc này chưa tải về được.';

  @override
  String get galleryRetryBtn => 'Thử lại';

  @override
  String multiPhotosResultPartial(int success, int total, int failed) {
    return 'Đã đăng $success/$total ảnh, $failed ảnh chưa lên được';
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
  String get yearsTogether => 'Năm';

  @override
  String get monthsRemaining => 'Tháng';

  @override
  String get yourInviteCodeLabel => 'Mã mời riêng của bạn';

  @override
  String get editOurStoryBtn => 'Chỉnh sửa câu chuyện';

  @override
  String get settingsSectionAccount => 'Tài khoản';

  @override
  String get settingsSectionNotifications => 'Thông báo';

  @override
  String get settingsSectionGeneral => 'Chung';

  @override
  String get dataManagementTitle => 'Quản lý dữ liệu';

  @override
  String get dataManagementDesc =>
      'Một mình bạn chỉ xoá được dữ liệu trên máy này hoặc rời cặp đôi. Muốn xoá dữ liệu chung, cả hai phải cùng xác nhận.';

  @override
  String get clearLocalDataBtn => 'Xoá dữ liệu trên máy này';

  @override
  String get localFallbackWarning =>
      'App đang chạy trên máy này (chưa kết nối máy chủ) nên chưa xoá riêng dữ liệu tạm được. Muốn làm mới, bạn có thể rời cặp đôi hiện tại.';

  @override
  String get leaveCoupleBtn => 'Rời cặp đôi';

  @override
  String get clearLocalDialogTitle => 'Xoá dữ liệu trên máy này';

  @override
  String get clearLocalDialogContent =>
      'Việc này chỉ xoá dữ liệu tạm trên máy này. Dữ liệu chung vẫn còn trên máy chủ và sẽ tự tải lại khi cần.';

  @override
  String get clearLocalActionBtn => 'Xoá';

  @override
  String get leaveCoupleDialogTitle => 'Rời cặp đôi?';

  @override
  String get leaveCoupleDialogContent =>
      'Bạn sẽ rời không gian chung này. Dữ liệu chung vẫn ở lại với người ấy, một mình bạn không xoá được.';

  @override
  String get leaveCoupleActionBtn => 'Rời cặp đôi';

  @override
  String get leaveCoupleDeleteAllTitle =>
      'Xoá vĩnh viễn không gian của hai người?';

  @override
  String get leaveCoupleDeleteAllContent =>
      'Chỉ còn mình bạn ở lại. Khi rời đi, TẤT CẢ kỷ niệm chung — ảnh, lời nhắn, nhật ký câu hỏi — sẽ bị xoá vĩnh viễn và KHÔNG THỂ khôi phục.';

  @override
  String get leaveCoupleDeleteAllBtn => 'Xoá tất cả';

  @override
  String get leaveCoupleError =>
      'Chưa rời cặp đôi được lúc này. Kiểm tra kết nối mạng rồi thử lại nhé.';

  @override
  String get localDataClearedMsg =>
      'Đã xoá dữ liệu tạm trên máy này. Dữ liệu chung trên máy chủ vẫn còn nguyên.';

  @override
  String get languageTitle => 'Ngôn ngữ';

  @override
  String get languageSystem => 'Theo hệ thống';

  @override
  String get languageSystemDesc => 'Theo ngôn ngữ thiết bị';

  @override
  String get loadingCoupleInfo => 'Đang tải thông tin cặp đôi...';

  @override
  String get savingCoupleSpace => 'Đang tạo không gian của chúng mình...';

  @override
  String get connectingCouple => 'Đang ghép đôi...';

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
    return 'Mình muốn lưu giữ kỷ niệm cùng bạn trên Dear Embeiu 💞\nNhập mã mời này để ghép đôi với mình nhé: $code\nTải app & nhập mã tại: https://dearembeiu.com/get?code=$code';
  }

  @override
  String get remindersPermissionDeniedMsg =>
      'Hãy bật thông báo trong Cài đặt để nhận lời nhắc.';

  @override
  String get dailyQuestionReminderTitle => 'Nhắc trả lời câu hỏi';

  @override
  String get dailyQuestionReminderSubtitle =>
      'Nhắc cả hai cùng trả lời mỗi ngày, hai máy dùng chung giờ nhắc.';

  @override
  String get dailyQuestionReminderAddTime => 'Thêm giờ nhắc';

  @override
  String get dailyQuestionReminderNotifTitle => 'Câu hỏi hôm nay đang chờ 💌';

  @override
  String get dailyQuestionReminderNotifBody =>
      'Ghé trả lời để mở khoá câu trả lời của người ấy nhé.';

  @override
  String get dailyQuestionReminderNotifBodyAlt1 =>
      'Hôm nay chúng mình có câu hỏi mới, bạn trả lời phần mình nha 💞';

  @override
  String get dailyQuestionReminderNotifBodyAlt2 =>
      'Một câu hỏi nhỏ đang đợi chúng mình, ghé trả lời nhé 🌸';

  @override
  String get dqPartnerOnlyNudgeTitle => 'Chỉ còn người ấy nữa thôi 💌';

  @override
  String get dailyQuestionReminderEndOfDayHint =>
      'Cuối ngày mà câu hỏi chưa xong, app nhắc thêm lúc 21:00. Nếu bạn vẫn chưa trả lời, app nhắc tiếp lúc 22:00 và 23:00.';

  @override
  String get dqEndOfDayNudgeTitle => 'Ngày sắp khép lại rồi 🌙';

  @override
  String get dqEndOfDayNudgeBody =>
      'Câu hỏi hôm nay vẫn đang chờ — ghé trả lời trước khi hết ngày nhé.';

  @override
  String get dqEndOfDayNudgePartnerBody =>
      'Người ấy chưa trả lời câu hỏi hôm nay — nhắc một câu cho kịp nhé.';

  @override
  String get dqStreakWarningTitle => 'Chuỗi sắp đứt rồi! 🔥';

  @override
  String dqStreakWarningBody(int days) {
    return 'Sắp hết ngày rồi. Trả lời câu hỏi để giữ chuỗi $days ngày của chúng mình nhé!';
  }

  @override
  String get dqStreakWarningStartBody =>
      'Sắp hết ngày rồi! Trả lời câu hỏi để mở chuỗi mới cho chúng mình nhé.';

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
  String get reminderMilestoneTodayTitle => 'Đã đến cột mốc 🎉';

  @override
  String reminderMilestoneTodayBody(String milestone) {
    return 'Hôm nay chúng mình chạm mốc $milestone rồi 💕';
  }

  @override
  String get reminderAnniversaryTitle => 'Chúc mừng kỷ niệm 🎉';

  @override
  String get reminderAnniversaryBody =>
      'Hôm nay chúng mình tròn thêm một năm bên nhau 💕';

  @override
  String get reminderInactivityTitle => 'Lâu rồi chưa có ảnh mới 💭';

  @override
  String get reminderInactivityBody => 'Cùng thêm một kỷ niệm mới nhé 💕';

  @override
  String remindersV2MilestoneCountBadge(int count) {
    return '$count mốc';
  }

  @override
  String get remindersV2MilestoneScreenTitle => 'Cột mốc & kỷ niệm';

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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count năm',
    );
    return '$_temp0';
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
  String get milestoneYearlyDesc => 'Đúng ngày yêu nhau mỗi năm';

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
      'Cột mốc, kỷ niệm và lời nhắc riêng của hai bạn.';

  @override
  String get settingsAnalyticsTitle => 'Chia sẻ dữ liệu sử dụng';

  @override
  String get settingsAnalyticsSubtitle =>
      'Gửi dữ liệu ẩn danh giúp app tốt hơn. Ảnh, tin nhắn và mọi nội dung riêng tư của bạn không bao giờ nằm trong đó.';

  @override
  String get languageSearchHint => 'Tìm ngôn ngữ';

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
  String get customRemindersEmptyTitle => 'Chưa có lời nhắc nào';

  @override
  String get customRemindersEmptyBody =>
      'Tạo mốc riêng của hai bạn: sinh nhật, ngày tròn tháng, ngày hẹn đầu tiên…';

  @override
  String get customRemindersEmptyCta => 'Tạo lời nhắc đầu tiên';

  @override
  String get customRemindersAddAnother => 'Thêm lời nhắc';

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
  String get authAccountNotFound => 'Chưa có tài khoản nào dùng email này.';

  @override
  String get authConfigNotFound =>
      'Hiện chưa đăng nhập bằng email được. Bạn thử lại sau nhé.';

  @override
  String get authEmailAlreadyUsed => 'Email này đã có tài khoản rồi.';

  @override
  String get authEmailPasswordNotEnabled =>
      'Hiện chưa đăng nhập bằng email được. Bạn thử lại sau nhé.';

  @override
  String get authFirebaseAuthGeneric =>
      'Có lỗi khi xác thực tài khoản. Bạn thử lại nhé.';

  @override
  String get continueWithApple => 'Tiếp tục với Apple';

  @override
  String get authOrDivider => 'hoặc';

  @override
  String get appleSignInFailed =>
      'Chưa đăng nhập được với Apple. Bạn thử lại nhé.';

  @override
  String get appleEmailHasPasswordAccount =>
      'Email này đã có tài khoản. Đăng nhập bằng cách bạn đã dùng lần trước nhé.';

  @override
  String get deleteAccountAppleNote =>
      'Sau đó Apple sẽ hiện hộp đăng nhập để xác nhận đó là bạn.';

  @override
  String get deleteAccountReauthBodyApple =>
      'Vì lý do bảo mật, bạn xác nhận lại với Apple để xoá tài khoản vĩnh viễn.';

  @override
  String get continueWithGoogle => 'Tiếp tục với Google';

  @override
  String get googleSignInFailed =>
      'Chưa đăng nhập được với Google. Bạn thử lại nhé.';

  @override
  String get socialConsentPrefix => 'Khi tiếp tục, bạn đồng ý với';

  @override
  String get deleteAccountReauthBodyGoogle =>
      'Bấm Xoá vĩnh viễn để thử lại. Nếu vẫn lỗi, bạn đăng nhập lại bằng Google rồi xoá nhé.';

  @override
  String get deleteAccountAppleIdMismatch =>
      'Máy này đang dùng một Apple ID khác. Bạn mở app trên máy dùng Apple ID của tài khoản này để xoá tài khoản nhé.';

  @override
  String get authFirebaseUserCreateFailed =>
      'Chưa tạo được tài khoản, bạn thử lại nhé.';

  @override
  String get authFirestoreGeneric =>
      'Chưa đồng bộ được dữ liệu tài khoản. Bạn thử lại nhé.';

  @override
  String get authFirestorePermissionDenied =>
      'Chưa lưu được thông tin tài khoản vì máy chủ từ chối. Bạn thử lại sau ít phút nhé.';

  @override
  String get authFirestoreUnavailable =>
      'Chưa kết nối được máy chủ, có thể do mạng chập chờn. Bạn thử lại sau ít phút nhé.';

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
      'Mạng đang chập chờn. Bạn kiểm tra kết nối rồi thử lại nhé.';

  @override
  String get authSessionNotReady =>
      'Phiên đăng nhập chưa sẵn sàng. Bạn thử đăng nhập lại giúp mình nhé.';

  @override
  String get authSessionUnavailable => 'Chưa đăng nhập được, bạn thử lại nhé.';

  @override
  String get authTooManyRequests =>
      'Có quá nhiều lần thử đăng nhập. Bạn đợi vài phút rồi thử lại nhé.';

  @override
  String get authUserDisabled =>
      'Tài khoản này đã bị khoá nên không đăng nhập được.';

  @override
  String get authWeakPassword =>
      'Mật khẩu còn yếu, bạn chọn mật khẩu mạnh hơn nhé.';

  @override
  String get authWrongPassword => 'Mật khẩu chưa đúng, bạn kiểm tra lại nhé.';

  @override
  String get bootstrapAndroidNotReady =>
      'App chưa kết nối được máy chủ, dữ liệu tạm lưu trên máy này.';

  @override
  String get bootstrapIosNotConfigured =>
      'App chưa kết nối được máy chủ, dữ liệu tạm lưu trên máy này.';

  @override
  String get bootstrapLinuxNotConfigured =>
      'Bản Linux chưa kết nối máy chủ, dữ liệu tạm lưu trên máy này.';

  @override
  String get bootstrapMacosNotConfigured =>
      'Bản macOS chưa kết nối máy chủ, dữ liệu tạm lưu trên máy này.';

  @override
  String get bootstrapPlatformNotConfigured =>
      'Thiết bị này chưa kết nối máy chủ, dữ liệu tạm lưu trên máy.';

  @override
  String get bootstrapWebNotConfigured =>
      'Bản web chưa kết nối máy chủ, dữ liệu tạm lưu trên trình duyệt này.';

  @override
  String get bootstrapWindowsNotConfigured =>
      'Bản Windows chưa kết nối máy chủ, dữ liệu tạm lưu trên máy này.';

  @override
  String get coupleAlreadyInCouple => 'Tài khoản này đã ghép đôi rồi.';

  @override
  String get coupleAlreadyInThisCouple => 'Bạn đã ở trong cặp đôi này rồi.';

  @override
  String get coupleCannotUseOwnCode =>
      'Bạn không thể nhập mã mời của chính mình.';

  @override
  String get coupleCodeNoLongerValid =>
      'Mã mời này không còn dùng được nữa. Bạn nhờ người ấy tạo lại mã mời nhé.';

  @override
  String get coupleCodeNotFoundLocal =>
      'Không tìm thấy mã mời trên máy này (chưa kết nối máy chủ).';

  @override
  String get coupleEnterCodeFirst => 'Bạn hãy nhập mã mời trước nhé.';

  @override
  String get coupleFirebaseUnavailable =>
      'Chưa kết nối được máy chủ, có thể do mạng chập chờn. Bạn thử lại sau ít phút nhé.';

  @override
  String get coupleFull => 'Cặp đôi này đã đủ 2 người rồi.';

  @override
  String get coupleFullLocal => 'Cặp đôi trên máy này đã đủ 2 người rồi.';

  @override
  String get coupleInviteCodeInvalid =>
      'Mã mời không đúng hoặc không còn dùng được.';

  @override
  String get coupleJoinGeneric =>
      'Chưa kết nối được bằng mã mời. Bạn thử lại sau nhé.';

  @override
  String get coupleJoinPermissionDenied =>
      'Chưa kết nối được bằng mã mời này. Có thể không gian cặp đôi đã thay đổi hoặc không còn dùng được. Bạn nhờ người ấy tạo lại mã mời, hoặc đăng xuất rồi đăng nhập lại và thử lần nữa nhé.';

  @override
  String get coupleMatchedLocal =>
      'Đã ghép đôi trên máy này (chưa kết nối máy chủ).';

  @override
  String get coupleNoDataToUpdate => 'Chưa có thông tin cặp đôi để cập nhật.';

  @override
  String get coupleNotFoundForCode => 'Không tìm thấy cặp đôi nào dùng mã này.';

  @override
  String get coupleOnboardingBadge => 'BẮT ĐẦU';

  @override
  String get couplePartnerHasNoSpace =>
      'Người ấy đã có mã mời riêng nhưng chưa tạo không gian cặp đôi để bạn tham gia.';

  @override
  String get couplePhotoUploadGeneric =>
      'Chưa tải được ảnh đôi lên. Bạn thử đổi ảnh lại sau nhé.';

  @override
  String get couplePhotoUploadPermission =>
      'Chưa tải được ảnh đôi lên. Mình đã lưu thông tin cặp đôi trước, bạn thử đổi ảnh lại sau nhé.';

  @override
  String get couplePhotoUploadSessionInvalid =>
      'Chưa tải được ảnh đôi lên vì phiên đăng nhập không còn hiệu lực. Bạn đăng nhập lại rồi đổi ảnh nhé.';

  @override
  String get couplePhotoUploadUnavailable =>
      'Chưa tải được ảnh đôi lên vì mạng hoặc máy chủ đang chập chờn. Bạn thử lại sau nhé.';

  @override
  String get coupleSaveGeneric =>
      'Chưa lưu được thông tin cặp đôi. Bạn thử lại sau nhé.';

  @override
  String get coupleSavePermissionDenied =>
      'Chưa lưu được thông tin cặp đôi vì máy chủ từ chối. Có thể dữ liệu đang bị lỗi, bạn đăng xuất rồi đăng nhập lại và thử lần nữa nhé.';

  @override
  String get coupleSessionExpiredJoin =>
      'Phiên đăng nhập đã hết hạn. Bạn đăng nhập lại rồi thử kết nối lần nữa nhé.';

  @override
  String get coupleSessionInvalid =>
      'Phiên đăng nhập không còn hiệu lực. Bạn đăng nhập lại giúp mình nhé.';

  @override
  String get coupleSessionNotReadyRelogin =>
      'Phiên đăng nhập chưa sẵn sàng. Bạn đăng xuất rồi đăng nhập lại giúp mình nhé.';

  @override
  String get coupleSpaceInvalidRegenerate =>
      'Không gian cặp đôi của mã mời này không còn dùng được. Bạn nhờ người ấy tạo lại mã mời rồi thử lại nhé.';

  @override
  String get coupleUpdatedSuccess => 'Đã cập nhật thông tin cặp đôi.';

  @override
  String get coupleUserNotFoundForCreate =>
      'Không tìm thấy tài khoản của bạn để tạo cặp đôi. Bạn đăng nhập lại nhé.';

  @override
  String get createAccountBadge => 'TẠO TÀI KHOẢN';

  @override
  String get defaultDisplayName => 'Người dùng mới';

  @override
  String get deleteAccountBtn => 'Xoá tài khoản';

  @override
  String get deleteAccountConfirmBtn => 'Xoá vĩnh viễn';

  @override
  String get deleteAccountDialogContent =>
      'Việc này không thể hoàn tác. Toàn bộ dữ liệu của bạn, gồm ảnh và thông tin cặp đôi, sẽ bị xoá vĩnh viễn.';

  @override
  String get deleteAccountDialogTitle => 'Xoá tài khoản?';

  @override
  String get deleteAccountFailed => 'Chưa xoá được tài khoản. Bạn thử lại nhé.';

  @override
  String get deleteAccountReauthTitle => 'Xác minh đó là bạn';

  @override
  String get deleteAccountReauthBody =>
      'Vì lý do bảo mật, hãy nhập lại mật khẩu để xoá tài khoản vĩnh viễn.';

  @override
  String get deleteAccountSessionExpiredMsg =>
      'Phiên đăng nhập đã hết hạn. Bạn đăng nhập lại rồi xoá tài khoản nhé.';

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
      'Mỗi tấm ảnh là một kỷ niệm của chúng mình.';

  @override
  String get galleryTodayEmptyTitle => 'Hôm nay chưa có khoảnh khắc nào';

  @override
  String get leavingCouple => 'Đang rời cặp đôi...';

  @override
  String get mustAgreeToPrivacyPolicy =>
      'Bạn cần đồng ý với Chính sách bảo mật để tiếp tục';

  @override
  String get photoConnectCoupleFirst =>
      'Bạn cần ghép đôi trước khi đăng ảnh nhé.';

  @override
  String get photoFileNotFoundStorage => 'Không tìm thấy ảnh này trên máy chủ.';

  @override
  String get photoFirebaseUnavailable =>
      'Chưa kết nối được máy chủ, có thể do mạng chập chờn. Bạn thử lại sau ít phút nhé.';

  @override
  String get photoNotFoundToPost => 'Không tìm thấy ảnh để đăng.';

  @override
  String get photoStorageUnauthorized =>
      'Chưa làm được việc này với ảnh. Bạn thử đăng xuất rồi đăng nhập lại nhé.';

  @override
  String get photoSyncGeneric => 'Chưa đồng bộ được ảnh. Bạn thử lại sau nhé.';

  @override
  String get photoSyncPermissionDenied =>
      'Bạn chưa có quyền đồng bộ ảnh. Thử đăng xuất rồi đăng nhập lại nhé.';

  @override
  String get photoSyncSessionExpired =>
      'Phiên đăng nhập đã hết hạn. Bạn đăng nhập lại giúp mình nhé.';

  @override
  String get posterNameFallback => 'Người ấy';

  @override
  String get privacyDisclosure =>
      'Khi tạo tài khoản, bạn đồng ý với Chính sách bảo mật của chúng tôi. Chúng tôi thu thập email, tên hiển thị và ảnh bạn chia sẻ để cung cấp dịch vụ.';

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
      'Chưa đăng xuất được. Bạn kiểm tra kết nối rồi thử lại nhé.';

  @override
  String get welcomeBackBadge => 'CHÀO MỪNG TRỞ LẠI';

  @override
  String counterDuration(int years, int months, int days) {
    return '$years năm, $months tháng, $days ngày';
  }

  @override
  String get coupleLoadError =>
      'Chưa tải được thông tin cặp đôi. Bạn thử lại nhé.';

  @override
  String get coupleSyncError =>
      'Chưa đồng bộ được thông tin cặp đôi. Bạn thử lại nhé.';

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
      'Đã xem hết kỷ niệm rồi 💕 Cùng nhau tạo thêm kỷ niệm mới nhé';

  @override
  String galleryTodayMomentsCount(int count) {
    return '$count khoảnh khắc hôm nay';
  }

  @override
  String get guestModeBadge => 'Chế độ dùng thử';

  @override
  String get guestCounterTitle => 'Đếm ngày yêu';

  @override
  String get guestCounterSubtitle =>
      'Chọn ngày hai bạn bắt đầu yêu để xem đã bên nhau bao lâu.';

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
  String get widgetEmptyTap => 'Chạm để bắt đầu đếm ngày yêu';

  @override
  String guestCounterStartFrom(String date) {
    return 'Bắt đầu từ $date';
  }

  @override
  String get guestCtaTitle => 'Muốn lưu kỷ niệm cùng người ấy?';

  @override
  String get guestCtaBody => 'Đăng nhập để ghép đôi & lưu ảnh chung.';

  @override
  String get guestCtaSignIn => 'Đăng nhập bằng email';

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
    return '$n ngày kết nối · chờ trả lời hôm nay 🌸';
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
  String get streakSheetRestartTitle => 'Thắp lại ngọn lửa';

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
  String get streakSheetAtRiskTitle => 'Vẫn còn kịp nè 🫶';

  @override
  String streakSheetAtRiskBody(int n) {
    return 'Hôm qua chúng mình lỡ một nhịp, không sao cả! Trả lời hôm nay là chuỗi $n ngày tiếp tục liền.';
  }

  @override
  String get streakSheetRestartBody =>
      'Chuỗi cũ khép lại rồi. Hôm nay chúng mình cùng trả lời câu hỏi là thắp lại được ngay 🌱';

  @override
  String streakSheetRecord(int m) {
    return 'Kỷ lục của chúng mình: $m ngày 🌟';
  }

  @override
  String streakNextMilestone(int n, int m) {
    return 'Còn $n ngày tới mốc $m ngày 🎉';
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
  String get streakMilestone7Title => 'Tròn một tuần! ✨';

  @override
  String get streakMilestone7Body =>
      '7 ngày liền chúng mình không lỡ nhịp nào. Tự hào ghê!';

  @override
  String get streakMilestone30Title => 'Tròn 30 ngày liền! 🔥';

  @override
  String get streakMilestone30Body =>
      'Một tháng giữ lửa, giờ thành thói quen của chúng mình rồi đấy 💞';

  @override
  String get streakMilestone100Title => '100 ngày! 💯';

  @override
  String get streakMilestone100Body =>
      'Trăm ngày cùng nhau trả lời, hiểu nhau thêm từng chút. Hiếm cặp nào làm được như chúng mình 🌟';

  @override
  String get streakMilestone365Title => 'Tròn một năm! 👑';

  @override
  String get streakMilestone365Body =>
      '365 ngày chưa lỡ nhịp nào. Cả năm trời, ngày nào chúng mình cũng có nhau 💞👑';

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
  String get forgotPasswordBadge => 'LẤY LẠI MẬT KHẨU';

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
      'Email vẫn chưa được xác thực. Bạn mở hộp thư, bấm vào liên kết rồi thử lại nhé.';

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
      'Đây là mã mời chung của hai bạn. Cả hai đều dùng mã này để kết nối lại nếu cần.';

  @override
  String get setupCoupleCodeRejoinHint =>
      'Lưu mã lại nhé, lúc nào cần quay lại không gian này cũng dùng được.';

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
      'Ảnh mới, tin nhắn của người ấy sẽ hiện ở đây.';

  @override
  String get notifGroupToday => 'Hôm nay';

  @override
  String get notifGroupEarlier => 'Trước đó';

  @override
  String notifUnreadCount(int count) {
    return '$count chưa đọc';
  }

  @override
  String get notifAllCaughtUp => 'Bạn đã xem hết rồi 💛';

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
    return '$name vừa nhắn tin cho bạn 💬';
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
      'Chọn ảnh muốn làm nền thẻ đếm ngày. Bỏ trống thì thẻ sẽ xoay vòng tất cả ảnh.';

  @override
  String counterBgSubtitleCount(int count) {
    return 'Đã chọn $count ảnh làm nền thẻ đếm.';
  }

  @override
  String get counterBgCoverLabel => 'Ảnh đôi';

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
  String get counterBgDiscardBody => 'Bạn chưa lưu thay đổi. Vẫn thoát chứ?';

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
      'Chỉ hiện ảnh dọc, đủ nét để phủ kín màn hình mà không bị cắt hay vỡ hình.';

  @override
  String get chatBgNoneLabel => 'Mặc định';

  @override
  String get chatBgMeasuring => 'Đang lọc ảnh…';

  @override
  String get chatBgNoneValidTitle => 'Chưa có ảnh phù hợp';

  @override
  String get chatBgNoneValidBody =>
      'Thêm ảnh dọc, sắc nét vào thư viện nhé. Ảnh ngang hoặc kém nét thì không làm nền chat được.';

  @override
  String get chatBgSavedMsg => 'Đã lưu ảnh nền chat 💕';

  @override
  String get journeyTrailTitle => 'Cột mốc của chúng mình';

  @override
  String milestoneTrailNext(int days, String label) {
    return 'Còn $days ngày tới mốc $label';
  }

  @override
  String get milestoneTrailAllDone => 'Hai bạn đã đi qua mọi cột mốc rồi 🎉';

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
  String get profileRecordStreakMilestones => 'Mốc chuỗi đã đạt';

  @override
  String profileJournalCountLabel(String count) {
    return '$count câu';
  }

  @override
  String get profileMemoriesTitle => 'Kỷ niệm của chúng mình';

  @override
  String profileMemoriesCountLabel(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString kỷ niệm';
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
  String loveTreeFlowerCount(int count) {
    return '$count bông hoa đã nở';
  }

  @override
  String get loveTreeSeedSubtitle => 'Chúng mình vừa gieo hạt mầm đầu tiên 🌱';

  @override
  String loveTreeNewBloomBanner(int count) {
    return 'Cây vừa nở $count bông mới 🌸';
  }

  @override
  String get loveTreeNewBloomBannerOne => 'Cây vừa nở một bông mới 🌸';

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
  String get loveTreeWaitingTitle => 'Cây đang chờ cả hai';

  @override
  String get loveTreeWaitingBody =>
      'Cây sẽ lớn khi cả hai cùng có mặt. Mời người ấy tham gia nhé 💌';

  @override
  String get loveTreeWaitingCta => 'Mời người ấy';

  @override
  String get loveTreeNoCoupleBody =>
      'Ghép đôi với người ấy để bắt đầu trồng cây nhé 🌱';

  @override
  String get loveTreeCoachTooltip => 'Chạm để xem khoảnh khắc 🌸';

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
      'Tấm ảnh chúng mình đã cùng giữ lại 💞';

  @override
  String get loveTreeMomentStreakCopy =>
      'Chuỗi dài nhất hai bạn từng giữ được. Bắt đầu chuỗi mới để phá kỷ lục này nhé 🔥';

  @override
  String get loveTreeMomentViewInGallery => 'Xem trong Thư viện';

  @override
  String loveTreeLockedDays(int count) {
    return 'Còn $count ngày nữa là nở 🌱';
  }

  @override
  String loveTreeLockedPhotos(int count) {
    return 'Còn $count kỷ niệm nữa là nở 🌱';
  }

  @override
  String loveTreeLockedStreak(int count) {
    return 'Còn $count ngày chuỗi nữa là nở 🌱';
  }

  @override
  String get loveTreeLockedPhotosCta => 'Thêm kỷ niệm';

  @override
  String get loveTreeLockedStreakCta => 'Trả lời hôm nay';

  @override
  String get loveTreeShareButton => 'Khoe cây';

  @override
  String loveTreeShareStats(int days, int flowers) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);
    final intl.NumberFormat flowersNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String flowersString = flowersNumberFormat.format(flowers);

    return '$daysString ngày bên nhau · $flowersString bông hoa';
  }

  @override
  String get loveTreeShareTagline => 'Cây tình yêu của chúng mình 🌳';

  @override
  String get loveTreeShareTaglineSeed => 'Cây vừa nảy mầm 🌱';

  @override
  String loveTreeShareMessage(int flowers, int days) {
    final intl.NumberFormat flowersNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String flowersString = flowersNumberFormat.format(flowers);
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    return 'Cây tình yêu của chúng mình đã nở $flowersString bông hoa sau $daysString ngày 🌳💞 — vun cây cùng người ấy trên Dear Embeiu.';
  }

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

  @override
  String get careMessageBadge => 'QUAN TÂM';

  @override
  String get careMessageEntryTitle => 'Gửi quan tâm';

  @override
  String get careMessageQuickPicksTitle => 'Gợi ý nhanh';

  @override
  String get careMessageTitleLabel => 'Tiêu đề';

  @override
  String get careMessageTitleHint => 'vd: Nhớ quá';

  @override
  String get careMessageBodyLabel => 'Lời nhắn';

  @override
  String get careMessageBodyHint => 'Viết vài lời thương thương...';

  @override
  String get careMessageSendCta => 'Gửi cho người ấy 💌';

  @override
  String get aiQuestionsSaveFailed => 'Chưa lưu được, thử lại sau nhé';

  @override
  String get dailyQuestionPreparing => 'Đang chuẩn bị câu hỏi hôm nay…';

  @override
  String get careMessageQueuedToast =>
      'Mạng chậm xíu, lời quan tâm sẽ tự gửi khi có mạng 💌';

  @override
  String get careMessageSentToast => 'Đã gửi rồi nhé 💌';

  @override
  String get careMessageErrorToast => 'Chưa gửi được, thử lại nhé.';

  @override
  String get careMessageNeedCouple =>
      'Cần ghép đôi trước khi gửi lời quan tâm nhé.';

  @override
  String get careMessageRecentTitle => 'Đã gửi gần đây';

  @override
  String get careMessageFromMe => 'Mình';

  @override
  String get careMessageFromPartner => 'Người ấy';

  @override
  String get careQuick1Title => 'Nhớ quá 💕';

  @override
  String get careQuick1Body => 'Tự nhiên nhớ ghê. Hôm nay thế nào rồi?';

  @override
  String get careQuick2Title => 'Uống nước nha 💧';

  @override
  String get careQuick2Body => 'Nhớ uống đủ nước nha, đừng để khát mới uống.';

  @override
  String get careQuick3Title => 'Ăn cơm chưa? 🍚';

  @override
  String get careQuick3Body => 'Nhớ ăn cơm đúng bữa, đừng bỏ bữa nha.';

  @override
  String get careQuick4Title => 'Ngủ sớm nha 🌙';

  @override
  String get careQuick4Body =>
      'Khuya rồi, ngủ sớm cho khoẻ nha. Chúc ngủ ngon!';

  @override
  String get careQuick5Title => 'Yêu nhiều lắm ❤️';

  @override
  String get careQuick5Body => 'Chỉ muốn nói là hôm nay cũng yêu nhiều lắm đó.';

  @override
  String get careQuick6Title => 'Cố lên nha 💪';

  @override
  String get careQuick6Body =>
      'Hôm nay chắc mệt lắm. Cố lên nha, luôn có mình ở đây mà.';

  @override
  String notifCareMessage(String name) {
    return '$name gửi lời quan tâm';
  }

  @override
  String get rpsGameTitle => 'Oẳn tù tì';

  @override
  String get rpsGameBadge => 'OẲN TÙ TÌ';

  @override
  String get rpsChoiceRock => 'Búa';

  @override
  String get rpsChoicePaper => 'Bao';

  @override
  String get rpsChoiceScissors => 'Kéo';

  @override
  String get rpsChoiceNone => 'Bỏ lượt';

  @override
  String get rpsResultWin => 'Bạn thắng 🎉';

  @override
  String get rpsResultLose => 'Người ấy thắng 😝';

  @override
  String get rpsResultDraw => 'Hoà 🤝';

  @override
  String get rpsWaitingPartner => 'Đang chờ người ấy…';

  @override
  String get rpsChosenWaiting => 'Bạn đã ra rồi ✓ · Chờ người ấy ra…';

  @override
  String get rpsExpired => 'Lời mời đã hết hạn';

  @override
  String get rpsCancelled => 'Người ấy đã huỷ lời mời';

  @override
  String notifRpsInvite(String name) {
    return '$name rủ bạn oẳn tù tì!';
  }

  @override
  String notifRpsResult(String name) {
    return 'Ván oẳn tù tì với $name đã có kết quả';
  }

  @override
  String get rpsHistoryBadge => 'LỊCH SỬ VÁN';

  @override
  String get rpsEntryIdleSubtitle => 'Rủ người ấy một ván nhé';

  @override
  String rpsEntryWeekScore(String win, String draw, String loss) {
    return 'Tuần này $win – $draw – $loss';
  }

  @override
  String get rpsEntryInvitedTitle => 'Người ấy đang rủ!';

  @override
  String get rpsEntryInvitedSubtitle => 'Vào chơi ngay nhé';

  @override
  String get rpsEntryPendingSubtitle => 'Lời mời hết hạn sau 10 phút';

  @override
  String get rpsEntryCtaPlay => 'Chơi';

  @override
  String get rpsEntryCtaJoin => 'Vào chơi';

  @override
  String get rpsEntryCtaOpen => 'Mở';

  @override
  String rpsScoreFormat(String win, String draw, String loss) {
    return '$win – $draw – $loss';
  }

  @override
  String rpsScoreSemantics(String win, String draw, String loss) {
    return 'Tỉ số: bạn $win, hoà $draw, người ấy $loss';
  }

  @override
  String rpsChoiceSemantics(String choice) {
    return 'Chọn $choice';
  }

  @override
  String get rpsRulesHint => 'Kéo cắt Bao · Bao bọc Búa · Búa đập Kéo';

  @override
  String get rpsRuleScissorsPaper => 'Kéo cắt Bao';

  @override
  String get rpsRulePaperRock => 'Bao bọc Búa';

  @override
  String get rpsRuleRockScissors => 'Búa đập Kéo';

  @override
  String get rpsMeLabel => 'Mình';

  @override
  String get rpsPartnerLabel => 'Người ấy';

  @override
  String get rpsVs => 'vs';

  @override
  String get rpsWaitingBody => 'Đã gửi lời mời. Chờ người ấy vào nhé…';

  @override
  String get rpsWaitingBodyInvitee =>
      'Đang kết nối với người ấy… Cả hai cùng có mặt là bắt đầu.';

  @override
  String get rpsNudgeCta => 'Nhắc lại';

  @override
  String rpsNudgeCooldown(String seconds) {
    return 'Nhắc lại (${seconds}s)';
  }

  @override
  String get rpsNudgeSentToast => 'Đã nhắc người ấy lần nữa 🔔';

  @override
  String get rpsCancelCta => 'Huỷ lời mời';

  @override
  String get rpsCloseCta => 'Đóng';

  @override
  String get rpsCancelledToast => 'Đã huỷ lời mời';

  @override
  String get rpsCountdownPrompt => 'Chọn ngay!';

  @override
  String get rpsCountdownUnit => 'GIÂY';

  @override
  String rpsCountdownSemantics(int seconds) {
    return 'Còn $seconds giây';
  }

  @override
  String get rpsResolving => 'Đang mở kết quả…';

  @override
  String get rpsResolvingSlow => 'Mạng đang hơi chậm…';

  @override
  String get rpsReloadCta => 'Tải lại';

  @override
  String get rpsOfflineHint =>
      'Mất mạng rồi, có mạng lại sẽ tự gửi lựa chọn của bạn';

  @override
  String rpsResultDrawSub(String choice) {
    return 'Cùng ra $choice';
  }

  @override
  String get rpsResultTimeoutPartner => 'Người ấy không kịp chọn';

  @override
  String get rpsResultTimeoutMe => 'Bạn không kịp chọn';

  @override
  String get rpsResultTimeoutBoth => 'Cả hai bỏ lượt — ván này hoà';

  @override
  String get rpsRematchCta => 'Chơi lại';

  @override
  String get rpsHistoryCta => 'Xem lịch sử';

  @override
  String get rpsRematchToast => 'Người ấy rủ chơi lại!';

  @override
  String rpsResultSemantics(String title, String mine, String theirs) {
    return '$title. Bạn ra $mine, người ấy ra $theirs.';
  }

  @override
  String get rpsExpiredBody =>
      'Lời mời quá 10 phút nên đã hết hạn. Rủ lại nhé!';

  @override
  String get rpsCancelledBody => 'Không sao, lúc nào rủ ván khác cũng được mà.';

  @override
  String get rpsInviteAgainCta => 'Rủ lại';

  @override
  String get rpsErrorTitle => 'Chưa mở được ván chơi';

  @override
  String get rpsErrorBody => 'Kiểm tra mạng rồi thử lại nhé.';

  @override
  String get rpsNeedCouple =>
      'Ghép đôi với người ấy rồi mới chơi cùng được nhé.';

  @override
  String get rpsScoreMe => 'MÌNH';

  @override
  String get rpsScoreDraw => 'HOÀ';

  @override
  String get rpsScorePartner => 'NGƯỜI ẤY';

  @override
  String rpsHistoryTotal(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Đã chơi $countString ván';
  }

  @override
  String rpsHistoryWinStreak(String count) {
    return 'Chuỗi thắng: $count';
  }

  @override
  String get rpsOutcomeWin => 'Bạn thắng';

  @override
  String get rpsOutcomeLoss => 'Người ấy thắng';

  @override
  String get rpsOutcomeDraw => 'Hoà';

  @override
  String get rpsOutcomeSkipped => 'Bỏ lượt';

  @override
  String rpsHistoryRowSemantics(
    String time,
    String mine,
    String theirs,
    String outcome,
  ) {
    return '$time: bạn $mine, người ấy $theirs, $outcome';
  }

  @override
  String get rpsHistoryEmptyTitle => 'Chưa có ván nào';

  @override
  String get rpsHistoryEmptyBody =>
      'Ván nào chúng mình chơi cũng sẽ nằm ở đây, kể cả ván hoà.';

  @override
  String get rpsHistoryEmptyCta => 'Rủ người ấy một ván';

  @override
  String get featureTourRpsTitle => 'Oẳn tù tì cùng người ấy';

  @override
  String get featureTourRpsBody =>
      'Rủ một ván, cùng đếm oẳn tù tì rồi ra tay. Không có chuyện bỏ lượt, ai chưa ra thì app nhắc. Cả hai chọn xong mới lộ kết quả. Lịch sử và tỉ số nằm ở Hồ sơ.';

  @override
  String get featureTourSleepTitle => 'Giấc ngủ của chúng mình';

  @override
  String get featureTourSleepBody =>
      'Lịch trăng ghi lại từng đêm, trăng càng tròn là ngủ càng đủ giấc. Cùng bật chia sẻ thì sáng ra mở app là biết đêm qua người ấy ngủ mấy tiếng.';

  @override
  String get featureTourSkyTitle => 'Chòm sao hôm nay';

  @override
  String get featureTourSkyBody =>
      'Cây Tình Yêu giờ có bầu trời đêm. Mỗi người 3 ngôi sao: trả lời câu hỏi, chọn tâm trạng, nhắn một tin. Đủ 6 sao là trái tim sáng trọn.';

  @override
  String get rpsOpenPrompt => 'Ra tay đi! Không có bỏ lượt đâu 😄';

  @override
  String get rpsOpenRingSemantics =>
      'Không giới hạn thời gian, ra tay khi bạn sẵn sàng';

  @override
  String get rpsPartnerMovedTitle => 'Người ấy đã ra rồi!';

  @override
  String get rpsPartnerMovedBody => 'Tới lượt bạn — chọn tay bên dưới';

  @override
  String get rpsMoveNudgeCta => 'Nhắc người ấy';

  @override
  String rpsMoveNudgeCooldown(String seconds) {
    return 'Đã nhắc · nhắc lại sau ${seconds}s';
  }

  @override
  String get rpsMoveNudgeSentToast => 'Đã nhắc người ấy 🔔';

  @override
  String rpsMoveNudgeTooSoon(String seconds) {
    return 'Vừa nhắc rồi — đợi ${seconds}s nữa nhé';
  }

  @override
  String get rpsMoveNudgeFailed => 'Chưa gửi được lời nhắc, thử lại nhé';

  @override
  String get rpsChosenLeaveHint =>
      'Cứ làm việc khác nhé, có kết quả là báo bạn ngay';

  @override
  String get rpsEntryMyTurnSubtitle => 'Tới lượt bạn, ra tay nhé 😄';

  @override
  String get rpsEntryUnplayedTitle => 'Ván đang dở';

  @override
  String get rpsEntryUnplayedSubtitle => 'Chưa ai ra — vào trước nhé';

  @override
  String get rpsEntryAwaitingTitle => 'Đang chờ người ấy ra';

  @override
  String get rpsEntryAwaitingSubtitle => 'Bạn đã ra · có kết quả sẽ báo';

  @override
  String get rpsEntryCtaThrow => 'Ra tay';

  @override
  String notifRpsMoved(String name) {
    return '$name đã ra rồi — tới lượt bạn!';
  }

  @override
  String get sleepCardTitle => 'Đêm qua';

  @override
  String get sleepBadge => 'GIẤC NGỦ';

  @override
  String get sleepYou => 'Bạn';

  @override
  String get sleepUnitHour => 'g';

  @override
  String get sleepUnitMinute => 'p';

  @override
  String sleepDurationShort(int h, int m) {
    return '${h}g ${m}p';
  }

  @override
  String sleepMinutesShort(int m) {
    return '${m}p';
  }

  @override
  String sleepDurationLong(int h, int m) {
    return '$h giờ $m phút';
  }

  @override
  String sleepTogether(String duration) {
    return 'Ngủ cùng lúc $duration';
  }

  @override
  String sleepWentFirst(String name, String duration) {
    return '$name ngủ trước $duration';
  }

  @override
  String get sleepNoOverlap => 'Đêm qua hai bạn không ngủ cùng lúc';

  @override
  String get sleepSetupPitch =>
      'Để điện thoại tự ghi giấc ngủ, sáng nào cũng biết đêm qua người ấy ngủ ra sao.';

  @override
  String get sleepEnableCta => 'Bật theo dõi';

  @override
  String get sleepHide => 'Ẩn';

  @override
  String get sleepNotRecorded => 'Chưa ghi nhận';

  @override
  String get sleepLogManually => 'Ghi tay';

  @override
  String get sleepPartnerNotShared => 'Chưa chia sẻ';

  @override
  String sleepPartnerNotSharedLong(String name) {
    return '$name chưa chia sẻ giấc ngủ';
  }

  @override
  String get sleepNoData => 'Chưa có dữ liệu';

  @override
  String get sleepNeedsPermission => 'Cần cấp lại quyền';

  @override
  String get sleepOpenSettings => 'Mở cài đặt';

  @override
  String get sleepPermissionBanner =>
      'App chưa được xem lúc màn hình bật, tắt nên chưa ghi được giấc ngủ. Bạn bật lại trong Cài đặt → Quyền truy cập dữ liệu sử dụng nhé.';

  @override
  String get sleepViewBoth => 'Cả hai';

  @override
  String get sleepPrevMonth => 'Tháng trước';

  @override
  String get sleepNextMonth => 'Tháng sau';

  @override
  String sleepNightTitle(String d1, String d2) {
    return 'Đêm $d1 → sáng $d2';
  }

  @override
  String sleepAwakenings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Thức giấc $count lần',
    );
    return '$_temp0';
  }

  @override
  String get sleepNoAwakenings => 'Ngủ một mạch';

  @override
  String get sleepSourceEdited => 'Đã sửa';

  @override
  String get sleepSourceManual => 'Ghi tay';

  @override
  String get sleepSourceHealth => 'Apple Health';

  @override
  String get sleepSourcePhone => 'Điện thoại (tự động)';

  @override
  String get sleepSourceMotion => 'Chuyển động của điện thoại';

  @override
  String sleepSourceRow(String source) {
    return 'Nguồn: $source';
  }

  @override
  String get sleepMonthSection => 'Tháng này';

  @override
  String get sleepPerNight => '/đêm';

  @override
  String sleepAvgTimes(String bed, String wake) {
    return 'Ngủ ~$bed · Dậy ~$wake';
  }

  @override
  String sleepFullNights(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count đêm tròn giấc',
    );
    return '$_temp0';
  }

  @override
  String sleepOfNights(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'trên $count đêm',
    );
    return '$_temp0';
  }

  @override
  String sleepTogetherNights(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count đêm ngủ cùng lúc từ 7 tiếng',
    );
    return '$_temp0';
  }

  @override
  String sleepTogetherAvg(String duration) {
    return 'trung bình $duration mỗi đêm';
  }

  @override
  String get sleepShareToggle => 'Chia sẻ với người ấy';

  @override
  String get sleepShareToggleSub => 'Tắt thì chỉ mình bạn xem được.';

  @override
  String get sleepHowItWorks => 'App tính giấc ngủ thế nào?';

  @override
  String get sleepMyColor => 'Màu trăng của bạn';

  @override
  String sleepMyColorSub(String name, String color, String blocked) {
    return '$name đang dùng màu $color. Màu quá giống ($blocked) bị khoá.';
  }

  @override
  String sleepMyColorSubNoBlock(String name, String color) {
    return '$name đang dùng màu $color.';
  }

  @override
  String get sleepMyColorSolo => 'Màu này đánh dấu giấc ngủ của bạn ở mọi chỗ.';

  @override
  String sleepColorTakenSemantics(String name) {
    return 'Màu của $name';
  }

  @override
  String sleepColorTooClose(String name) {
    return 'Quá giống màu của $name';
  }

  @override
  String sleepColorAutoChanged(String color) {
    return 'Màu bạn chọn trùng với người ấy nên tạm hiện màu $color.';
  }

  @override
  String get sleepColorRose => 'Hồng';

  @override
  String get sleepColorPurple => 'Tím';

  @override
  String get sleepColorBlue => 'Xanh dương';

  @override
  String get sleepColorTeal => 'Ngọc';

  @override
  String get sleepColorOrange => 'Cam';

  @override
  String get sleepColorGreen => 'Xanh lá';

  @override
  String get sleepColorMagenta => 'Hồng sen';

  @override
  String get sleepColorAmber => 'Vàng nghệ';

  @override
  String get sleepLegend0 => 'dưới 5g';

  @override
  String get sleepLegend1 => '5–6g';

  @override
  String get sleepLegend2 => '6–7g';

  @override
  String get sleepLegend3 => '7–8g';

  @override
  String get sleepLegend4 => 'từ 8g';

  @override
  String get sleepMoonTagline => 'Trăng càng tròn, ngủ càng tròn giấc';

  @override
  String get sleepMoonLeft => 'Trăng trái: Bạn';

  @override
  String sleepMoonRight(String name) {
    return 'Trăng phải: $name';
  }

  @override
  String get sleepMoonTogether => 'Ngủ cùng lúc từ 7 tiếng';

  @override
  String get sleepPhase0 => 'Trăng lưỡi liềm';

  @override
  String get sleepPhase1 => 'Trăng non';

  @override
  String get sleepPhase2 => 'Trăng bán nguyệt';

  @override
  String get sleepPhase3 => 'Trăng gần tròn';

  @override
  String get sleepPhase4 => 'Trăng tròn';

  @override
  String sleepDaySemantics(String day, String summary) {
    return 'Ngày $day: $summary';
  }

  @override
  String sleepSemanticsSlept(String name, String duration, String phase) {
    return '$name ngủ $duration, $phase';
  }

  @override
  String sleepSemanticsNoData(String name) {
    return '$name chưa có dữ liệu';
  }

  @override
  String get sleepEditedSemantics => '(đã sửa)';

  @override
  String get sleepNoOverlapNight => 'Đêm này hai bạn không ngủ cùng lúc';

  @override
  String get sleepManualHint => 'Bấm nút sửa để ghi tay';

  @override
  String get sleepPartnerNightEmpty => 'Chưa có dữ liệu đêm này';

  @override
  String get sleepEditLocked => 'Đêm này quá 7 ngày rồi nên không sửa được nữa';

  @override
  String get sleepEditButton => 'Sửa giờ ngủ đêm này';

  @override
  String get sleepSetupTitle => 'Để điện thoại tự ghi giấc ngủ';

  @override
  String get sleepSetupBodyAndroid =>
      'Mỗi sáng, app xem đêm qua bạn để điện thoại yên lâu nhất từ mấy giờ đến mấy giờ. App không đọc tin nhắn, ảnh hay bất kỳ nội dung nào.';

  @override
  String get sleepSetupBodyIos =>
      'App đọc giấc ngủ mà iPhone hoặc Apple Watch đã ghi trong app Sức khoẻ. Chỉ đọc, không ghi gì vào đó.';

  @override
  String get sleepSetupUnsupported =>
      'Máy này chưa tự ghi được giấc ngủ. Bạn vẫn ghi tay được, mỗi lần chỉ mất vài giây.';

  @override
  String get sleepSetupPoint1 => 'Không cần làm gì mỗi ngày';

  @override
  String get sleepSetupPoint2 => 'App đoán sai thì bạn sửa được';

  @override
  String get sleepSetupPoint3 => 'Chỉ chia sẻ khi bạn muốn';

  @override
  String get sleepSetupHintAndroid =>
      'App sẽ mở Cài đặt → Quyền truy cập dữ liệu sử dụng. Bạn bật Dear Embeiu rồi quay lại đây nhé.';

  @override
  String get sleepSetupHintIos =>
      'iPhone sẽ hỏi quyền đọc mục Giấc ngủ trong Sức khoẻ. Chưa có dữ liệu thì bật Lịch ngủ trong app Sức khoẻ.';

  @override
  String get sleepPermissionStillOff =>
      'Dear Embeiu chưa được bật trong danh sách. Bạn thử lại nhé.';

  @override
  String get sleepGrantCta => 'Cấp quyền';

  @override
  String get sleepManualCta => 'Mình sẽ tự ghi';

  @override
  String sleepShareAskTitle(String name) {
    return 'Cho $name xem giấc ngủ của bạn?';
  }

  @override
  String get sleepShareAskBody =>
      'Người ấy sẽ thấy giờ ngủ, giờ dậy và những lần bạn thức giấc trong đêm. Bạn tắt lúc nào cũng được.';

  @override
  String sleepShareAskPreview(String name) {
    return '$name SẼ THẤY';
  }

  @override
  String get sleepShareAskOnly =>
      'Chỉ giờ ngủ, giờ dậy và những lần thức giấc trong đêm, theo giờ nơi bạn ngủ. Đêm nào bạn sửa hoặc ghi tay sẽ có thêm nhãn.';

  @override
  String get sleepShareAskCta => 'Chia sẻ với người ấy';

  @override
  String get sleepLater => 'Để sau';

  @override
  String get sleepBackToStep1 => 'Quay lại bước 1';

  @override
  String get sleepEditBedTitle => 'Đi ngủ';

  @override
  String get sleepEditWakeTitle => 'Thức dậy';

  @override
  String sleepEditTotal(String duration) {
    return 'Tổng: $duration';
  }

  @override
  String get sleepEditInvalid => 'Giấc ngủ cần dài từ 1 đến 16 tiếng';

  @override
  String get sleepDeleteNight => 'Xoá đêm này';

  @override
  String get sleepEditSubtitle => 'Sửa lại nếu app đoán chưa đúng.';

  @override
  String get sleepManualSubtitle => 'Ghi lại lúc bạn đi ngủ và lúc thức dậy.';

  @override
  String get sleepEditNote =>
      'Lưu xong, đêm này mang nhãn “Đã sửa” (người ấy cũng thấy) và app không tự ghi đè nữa.';

  @override
  String get sleepManualNote =>
      'Lưu xong, đêm này mang nhãn “Ghi tay”, người ấy cũng thấy.';

  @override
  String get sleepPickerSubtitle => 'Kéo để chọn giờ và phút';

  @override
  String get sleepSaveFailed => 'Chưa lưu được, thử lại nhé';

  @override
  String get sleepLoadFailed => 'Chưa tải được giấc ngủ của người ấy';

  @override
  String get sleepHowBody1 =>
      'App coi khoảng điện thoại nằm yên lâu nhất trong đêm là giấc ngủ, tính từ 18h tới 14h hôm sau, dài 3 đến 16 tiếng. Khoảng kết thúc trước 1 giờ sáng, như lúc cắm sạc buổi tối, chỉ được tính khi đêm đó không có khoảng nào kéo dài sau 1 giờ.';

  @override
  String get sleepHowBody1Ios =>
      'App lấy giấc ngủ dài nhất mà iPhone hoặc Apple Watch ghi trong Sức khoẻ, tính từ 18h tới 14h hôm sau. Giấc dưới 3 tiếng hoặc quá 16 tiếng không được tính. Giấc kết thúc trước 1 giờ sáng chỉ được tính khi đêm đó không có giấc nào kéo dài sau 1 giờ.';

  @override
  String get sleepHowBody2 =>
      'Cầm máy dưới 5 phút giữa đêm chỉ tính là một lần thức giấc, giấc ngủ không bị cắt đôi.';

  @override
  String get sleepHowBody3 =>
      'Đây chỉ là ước tính: nằm xem phim hay để quên máy ở xa đều làm số lệch. Bạn sửa được trong 7 ngày, và người ấy sẽ thấy nhãn “Đã sửa”.';

  @override
  String get sleepHowBody4 =>
      'App không đọc nội dung nào trên máy, chỉ biết lúc màn hình bật hay tắt.';

  @override
  String get sleepHowBody4Ios =>
      'App chỉ đọc mục Giấc ngủ trong Sức khoẻ, ngoài ra không đọc gì.';

  @override
  String get sleepHowIphoneInBed =>
      'iPhone có thể tự ghi giờ lên giường: mở Sức khoẻ → Duyệt → Giấc ngủ → Lịch ngủ, đặt giờ ngủ rồi bật theo dõi thời gian trên giường bằng iPhone. Một số máy từ iOS 18 không còn tuỳ chọn này.';

  @override
  String get sleepHowMotion =>
      'Nếu bạn cho app xem chuyển động, đêm nào không có số liệu thì app đoán từ quãng điện thoại nằm yên. Đây chỉ là phỏng đoán: máy để trên bàn cả tối cũng bị tính là đang ngủ.';

  @override
  String get sleepGotIt => 'Đã hiểu';

  @override
  String get sleepIosHealthHint =>
      'Đặt *Lịch ngủ* trong Sức khoẻ (Duyệt → Giấc ngủ) để iPhone tự ghi giờ lên giường, nếu máy có tuỳ chọn này.';

  @override
  String get sleepHintDismiss => 'Ẩn gợi ý';

  @override
  String get timePickerDefaultTitle => 'Chọn giờ nhắc';

  @override
  String get timePickerDefaultSubtitle => 'Kéo để chọn giờ và phút';

  @override
  String get timePickerConfirm => 'Xác nhận';

  @override
  String sleepHoursShort(int h) {
    return '${h}g';
  }

  @override
  String sleepHoursLong(int h) {
    return '$h giờ';
  }

  @override
  String get loveTreeSkyTitle => 'Chòm sao hôm nay';

  @override
  String get loveTreeSkyExplain =>
      'Mỗi việc nhỏ chúng mình làm cho nhau hôm nay thắp một ngôi sao. Đủ cả hai nửa, trái tim sáng trọn.';

  @override
  String get loveTreeLeftHalf => 'Nửa trái: Bạn';

  @override
  String loveTreeRightHalf(String name) {
    return 'Nửa phải: $name';
  }

  @override
  String get loveTreeStarQuestion => 'Câu hỏi';

  @override
  String get loveTreeStarMood => 'Tâm trạng';

  @override
  String get loveTreeStarMessage => 'Nhắn tin';

  @override
  String get loveTreeTapStar => 'Chạm vào một ngôi sao để xem chi tiết';

  @override
  String get loveTreeHeartFull => 'Trái tim hôm nay đã sáng trọn';

  @override
  String get loveTreeTaskQuestion => 'Trả lời câu hỏi hôm nay';

  @override
  String get loveTreeTaskMood => 'Chia sẻ tâm trạng';

  @override
  String get loveTreeTaskMessage => 'Nhắn cho nhau một câu';

  @override
  String loveTreeStarAnsweredAt(String name, String time) {
    return '$name đã trả lời lúc $time';
  }

  @override
  String loveTreeStarMoodAt(String mood, String time) {
    return '$mood · $time';
  }

  @override
  String loveTreeStarMessagedAt(String name, String time) {
    return '$name đã nhắn lúc $time';
  }

  @override
  String get loveTreeStarDone => 'Đã xong hôm nay';

  @override
  String get loveTreeStarNoAnswer => 'Chưa trả lời câu hỏi hôm nay';

  @override
  String get loveTreeStarNoMood => 'Chưa chia sẻ tâm trạng hôm nay';

  @override
  String get loveTreeStarNoMessage => 'Chưa nhắn gì hôm nay';

  @override
  String get loveTreeActAnswer => 'Trả lời ngay';

  @override
  String get loveTreeActMood => 'Chia sẻ ngay';

  @override
  String get loveTreeActMessage => 'Nhắn ngay';

  @override
  String get loveTreeNudge => 'Gửi lời quan tâm';

  @override
  String get loveTreeClosePanel => 'Đóng';

  @override
  String loveTreeStarSemantics(String name, String task, String state) {
    return '$name · $task · $state';
  }

  @override
  String get loveTreeStarLit => 'đã thắp';

  @override
  String get loveTreeStarUnlit => 'chưa thắp';

  @override
  String get loveTreeFlowersExplain =>
      'Mỗi bông là một cột mốc của chúng mình. Chạm vào bông hoa để xem lại.';

  @override
  String get loveTreeKindDays => 'Ngày bên nhau';

  @override
  String get loveTreeKindStreak => 'Chuỗi câu hỏi';

  @override
  String get loveTreeKindPhotos => 'Kỷ niệm ảnh';

  @override
  String get loveTreeNextFlower => 'BÔNG TIẾP THEO';

  @override
  String loveTreeNextProgressDays(int current, int target) {
    return '$current/$target ngày bên nhau';
  }

  @override
  String loveTreeNextProgressStreak(int current, int target) {
    return '$current/$target ngày chuỗi';
  }

  @override
  String loveTreeNextProgressPhotos(int current, int target) {
    return '$current/$target ảnh';
  }

  @override
  String get loveTreeTodayTasks => 'Việc nhỏ hôm nay';

  @override
  String loveTreeTaskDone(String name) {
    return '$name ✓';
  }

  @override
  String loveTreeTaskPending(String name) {
    return '$name · chưa';
  }

  @override
  String get loveTreeDoNow => 'Làm ngay';

  @override
  String get loveTreeBloomedTitle => 'Cột mốc đã nở';

  @override
  String get loveTreeShowLess => 'Thu gọn';

  @override
  String homeConstellationSemantics(int lit) {
    return 'Chòm sao hôm nay: $lit trên 6 sao. Mở Cây Tình Yêu';
  }
}

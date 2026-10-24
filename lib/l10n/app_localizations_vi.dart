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
  String get moodChangeShort => 'Đổi';

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
  String widgetStatusQuestionPartner(String name) {
    return '$name đã trả lời, đến lượt mình';
  }

  @override
  String get widgetStatusQuestionBoth => 'Cả hai đã trả lời hôm nay';

  @override
  String get widgetStatusQuestionMine => 'Câu hỏi hôm nay đang chờ mình';

  @override
  String widgetStatusMood(String name, String mood) {
    return '$name hôm nay: $mood';
  }

  @override
  String widgetStatusMessage(String name) {
    return '$name vừa nhắn cho mình';
  }

  @override
  String widgetStatusPhoto(String name) {
    return '$name vừa đăng ảnh mới';
  }

  @override
  String widgetStatusDecisionEat(String result) {
    return 'Hôm nay ăn: $result';
  }

  @override
  String widgetStatusDecisionGo(String result) {
    return 'Hôm nay: $result';
  }

  @override
  String widgetStatusDecisionCustom(String question, String result) {
    return '$question: $result';
  }

  @override
  String widgetStatusShortQuestionPartner(String name) {
    return '$name đã trả lời';
  }

  @override
  String get widgetStatusShortQuestionBoth => 'Cả hai đã trả lời';

  @override
  String get widgetStatusShortQuestionMine => 'Câu hỏi đang chờ mình';

  @override
  String widgetStatusShortMood(String name, String mood) {
    return '$name: $mood';
  }

  @override
  String widgetStatusShortMessage(String name) {
    return '$name vừa nhắn';
  }

  @override
  String widgetStatusShortPhoto(String name) {
    return '$name đăng ảnh mới';
  }

  @override
  String widgetStatusShortDecisionEat(String result) {
    return 'Ăn: $result';
  }

  @override
  String widgetStatusShortDecisionGo(String result) {
    return '$result';
  }

  @override
  String widgetStatusShortDecisionCustom(String result) {
    return 'Quay ra: $result';
  }

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
  String get featureTourSleepMotionTitle =>
      'Không cần đồng hồ vẫn biết giấc ngủ';

  @override
  String get featureTourSleepMotionBody =>
      'Để điện thoại cạnh giường là đủ: app đoán giờ ngủ, giờ dậy từ lúc máy nằm yên. Đêm nào lệch thì chạm vào sửa lại.';

  @override
  String get featureTourDecisionTitle => 'Chọn giúp chúng mình';

  @override
  String get featureTourDecisionBody =>
      'Ăn gì, đi đâu, ai rửa bát? Quay một vòng rồi chốt, người ấy biết ngay kết quả.';

  @override
  String get featureTourWidgetTodayTitle => 'Widget có tin của người ấy';

  @override
  String get featureTourWidgetTodayBody =>
      'Widget ngoài màn hình chính thêm một dòng: người ấy vừa trả lời câu hỏi, đổi tâm trạng hay chốt món hôm nay.';

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
  String get sleepSourceHealthEmpty => 'Apple Health (chưa có dữ liệu)';

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
      'Nếu bạn cho app xem chuyển động, đêm nào không có số liệu thì app đoán từ quãng điện thoại nằm yên. Đây chỉ là phỏng đoán: điện thoại nằm trên bàn cả buổi sáng có thể bị tính nhầm là đang ngủ, bạn sửa tay được. Dữ liệu chuyển động thô chỉ nằm trên máy; người ấy chỉ thấy giờ ngủ và giờ thức khi bạn bật chia sẻ.';

  @override
  String get sleepGotIt => 'Đã hiểu';

  @override
  String get sleepIosHealthHint =>
      'Đặt *Lịch ngủ* trong Sức khoẻ (Duyệt → Giấc ngủ) để iPhone tự ghi giờ lên giường, nếu máy có tuỳ chọn này.';

  @override
  String get sleepMotionHint =>
      'Cho app xem *chuyển động* để đêm nào thiếu số liệu vẫn được đoán từ lúc điện thoại nằm yên.';

  @override
  String get sleepMotionAllow => 'Cho phép';

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

  @override
  String get decisionCardTitle => 'Phân vân gì không?';

  @override
  String get decisionHistoryLink => 'Đã quay';

  @override
  String get decisionRowEatTitle => 'Ăn gì?';

  @override
  String get decisionRowGoTitle => 'Đi đâu?';

  @override
  String get decisionRowCustomTitle => 'Phân vân khác';

  @override
  String get decisionRowEmpty => 'Chưa ai quay hôm nay';

  @override
  String get decisionRowCustomEmpty => 'Ai rửa bát, xem phim gì…';

  @override
  String get decisionRowEatLabel => 'HÔM NAY ĂN';

  @override
  String get decisionRowGoLabel => 'HÔM NAY MÌNH';

  @override
  String get decisionSpinCta => 'Quay';

  @override
  String get decisionCustomCta => 'Nhập & quay';

  @override
  String decisionByMe(String time) {
    return 'Mình quay · $time';
  }

  @override
  String decisionByPartner(String name, String time) {
    return '$name quay · $time';
  }

  @override
  String decisionSpinsBadge(int count) {
    return '×$count';
  }

  @override
  String decisionCustomMore(int count) {
    return '+$count câu khác';
  }

  @override
  String get decisionRowHintSpin => 'Chạm để quay';

  @override
  String get decisionRowHintView => 'Chạm để xem';

  @override
  String decisionSheetByMe(String time) {
    return 'Mình quay lúc $time';
  }

  @override
  String decisionSheetByPartner(String name, String time) {
    return '$name quay lúc $time';
  }

  @override
  String decisionSheetSpins(int count) {
    return 'quay $count lần';
  }

  @override
  String get decisionPhotoCta => 'Chụp lại';

  @override
  String get decisionAskAnother => 'Phân vân câu khác';

  @override
  String get decisionBadge => 'CHỌN GIÚP';

  @override
  String get decisionModeEat => 'Ăn gì';

  @override
  String get decisionModeGo => 'Đi đâu';

  @override
  String get decisionModeCustom => 'Tự nhập';

  @override
  String get decisionFilterAny => 'Tuỳ';

  @override
  String get decisionFilterHomeCooked => 'Nhà nấu';

  @override
  String get decisionFilterEatOut => 'Ăn ngoài';

  @override
  String get decisionFilterQuick => 'Nhanh gọn';

  @override
  String get decisionFilterStayIn => 'Ở nhà';

  @override
  String get decisionFilterGoOut => 'Ra ngoài';

  @override
  String get decisionFilterFree => 'Không tốn tiền';

  @override
  String get decisionReelEatLabel => 'HÔM NAY ĂN';

  @override
  String get decisionReelGoLabel => 'HÔM NAY MÌNH';

  @override
  String get decisionIdleEat => 'Bấm quay, app chọn món giúp';

  @override
  String get decisionIdleGo => 'Bấm quay, app chọn chỗ giúp';

  @override
  String get decisionIdleCustom => 'Thêm ít nhất 2 lựa chọn rồi quay';

  @override
  String get decisionPoolEmpty => 'Hết món hợp bộ lọc này, thử chip khác nhé';

  @override
  String get decisionTagHomeCooked => 'Nhà nấu';

  @override
  String get decisionTagEatOut => 'Ăn ngoài';

  @override
  String get decisionTagEither => 'Nấu hay ăn ngoài đều được';

  @override
  String get decisionTagQuick => 'nhanh gọn';

  @override
  String get decisionTagMedium => 'vừa sức';

  @override
  String get decisionTagFancy => 'cầu kỳ';

  @override
  String get decisionTagStayIn => 'Ở nhà';

  @override
  String get decisionTagGoOut => 'Ra ngoài';

  @override
  String get decisionTagFree => 'không tốn tiền';

  @override
  String get decisionTagCheap => 'rẻ';

  @override
  String get decisionTagPricey => 'hơi tốn';

  @override
  String get decisionTagManualEat => 'Món chúng mình tự thêm';

  @override
  String get decisionTagManualGo => 'Chỗ chúng mình tự thêm';

  @override
  String decisionTagCustomOf(int count) {
    return '1 trong $count lựa chọn';
  }

  @override
  String decisionCurrent(String result) {
    return 'Đang chốt: $result';
  }

  @override
  String get decisionSpin => 'Quay';

  @override
  String get decisionSpinSemanticsEat => 'Quay chọn món';

  @override
  String get decisionSpinSemanticsGo => 'Quay chọn chỗ đi';

  @override
  String get decisionSpinSemanticsCustom => 'Quay chọn giúp';

  @override
  String decisionResultSemantics(String result, String tag) {
    return 'Kết quả: $result. $tag';
  }

  @override
  String get decisionCommit => 'Chốt luôn';

  @override
  String get decisionRespin => 'Quay lại';

  @override
  String get decisionManual => 'Nhập tay';

  @override
  String get decisionManualTitleEat => 'Mình muốn ăn…';

  @override
  String get decisionManualTitleGo => 'Mình muốn đi…';

  @override
  String get decisionManualHintEat => 'Ví dụ: Bánh xèo';

  @override
  String get decisionManualHintGo => 'Ví dụ: Đi dạo Hồ Tây';

  @override
  String get decisionQuestionLabel => 'Phân vân chuyện gì?';

  @override
  String get decisionQuestionHint1 => 'Phở hay bún?';

  @override
  String get decisionQuestionHint2 => 'Đà Lạt hay Vũng Tàu?';

  @override
  String get decisionQuestionHint3 => 'Ai rửa bát?';

  @override
  String get decisionPresetLabel => 'Điền nhanh';

  @override
  String get decisionPresetWho => 'Ai làm?';

  @override
  String get decisionPresetWhich => 'Cái nào?';

  @override
  String decisionPresetReplaced(int count) {
    return 'Đã thay $count lựa chọn';
  }

  @override
  String get decisionOptionsLabel => 'Các lựa chọn';

  @override
  String decisionOptionsCount(int count) {
    return '$count/12';
  }

  @override
  String get decisionOptionAddHint => 'Thêm lựa chọn';

  @override
  String decisionOptionNumberHint(int n) {
    return 'Lựa chọn $n';
  }

  @override
  String get decisionOptionAdd => 'Thêm';

  @override
  String decisionOptionRemove(String option) {
    return 'Xoá $option';
  }

  @override
  String get decisionOptionsNeedTwo => 'Cần ít nhất 2 lựa chọn để quay';

  @override
  String get decisionOptionsMax => 'Đủ 12 lựa chọn rồi';

  @override
  String get decisionOptionDuplicate => 'Lựa chọn này có rồi';

  @override
  String get decisionTextTooLong => 'Dài quá rồi, viết gọn lại chút nhé';

  @override
  String get decisionCustomDailyCap =>
      'Hôm nay chốt đủ 10 câu rồi, mai quay tiếp nhé';

  @override
  String get decisionCustomDefaultQuestion => 'Chọn giúp chúng mình';

  @override
  String get decisionMeFallback => 'Mình';

  @override
  String decisionCommittedPaired(String name) {
    return 'Đã chốt, đã báo $name';
  }

  @override
  String get decisionCommittedSolo => 'Đã chốt, lưu vào lịch sử của chúng mình';

  @override
  String get decisionCommittedQueued =>
      'Đang mất mạng. Có mạng lại app gửi liền.';

  @override
  String get decisionCommitFailed =>
      'Chưa chốt được. Mạng chập chờn, thử lại nhé';

  @override
  String get decisionRetry => 'Thử lại';

  @override
  String get decisionHistoryBadge => 'ĐÃ QUAY';

  @override
  String get decisionTopEat => 'Hay ăn';

  @override
  String get decisionTopGo => 'Hay đi';

  @override
  String get decisionTopCaption => '90 ngày qua';

  @override
  String get decisionTopEmpty => 'Chưa có gì';

  @override
  String decisionTopCountSemantics(int count) {
    return '$count lần';
  }

  @override
  String get decisionRecent => 'Gần đây';

  @override
  String get decisionDayToday => 'Hôm nay';

  @override
  String get decisionDayYesterday => 'Hôm qua';

  @override
  String decisionSpinsSemantics(int count) {
    return 'quay $count lần';
  }

  @override
  String get decisionHistoryEmptyTitle => 'Chưa quay lần nào';

  @override
  String get decisionHistoryEmptyBody =>
      'Lần tới phân vân ăn gì, đi đâu, ai rửa bát, cứ để app chọn. Chốt xong sẽ hiện ở đây.';

  @override
  String get decisionHistoryEmptyCta => 'Quay thử';

  @override
  String get decisionHistoryLoadError => 'Chưa tải được lịch sử';

  @override
  String get decisionReminderSettingTitle => 'Nhắc chọn món';

  @override
  String get decisionReminderSettingSubtitle =>
      'Chưa ai chốt món hôm nay thì nhắc lúc này';

  @override
  String get decisionReminderTitle => 'Hôm nay ăn gì?';

  @override
  String get decisionReminderBody1 => 'Tối nay ăn gì? Quay một phát cho xong.';

  @override
  String get decisionReminderBody2 =>
      'Chưa ai chốt món hôm nay, mình quay trước nhé.';

  @override
  String get decisionReminderBody3 =>
      'Thôi \"tuỳ em\" với \"tuỳ anh\". Để app chọn giúp.';

  @override
  String get decisionReminderBody4 => 'Bún, phở hay cơm nhà? Quay là biết.';

  @override
  String get decisionReminderBody5 =>
      'Sắp tới giờ ăn rồi. Quay món rồi báo người ấy luôn.';

  @override
  String notifDecisionEat(String name, String result) {
    return '$name quay ra: hôm nay ăn $result';
  }

  @override
  String notifDecisionGo(String name, String result) {
    return '$name quay ra: $result';
  }

  @override
  String notifDecisionCustom(String name, String question, String result) {
    return '$name quay \"$question\": $result';
  }

  @override
  String notifDecisionRespin(String name, String result) {
    return '$name quay lại: $result';
  }

  @override
  String get caroPlayTogetherTitle => 'Chơi cùng nhau';

  @override
  String get caroGameTitle => 'Cờ caro';

  @override
  String caroEntryInvited(String name) {
    return '$name rủ bạn một ván và đã đi nước đầu.';
  }

  @override
  String caroEntryMyTurn(String name, String n) {
    return 'Đến lượt bạn. $name vừa đi nước $n.';
  }

  @override
  String caroEntryWaiting(String name, String n, String time) {
    return 'Đang chờ $name. Bạn đi nước $n lúc $time.';
  }

  @override
  String caroEntryWatching(String name) {
    return '$name đang mở ván, chờ chút nhé.';
  }

  @override
  String caroEntryStale(String days) {
    return 'Ván dừng $days ngày rồi. Vào kết thúc để rủ ván mới.';
  }

  @override
  String caroEntryJustLost(String name, String score) {
    return '$name thắng ván vừa rồi. $score.';
  }

  @override
  String caroEntryJustWon(String score) {
    return 'Bạn thắng ván vừa rồi. $score.';
  }

  @override
  String caroEntryJustDraw(String score) {
    return 'Ván vừa rồi hoà. $score.';
  }

  @override
  String caroEntryIdle(String score, String name) {
    return '$score. Rủ $name một ván?';
  }

  @override
  String caroEntryFirst(String name) {
    return 'Rủ $name một ván, bạn đi trước.';
  }

  @override
  String caroScore(String me, String a, String b, String partner) {
    return '$me $a – $b $partner';
  }

  @override
  String caroScoreDraws(String score, String n) {
    return '$score, $n ván hoà';
  }

  @override
  String caroScorePair(String a, String b) {
    return '$a – $b';
  }

  @override
  String get caroCtaJoin => 'Vào chơi';

  @override
  String get caroCtaPlayOn => 'Đi tiếp';

  @override
  String get caroCtaRematch => 'Phục thù';

  @override
  String get caroCtaNewGame => 'Ván mới';

  @override
  String get caroCtaInvite => 'Chơi';

  @override
  String get caroCtaRetry => 'Thử lại';

  @override
  String get caroActionError => 'Chưa làm được, thử lại nhé.';

  @override
  String get caroEntryError => 'Chưa tải được ván. Chạm để thử lại.';

  @override
  String caroNewTitle(String name) {
    return 'Rủ $name chơi caro';
  }

  @override
  String get caroNewSub => 'Chọn luật cho ván này. Đổi được ở ván sau.';

  @override
  String get caroRuleVn => 'Chặn hai đầu';

  @override
  String get caroRuleVnDesc =>
      'Năm quân liền nhau là thắng, trừ khi cả hai đầu đều bị quân người kia chặn.';

  @override
  String get caroRuleFree => 'Tự do';

  @override
  String get caroRuleFreeDesc =>
      'Cứ năm quân liền nhau là thắng, bị chặn hai đầu vẫn tính.';

  @override
  String get caroRuleExampleNoWin => 'Thế này chưa thắng';

  @override
  String get caroRuleExampleWin => 'Thế này là thắng';

  @override
  String get caroRuleLastUsed => 'lần trước';

  @override
  String caroNewFirstNote(String name) {
    return 'Bạn cầm X, quân đầu đặt ở giữa bàn. $name nhận được lời rủ ngay.';
  }

  @override
  String caroNewCta(String name) {
    return 'Rủ $name chơi';
  }

  @override
  String get caroNewPickFirst => 'Tự chọn ô đầu tiên';

  @override
  String get caroBadge => 'CỜ CARO';

  @override
  String get caroMyTurn => 'Đến lượt bạn';

  @override
  String caroLastMove(String name, String n, String time) {
    return '$name vừa đi nước $n lúc $time.';
  }

  @override
  String caroWaiting(String name) {
    return 'Đang chờ $name';
  }

  @override
  String caroYouMoved(String n, String time, String name) {
    return 'Bạn đi nước $n lúc $time. Cứ thoát app, $name đi xong là có thông báo.';
  }

  @override
  String caroPartnerWatching(String n, String time, String name) {
    return 'Bạn đi nước $n lúc $time. $name đang xem ván.';
  }

  @override
  String caroWaitedMin(String n, String time, int m) {
    return 'Bạn đi nước $n lúc $time. Đã $m phút rồi.';
  }

  @override
  String caroNudged(String name, String time) {
    return 'Đã nhắc $name lúc $time.';
  }

  @override
  String get caroLaneWins => 'thắng';

  @override
  String get caroLaneWatching => 'đang xem';

  @override
  String caroLaneMove(String n) {
    return 'nước $n';
  }

  @override
  String get caroLaneNew => 'ván mới';

  @override
  String caroLaneGames(String n) {
    return '$n ván';
  }

  @override
  String get caroLanePlusOne => '+1 ván này';

  @override
  String get caroPlayHere => 'Đi nước này';

  @override
  String get caroSending => 'Đang đi…';

  @override
  String get caroSendError =>
      'Chưa đi được nước này, ô bạn chọn vẫn giữ nguyên. Thử lại nhé.';

  @override
  String get caroStaleBoard => 'Bàn vừa đổi, xem lại rồi đi nhé.';

  @override
  String get caroOffline => 'Đang mất mạng. Có mạng lại là đi tiếp được.';

  @override
  String get caroWaitNetwork => 'Chờ có mạng';

  @override
  String get caroTapAgainHint =>
      'Chạm lại ô đang chọn cũng là đi. Chạm ô khác để đổi.';

  @override
  String caroNudge(String name) {
    return 'Nhắc $name';
  }

  @override
  String caroNudgeIn(int m) {
    return 'Nhắc sau $m phút';
  }

  @override
  String caroNudgeSent(String name) {
    return 'Đã nhắc $name';
  }

  @override
  String caroInvitedTitle(String name) {
    return '$name rủ bạn chơi caro';
  }

  @override
  String caroInvitedSubVn(String name) {
    return '$name đã đi nước đầu. Luật chặn hai đầu: năm quân bị chặn cả hai đầu thì chưa thắng.';
  }

  @override
  String caroInvitedSubFree(String name) {
    return '$name đã đi nước đầu. Luật tự do: cứ năm quân liền nhau là thắng.';
  }

  @override
  String get caroLater => 'Để sau';

  @override
  String get caroFirstTitle => 'Đặt quân đầu tiên';

  @override
  String caroFirstSub(String name) {
    return 'Bạn cầm X và đi trước. Đi xong là $name nhận được lời rủ.';
  }

  @override
  String caroInviteCta(String name) {
    return 'Rủ $name chơi';
  }

  @override
  String caroStaleTitle(String days) {
    return 'Ván dừng $days ngày rồi';
  }

  @override
  String caroStaleSub(String date, String name) {
    return 'Không ai đi từ $date. Nhắc $name, hoặc kết thúc để rủ ván mới.';
  }

  @override
  String get caroEndGame => 'Kết thúc ván';

  @override
  String caroInvitedYesterday(String name, String when, String time) {
    return 'Bạn rủ $name $when, lúc $time.';
  }

  @override
  String caroOldAppHint(String name) {
    return 'Nếu $name chưa thấy ván, có thể app của $name cần cập nhật.';
  }

  @override
  String get caroLoading => 'Đang tải ván';

  @override
  String get caroCancelledTitle => 'Ván này đã huỷ';

  @override
  String caroCancelledSub(String name, String time) {
    return '$name bấm Để sau lúc $time. Ván huỷ không tính vào tỉ số.';
  }

  @override
  String get caroExpiredTitle => 'Ván này đã kết thúc vì để lâu';

  @override
  String get caroExpiredSub =>
      '7 ngày không ai đi nên ván dừng ở đây, không tính tỉ số.';

  @override
  String caroNewInviteCta(String name) {
    return 'Rủ $name ván mới';
  }

  @override
  String get caroHistoryTooltip => 'Lịch sử ván';

  @override
  String caroRuleTapHint(String rule) {
    return 'Luật $rule, chạm để xem giải thích';
  }

  @override
  String get caroResign => 'Xin thua';

  @override
  String get caroRuleEdgeNote => 'Mép bàn không tính là chặn.';

  @override
  String get caroEndKeep => 'Để đó';

  @override
  String get caroEndConfirm => 'Kết thúc';

  @override
  String get caroResignTitle => 'Xin thua ván này?';

  @override
  String caroResignBody(String name, String score) {
    return '$name được tính thắng. Tỉ số thành $score.';
  }

  @override
  String get caroKeepPlaying => 'Chơi tiếp';

  @override
  String get caroCancelTitle => 'Bỏ ván này?';

  @override
  String caroCancelBody(String name) {
    return 'Ván huỷ không tính tỉ số. $name sẽ thấy ván đã huỷ.';
  }

  @override
  String get caroCancelConfirm => 'Bỏ ván';

  @override
  String get caroEndTitle => 'Kết thúc ván này?';

  @override
  String get caroEndBody =>
      'Ván này không tính tỉ số. Kết thúc rồi là rủ được ván mới.';

  @override
  String get caroZoomIn => 'Phóng to quanh nước cuối';

  @override
  String get caroZoomOut => 'Xem toàn bàn';

  @override
  String get caroYouWon => 'Bạn thắng ván này';

  @override
  String caroPartnerWon(String name) {
    return '$name thắng ván này';
  }

  @override
  String caroWinDetail(String n, String time, String span) {
    return 'Năm quân liền nhau ở nước $n, lúc $time. Ván kéo dài $span.';
  }

  @override
  String caroSpanHours(int h) {
    return '$h giờ';
  }

  @override
  String caroSpanMinutes(int m) {
    return '$m phút';
  }

  @override
  String caroPartnerResigned(String name) {
    return '$name xin thua';
  }

  @override
  String caroPartnerResignedSub(String n) {
    return 'Ván này bạn thắng, ở nước $n.';
  }

  @override
  String get caroYouResigned => 'Bạn đã xin thua';

  @override
  String caroYouResignedSub(String name) {
    return '$name được tính thắng ván này.';
  }

  @override
  String get caroDraw => 'Ván này hoà';

  @override
  String get caroDrawSub => 'Kín cả 225 ô mà chưa ai thắng.';

  @override
  String get caroSeeHistory => 'Xem lịch sử ván';

  @override
  String get caroHistoryBadge => 'LỊCH SỬ CARO';

  @override
  String caroLeads(String name, String n) {
    return '$name dẫn trước $n ván';
  }

  @override
  String caroTied(String a) {
    return 'Đang hoà $a – $a';
  }

  @override
  String caroHistorySub(String n, String date, String name, String when) {
    return '$n ván từ $date. Ván gần nhất $name thắng $when.';
  }

  @override
  String caroHistorySubNoSince(String n, String name, String when) {
    return '$n ván. Ván gần nhất $name thắng $when.';
  }

  @override
  String caroHistorySubDrawNoSince(String n, String when) {
    return '$n ván. Ván gần nhất hoà $when.';
  }

  @override
  String caroHistorySubDraw(String n, String date, String when) {
    return '$n ván từ $date. Ván gần nhất hoà $when.';
  }

  @override
  String get caroWhenToday => 'hôm nay';

  @override
  String get caroWhenYesterday => 'hôm qua';

  @override
  String caroWhenOn(String date) {
    return 'ngày $date';
  }

  @override
  String get caroDateToday => 'Hôm nay';

  @override
  String get caroDateYesterday => 'Hôm qua';

  @override
  String caroRowWon(String name) {
    return '$name thắng';
  }

  @override
  String get caroRowDraw => 'Hoà';

  @override
  String caroRowFive(String n) {
    return 'Năm quân liền, $n nước';
  }

  @override
  String caroRowResign(String name, String n) {
    return '$name xin thua ở nước $n';
  }

  @override
  String get caroRowFull => 'Kín bàn, 225 nước';

  @override
  String get caroRowFreeSuffix => '. Tự do';

  @override
  String get caroHistoryEmpty => 'Chưa có ván nào xong';

  @override
  String get caroHistoryEmptySub =>
      'Ván đầu tiên đang chờ đó. Tỉ số bắt đầu từ 0 – 0.';

  @override
  String get caroOpenCurrent => 'Mở ván đang chơi';

  @override
  String caroStartWith(String name) {
    return 'Rủ $name một ván';
  }

  @override
  String get caroHistoryPageError => 'Chưa tải thêm được ván cũ.';

  @override
  String caroReplayBadge(String date) {
    return 'VÁN $date';
  }

  @override
  String caroCellEmpty(String r, String c) {
    return 'Hàng $r, cột $c, trống';
  }

  @override
  String caroCellX(String r, String c, String name) {
    return 'Hàng $r, cột $c, quân X của $name';
  }

  @override
  String caroCellO(String r, String c, String name) {
    return 'Hàng $r, cột $c, quân O của $name';
  }

  @override
  String get caroCellLast => ', nước vừa đi';

  @override
  String get caroCellSelected => ', đang chọn';

  @override
  String get caroCellWinning => ', trong đường thắng';

  @override
  String caroNotifInvite(String name) {
    return '$name rủ bạn chơi cờ caro';
  }

  @override
  String get caroNotifInviteBody => 'Nước đầu đã đi rồi, giờ đến lượt bạn.';

  @override
  String caroWidgetTurn(String name) {
    return '$name đã đi caro, đến lượt mình';
  }

  @override
  String get caroWidgetTurnShort => 'Lượt mình đi caro';

  @override
  String get caroTourTitle => 'Cờ caro theo lượt';

  @override
  String get caroTourBody =>
      'Mỗi người đi một nước khi rảnh, rải cả ngày cũng được. Thắng thua cộng vào tỉ số chung của chúng mình.';

  @override
  String get weatherCardTitle => 'Thời tiết hai nơi';

  @override
  String weatherUpdatedAt(String time) {
    return 'Cập nhật $time';
  }

  @override
  String weatherStaleAt(String time) {
    return 'Số liệu lúc $time';
  }

  @override
  String get weatherStaleHeader => 'Chưa cập nhật được';

  @override
  String get weatherLoadFailed => 'Chưa tải được thời tiết';

  @override
  String get weatherRetry => 'Thử lại';

  @override
  String get weatherWhereAmI => 'Bạn đang ở đâu?';

  @override
  String weatherWhereIsPartner(String name) {
    return '$name đang ở đâu?';
  }

  @override
  String weatherWhereIsPartnerNext(String name) {
    return 'Còn $name đang ở đâu?';
  }

  @override
  String get weatherChoose => 'Chọn';

  @override
  String get weatherChooseForPartner => 'Chọn giúp';

  @override
  String weatherSetupBody(String name) {
    return 'Chọn chỗ của bạn và của $name. Sáng nào mở app cũng thấy trời hai nơi.';
  }

  @override
  String get weatherSetupBodySolo =>
      'Chọn thành phố của bạn, sáng nào mở app cũng thấy trời hôm nay.';

  @override
  String get weatherSetupCta => 'Chọn thành phố';

  @override
  String get weatherHide => 'Ẩn';

  @override
  String get weatherHideA11y => 'Ẩn thẻ thời tiết';

  @override
  String weatherSameCity(String city) {
    return 'Cả hai cùng ở $city';
  }

  @override
  String weatherColder(String name, int n) {
    return 'Chỗ $name lạnh hơn $n°';
  }

  @override
  String weatherWarmer(String name, int n) {
    return 'Chỗ $name nóng hơn $n°';
  }

  @override
  String weatherCtaUmbrella(String name) {
    return 'Nhắc $name mang ô';
  }

  @override
  String weatherCtaWater(String name) {
    return 'Nhắc $name uống nước';
  }

  @override
  String weatherCtaWarm(String name) {
    return 'Nhắc $name mặc ấm';
  }

  @override
  String weatherCtaA11yUmbrella(String name) {
    return 'Nhắc $name mang ô';
  }

  @override
  String weatherCtaA11yWater(String name) {
    return 'Nhắc $name uống nước';
  }

  @override
  String weatherCtaA11yWarm(String name) {
    return 'Nhắc $name mặc ấm';
  }

  @override
  String get weatherCtaHint => 'Mở màn Quan tâm, lời nhắn đã soạn sẵn';

  @override
  String get weatherCardHint => 'Mở chi tiết thời tiết';

  @override
  String weatherDegrees(int n) {
    return '$n độ';
  }

  @override
  String get weatherCondRainNow => 'Đang mưa';

  @override
  String get weatherCondRainMorning => 'Sáng nay mưa';

  @override
  String get weatherCondRainAfternoon => 'Chiều nay mưa';

  @override
  String get weatherCondRainTonight => 'Tối nay mưa';

  @override
  String get weatherCondRainTomorrow => 'Sáng mai mưa';

  @override
  String weatherCondHot(int max) {
    return 'Nắng gắt, lên $max°';
  }

  @override
  String weatherCondCold(int min) {
    return 'Lạnh, xuống $min°';
  }

  @override
  String get weatherSkyClear => 'Trời quang';

  @override
  String get weatherSkyPartlyCloudy => 'Ít mây';

  @override
  String get weatherSkyCloudy => 'Nhiều mây';

  @override
  String get weatherSkyFog => 'Có sương mù';

  @override
  String get weatherSkyLightRain => 'Mưa nhỏ';

  @override
  String get weatherSkyRain => 'Có mưa';

  @override
  String get weatherSkyHeavyRain => 'Mưa to';

  @override
  String get weatherSkyThunder => 'Có dông';

  @override
  String get weatherSkySnow => 'Có tuyết';

  @override
  String weatherRestOfDay(int min, int max) {
    return 'Từ giờ tới khuya $min° – $max°';
  }

  @override
  String weatherScaleA11y(int min, int max, int now) {
    return 'Từ giờ tới khuya $min đến $max độ, bây giờ $now độ';
  }

  @override
  String weatherSlotA11y(String time, int n) {
    return '$time, $n độ';
  }

  @override
  String weatherSlotRainA11y(String time, int n) {
    return '$time, $n độ, có mưa';
  }

  @override
  String weatherPartnerSelfSet(String name) {
    return '$name tự chọn';
  }

  @override
  String get weatherSetByMe => 'bạn chọn giúp';

  @override
  String get weatherChangeCity => 'Đổi thành phố';

  @override
  String get weatherChangeForPartner => 'Đổi giúp';

  @override
  String weatherTheirTimeNow(String time) {
    return 'bên đó đang $time';
  }

  @override
  String get weatherPickerSubSelf =>
      'Chỉ cần tên thành phố, app không xin vị trí.';

  @override
  String weatherPickerSubPartner(String name) {
    return '$name vẫn tự đổi được sau.';
  }

  @override
  String get weatherSearchHint => 'Tìm thành phố hoặc tỉnh';

  @override
  String get weatherSearchLabel => 'Tìm thành phố';

  @override
  String get weatherClearSearch => 'Xoá chữ đã gõ';

  @override
  String get weatherGroupCurrent => 'Đang chọn';

  @override
  String get weatherGroupVn => 'Việt Nam';

  @override
  String get weatherGroupIntl => 'Nước ngoài';

  @override
  String weatherOldProvince(String name) {
    return 'Tỉnh cũ: $name';
  }

  @override
  String get weatherNoMatch => 'Chưa có thành phố này. Chọn nơi gần nhất nhé.';

  @override
  String weatherPartnerJustSet(String name) {
    return '$name vừa tự chọn chỗ của mình rồi.';
  }

  @override
  String get weatherLater => 'Để sau';

  @override
  String get weatherSourcePrefix => 'Dữ liệu thời tiết: ';

  @override
  String get weatherSettingsSection => 'Thời tiết hai nơi';

  @override
  String get weatherSettingsMine => 'Chỗ của bạn';

  @override
  String weatherSettingsPartner(String name) {
    return 'Chỗ $name';
  }

  @override
  String get weatherNotSet => 'Chưa chọn';

  @override
  String get weatherNotifToggle => 'Thời tiết chỗ người ấy';

  @override
  String weatherNotifToggleSub(String time, String name) {
    return 'Báo lúc $time khi chỗ $name mưa, nắng gắt hoặc lạnh. Tối đa 3 lần một tuần.';
  }

  @override
  String get weatherNotifNeedsCouple => 'Ghép đôi xong mới báo được.';

  @override
  String weatherNotifPreviewCaption(String name) {
    return 'Hôm nào chỗ $name có mưa, thông báo sẽ như thế này:';
  }

  @override
  String get weatherCareUmbrellaTitle => 'Nhớ mang ô nhé';

  @override
  String weatherCareUmbrellaBody(String city) {
    return '$city đang có mưa đó, nhớ mang ô nha.';
  }

  @override
  String get weatherCareWaterTitle => 'Uống nước nhiều nha';

  @override
  String weatherCareWaterBody(String city, int max) {
    return '$city hôm nay lên tới $max°. Ra đường nhớ che nắng, uống đủ nước nhé.';
  }

  @override
  String get weatherCareWarmTitle => 'Mặc ấm vào nhé';

  @override
  String weatherCareWarmBody(String city, int min) {
    return '$city xuống còn $min° đó. Ra ngoài nhớ mặc thêm áo.';
  }

  @override
  String weatherMorningRainTitle(String city) {
    return 'Hôm nay $city có mưa';
  }

  @override
  String weatherMorningRainBody(String name) {
    return 'Nhắc $name mang ô nhé?';
  }

  @override
  String weatherMorningHotTitle(String city, int max) {
    return 'Hôm nay $city lên $max°';
  }

  @override
  String weatherMorningHotBody(String name) {
    return 'Nhắc $name uống đủ nước nhé?';
  }

  @override
  String weatherMorningColdTitle(String city, int min) {
    return 'Hôm nay $city xuống $min°';
  }

  @override
  String weatherMorningColdBody(String name) {
    return 'Nhắc $name mặc ấm nhé?';
  }

  @override
  String get weatherSaveFailed => 'Chưa lưu được, thử lại nhé.';

  @override
  String get weatherLaneFailed => 'Chưa tải được';

  @override
  String get weatherFeatureTourTitle => 'Thời tiết hai nơi';

  @override
  String get weatherFeatureTourBody =>
      'Mở app là biết chỗ người ấy có mưa không. Trời sắp mưa thì chạm một cái là nhắc được người ấy mang ô.';

  @override
  String get arrivalCardTitle => 'Về đến nhà chưa?';

  @override
  String get arrivalOpenManageA11y => 'Mở cài đặt Về đến nhà';

  @override
  String arrivalPitch(String name) {
    return 'Về đến nhà là máy tự báo cho $name. Đang chạy xe thì khỏi phải nhắn.';
  }

  @override
  String get arrivalEnableCta => 'Bật báo về nhà';

  @override
  String get arrivalManualHome => 'Về nhà rồi';

  @override
  String get arrivalManualOther => 'Đến nơi rồi';

  @override
  String get arrivalHomeName => 'Nhà';

  @override
  String get arrivalEnterHome => 'Đã về đến nhà';

  @override
  String get arrivalExitHome => 'Đã rời nhà';

  @override
  String arrivalEnterPlace(String place) {
    return 'Đã đến $place';
  }

  @override
  String arrivalExitPlace(String place) {
    return 'Đã rời $place';
  }

  @override
  String arrivalYesterdayAt(String time) {
    return 'hôm qua $time';
  }

  @override
  String arrivalBattery(int pct) {
    return '$pct%';
  }

  @override
  String arrivalBatteryLow(int pct) {
    return 'Pin còn $pct%';
  }

  @override
  String get arrivalManualTag => 'bấm tay';

  @override
  String get arrivalPartnerOn => 'Đang bật báo về nhà';

  @override
  String arrivalPartnerOnSub(String name) {
    return 'Khi $name đến nơi, tin sẽ hiện ở đây.';
  }

  @override
  String get arrivalPartnerOff => 'Chưa bật báo về nhà';

  @override
  String get arrivalCareCta => 'Hỏi thăm';

  @override
  String arrivalCareA11y(String name) {
    return 'Hỏi thăm $name';
  }

  @override
  String get arrivalCareSuggestion => 'Về tới nơi rồi thì nghỉ ngơi nhé';

  @override
  String get arrivalNoEventToday => 'Chưa có tin hôm nay';

  @override
  String arrivalMineAuto(String places) {
    return 'Tự báo: $places';
  }

  @override
  String arrivalPlacesMany(int n) {
    return 'Nhà và $n nơi khác';
  }

  @override
  String get arrivalMineNeedAlways =>
      'Chưa tự báo được: cần quyền vị trí Luôn luôn';

  @override
  String get arrivalMineRemoteOff => 'Tạm thời chỉ báo bằng tay';

  @override
  String get arrivalMineManual => 'Chỉ báo khi bạn bấm';

  @override
  String get arrivalMineNoAddress => 'Chưa đặt địa chỉ Nhà';

  @override
  String get arrivalSetAddress => 'Đặt địa chỉ';

  @override
  String get arrivalOpenSettings => 'Mở Cài đặt';

  @override
  String arrivalFirstDetected(String place) {
    return 'App đã nhận ra $place';
  }

  @override
  String arrivalSent(String name) {
    return 'Đã báo $name';
  }

  @override
  String arrivalQueued(String name) {
    return 'Sẽ báo khi có mạng. Quá 30 phút thì $name chỉ thấy trên thẻ, không nhận thông báo.';
  }

  @override
  String arrivalSendFailed(String what) {
    return 'Chưa gửi được tin “$what”.';
  }

  @override
  String get arrivalRetry => 'Thử lại';

  @override
  String get arrivalPickTitle => 'Bạn vừa đến đâu?';

  @override
  String arrivalPickNote(String name, String me) {
    return 'Bấm là $name nhận “$me đã đến …” ngay, không cần quyền vị trí.';
  }

  @override
  String get arrivalAddPlace => 'Thêm nơi';

  @override
  String arrivalSlotsLeft(int n) {
    return 'Còn $n chỗ';
  }

  @override
  String get arrivalBadge => 'VỀ ĐẾN NHÀ';

  @override
  String get arrivalNewPlaceTitle => 'Nơi mới';

  @override
  String get arrivalNameLabel => 'Tên nơi';

  @override
  String get arrivalNameHint => 'Vd: Công ty, Nhà bố mẹ';

  @override
  String get arrivalNameNote => 'Người ấy sẽ thấy tên này khi bạn đến.';

  @override
  String get arrivalNameEmpty => 'Gõ tên để tiếp tục. Tối đa 24 ký tự.';

  @override
  String get arrivalChipWork => 'Công ty';

  @override
  String get arrivalChipSchool => 'Trường';

  @override
  String get arrivalChipFamily => 'Nhà bố mẹ';

  @override
  String get arrivalChipGym => 'Phòng gym';

  @override
  String get arrivalChipCafe => 'Quán quen';

  @override
  String get arrivalIconLabel => 'Biểu tượng';

  @override
  String get arrivalIconAuto =>
      'Chọn tên gợi ý thì biểu tượng tự đổi theo, bạn vẫn đổi lại được.';

  @override
  String get arrivalIconWork => 'Công việc';

  @override
  String get arrivalIconSchool => 'Trường';

  @override
  String get arrivalIconFamily => 'Gia đình';

  @override
  String get arrivalIconGym => 'Tập luyện';

  @override
  String get arrivalIconCafe => 'Quán';

  @override
  String get arrivalIconShop => 'Mua sắm';

  @override
  String get arrivalIconPin => 'Chỗ khác';

  @override
  String arrivalPreviewLead(String name) {
    return '$name sẽ thấy:';
  }

  @override
  String get arrivalContinue => 'Tiếp tục';

  @override
  String arrivalWhereTitle(String place) {
    return '$place ở đâu?';
  }

  @override
  String get arrivalWhereSub =>
      'Gõ đủ số nhà, tên đường và phường để tìm cho đúng.';

  @override
  String get arrivalSearchHint => 'Vd: 12 Nguyễn Trãi, Thanh Xuân, Hà Nội';

  @override
  String get arrivalSearching => 'Đang tìm…';

  @override
  String get arrivalSearchTip =>
      'Gõ xong bấm Tìm trên bàn phím nếu chưa thấy kết quả.';

  @override
  String get arrivalClearSearch => 'Xoá chữ đã gõ';

  @override
  String get arrivalUseCurrentRow => 'Không thấy địa chỉ? Dùng vị trí hiện tại';

  @override
  String get arrivalUseCurrentRowSub => 'Bấm khi bạn đang đứng ở đó';

  @override
  String get arrivalNoResults =>
      'Không tìm thấy địa chỉ này. Thử thêm tên phường hoặc tỉnh, hoặc dùng vị trí hiện tại khi bạn đang ở đó.';

  @override
  String get arrivalSearchOffline =>
      'Cần mạng để tìm địa chỉ. Có mạng lại thì gõ tiếp, hoặc dùng vị trí hiện tại khi bạn đang ở đó.';

  @override
  String get arrivalSearchError =>
      'Chưa tìm được lúc này. Thử lại sau chút nữa, hoặc dùng vị trí hiện tại khi bạn đang ở đó.';

  @override
  String get arrivalNoGeocoder =>
      'Máy này không tra được địa chỉ. Lúc đứng ở đó, bạn lưu bằng vị trí hiện tại nhé.';

  @override
  String get arrivalUseCurrent => 'Dùng vị trí hiện tại';

  @override
  String get arrivalNameOnly => 'Lưu tên, chỉ bấm tay';

  @override
  String arrivalCurrentTitle(String place) {
    return 'Bạn đang ở $place?';
  }

  @override
  String get arrivalCurrentBody =>
      'App đọc vị trí một lần để lưu chỗ này. Toạ độ chỉ nằm trên máy bạn.';

  @override
  String get arrivalCurrentHint =>
      'Lần đầu, máy sẽ hỏi quyền vị trí. Chọn “Cho phép khi dùng ứng dụng” và để Vị trí chính xác bật.';

  @override
  String get arrivalReadLocation => 'Đọc vị trí';

  @override
  String get arrivalReading => 'Đang đọc vị trí…';

  @override
  String get arrivalBackToSearch => 'Quay lại tìm địa chỉ';

  @override
  String get arrivalReadTimeout =>
      'Chưa đọc được vị trí. Ra chỗ thoáng hơn rồi thử lại nhé.';

  @override
  String get arrivalPreciseTitle => 'Cần bật Vị trí chính xác';

  @override
  String get arrivalPreciseBody =>
      'Nếu chỉ có vị trí gần đúng, app không phân biệt được bạn đã tới cửa hay còn cách nhà vài con phố.';

  @override
  String get arrivalConfirmTitle => 'Đúng chỗ này chưa?';

  @override
  String get arrivalFromAddress => 'Từ địa chỉ';

  @override
  String arrivalFromCurrent(int m) {
    return 'Vị trí hiện tại của bạn, lệch khoảng $m m';
  }

  @override
  String arrivalRadiusLine(int m) {
    return 'App báo khi bạn vào trong khoảng $m m quanh đây.';
  }

  @override
  String get arrivalNoHouseNumber =>
      'Địa chỉ này chưa có số nhà, app có thể báo hơi sớm hoặc hơi muộn.';

  @override
  String get arrivalConfirmAlleyWarn =>
      'Số nhà trong hẻm thường chỉ tìm được tới đầu hẻm, app có thể báo hơi sớm hoặc hơi muộn.';

  @override
  String get arrivalSave => 'Lưu';

  @override
  String get arrivalWrongSpot =>
      'Không đúng chỗ? Dùng vị trí hiện tại khi bạn đang ở đó';

  @override
  String get arrivalReread => 'Đọc lại vị trí';

  @override
  String arrivalSaved(String place) {
    return 'Đã lưu $place';
  }

  @override
  String arrivalEditTitle(String place) {
    return 'Sửa $place';
  }

  @override
  String get arrivalRenameNote => 'Đổi tên chỉ áp cho lần đến sau.';

  @override
  String get arrivalLocationLabel => 'Vị trí';

  @override
  String arrivalSavedFromAddress(String date) {
    return 'Lưu từ địa chỉ · $date';
  }

  @override
  String arrivalSavedFromCurrent(String date) {
    return 'Lưu bằng vị trí hiện tại · $date';
  }

  @override
  String get arrivalNoAddressManual => 'Chưa đặt địa chỉ, chỉ bấm tay';

  @override
  String get arrivalPaused => 'Đang tạm dừng';

  @override
  String get arrivalDeletePlace => 'Xoá nơi này';

  @override
  String get arrivalDeletePlaceSub => 'App hỏi lại trước khi xoá.';

  @override
  String arrivalDeletePlaceTitle(String place) {
    return 'Xoá $place?';
  }

  @override
  String get arrivalDeletePlaceBody =>
      'App thôi báo khi bạn đến đây. Tin đã gửi trước đó vẫn giữ tên cũ.';

  @override
  String get arrivalHomeEditBody =>
      'Nhà luôn có trên thẻ. Bạn chỉ đổi được chỗ của nó.';

  @override
  String get arrivalDeleteHomeAddress => 'Xoá địa chỉ';

  @override
  String get arrivalDeleteHomeAddressSub =>
      'Về Nhà thì bạn bấm tay “Về nhà rồi”.';

  @override
  String get arrivalDeleteHomeAddressTitle => 'Xoá địa chỉ Nhà?';

  @override
  String get arrivalDeleteHomeAddressBody =>
      'Nhà vẫn còn trên thẻ, bạn bấm “Về nhà rồi” mỗi lần về.';

  @override
  String get arrivalDelete => 'Xoá';

  @override
  String get arrivalCancel => 'Huỷ';

  @override
  String arrivalDeleted(String place) {
    return 'Đã xoá $place';
  }

  @override
  String get arrivalHomeAddressDeleted => 'Đã xoá địa chỉ Nhà';

  @override
  String get arrivalUndo => 'Hoàn tác';

  @override
  String get arrivalNeedPlaceTitle => 'Trước hết, nhà bạn ở đâu?';

  @override
  String get arrivalNeedPlaceBody =>
      'Máy cần biết Nhà ở đâu thì mới tự báo được. Gõ địa chỉ là xong, chưa cần cấp quyền gì.';

  @override
  String get arrivalNoAddressYet => 'Chưa đặt địa chỉ';

  @override
  String get arrivalSetHomeAddress => 'Đặt địa chỉ Nhà';

  @override
  String get arrivalLater => 'Để sau';

  @override
  String arrivalDisclosureTitle(String name) {
    return 'Về đến nơi, $name biết ngay';
  }

  @override
  String get arrivalDisclosureBody =>
      'Dear Embeiu dùng vị trí để báo người ấy khi bạn đến hoặc rời Nhà và những nơi bạn đã lưu, kể cả khi app đã đóng hoặc không dùng. Địa chỉ và toạ độ chỉ lưu trên máy bạn. Người ấy chỉ thấy tên nơi, giờ đến, giờ rời và mức pin lúc đó. Bạn tắt lúc nào cũng được.';

  @override
  String arrivalPreviewLabel(String name) {
    return '$name sẽ nhận được';
  }

  @override
  String get arrivalPushBody => 'Nhắn một câu hỏi thăm nhé';

  @override
  String get arrivalAgree => 'Đồng ý, tiếp tục';

  @override
  String get arrivalPrivacyLink => 'Chính sách bảo mật';

  @override
  String arrivalAlwaysTitle(String label) {
    return 'Chọn “$label”';
  }

  @override
  String arrivalAlwaysBody(String label) {
    return 'Để tự báo cả lúc app đang đóng, chọn “$label” ở trang tiếp theo.';
  }

  @override
  String get arrivalAlwaysLabelIos => 'Luôn luôn';

  @override
  String get arrivalAlwaysLabelAndroid => 'Cho phép mọi lúc';

  @override
  String get arrivalNextLooksLike => 'Trang tiếp theo trông như thế này';

  @override
  String get arrivalOsNever => 'Không bao giờ';

  @override
  String get arrivalOsAskNext => 'Hỏi lần sau';

  @override
  String get arrivalOsWhileUsing => 'Khi dùng ứng dụng';

  @override
  String get arrivalOsAndroidWhileUsing =>
      'Chỉ cho phép khi đang dùng ứng dụng';

  @override
  String get arrivalOsAndroidAsk => 'Luôn hỏi';

  @override
  String get arrivalOsAndroidDeny => 'Không cho phép';

  @override
  String get arrivalSwipeHint =>
      'Đừng vuốt tắt Dear Embeiu trong đa nhiệm. App bị vuốt tắt thì iPhone có thể không báo được.';

  @override
  String get arrivalAutostartHint =>
      'Máy Xiaomi, Oppo, Vivo: bật thêm Tự khởi động cho Dear Embeiu để tin báo không bị chặn.';

  @override
  String get arrivalOpenPermission => 'Mở trang quyền';

  @override
  String get arrivalLaterManual => 'Để sau, mình bấm tay';

  @override
  String get arrivalSetupDone => 'Xong';

  @override
  String get arrivalDoneTitle => 'Đã bật báo về nhà';

  @override
  String arrivalDoneBody(String name) {
    return 'Từ giờ về đến Nhà là $name biết. Muốn tắt thì vào Cài đặt → Về đến nhà. Tắt là tin gần nhất bị xoá, $name không nhận thông báo nào.';
  }

  @override
  String get arrivalDoneRow => 'Tự báo khi đến Nhà';

  @override
  String get arrivalDoneRowSub =>
      'Thêm Công ty, phòng gym… để báo cả những chỗ đó';

  @override
  String get arrivalPartialTitle => 'Tạm thời bạn báo bằng tay';

  @override
  String arrivalPartialBody(String name) {
    return 'Mỗi lần về, bấm “Về nhà rồi” ở trang chủ. $name nhận tin y như lúc máy tự báo. Các nơi đã lưu vẫn giữ nguyên.';
  }

  @override
  String get arrivalBackHome => 'Về trang chủ';

  @override
  String arrivalSeesLabel(String name) {
    return '$name đang thấy';
  }

  @override
  String arrivalShareTitle(String name) {
    return 'Báo cho $name';
  }

  @override
  String arrivalShareSub(String name) {
    return 'Tắt là xoá tin gần nhất trên máy chủ. $name không nhận thông báo nào.';
  }

  @override
  String arrivalShareOffSub(String name) {
    return 'Bật lại để báo cho $name mỗi khi bạn đến nơi.';
  }

  @override
  String get arrivalAutoTitle => 'Tự báo khi đến nơi';

  @override
  String arrivalAutoSub(String places) {
    return 'Máy tự báo khi bạn đến $places.';
  }

  @override
  String get arrivalAutoNeedPlace =>
      'Đặt địa chỉ Nhà hoặc một nơi khác trước, rồi bật.';

  @override
  String get arrivalAutoNeedAlways =>
      'Chưa tự báo được: cần quyền vị trí Luôn luôn.';

  @override
  String get arrivalAutoRemoteOff =>
      'Tạm thời chỉ báo bằng tay. Bạn vẫn bấm “Về nhà rồi” ở trang chủ.';

  @override
  String get arrivalPlacesTitle => 'Nơi báo';

  @override
  String get arrivalPlacesSub =>
      'Nhà luôn có. Thêm tối đa 4 nơi nữa. Địa chỉ chỉ nằm trên máy này.';

  @override
  String get arrivalPermTitle => 'Quyền vị trí';

  @override
  String get arrivalPermAlways => 'Vị trí: Luôn luôn';

  @override
  String get arrivalPermAlwaysSub => 'Đủ để tự báo cả lúc app đang đóng.';

  @override
  String get arrivalPermWhileUsing => 'Vị trí: Khi dùng ứng dụng';

  @override
  String get arrivalPermWhileUsingSub =>
      'Cần “Luôn luôn” thì máy mới tự báo lúc app đang đóng.';

  @override
  String get arrivalPermNone => 'Vị trí: Chưa cho phép';

  @override
  String get arrivalPermPreciseOn => 'Vị trí chính xác: Bật';

  @override
  String get arrivalPermPreciseOff => 'Vị trí chính xác: Tắt';

  @override
  String get arrivalPermPreciseSub =>
      'Để biết bạn đã tới cửa, không phải đầu ngõ.';

  @override
  String get arrivalPermOpenSettings => 'Mở Cài đặt của máy';

  @override
  String get arrivalTurnOffTitle => 'Tắt báo về nhà?';

  @override
  String arrivalTurnOffBody(String name, String me) {
    return 'Tin gần nhất của bạn bị xoá khỏi máy chủ ngay. $name sẽ thấy “$me chưa bật báo về nhà” và không nhận thông báo nào.';
  }

  @override
  String arrivalTurnOffAlsoPlaces(int n) {
    return 'Xoá luôn địa chỉ đã lưu của $n nơi trên máy này';
  }

  @override
  String get arrivalTurnOff => 'Tắt';

  @override
  String get arrivalSettingsPushTitle => 'Khi người ấy đến nơi';

  @override
  String arrivalSettingsPushSub(String name) {
    return 'Báo khi $name về nhà hoặc đến một nơi đã lưu. Tắt thì trang chủ vẫn hiện tin.';
  }

  @override
  String get arrivalSettingsTitle => 'Về đến nhà';

  @override
  String arrivalSettingsSharing(String name, String places) {
    return 'Đang báo cho $name: $places';
  }

  @override
  String get arrivalSettingsOff => 'Đang tắt';

  @override
  String arrivalWidgetHome(String name) {
    return '$name đã về đến nhà';
  }

  @override
  String arrivalWidgetHomeShort(String name) {
    return '$name về nhà rồi';
  }

  @override
  String arrivalWidgetPlace(String name, String place) {
    return '$name đã đến $place';
  }

  @override
  String arrivalWidgetPlaceShort(String name, String place) {
    return '$name tới $place';
  }

  @override
  String get arrivalTourTitle => 'Về đến nhà chưa?';

  @override
  String get arrivalTourBody =>
      'Về tới nhà, bấm “Về nhà rồi” trên trang chủ là người ấy biết, khỏi phải nhắn. Muốn thì cho máy tự báo khi bạn đến những nơi đã lưu.';

  @override
  String arrivalSaveFailed(String place) {
    return 'Chưa lưu được $place. Thử lại sau nhé.';
  }

  @override
  String get arrivalPlacesFull => 'Đã đủ 4 nơi. Xoá bớt một nơi rồi thêm lại.';

  @override
  String get arrivalUndoFailed =>
      'Chưa hoàn tác được: chỗ này vừa được dùng cho nơi khác.';

  @override
  String get moneyCatFood => 'Ăn uống';

  @override
  String get moneyCatFoodOut => 'Ăn ngoài';

  @override
  String get moneyCatFoodMarket => 'Đi chợ, siêu thị';

  @override
  String get moneyCatFoodCoffee => 'Cà phê, trà sữa';

  @override
  String get moneyCatFoodSnack => 'Ăn vặt';

  @override
  String get moneyCatDate => 'Hẹn hò';

  @override
  String get moneyCatDateMovie => 'Xem phim';

  @override
  String get moneyCatDateOut => 'Đi chơi';

  @override
  String get moneyCatDateGift => 'Quà cho người ấy';

  @override
  String get moneyCatMove => 'Đi lại';

  @override
  String get moneyCatMoveFuel => 'Xăng xe';

  @override
  String get moneyCatMoveParking => 'Gửi xe';

  @override
  String get moneyCatMoveGrab => 'Grab, taxi';

  @override
  String get moneyCatMoveRepair => 'Sửa xe';

  @override
  String get moneyCatHome => 'Nhà cửa';

  @override
  String get moneyCatHomeRent => 'Tiền nhà';

  @override
  String get moneyCatHomePower => 'Điện';

  @override
  String get moneyCatHomeWater => 'Nước';

  @override
  String get moneyCatHomeNet => 'Internet';

  @override
  String get moneyCatHomeGoods => 'Đồ gia dụng';

  @override
  String get moneyCatBill => 'Hoá đơn & gói';

  @override
  String get moneyCatBillPhone => 'Điện thoại';

  @override
  String get moneyCatBillStream => 'Xem phim, nghe nhạc';

  @override
  String get moneyCatBillSoft => 'Phần mềm';

  @override
  String get moneyCatShop => 'Mua sắm';

  @override
  String get moneyCatShopClothes => 'Quần áo';

  @override
  String get moneyCatShopBeauty => 'Mỹ phẩm';

  @override
  String get moneyCatShopTech => 'Đồ điện tử';

  @override
  String get moneyCatHealth => 'Sức khoẻ';

  @override
  String get moneyCatHealthMed => 'Thuốc';

  @override
  String get moneyCatHealthDoctor => 'Khám bệnh';

  @override
  String get moneyCatHealthSport => 'Thể thao';

  @override
  String get moneyCatEdu => 'Học tập';

  @override
  String get moneyCatEduFee => 'Học phí';

  @override
  String get moneyCatEduBooks => 'Sách, khoá học';

  @override
  String get moneyCatGift => 'Quà & hiếu hỉ';

  @override
  String get moneyCatGiftPresent => 'Quà tặng';

  @override
  String get moneyCatGiftWedding => 'Đám cưới, đám hiếu';

  @override
  String get moneyCatGiftLixi => 'Lì xì';

  @override
  String get moneyCatFamily => 'Gia đình';

  @override
  String get moneyCatFamilyParents => 'Biếu bố mẹ';

  @override
  String get moneyCatFamilyPet => 'Thú cưng';

  @override
  String get moneyCatTravel => 'Du lịch';

  @override
  String get moneyCatTravelTicket => 'Vé';

  @override
  String get moneyCatTravelStay => 'Chỗ ở';

  @override
  String get moneyCatTravelFun => 'Ăn chơi';

  @override
  String get moneyCatOther => 'Khác';

  @override
  String get moneyWalletCash => 'Tiền mặt';

  @override
  String get moneyJointWallet => 'Ví chung';

  @override
  String get moneyTitle => 'Sổ tiền';

  @override
  String get moneyBadge => 'SỔ TIỀN';

  @override
  String get moneyTabMine => 'Của mình';

  @override
  String get moneyTabShared => 'Chung';

  @override
  String moneyHomeShared(String month) {
    return 'Sổ chung tháng $month';
  }

  @override
  String moneyHomeSpent(String amount, String percent) {
    return 'Đã chi $amount · $percent% ngân sách';
  }

  @override
  String moneyHomeSpentNoBudget(String amount) {
    return 'Đã chi $amount tháng này';
  }

  @override
  String moneyHomeSpentOnly(String amount) {
    return 'Đã chi $amount';
  }

  @override
  String moneyHomeOverPart(String over) {
    return 'vượt $over';
  }

  @override
  String moneyHomeZero(String amount) {
    return 'Đã chi $amount · chưa có khoản nào';
  }

  @override
  String moneyHomeStale(String amount, String time) {
    return '$amount · số liệu lúc $time';
  }

  @override
  String get moneyHomeError => 'Chưa tải được sổ chung';

  @override
  String get moneyHomeLoading => 'Đang tải sổ chung';

  @override
  String get moneyHomeMine => 'Sổ tiền của mình';

  @override
  String moneyHomeTodayCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Hôm nay đã ghi $n khoản',
      zero: 'Hôm nay chưa ghi khoản nào',
    );
    return '$_temp0';
  }

  @override
  String get moneyHomeFirst => 'Gõ 50k, chọn danh mục là xong';

  @override
  String get moneyAddTx => 'Ghi khoản';

  @override
  String get moneyRetry => 'Thử lại';

  @override
  String get moneyMoreLabel => 'Ví, danh mục, ngân sách';

  @override
  String get moneyPrevMonth => 'Tháng trước';

  @override
  String get moneyNextMonth => 'Tháng sau';

  @override
  String get moneyMonthSpentMine => 'Đã chi';

  @override
  String get moneyMonthSpentShared => 'Chúng mình đã chi';

  @override
  String get moneyBudgetLeftLabel => 'Còn trong ngân sách';

  @override
  String get moneyBudgetNone => 'Chưa đặt ngân sách';

  @override
  String moneyBudgetUsed(String percent) {
    return 'Đã dùng $percent%';
  }

  @override
  String moneyBudgetOfShort(String amount) {
    return 'của $amount';
  }

  @override
  String get moneyToday => 'Hôm nay';

  @override
  String moneyBudgetSemantics(String percent, String left) {
    return 'Đã dùng $percent% ngân sách, còn $left';
  }

  @override
  String moneyFindingPerDay(
    String passed,
    String total,
    String percent,
    String perDay,
  ) {
    return 'Tháng mới qua $passed/$total ngày mà đã dùng $percent% ngân sách. Từ giờ tới cuối tháng, mỗi ngày chỉ còn khoảng $perDay.';
  }

  @override
  String moneyFindingOver(String over) {
    return 'Tháng này đã vượt ngân sách $over.';
  }

  @override
  String moneyFindingCategory(
    String category,
    String percent,
    String left,
    String days,
  ) {
    return '$category chung đã dùng $percent% ngân sách, còn $left cho $days ngày.';
  }

  @override
  String get moneyMe => 'Mình';

  @override
  String get moneyRecent => 'Gần đây';

  @override
  String moneyRecentEmpty(String month, String prev) {
    return 'Chưa có khoản nào trong tháng $month. Mở tháng $prev bằng nút ‹ ở trên để xem lại.';
  }

  @override
  String moneyEmptyMonth(String month) {
    return 'Tháng $month chưa có khoản nào. Bấm nút hồng ở góc dưới để ghi khoản đầu tiên.';
  }

  @override
  String moneyDaySpent(String amount) {
    return 'Chi $amount';
  }

  @override
  String moneyDayToday(String date) {
    return 'Hôm nay, $date';
  }

  @override
  String moneyDayYesterday(String date) {
    return 'Hôm qua, $date';
  }

  @override
  String get moneyWhere => 'Tiêu vào đâu';

  @override
  String moneyBudgetPercentShort(String percent) {
    return '$percent% ngân sách';
  }

  @override
  String moneyOverPercent(String percent) {
    return 'Vượt $percent%';
  }

  @override
  String get moneyWallets => 'Ví';

  @override
  String get moneyTotalAssets => 'Tổng tiền đang có';

  @override
  String moneyTotalAssetsValue(String amount) {
    return 'Tổng tiền đang có $amount';
  }

  @override
  String get moneyManageWallets => 'Quản lý ví';

  @override
  String moneyGoalProgress(String percent, String target) {
    return '$percent% của $target';
  }

  @override
  String moneyPaidByNoSplit(String name) {
    return '$name trả';
  }

  @override
  String get moneyPaidFromJoint => 'Trả từ Ví chung';

  @override
  String moneyEditedBy(String name, String time) {
    return '$name sửa $time';
  }

  @override
  String get moneyPending => 'chờ mạng';

  @override
  String moneyOffline(String time, int n) {
    return 'Đang mất mạng. Số dư là số lúc $time, cộng thêm $n khoản đang chờ gửi.';
  }

  @override
  String moneyOfflineNoTime(int n) {
    return 'Đang mất mạng. $n khoản đang chờ gửi.';
  }

  @override
  String moneyLoadError(String time) {
    return 'Chưa tải được khoản mới. Số liệu đúng lúc $time.';
  }

  @override
  String get moneyLoadErrorNoTime => 'Chưa tải được khoản mới.';

  @override
  String get moneyWaitingCard =>
      'Khi người ấy vào app, chúng mình có thêm sổ chung để ghi ai trả, chia đôi và góp quỹ đi chơi.';

  @override
  String get moneySendInvite => 'Gửi lời mời';

  @override
  String get moneyAdjustRow => 'Sửa số dư cho khớp';

  @override
  String moneyAdjustSub(String wallet) {
    return '$wallet · không tính là chi';
  }

  @override
  String moneyTransferSub(String from, String to) {
    return '$from → $to';
  }

  @override
  String moneyContribSub(String name) {
    return '$name góp';
  }

  @override
  String moneyContribOwnSub(String wallet) {
    return '$wallet → sổ chung';
  }

  @override
  String get moneyLinkedBadge => 'Có ở sổ chung';

  @override
  String get moneyFirstEntryTitle => 'Ghi khoản đầu tiên';

  @override
  String get moneyFirstEntryBody =>
      'Hôm nay vừa trả gì? Chạm một mục, gõ số tiền rồi Lưu.';

  @override
  String get moneyFirstEntryFoot =>
      'Ghi vài hôm, mình sẽ thấy tiền đi đâu nhiều nhất và đặt ngân sách cho tháng sau.';

  @override
  String get moneyNegWallet => 'Số dư âm, có khoản nào ghi nhầm ví không?';

  @override
  String get moneyCategories => 'Danh mục';

  @override
  String get moneyEditTx => 'Sửa khoản';

  @override
  String get moneyClose => 'Đóng';

  @override
  String get moneyBookShared => 'Sổ chung';

  @override
  String moneySwitchBook(String book) {
    return 'Đổi sổ, đang ở $book';
  }

  @override
  String get moneyTypeExpense => 'Chi';

  @override
  String get moneyTypeTransfer => 'Chuyển';

  @override
  String get moneyAmountLabel => 'Số tiền';

  @override
  String get moneyAmountHint => 'Gõ 50k, 1tr2 hay 1 củ đều được';

  @override
  String moneyAmountEcho(String raw) {
    return 'Bạn gõ “$raw”';
  }

  @override
  String get moneyAmountInvalid => 'Chưa hiểu số này. Thử 120k hoặc 120000.';

  @override
  String get moneyAmountTooBig =>
      'Tối đa 10 tỷ một khoản. Kiểm tra lại số 0 nhé.';

  @override
  String get moneyWalletCapHit =>
      'Số dư ví sẽ vượt 100 tỷ. Kiểm tra lại số tiền nhé.';

  @override
  String get moneyQuickRepeat => 'Ghi lại khoản quen';

  @override
  String get moneyCategory => 'Danh mục';

  @override
  String get moneyAllCategories => 'Tất cả';

  @override
  String get moneyWallet => 'Ví';

  @override
  String get moneyDeductMine => 'Trừ vào ví của mình';

  @override
  String get moneyFromWallet => 'Từ ví';

  @override
  String get moneyAddNote => 'Thêm ghi chú';

  @override
  String get moneyDate => 'Ngày';

  @override
  String get moneyNote => 'Ghi chú';

  @override
  String get moneyNoteHint => 'Bún chả, quà sinh nhật…';

  @override
  String moneySaveAmount(String amount) {
    return 'Lưu $amount';
  }

  @override
  String get moneySaveNeedAmount => 'Nhập số tiền để lưu';

  @override
  String get moneySaveFixAmount => 'Sửa số tiền để lưu';

  @override
  String get moneySaveNeedWallet => 'Chọn ví để lưu';

  @override
  String moneySaved(String amount, String category) {
    return 'Đã ghi $amount · $category';
  }

  @override
  String get moneySavedEdit => 'Đã lưu thay đổi';

  @override
  String get moneySavedOffline =>
      'Đang chờ mạng, có mạng sẽ tự gửi lên sổ chung';

  @override
  String get moneySavedOfflineMine => 'Đang chờ mạng, có mạng sẽ tự gửi lên';

  @override
  String moneyOverBudgetToast(String category, String amount) {
    return '$category chung đã vượt ngân sách $amount';
  }

  @override
  String moneyNearBudgetToast(String category, String percent) {
    return '$category chung đã dùng $percent% ngân sách tháng';
  }

  @override
  String moneyOverBudgetToastMine(String category, String amount) {
    return '$category đã vượt ngân sách $amount';
  }

  @override
  String moneyNearBudgetToastMine(String category, String percent) {
    return '$category đã dùng $percent% ngân sách tháng';
  }

  @override
  String moneyOverTotalToast(String amount) {
    return 'Cả tháng đã vượt ngân sách $amount';
  }

  @override
  String moneyNearTotalToast(String percent) {
    return 'Cả tháng đã dùng $percent% ngân sách';
  }

  @override
  String moneyConflictTitle(String name) {
    return 'Chưa lưu được: $name vừa sửa khoản này';
  }

  @override
  String get moneyConflictBody => 'Đã hiện bản mới nhất, sửa lại nếu cần';

  @override
  String get moneyWriteFailed => 'Chưa lưu được khoản này. Thử lại nhé.';

  @override
  String get moneyDeleteTx => 'Xoá khoản';

  @override
  String moneyDeleted(String note, String amount) {
    return 'Đã xoá $note · $amount';
  }

  @override
  String get moneyUndo => 'Hoàn tác';

  @override
  String get moneyLinkedAskTitle => 'Sửa luôn bên sổ của mình?';

  @override
  String moneyLinkedAskBody(
    String note,
    String old,
    String wallet,
    String amount,
  ) {
    return 'Khoản “$note” cũng đang trừ $old ở $wallet. Đổi thành $amount ở cả hai sổ?';
  }

  @override
  String get moneyLinkedBoth => 'Sửa cả hai';

  @override
  String get moneyLinkedSharedOnly => 'Chỉ sổ chung';

  @override
  String moneyLinkedChanged(String name, String amount) {
    return '$name đã đổi khoản chung thành $amount';
  }

  @override
  String get moneyLinkedUpdate => 'Cập nhật';

  @override
  String moneyLinkedLocked(String name) {
    return 'Chỉ $name sửa được số tiền, vì khoản này nằm trong sổ riêng của $name';
  }

  @override
  String get moneyDeleteBothTitle => 'Xoá ở cả hai sổ?';

  @override
  String moneyDeleteBothBody(String note, String amount, String wallet) {
    return '“$note” $amount có ở sổ chung và đang trừ $wallet của mình. Xoá cả hai thì $wallet được cộng lại $amount.';
  }

  @override
  String get moneyDeleteBoth => 'Xoá cả hai';

  @override
  String get moneyDeleteSharedOnly => 'Chỉ xoá ở sổ chung';

  @override
  String get moneyCancel => 'Huỷ';

  @override
  String get moneyDiscardTitle => 'Bỏ khoản đang ghi?';

  @override
  String moneyDiscardBody(String amount, String category) {
    return 'Khoản $amount · $category chưa lưu.';
  }

  @override
  String get moneyKeepEditing => 'Tiếp tục ghi';

  @override
  String get moneyDiscard => 'Bỏ khoản này';

  @override
  String get moneyPickCategory => 'Chọn danh mục';

  @override
  String get moneyEditCategoriesShort => 'Sửa';

  @override
  String get moneyCategorySearchHint => 'Tìm danh mục, vd “trà sữa”';

  @override
  String get moneyCategoryNoMatch => 'Không có danh mục nào khớp.';

  @override
  String get moneyKeyDelete => 'Xoá một ký tự';

  @override
  String get moneyKeyBillion => 'tỷ';

  @override
  String moneyAmountTooBigFor(String max) {
    return 'Tối đa $max một khoản.';
  }

  @override
  String moneyWalletTooBigFor(String max) {
    return 'Tối đa $max một ví.';
  }

  @override
  String get moneyAddSource => 'Thêm nguồn';

  @override
  String get moneyCurrencyTitle => 'Tiền tệ';

  @override
  String get moneyTypeSave => 'Góp quỹ';

  @override
  String moneySavedContribution(String amount, String fund) {
    return 'Đã góp $amount vào $fund';
  }

  @override
  String get moneySaveInto => 'Góp vào';

  @override
  String get moneyPaidFrom => 'Tiền từ đâu';

  @override
  String get moneyMyMoney => 'Tiền riêng';

  @override
  String get moneyGoalsTitle => 'Mục tiêu tiết kiệm';

  @override
  String get moneyChTplNoCoffee7 => '7 ngày không trà sữa, cà phê';

  @override
  String get moneyChTplNoSnack7 => '7 ngày không ăn vặt';

  @override
  String get moneyChTplNoGrab7 => '7 ngày không gọi xe';

  @override
  String get moneyChTplNoShop7 => '7 ngày không mua sắm';

  @override
  String get moneyChTplNoClothes14 => '14 ngày không mua quần áo';

  @override
  String get moneyChTplCookHome14 => '14 ngày nấu ăn ở nhà';

  @override
  String get moneyChTplNoTech30 => '30 ngày không mua đồ công nghệ';

  @override
  String moneyChTplEatOutCap7(String amount) {
    return 'Tuần này ăn ngoài dưới $amount';
  }

  @override
  String moneyChTplDateCap7(String amount) {
    return 'Tuần này hẹn hò dưới $amount';
  }

  @override
  String moneyChTplAllCap7(String amount) {
    return 'Tuần này chi dưới $amount';
  }

  @override
  String get moneyChallengesTitle => 'Thử thách tiết kiệm';

  @override
  String get moneyChallengeNew => 'Thử thách mới';

  @override
  String get moneyChallengeCustom => 'Tự tạo';

  @override
  String moneyChallengeDaysLeft(String n) {
    return 'Còn $n ngày';
  }

  @override
  String moneyChallengeCleanDays(String done, String total) {
    return '$done/$total ngày';
  }

  @override
  String moneyChallengeSpentOf(String spent, String limit) {
    return '$spent / $limit';
  }

  @override
  String get moneyChallengeWon => 'Hoàn thành';

  @override
  String get moneyChallengeLost => 'Thử lại lần sau';

  @override
  String get moneyChallengeStop => 'Dừng thử thách';

  @override
  String get moneyChallengeStart => 'Bắt đầu';

  @override
  String get moneyChallengeKindNoSpend => 'Không chi';

  @override
  String get moneyChallengeKindCap => 'Chi dưới mức';

  @override
  String get moneyChallengeLimit => 'Mức tối đa';

  @override
  String get moneyChallengeAll => 'Mọi khoản chi';

  @override
  String moneyChallengeDays(String n) {
    return '$n ngày';
  }

  @override
  String get moneyChallengeMax => 'Đang chạy đủ 3 thử thách';

  @override
  String get moneyChallengeLastDayTitle => 'Hôm nay là ngày cuối thử thách';

  @override
  String moneyChallengeStarted(String title) {
    return 'Bắt đầu: $title';
  }

  @override
  String moneyRecapTitle(String month) {
    return 'Nhìn lại $month';
  }

  @override
  String get moneyRecapKeptBudget => 'Giữ được hạn mức tháng';

  @override
  String moneyRecapSpentLess(String amount, String month) {
    return 'Chi ít hơn $month $amount';
  }

  @override
  String moneyRecapSaved(String amount) {
    return 'Góp quỹ thêm $amount';
  }

  @override
  String moneyRecapChallenges(String n) {
    return 'Xong $n thử thách';
  }

  @override
  String moneyRecapLogged(String n, String total) {
    return 'Ghi chi tiêu $n/$total ngày';
  }

  @override
  String get moneyRecapEmpty => 'Tháng mới bắt đầu. Đặt hạn mức cho tháng này?';

  @override
  String get moneyChallengeLength => 'Thời gian';

  @override
  String get moneyKeyThousand => 'nghìn';

  @override
  String get moneyKeyMillion => 'triệu';

  @override
  String get moneyKeyCu => 'củ';

  @override
  String get moneyShowKeypad => 'Mở bàn phím số';

  @override
  String get moneyFirstRunTitle => 'Tiền của mình đang nằm ở đâu?';

  @override
  String get moneyFirstRunBody =>
      'Bật những ví đang dùng, nhập số dư lúc này. Bỏ qua cũng được: đã có sẵn ví Tiền mặt.';

  @override
  String get moneyFirstRunDone => 'Xong, vào sổ';

  @override
  String get moneySkip => 'Bỏ qua';

  @override
  String get moneyBuiltIn => 'Có sẵn';

  @override
  String get moneyWalletBank => 'Ngân hàng';

  @override
  String get moneyWalletEwallet => 'Ví điện tử';

  @override
  String get moneyWalletCredit => 'Thẻ tín dụng';

  @override
  String get moneyWalletGoal => 'Mục tiêu';

  @override
  String get moneyCreditOwed => 'Đang nợ thẻ bao nhiêu';

  @override
  String moneyBalanceOf(String name) {
    return 'Số dư $name';
  }

  @override
  String get moneyWalletTooBig => 'Tối đa 100 tỷ một ví.';

  @override
  String get moneyWalletsBadge => 'VÍ';

  @override
  String get moneyAddWallet => 'Thêm ví';

  @override
  String moneyAssetsNote(int n) {
    return 'Cộng $n ví đang dùng, đã trừ tiền đang nợ thẻ. Tiền để dành cho mục tiêu tính riêng bên dưới.';
  }

  @override
  String get moneyInUse => 'Đang dùng';

  @override
  String moneyWalletCount(int n) {
    return '$n ví';
  }

  @override
  String get moneyGoals => 'Mục tiêu';

  @override
  String get moneyNotInTotal => 'không tính vào tổng';

  @override
  String moneyGoalPerMonthShort(String amount) {
    return 'Cần ~$amount mỗi tháng';
  }

  @override
  String get moneyArchivedSection => 'Đã lưu trữ';

  @override
  String moneyArchived(String date) {
    return 'Lưu trữ từ $date, giữ nguyên lịch sử';
  }

  @override
  String get moneyArchivedPlain => 'Đã lưu trữ, giữ nguyên lịch sử';

  @override
  String get moneyOwingCard => 'đang nợ thẻ';

  @override
  String get moneyCurrentBalance => 'Số dư hiện tại';

  @override
  String moneyWalletInTotal(String type) {
    return '$type · tính vào tổng tiền đang có';
  }

  @override
  String moneyWalletNotInTotal(String type) {
    return '$type · không tính vào tổng';
  }

  @override
  String moneyInMonth(String month) {
    return 'Vào tháng $month';
  }

  @override
  String moneyOutMonth(String month) {
    return 'Ra tháng $month';
  }

  @override
  String get moneyFixBalance => 'Sửa số dư';

  @override
  String moneyEntryCount(int n) {
    return '$n khoản';
  }

  @override
  String get moneyEditWallet => 'Sửa ví';

  @override
  String get moneyWalletNoEntries => 'Tháng này ví chưa có khoản nào.';

  @override
  String get moneyNewWallet => 'Ví mới';

  @override
  String get moneyNewGoal => 'Mục tiêu mới';

  @override
  String get moneyName => 'Tên';

  @override
  String get moneyPickEmoji => 'Chọn biểu tượng';

  @override
  String get moneyBalanceNow => 'Số dư lúc này';

  @override
  String get moneyIncludeInTotal => 'Tính vào tổng tiền đang có';

  @override
  String get moneyCreateWallet => 'Tạo ví';

  @override
  String get moneyCreateGoal => 'Tạo mục tiêu';

  @override
  String get moneyGoalTarget => 'Cần bao nhiêu';

  @override
  String get moneyGoalDeadline => 'Hạn (không bắt buộc)';

  @override
  String moneyGoalPerMonth(String amount, int n) {
    return 'Cần để dành ~$amount mỗi tháng trong $n tháng tới.';
  }

  @override
  String get moneyNotSet => 'Chưa chọn';

  @override
  String get moneySave => 'Lưu';

  @override
  String get moneyArchiveWallet => 'Lưu trữ ví';

  @override
  String get moneyArchiveAskTitle => 'Lưu trữ ví này?';

  @override
  String get moneyArchiveAskBody =>
      'Ví thôi hiện khi ghi khoản, lịch sử giữ nguyên. Muốn dùng lại lúc nào cũng được.';

  @override
  String get moneyUnarchiveWallet => 'Dùng lại ví này';

  @override
  String get moneyNameNeeded => 'Đặt tên để lưu';

  @override
  String get moneyFixTitle => 'Sửa số dư cho khớp';

  @override
  String moneyFixInBook(String wallet, String amount) {
    return '$wallet · trong sổ đang là $amount';
  }

  @override
  String get moneyAdjustReal => 'Số tiền thật đang có';

  @override
  String moneyFixMore(String amount) {
    return 'Trong app đang nhiều hơn tiền thật $amount. App ghi 1 dòng “sửa số dư” để khớp, dòng này không tính là chi tiêu.';
  }

  @override
  String moneyFixLess(String amount) {
    return 'Trong app đang ít hơn tiền thật $amount. App ghi 1 dòng “sửa số dư” để khớp, dòng này không tính là thu nhập.';
  }

  @override
  String get moneyFixSame => 'Đã khớp với tiền thật, không cần sửa.';

  @override
  String get moneyAdjustSave => 'Cập nhật số dư';

  @override
  String moneyFixedToast(String wallet) {
    return 'Đã sửa số dư $wallet';
  }

  @override
  String moneyWalletCreated(String name) {
    return 'Đã tạo $name';
  }

  @override
  String get moneyCategoriesBadge => 'DANH MỤC';

  @override
  String get moneyCategoryScope => 'Sổ của mình · mỗi sổ có bộ danh mục riêng';

  @override
  String get moneyCategoryScopeShared =>
      'Sổ chung · mỗi sổ có bộ danh mục riêng';

  @override
  String moneySubCount(int n) {
    return '$n mục con';
  }

  @override
  String get moneyAddSub => 'Thêm mục con';

  @override
  String moneyRenamedFrom(String name) {
    return 'Đã đổi tên, gốc là “$name”';
  }

  @override
  String get moneyCustom => 'Tự thêm';

  @override
  String get moneyHidden => 'Đã ẩn';

  @override
  String get moneyHiddenNote => 'không hiện khi ghi khoản';

  @override
  String get moneyHiddenSub => 'Khoản cũ vẫn giữ tên';

  @override
  String get moneyShowAgain => 'Hiện lại';

  @override
  String get moneyHideCategory => 'Ẩn danh mục này';

  @override
  String get moneyEditCategory => 'Sửa danh mục';

  @override
  String get moneyNewCategory => 'Nhóm mới';

  @override
  String get moneyNewSub => 'Mục con mới';

  @override
  String moneyOriginalName(String name) {
    return 'Tên gốc: $name. Đổi tên chỉ áp cho sổ này.';
  }

  @override
  String get moneyInGroup => 'Nằm trong';

  @override
  String get moneyDeleteCategory => 'Xoá danh mục';

  @override
  String moneyDeleteCategoryAsk(String name) {
    return 'Xoá “$name”?';
  }

  @override
  String get moneyDeleteCategoryBody =>
      'Khoản cũ của danh mục này chuyển về “Khác”.';

  @override
  String get moneyDelete => 'Xoá';

  @override
  String get moneyAddCategory => 'Thêm danh mục';

  @override
  String get moneyCategoryLimit => 'Sổ này đã đủ 80 danh mục tự thêm.';

  @override
  String get moneyNotSpending => 'không tính là chi';

  @override
  String get moneyBudgets => 'Ngân sách';

  @override
  String get moneyBudgetsBadge => 'NGÂN SÁCH';

  @override
  String get moneyReport => 'Báo cáo';

  @override
  String get moneyReportBadge => 'BÁO CÁO';

  @override
  String get moneySearchBadge => 'TÌM KHOẢN';

  @override
  String get moneySearchLabel => 'Tìm khoản';

  @override
  String get moneySeeAll => 'Tất cả';

  @override
  String get moneyBudgetSetLink => 'Đặt';

  @override
  String get moneyAddBudget => 'Đặt ngân sách';

  @override
  String moneyBudgetScopeShared(String month) {
    return 'Tháng $month · cả sổ chung';
  }

  @override
  String moneyBudgetScopeMine(String month) {
    return 'Tháng $month · cả sổ của mình';
  }

  @override
  String moneyBudgetDaysLeft(String n) {
    return 'còn $n ngày';
  }

  @override
  String moneyBudgetDailyLeft(String left, String perDay) {
    return 'Còn $left, tức khoảng $perDay mỗi ngày tới hết tháng.';
  }

  @override
  String moneyBudgetUsedOf(String budget) {
    return 'của $budget';
  }

  @override
  String get moneyBudgetByCategory => 'Theo danh mục';

  @override
  String moneyBudgetOverOf(String amount, String budget) {
    return 'Vượt $amount của $budget';
  }

  @override
  String moneyBudgetLeftOf(String amount, String budget) {
    return 'Còn $amount của $budget';
  }

  @override
  String get moneyBudgetNoCategory =>
      'Chưa nhóm nào có ngân sách riêng. Đặt cho nhóm hay tiêu nhiều, app sẽ báo khi dùng tới 80% và 100%.';

  @override
  String get moneyBudgetUnset =>
      'Chưa đặt ngân sách. Đặt một con số cho cả tháng, app sẽ báo khi dùng tới 80% và 100%.';

  @override
  String get moneySetBudget => 'Đặt ngân sách tháng';

  @override
  String get moneyBudgetPushNote =>
      'Khi chi tới 80% và 100% ngân sách tổng, người không ghi khoản đó sẽ nhận thông báo. Thông báo chỉ có phần trăm, không có số tiền.';

  @override
  String get moneyBudgetSheetTitle => 'Ngân sách tháng';

  @override
  String get moneyBudgetWholeBook => 'Cả sổ';

  @override
  String get moneyBudgetAmountLabel => 'Mỗi tháng tối đa';

  @override
  String get moneyBudgetResets => 'Đầu tháng nào cũng tính lại từ 0.';

  @override
  String get moneyBudgetSave => 'Lưu ngân sách';

  @override
  String get moneyBudgetRemove => 'Bỏ ngân sách này';

  @override
  String moneyBudgetSaved(String name, String amount) {
    return 'Đã đặt ngân sách $name: $amount';
  }

  @override
  String moneyBudgetRemoved(String name) {
    return 'Đã bỏ ngân sách $name';
  }

  @override
  String moneyReportUpTo(String date) {
    return 'tới $date';
  }

  @override
  String moneyReportTopCategory(String category, String percent) {
    return 'Chi nhiều nhất là $category, chiếm $percent% cả tháng.';
  }

  @override
  String moneyReportTopShared(String category, String percent) {
    return '$category chiếm $percent% chi chung.';
  }

  @override
  String moneyReportTopChild(String sub, String amount) {
    return 'Phần lớn là $sub, $amount.';
  }

  @override
  String get moneyReportByCategory => 'Chi theo danh mục';

  @override
  String get moneyReportTapHint => 'chạm để xem mục con';

  @override
  String get moneyReportByMonth => 'Chi mỗi tháng';

  @override
  String get moneyReport6 => '6 tháng';

  @override
  String get moneyReport12 => '12 tháng';

  @override
  String moneyReportBudgetLine(String amount) {
    return 'Ngân sách $amount';
  }

  @override
  String moneyReportPartial(String month, String date) {
    return 'Tháng $month mới tính tới $date. Đường đứt là ngân sách tổng hiện tại.';
  }

  @override
  String moneyReportPartialNoBudget(String month, String date) {
    return 'Tháng $month mới tính tới $date.';
  }

  @override
  String moneyReportNewBook(String month) {
    return 'Sổ chung mới có từ tháng $month, nên các tháng trước để trống.';
  }

  @override
  String moneyReportNewBookMine(String month) {
    return 'Sổ của mình mới có từ tháng $month, nên các tháng trước để trống.';
  }

  @override
  String get moneyReportMissing =>
      'Chưa tải được vài tháng nên các cột đó để trống. Có mạng sẽ hiện lại.';

  @override
  String get moneyReportTet => 'Tết';

  @override
  String moneyReportChartLabel(String n, String values) {
    return 'Chi mỗi tháng, $n tháng gần đây: $values';
  }

  @override
  String get moneyReportByWallet => 'Chi theo ví';

  @override
  String moneyReportNoSpend(String month) {
    return 'Tháng $month chưa có khoản chi nào.';
  }

  @override
  String get moneySearchHint => 'Tìm trong ghi chú và danh mục';

  @override
  String get moneySearchClear => 'Xoá chữ';

  @override
  String get moneySearchAccent =>
      'Gõ không dấu vẫn ra, vd “bun cha” ra “Bún chả”.';

  @override
  String moneySearchCount(String n) {
    return '$n khoản';
  }

  @override
  String moneySearchRange(String n) {
    return '$n tháng gần đây';
  }

  @override
  String moneySearchEmpty(String q, String n) {
    return 'Không có khoản nào khớp “$q” trong $n tháng gần đây.';
  }

  @override
  String moneySearchEmptyAll(String n) {
    return 'Không có khoản nào trong $n tháng gần đây với bộ lọc này.';
  }

  @override
  String get moneySearch12 => 'Tìm trong 12 tháng';

  @override
  String get moneySearchCap =>
      'Chỉ tìm trong 2.000 khoản gần nhất. Chọn khoảng ngày hẹp hơn để không sót khoản nào.';

  @override
  String get moneySearchError => 'Chưa tìm được. Kiểm tra mạng rồi thử lại.';

  @override
  String get moneySearchAmount => 'Khoảng tiền';

  @override
  String get moneySearchPerson => 'Người';

  @override
  String get moneySearchFrom => 'Từ';

  @override
  String get moneySearchTo => 'Đến';

  @override
  String moneySearchFromOnly(String amount) {
    return 'Từ $amount';
  }

  @override
  String moneySearchToOnly(String amount) {
    return 'Tới $amount';
  }

  @override
  String get moneySearchApply => 'Áp dụng';

  @override
  String get moneySearchClearFilter => 'Bỏ lọc';

  @override
  String moneySearchPickedCount(String label, String n) {
    return '$label · $n';
  }

  @override
  String get moneySearchPeriod => 'Khoảng ngày';

  @override
  String get moneyGoalSaved => 'Chúng mình đã góp';

  @override
  String get moneyGoalSavedMine => 'Đã để dành';

  @override
  String moneyGoalTargetOf(String amount) {
    return 'Mục tiêu $amount';
  }

  @override
  String moneyGoalLeft(String left, String date, String perMonth) {
    return 'Còn $left. Để kịp $date, mỗi tháng chúng mình cần để dành khoảng $perMonth.';
  }

  @override
  String moneyGoalLeftMine(String left, String date, String perMonth) {
    return 'Còn $left. Để kịp $date, mỗi tháng mình cần để dành khoảng $perMonth.';
  }

  @override
  String moneyGoalLeftOnly(String left) {
    return 'Còn $left.';
  }

  @override
  String get moneyGoalNoDeadline =>
      'Chưa đặt hạn. Thêm hạn để biết mỗi tháng cần để dành bao nhiêu.';

  @override
  String moneyGoalReachedOn(String date) {
    return 'Đủ ngày $date';
  }

  @override
  String moneyGoalReached(String trip) {
    return 'Đủ rồi! Lên lịch đi $trip thôi. Tiêu gì trong chuyến đi thì ghi thẳng từ quỹ này.';
  }

  @override
  String get moneyGoalHistory => 'Lịch sử góp';

  @override
  String moneyGoalTimes(int count) {
    return '$count lần';
  }

  @override
  String get moneyGoalHistoryEmpty =>
      'Chưa có lần góp nào. Góp lần đầu đi, 50k cũng được.';

  @override
  String get moneyGoalHistoryPartial =>
      'Chưa tải được lịch sử cũ, đang hiện các lần góp gần đây.';

  @override
  String get moneyContribute => 'Góp vào quỹ';

  @override
  String get moneySpendFromFund => 'Chi từ quỹ';

  @override
  String moneyContributeTitle(String wallet) {
    return 'Góp vào $wallet';
  }

  @override
  String get moneyContributeFrom => 'Lấy từ ví';

  @override
  String moneyContributeSave(String amount) {
    return 'Góp $amount';
  }

  @override
  String moneyContributed(String amount, String wallet) {
    return 'Đã góp $amount vào $wallet';
  }

  @override
  String moneyContributedFull(String wallet) {
    return '$wallet đủ rồi';
  }

  @override
  String get moneyContributeHint => 'Số tiền góp';

  @override
  String get moneyLogFromDecision => 'Ghi chi';

  @override
  String get moneyReminderBody1 => 'Hôm nay có khoản nào chưa ghi không?';

  @override
  String get moneyReminderBody2 =>
      'Ghi nốt chi tiêu hôm nay, mất chưa tới một phút';

  @override
  String get moneyReminderBody3 =>
      'Tối rồi, xem hôm nay mình tiêu bao nhiêu nhé';

  @override
  String get moneyReminderSettingTitle => 'Nhắc ghi chi tiêu buổi tối';

  @override
  String get moneyReminderSettingSubtitle =>
      'Mỗi tối một lần. Hôm nào đã ghi khoản thì thôi không nhắc.';

  @override
  String get moneyMenuReminder => 'Nhắc tối';

  @override
  String get moneyProfileSub => 'Ví, chi tiêu và quỹ chung';

  @override
  String moneyNotifGoal(String name, String percent) {
    return '$name vừa góp vào quỹ, giờ được $percent%';
  }

  @override
  String moneyNotifGoalReached(String wallet) {
    return '$wallet đủ rồi!';
  }

  @override
  String get moneyNotifGoalReachedSub =>
      'Chúng mình góp đủ mục tiêu rồi. Lên lịch đi thôi.';

  @override
  String get moneyNotifBudget80 => 'Tháng này chúng mình đã tiêu 80% ngân sách';

  @override
  String get moneyNotifBudget100 =>
      'Tháng này chúng mình tiêu hết ngân sách rồi';

  @override
  String moneyNotifBudgetSub(String month) {
    return 'Sổ chung · $month';
  }

  @override
  String get moneyLinkedPayerLocked =>
      'Khoản này đã trừ vào ví của mình nên không đổi người trả được. Muốn đổi thì xoá rồi ghi lại nhé.';
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get badgeCareLabel => 'care notes';

  @override
  String get careTimelineBadge => 'CARE NOTES';

  @override
  String get careTimelineSeeAll => 'See all';

  @override
  String get careTimelineYesterday => 'Yesterday';

  @override
  String get careTimelineEmptyTitle => 'No care notes yet';

  @override
  String get careTimelineEmptyBody =>
      'Every little note the two of you send lands here, in order.';

  @override
  String get careTimelineEmptyCta => 'Send the first care note';

  @override
  String get careTimelineLoadError => 'Couldn\'t load the timeline.';

  @override
  String get aiQuestionsTitle => 'AI-personalised questions';

  @override
  String get aiQuestionsSubtitle =>
      'Uses the last 30 days of both your answers to write a question just for the two of you. The data is only used to create questions, never for training. Turn it off any time.';

  @override
  String get aiQuestionsDialogTitle => 'Turn on personalised questions?';

  @override
  String get aiQuestionsDialogBody =>
      'This applies to both of you: your partner will see the AI-written question too. We only read the last 30 days of answers to create it — nothing is used for training, and you can turn it off any time. AI questions start from tomorrow\'s question.';

  @override
  String get aiQuestionsDialogConfirm => 'Turn on';

  @override
  String get introSkip => 'Skip';

  @override
  String get introNext => 'Next';

  @override
  String get introStart => 'Get started';

  @override
  String get introSlide1Badge => 'LOVE COUNTER';

  @override
  String get introSlide1Title => 'Count every day together';

  @override
  String get introSlide1Body =>
      'See how long you have been together, reach every milestone, and watch your love tree grow day by day.';

  @override
  String get introSlide2Badge => 'EVERY DAY';

  @override
  String get introSlide2Title => 'Memories & a question a day';

  @override
  String get introSlide2Body =>
      'A shared photo library, a daily question for both of you, your connection streak, and a chat corner just for the two of you.';

  @override
  String get introSlide3Badge => 'IT TAKES TWO';

  @override
  String get introSlide3Title => 'It takes both of you';

  @override
  String get introSlide3Body =>
      'Dear Embeiu is a space for two. You create an invite code, your partner downloads the app (iOS/Android) and enters the code — that\'s it.';

  @override
  String get featureTourBadge => 'WHAT\'S NEW';

  @override
  String featureTourVersionTitle(String version) {
    return 'Version $version';
  }

  @override
  String get featureTourGotIt => 'Got it';

  @override
  String get featureTourSettingsTile => 'What\'s new';

  @override
  String get featureTourSettingsTileSub =>
      'Take another look at the latest features';

  @override
  String get featureTourCareTitle => 'Send a little care';

  @override
  String get featureTourCareBody =>
      'Write a short message and your partner gets a notification right away.';

  @override
  String get featureTourQuestionsTitle => 'Fresher daily questions';

  @override
  String get featureTourQuestionsBody =>
      'Questions that follow the week, the month and your mood, a way to look back at old answers, and an optional AI personalisation you can turn on in Settings.';

  @override
  String get featureTourInviteTitle => 'Easier to invite your partner';

  @override
  String get featureTourInviteBody =>
      'Share a download link together with your invite code, with step-by-step guidance.';

  @override
  String get homeWaitingBadge => 'WAITING FOR THEM';

  @override
  String get homeWaitingStep1Title => 'Send the invite';

  @override
  String get homeWaitingStep1Desc =>
      'Send this invite code to your partner in a message.';

  @override
  String get homeWaitingStep1Cta => 'Send it to them 💌';

  @override
  String get homeWaitingStep1Copy => 'Copy code';

  @override
  String get homeWaitingStep2Title => 'They install the app and sign up';

  @override
  String get homeWaitingStep2Desc =>
      'They need to install Dear Embeiu (iOS/Android), sign up, then pick <Join with code>.';

  @override
  String get homeWaitingStep3Title => 'Entering the code is all it takes';

  @override
  String get homeWaitingStep3Desc =>
      'Once you are paired the app switches over by itself and you get a notification.';

  @override
  String get homeWaitingMeanwhileTitle => 'While you wait, you can already:';

  @override
  String get homeWaitingMeanwhileItem1 => 'Set your anniversary date';

  @override
  String get homeWaitingMeanwhileItem2 => 'Add memories';

  @override
  String get homeWaitingMeanwhileItem3 => 'Answer today\'s question';

  @override
  String get homeWaitingMeanwhileFooter =>
      'They will see all of it when they join.';

  @override
  String get inviteFollowUpTitle => 'Your partner hasn\'t joined yet 💌';

  @override
  String get inviteFollowUpBody24h =>
      'Send the invite again — it only takes 10 seconds';

  @override
  String get inviteFollowUpBody72h =>
      'Our memories are waiting for them. Remind them to download the app';

  @override
  String get back => 'Back';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get continueBtn => 'Continue';

  @override
  String get splashTagline => 'Our story';

  @override
  String get splashSubtitle => 'Counting every day of us';

  @override
  String get checkingSession => 'Checking your session...';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailHint => 'you@example.com';

  @override
  String get emailRequired => 'Please enter your email';

  @override
  String get emailInvalid => 'That doesn\'t look like an email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordHint => 'At least 6 characters';

  @override
  String get passwordRequired => 'Please enter your password';

  @override
  String get passwordTooShort => 'Password needs at least 6 characters';

  @override
  String get signIn => 'Sign in';

  @override
  String get newHere => 'New here?';

  @override
  String get createAccountLink => 'Create an account';

  @override
  String get displayNameLabel => 'Display name';

  @override
  String get displayNameHint => 'How you\'ll appear';

  @override
  String get displayNameRequired => 'Please enter a display name';

  @override
  String get displayNameTooShort => 'Name is too short';

  @override
  String get confirmPasswordLabel => 'Confirm password';

  @override
  String get confirmPasswordHint => 'Repeat the password';

  @override
  String get confirmPasswordRequired => 'Please confirm the password';

  @override
  String get passwordsMismatch => 'Passwords don\'t match yet';

  @override
  String get createAccountBtn => 'Create account';

  @override
  String get alreadyWithUs => 'Already with us?';

  @override
  String get backToSignIn => 'Back to sign in';

  @override
  String get setupCreateTitle => 'Begin\nour story';

  @override
  String setupEditTitle(String me, String partner) {
    return 'Refine the story of\n$me ❤️ $partner';
  }

  @override
  String get setupEditTitleGeneric => 'Refine\nyour story';

  @override
  String get setupTabCreate => 'Create';

  @override
  String get setupTabJoin => 'Join with code';

  @override
  String get inviteCodeDialogTitle => 'Your invite code';

  @override
  String get inviteCodeDialogContent =>
      'This code is tied to your account. Send it to your partner so they can sign in with their own account and enter it on the join screen.';

  @override
  String get sectionAboutCouple => 'About your couple';

  @override
  String get setupEditSectionDesc =>
      'Edit shared info — names, anniversary, couple photo.';

  @override
  String get setupCreateSectionDesc =>
      'Create the space first, then share your invite code with your partner.';

  @override
  String get yourNameLabel => 'Your name';

  @override
  String get yourNameHint => 'e.g. Anh';

  @override
  String get partnerNameLabel => 'Partner\'s name';

  @override
  String get partnerNameHint => 'e.g. Em';

  @override
  String get anniversaryLabel => 'Anniversary date';

  @override
  String get anniversaryHint => 'Pick the day you started';

  @override
  String get couplePhotoLabel => 'Couple photo';

  @override
  String get couplePhotoHint => 'Add a couple photo (optional)';

  @override
  String get couplePhotoSelected => 'Photo selected';

  @override
  String get saveChangesBtn => 'Save changes';

  @override
  String get createOurSpaceBtn => 'Create our space';

  @override
  String get useInviteCodeTitle => 'Use an invite code';

  @override
  String get theirInviteCodeLabel => 'Their invite code';

  @override
  String get theirInviteCodeHint => 'e.g. A7B9KD';

  @override
  String get joinBtn => 'Join their space';

  @override
  String get yourInviteCodeTitle => 'Your invite code';

  @override
  String get inviteCodeTiedToAccount => 'Code tied to your account';

  @override
  String get setupErrorNoAccount => 'No account found. Please sign in again.';

  @override
  String get setupErrorFillRequired =>
      'Please fill in both names and the anniversary date.';

  @override
  String get setupErrorSaveCouple =>
      'Couldn\'t save your couple info. Please try again.';

  @override
  String get setupErrorNoAccountShort => 'No account found.';

  @override
  String get setupErrorNoInviteCode => 'Please enter the invite code first.';

  @override
  String get setupErrorJoinCouple => 'Couldn\'t pair up. Please try again.';

  @override
  String get setupSuccessConnected => 'Connected successfully 💞';

  @override
  String get navHome => 'Home';

  @override
  String get navChat => 'Chat';

  @override
  String get navMemories => 'Memories';

  @override
  String get navProfile => 'Profile';

  @override
  String get chatBadge => 'JUST THE TWO OF US';

  @override
  String get chatEmptyHint =>
      'No messages yet — send your love the first one 💬';

  @override
  String get chatComposerHint => 'Message your love…';

  @override
  String get chatSendFailed => 'Couldn\'t send your message. Please try again.';

  @override
  String get chatSendSemantics => 'Send message';

  @override
  String get chatSending => 'Sending…';

  @override
  String get chatStatusSent => 'Sent';

  @override
  String get chatStatusDelivered => 'Delivered';

  @override
  String get chatStatusRead => 'Seen';

  @override
  String get lunarSectionTitle => 'Lunar calendar';

  @override
  String lunarDateLabel(int month, int day) {
    return 'Lunar $month/$day';
  }

  @override
  String get lunarTodayLabel => 'Today';

  @override
  String get lunarNextNewMoon => 'Next 1st';

  @override
  String get lunarNextFullMoon => 'Next full moon';

  @override
  String get lunarReminderToggle => 'Lunar-day reminder';

  @override
  String get lunarReminderToggleSub => 'On your chosen days & times';

  @override
  String get lunarNewMoonNotifTitle => 'First day of the lunar month 🌙';

  @override
  String get lunarNewMoonNotifBody =>
      'Today is the first day of the lunar month.';

  @override
  String get lunarFullMoonNotifTitle => 'Full moon day 🌕';

  @override
  String get lunarFullMoonNotifBody =>
      'Today is the full moon (15th lunar day).';

  @override
  String lunarOtherDayNotifTitle(int day) {
    return 'Lunar day $day 🌙';
  }

  @override
  String lunarOtherDayNotifBody(int day) {
    return 'Today is lunar day $day.';
  }

  @override
  String get lunarCalendarBadge => 'LUNAR CALENDAR';

  @override
  String get lunarOpenCalendar => 'Open lunar calendar';

  @override
  String get lunarRemindDaysLabel => 'Reminder days (lunar)';

  @override
  String get lunarRemindTimesLabel => 'Reminder times';

  @override
  String get lunarAddTime => 'Add time';

  @override
  String get chatUnreadDotSemantics => 'New message waiting';

  @override
  String get chatWaitingPartnerTitle => 'One seat is still empty';

  @override
  String get chatWaitingPartnerBody =>
      'Invite your partner to pair up and start your private chat.';

  @override
  String get chatWaitingPartnerCta => 'Invite to pair';

  @override
  String get ourStoryBadge => 'OUR STORY';

  @override
  String get homeGreetingMorning => 'Good morning,';

  @override
  String get homeGreetingAfternoon => 'Good afternoon,';

  @override
  String get homeGreetingEvening => 'Good evening,';

  @override
  String get homeGreetingNight => 'Up late,';

  @override
  String get homeTodaySectionTitle => 'Today, together';

  @override
  String get dailyTapToAnswer => 'Tap to answer…';

  @override
  String dailyPartnerAnsweredTeaser(String name) {
    return '$name has answered 👀';
  }

  @override
  String get dailyAnswerToReveal => 'Answer to unlock their reply';

  @override
  String get dailyBothAnsweredToday => 'You both answered today';

  @override
  String get dailyReadAgain => 'Read again';

  @override
  String get dailyCollapse => 'Collapse';

  @override
  String milestoneNextLabel(String label) {
    return 'Milestone: $label';
  }

  @override
  String milestoneDaysLeft(int count) {
    return '$count days left';
  }

  @override
  String get milestoneTodayLabel => 'today 🎉';

  @override
  String onThisDayShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count years ago 💞',
      one: '1 year ago 💞',
    );
    return '$_temp0';
  }

  @override
  String get counterBgSwipeHint => 'Swipe to change the photo';

  @override
  String get dailyQuestionPairedFirst =>
      'Once you\'re paired, you\'ll answer a question like this together every day 💞';

  @override
  String notificationBellLabel(int count) {
    return 'Notifications, $count unread';
  }

  @override
  String get youveBeenTogetherFor => 'YOU\'VE BEEN TOGETHER FOR';

  @override
  String daysOfUsSince(String date) {
    return 'days of us · since $date';
  }

  @override
  String get todayIsAnniversary => 'Today is your anniversary ✨';

  @override
  String daysUntilNextAnniversary(int count) {
    return '$count days until your next anniversary';
  }

  @override
  String get addMemoryCta => 'Add a memory';

  @override
  String get daysTogether => 'Days together';

  @override
  String get daysUnit => 'Days';

  @override
  String get hoursShort => 'hr';

  @override
  String get minutesShort => 'min';

  @override
  String get secondsShort => 'sec';

  @override
  String get recentMemoriesTitle => 'Recent memories';

  @override
  String get addPhotosPrompt => 'Add a few photos to start your love letter';

  @override
  String get seeAll => 'See all';

  @override
  String get addPhotosEmpty =>
      'Add a few photos to start filling this love letter.';

  @override
  String get loveNoteJustNow => 'just now';

  @override
  String loveNoteMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String loveNoteHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String loveNoteDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get reactionHint => 'React to this moment';

  @override
  String get reactionYouLabel => 'You';

  @override
  String get reactionAddTooltip => 'React';

  @override
  String get reactionRemoveTooltip => 'Remove reaction';

  @override
  String get reactionErrorRetry => 'Couldn\'t react, try again';

  @override
  String get dailyQuestionSubmitError =>
      'Couldn\'t send your answer. Please try again.';

  @override
  String get reactionBothShort => 'You both reacted';

  @override
  String reactionWaitingPartner(String name) {
    return 'Waiting for $name to react…';
  }

  @override
  String get reactionWaitingPartnerGeneric =>
      'Waiting for your partner to react…';

  @override
  String get reactionPartnerFallback => 'Your partner';

  @override
  String get moodCardTitle => 'Today\'s mood';

  @override
  String get moodMatched => 'You both feel the same today 💞';

  @override
  String get moodShareCta => 'Share your mood';

  @override
  String get moodUpdateCta => 'Update mood';

  @override
  String get moodNotSharedYou => 'Tap to share';

  @override
  String moodPartnerEmpty(String name) {
    return '$name hasn\'t shared today';
  }

  @override
  String get moodSheetTitle => 'How are you today?';

  @override
  String get moodNoteHint => 'Add a few words (optional)';

  @override
  String get moodSaveCta => 'Save mood';

  @override
  String get moodHappy => 'Happy';

  @override
  String get moodLoved => 'Loved';

  @override
  String get moodMissing => 'Missing you';

  @override
  String get moodCalm => 'Calm';

  @override
  String get moodMeh => 'Meh';

  @override
  String get moodTired => 'Tired';

  @override
  String get moodSad => 'Sad';

  @override
  String get moodStressed => 'Stressed';

  @override
  String get dailyQuestionLabel => 'Today\'s question';

  @override
  String get dailyQuestionHint => 'Write your answer…';

  @override
  String get dailyQuestionSend => 'Send';

  @override
  String get dailyQuestionYourAnswerLabel => 'Your answer';

  @override
  String dailyQuestionAnsweredWaiting(String name) {
    return 'Answered ✓ — waiting for $name';
  }

  @override
  String dailyQuestionPartnerAnswerLabel(String name) {
    return '$name\'s answer';
  }

  @override
  String get dailyQuestionWaitingPartner =>
      'It will unlock once your partner joins and answers too.';

  @override
  String get dailyQuestionSent => 'Your answer was sent 💞';

  @override
  String get journalBadge => 'QUESTION JOURNAL';

  @override
  String get journalYourAnswerLabel => 'YOUR ANSWER';

  @override
  String journalPartnerAnswerLabel(String name) {
    return '$name\'S ANSWER';
  }

  @override
  String get journalLoadMore => 'Show more';

  @override
  String get journalEmptyTitle => 'No question memories yet';

  @override
  String get journalEmptyBody =>
      'When you both answer a daily question, that moment gets saved here.';

  @override
  String get journalEmptyCta => 'Answer today\'s question';

  @override
  String get journalEmptyNoPartnerBody =>
      'Invite your partner to start your journal together.';

  @override
  String get journalEmptyNoPartnerCta => 'Invite partner';

  @override
  String get journalErrorTitle => 'Couldn\'t load the journal';

  @override
  String get journalRetry => 'Try again';

  @override
  String get milestoneReached => 'You just reached a beautiful milestone ✨';

  @override
  String onlyDaysUntilMilestone(int count) {
    return 'Only $count days until your next milestone.';
  }

  @override
  String nextMilestonePrefix(String label) {
    return 'Next: $label';
  }

  @override
  String daysCountLabel(int count) {
    return '$count days';
  }

  @override
  String percentThere(String percent) {
    return '$percent% there';
  }

  @override
  String milestoneYearsOne(int count) {
    return '$count year';
  }

  @override
  String milestoneYearsMany(int count) {
    return '$count years';
  }

  @override
  String milestoneMonthsOne(int count) {
    return '$count month';
  }

  @override
  String milestoneMonthsMany(int count) {
    return '$count months';
  }

  @override
  String milestoneDaysLabel(int count) {
    return '$count days';
  }

  @override
  String get privateGalleryBadge => 'PHOTO LIBRARY';

  @override
  String get addCaptionOptionalTitle => 'Add caption (optional)';

  @override
  String get addCaptionOptionalHint => 'Write something truly memorable...';

  @override
  String get editCaptionTitle => 'Edit caption';

  @override
  String get editCaptionHint => 'How memorable was this moment?';

  @override
  String get deletePhotoTitle => 'Delete this photo?';

  @override
  String get deletePhotoContent =>
      'This moment will be removed from your shared diary.';

  @override
  String get keepPhotoBtn => 'Keep';

  @override
  String get deletePhotoBtn => 'Delete';

  @override
  String postedByLabel(String name) {
    return 'Posted by $name';
  }

  @override
  String momentsCount(int count) {
    return '$count moments';
  }

  @override
  String get privateFeedLabel => 'Private feed for you two';

  @override
  String get postNewPhotoBtn => 'Take photo';

  @override
  String get addMultipleBtn => 'Add photos';

  @override
  String get cameraUnavailable =>
      'Couldn\'t open the camera. Try again, or turn on camera access for the app in your phone\'s Settings.';

  @override
  String get createPostBadge => 'NEW MEMORY';

  @override
  String createPostAuthorMeta(String name, String when) {
    return 'Posted by $name · $when';
  }

  @override
  String get today => 'Today';

  @override
  String get createPostCaptionHint => 'What\'s happening with you two today?…';

  @override
  String get createPostAddMore => 'Add';

  @override
  String get createPostAddFromLibrary => 'Add from library';

  @override
  String createPostPhotoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos',
      one: '$count photo',
    );
    return '$_temp0';
  }

  @override
  String get createPostBtn => 'Post';

  @override
  String get createPostRemovePhoto => 'Remove photo';

  @override
  String get createPostDiscardTitle => 'Discard this memory?';

  @override
  String get createPostDiscardMessage =>
      'The caption you just wrote won\'t be saved.';

  @override
  String get createPostDiscardConfirm => 'Discard';

  @override
  String get createPostDiscardKeep => 'Keep editing';

  @override
  String get addNewMemoryTitle => 'Add a new memory today';

  @override
  String get whatNewToday => 'what\'s new today?';

  @override
  String get composerSubtitle =>
      'Turn the library into a private and memorable love newsfeed.';

  @override
  String compactCaption(int count) {
    return '$count moments · Swipe to expand post frame';
  }

  @override
  String get editCaptionAction => 'Edit caption';

  @override
  String get deletePhotoAction => 'Delete photo';

  @override
  String get reportPhotoAction => 'Report photo';

  @override
  String get reportPhotoTitle => 'Report photo';

  @override
  String get reportPhotoSubtitle => 'Tell us what\'s wrong with this photo.';

  @override
  String get reportReasonInappropriate => 'Inappropriate content';

  @override
  String get reportReasonSpam => 'Spam or scam';

  @override
  String get reportReasonOther => 'Something else';

  @override
  String get reportCancel => 'Cancel';

  @override
  String get reportSentConfirm => 'Report sent, thank you.';

  @override
  String get startNewfeedTitle => 'Start building a memory newsfeed';

  @override
  String get postFirstMomentOf => 'Post the first moment of';

  @override
  String get emptyFeedContent =>
      'Once you add photos, this library will become a private love newsfeed with timelines that are easy to view and feel.';

  @override
  String get postFirstPhotoBtn => 'Post first photo';

  @override
  String get photoAddedSuccess => 'Photo added successfully!';

  @override
  String get photoAddError => 'Could not post photo right now.';

  @override
  String multiplePhotosAdded(int count) {
    return 'Added $count photos!';
  }

  @override
  String get captionUpdatedSuccess => 'Caption updated';

  @override
  String get captionUpdateError => 'Could not update caption.';

  @override
  String get photoDeletedSuccess => 'Photo deleted';

  @override
  String get photoDeleteError => 'Could not delete photo right now.';

  @override
  String get youTwoLabel => 'You two';

  @override
  String get syncingLibrary => 'Syncing library...';

  @override
  String get uploadingPhoto => 'Uploading photo...';

  @override
  String uploadingPhotoProgress(int current, int total) {
    return 'Uploading $current/$total...';
  }

  @override
  String get deletingPhoto => 'Deleting photo...';

  @override
  String get updatingCaption => 'Updating caption...';

  @override
  String get photoOptionsTitle => 'Photo options';

  @override
  String get replacePhotoAction => 'Replace photo';

  @override
  String get galleryReplacePhotoTooltip => 'Replace photo';

  @override
  String get replacingPhoto => 'Updating photo...';

  @override
  String get photoUpdatedSuccess => 'Photo updated';

  @override
  String get photoUpdateError => 'Could not update photo right now.';

  @override
  String get galleryLoadErrorTitle => 'Couldn\'t load photos';

  @override
  String get galleryLoadErrorSubtitle =>
      'Your memories are safe — we just couldn\'t reach them right now.';

  @override
  String get galleryRetryBtn => 'Try again';

  @override
  String multiPhotosResultPartial(int success, int total, int failed) {
    return 'Posted $success/$total, $failed failed';
  }

  @override
  String get feedDateFormat => 'dd MMM • HH:mm';

  @override
  String get fullDateFormat => 'MMM d, y';

  @override
  String momentNumberFallback(int index) {
    return 'Moment #$index';
  }

  @override
  String get loveProfileBadge => 'LOVE PROFILE';

  @override
  String get yearsTogether => 'Years';

  @override
  String get monthsRemaining => 'Months';

  @override
  String get yourInviteCodeLabel => 'Your account invite code';

  @override
  String get editOurStoryBtn => 'Edit our story';

  @override
  String get settingsSectionAccount => 'Account';

  @override
  String get settingsSectionNotifications => 'Notifications';

  @override
  String get settingsSectionGeneral => 'General';

  @override
  String get dataManagementTitle => 'Data management';

  @override
  String get dataManagementDesc =>
      'One person can only clear cache on this device or leave the couple. To delete shared data, both must confirm.';

  @override
  String get clearLocalDataBtn => 'Clear data on this device';

  @override
  String get localFallbackWarning =>
      'App is in local fallback mode so safe individual cache clearing is not yet supported. You can leave the current local couple if you want to reset.';

  @override
  String get leaveCoupleBtn => 'Leave couple';

  @override
  String get clearLocalDialogTitle => 'Clear data on this device';

  @override
  String get clearLocalDialogContent =>
      'This only clears the cache on the current device. Shared data on Firebase is preserved and will reload when needed.';

  @override
  String get clearLocalActionBtn => 'Clear local';

  @override
  String get leaveCoupleDialogTitle => 'Leave couple';

  @override
  String get leaveCoupleDialogContent =>
      'You will leave the current couple space. The other person keeps the shared data. You cannot delete all shared data from one side.';

  @override
  String get leaveCoupleActionBtn => 'Leave couple';

  @override
  String get leaveCoupleDeleteAllTitle =>
      'Permanently delete your shared space?';

  @override
  String get leaveCoupleDeleteAllContent =>
      'You\'re the last member. Leaving will permanently delete ALL your shared memories — photos, love notes, and the question journal. This can\'t be undone.';

  @override
  String get leaveCoupleDeleteAllBtn => 'Delete everything';

  @override
  String get leaveCoupleError =>
      'Couldn\'t leave the couple right now. Please check your connection and try again.';

  @override
  String get localDataClearedMsg =>
      'Local data on this device has been cleared. Shared data in the cloud is preserved.';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get languageSystemDesc => 'Follow device language';

  @override
  String get loadingCoupleInfo => 'Loading couple info...';

  @override
  String get savingCoupleSpace => 'Saving couple space...';

  @override
  String get connectingCouple => 'Connecting couple...';

  @override
  String get updatingCoupleInfo => 'Updating couple info...';

  @override
  String get setupNoChangesToSaveMsg => 'No changes to save.';

  @override
  String get inviteCodeCopiedMsg => 'Invite code copied';

  @override
  String get copyBtn => 'Copy';

  @override
  String get shareBtn => 'Share';

  @override
  String inviteShareMessage(String code) {
    return 'I want to keep our memories together on Dear Embeiu 💞\nEnter this invite code to pair with me: $code\nGet the app & enter the code at: https://dearembeiu.com/get?code=$code';
  }

  @override
  String get remindersPermissionDeniedMsg =>
      'Turn on notifications in Settings to receive reminders.';

  @override
  String get dailyQuestionReminderTitle => 'Daily question reminder';

  @override
  String get dailyQuestionReminderSubtitle =>
      'Nudges you both to answer each day, synced across both phones.';

  @override
  String get dailyQuestionReminderAddTime => 'Add a time';

  @override
  String get dailyQuestionReminderNotifTitle =>
      'Today\'s question is waiting 💌';

  @override
  String get dailyQuestionReminderNotifBody =>
      'Answer it to unlock your partner\'s reply.';

  @override
  String get dailyQuestionReminderNotifBodyAlt1 =>
      'There\'s a new question for the two of you — answer yours first 💞';

  @override
  String get dailyQuestionReminderNotifBodyAlt2 =>
      'A little question is waiting for you both, come answer it 🌸';

  @override
  String get dqPartnerOnlyNudgeTitle => 'Just your partner left to answer 💌';

  @override
  String get dailyQuestionReminderEndOfDayHint =>
      'If the question is still unfinished at the end of the day, you\'ll also be nudged at 21:00 — plus 22:00 and 23:00 if you haven\'t answered yet.';

  @override
  String get dqEndOfDayNudgeTitle => 'The day is winding down 🌙';

  @override
  String get dqEndOfDayNudgeBody =>
      'Today\'s question is still waiting — answer it before the day ends.';

  @override
  String get dqEndOfDayNudgePartnerBody =>
      'Your partner hasn\'t answered today\'s question yet — give them a nudge.';

  @override
  String get dqStreakWarningTitle => 'Your streak is about to break! 🔥';

  @override
  String dqStreakWarningBody(int days) {
    return 'The day\'s almost over. Answer today\'s question to keep your $days-day streak!';
  }

  @override
  String get dqStreakWarningStartBody =>
      'The day\'s almost over! Answer today\'s question to start a new streak.';

  @override
  String get dqStreakWarningFinalTitle => 'Less than an hour left! ⏳';

  @override
  String dqStreakWarningFinalBody(int days) {
    return 'Answer now so your $days-day streak doesn\'t break 🔥';
  }

  @override
  String get dqStreakWarningFinalStartBody =>
      'Answer now to start a new streak before the day ends 🌱';

  @override
  String get reminderMilestoneTodayTitle => 'Milestone reached 🎉';

  @override
  String reminderMilestoneTodayBody(String milestone) {
    return 'Today you reach $milestone together 💕';
  }

  @override
  String get reminderAnniversaryTitle => 'Happy anniversary 🎉';

  @override
  String get reminderAnniversaryBody =>
      'Celebrate another year of your love story today 💕';

  @override
  String get reminderInactivityTitle => 'Missing your moments 💭';

  @override
  String get reminderInactivityBody =>
      'It\'s been a while — add a new memory together 💕';

  @override
  String remindersV2MilestoneCountBadge(int count) {
    return '$count';
  }

  @override
  String get remindersV2MilestoneScreenTitle => 'Milestones & anniversaries';

  @override
  String get milestoneBadge => 'SPECIAL DAYS';

  @override
  String get milestoneHeaderSubtitle =>
      'Pick milestones to be reminded of, with their own times.';

  @override
  String remindersV2MilestoneNext(String date) {
    return 'Next: $date';
  }

  @override
  String remindersV2MilestoneNextWithLabel(String label, String date) {
    return 'Next: $label · $date';
  }

  @override
  String get remindersV2MilestonePast => 'Passed';

  @override
  String get remindersV2MilestonePending =>
      'Calculated once your anniversary begins';

  @override
  String remindersV2MilestoneDaysLabel(int count) {
    return '$count days';
  }

  @override
  String remindersV2MilestoneYearsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count years',
      one: '1 year',
    );
    return '$_temp0';
  }

  @override
  String get milestoneEvery100Title => 'Every 100 days';

  @override
  String get milestoneEvery100Desc => 'Celebrate every 100 days together';

  @override
  String get milestone520Title => '520 days';

  @override
  String get milestone520Desc => '\"I love you\" — the 520-day mark';

  @override
  String get milestone1000Title => '1000 days';

  @override
  String get milestone1000Desc => 'A full 1000 days in love';

  @override
  String get milestone1314Title => '1314 days';

  @override
  String get milestone1314Desc => '\"Forever love\" — the 1314-day mark';

  @override
  String get milestoneHalfYearTitle => 'Half a year together';

  @override
  String get milestoneHalfYearDesc => 'A full 6 months together';

  @override
  String get milestoneYearlyTitle => 'Yearly anniversary';

  @override
  String get milestoneYearlyDesc => 'Every year on your anniversary';

  @override
  String get milestoneInactivityTitle => 'No photos for a while';

  @override
  String get milestoneInactivityDesc =>
      'A gentle nudge after 7 days without a new photo';

  @override
  String get milestoneInactivitySub => 'Reminds you after 7 photo-free days';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsBadge => 'APP PREFERENCES';

  @override
  String get settingsHeaderSubtitle =>
      'Reminders, notifications, language and your account.';

  @override
  String get settingsRemindersEntryTitle => 'Reminders';

  @override
  String get settingsRemindersEntrySubtitle =>
      'Milestones, anniversaries and your own reminders';

  @override
  String get remindersHubBadge => 'REMINDERS';

  @override
  String get remindersHubTitle => 'Our reminders';

  @override
  String get remindersHubSubtitle =>
      'Milestones, anniversaries and your own reminders — all in one place.';

  @override
  String get settingsAnalyticsTitle => 'Share usage data';

  @override
  String get settingsAnalyticsSubtitle =>
      'Help improve the app with anonymous data. We never collect your private content.';

  @override
  String get languageSearchHint => 'Search languages';

  @override
  String get customRemindersScreenTitle => 'Our reminders';

  @override
  String get customRemindersBadge => 'YOUR OWN MOMENTS';

  @override
  String get customRemindersHeaderSubtitle =>
      'Create reminders for your own special moments.';

  @override
  String customRemindersCount(int count) {
    return '$count/20';
  }

  @override
  String customRemindersNextFire(String date) {
    return 'Next: $date';
  }

  @override
  String get customRemindersDisabledLabel => 'Off';

  @override
  String get customRemindersFabTooltip => 'Add reminder';

  @override
  String get customRemindersEmptyTitle => 'No reminders yet';

  @override
  String get customRemindersEmptyBody =>
      'Create your own moments: birthdays, monthsaries, special days…';

  @override
  String get customRemindersEmptyCta => 'Create your first reminder';

  @override
  String get customRemindersAddAnother => 'Add a reminder';

  @override
  String get customRemindersLimitMsg =>
      'You\'ve reached the max of 20 reminders. Delete one to add more.';

  @override
  String get customRemindersAddTitle => 'New reminder';

  @override
  String get customRemindersEditTitle => 'Edit reminder';

  @override
  String get customReminderFormBadge => 'YOUR REMINDER';

  @override
  String get customRemindersSave => 'Save';

  @override
  String get customRemindersCancel => 'Cancel';

  @override
  String get customRemindersSavedMsg => 'Reminder saved 💌';

  @override
  String get customRemindersNameLabel => 'Reminder name';

  @override
  String get customRemindersNameRequiredMark => '*';

  @override
  String get customRemindersNameHint => 'e.g. My love\'s birthday';

  @override
  String get customRemindersNoteLabel => 'Note (optional)';

  @override
  String get customRemindersNoteHint => 'Add a sweet note…';

  @override
  String get customRemindersDateLabel => 'Date';

  @override
  String get customRemindersTimeLabel => 'Time';

  @override
  String get customRemindersRepeatLabel => 'Repeat';

  @override
  String get customRemindersRepeatOnce => 'Once';

  @override
  String get customRemindersRepeatDaily => 'Daily';

  @override
  String get customRemindersRepeatWeekly => 'Weekly';

  @override
  String get customRemindersRepeatMonthly => 'Monthly';

  @override
  String get customRemindersRepeatYearly => 'Yearly';

  @override
  String get customRemindersNotifyPartnerLabel => 'Also remind my partner';

  @override
  String get customRemindersNotifyPartnerSubtitle =>
      'Your partner gets this reminder at the same time too';

  @override
  String customRemindersMetaOnce(String date, String time) {
    return 'Once · $date · $time';
  }

  @override
  String customRemindersMetaDaily(String time) {
    return 'Daily · $time';
  }

  @override
  String customRemindersMetaWeekly(String weekday, String time) {
    return 'Weekly · $weekday · $time';
  }

  @override
  String customRemindersMetaMonthly(int day, String time) {
    return 'Monthly · day $day · $time';
  }

  @override
  String customRemindersMetaYearly(String dayMonth, String time) {
    return 'Yearly · $dayMonth · $time';
  }

  @override
  String get customRemindersNameError => 'Please name your reminder';

  @override
  String get customRemindersPastDateWarning =>
      'That date has passed — pick another';

  @override
  String get customRemindersDeleteSectionHint => 'Can\'t be undone';

  @override
  String get customRemindersDeleteButton => 'Delete reminder';

  @override
  String get customRemindersDeleteDialogTitle => 'Delete this reminder?';

  @override
  String customRemindersDeleteDialogBody(String name) {
    return '\"$name\" will be removed and won\'t remind you anymore.';
  }

  @override
  String get customRemindersDeleteConfirm => 'Delete';

  @override
  String get customRemindersDeletedMsg => 'Reminder deleted';

  @override
  String get customRemindersUndoLabel => 'Undo';

  @override
  String get customRemindersNotifBodyFallback =>
      'A special moment for the two of you 💞';

  @override
  String get agreeToPrivacyPolicy => 'I agree to the Privacy Policy';

  @override
  String get appTitle => 'Our Memories';

  @override
  String get authAccountNotFound => 'No account found for this email.';

  @override
  String get authConfigNotFound =>
      'Email sign-in isn\'t available right now. Please try again later.';

  @override
  String get authEmailAlreadyUsed => 'This email is already in use.';

  @override
  String get authEmailPasswordNotEnabled =>
      'Email sign-in isn\'t available right now. Please try again later.';

  @override
  String get authFirebaseAuthGeneric =>
      'Couldn\'t verify your account. Please try again.';

  @override
  String get authFirebaseUserCreateFailed =>
      'Couldn\'t create your account. Please try again.';

  @override
  String get authFirestoreGeneric =>
      'Couldn\'t sync your account data. Please try again.';

  @override
  String get authFirestorePermissionDenied =>
      'The server didn\'t accept your account info. Please try again in a few minutes.';

  @override
  String get authFirestoreUnavailable =>
      'Can\'t reach the server right now. It might be a network hiccup, so try again in a few minutes.';

  @override
  String get authInvalidCredential => 'Email or password is incorrect.';

  @override
  String get authInvalidEmail => 'That email isn\'t valid.';

  @override
  String get authInviteCodeGenerateFailed =>
      'Couldn\'t generate a new invite code — please try again later.';

  @override
  String get authInviteCodeUnavailable =>
      'Couldn\'t create an invite code for your account right now — please try again.';

  @override
  String get authNetworkError =>
      'Your connection seems unstable. Check it and try again.';

  @override
  String get authSessionNotReady =>
      'Your session isn\'t ready yet. Please sign in again.';

  @override
  String get authSessionUnavailable =>
      'Couldn\'t sign you in. Please try again.';

  @override
  String get authTooManyRequests =>
      'Too many sign-in attempts — please try again in a few minutes.';

  @override
  String get authUserDisabled =>
      'This account has been disabled, so you can\'t sign in.';

  @override
  String get authWeakPassword =>
      'That password is too weak — please choose a stronger one.';

  @override
  String get authWrongPassword =>
      'That password isn\'t right — please check and try again.';

  @override
  String get bootstrapAndroidNotReady =>
      'Firebase Android isn\'t ready. Check `android/app/google-services.json` and the app\'s package name.';

  @override
  String get bootstrapIosNotConfigured =>
      'You\'re on iOS but the project has no `GoogleService-Info.plist`, so the app fell back to local mode.';

  @override
  String get bootstrapLinuxNotConfigured =>
      'Firebase for Linux isn\'t configured, so the app is running in local fallback.';

  @override
  String get bootstrapMacosNotConfigured =>
      'Firebase for macOS isn\'t configured, so the app is running in local fallback.';

  @override
  String get bootstrapPlatformNotConfigured =>
      'Firebase isn\'t configured for the current platform, so the app is running in local fallback.';

  @override
  String get bootstrapWebNotConfigured =>
      'Firebase isn\'t configured for Web, so the app is running in local fallback.';

  @override
  String get bootstrapWindowsNotConfigured =>
      'Firebase for Windows isn\'t configured, so the app is running in local fallback.';

  @override
  String get coupleAlreadyInCouple =>
      'This account already belongs to a couple.';

  @override
  String get coupleAlreadyInThisCouple => 'You\'re already in this couple.';

  @override
  String get coupleCannotUseOwnCode => 'You can\'t use your own invite code.';

  @override
  String get coupleCodeNoLongerValid =>
      'This invite code no longer points to a valid couple.';

  @override
  String get coupleCodeNotFoundLocal =>
      'Couldn\'t find the connection code in local fallback.';

  @override
  String get coupleEnterCodeFirst => 'Please enter a connection code first.';

  @override
  String get coupleFirebaseUnavailable =>
      'Can\'t reach the server right now. It might be a network hiccup, so try again in a few minutes.';

  @override
  String get coupleFull => 'This couple already has two people.';

  @override
  String get coupleFullLocal => 'This local couple already has two people.';

  @override
  String get coupleInviteCodeInvalid =>
      'This invite code is invalid or no longer exists.';

  @override
  String get coupleJoinGeneric =>
      'Couldn\'t connect with this invite code right now.';

  @override
  String get coupleJoinPermissionDenied =>
      'Couldn\'t connect with this invite code. The couple space may have changed or is no longer valid — ask your partner to regenerate the code, or sign out and back in, then try again.';

  @override
  String get coupleMatchedLocal => 'Matched in local fallback mode.';

  @override
  String get coupleNoDataToUpdate => 'No couple data to update.';

  @override
  String get coupleNotFoundForCode => 'No couple found for this code.';

  @override
  String get coupleOnboardingBadge => 'ONBOARDING';

  @override
  String get couplePartnerHasNoSpace =>
      'Your partner has their own invite code but hasn\'t created a couple space for you to join yet.';

  @override
  String get couplePhotoUploadGeneric =>
      'Couldn\'t upload your couple photo. Try changing it again later.';

  @override
  String get couplePhotoUploadPermission =>
      'Couldn\'t upload your couple photo. Your couple info is saved, so just try changing the photo again later.';

  @override
  String get couplePhotoUploadSessionInvalid =>
      'Couldn\'t upload your couple photo because your session expired. Sign in again, then change the photo.';

  @override
  String get couplePhotoUploadUnavailable =>
      'Couldn\'t upload your couple photo. The network or server is acting up. Please try again later.';

  @override
  String get coupleSaveGeneric => 'Couldn\'t save couple info right now.';

  @override
  String get coupleSavePermissionDenied =>
      'Couldn\'t save couple info because access was denied. The data may be in an invalid state — please sign out and back in, then try again.';

  @override
  String get coupleSessionExpiredJoin =>
      'Your session has expired. Please sign in again, then retry connecting.';

  @override
  String get coupleSessionInvalid =>
      'Your session has expired. Please sign in again.';

  @override
  String get coupleSessionNotReadyRelogin =>
      'Your session isn\'t ready yet. Please sign out and back in.';

  @override
  String get coupleSpaceInvalidRegenerate =>
      'This invite code points to a couple space that\'s no longer valid. Ask your partner to regenerate the code, then try again.';

  @override
  String get coupleUpdatedSuccess => 'Couple info updated.';

  @override
  String get coupleUserNotFoundForCreate =>
      'Couldn\'t find your current account to create a couple.';

  @override
  String get createAccountBadge => 'CREATE ACCOUNT';

  @override
  String get defaultDisplayName => 'New user';

  @override
  String get deleteAccountBtn => 'Delete account';

  @override
  String get deleteAccountConfirmBtn => 'Delete permanently';

  @override
  String get deleteAccountDialogContent =>
      'This action cannot be undone. All your data, including photos and couple information, will be permanently deleted.';

  @override
  String get deleteAccountDialogTitle => 'Delete account?';

  @override
  String get deleteAccountFailed =>
      'Could not delete your account right now. Please try again.';

  @override
  String get deleteAccountReauthTitle => 'Confirm it\'s you';

  @override
  String get deleteAccountReauthBody =>
      'For your security, re-enter your password to permanently delete your account.';

  @override
  String get deleteAccountSessionExpiredMsg =>
      'Your session has expired. Please sign in again, then delete your account.';

  @override
  String get editCoupleBadge => 'COUPLE PROFILE';

  @override
  String get galleryEditCaptionTooltip => 'Edit caption';

  @override
  String get galleryEmptySubtitle => 'Add photos to start making memories';

  @override
  String get galleryEmptyTitle => 'No photos yet';

  @override
  String get galleryRecordTodayMoment => 'Capture today\'s moment';

  @override
  String get galleryTodayBadge => 'Today';

  @override
  String get galleryTodayEmptySubtitle =>
      'Every photo is a memory the two of you share.';

  @override
  String get galleryTodayEmptyTitle => 'No moments captured today yet';

  @override
  String get leavingCouple => 'Leaving the couple...';

  @override
  String get mustAgreeToPrivacyPolicy =>
      'Please agree to the privacy policy to continue';

  @override
  String get photoConnectCoupleFirst =>
      'Connect with your partner before posting a photo.';

  @override
  String get photoFileNotFoundStorage =>
      'This photo couldn\'t be found on the server.';

  @override
  String get photoFirebaseUnavailable =>
      'Can\'t reach the server right now. It might be a network hiccup, so try again in a few minutes.';

  @override
  String get photoNotFoundToPost => 'Couldn\'t find the photo to post.';

  @override
  String get photoStorageUnauthorized =>
      'You can\'t do that with this photo right now. Try signing out and back in.';

  @override
  String get photoSyncGeneric => 'Couldn\'t sync photos right now.';

  @override
  String get photoSyncPermissionDenied =>
      'You don\'t have permission to sync photos yet. Try signing out and back in.';

  @override
  String get photoSyncSessionExpired =>
      'Your session has expired. Please sign in again.';

  @override
  String get posterNameFallback => 'Your partner';

  @override
  String get privacyDisclosure =>
      'By creating an account, you agree to our Privacy Policy. We collect your email, display name, and photos you share to provide the service.';

  @override
  String get privacyPolicyLabel => 'Privacy Policy';

  @override
  String get profileDangerIrreversible => 'Can\'t be undone';

  @override
  String get pushPhotoChannelDescription =>
      'Get notified when your partner posts a new photo.';

  @override
  String get pushPhotoChannelName => 'Partner photo updates';

  @override
  String get signOutBtn => 'Sign out';

  @override
  String get signOutConfirmBtn => 'Sign out';

  @override
  String get signOutDialogContent =>
      'Are you sure you want to sign out of your account?';

  @override
  String get signOutDialogTitle => 'Sign out?';

  @override
  String get signOutFailedMsg =>
      'Couldn\'t sign out. Please check your connection and try again.';

  @override
  String get welcomeBackBadge => 'WELCOME BACK';

  @override
  String counterDuration(int years, int months, int days) {
    return '$years years, $months months, $days days';
  }

  @override
  String get coupleLoadError =>
      'Couldn\'t load your couple info. Please try again.';

  @override
  String get coupleSyncError =>
      'Couldn\'t sync your couple info. Please try again.';

  @override
  String galleryMonthLabel(String month, String year) {
    String _temp0 = intl.Intl.selectLogic(month, {
      '1': 'January $year',
      '2': 'February $year',
      '3': 'March $year',
      '4': 'April $year',
      '5': 'May $year',
      '6': 'June $year',
      '7': 'July $year',
      '8': 'August $year',
      '9': 'September $year',
      '10': 'October $year',
      '11': 'November $year',
      '12': 'December $year',
      'other': '$month $year',
    });
    return '$_temp0';
  }

  @override
  String get galleryEndOfFeed =>
      'That\'s every memory 💕 — go make some new ones together';

  @override
  String galleryTodayMomentsCount(int count) {
    return '$count moments today';
  }

  @override
  String get guestModeBadge => 'Trial mode';

  @override
  String get guestCounterTitle => 'Love day counter';

  @override
  String get guestCounterSubtitle =>
      'Enter the day you started to see how long you\'ve been together.';

  @override
  String get guestEmptyTitle => 'Start counting your love days';

  @override
  String get guestEmptyBody =>
      'Pick your anniversary date to see how long you\'ve been together.';

  @override
  String get guestPickDate => 'Pick anniversary date';

  @override
  String get guestChangeDate => 'Change anniversary date';

  @override
  String guestCounterStartFrom(String date) {
    return 'Since $date';
  }

  @override
  String get guestCtaTitle => 'Want to keep memories together?';

  @override
  String get guestCtaBody => 'Sign in to pair up & share photos together.';

  @override
  String get guestCtaSignIn => 'Sign in';

  @override
  String get guestCtaRegister => 'Sign up';

  @override
  String get streakChipNoStreak => 'Start a streak together';

  @override
  String get streakChipRestart => 'Let\'s start a new streak 🌱';

  @override
  String streakChipActiveToday(int n) {
    return '$n-day streak · done for today';
  }

  @override
  String streakChipInProgress(int n) {
    return '$n-day streak · today\'s your turn 🌸';
  }

  @override
  String streakChipAtRisk(int n) {
    return 'Your $n-day streak is waiting 🫶';
  }

  @override
  String get streakSheetUnit => 'days connected in a row';

  @override
  String get streakSheetNoStreakTitle => 'Light your first spark';

  @override
  String get streakSheetRestartTitle => 'Light the spark again';

  @override
  String get streakSheetNoStreakBody =>
      'Each day you both answer the question, your streak grows. Let\'s begin 💞';

  @override
  String get streakSheetActiveTitle => 'You\'re keeping the spark alive 💞';

  @override
  String get streakSheetActiveBody =>
      'All done today! See you at tomorrow\'s question.';

  @override
  String get streakSheetInProgressTitle => 'Your streak\'s still glowing 🌸';

  @override
  String streakSheetInProgressBody(int n) {
    return 'Answer today\'s question to keep your $n-day streak going 💞';
  }

  @override
  String get streakSheetAtRiskTitle => 'One soft day left 🫶';

  @override
  String streakSheetAtRiskBody(int n) {
    return 'You missed a beat yesterday — totally okay! Answer today and your $n-day streak picks right back up.';
  }

  @override
  String get streakSheetRestartBody =>
      'The old streak wrapped up, but every new day\'s a fresh start. Let\'s light it again 🌱';

  @override
  String streakSheetRecord(int m) {
    return 'Your record: $m days 🌟';
  }

  @override
  String streakNextMilestone(int n, int m) {
    return '$n days to your $m-day milestone 🎉';
  }

  @override
  String get streakCtaAnswerNow => 'Answer now';

  @override
  String get streakCtaKeepGoing => 'Keep it going';

  @override
  String get streakMilestone3Title => '3 days already! 🌸';

  @override
  String get streakMilestone3Body =>
      'What a sweet start. You two are doing great 💞';

  @override
  String get streakMilestone7Title => 'A whole week! ✨';

  @override
  String get streakMilestone7Body =>
      '7 days without missing a beat. So proud of you both!';

  @override
  String get streakMilestone30Title => '30 days, every single day! 🔥';

  @override
  String get streakMilestone30Body =>
      'A month of keeping it lit — this is your ritual now 💞';

  @override
  String get streakMilestone100Title => '100 days! 💯';

  @override
  String get streakMilestone100Body =>
      'A hundred days answering together, growing together. Few couples make it this far 🌟';

  @override
  String get streakMilestone365Title => 'A full year! 👑';

  @override
  String get streakMilestone365Body =>
      '365 days of never missing your connection. This is your love story 💞👑';

  @override
  String streakJournalSummary(int n, int m) {
    return '$n-day streak · longest $m';
  }

  @override
  String get streakJournalSummaryNone =>
      'Answer together each day to start a streak 🌸';

  @override
  String get forgotPasswordLink => 'Forgot password?';

  @override
  String get forgotPasswordBadge => 'RECOVER ACCESS';

  @override
  String get forgotPasswordEmailHeading => 'Email';

  @override
  String get forgotPasswordSendBtn => 'Send reset email';

  @override
  String get forgotPasswordBackToLogin => 'Back to sign in';

  @override
  String get forgotPasswordSentTitle => 'Check your inbox';

  @override
  String forgotPasswordSentBody(String email) {
    return 'We\'ve sent a password reset link to $email. Open the email and tap the link to reset it. Don\'t forget to check your spam folder.';
  }

  @override
  String get forgotPasswordResendLink => 'Didn\'t get it? Resend';

  @override
  String get forgotPasswordNetworkError =>
      'Couldn\'t send the email. Check your connection and try again.';

  @override
  String get forgotPasswordLocalFallback =>
      'This feature needs an internet connection. Please connect and try again.';

  @override
  String get verifyEmailBadge => 'VERIFY EMAIL';

  @override
  String get verifyEmailBody =>
      'Open the email, tap the verification link, then come back here and tap \"I\'ve verified\".';

  @override
  String get verifyEmailCheckBtn => 'I\'ve verified';

  @override
  String get verifyEmailResend => 'Resend email';

  @override
  String verifyEmailResendCountdown(String time) {
    return 'Resend in $time';
  }

  @override
  String get verifyEmailNotYet =>
      'Not verified yet — please check your inbox and try again.';

  @override
  String get verifyEmailSuccess => 'Verified! Taking you in...';

  @override
  String get verifyEmailResendError =>
      'Couldn\'t resend the email. Check your connection and try again.';

  @override
  String get setupWaitingCoupleCodeTitle => 'Share this code to connect';

  @override
  String get setupCoupleCodeDesc =>
      'This is your couple\'s pairing code. Either of you can use it to reconnect.';

  @override
  String get setupCoupleCodeRejoinHint =>
      'Save this code — you can use it to rejoin your space at any time.';

  @override
  String get galleryNeedsCoupleToUpload =>
      'Connect with your partner first before sharing photos 💞';

  @override
  String get notifCenterTitle => 'Notifications';

  @override
  String get notifCenterBadge => 'WHAT\'S NEW';

  @override
  String get notifCenterEmptyTitle => 'No notifications yet';

  @override
  String get notifCenterEmptyBody =>
      'Activity from the two of you will appear here.';

  @override
  String get notifGroupToday => 'Today';

  @override
  String get notifGroupEarlier => 'Earlier';

  @override
  String notifUnreadCount(int count) {
    return '$count unread';
  }

  @override
  String get notifAllCaughtUp => 'You\'re all caught up 💛';

  @override
  String get notifMarkAllRead => 'Mark all read';

  @override
  String get notifClearAll => 'Clear all';

  @override
  String get notifClearAllConfirmTitle => 'Clear all notifications?';

  @override
  String get notifClearAllConfirmBody =>
      'You won\'t be able to see these again.';

  @override
  String get notifGeneric => 'You have a new notification';

  @override
  String notifPhotoPosted(String name) {
    return '$name shared a new photo';
  }

  @override
  String notifPhotoReaction(String name, String emoji) {
    return '$name reacted $emoji to your photo';
  }

  @override
  String notifPartnerJoined(String name) {
    return '$name paired up with you';
  }

  @override
  String notifPartnerLeft(String name) {
    return '$name left your shared space';
  }

  @override
  String notifLoveNote(String name) {
    return '$name left you a love note';
  }

  @override
  String notifDailyQuestion(String name) {
    return '$name answered today\'s question';
  }

  @override
  String notifDailyQuestionBoth(String name) {
    return 'You and $name both answered today\'s question 💞';
  }

  @override
  String notifChatMessage(String name) {
    return '$name sent you a message 💬';
  }

  @override
  String get forceUpdateBadge => 'UPDATE';

  @override
  String get forceUpdateTitle => 'Time to update';

  @override
  String get forceUpdateBody =>
      'The version you\'re on is out of date. Update to the latest to keep making memories with your other half.';

  @override
  String get forceUpdateButton => 'Update now';

  @override
  String get counterBgBadge => 'BACKGROUND';

  @override
  String get counterBgTitle => 'Counter background';

  @override
  String get counterBgSubtitleAll =>
      'Pick which photos can back the day-counter card. Leave empty to cycle through them all.';

  @override
  String counterBgSubtitleCount(int count) {
    return '$count photos picked for the counter background.';
  }

  @override
  String get counterBgCoverLabel => 'Cover';

  @override
  String get counterBgEmptyTitle => 'No photos yet';

  @override
  String get counterBgEmptyBody => 'Add some memories to your gallery first.';

  @override
  String get settingsCounterBgTitle => 'Counter background';

  @override
  String get settingsCounterBgSubtitle =>
      'Choose which photos show on the counter';

  @override
  String get counterBgSave => 'Save';

  @override
  String get counterBgSavedMsg => 'Counter background saved 💕';

  @override
  String get counterBgDiscardTitle => 'Discard changes?';

  @override
  String get counterBgDiscardBody =>
      'You have unsaved changes. Leave without saving?';

  @override
  String get counterBgDiscardLeave => 'Leave';

  @override
  String get settingsChatBgTitle => 'Chat background';

  @override
  String get settingsChatBgSubtitle => 'Pick a photo to back your conversation';

  @override
  String get chatBgBadge => 'CHAT BACKGROUND';

  @override
  String get chatBgTitle => 'Chat background';

  @override
  String get chatBgSubtitle =>
      'Pick one photo to back your conversation, or keep the default gradient.';

  @override
  String get chatBgFilterHint =>
      'Only portrait, high-resolution photos are shown — they fill the screen without cropping or blurring.';

  @override
  String get chatBgNoneLabel => 'Default';

  @override
  String get chatBgMeasuring => 'Filtering photos…';

  @override
  String get chatBgNoneValidTitle => 'No suitable photos yet';

  @override
  String get chatBgNoneValidBody =>
      'Add a tall, sharp photo to your gallery — landscape or low-resolution photos can\'t be used as a chat background.';

  @override
  String get chatBgSavedMsg => 'Chat background saved 💕';

  @override
  String get journeyTrailTitle => 'Our journey';

  @override
  String milestoneTrailNext(int days, String label) {
    return '$days days to $label';
  }

  @override
  String get milestoneTrailAllDone => 'You\'ve reached every milestone 🎉';

  @override
  String get profileAchievementsTitle => 'Your badges';

  @override
  String get badgeStreakLabel => 'day streak';

  @override
  String get badgeRecordLabel => 'record';

  @override
  String get badgeMemoriesLabel => 'memories';

  @override
  String get badgeJournalLabel => 'journal';

  @override
  String get profileRecordsTitle => 'Your records';

  @override
  String get profileRecordLongestStreak => 'Longest streak';

  @override
  String get profileRecordDaysTogether => 'Days together';

  @override
  String get profileRecordTotalMemories => 'Total memories';

  @override
  String get profileRecordJournalEntries => 'Questions answered';

  @override
  String get profileRecordStreakMilestones => 'Streak milestones';

  @override
  String profileJournalCountLabel(String count) {
    return '$count answered';
  }

  @override
  String get profileMemoriesTitle => 'Our memories';

  @override
  String profileMemoriesCountLabel(String count) {
    return '$count memories';
  }

  @override
  String profileMemoriesNextLabel(String count, String milestone) {
    return '$count more to reach $milestone';
  }

  @override
  String get loveTreeBadge => 'LOVE TREE';

  @override
  String get loveTreeStage0 => 'Tiny seed';

  @override
  String loveTreeFlowerCount(int count) {
    return '$count flowers bloomed';
  }

  @override
  String get loveTreeSeedSubtitle => 'Your journey starts right here 🌱';

  @override
  String loveTreeNewBloomBanner(int count) {
    return 'Your tree just bloomed $count new flowers 🌸';
  }

  @override
  String get loveTreeNewBloomBannerOne =>
      'Your tree just bloomed a new flower 🌸';

  @override
  String loveTreeMilestoneDays(int count) {
    return '$count days together';
  }

  @override
  String loveTreeMilestoneStreak(int count) {
    return '$count-day streak';
  }

  @override
  String loveTreeMilestonePhotos(int count) {
    return '$count memories';
  }

  @override
  String loveTreeMilestoneDaysLeft(int count) {
    return '$count days to go';
  }

  @override
  String loveTreeMilestoneStreakLeft(int count) {
    return '$count streak days to go';
  }

  @override
  String loveTreeMilestonePhotosLeft(int count) {
    return '$count photos to go';
  }

  @override
  String get loveTreeWaitingTitle => 'Waiting for both of you';

  @override
  String get loveTreeWaitingBody =>
      'The tree grows when you\'re both here. Invite your partner 💌';

  @override
  String get loveTreeWaitingCta => 'Invite partner';

  @override
  String get loveTreeNoCoupleBody =>
      'Connect with your partner to start growing 🌱';

  @override
  String get loveTreeCoachTooltip => 'Tap to see this moment 🌸';

  @override
  String loveTreeMomentDaysTitle(int count) {
    return '$count days together';
  }

  @override
  String loveTreeMomentPhotosTitle(int count) {
    return 'Memory #$count';
  }

  @override
  String loveTreeMomentStreakTitle(int count) {
    return '$count-day streak record';
  }

  @override
  String loveTreeMomentBloomedOn(String date) {
    return 'Bloomed on $date';
  }

  @override
  String loveTreeMomentPhotoTakenOn(String date) {
    return 'Added on $date';
  }

  @override
  String get loveTreeMomentDaysCopy =>
      'Every day together is one more petal in bloom 🌸';

  @override
  String get loveTreeMomentPhotosCopy =>
      'A moment the two of you chose to keep 💞';

  @override
  String get loveTreeMomentStreakCopy =>
      'The record you two once kept together. Start a new streak to beat it 🔥';

  @override
  String get loveTreeMomentViewInGallery => 'View in Gallery';

  @override
  String loveTreeLockedDays(int count) {
    return '$count days to go before this blooms 🌱';
  }

  @override
  String loveTreeLockedPhotos(int count) {
    return '$count memories to go before this blooms 🌱';
  }

  @override
  String loveTreeLockedStreak(int count) {
    return '$count streak days to go before this blooms 🌱';
  }

  @override
  String get loveTreeLockedPhotosCta => 'Add a memory';

  @override
  String get loveTreeLockedStreakCta => 'Answer today';

  @override
  String get loveTreeShareButton => 'Share our tree';

  @override
  String loveTreeShareStats(String days, String flowers) {
    return '$days days together · $flowers flowers in bloom';
  }

  @override
  String get loveTreeShareTagline => 'The tree we grew together 🌳';

  @override
  String get loveTreeShareTaglineSeed => 'Our tree just sprouted 🌱';

  @override
  String loveTreeShareMessage(String flowers, String days) {
    return 'Our love tree has bloomed $flowers flowers after $days days 🌳💞 — grow yours together on Dear Embeiu.';
  }

  @override
  String get partnerReminderNotifBody => 'A reminder from your partner 💌';

  @override
  String notifAnswerReaction(String name, String emoji) {
    return '$name reacted $emoji to your answer';
  }

  @override
  String get answerReactionHint => 'React to your partner\'s answer';

  @override
  String get answerReactionAddTooltip => 'Add a reaction';

  @override
  String get answerReactionRemoveTooltip => 'Remove reaction';

  @override
  String get answerReactionErrorRetry => 'Couldn\'t send — tap to retry';

  @override
  String get careMessageBadge => 'CARE NOTE';

  @override
  String get careMessageEntryTitle => 'Send a care note';

  @override
  String get careMessageQuickPicksTitle => 'Quick picks';

  @override
  String get careMessageTitleLabel => 'Title';

  @override
  String get careMessageTitleHint => 'e.g. Missing you';

  @override
  String get careMessageBodyLabel => 'Message';

  @override
  String get careMessageBodyHint => 'Write something warm...';

  @override
  String get careMessageSendCta => 'Send to your love 💌';

  @override
  String get aiQuestionsSaveFailed => 'Couldn\'t save that, please try again';

  @override
  String get dailyQuestionPreparing => 'Getting today\'s question ready…';

  @override
  String get careMessageQueuedToast =>
      'Slow network — your note will be sent as soon as you\'re back online 💌';

  @override
  String get careMessageSentToast => 'Sent 💌';

  @override
  String get careMessageErrorToast => 'Couldn\'t send. Please try again.';

  @override
  String get careMessageNeedCouple => 'Pair up first to send a care note.';

  @override
  String get careMessageRecentTitle => 'Recently sent';

  @override
  String get careMessageFromMe => 'You';

  @override
  String get careMessageFromPartner => 'Your love';

  @override
  String get careQuick1Title => 'Missing you 💕';

  @override
  String get careQuick1Body =>
      'Just thinking about you. How is your day going?';

  @override
  String get careQuick2Title => 'Drink some water 💧';

  @override
  String get careQuick2Body => 'Remember to stay hydrated today, okay?';

  @override
  String get careQuick3Title => 'Have you eaten? 🍚';

  @override
  String get careQuick3Body => 'Please eat on time today, no skipping meals.';

  @override
  String get careQuick4Title => 'Sleep early tonight 🌙';

  @override
  String get careQuick4Body =>
      'It is getting late, get some rest. Sweet dreams!';

  @override
  String get careQuick5Title => 'Love you so much ❤️';

  @override
  String get careQuick5Body => 'Just wanted to say I love you so much today.';

  @override
  String get careQuick6Title => 'You\'ve got this 💪';

  @override
  String get careQuick6Body =>
      'Today looks tough, but you\'ve got this. I am right here.';

  @override
  String notifCareMessage(String name) {
    return '$name sent you a care note';
  }

  @override
  String get rpsGameTitle => 'Rock Paper Scissors';

  @override
  String get rpsGameBadge => 'ROCK PAPER SCISSORS';

  @override
  String get rpsChoiceRock => 'Rock';

  @override
  String get rpsChoicePaper => 'Paper';

  @override
  String get rpsChoiceScissors => 'Scissors';

  @override
  String get rpsChoiceNone => 'Skipped';

  @override
  String get rpsResultWin => 'You win 🎉';

  @override
  String get rpsResultLose => 'Your person wins 😝';

  @override
  String get rpsResultDraw => 'It\'s a draw 🤝';

  @override
  String get rpsWaitingPartner => 'Waiting for your person…';

  @override
  String get rpsChosenWaiting => 'You\'ve thrown ✓ · Waiting for your person…';

  @override
  String get rpsExpired => 'This invite has expired';

  @override
  String get rpsCancelled => 'Your person cancelled the invite';

  @override
  String notifRpsInvite(String name) {
    return '$name challenged you to rock-paper-scissors!';
  }

  @override
  String notifRpsResult(String name) {
    return 'Your rock-paper-scissors game with $name is over';
  }

  @override
  String get rpsHistoryBadge => 'MATCH HISTORY';

  @override
  String get rpsEntryIdleSubtitle => 'Challenge your person to a round';

  @override
  String rpsEntryWeekScore(String win, String draw, String loss) {
    return 'This week $win – $draw – $loss';
  }

  @override
  String get rpsEntryInvitedTitle => 'You\'re challenged!';

  @override
  String get rpsEntryInvitedSubtitle => 'Hop in — they\'re waiting';

  @override
  String get rpsEntryPendingSubtitle => 'Invite stays open for 10 minutes';

  @override
  String get rpsEntryCtaPlay => 'Play';

  @override
  String get rpsEntryCtaJoin => 'Join';

  @override
  String get rpsEntryCtaOpen => 'Open';

  @override
  String rpsScoreFormat(String win, String draw, String loss) {
    return '$win – $draw – $loss';
  }

  @override
  String rpsScoreSemantics(String win, String draw, String loss) {
    return 'Score: you $win, draw $draw, your person $loss';
  }

  @override
  String rpsChoiceSemantics(String choice) {
    return 'Pick $choice';
  }

  @override
  String get rpsRulesHint =>
      'Scissors cut Paper · Paper wraps Rock · Rock breaks Scissors';

  @override
  String get rpsRuleScissorsPaper => 'Scissors cut Paper';

  @override
  String get rpsRulePaperRock => 'Paper wraps Rock';

  @override
  String get rpsRuleRockScissors => 'Rock breaks Scissors';

  @override
  String get rpsMeLabel => 'Me';

  @override
  String get rpsPartnerLabel => 'Your person';

  @override
  String get rpsVs => 'vs';

  @override
  String get rpsWaitingBody => 'Invite sent. Waiting for your person…';

  @override
  String get rpsWaitingBodyInvitee =>
      'Connecting to your person… The round starts once you\'re both here.';

  @override
  String get rpsNudgeCta => 'Nudge again';

  @override
  String rpsNudgeCooldown(String seconds) {
    return 'Nudge again (${seconds}s)';
  }

  @override
  String get rpsNudgeSentToast => 'Nudged your person again 🔔';

  @override
  String get rpsCancelCta => 'Cancel invite';

  @override
  String get rpsCloseCta => 'Close';

  @override
  String get rpsCancelledToast => 'Invite cancelled';

  @override
  String get rpsCountdownPrompt => 'Pick now!';

  @override
  String get rpsCountdownUnit => 'SEC';

  @override
  String rpsCountdownSemantics(String seconds) {
    return '$seconds seconds left';
  }

  @override
  String get rpsResolving => 'Revealing…';

  @override
  String get rpsResolvingSlow => 'Connection is a bit slow…';

  @override
  String get rpsReloadCta => 'Reload';

  @override
  String get rpsOfflineHint =>
      'Offline — your pick will go through once you\'re back online';

  @override
  String rpsResultDrawSub(String choice) {
    return 'Both picked $choice';
  }

  @override
  String get rpsResultTimeoutPartner => 'Your person didn\'t pick in time';

  @override
  String get rpsResultTimeoutMe => 'You didn\'t pick in time';

  @override
  String get rpsResultTimeoutBoth => 'Both skipped — this round is a draw';

  @override
  String get rpsRematchCta => 'Play again';

  @override
  String get rpsHistoryCta => 'View history';

  @override
  String get rpsRematchToast => 'Your person wants a rematch!';

  @override
  String rpsResultSemantics(String title, String mine, String theirs) {
    return '$title. You picked $mine, your person picked $theirs.';
  }

  @override
  String get rpsExpiredBody =>
      'This invite expired after 10 minutes. Start a new round!';

  @override
  String get rpsCancelledBody =>
      'No worries — you two can play another round any time.';

  @override
  String get rpsInviteAgainCta => 'Challenge again';

  @override
  String get rpsErrorTitle => 'Couldn\'t open the round';

  @override
  String get rpsErrorBody => 'Check your connection and try again.';

  @override
  String get rpsNeedCouple => 'You need your person in the app to play.';

  @override
  String get rpsScoreMe => 'ME';

  @override
  String get rpsScoreDraw => 'DRAW';

  @override
  String get rpsScorePartner => 'THEM';

  @override
  String rpsHistoryTotal(String count) {
    return '$count rounds played';
  }

  @override
  String rpsHistoryWinStreak(String count) {
    return 'Win streak: $count';
  }

  @override
  String get rpsOutcomeWin => 'You won';

  @override
  String get rpsOutcomeLoss => 'They won';

  @override
  String get rpsOutcomeDraw => 'Draw';

  @override
  String get rpsOutcomeSkipped => 'Skipped';

  @override
  String rpsHistoryRowSemantics(
    String time,
    String mine,
    String theirs,
    String outcome,
  ) {
    return '$time: you $mine, your person $theirs, $outcome';
  }

  @override
  String get rpsHistoryEmptyTitle => 'No rounds yet';

  @override
  String get rpsHistoryEmptyBody =>
      'Every round you two play lands here — draws included.';

  @override
  String get rpsHistoryEmptyCta => 'Challenge your person';

  @override
  String get featureTourRpsTitle => 'Rock-paper-scissors together';

  @override
  String get featureTourRpsBody =>
      'Send a challenge, count it down together and throw. No skipping — whoever hasn\'t thrown gets a nudge, and the reveal waits for both of you. History and score live on your Profile.';

  @override
  String get rpsOpenPrompt => 'Go on, throw! No skipping here 😄';

  @override
  String get rpsOpenRingSemantics => 'No time limit — throw when you\'re ready';

  @override
  String get rpsPartnerMovedTitle => 'Your person has thrown!';

  @override
  String get rpsPartnerMovedBody => 'Your move — pick a hand below';

  @override
  String get rpsMoveNudgeCta => 'Nudge your person';

  @override
  String rpsMoveNudgeCooldown(String seconds) {
    return 'Nudged · again in ${seconds}s';
  }

  @override
  String get rpsMoveNudgeSentToast => 'Nudged your person 🔔';

  @override
  String rpsMoveNudgeTooSoon(String seconds) {
    return 'You just nudged — try again in ${seconds}s';
  }

  @override
  String get rpsMoveNudgeFailed => 'Couldn\'t send the nudge — try again';

  @override
  String get rpsChosenLeaveHint =>
      'Feel free to step away — we\'ll tell you the result';

  @override
  String get rpsEntryMyTurnSubtitle => 'Your turn — go ahead 😄';

  @override
  String get rpsEntryUnplayedTitle => 'Round in progress';

  @override
  String get rpsEntryUnplayedSubtitle => 'No one\'s thrown — go first';

  @override
  String get rpsEntryAwaitingTitle => 'Waiting for their move';

  @override
  String get rpsEntryAwaitingSubtitle => 'You\'ve thrown · we\'ll tell you';

  @override
  String get rpsEntryCtaThrow => 'Throw';

  @override
  String notifRpsMoved(String name) {
    return '$name has thrown — your move!';
  }

  @override
  String get sleepCardTitle => 'Last night';

  @override
  String get sleepBadge => 'SLEEP';

  @override
  String get sleepYou => 'You';

  @override
  String get sleepUnitHour => 'h';

  @override
  String get sleepUnitMinute => 'm';

  @override
  String sleepDurationShort(int h, int m) {
    return '${h}h ${m}m';
  }

  @override
  String sleepMinutesShort(int m) {
    return '${m}m';
  }

  @override
  String sleepDurationLong(int h, int m) {
    return '$h hr $m min';
  }

  @override
  String sleepTogether(String duration) {
    return 'Asleep together $duration';
  }

  @override
  String sleepWentFirst(String name, String duration) {
    return '$name fell asleep $duration earlier';
  }

  @override
  String get sleepNoOverlap => 'You didn\'t sleep at the same time last night';

  @override
  String get sleepSetupPitch =>
      'Let your phone log your sleep and see each morning how your person slept.';

  @override
  String get sleepEnableCta => 'Turn on';

  @override
  String get sleepHide => 'Hide';

  @override
  String get sleepNotRecorded => 'Not recorded';

  @override
  String get sleepLogManually => 'Log it';

  @override
  String get sleepPartnerNotShared => 'Not shared';

  @override
  String sleepPartnerNotSharedLong(String name) {
    return '$name isn\'t sharing sleep';
  }

  @override
  String get sleepNoData => 'No data yet';

  @override
  String get sleepNeedsPermission => 'Permission needed';

  @override
  String get sleepOpenSettings => 'Open settings';

  @override
  String get sleepPermissionBanner =>
      'The app can\'t see when your screen turns on or off, so it can\'t log your sleep. Turn it back on in Settings → Usage access.';

  @override
  String get sleepViewBoth => 'Both';

  @override
  String get sleepPrevMonth => 'Previous month';

  @override
  String get sleepNextMonth => 'Next month';

  @override
  String sleepNightTitle(String d1, String d2) {
    return 'Night of $d1 → $d2';
  }

  @override
  String sleepAwakenings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Woke up $count times',
      one: 'Woke up once',
    );
    return '$_temp0';
  }

  @override
  String get sleepNoAwakenings => 'Slept straight through';

  @override
  String get sleepSourceEdited => 'Edited';

  @override
  String get sleepSourceManual => 'Manual';

  @override
  String get sleepSourceHealth => 'Apple Health';

  @override
  String get sleepSourcePhone => 'Phone (automatic)';

  @override
  String sleepSourceRow(String source) {
    return 'Source: $source';
  }

  @override
  String get sleepMonthSection => 'This month';

  @override
  String get sleepPerNight => '/night';

  @override
  String sleepAvgTimes(String bed, String wake) {
    return 'Bed ~$bed · Up ~$wake';
  }

  @override
  String sleepFullNights(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count full nights',
      one: '1 full night',
    );
    return '$_temp0';
  }

  @override
  String sleepOfNights(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'of $count nights',
      one: 'of 1 night',
    );
    return '$_temp0';
  }

  @override
  String sleepTogetherNights(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nights asleep together 7h+',
      one: '1 night asleep together 7h+',
    );
    return '$_temp0';
  }

  @override
  String sleepTogetherAvg(String duration) {
    return 'avg. $duration a night';
  }

  @override
  String get sleepShareToggle => 'Share with your person';

  @override
  String get sleepShareToggleSub => 'When off, only you can see it.';

  @override
  String get sleepHowItWorks => 'How is sleep worked out?';

  @override
  String get sleepMyColor => 'Your moon color';

  @override
  String sleepMyColorSub(String name, String color, String blocked) {
    return '$name uses $color. Colors too close to it ($blocked) are locked.';
  }

  @override
  String sleepMyColorSubNoBlock(String name, String color) {
    return '$name uses $color.';
  }

  @override
  String get sleepMyColorSolo => 'This color marks your sleep everywhere.';

  @override
  String sleepColorTakenSemantics(String name) {
    return '$name\'s color';
  }

  @override
  String sleepColorTooClose(String name) {
    return 'Too close to $name\'s color';
  }

  @override
  String sleepColorAutoChanged(String color) {
    return 'Your color matched your person\'s, so $color shows for now.';
  }

  @override
  String get sleepColorRose => 'Pink';

  @override
  String get sleepColorPurple => 'Purple';

  @override
  String get sleepColorBlue => 'Blue';

  @override
  String get sleepColorTeal => 'Teal';

  @override
  String get sleepColorOrange => 'Orange';

  @override
  String get sleepColorGreen => 'Green';

  @override
  String get sleepColorMagenta => 'Magenta';

  @override
  String get sleepColorAmber => 'Amber';

  @override
  String get sleepLegend0 => '<5h';

  @override
  String get sleepLegend1 => '5–6h';

  @override
  String get sleepLegend2 => '6–7h';

  @override
  String get sleepLegend3 => '7–8h';

  @override
  String get sleepLegend4 => '8h+';

  @override
  String get sleepMoonTagline => 'The fuller the moon, the fuller the sleep';

  @override
  String get sleepMoonLeft => 'Left moon: you';

  @override
  String sleepMoonRight(String name) {
    return 'Right moon: $name';
  }

  @override
  String get sleepMoonTogether => 'Asleep together 7h+';

  @override
  String get sleepPhase0 => 'Thin crescent';

  @override
  String get sleepPhase1 => 'Crescent';

  @override
  String get sleepPhase2 => 'Half moon';

  @override
  String get sleepPhase3 => 'Gibbous moon';

  @override
  String get sleepPhase4 => 'Full moon';

  @override
  String sleepDaySemantics(String day, String summary) {
    return '$day: $summary';
  }

  @override
  String sleepSemanticsSlept(String name, String duration, String phase) {
    return '$name slept $duration, $phase';
  }

  @override
  String sleepSemanticsNoData(String name) {
    return '$name: no data';
  }

  @override
  String get sleepEditedSemantics => '(edited)';

  @override
  String get sleepNoOverlapNight =>
      'You didn\'t sleep at the same time this night';

  @override
  String get sleepManualHint => 'Tap edit to log it yourself';

  @override
  String get sleepPartnerNightEmpty => 'Nothing logged this night';

  @override
  String get sleepEditLocked =>
      'Older than 7 days, so it can no longer be edited';

  @override
  String get sleepEditButton => 'Edit this night\'s sleep';

  @override
  String get sleepSetupTitle => 'Let your phone log your sleep';

  @override
  String get sleepSetupBodyAndroid =>
      'Each morning the app checks when your phone sat untouched longest overnight. It never reads messages, photos or any other content.';

  @override
  String get sleepSetupBodyIos =>
      'The app reads the sleep your iPhone or Apple Watch saved in Health. Read only, nothing gets written.';

  @override
  String get sleepSetupUnsupported =>
      'This phone can\'t log sleep on its own. You can still log it by hand in a few seconds.';

  @override
  String get sleepSetupPoint1 => 'Nothing to do each day';

  @override
  String get sleepSetupPoint2 => 'Fix it if the app guesses wrong';

  @override
  String get sleepSetupPoint3 => 'Shared only if you want';

  @override
  String get sleepSetupHintAndroid =>
      'The app opens Settings → Usage access. Turn on Dear Embeiu, then come back here.';

  @override
  String get sleepSetupHintIos =>
      'Your iPhone will ask to read Sleep in Health. No data yet? Turn on Sleep Schedule in Health.';

  @override
  String get sleepPermissionStillOff =>
      'Dear Embeiu isn\'t turned on in the list yet. Try again.';

  @override
  String get sleepGrantCta => 'Allow access';

  @override
  String get sleepManualCta => 'I\'ll log it myself';

  @override
  String sleepShareAskTitle(String name) {
    return 'Let $name see your sleep?';
  }

  @override
  String get sleepShareAskBody =>
      'They\'ll see when you fall asleep and wake up. You can turn this off anytime.';

  @override
  String sleepShareAskPreview(String name) {
    return '$name WILL SEE';
  }

  @override
  String get sleepShareAskOnly => 'Only when you sleep and wake, nothing else.';

  @override
  String get sleepShareAskCta => 'Share with them';

  @override
  String get sleepLater => 'Later';

  @override
  String get sleepBackToStep1 => 'Back to step 1';

  @override
  String get sleepEditBedTitle => 'Bedtime';

  @override
  String get sleepEditWakeTitle => 'Wake up';

  @override
  String sleepEditTotal(String duration) {
    return 'Total: $duration';
  }

  @override
  String get sleepEditInvalid => 'Sleep must be 1 to 16 hours';

  @override
  String get sleepDeleteNight => 'Delete this night';

  @override
  String get sleepEditSubtitle => 'Fix it if the app got it wrong.';

  @override
  String get sleepManualSubtitle => 'Log when you fell asleep and woke up.';

  @override
  String get sleepEditNote =>
      'Once saved, this night shows an “Edited” label (your person sees it too) and the app won\'t overwrite it.';

  @override
  String get sleepManualNote =>
      'Once saved, this night shows a “Manual” label, and your person sees it too.';

  @override
  String get sleepPickerSubtitle => 'Scroll to pick the hour and minute';

  @override
  String get sleepSaveFailed => 'Couldn\'t save, please try again';

  @override
  String get sleepLoadFailed => 'Couldn\'t load your person\'s sleep';

  @override
  String get sleepHowBody1 =>
      'The app counts the longest stretch your phone sits untouched overnight as sleep, between 6 pm and 2 pm the next day, lasting 3 to 16 hours. A stretch that ends before 1 am, like charging in the evening, only counts when nothing that night lasts past 1 am.';

  @override
  String get sleepHowBody1Ios =>
      'The app takes the longest sleep your iPhone or Apple Watch saved in Health between 6 pm and 2 pm the next day. Sleep under 3 hours or over 16 hours doesn\'t count. Sleep that ends before 1 am only counts when nothing that night lasts past 1 am.';

  @override
  String get sleepHowBody2 =>
      'Picking up your phone for under 5 minutes counts as waking up, not as the end of your sleep.';

  @override
  String get sleepHowBody3 =>
      'It\'s an estimate: watching a movie in bed or leaving your phone elsewhere can skew it. You can fix it within 7 days, and your person will see an “Edited” label.';

  @override
  String get sleepHowBody4 =>
      'The app reads no content on your phone, only when the screen turns on or off.';

  @override
  String get sleepHowBody4Ios =>
      'The app only reads Sleep in Health, nothing else.';

  @override
  String get sleepGotIt => 'Got it';

  @override
  String get sleepIosHealthHint =>
      'Turn on *Sleep Schedule* in Health so your iPhone logs your sleep.';

  @override
  String get sleepHintDismiss => 'Dismiss tip';

  @override
  String get timePickerDefaultTitle => 'Pick a reminder time';

  @override
  String get timePickerDefaultSubtitle => 'Scroll to pick the hour and minute';

  @override
  String get timePickerConfirm => 'Confirm';

  @override
  String sleepHoursShort(int h) {
    return '${h}h';
  }

  @override
  String sleepHoursLong(int h) {
    return '$h hr';
  }

  @override
  String get loveTreeSkyTitle => 'Today\'s constellation';

  @override
  String get loveTreeSkyExplain =>
      'Every little thing we do for each other today lights a star. When both halves glow, the heart is complete.';

  @override
  String get loveTreeLeftHalf => 'Left half: You';

  @override
  String loveTreeRightHalf(String name) {
    return 'Right half: $name';
  }

  @override
  String get loveTreeStarQuestion => 'Question';

  @override
  String get loveTreeStarMood => 'Mood';

  @override
  String get loveTreeStarMessage => 'Message';

  @override
  String get loveTreeTapStar => 'Tap a star to see more';

  @override
  String get loveTreeHeartFull => 'Today\'s heart is complete';

  @override
  String get loveTreeTaskQuestion => 'Answer today\'s question';

  @override
  String get loveTreeTaskMood => 'Share your mood';

  @override
  String get loveTreeTaskMessage => 'Send each other a message';

  @override
  String loveTreeStarAnsweredAt(String name, String time) {
    return '$name answered at $time';
  }

  @override
  String loveTreeStarMoodAt(String mood, String time) {
    return '$mood · $time';
  }

  @override
  String loveTreeStarMessagedAt(String name, String time) {
    return '$name messaged at $time';
  }

  @override
  String get loveTreeStarDone => 'Done for today';

  @override
  String get loveTreeStarNoAnswer => 'Today\'s question isn\'t answered yet';

  @override
  String get loveTreeStarNoMood => 'No mood shared yet today';

  @override
  String get loveTreeStarNoMessage => 'No message yet today';

  @override
  String get loveTreeActAnswer => 'Answer now';

  @override
  String get loveTreeActMood => 'Share now';

  @override
  String get loveTreeActMessage => 'Message now';

  @override
  String get loveTreeNudge => 'Send some care';

  @override
  String get loveTreeClosePanel => 'Close';

  @override
  String loveTreeStarSemantics(String name, String task, String state) {
    return '$name · $task · $state';
  }

  @override
  String get loveTreeStarLit => 'lit';

  @override
  String get loveTreeStarUnlit => 'not lit yet';

  @override
  String get loveTreeFlowersExplain =>
      'Each flower is one of our milestones. Tap one to look back.';

  @override
  String get loveTreeKindDays => 'Days together';

  @override
  String get loveTreeKindStreak => 'Question streak';

  @override
  String get loveTreeKindPhotos => 'Photo memories';

  @override
  String get loveTreeNextFlower => 'NEXT FLOWER';

  @override
  String loveTreeNextProgressDays(int current, int target) {
    return '$current/$target days together';
  }

  @override
  String loveTreeNextProgressStreak(int current, int target) {
    return '$current/$target streak days';
  }

  @override
  String loveTreeNextProgressPhotos(int current, int target) {
    return '$current/$target photos';
  }

  @override
  String get loveTreeTodayTasks => 'Little things today';

  @override
  String loveTreeTaskDone(String name) {
    return '$name ✓';
  }

  @override
  String loveTreeTaskPending(String name) {
    return '$name · not yet';
  }

  @override
  String get loveTreeDoNow => 'Do it now';

  @override
  String get loveTreeBloomedTitle => 'Bloomed milestones';

  @override
  String get loveTreeShowLess => 'Show less';

  @override
  String homeConstellationSemantics(int lit) {
    return 'Today\'s constellation: $lit of 6 stars. Opens the Love Tree';
  }
}

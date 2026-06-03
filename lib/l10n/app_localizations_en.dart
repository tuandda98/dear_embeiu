// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

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
  String get keep => 'Keep';

  @override
  String get splashTagline => 'Our story';

  @override
  String get splashSubtitle => 'Counting every day of us';

  @override
  String get checkingSession => 'Checking your session...';

  @override
  String get loginTitle => 'Welcome back';

  @override
  String get loginSubtitle => 'Sign in to keep counting every day of you two.';

  @override
  String get loginLocalFallback =>
      'Local fallback is on — Firebase will be wired up later.';

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
  String get registerTitle => 'Begin your\nlove story';

  @override
  String get registerSubtitle =>
      'Create an account to keep every day of you two safe.';

  @override
  String get registerLocalFallback =>
      'Local fallback is on — Firebase will be wired up later.';

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
  String get setupEditTitle => 'Refine\nyour story';

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
  String get sendToPartnerHint => 'Send this to them';

  @override
  String get inviteCodeTiedToAccount => 'Code tied to your account';

  @override
  String get setupErrorNoAccount => 'No account found. Please sign in again.';

  @override
  String get setupErrorFillRequired =>
      'Please fill in both names and the anniversary date.';

  @override
  String setupErrorSaveCouple(String error) {
    return 'Could not save couple info: $error';
  }

  @override
  String get setupErrorNoAccountShort => 'No account found.';

  @override
  String get setupErrorNoInviteCode => 'Please enter the invite code first.';

  @override
  String setupErrorJoinCouple(String error) {
    return 'Could not join couple: $error';
  }

  @override
  String get setupSuccessConnected => 'Connected successfully 💞';

  @override
  String get navHome => 'Home';

  @override
  String get navMemories => 'Memories';

  @override
  String get navProfile => 'Profile';

  @override
  String get ourStoryBadge => 'OUR STORY';

  @override
  String get helloGreeting => 'Hello,';

  @override
  String get homeSubtitle => 'A good day to look back at your love story.';

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
  String get quickMomentsTitle => 'Quick moments';

  @override
  String get quickMomentsSubtitle => 'Shortcuts to revisit your story';

  @override
  String get addMemoryCta => 'Add a memory';

  @override
  String get addMemoryCtaSubtitle => 'Post a new photo for you both to keep';

  @override
  String get memoriesCardTitle => 'Memories';

  @override
  String get viewAllPhotos => 'View all photos';

  @override
  String get profileCardTitle => 'Profile';

  @override
  String get updateInfo => 'Update info';

  @override
  String get milestoneCardTitle => 'Milestone';

  @override
  String get loveInNumbersTitle => 'Love in numbers';

  @override
  String get loveInNumbersSubtitle => 'Little stats from your journey';

  @override
  String get daysTogether => 'Days together';

  @override
  String get daysUnit => 'days';

  @override
  String get memoriesSaved => 'Memories saved';

  @override
  String get photosUnit => 'photos';

  @override
  String get nextAnniversaryLabel => 'Next anniversary';

  @override
  String get daysAway => 'days away';

  @override
  String get nextMilestoneTitle => 'Next milestone';

  @override
  String get milestoneProgressTitle => 'Milestone progress';

  @override
  String get milestoneProgressSubtitle =>
      'Gently approaching the next sweet number';

  @override
  String get recentMemoriesTitle => 'Recent memories';

  @override
  String onThisDayTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count years ago',
      one: '1 year ago',
    );
    return 'On this day, $_temp0 💞';
  }

  @override
  String get onThisDaySubtitle => 'A memory from this very day';

  @override
  String get addPhotosPrompt => 'Add a few photos to start your love letter';

  @override
  String get latestMomentsSubtitle => 'A few of your latest moments together';

  @override
  String get seeAll => 'See all';

  @override
  String get addPhotosEmpty =>
      'Add a few photos to start filling this love letter.';

  @override
  String get yourStorySoFar => 'Your story so far';

  @override
  String get whenItAllBegan => 'When it all began';

  @override
  String whenItAllBeganSubtitle(String name1, String name2, String date) {
    return '$name1 & $name2 on $date';
  }

  @override
  String monthiversaries(int count) {
    return '$count monthiversaries';
  }

  @override
  String get monthiversaryDesc =>
      'Each month, another layer of understanding and tenderness.';

  @override
  String memoriesCaptured(int count) {
    return '$count memories captured';
  }

  @override
  String get memoriesCapturedDesc =>
      'Your library is becoming a quiet little album.';

  @override
  String get loveNoteLabel => 'Love note';

  @override
  String loveNoteQuote(int count) {
    return '\"$count days isn\'t just time — it\'s every soft moment, every choice to stay, every little kindness we share.\"';
  }

  @override
  String loveNoteFromPartner(String name) {
    return 'Note from $name';
  }

  @override
  String loveNoteEmptyFromPartner(String name) {
    return 'No note from $name yet';
  }

  @override
  String get loveNoteWriteCta => 'Write a note';

  @override
  String get loveNoteEditCta => 'Edit your note';

  @override
  String get loveNoteWaitingPartner =>
      'Invite your partner so you can leave little notes for each other.';

  @override
  String get loveNoteSheetTitle => 'Your love note';

  @override
  String get loveNoteSheetHint => 'Write something sweet for your partner…';

  @override
  String loveNoteCharCount(int count) {
    return '$count/140';
  }

  @override
  String get loveNoteSaved => 'Your note was sent 💞';

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
  String get dailyQuestionLabel => 'Today\'s question';

  @override
  String get dailyQuestionHint => 'Write your answer…';

  @override
  String dailyQuestionCharCount(int count) {
    return '$count/280';
  }

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
  String get dailyQuestionRevealHint =>
      'You both answered — here\'s what you each said 💞';

  @override
  String get dailyQuestionSent => 'Your answer was sent 💞';

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
  String get privateGalleryBadge => 'PRIVATE GALLERY';

  @override
  String get galleryTitle => 'Photo Library';

  @override
  String get gallerySubtitle =>
      'Swipe up to quickly bring up the post frame and manage memories.';

  @override
  String get addCaptionTitle => 'Add caption';

  @override
  String get addCaptionHint => 'Write a few lines about this moment...';

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
  String daysTogetherCount(int count) {
    return '$count days together';
  }

  @override
  String get privateFeedLabel => 'Private feed for you two';

  @override
  String get postNewPhotoBtn => 'Post new photo';

  @override
  String get addMultipleBtn => 'Add multiple';

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
  String get todayInLoveBadge => 'TODAY IN LOVE';

  @override
  String get storyStripBadge => 'STORY STRIP';

  @override
  String get memoriesTodayTitle => 'Memories today';

  @override
  String get recentPhotosTitle => 'Recent photos';

  @override
  String get memoriesTodaySubtitle =>
      'Moments saved on this exact date, tender and personal.';

  @override
  String get recentPhotosSubtitle =>
      'A small story strip for a quick look at your latest moments.';

  @override
  String get memoryBadge => 'Memory';

  @override
  String get newBadge => 'New';

  @override
  String momentLabel(int number) {
    return 'Moment #$number';
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
  String get editAction => 'Edit';

  @override
  String get deleteAction => 'Delete';

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
  String get deletingPhoto => 'Deleting photo...';

  @override
  String get updatingCaption => 'Updating caption...';

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
  String get profileTitle => 'Your profile';

  @override
  String get profileSubtitle =>
      'A private corner to look back on your love journey, milestones, and memory album.';

  @override
  String get todayIsAnniversaryProfile => 'Today is your anniversary ✨';

  @override
  String daysUntilAnniversaryProfile(int count) {
    return '$count days until the next anniversary';
  }

  @override
  String khoanhKhacCount(int count) {
    return '$count moments';
  }

  @override
  String get privateDiaryLabel => 'Private diary';

  @override
  String get loveMilestonesLabel => 'Love milestones';

  @override
  String get journeySnapshotTitle => 'Journey snapshot';

  @override
  String get journeySnapshotSubtitle =>
      'The standout numbers of your relationship, presented cleanly, modernly, and clearly.';

  @override
  String get yearsTogether => 'Years together';

  @override
  String get monthsRemaining => 'Months remaining';

  @override
  String get totalDaysLabel => 'Total days';

  @override
  String get memoriesSavedLabel => 'Memories saved';

  @override
  String get infoAndRhythmTitle => 'Info & rhythm';

  @override
  String get infoAndRhythmSubtitle =>
      'A clearer look at your start date, album, and upcoming milestones.';

  @override
  String get loveStartDateLabel => 'Love start date';

  @override
  String get yourInviteCodeLabel => 'Your account invite code';

  @override
  String get dayStreakLabel => 'Day streak';

  @override
  String dayStreakValue(int count) {
    return '$count days and still going';
  }

  @override
  String get memoryAlbumLabel => 'Memory album';

  @override
  String memoryAlbumValue(int count) {
    return '$count photos saved in private album';
  }

  @override
  String get upcomingMilestoneLabel => 'Upcoming milestone';

  @override
  String get todaySpecialMsg => 'Today is a very special day for you two';

  @override
  String daysUntilNextMsg(int count) {
    return '$count more days until the next anniversary';
  }

  @override
  String get customizeProfileTitle => 'Customize profile';

  @override
  String get customizeProfileSubtitle =>
      'Update names, anniversary date, and couple photo so the profile always reflects your current journey.';

  @override
  String get editOurStoryBtn => 'Edit our story';

  @override
  String get proTipLabel => 'Pro tip';

  @override
  String get proTipContent =>
      'A bright, close-up couple photo with good breathing room will make the hero section look much more polished.';

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
  String get clearDataNote =>
      'Deleting all shared data is currently not allowed from one side. In the next sprint, this will be changed to a flow requiring both to confirm.';

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
  String get localDataClearedMsg =>
      'Local data on this device has been cleared. Shared data on cloud is preserved.';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageSubtitle => 'Choose the app display language';

  @override
  String get languageSystem => 'System default';

  @override
  String get languageSystemDesc => 'Follow device language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageVietnamese => 'Tiếng Việt';

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
    return 'I want to keep our memories together on Dear Embeiu 💞\nEnter this invite code to pair with me: $code';
  }

  @override
  String get remindersTitle => 'Love reminders';

  @override
  String get remindersSubtitle => 'Gentle nudges to keep your story growing';

  @override
  String get remindersToggleLabel => 'Milestone & anniversary reminders';

  @override
  String get remindersToggleDesc =>
      'Reminds you of the milestones & anniversaries you choose. Required to use \"Our reminders\".';

  @override
  String get remindersTimeLabel => 'Reminder time';

  @override
  String get remindersPermissionDeniedMsg =>
      'Turn on notifications in Settings to receive reminders.';

  @override
  String get reminderDailyTitle => 'Another day of us 💕';

  @override
  String get reminderDailyBody => 'Open Dear Embeiu and count today together.';

  @override
  String get reminderMilestoneApproachingTitle => 'A milestone is near 💕';

  @override
  String reminderMilestoneApproachingBody(int count, String milestone) {
    return '$count days until your $milestone milestone!';
  }

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
  String get remindersV2MilestoneEntryTitle => 'Milestones & anniversaries';

  @override
  String get remindersV2MilestoneEntrySubtitle =>
      'Choose which milestones to be reminded of';

  @override
  String remindersV2MilestoneCountBadge(int count) {
    return '$count';
  }

  @override
  String get remindersV2MilestoneScreenTitle => 'Milestones & anniversaries';

  @override
  String get remindersV2MilestoneScreenCaption =>
      'Choose the milestones you want and when to be reminded.';

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
    return '$count years';
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
  String get settingsProfileTileSubtitle => 'Reminders, language, account';

  @override
  String get settingsRemindersModuleTitle => 'Reminders';

  @override
  String get settingsRemindersModuleSubtitle =>
      'Milestones, anniversaries & your own reminders';

  @override
  String get settingsAccountModuleTitle => 'Account & data';

  @override
  String get settingsAccountModuleSubtitle => 'Your story, data & account';

  @override
  String get settingsAnalyticsTitle => 'Share usage data';

  @override
  String get settingsAnalyticsSubtitle =>
      'Help improve the app with anonymous data. We never collect your private content.';

  @override
  String get settingsEditStorySubtitle => 'Edit names, anniversary date, photo';

  @override
  String get settingsDefaultTimeLabel => 'Default time';

  @override
  String get settingsDefaultTimeSubtitle =>
      'Used for milestones without a custom time';

  @override
  String settingsMilestoneUsesDefault(String time) {
    return 'Default · $time';
  }

  @override
  String get settingsMilestoneCustomTimeReset => 'Reset to default time';

  @override
  String get remindersV2ForceOpenTitle => 'Turn on reminders to continue';

  @override
  String get remindersV2ForceOpenBody =>
      'You need to turn on \"Milestone & anniversary reminders\" to create and receive your own reminders.';

  @override
  String get remindersV2ForceOpenConfirm => 'Turn on';

  @override
  String get remindersV2ForceOpenLater => 'Later';

  @override
  String get remindersV2ForceOpenDeniedMsg =>
      'Notification permission denied. Enable notifications in Settings to continue.';

  @override
  String get languageSearchHint => 'Search languages';

  @override
  String get customRemindersEntryTitle => 'Our reminders';

  @override
  String get customRemindersEntrySubtitle => 'Create your own special dates';

  @override
  String get customRemindersScreenTitle => 'Our reminders';

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
  String get customRemindersItemMenuEdit => 'Edit';

  @override
  String get customRemindersItemMenuDelete => 'Delete';

  @override
  String get customRemindersEmptyTitle => 'No reminders yet';

  @override
  String get customRemindersEmptyBody =>
      'Create your own moments: birthdays, monthsaries, special days…';

  @override
  String get customRemindersEmptyCta => 'Create your first reminder';

  @override
  String get customRemindersOffTitle => 'Reminders are off';

  @override
  String get customRemindersOffBody =>
      'Turn on \"Love reminders\" in Profile so your reminders can work.';

  @override
  String get customRemindersOffCta => 'Turn on reminders';

  @override
  String get customRemindersLimitMsg =>
      'You\'ve reached the max of 20 reminders. Delete one to add more.';

  @override
  String get customRemindersAddTitle => 'New reminder';

  @override
  String get customRemindersEditTitle => 'Edit reminder';

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
      'Firebase Authentication for this project isn\'t enabled, or Email/Password is off. In Firebase Console > Authentication > Sign-in method > Email/Password, turn it on.';

  @override
  String get authEmailAlreadyUsed => 'This email is already in use.';

  @override
  String get authEmailPasswordNotEnabled =>
      'Firebase Authentication isn\'t fully set up for Email/Password. In Firebase Console > Authentication > Sign-in method, enable Email/Password.';

  @override
  String get authFirebaseAuthGeneric => 'A Firebase Auth error occurred.';

  @override
  String get authFirebaseUserCreateFailed =>
      'Couldn\'t create your Firebase account.';

  @override
  String get authFirestoreGeneric => 'A Firestore error occurred.';

  @override
  String get authFirestorePermissionDenied =>
      'Firestore is blocking writes to user data. This app connects to the Firebase project `tonyembeiu`, so check that project\'s Firestore Rules and allow a signed-in user to create/write their own `users/<uid>` and `invite_codes/<code>`.';

  @override
  String get authFirestoreUnavailable =>
      'Firestore is currently unavailable or the network is unstable. Please try again in a few minutes.';

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
      'No stable network connection to sign in to Firebase.';

  @override
  String get authSessionNotReady =>
      'Your Firebase session isn\'t ready. Please sign in again.';

  @override
  String get authSessionUnavailable => 'Couldn\'t get your Firebase session.';

  @override
  String get authTooManyRequests =>
      'Too many sign-in attempts — please try again in a few minutes.';

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
      'Firebase is currently unavailable or the network is unstable. Please try again in a few minutes.';

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
      'The couple photo couldn\'t be uploaded to Firebase Storage.';

  @override
  String get couplePhotoUploadPermission =>
      'The couple photo couldn\'t be uploaded to Firebase Storage. Your couple info was saved first — deploy `storage.rules`, then try changing the photo again.';

  @override
  String get couplePhotoUploadSessionInvalid =>
      'The couple photo couldn\'t be uploaded because your Firebase session is no longer valid.';

  @override
  String get couplePhotoUploadUnavailable =>
      'The couple photo couldn\'t be uploaded because Firebase Storage or the network is temporarily unstable.';

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
      'Your Firebase session is no longer valid. Please sign in again.';

  @override
  String get coupleSessionNotReadyRelogin =>
      'Your Firebase session isn\'t ready. Please sign out and back in.';

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
  String get deleteAccountDesc =>
      'Permanently delete your account and all associated data';

  @override
  String get deleteAccountDialogContent =>
      'This action cannot be undone. All your data, including photos and couple information, will be permanently deleted.';

  @override
  String get deleteAccountDialogTitle => 'Delete account?';

  @override
  String get deleteAccountFailed =>
      'Could not delete your account right now. Please try again.';

  @override
  String get deleteAccountRequiresReloginMsg =>
      'Please sign out, sign in again, and retry to verify your identity';

  @override
  String get deleteAccountSuccessMsg => 'Account deleted';

  @override
  String get deleteAccountTitle => 'Delete Account';

  @override
  String get editCoupleBadge => 'EDIT COUPLE';

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
      'Don\'t let today slip by without a trace.';

  @override
  String get galleryTodayEmptyTitle => 'No moments captured today yet';

  @override
  String get homeWaitingPartnerSubtitle =>
      'Share your invite code with your partner to start the journey together.';

  @override
  String get homeWaitingPartnerTitle => 'Waiting for your partner';

  @override
  String get leavingCouple => 'Leaving the couple...';

  @override
  String get loveHomeBadge => 'LOVE HOME';

  @override
  String get mustAgreeToPrivacyPolicy =>
      'Please agree to the privacy policy to continue';

  @override
  String get photoConnectCoupleFirst =>
      'Connect with your partner before posting a photo.';

  @override
  String get photoFileNotFoundStorage =>
      'The photo file wasn\'t found on Firebase Storage.';

  @override
  String get photoFirebaseUnavailable =>
      'Firebase is currently unavailable or the network is unstable.';

  @override
  String get photoNotFoundToPost => 'Couldn\'t find the photo to post.';

  @override
  String get photoStorageUnauthorized =>
      'Firebase Storage is refusing this photo operation.';

  @override
  String get photoSyncGeneric => 'Couldn\'t sync photos right now.';

  @override
  String get photoSyncPermissionDenied =>
      'You don\'t have permission to sync photos. Check `firestore.rules` and `storage.rules` on Firebase.';

  @override
  String get photoSyncSessionExpired =>
      'Your Firebase session has expired. Please sign in again.';

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
  String get welcomeBackBadge => 'WELCOME BACK';

  @override
  String counterDuration(int years, int months, int days) {
    return '$years years, $months months, $days days';
  }

  @override
  String coupleLoadError(String error) {
    return 'Couldn\'t load couple info: $error';
  }

  @override
  String coupleSyncError(String error) {
    return 'Couldn\'t sync couple info: $error';
  }

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
  String galleryTodayMomentsCount(int count) {
    return '$count moments today';
  }

  @override
  String homeCounterStartFrom(String date) {
    return 'Since $date';
  }

  @override
  String get guestTryWithoutLogin => 'Try without signing in';

  @override
  String get guestLoginDivider => 'or';

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
}

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
  String get welcomeBackBadge => 'WELCOME BACK';

  @override
  String get createAccountBadge => 'CREATE ACCOUNT';

  @override
  String get loveHomeBadge => 'LOVE HOME';

  @override
  String get coupleOnboardingBadge => 'ONBOARDING';

  @override
  String get editCoupleBadge => 'EDIT COUPLE';

  @override
  String get deleteAccountBtn => 'Delete account';

  @override
  String get deleteAccountTitle => 'Delete Account';

  @override
  String get deleteAccountDesc => 'Permanently delete your account and all associated data';

  @override
  String get deleteAccountDialogTitle => 'Delete account?';

  @override
  String get deleteAccountDialogContent =>
      'This action cannot be undone. All your data, including photos and couple information, will be permanently deleted.';

  @override
  String get deleteAccountConfirmBtn => 'Delete permanently';

  @override
  String get deleteAccountSuccessMsg => 'Account deleted';

  @override
  String get deleteAccountRequiresReloginMsg =>
      'Please sign out, sign in again, and retry to verify your identity';

  @override
  String get privacyPolicyLabel => 'Privacy Policy';

  @override
  String get privacyDisclosure =>
      'By creating an account, you agree to our Privacy Policy. We collect your email, display name, and photos you share to provide the service.';

  String get signOutBtn => 'Sign out';

  String get signOutDialogTitle => 'Sign out?';

  String get signOutDialogContent => 'Are you sure you want to sign out of your account?';

  String get signOutConfirmBtn => 'Sign out';

  String get agreeToPrivacyPolicy => 'I agree to the Privacy Policy';

  String get mustAgreeToPrivacyPolicy => 'Please agree to the privacy policy to continue';

  @override
  String get setupNoChangesToSaveMsg => 'No changes to save.';

  @override
  String get inviteCodeCopiedMsg => 'Invite code copied';

  @override
  String get copyBtn => 'Copy';
}

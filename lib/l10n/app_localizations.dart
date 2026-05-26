import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @continueBtn.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueBtn;

  /// No description provided for @keep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get keep;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Our story'**
  String get splashTagline;

  /// No description provided for @splashSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Counting every day of us'**
  String get splashSubtitle;

  /// No description provided for @checkingSession.
  ///
  /// In en, this message translates to:
  /// **'Checking your session...'**
  String get checkingSession;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to keep counting every day of you two.'**
  String get loginSubtitle;

  /// No description provided for @loginLocalFallback.
  ///
  /// In en, this message translates to:
  /// **'Local fallback is on — Firebase will be wired up later.'**
  String get loginLocalFallback;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get emailHint;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'That doesn\'t look like an email'**
  String get emailInvalid;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get passwordHint;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get passwordRequired;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password needs at least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @newHere.
  ///
  /// In en, this message translates to:
  /// **'New here?'**
  String get newHere;

  /// No description provided for @createAccountLink.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get createAccountLink;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Begin your\nlove story'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create an account to keep every day of you two safe.'**
  String get registerSubtitle;

  /// No description provided for @registerLocalFallback.
  ///
  /// In en, this message translates to:
  /// **'Local fallback is on — Firebase will be wired up later.'**
  String get registerLocalFallback;

  /// No description provided for @displayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get displayNameLabel;

  /// No description provided for @displayNameHint.
  ///
  /// In en, this message translates to:
  /// **'How you\'ll appear'**
  String get displayNameHint;

  /// No description provided for @displayNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a display name'**
  String get displayNameRequired;

  /// No description provided for @displayNameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Name is too short'**
  String get displayNameTooShort;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPasswordLabel;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Repeat the password'**
  String get confirmPasswordHint;

  /// No description provided for @confirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm the password'**
  String get confirmPasswordRequired;

  /// No description provided for @passwordsMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords don\'t match yet'**
  String get passwordsMismatch;

  /// No description provided for @createAccountBtn.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccountBtn;

  /// No description provided for @alreadyWithUs.
  ///
  /// In en, this message translates to:
  /// **'Already with us?'**
  String get alreadyWithUs;

  /// No description provided for @backToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get backToSignIn;

  /// No description provided for @setupCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Begin\nour story'**
  String get setupCreateTitle;

  /// No description provided for @setupEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Refine\nyour story'**
  String get setupEditTitle;

  /// No description provided for @setupTabCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get setupTabCreate;

  /// No description provided for @setupTabJoin.
  ///
  /// In en, this message translates to:
  /// **'Join with code'**
  String get setupTabJoin;

  /// No description provided for @inviteCodeDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Your invite code'**
  String get inviteCodeDialogTitle;

  /// No description provided for @inviteCodeDialogContent.
  ///
  /// In en, this message translates to:
  /// **'This code is tied to your account. Send it to your partner so they can sign in with their own account and enter it on the join screen.'**
  String get inviteCodeDialogContent;

  /// No description provided for @sectionAboutCouple.
  ///
  /// In en, this message translates to:
  /// **'About your couple'**
  String get sectionAboutCouple;

  /// No description provided for @setupEditSectionDesc.
  ///
  /// In en, this message translates to:
  /// **'Edit shared info — names, anniversary, couple photo.'**
  String get setupEditSectionDesc;

  /// No description provided for @setupCreateSectionDesc.
  ///
  /// In en, this message translates to:
  /// **'Create the space first, then share your invite code with your partner.'**
  String get setupCreateSectionDesc;

  /// No description provided for @yourNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get yourNameLabel;

  /// No description provided for @yourNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Anh'**
  String get yourNameHint;

  /// No description provided for @partnerNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Partner\'s name'**
  String get partnerNameLabel;

  /// No description provided for @partnerNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Em'**
  String get partnerNameHint;

  /// No description provided for @anniversaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Anniversary date'**
  String get anniversaryLabel;

  /// No description provided for @anniversaryHint.
  ///
  /// In en, this message translates to:
  /// **'Pick the day you started'**
  String get anniversaryHint;

  /// No description provided for @couplePhotoLabel.
  ///
  /// In en, this message translates to:
  /// **'Couple photo'**
  String get couplePhotoLabel;

  /// No description provided for @couplePhotoHint.
  ///
  /// In en, this message translates to:
  /// **'Add a couple photo (optional)'**
  String get couplePhotoHint;

  /// No description provided for @couplePhotoSelected.
  ///
  /// In en, this message translates to:
  /// **'Photo selected'**
  String get couplePhotoSelected;

  /// No description provided for @saveChangesBtn.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChangesBtn;

  /// No description provided for @createOurSpaceBtn.
  ///
  /// In en, this message translates to:
  /// **'Create our space'**
  String get createOurSpaceBtn;

  /// No description provided for @useInviteCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Use an invite code'**
  String get useInviteCodeTitle;

  /// No description provided for @theirInviteCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Their invite code'**
  String get theirInviteCodeLabel;

  /// No description provided for @theirInviteCodeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. A7B9KD'**
  String get theirInviteCodeHint;

  /// No description provided for @joinBtn.
  ///
  /// In en, this message translates to:
  /// **'Join their space'**
  String get joinBtn;

  /// No description provided for @yourInviteCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Your invite code'**
  String get yourInviteCodeTitle;

  /// No description provided for @sendToPartnerHint.
  ///
  /// In en, this message translates to:
  /// **'Send this to them'**
  String get sendToPartnerHint;

  /// No description provided for @inviteCodeTiedToAccount.
  ///
  /// In en, this message translates to:
  /// **'Code tied to your account'**
  String get inviteCodeTiedToAccount;

  /// No description provided for @setupErrorNoAccount.
  ///
  /// In en, this message translates to:
  /// **'No account found. Please sign in again.'**
  String get setupErrorNoAccount;

  /// No description provided for @setupErrorFillRequired.
  ///
  /// In en, this message translates to:
  /// **'Please fill in both names and the anniversary date.'**
  String get setupErrorFillRequired;

  /// No description provided for @setupErrorSaveCouple.
  ///
  /// In en, this message translates to:
  /// **'Could not save couple info: {error}'**
  String setupErrorSaveCouple(String error);

  /// No description provided for @setupErrorNoAccountShort.
  ///
  /// In en, this message translates to:
  /// **'No account found.'**
  String get setupErrorNoAccountShort;

  /// No description provided for @setupErrorNoInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter the invite code first.'**
  String get setupErrorNoInviteCode;

  /// No description provided for @setupErrorJoinCouple.
  ///
  /// In en, this message translates to:
  /// **'Could not join couple: {error}'**
  String setupErrorJoinCouple(String error);

  /// No description provided for @setupSuccessConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected successfully 💞'**
  String get setupSuccessConnected;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navMemories.
  ///
  /// In en, this message translates to:
  /// **'Memories'**
  String get navMemories;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @ourStoryBadge.
  ///
  /// In en, this message translates to:
  /// **'OUR STORY'**
  String get ourStoryBadge;

  /// No description provided for @helloGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello,'**
  String get helloGreeting;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A good day to look back at your love story.'**
  String get homeSubtitle;

  /// No description provided for @youveBeenTogetherFor.
  ///
  /// In en, this message translates to:
  /// **'YOU\'VE BEEN TOGETHER FOR'**
  String get youveBeenTogetherFor;

  /// No description provided for @daysOfUsSince.
  ///
  /// In en, this message translates to:
  /// **'days of us · since {date}'**
  String daysOfUsSince(String date);

  /// No description provided for @todayIsAnniversary.
  ///
  /// In en, this message translates to:
  /// **'Today is your anniversary ✨'**
  String get todayIsAnniversary;

  /// No description provided for @daysUntilNextAnniversary.
  ///
  /// In en, this message translates to:
  /// **'{count} days until your next anniversary'**
  String daysUntilNextAnniversary(int count);

  /// No description provided for @quickMomentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick moments'**
  String get quickMomentsTitle;

  /// No description provided for @quickMomentsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Shortcuts to revisit your story'**
  String get quickMomentsSubtitle;

  /// No description provided for @memoriesCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Memories'**
  String get memoriesCardTitle;

  /// No description provided for @viewAllPhotos.
  ///
  /// In en, this message translates to:
  /// **'View all photos'**
  String get viewAllPhotos;

  /// No description provided for @profileCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileCardTitle;

  /// No description provided for @updateInfo.
  ///
  /// In en, this message translates to:
  /// **'Update info'**
  String get updateInfo;

  /// No description provided for @milestoneCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Milestone'**
  String get milestoneCardTitle;

  /// No description provided for @loveInNumbersTitle.
  ///
  /// In en, this message translates to:
  /// **'Love in numbers'**
  String get loveInNumbersTitle;

  /// No description provided for @loveInNumbersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Little stats from your journey'**
  String get loveInNumbersSubtitle;

  /// No description provided for @daysTogether.
  ///
  /// In en, this message translates to:
  /// **'Days together'**
  String get daysTogether;

  /// No description provided for @daysUnit.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get daysUnit;

  /// No description provided for @memoriesSaved.
  ///
  /// In en, this message translates to:
  /// **'Memories saved'**
  String get memoriesSaved;

  /// No description provided for @photosUnit.
  ///
  /// In en, this message translates to:
  /// **'photos'**
  String get photosUnit;

  /// No description provided for @nextAnniversaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Next anniversary'**
  String get nextAnniversaryLabel;

  /// No description provided for @daysAway.
  ///
  /// In en, this message translates to:
  /// **'days away'**
  String get daysAway;

  /// No description provided for @nextMilestoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Next milestone'**
  String get nextMilestoneTitle;

  /// No description provided for @milestoneProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Milestone progress'**
  String get milestoneProgressTitle;

  /// No description provided for @milestoneProgressSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Gently approaching the next sweet number'**
  String get milestoneProgressSubtitle;

  /// No description provided for @recentMemoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent memories'**
  String get recentMemoriesTitle;

  /// No description provided for @addPhotosPrompt.
  ///
  /// In en, this message translates to:
  /// **'Add a few photos to start your love letter'**
  String get addPhotosPrompt;

  /// No description provided for @latestMomentsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A few of your latest moments together'**
  String get latestMomentsSubtitle;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @addPhotosEmpty.
  ///
  /// In en, this message translates to:
  /// **'Add a few photos to start filling this love letter.'**
  String get addPhotosEmpty;

  /// No description provided for @yourStorySoFar.
  ///
  /// In en, this message translates to:
  /// **'Your story so far'**
  String get yourStorySoFar;

  /// No description provided for @whenItAllBegan.
  ///
  /// In en, this message translates to:
  /// **'When it all began'**
  String get whenItAllBegan;

  /// No description provided for @whenItAllBeganSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{name1} & {name2} on {date}'**
  String whenItAllBeganSubtitle(String name1, String name2, String date);

  /// No description provided for @monthiversaries.
  ///
  /// In en, this message translates to:
  /// **'{count} monthiversaries'**
  String monthiversaries(int count);

  /// No description provided for @monthiversaryDesc.
  ///
  /// In en, this message translates to:
  /// **'Each month, another layer of understanding and tenderness.'**
  String get monthiversaryDesc;

  /// No description provided for @memoriesCaptured.
  ///
  /// In en, this message translates to:
  /// **'{count} memories captured'**
  String memoriesCaptured(int count);

  /// No description provided for @memoriesCapturedDesc.
  ///
  /// In en, this message translates to:
  /// **'Your library is becoming a quiet little album.'**
  String get memoriesCapturedDesc;

  /// No description provided for @loveNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Love note'**
  String get loveNoteLabel;

  /// No description provided for @loveNoteQuote.
  ///
  /// In en, this message translates to:
  /// **'\"{count} days isn\'t just time — it\'s every soft moment, every choice to stay, every little kindness we share.\"'**
  String loveNoteQuote(int count);

  /// No description provided for @milestoneReached.
  ///
  /// In en, this message translates to:
  /// **'You just reached a beautiful milestone ✨'**
  String get milestoneReached;

  /// No description provided for @onlyDaysUntilMilestone.
  ///
  /// In en, this message translates to:
  /// **'Only {count} days until your next milestone.'**
  String onlyDaysUntilMilestone(int count);

  /// No description provided for @nextMilestonePrefix.
  ///
  /// In en, this message translates to:
  /// **'Next: {label}'**
  String nextMilestonePrefix(String label);

  /// No description provided for @daysCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String daysCountLabel(int count);

  /// No description provided for @percentThere.
  ///
  /// In en, this message translates to:
  /// **'{percent}% there'**
  String percentThere(String percent);

  /// No description provided for @milestoneYearsOne.
  ///
  /// In en, this message translates to:
  /// **'{count} year'**
  String milestoneYearsOne(int count);

  /// No description provided for @milestoneYearsMany.
  ///
  /// In en, this message translates to:
  /// **'{count} years'**
  String milestoneYearsMany(int count);

  /// No description provided for @milestoneMonthsOne.
  ///
  /// In en, this message translates to:
  /// **'{count} month'**
  String milestoneMonthsOne(int count);

  /// No description provided for @milestoneMonthsMany.
  ///
  /// In en, this message translates to:
  /// **'{count} months'**
  String milestoneMonthsMany(int count);

  /// No description provided for @milestoneDaysLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String milestoneDaysLabel(int count);

  /// No description provided for @privateGalleryBadge.
  ///
  /// In en, this message translates to:
  /// **'PRIVATE GALLERY'**
  String get privateGalleryBadge;

  /// No description provided for @galleryTitle.
  ///
  /// In en, this message translates to:
  /// **'Photo Library'**
  String get galleryTitle;

  /// No description provided for @gallerySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Swipe up to quickly bring up the post frame and manage memories.'**
  String get gallerySubtitle;

  /// No description provided for @addCaptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Add caption'**
  String get addCaptionTitle;

  /// No description provided for @addCaptionHint.
  ///
  /// In en, this message translates to:
  /// **'Write a few lines about this moment...'**
  String get addCaptionHint;

  /// No description provided for @addCaptionOptionalTitle.
  ///
  /// In en, this message translates to:
  /// **'Add caption (optional)'**
  String get addCaptionOptionalTitle;

  /// No description provided for @addCaptionOptionalHint.
  ///
  /// In en, this message translates to:
  /// **'Write something truly memorable...'**
  String get addCaptionOptionalHint;

  /// No description provided for @editCaptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit caption'**
  String get editCaptionTitle;

  /// No description provided for @editCaptionHint.
  ///
  /// In en, this message translates to:
  /// **'How memorable was this moment?'**
  String get editCaptionHint;

  /// No description provided for @deletePhotoTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this photo?'**
  String get deletePhotoTitle;

  /// No description provided for @deletePhotoContent.
  ///
  /// In en, this message translates to:
  /// **'This moment will be removed from your shared diary.'**
  String get deletePhotoContent;

  /// No description provided for @keepPhotoBtn.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get keepPhotoBtn;

  /// No description provided for @deletePhotoBtn.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deletePhotoBtn;

  /// No description provided for @postedByLabel.
  ///
  /// In en, this message translates to:
  /// **'Posted by {name}'**
  String postedByLabel(String name);

  /// No description provided for @momentsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} moments'**
  String momentsCount(int count);

  /// No description provided for @daysTogetherCount.
  ///
  /// In en, this message translates to:
  /// **'{count} days together'**
  String daysTogetherCount(int count);

  /// No description provided for @privateFeedLabel.
  ///
  /// In en, this message translates to:
  /// **'Private feed for you two'**
  String get privateFeedLabel;

  /// No description provided for @postNewPhotoBtn.
  ///
  /// In en, this message translates to:
  /// **'Post new photo'**
  String get postNewPhotoBtn;

  /// No description provided for @addMultipleBtn.
  ///
  /// In en, this message translates to:
  /// **'Add multiple'**
  String get addMultipleBtn;

  /// No description provided for @addNewMemoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a new memory today'**
  String get addNewMemoryTitle;

  /// No description provided for @whatNewToday.
  ///
  /// In en, this message translates to:
  /// **'what\'s new today?'**
  String get whatNewToday;

  /// No description provided for @composerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Turn the library into a private and memorable love newsfeed.'**
  String get composerSubtitle;

  /// No description provided for @compactCaption.
  ///
  /// In en, this message translates to:
  /// **'{count} moments · Swipe to expand post frame'**
  String compactCaption(int count);

  /// No description provided for @todayInLoveBadge.
  ///
  /// In en, this message translates to:
  /// **'TODAY IN LOVE'**
  String get todayInLoveBadge;

  /// No description provided for @storyStripBadge.
  ///
  /// In en, this message translates to:
  /// **'STORY STRIP'**
  String get storyStripBadge;

  /// No description provided for @memoriesTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'Memories today'**
  String get memoriesTodayTitle;

  /// No description provided for @recentPhotosTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent photos'**
  String get recentPhotosTitle;

  /// No description provided for @memoriesTodaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Moments saved on this exact date, tender and personal.'**
  String get memoriesTodaySubtitle;

  /// No description provided for @recentPhotosSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A small story strip for a quick look at your latest moments.'**
  String get recentPhotosSubtitle;

  /// No description provided for @memoryBadge.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get memoryBadge;

  /// No description provided for @newBadge.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newBadge;

  /// No description provided for @momentLabel.
  ///
  /// In en, this message translates to:
  /// **'Moment #{number}'**
  String momentLabel(int number);

  /// No description provided for @editCaptionAction.
  ///
  /// In en, this message translates to:
  /// **'Edit caption'**
  String get editCaptionAction;

  /// No description provided for @deletePhotoAction.
  ///
  /// In en, this message translates to:
  /// **'Delete photo'**
  String get deletePhotoAction;

  /// No description provided for @editAction.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editAction;

  /// No description provided for @deleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteAction;

  /// No description provided for @startNewfeedTitle.
  ///
  /// In en, this message translates to:
  /// **'Start building a memory newsfeed'**
  String get startNewfeedTitle;

  /// No description provided for @postFirstMomentOf.
  ///
  /// In en, this message translates to:
  /// **'Post the first moment of'**
  String get postFirstMomentOf;

  /// No description provided for @emptyFeedContent.
  ///
  /// In en, this message translates to:
  /// **'Once you add photos, this library will become a private love newsfeed with timelines that are easy to view and feel.'**
  String get emptyFeedContent;

  /// No description provided for @postFirstPhotoBtn.
  ///
  /// In en, this message translates to:
  /// **'Post first photo'**
  String get postFirstPhotoBtn;

  /// No description provided for @photoAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Photo added successfully!'**
  String get photoAddedSuccess;

  /// No description provided for @photoAddError.
  ///
  /// In en, this message translates to:
  /// **'Could not post photo right now.'**
  String get photoAddError;

  /// No description provided for @multiplePhotosAdded.
  ///
  /// In en, this message translates to:
  /// **'Added {count} photos!'**
  String multiplePhotosAdded(int count);

  /// No description provided for @captionUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Caption updated'**
  String get captionUpdatedSuccess;

  /// No description provided for @captionUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Could not update caption.'**
  String get captionUpdateError;

  /// No description provided for @photoDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Photo deleted'**
  String get photoDeletedSuccess;

  /// No description provided for @photoDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Could not delete photo right now.'**
  String get photoDeleteError;

  /// No description provided for @youTwoLabel.
  ///
  /// In en, this message translates to:
  /// **'You two'**
  String get youTwoLabel;

  /// No description provided for @syncingLibrary.
  ///
  /// In en, this message translates to:
  /// **'Syncing library...'**
  String get syncingLibrary;

  /// No description provided for @uploadingPhoto.
  ///
  /// In en, this message translates to:
  /// **'Uploading photo...'**
  String get uploadingPhoto;

  /// No description provided for @deletingPhoto.
  ///
  /// In en, this message translates to:
  /// **'Deleting photo...'**
  String get deletingPhoto;

  /// No description provided for @updatingCaption.
  ///
  /// In en, this message translates to:
  /// **'Updating caption...'**
  String get updatingCaption;

  /// No description provided for @feedDateFormat.
  ///
  /// In en, this message translates to:
  /// **'dd MMM • HH:mm'**
  String get feedDateFormat;

  /// No description provided for @momentNumberFallback.
  ///
  /// In en, this message translates to:
  /// **'Moment #{index}'**
  String momentNumberFallback(int index);

  /// No description provided for @loveProfileBadge.
  ///
  /// In en, this message translates to:
  /// **'LOVE PROFILE'**
  String get loveProfileBadge;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Your profile'**
  String get profileTitle;

  /// No description provided for @profileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A private corner to look back on your love journey, milestones, and memory album.'**
  String get profileSubtitle;

  /// No description provided for @todayIsAnniversaryProfile.
  ///
  /// In en, this message translates to:
  /// **'Today is your anniversary ✨'**
  String get todayIsAnniversaryProfile;

  /// No description provided for @daysUntilAnniversaryProfile.
  ///
  /// In en, this message translates to:
  /// **'{count} days until the next anniversary'**
  String daysUntilAnniversaryProfile(int count);

  /// No description provided for @khoanhKhacCount.
  ///
  /// In en, this message translates to:
  /// **'{count} moments'**
  String khoanhKhacCount(int count);

  /// No description provided for @privateDiaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Private diary'**
  String get privateDiaryLabel;

  /// No description provided for @loveMilestonesLabel.
  ///
  /// In en, this message translates to:
  /// **'Love milestones'**
  String get loveMilestonesLabel;

  /// No description provided for @journeySnapshotTitle.
  ///
  /// In en, this message translates to:
  /// **'Journey snapshot'**
  String get journeySnapshotTitle;

  /// No description provided for @journeySnapshotSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The standout numbers of your relationship, presented cleanly, modernly, and clearly.'**
  String get journeySnapshotSubtitle;

  /// No description provided for @yearsTogether.
  ///
  /// In en, this message translates to:
  /// **'Years together'**
  String get yearsTogether;

  /// No description provided for @monthsRemaining.
  ///
  /// In en, this message translates to:
  /// **'Months remaining'**
  String get monthsRemaining;

  /// No description provided for @totalDaysLabel.
  ///
  /// In en, this message translates to:
  /// **'Total days'**
  String get totalDaysLabel;

  /// No description provided for @memoriesSavedLabel.
  ///
  /// In en, this message translates to:
  /// **'Memories saved'**
  String get memoriesSavedLabel;

  /// No description provided for @infoAndRhythmTitle.
  ///
  /// In en, this message translates to:
  /// **'Info & rhythm'**
  String get infoAndRhythmTitle;

  /// No description provided for @infoAndRhythmSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A clearer look at your start date, album, and upcoming milestones.'**
  String get infoAndRhythmSubtitle;

  /// No description provided for @loveStartDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Love start date'**
  String get loveStartDateLabel;

  /// No description provided for @yourInviteCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Your account invite code'**
  String get yourInviteCodeLabel;

  /// No description provided for @dayStreakLabel.
  ///
  /// In en, this message translates to:
  /// **'Day streak'**
  String get dayStreakLabel;

  /// No description provided for @dayStreakValue.
  ///
  /// In en, this message translates to:
  /// **'{count} days and still going'**
  String dayStreakValue(int count);

  /// No description provided for @memoryAlbumLabel.
  ///
  /// In en, this message translates to:
  /// **'Memory album'**
  String get memoryAlbumLabel;

  /// No description provided for @memoryAlbumValue.
  ///
  /// In en, this message translates to:
  /// **'{count} photos saved in private album'**
  String memoryAlbumValue(int count);

  /// No description provided for @upcomingMilestoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Upcoming milestone'**
  String get upcomingMilestoneLabel;

  /// No description provided for @todaySpecialMsg.
  ///
  /// In en, this message translates to:
  /// **'Today is a very special day for you two'**
  String get todaySpecialMsg;

  /// No description provided for @daysUntilNextMsg.
  ///
  /// In en, this message translates to:
  /// **'{count} more days until the next anniversary'**
  String daysUntilNextMsg(int count);

  /// No description provided for @customizeProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Customize profile'**
  String get customizeProfileTitle;

  /// No description provided for @customizeProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update names, anniversary date, and couple photo so the profile always reflects your current journey.'**
  String get customizeProfileSubtitle;

  /// No description provided for @editOurStoryBtn.
  ///
  /// In en, this message translates to:
  /// **'Edit our story'**
  String get editOurStoryBtn;

  /// No description provided for @proTipLabel.
  ///
  /// In en, this message translates to:
  /// **'Pro tip'**
  String get proTipLabel;

  /// No description provided for @proTipContent.
  ///
  /// In en, this message translates to:
  /// **'A bright, close-up couple photo with good breathing room will make the hero section look much more polished.'**
  String get proTipContent;

  /// No description provided for @dataManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Data management'**
  String get dataManagementTitle;

  /// No description provided for @dataManagementDesc.
  ///
  /// In en, this message translates to:
  /// **'One person can only clear cache on this device or leave the couple. To delete shared data, both must confirm.'**
  String get dataManagementDesc;

  /// No description provided for @clearLocalDataBtn.
  ///
  /// In en, this message translates to:
  /// **'Clear data on this device'**
  String get clearLocalDataBtn;

  /// No description provided for @localFallbackWarning.
  ///
  /// In en, this message translates to:
  /// **'App is in local fallback mode so safe individual cache clearing is not yet supported. You can leave the current local couple if you want to reset.'**
  String get localFallbackWarning;

  /// No description provided for @leaveCoupleBtn.
  ///
  /// In en, this message translates to:
  /// **'Leave couple'**
  String get leaveCoupleBtn;

  /// No description provided for @clearDataNote.
  ///
  /// In en, this message translates to:
  /// **'Deleting all shared data is currently not allowed from one side. In the next sprint, this will be changed to a flow requiring both to confirm.'**
  String get clearDataNote;

  /// No description provided for @clearLocalDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear data on this device'**
  String get clearLocalDialogTitle;

  /// No description provided for @clearLocalDialogContent.
  ///
  /// In en, this message translates to:
  /// **'This only clears the cache on the current device. Shared data on Firebase is preserved and will reload when needed.'**
  String get clearLocalDialogContent;

  /// No description provided for @clearLocalActionBtn.
  ///
  /// In en, this message translates to:
  /// **'Clear local'**
  String get clearLocalActionBtn;

  /// No description provided for @leaveCoupleDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave couple'**
  String get leaveCoupleDialogTitle;

  /// No description provided for @leaveCoupleDialogContent.
  ///
  /// In en, this message translates to:
  /// **'You will leave the current couple space. The other person keeps the shared data. You cannot delete all shared data from one side.'**
  String get leaveCoupleDialogContent;

  /// No description provided for @leaveCoupleActionBtn.
  ///
  /// In en, this message translates to:
  /// **'Leave couple'**
  String get leaveCoupleActionBtn;

  /// No description provided for @localDataClearedMsg.
  ///
  /// In en, this message translates to:
  /// **'Local data on this device has been cleared. Shared data on cloud is preserved.'**
  String get localDataClearedMsg;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the app display language'**
  String get languageSubtitle;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @languageSystemDesc.
  ///
  /// In en, this message translates to:
  /// **'Follow device language'**
  String get languageSystemDesc;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageVietnamese.
  ///
  /// In en, this message translates to:
  /// **'Tiếng Việt'**
  String get languageVietnamese;

  /// No description provided for @loadingCoupleInfo.
  ///
  /// In en, this message translates to:
  /// **'Loading couple info...'**
  String get loadingCoupleInfo;

  /// No description provided for @savingCoupleSpace.
  ///
  /// In en, this message translates to:
  /// **'Saving couple space...'**
  String get savingCoupleSpace;

  /// No description provided for @connectingCouple.
  ///
  /// In en, this message translates to:
  /// **'Connecting couple...'**
  String get connectingCouple;

  /// No description provided for @updatingCoupleInfo.
  ///
  /// In en, this message translates to:
  /// **'Updating couple info...'**
  String get updatingCoupleInfo;

  String get welcomeBackBadge;

  String get createAccountBadge;

  String get loveHomeBadge;

  String get coupleOnboardingBadge;

  String get editCoupleBadge;

  String get deleteAccountBtn;

  String get deleteAccountTitle;

  String get deleteAccountDesc;

  String get deleteAccountDialogTitle;

  String get deleteAccountDialogContent;

  String get deleteAccountConfirmBtn;

  String get deleteAccountSuccessMsg;

  String get deleteAccountRequiresReloginMsg;

  String get privacyPolicyLabel;

  String get privacyDisclosure;

  String get signOutBtn;

  String get signOutDialogTitle;

  String get signOutDialogContent;

  String get signOutConfirmBtn;

  String get agreeToPrivacyPolicy;

  String get mustAgreeToPrivacyPolicy;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

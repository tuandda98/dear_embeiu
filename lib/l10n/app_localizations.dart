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

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

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
  /// **'Refine the story of\n{me} ❤️ {partner}'**
  String setupEditTitle(String me, String partner);

  /// No description provided for @setupEditTitleGeneric.
  ///
  /// In en, this message translates to:
  /// **'Refine\nyour story'**
  String get setupEditTitleGeneric;

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

  /// No description provided for @navChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get navChat;

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

  /// No description provided for @chatBadge.
  ///
  /// In en, this message translates to:
  /// **'JUST THE TWO OF US'**
  String get chatBadge;

  /// No description provided for @chatHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Where the two of you talk about everything.'**
  String get chatHeaderSubtitle;

  /// No description provided for @chatEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'No messages yet — send your love the first one 💬'**
  String get chatEmptyHint;

  /// No description provided for @chatComposerHint.
  ///
  /// In en, this message translates to:
  /// **'Message your love…'**
  String get chatComposerHint;

  /// No description provided for @chatSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send your message. Please try again.'**
  String get chatSendFailed;

  /// No description provided for @chatSendSemantics.
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get chatSendSemantics;

  /// No description provided for @chatSending.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get chatSending;

  /// No description provided for @chatUnreadDotSemantics.
  ///
  /// In en, this message translates to:
  /// **'New message waiting'**
  String get chatUnreadDotSemantics;

  /// No description provided for @chatWaitingPartnerTitle.
  ///
  /// In en, this message translates to:
  /// **'One seat is still empty'**
  String get chatWaitingPartnerTitle;

  /// No description provided for @chatWaitingPartnerBody.
  ///
  /// In en, this message translates to:
  /// **'Invite your partner to pair up and start your private chat.'**
  String get chatWaitingPartnerBody;

  /// No description provided for @chatWaitingPartnerCta.
  ///
  /// In en, this message translates to:
  /// **'Invite to pair'**
  String get chatWaitingPartnerCta;

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

  /// No description provided for @homeGreetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning,'**
  String get homeGreetingMorning;

  /// No description provided for @homeGreetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon,'**
  String get homeGreetingAfternoon;

  /// No description provided for @homeGreetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening,'**
  String get homeGreetingEvening;

  /// No description provided for @homeGreetingNight.
  ///
  /// In en, this message translates to:
  /// **'Up late,'**
  String get homeGreetingNight;

  /// No description provided for @homeGreetingTeaser1.
  ///
  /// In en, this message translates to:
  /// **'Send them a big warm hug 🤗'**
  String get homeGreetingTeaser1;

  /// No description provided for @homeGreetingTeaser2.
  ///
  /// In en, this message translates to:
  /// **'Said \"I love you\" today? 💕'**
  String get homeGreetingTeaser2;

  /// No description provided for @homeGreetingTeaser3.
  ///
  /// In en, this message translates to:
  /// **'Send them a cute photo 📸'**
  String get homeGreetingTeaser3;

  /// No description provided for @homeGreetingTeaser4.
  ///
  /// In en, this message translates to:
  /// **'They can\'t wait to hear from you 🕊️'**
  String get homeGreetingTeaser4;

  /// No description provided for @homeGreetingTeaser5.
  ///
  /// In en, this message translates to:
  /// **'Don\'t forget today\'s question ✨'**
  String get homeGreetingTeaser5;

  /// No description provided for @homeGreetingTeaser6.
  ///
  /// In en, this message translates to:
  /// **'Send something sweet their way 🍯'**
  String get homeGreetingTeaser6;

  /// No description provided for @homeGreetingTeaser7.
  ///
  /// In en, this message translates to:
  /// **'Say a little thank-you today 💞'**
  String get homeGreetingTeaser7;

  /// No description provided for @homeGreetingTeaser8.
  ///
  /// In en, this message translates to:
  /// **'A calm moment together is enough 🍃'**
  String get homeGreetingTeaser8;

  /// No description provided for @homeGreetingTeaser9.
  ///
  /// In en, this message translates to:
  /// **'A beautiful day to love 💖'**
  String get homeGreetingTeaser9;

  /// No description provided for @homeGreetingTeaser10.
  ///
  /// In en, this message translates to:
  /// **'Tell them you miss them 💭'**
  String get homeGreetingTeaser10;

  /// No description provided for @homeGreetingTeaser11.
  ///
  /// In en, this message translates to:
  /// **'Keep writing your love story together ✍️'**
  String get homeGreetingTeaser11;

  /// No description provided for @homeGreetingTeaser12.
  ///
  /// In en, this message translates to:
  /// **'Keep your love streak going 🔥'**
  String get homeGreetingTeaser12;

  /// No description provided for @homeTodaySectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Today, together'**
  String get homeTodaySectionTitle;

  /// No description provided for @dailyTapToAnswer.
  ///
  /// In en, this message translates to:
  /// **'Tap to answer…'**
  String get dailyTapToAnswer;

  /// No description provided for @dailyPartnerAnsweredTeaser.
  ///
  /// In en, this message translates to:
  /// **'{name} has answered 👀'**
  String dailyPartnerAnsweredTeaser(String name);

  /// No description provided for @dailyAnswerToReveal.
  ///
  /// In en, this message translates to:
  /// **'Answer to unlock their reply'**
  String get dailyAnswerToReveal;

  /// No description provided for @dailyBothAnsweredToday.
  ///
  /// In en, this message translates to:
  /// **'You both answered today'**
  String get dailyBothAnsweredToday;

  /// No description provided for @dailyReadAgain.
  ///
  /// In en, this message translates to:
  /// **'Read again'**
  String get dailyReadAgain;

  /// No description provided for @dailyCollapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get dailyCollapse;

  /// No description provided for @loveNoteSealedTitle.
  ///
  /// In en, this message translates to:
  /// **'A new note from {name}'**
  String loveNoteSealedTitle(String name);

  /// No description provided for @loveNoteSealedTap.
  ///
  /// In en, this message translates to:
  /// **'Tap to open 💌'**
  String get loveNoteSealedTap;

  /// No description provided for @loveNoteNewBadge.
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get loveNoteNewBadge;

  /// No description provided for @loveNoteComposeCta.
  ///
  /// In en, this message translates to:
  /// **'Compose a message'**
  String get loveNoteComposeCta;

  /// No description provided for @loveNoteSheetTitleTo.
  ///
  /// In en, this message translates to:
  /// **'Send a note to {name}'**
  String loveNoteSheetTitleTo(String name);

  /// No description provided for @journalLinkShort.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get journalLinkShort;

  /// No description provided for @milestoneNextLabel.
  ///
  /// In en, this message translates to:
  /// **'Milestone: {label}'**
  String milestoneNextLabel(String label);

  /// No description provided for @milestoneDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} days left'**
  String milestoneDaysLeft(int count);

  /// No description provided for @milestoneTodayLabel.
  ///
  /// In en, this message translates to:
  /// **'today 🎉'**
  String get milestoneTodayLabel;

  /// No description provided for @onThisDayShort.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 year ago 💞} other{{count} years ago 💞}}'**
  String onThisDayShort(int count);

  /// No description provided for @counterBgSwipeHint.
  ///
  /// In en, this message translates to:
  /// **'Swipe to change the photo'**
  String get counterBgSwipeHint;

  /// No description provided for @dailyQuestionPairedFirst.
  ///
  /// In en, this message translates to:
  /// **'Once you\'re paired, you\'ll answer a question like this together every day 💞'**
  String get dailyQuestionPairedFirst;

  /// No description provided for @loveNoteHistoryLinkShort.
  ///
  /// In en, this message translates to:
  /// **'Past notes'**
  String get loveNoteHistoryLinkShort;

  /// No description provided for @loveNoteReplyCta.
  ///
  /// In en, this message translates to:
  /// **'Reply…'**
  String get loveNoteReplyCta;

  /// No description provided for @loveNoteSendFirstCta.
  ///
  /// In en, this message translates to:
  /// **'Send the first note…'**
  String get loveNoteSendFirstCta;

  /// No description provided for @loveNoteStartChat.
  ///
  /// In en, this message translates to:
  /// **'No notes yet — send each other the first one 💌'**
  String get loveNoteStartChat;

  /// No description provided for @loveNoteYouLabel.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get loveNoteYouLabel;

  /// No description provided for @notificationBellLabel.
  ///
  /// In en, this message translates to:
  /// **'Notifications, {count} unread'**
  String notificationBellLabel(int count);

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

  /// No description provided for @addMemoryCta.
  ///
  /// In en, this message translates to:
  /// **'Add a memory'**
  String get addMemoryCta;

  /// No description provided for @addMemoryCtaSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Post a new photo for you both to keep'**
  String get addMemoryCtaSubtitle;

  /// No description provided for @cinemaCardSemantics.
  ///
  /// In en, this message translates to:
  /// **'Memory: {caption}, photo {index} of {total}. Tap to view full screen.'**
  String cinemaCardSemantics(String caption, int index, int total);

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
  /// **'Days'**
  String get daysUnit;

  /// No description provided for @hoursShort.
  ///
  /// In en, this message translates to:
  /// **'hr'**
  String get hoursShort;

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get minutesShort;

  /// No description provided for @secondsShort.
  ///
  /// In en, this message translates to:
  /// **'sec'**
  String get secondsShort;

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

  /// No description provided for @onThisDayTitle.
  ///
  /// In en, this message translates to:
  /// **'On this day, {count, plural, =1{1 year ago} other{{count} years ago}} 💞'**
  String onThisDayTitle(int count);

  /// No description provided for @onThisDaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'A memory from this very day'**
  String get onThisDaySubtitle;

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

  /// No description provided for @loveNoteFromPartner.
  ///
  /// In en, this message translates to:
  /// **'Note from {name}'**
  String loveNoteFromPartner(String name);

  /// No description provided for @loveNoteEmptyFromPartner.
  ///
  /// In en, this message translates to:
  /// **'No note from {name} yet'**
  String loveNoteEmptyFromPartner(String name);

  /// No description provided for @loveNoteWriteCta.
  ///
  /// In en, this message translates to:
  /// **'Write a note'**
  String get loveNoteWriteCta;

  /// No description provided for @loveNoteEditCta.
  ///
  /// In en, this message translates to:
  /// **'Edit your note'**
  String get loveNoteEditCta;

  /// No description provided for @loveNoteWaitingPartner.
  ///
  /// In en, this message translates to:
  /// **'Invite your partner so you can leave little notes for each other.'**
  String get loveNoteWaitingPartner;

  /// No description provided for @loveNoteSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Your love note'**
  String get loveNoteSheetTitle;

  /// No description provided for @loveNoteSheetHint.
  ///
  /// In en, this message translates to:
  /// **'Write something sweet for your partner…'**
  String get loveNoteSheetHint;

  /// No description provided for @loveNoteCharCount.
  ///
  /// In en, this message translates to:
  /// **'{count}/140'**
  String loveNoteCharCount(int count);

  /// No description provided for @loveNoteSaved.
  ///
  /// In en, this message translates to:
  /// **'Your note was sent 💞'**
  String get loveNoteSaved;

  /// No description provided for @loveNoteSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send the note — please try again.'**
  String get loveNoteSendFailed;

  /// No description provided for @loveNoteHistoryCta.
  ///
  /// In en, this message translates to:
  /// **'See past notes'**
  String get loveNoteHistoryCta;

  /// No description provided for @loveNoteHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Note journal'**
  String get loveNoteHistoryTitle;

  /// No description provided for @loveNoteHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Every note you two have left for each other.'**
  String get loveNoteHistorySubtitle;

  /// No description provided for @loveNoteHistoryBadge.
  ///
  /// In en, this message translates to:
  /// **'LOVE NOTES'**
  String get loveNoteHistoryBadge;

  /// No description provided for @loveNoteHistoryHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Every note the two of you have sent.'**
  String get loveNoteHistoryHeaderSubtitle;

  /// No description provided for @loveNoteHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notes saved yet. The ones you send each other will be kept here.'**
  String get loveNoteHistoryEmpty;

  /// No description provided for @loveNoteJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get loveNoteJustNow;

  /// No description provided for @loveNoteMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute ago} other{{count} minutes ago}}'**
  String loveNoteMinutesAgo(int count);

  /// No description provided for @loveNoteHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour ago} other{{count} hours ago}}'**
  String loveNoteHoursAgo(int count);

  /// No description provided for @loveNoteDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day ago} other{{count} days ago}}'**
  String loveNoteDaysAgo(int count);

  /// Faint hint shown on the reaction bar before anyone reacts
  ///
  /// In en, this message translates to:
  /// **'React to this moment'**
  String get reactionHint;

  /// Label on the current user's own reaction chip
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get reactionYouLabel;

  /// Tooltip / a11y label for the heart button when adding a reaction
  ///
  /// In en, this message translates to:
  /// **'React'**
  String get reactionAddTooltip;

  /// Tooltip / a11y label for long-pressing to change the reaction emoji
  ///
  /// In en, this message translates to:
  /// **'Change reaction'**
  String get reactionChangeTooltip;

  /// Tooltip / a11y label for the heart button when it would remove the user's reaction
  ///
  /// In en, this message translates to:
  /// **'Remove reaction'**
  String get reactionRemoveTooltip;

  /// SnackBar shown when writing a reaction fails and was rolled back
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t react, try again'**
  String get reactionErrorRetry;

  /// a11y label / tooltip for the partner's reaction chip
  ///
  /// In en, this message translates to:
  /// **'{name} reacted {emoji}'**
  String reactionPartnerReacted(String name, String emoji);

  /// a11y label when both members have reacted to a photo
  ///
  /// In en, this message translates to:
  /// **'You both reacted 💞'**
  String get reactionBothLabel;

  /// No description provided for @dailyQuestionLabel.
  ///
  /// In en, this message translates to:
  /// **'Today\'s question'**
  String get dailyQuestionLabel;

  /// No description provided for @dailyQuestionHint.
  ///
  /// In en, this message translates to:
  /// **'Write your answer…'**
  String get dailyQuestionHint;

  /// No description provided for @dailyQuestionCharCount.
  ///
  /// In en, this message translates to:
  /// **'{count}/280'**
  String dailyQuestionCharCount(int count);

  /// No description provided for @dailyQuestionSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get dailyQuestionSend;

  /// No description provided for @dailyQuestionYourAnswerLabel.
  ///
  /// In en, this message translates to:
  /// **'Your answer'**
  String get dailyQuestionYourAnswerLabel;

  /// No description provided for @dailyQuestionAnsweredWaiting.
  ///
  /// In en, this message translates to:
  /// **'Answered ✓ — waiting for {name}'**
  String dailyQuestionAnsweredWaiting(String name);

  /// No description provided for @dailyQuestionPartnerAnswerLabel.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s answer'**
  String dailyQuestionPartnerAnswerLabel(String name);

  /// No description provided for @dailyQuestionWaitingPartner.
  ///
  /// In en, this message translates to:
  /// **'It will unlock once your partner joins and answers too.'**
  String get dailyQuestionWaitingPartner;

  /// No description provided for @dailyQuestionRevealHint.
  ///
  /// In en, this message translates to:
  /// **'You both answered — here\'s what you each said 💞'**
  String get dailyQuestionRevealHint;

  /// No description provided for @dailyQuestionSent.
  ///
  /// In en, this message translates to:
  /// **'Your answer was sent 💞'**
  String get dailyQuestionSent;

  /// No description provided for @journalEntryCta.
  ///
  /// In en, this message translates to:
  /// **'Open journal'**
  String get journalEntryCta;

  /// No description provided for @journalScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Question journal'**
  String get journalScreenTitle;

  /// No description provided for @journalScreenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The questions you\'ve both answered.'**
  String get journalScreenSubtitle;

  /// No description provided for @journalBadge.
  ///
  /// In en, this message translates to:
  /// **'QUESTION JOURNAL'**
  String get journalBadge;

  /// No description provided for @journalHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The questions you two have answered together.'**
  String get journalHeaderSubtitle;

  /// No description provided for @journalSettingsTile.
  ///
  /// In en, this message translates to:
  /// **'Question journal'**
  String get journalSettingsTile;

  /// No description provided for @journalSettingsSection.
  ///
  /// In en, this message translates to:
  /// **'Memories'**
  String get journalSettingsSection;

  /// No description provided for @journalYourAnswerLabel.
  ///
  /// In en, this message translates to:
  /// **'YOUR ANSWER'**
  String get journalYourAnswerLabel;

  /// No description provided for @journalPartnerAnswerLabel.
  ///
  /// In en, this message translates to:
  /// **'{name}\'S ANSWER'**
  String journalPartnerAnswerLabel(String name);

  /// No description provided for @journalLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get journalLoadMore;

  /// No description provided for @journalEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No question memories yet'**
  String get journalEmptyTitle;

  /// No description provided for @journalEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'When you both answer a daily question, that moment gets saved here.'**
  String get journalEmptyBody;

  /// No description provided for @journalEmptyCta.
  ///
  /// In en, this message translates to:
  /// **'Answer today\'s question'**
  String get journalEmptyCta;

  /// No description provided for @journalEmptyNoPartnerBody.
  ///
  /// In en, this message translates to:
  /// **'Invite your partner to start your journal together.'**
  String get journalEmptyNoPartnerBody;

  /// No description provided for @journalEmptyNoPartnerCta.
  ///
  /// In en, this message translates to:
  /// **'Invite partner'**
  String get journalEmptyNoPartnerCta;

  /// No description provided for @journalErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the journal'**
  String get journalErrorTitle;

  /// No description provided for @journalRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get journalRetry;

  /// No description provided for @loveNoteYourNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'YOUR NOTE'**
  String get loveNoteYourNoteLabel;

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
  /// **'PHOTO LIBRARY'**
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
  /// **'Take photo'**
  String get postNewPhotoBtn;

  /// No description provided for @addMultipleBtn.
  ///
  /// In en, this message translates to:
  /// **'Add photos'**
  String get addMultipleBtn;

  /// No description provided for @cameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the camera. Try again or check camera permission (the Simulator has no camera — use a real device).'**
  String get cameraUnavailable;

  /// No description provided for @galleryDraftTitle.
  ///
  /// In en, this message translates to:
  /// **'Review & post'**
  String get galleryDraftTitle;

  /// No description provided for @galleryDraftCaptionHint.
  ///
  /// In en, this message translates to:
  /// **'Add a shared caption (optional)…'**
  String get galleryDraftCaptionHint;

  /// No description provided for @galleryDraftEmpty.
  ///
  /// In en, this message translates to:
  /// **'All photos removed.'**
  String get galleryDraftEmpty;

  /// No description provided for @galleryDraftPostBtn.
  ///
  /// In en, this message translates to:
  /// **'Post {count} photos'**
  String galleryDraftPostBtn(int count);

  /// No description provided for @createPostTitle.
  ///
  /// In en, this message translates to:
  /// **'New memory'**
  String get createPostTitle;

  /// No description provided for @createPostBadge.
  ///
  /// In en, this message translates to:
  /// **'NEW MEMORY'**
  String get createPostBadge;

  /// No description provided for @createPostAuthorMeta.
  ///
  /// In en, this message translates to:
  /// **'Posted by {name} · {when}'**
  String createPostAuthorMeta(String name, String when);

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @createPostCaptionHint.
  ///
  /// In en, this message translates to:
  /// **'What\'s happening with you two today?…'**
  String get createPostCaptionHint;

  /// No description provided for @createPostAddMore.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get createPostAddMore;

  /// No description provided for @createPostAddFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Add from library'**
  String get createPostAddFromLibrary;

  /// No description provided for @createPostPhotoCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} photo} other{{count} photos}}'**
  String createPostPhotoCount(int count);

  /// No description provided for @createPostBtn.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get createPostBtn;

  /// No description provided for @createPostRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get createPostRemovePhoto;

  /// No description provided for @createPostDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard this memory?'**
  String get createPostDiscardTitle;

  /// No description provided for @createPostDiscardMessage.
  ///
  /// In en, this message translates to:
  /// **'The caption you just wrote won\'t be saved.'**
  String get createPostDiscardMessage;

  /// No description provided for @createPostDiscardConfirm.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get createPostDiscardConfirm;

  /// No description provided for @createPostDiscardKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get createPostDiscardKeep;

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

  /// No description provided for @reportPhotoAction.
  ///
  /// In en, this message translates to:
  /// **'Report photo'**
  String get reportPhotoAction;

  /// No description provided for @reportPhotoTitle.
  ///
  /// In en, this message translates to:
  /// **'Report photo'**
  String get reportPhotoTitle;

  /// No description provided for @reportPhotoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us what\'s wrong with this photo.'**
  String get reportPhotoSubtitle;

  /// No description provided for @reportReasonInappropriate.
  ///
  /// In en, this message translates to:
  /// **'Inappropriate content'**
  String get reportReasonInappropriate;

  /// No description provided for @reportReasonSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam or scam'**
  String get reportReasonSpam;

  /// No description provided for @reportReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get reportReasonOther;

  /// No description provided for @reportCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get reportCancel;

  /// No description provided for @reportSentConfirm.
  ///
  /// In en, this message translates to:
  /// **'Report sent, thank you.'**
  String get reportSentConfirm;

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

  /// No description provided for @uploadingPhotoProgress.
  ///
  /// In en, this message translates to:
  /// **'Uploading {current}/{total}...'**
  String uploadingPhotoProgress(int current, int total);

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

  /// No description provided for @galleryLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load photos'**
  String get galleryLoadErrorTitle;

  /// No description provided for @galleryLoadErrorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your memories are safe — we just couldn\'t reach them right now.'**
  String get galleryLoadErrorSubtitle;

  /// No description provided for @galleryRetryBtn.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get galleryRetryBtn;

  /// No description provided for @multiPhotosResultPartial.
  ///
  /// In en, this message translates to:
  /// **'Posted {success}/{total}, {failed} failed'**
  String multiPhotosResultPartial(int success, int total, int failed);

  /// No description provided for @feedDateFormat.
  ///
  /// In en, this message translates to:
  /// **'dd MMM • HH:mm'**
  String get feedDateFormat;

  /// No description provided for @fullDateFormat.
  ///
  /// In en, this message translates to:
  /// **'MMM d, y'**
  String get fullDateFormat;

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

  /// No description provided for @yearsTogether.
  ///
  /// In en, this message translates to:
  /// **'Years'**
  String get yearsTogether;

  /// No description provided for @monthsRemaining.
  ///
  /// In en, this message translates to:
  /// **'Months'**
  String get monthsRemaining;

  /// No description provided for @totalDaysLabel.
  ///
  /// In en, this message translates to:
  /// **'Total days'**
  String get totalDaysLabel;

  /// No description provided for @totalHoursLabel.
  ///
  /// In en, this message translates to:
  /// **'Total hours'**
  String get totalHoursLabel;

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

  /// No description provided for @profileChipDaysLabel.
  ///
  /// In en, this message translates to:
  /// **'days together'**
  String get profileChipDaysLabel;

  /// No description provided for @profileChipAnniversaryLabel.
  ///
  /// In en, this message translates to:
  /// **'days to anniversary'**
  String get profileChipAnniversaryLabel;

  /// No description provided for @profileChipAnniversaryTodayLabel.
  ///
  /// In en, this message translates to:
  /// **'anniversary is today!'**
  String get profileChipAnniversaryTodayLabel;

  /// No description provided for @profileChipPhotosLabel.
  ///
  /// In en, this message translates to:
  /// **'memories saved'**
  String get profileChipPhotosLabel;

  /// No description provided for @profileMemoryChestTitle.
  ///
  /// In en, this message translates to:
  /// **'Memory chest'**
  String get profileMemoryChestTitle;

  /// No description provided for @profileStreakTile.
  ///
  /// In en, this message translates to:
  /// **'Connection streak'**
  String get profileStreakTile;

  /// No description provided for @settingsSectionAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsSectionAccount;

  /// No description provided for @settingsSectionNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsSectionNotifications;

  /// No description provided for @settingsSectionGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settingsSectionGeneral;

  /// No description provided for @settingsPushGroupLabel.
  ///
  /// In en, this message translates to:
  /// **'Push from your partner'**
  String get settingsPushGroupLabel;

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

  /// No description provided for @leaveCoupleDeleteAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your shared space?'**
  String get leaveCoupleDeleteAllTitle;

  /// No description provided for @leaveCoupleDeleteAllContent.
  ///
  /// In en, this message translates to:
  /// **'You\'re the last member. Leaving will permanently delete ALL your shared memories — photos, love notes, and the question journal. This can\'t be undone.'**
  String get leaveCoupleDeleteAllContent;

  /// No description provided for @leaveCoupleDeleteAllBtn.
  ///
  /// In en, this message translates to:
  /// **'Delete everything'**
  String get leaveCoupleDeleteAllBtn;

  /// Snackbar shown when leaving the couple fails
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t leave the couple right now. Please check your connection and try again.'**
  String get leaveCoupleError;

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

  /// No description provided for @setupNoChangesToSaveMsg.
  ///
  /// In en, this message translates to:
  /// **'No changes to save.'**
  String get setupNoChangesToSaveMsg;

  /// No description provided for @inviteCodeCopiedMsg.
  ///
  /// In en, this message translates to:
  /// **'Invite code copied'**
  String get inviteCodeCopiedMsg;

  /// No description provided for @copyBtn.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copyBtn;

  /// No description provided for @shareBtn.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareBtn;

  /// No description provided for @inviteShareMessage.
  ///
  /// In en, this message translates to:
  /// **'I want to keep our memories together on Dear Embeiu 💞\nEnter this invite code to pair with me: {code}'**
  String inviteShareMessage(String code);

  /// No description provided for @remindersTitle.
  ///
  /// In en, this message translates to:
  /// **'Love reminders'**
  String get remindersTitle;

  /// No description provided for @remindersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Gentle nudges to keep your story growing'**
  String get remindersSubtitle;

  /// No description provided for @remindersToggleLabel.
  ///
  /// In en, this message translates to:
  /// **'Milestone & anniversary reminders'**
  String get remindersToggleLabel;

  /// No description provided for @remindersToggleDesc.
  ///
  /// In en, this message translates to:
  /// **'Reminds you of the milestones & anniversaries you choose. Required to use \"Our reminders\".'**
  String get remindersToggleDesc;

  /// No description provided for @remindersTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Reminder time'**
  String get remindersTimeLabel;

  /// No description provided for @remindersPermissionDeniedMsg.
  ///
  /// In en, this message translates to:
  /// **'Turn on notifications in Settings to receive reminders.'**
  String get remindersPermissionDeniedMsg;

  /// No description provided for @dailyQuestionReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily question reminder'**
  String get dailyQuestionReminderTitle;

  /// No description provided for @dailyQuestionReminderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Nudges you both to answer each day, synced across both phones.'**
  String get dailyQuestionReminderSubtitle;

  /// No description provided for @dailyQuestionReminderTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Remind me at'**
  String get dailyQuestionReminderTimeLabel;

  /// No description provided for @dailyQuestionReminderTimesLabel.
  ///
  /// In en, this message translates to:
  /// **'Reminder times'**
  String get dailyQuestionReminderTimesLabel;

  /// No description provided for @dailyQuestionReminderAddTime.
  ///
  /// In en, this message translates to:
  /// **'Add a time'**
  String get dailyQuestionReminderAddTime;

  /// No description provided for @dailyQuestionReminderRemoveTime.
  ///
  /// In en, this message translates to:
  /// **'Remove reminder time {time}'**
  String dailyQuestionReminderRemoveTime(String time);

  /// No description provided for @dailyQuestionReminderNotifTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s question is waiting 💌'**
  String get dailyQuestionReminderNotifTitle;

  /// No description provided for @dailyQuestionReminderNotifBody.
  ///
  /// In en, this message translates to:
  /// **'Answer it to unlock your partner\'s reply.'**
  String get dailyQuestionReminderNotifBody;

  /// No description provided for @reminderDailyTitle.
  ///
  /// In en, this message translates to:
  /// **'Another day of us 💕'**
  String get reminderDailyTitle;

  /// No description provided for @reminderDailyBody.
  ///
  /// In en, this message translates to:
  /// **'Open Dear Embeiu and count today together.'**
  String get reminderDailyBody;

  /// No description provided for @reminderMilestoneApproachingTitle.
  ///
  /// In en, this message translates to:
  /// **'A milestone is near 💕'**
  String get reminderMilestoneApproachingTitle;

  /// No description provided for @reminderMilestoneApproachingBody.
  ///
  /// In en, this message translates to:
  /// **'{count} days until your {milestone} milestone!'**
  String reminderMilestoneApproachingBody(int count, String milestone);

  /// No description provided for @reminderMilestoneTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'Milestone reached 🎉'**
  String get reminderMilestoneTodayTitle;

  /// No description provided for @reminderMilestoneTodayBody.
  ///
  /// In en, this message translates to:
  /// **'Today you reach {milestone} together 💕'**
  String reminderMilestoneTodayBody(String milestone);

  /// No description provided for @reminderAnniversaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Happy anniversary 🎉'**
  String get reminderAnniversaryTitle;

  /// No description provided for @reminderAnniversaryBody.
  ///
  /// In en, this message translates to:
  /// **'Celebrate another year of your love story today 💕'**
  String get reminderAnniversaryBody;

  /// No description provided for @reminderInactivityTitle.
  ///
  /// In en, this message translates to:
  /// **'Missing your moments 💭'**
  String get reminderInactivityTitle;

  /// No description provided for @reminderInactivityBody.
  ///
  /// In en, this message translates to:
  /// **'It\'s been a while — add a new memory together 💕'**
  String get reminderInactivityBody;

  /// No description provided for @remindersV2MilestoneEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Milestones & anniversaries'**
  String get remindersV2MilestoneEntryTitle;

  /// No description provided for @remindersV2MilestoneEntrySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose which milestones to be reminded of'**
  String get remindersV2MilestoneEntrySubtitle;

  /// No description provided for @remindersV2MilestoneCountBadge.
  ///
  /// In en, this message translates to:
  /// **'{count}'**
  String remindersV2MilestoneCountBadge(int count);

  /// No description provided for @remindersV2MilestoneScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Milestones & anniversaries'**
  String get remindersV2MilestoneScreenTitle;

  /// No description provided for @remindersV2MilestoneScreenCaption.
  ///
  /// In en, this message translates to:
  /// **'Choose the milestones you want and when to be reminded.'**
  String get remindersV2MilestoneScreenCaption;

  /// No description provided for @milestoneBadge.
  ///
  /// In en, this message translates to:
  /// **'SPECIAL DAYS'**
  String get milestoneBadge;

  /// No description provided for @milestoneHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick milestones to be reminded of, with their own times.'**
  String get milestoneHeaderSubtitle;

  /// No description provided for @remindersV2MilestoneNext.
  ///
  /// In en, this message translates to:
  /// **'Next: {date}'**
  String remindersV2MilestoneNext(String date);

  /// No description provided for @remindersV2MilestoneNextWithLabel.
  ///
  /// In en, this message translates to:
  /// **'Next: {label} · {date}'**
  String remindersV2MilestoneNextWithLabel(String label, String date);

  /// No description provided for @remindersV2MilestonePast.
  ///
  /// In en, this message translates to:
  /// **'Passed'**
  String get remindersV2MilestonePast;

  /// No description provided for @remindersV2MilestonePending.
  ///
  /// In en, this message translates to:
  /// **'Calculated once your anniversary begins'**
  String get remindersV2MilestonePending;

  /// No description provided for @remindersV2MilestoneDaysLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String remindersV2MilestoneDaysLabel(int count);

  /// No description provided for @remindersV2MilestoneYearsLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} years'**
  String remindersV2MilestoneYearsLabel(int count);

  /// No description provided for @milestoneEvery100Title.
  ///
  /// In en, this message translates to:
  /// **'Every 100 days'**
  String get milestoneEvery100Title;

  /// No description provided for @milestoneEvery100Desc.
  ///
  /// In en, this message translates to:
  /// **'Celebrate every 100 days together'**
  String get milestoneEvery100Desc;

  /// No description provided for @milestone520Title.
  ///
  /// In en, this message translates to:
  /// **'520 days'**
  String get milestone520Title;

  /// No description provided for @milestone520Desc.
  ///
  /// In en, this message translates to:
  /// **'\"I love you\" — the 520-day mark'**
  String get milestone520Desc;

  /// No description provided for @milestone1000Title.
  ///
  /// In en, this message translates to:
  /// **'1000 days'**
  String get milestone1000Title;

  /// No description provided for @milestone1000Desc.
  ///
  /// In en, this message translates to:
  /// **'A full 1000 days in love'**
  String get milestone1000Desc;

  /// No description provided for @milestone1314Title.
  ///
  /// In en, this message translates to:
  /// **'1314 days'**
  String get milestone1314Title;

  /// No description provided for @milestone1314Desc.
  ///
  /// In en, this message translates to:
  /// **'\"Forever love\" — the 1314-day mark'**
  String get milestone1314Desc;

  /// No description provided for @milestoneHalfYearTitle.
  ///
  /// In en, this message translates to:
  /// **'Half a year together'**
  String get milestoneHalfYearTitle;

  /// No description provided for @milestoneHalfYearDesc.
  ///
  /// In en, this message translates to:
  /// **'A full 6 months together'**
  String get milestoneHalfYearDesc;

  /// No description provided for @milestoneYearlyTitle.
  ///
  /// In en, this message translates to:
  /// **'Yearly anniversary'**
  String get milestoneYearlyTitle;

  /// No description provided for @milestoneYearlyDesc.
  ///
  /// In en, this message translates to:
  /// **'Every year on your anniversary'**
  String get milestoneYearlyDesc;

  /// No description provided for @milestoneInactivityTitle.
  ///
  /// In en, this message translates to:
  /// **'No photos for a while'**
  String get milestoneInactivityTitle;

  /// No description provided for @milestoneInactivityDesc.
  ///
  /// In en, this message translates to:
  /// **'A gentle nudge after 7 days without a new photo'**
  String get milestoneInactivityDesc;

  /// No description provided for @milestoneInactivitySub.
  ///
  /// In en, this message translates to:
  /// **'Reminds you after 7 photo-free days'**
  String get milestoneInactivitySub;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsBadge.
  ///
  /// In en, this message translates to:
  /// **'APP PREFERENCES'**
  String get settingsBadge;

  /// No description provided for @settingsHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reminders, notifications, language and your account.'**
  String get settingsHeaderSubtitle;

  /// No description provided for @settingsProfileTileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reminders, language, account'**
  String get settingsProfileTileSubtitle;

  /// No description provided for @settingsRemindersModuleTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get settingsRemindersModuleTitle;

  /// No description provided for @settingsRemindersModuleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Milestones, anniversaries & your own reminders'**
  String get settingsRemindersModuleSubtitle;

  /// No description provided for @settingsRemindersEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get settingsRemindersEntryTitle;

  /// No description provided for @settingsRemindersEntrySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Milestones, anniversaries and your own reminders'**
  String get settingsRemindersEntrySubtitle;

  /// No description provided for @remindersHubBadge.
  ///
  /// In en, this message translates to:
  /// **'REMINDERS'**
  String get remindersHubBadge;

  /// No description provided for @remindersHubTitle.
  ///
  /// In en, this message translates to:
  /// **'Our reminders'**
  String get remindersHubTitle;

  /// No description provided for @remindersHubSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Milestones, anniversaries and your own reminders — all in one place.'**
  String get remindersHubSubtitle;

  /// No description provided for @remindersHubMilestonesSection.
  ///
  /// In en, this message translates to:
  /// **'Milestones & anniversaries'**
  String get remindersHubMilestonesSection;

  /// No description provided for @remindersHubMilestonesSectionSub.
  ///
  /// In en, this message translates to:
  /// **'Pick the milestones to be reminded of and set their times.'**
  String get remindersHubMilestonesSectionSub;

  /// No description provided for @remindersHubCustomSection.
  ///
  /// In en, this message translates to:
  /// **'Our reminders'**
  String get remindersHubCustomSection;

  /// No description provided for @remindersHubCustomSectionSub.
  ///
  /// In en, this message translates to:
  /// **'Create reminders for your own special days.'**
  String get remindersHubCustomSectionSub;

  /// No description provided for @settingsAccountModuleTitle.
  ///
  /// In en, this message translates to:
  /// **'Account & data'**
  String get settingsAccountModuleTitle;

  /// No description provided for @settingsAccountModuleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your story, data & account'**
  String get settingsAccountModuleSubtitle;

  /// No description provided for @settingsAnalyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Share usage data'**
  String get settingsAnalyticsTitle;

  /// No description provided for @settingsAnalyticsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Help improve the app with anonymous data. We never collect your private content.'**
  String get settingsAnalyticsSubtitle;

  /// No description provided for @settingsNotifTypesTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification types'**
  String get settingsNotifTypesTitle;

  /// No description provided for @settingsNotifTypesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Mute the push types you\'d rather not be interrupted by. They still appear in your notification center.'**
  String get settingsNotifTypesSubtitle;

  /// No description provided for @settingsNotifTypePhoto.
  ///
  /// In en, this message translates to:
  /// **'New photos'**
  String get settingsNotifTypePhoto;

  /// No description provided for @settingsNotifTypePhotoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When your partner posts a photo'**
  String get settingsNotifTypePhotoSubtitle;

  /// No description provided for @settingsNotifTypeReaction.
  ///
  /// In en, this message translates to:
  /// **'Photo reactions'**
  String get settingsNotifTypeReaction;

  /// No description provided for @settingsNotifTypeReactionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When your partner reacts to your photo'**
  String get settingsNotifTypeReactionSubtitle;

  /// No description provided for @settingsNotifTypeDailyQuestion.
  ///
  /// In en, this message translates to:
  /// **'Daily question'**
  String get settingsNotifTypeDailyQuestion;

  /// No description provided for @settingsNotifTypeDailyQuestionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When your partner answers today\'s question'**
  String get settingsNotifTypeDailyQuestionSubtitle;

  /// No description provided for @settingsEditStorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Edit names, anniversary date, photo'**
  String get settingsEditStorySubtitle;

  /// No description provided for @settingsDefaultTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Default time'**
  String get settingsDefaultTimeLabel;

  /// No description provided for @settingsDefaultTimeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Used for milestones without a custom time'**
  String get settingsDefaultTimeSubtitle;

  /// No description provided for @settingsMilestoneUsesDefault.
  ///
  /// In en, this message translates to:
  /// **'Default · {time}'**
  String settingsMilestoneUsesDefault(String time);

  /// No description provided for @settingsMilestoneCustomTimeReset.
  ///
  /// In en, this message translates to:
  /// **'Reset to default time'**
  String get settingsMilestoneCustomTimeReset;

  /// No description provided for @remindersV2ForceOpenTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn on reminders to continue'**
  String get remindersV2ForceOpenTitle;

  /// No description provided for @remindersV2ForceOpenBody.
  ///
  /// In en, this message translates to:
  /// **'You need to turn on \"Milestone & anniversary reminders\" to create and receive your own reminders.'**
  String get remindersV2ForceOpenBody;

  /// No description provided for @remindersV2ForceOpenConfirm.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get remindersV2ForceOpenConfirm;

  /// No description provided for @remindersV2ForceOpenLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get remindersV2ForceOpenLater;

  /// No description provided for @remindersV2ForceOpenDeniedMsg.
  ///
  /// In en, this message translates to:
  /// **'Notification permission denied. Enable notifications in Settings to continue.'**
  String get remindersV2ForceOpenDeniedMsg;

  /// No description provided for @languageSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search languages'**
  String get languageSearchHint;

  /// No description provided for @customRemindersEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Our reminders'**
  String get customRemindersEntryTitle;

  /// No description provided for @customRemindersEntrySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your own special dates'**
  String get customRemindersEntrySubtitle;

  /// No description provided for @customRemindersScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Our reminders'**
  String get customRemindersScreenTitle;

  /// No description provided for @customRemindersBadge.
  ///
  /// In en, this message translates to:
  /// **'YOUR OWN MOMENTS'**
  String get customRemindersBadge;

  /// No description provided for @customRemindersHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create reminders for your own special moments.'**
  String get customRemindersHeaderSubtitle;

  /// No description provided for @customRemindersCount.
  ///
  /// In en, this message translates to:
  /// **'{count}/20'**
  String customRemindersCount(int count);

  /// No description provided for @customRemindersNextFire.
  ///
  /// In en, this message translates to:
  /// **'Next: {date}'**
  String customRemindersNextFire(String date);

  /// No description provided for @customRemindersDisabledLabel.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get customRemindersDisabledLabel;

  /// No description provided for @customRemindersFabTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add reminder'**
  String get customRemindersFabTooltip;

  /// No description provided for @customRemindersItemMenuEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get customRemindersItemMenuEdit;

  /// No description provided for @customRemindersItemMenuDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get customRemindersItemMenuDelete;

  /// No description provided for @customRemindersEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No reminders yet'**
  String get customRemindersEmptyTitle;

  /// No description provided for @customRemindersEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Create your own moments: birthdays, monthsaries, special days…'**
  String get customRemindersEmptyBody;

  /// No description provided for @customRemindersEmptyCta.
  ///
  /// In en, this message translates to:
  /// **'Create your first reminder'**
  String get customRemindersEmptyCta;

  /// No description provided for @customRemindersAddAnother.
  ///
  /// In en, this message translates to:
  /// **'Add a reminder'**
  String get customRemindersAddAnother;

  /// No description provided for @customRemindersOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminders are off'**
  String get customRemindersOffTitle;

  /// No description provided for @customRemindersOffBody.
  ///
  /// In en, this message translates to:
  /// **'Turn on \"Love reminders\" in Profile so your reminders can work.'**
  String get customRemindersOffBody;

  /// No description provided for @customRemindersOffCta.
  ///
  /// In en, this message translates to:
  /// **'Turn on reminders'**
  String get customRemindersOffCta;

  /// No description provided for @customRemindersLimitMsg.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached the max of 20 reminders. Delete one to add more.'**
  String get customRemindersLimitMsg;

  /// No description provided for @customRemindersAddTitle.
  ///
  /// In en, this message translates to:
  /// **'New reminder'**
  String get customRemindersAddTitle;

  /// No description provided for @customRemindersEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit reminder'**
  String get customRemindersEditTitle;

  /// No description provided for @customReminderFormBadge.
  ///
  /// In en, this message translates to:
  /// **'YOUR REMINDER'**
  String get customReminderFormBadge;

  /// No description provided for @customRemindersSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get customRemindersSave;

  /// No description provided for @customRemindersCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get customRemindersCancel;

  /// No description provided for @customRemindersSavedMsg.
  ///
  /// In en, this message translates to:
  /// **'Reminder saved 💌'**
  String get customRemindersSavedMsg;

  /// No description provided for @customRemindersNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Reminder name'**
  String get customRemindersNameLabel;

  /// No description provided for @customRemindersNameRequiredMark.
  ///
  /// In en, this message translates to:
  /// **'*'**
  String get customRemindersNameRequiredMark;

  /// No description provided for @customRemindersNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. My love\'s birthday'**
  String get customRemindersNameHint;

  /// No description provided for @customRemindersNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get customRemindersNoteLabel;

  /// No description provided for @customRemindersNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Add a sweet note…'**
  String get customRemindersNoteHint;

  /// No description provided for @customRemindersDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get customRemindersDateLabel;

  /// No description provided for @customRemindersTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get customRemindersTimeLabel;

  /// No description provided for @customRemindersRepeatLabel.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get customRemindersRepeatLabel;

  /// No description provided for @customRemindersRepeatOnce.
  ///
  /// In en, this message translates to:
  /// **'Once'**
  String get customRemindersRepeatOnce;

  /// No description provided for @customRemindersRepeatDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get customRemindersRepeatDaily;

  /// No description provided for @customRemindersRepeatWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get customRemindersRepeatWeekly;

  /// No description provided for @customRemindersRepeatMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get customRemindersRepeatMonthly;

  /// No description provided for @customRemindersRepeatYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get customRemindersRepeatYearly;

  /// No description provided for @customRemindersMetaOnce.
  ///
  /// In en, this message translates to:
  /// **'Once · {date} · {time}'**
  String customRemindersMetaOnce(String date, String time);

  /// No description provided for @customRemindersMetaDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily · {time}'**
  String customRemindersMetaDaily(String time);

  /// No description provided for @customRemindersMetaWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly · {weekday} · {time}'**
  String customRemindersMetaWeekly(String weekday, String time);

  /// No description provided for @customRemindersMetaMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly · day {day} · {time}'**
  String customRemindersMetaMonthly(int day, String time);

  /// No description provided for @customRemindersMetaYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly · {dayMonth} · {time}'**
  String customRemindersMetaYearly(String dayMonth, String time);

  /// No description provided for @customRemindersNameError.
  ///
  /// In en, this message translates to:
  /// **'Please name your reminder'**
  String get customRemindersNameError;

  /// No description provided for @customRemindersPastDateWarning.
  ///
  /// In en, this message translates to:
  /// **'That date has passed — pick another'**
  String get customRemindersPastDateWarning;

  /// No description provided for @customRemindersDeleteSectionHint.
  ///
  /// In en, this message translates to:
  /// **'Can\'t be undone'**
  String get customRemindersDeleteSectionHint;

  /// No description provided for @customRemindersDeleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete reminder'**
  String get customRemindersDeleteButton;

  /// No description provided for @customRemindersDeleteDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this reminder?'**
  String get customRemindersDeleteDialogTitle;

  /// No description provided for @customRemindersDeleteDialogBody.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" will be removed and won\'t remind you anymore.'**
  String customRemindersDeleteDialogBody(String name);

  /// No description provided for @customRemindersDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get customRemindersDeleteConfirm;

  /// No description provided for @customRemindersDeletedMsg.
  ///
  /// In en, this message translates to:
  /// **'Reminder deleted'**
  String get customRemindersDeletedMsg;

  /// No description provided for @customRemindersNotifBodyFallback.
  ///
  /// In en, this message translates to:
  /// **'A special moment for the two of you 💞'**
  String get customRemindersNotifBodyFallback;

  /// agreeToPrivacyPolicy
  ///
  /// In en, this message translates to:
  /// **'I agree to the Privacy Policy'**
  String get agreeToPrivacyPolicy;

  /// appTitle
  ///
  /// In en, this message translates to:
  /// **'Our Memories'**
  String get appTitle;

  /// authAccountNotFound
  ///
  /// In en, this message translates to:
  /// **'No account found for this email.'**
  String get authAccountNotFound;

  /// authConfigNotFound
  ///
  /// In en, this message translates to:
  /// **'Firebase Authentication for this project isn\'t enabled, or Email/Password is off. In Firebase Console > Authentication > Sign-in method > Email/Password, turn it on.'**
  String get authConfigNotFound;

  /// authEmailAlreadyUsed
  ///
  /// In en, this message translates to:
  /// **'This email is already in use.'**
  String get authEmailAlreadyUsed;

  /// authEmailPasswordNotEnabled
  ///
  /// In en, this message translates to:
  /// **'Firebase Authentication isn\'t fully set up for Email/Password. In Firebase Console > Authentication > Sign-in method, enable Email/Password.'**
  String get authEmailPasswordNotEnabled;

  /// authFirebaseAuthGeneric
  ///
  /// In en, this message translates to:
  /// **'A Firebase Auth error occurred.'**
  String get authFirebaseAuthGeneric;

  /// authFirebaseUserCreateFailed
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create your Firebase account.'**
  String get authFirebaseUserCreateFailed;

  /// authFirestoreGeneric
  ///
  /// In en, this message translates to:
  /// **'A Firestore error occurred.'**
  String get authFirestoreGeneric;

  /// authFirestorePermissionDenied
  ///
  /// In en, this message translates to:
  /// **'Firestore is blocking writes to user data. Check this app\'s Firestore Rules and allow a signed-in user to create/write their own `users/<uid>` and `invite_codes/<code>`.'**
  String get authFirestorePermissionDenied;

  /// authFirestoreUnavailable
  ///
  /// In en, this message translates to:
  /// **'Firestore is currently unavailable or the network is unstable. Please try again in a few minutes.'**
  String get authFirestoreUnavailable;

  /// authInvalidCredential
  ///
  /// In en, this message translates to:
  /// **'Email or password is incorrect.'**
  String get authInvalidCredential;

  /// authInvalidEmail
  ///
  /// In en, this message translates to:
  /// **'That email isn\'t valid.'**
  String get authInvalidEmail;

  /// authInviteCodeGenerateFailed
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t generate a new invite code — please try again later.'**
  String get authInviteCodeGenerateFailed;

  /// authInviteCodeUnavailable
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create an invite code for your account right now — please try again.'**
  String get authInviteCodeUnavailable;

  /// authNetworkError
  ///
  /// In en, this message translates to:
  /// **'No stable network connection to sign in to Firebase.'**
  String get authNetworkError;

  /// authSessionNotReady
  ///
  /// In en, this message translates to:
  /// **'Your Firebase session isn\'t ready. Please sign in again.'**
  String get authSessionNotReady;

  /// authSessionUnavailable
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t get your Firebase session.'**
  String get authSessionUnavailable;

  /// authTooManyRequests
  ///
  /// In en, this message translates to:
  /// **'Too many sign-in attempts — please try again in a few minutes.'**
  String get authTooManyRequests;

  /// authWeakPassword
  ///
  /// In en, this message translates to:
  /// **'That password is too weak — please choose a stronger one.'**
  String get authWeakPassword;

  /// authWrongPassword
  ///
  /// In en, this message translates to:
  /// **'That password isn\'t right — please check and try again.'**
  String get authWrongPassword;

  /// bootstrapAndroidNotReady
  ///
  /// In en, this message translates to:
  /// **'Firebase Android isn\'t ready. Check `android/app/google-services.json` and the app\'s package name.'**
  String get bootstrapAndroidNotReady;

  /// bootstrapIosNotConfigured
  ///
  /// In en, this message translates to:
  /// **'You\'re on iOS but the project has no `GoogleService-Info.plist`, so the app fell back to local mode.'**
  String get bootstrapIosNotConfigured;

  /// bootstrapLinuxNotConfigured
  ///
  /// In en, this message translates to:
  /// **'Firebase for Linux isn\'t configured, so the app is running in local fallback.'**
  String get bootstrapLinuxNotConfigured;

  /// bootstrapMacosNotConfigured
  ///
  /// In en, this message translates to:
  /// **'Firebase for macOS isn\'t configured, so the app is running in local fallback.'**
  String get bootstrapMacosNotConfigured;

  /// bootstrapPlatformNotConfigured
  ///
  /// In en, this message translates to:
  /// **'Firebase isn\'t configured for the current platform, so the app is running in local fallback.'**
  String get bootstrapPlatformNotConfigured;

  /// bootstrapWebNotConfigured
  ///
  /// In en, this message translates to:
  /// **'Firebase isn\'t configured for Web, so the app is running in local fallback.'**
  String get bootstrapWebNotConfigured;

  /// bootstrapWindowsNotConfigured
  ///
  /// In en, this message translates to:
  /// **'Firebase for Windows isn\'t configured, so the app is running in local fallback.'**
  String get bootstrapWindowsNotConfigured;

  /// coupleAlreadyInCouple
  ///
  /// In en, this message translates to:
  /// **'This account already belongs to a couple.'**
  String get coupleAlreadyInCouple;

  /// coupleAlreadyInThisCouple
  ///
  /// In en, this message translates to:
  /// **'You\'re already in this couple.'**
  String get coupleAlreadyInThisCouple;

  /// coupleCannotUseOwnCode
  ///
  /// In en, this message translates to:
  /// **'You can\'t use your own invite code.'**
  String get coupleCannotUseOwnCode;

  /// coupleCodeNoLongerValid
  ///
  /// In en, this message translates to:
  /// **'This invite code no longer points to a valid couple.'**
  String get coupleCodeNoLongerValid;

  /// coupleCodeNotFoundLocal
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t find the connection code in local fallback.'**
  String get coupleCodeNotFoundLocal;

  /// coupleEnterCodeFirst
  ///
  /// In en, this message translates to:
  /// **'Please enter a connection code first.'**
  String get coupleEnterCodeFirst;

  /// coupleFirebaseUnavailable
  ///
  /// In en, this message translates to:
  /// **'Firebase is currently unavailable or the network is unstable. Please try again in a few minutes.'**
  String get coupleFirebaseUnavailable;

  /// coupleFull
  ///
  /// In en, this message translates to:
  /// **'This couple already has two people.'**
  String get coupleFull;

  /// coupleFullLocal
  ///
  /// In en, this message translates to:
  /// **'This local couple already has two people.'**
  String get coupleFullLocal;

  /// coupleInviteCodeInvalid
  ///
  /// In en, this message translates to:
  /// **'This invite code is invalid or no longer exists.'**
  String get coupleInviteCodeInvalid;

  /// coupleJoinGeneric
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t connect with this invite code right now.'**
  String get coupleJoinGeneric;

  /// coupleJoinPermissionDenied
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t connect with this invite code. The couple space may have changed or is no longer valid — ask your partner to regenerate the code, or sign out and back in, then try again.'**
  String get coupleJoinPermissionDenied;

  /// coupleMatchedLocal
  ///
  /// In en, this message translates to:
  /// **'Matched in local fallback mode.'**
  String get coupleMatchedLocal;

  /// coupleNoDataToUpdate
  ///
  /// In en, this message translates to:
  /// **'No couple data to update.'**
  String get coupleNoDataToUpdate;

  /// coupleNotFoundForCode
  ///
  /// In en, this message translates to:
  /// **'No couple found for this code.'**
  String get coupleNotFoundForCode;

  /// coupleOnboardingBadge
  ///
  /// In en, this message translates to:
  /// **'ONBOARDING'**
  String get coupleOnboardingBadge;

  /// couplePartnerHasNoSpace
  ///
  /// In en, this message translates to:
  /// **'Your partner has their own invite code but hasn\'t created a couple space for you to join yet.'**
  String get couplePartnerHasNoSpace;

  /// couplePhotoUploadGeneric
  ///
  /// In en, this message translates to:
  /// **'The couple photo couldn\'t be uploaded to Firebase Storage.'**
  String get couplePhotoUploadGeneric;

  /// couplePhotoUploadPermission
  ///
  /// In en, this message translates to:
  /// **'The couple photo couldn\'t be uploaded to Firebase Storage. Your couple info was saved first — deploy `storage.rules`, then try changing the photo again.'**
  String get couplePhotoUploadPermission;

  /// couplePhotoUploadSessionInvalid
  ///
  /// In en, this message translates to:
  /// **'The couple photo couldn\'t be uploaded because your Firebase session is no longer valid.'**
  String get couplePhotoUploadSessionInvalid;

  /// couplePhotoUploadUnavailable
  ///
  /// In en, this message translates to:
  /// **'The couple photo couldn\'t be uploaded because Firebase Storage or the network is temporarily unstable.'**
  String get couplePhotoUploadUnavailable;

  /// coupleSaveGeneric
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save couple info right now.'**
  String get coupleSaveGeneric;

  /// coupleSavePermissionDenied
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save couple info because access was denied. The data may be in an invalid state — please sign out and back in, then try again.'**
  String get coupleSavePermissionDenied;

  /// coupleSessionExpiredJoin
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please sign in again, then retry connecting.'**
  String get coupleSessionExpiredJoin;

  /// coupleSessionInvalid
  ///
  /// In en, this message translates to:
  /// **'Your Firebase session is no longer valid. Please sign in again.'**
  String get coupleSessionInvalid;

  /// coupleSessionNotReadyRelogin
  ///
  /// In en, this message translates to:
  /// **'Your Firebase session isn\'t ready. Please sign out and back in.'**
  String get coupleSessionNotReadyRelogin;

  /// coupleSpaceInvalidRegenerate
  ///
  /// In en, this message translates to:
  /// **'This invite code points to a couple space that\'s no longer valid. Ask your partner to regenerate the code, then try again.'**
  String get coupleSpaceInvalidRegenerate;

  /// coupleUpdatedSuccess
  ///
  /// In en, this message translates to:
  /// **'Couple info updated.'**
  String get coupleUpdatedSuccess;

  /// coupleUserNotFoundForCreate
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t find your current account to create a couple.'**
  String get coupleUserNotFoundForCreate;

  /// createAccountBadge
  ///
  /// In en, this message translates to:
  /// **'CREATE ACCOUNT'**
  String get createAccountBadge;

  /// defaultDisplayName
  ///
  /// In en, this message translates to:
  /// **'New user'**
  String get defaultDisplayName;

  /// deleteAccountBtn
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccountBtn;

  /// deleteAccountConfirmBtn
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get deleteAccountConfirmBtn;

  /// deleteAccountDesc
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your account and all associated data'**
  String get deleteAccountDesc;

  /// deleteAccountDialogContent
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone. All your data, including photos and couple information, will be permanently deleted.'**
  String get deleteAccountDialogContent;

  /// deleteAccountDialogTitle
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get deleteAccountDialogTitle;

  /// deleteAccountFailed
  ///
  /// In en, this message translates to:
  /// **'Could not delete your account right now. Please try again.'**
  String get deleteAccountFailed;

  /// deleteAccountRequiresReloginMsg
  ///
  /// In en, this message translates to:
  /// **'Please sign out, sign in again, and retry to verify your identity'**
  String get deleteAccountRequiresReloginMsg;

  /// Title of the re-auth dialog shown when deleting an account needs a recent login
  ///
  /// In en, this message translates to:
  /// **'Confirm it\'s you'**
  String get deleteAccountReauthTitle;

  /// Body of the re-auth dialog before deleting an account
  ///
  /// In en, this message translates to:
  /// **'For your security, re-enter your password to permanently delete your account.'**
  String get deleteAccountReauthBody;

  /// Shown when re-auth can't proceed because there's no local session left
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please sign in again, then delete your account.'**
  String get deleteAccountSessionExpiredMsg;

  /// deleteAccountSuccessMsg
  ///
  /// In en, this message translates to:
  /// **'Account deleted'**
  String get deleteAccountSuccessMsg;

  /// deleteAccountTitle
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccountTitle;

  /// editCoupleBadge
  ///
  /// In en, this message translates to:
  /// **'COUPLE PROFILE'**
  String get editCoupleBadge;

  /// galleryEditCaptionTooltip
  ///
  /// In en, this message translates to:
  /// **'Edit caption'**
  String get galleryEditCaptionTooltip;

  /// galleryEmptySubtitle
  ///
  /// In en, this message translates to:
  /// **'Add photos to start making memories'**
  String get galleryEmptySubtitle;

  /// galleryEmptyTitle
  ///
  /// In en, this message translates to:
  /// **'No photos yet'**
  String get galleryEmptyTitle;

  /// galleryRecordTodayMoment
  ///
  /// In en, this message translates to:
  /// **'Capture today\'s moment'**
  String get galleryRecordTodayMoment;

  /// galleryTodayBadge
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get galleryTodayBadge;

  /// galleryTodayEmptySubtitle
  ///
  /// In en, this message translates to:
  /// **'Every photo is a memory the two of you share.'**
  String get galleryTodayEmptySubtitle;

  /// galleryTodayEmptyTitle
  ///
  /// In en, this message translates to:
  /// **'No moments captured today yet'**
  String get galleryTodayEmptyTitle;

  /// homeWaitingPartnerSubtitle
  ///
  /// In en, this message translates to:
  /// **'Share your invite code with your partner to start the journey together.'**
  String get homeWaitingPartnerSubtitle;

  /// homeWaitingPartnerTitle
  ///
  /// In en, this message translates to:
  /// **'Waiting for your partner'**
  String get homeWaitingPartnerTitle;

  /// leavingCouple
  ///
  /// In en, this message translates to:
  /// **'Leaving the couple...'**
  String get leavingCouple;

  /// loveHomeBadge
  ///
  /// In en, this message translates to:
  /// **'LOVE HOME'**
  String get loveHomeBadge;

  /// mustAgreeToPrivacyPolicy
  ///
  /// In en, this message translates to:
  /// **'Please agree to the privacy policy to continue'**
  String get mustAgreeToPrivacyPolicy;

  /// photoConnectCoupleFirst
  ///
  /// In en, this message translates to:
  /// **'Connect with your partner before posting a photo.'**
  String get photoConnectCoupleFirst;

  /// photoFileNotFoundStorage
  ///
  /// In en, this message translates to:
  /// **'The photo file wasn\'t found on Firebase Storage.'**
  String get photoFileNotFoundStorage;

  /// photoFirebaseUnavailable
  ///
  /// In en, this message translates to:
  /// **'Firebase is currently unavailable or the network is unstable.'**
  String get photoFirebaseUnavailable;

  /// photoNotFoundToPost
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t find the photo to post.'**
  String get photoNotFoundToPost;

  /// photoStorageUnauthorized
  ///
  /// In en, this message translates to:
  /// **'Firebase Storage is refusing this photo operation.'**
  String get photoStorageUnauthorized;

  /// photoSyncGeneric
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sync photos right now.'**
  String get photoSyncGeneric;

  /// photoSyncPermissionDenied
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to sync photos. Check `firestore.rules` and `storage.rules` on Firebase.'**
  String get photoSyncPermissionDenied;

  /// photoSyncSessionExpired
  ///
  /// In en, this message translates to:
  /// **'Your Firebase session has expired. Please sign in again.'**
  String get photoSyncSessionExpired;

  /// posterNameFallback
  ///
  /// In en, this message translates to:
  /// **'Your partner'**
  String get posterNameFallback;

  /// privacyDisclosure
  ///
  /// In en, this message translates to:
  /// **'By creating an account, you agree to our Privacy Policy. We collect your email, display name, and photos you share to provide the service.'**
  String get privacyDisclosure;

  /// privacyPolicyLabel
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicyLabel;

  /// profileDangerIrreversible
  ///
  /// In en, this message translates to:
  /// **'Can\'t be undone'**
  String get profileDangerIrreversible;

  /// pushPhotoChannelDescription
  ///
  /// In en, this message translates to:
  /// **'Get notified when your partner posts a new photo.'**
  String get pushPhotoChannelDescription;

  /// pushPhotoChannelName
  ///
  /// In en, this message translates to:
  /// **'Partner photo updates'**
  String get pushPhotoChannelName;

  /// signOutBtn
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOutBtn;

  /// signOutConfirmBtn
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOutConfirmBtn;

  /// signOutDialogContent
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out of your account?'**
  String get signOutDialogContent;

  /// signOutDialogTitle
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get signOutDialogTitle;

  /// signOutFailedMsg
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sign out. Please check your connection and try again.'**
  String get signOutFailedMsg;

  /// welcomeBackBadge
  ///
  /// In en, this message translates to:
  /// **'WELCOME BACK'**
  String get welcomeBackBadge;

  /// Love duration breakdown
  ///
  /// In en, this message translates to:
  /// **'{years} years, {months} months, {days} days'**
  String counterDuration(int years, int months, int days);

  /// Error loading couple info
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load couple info: {error}'**
  String coupleLoadError(String error);

  /// Error syncing couple info
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sync couple info: {error}'**
  String coupleSyncError(String error);

  /// Month header label in gallery
  ///
  /// In en, this message translates to:
  /// **'{month, select, 1{January {year}} 2{February {year}} 3{March {year}} 4{April {year}} 5{May {year}} 6{June {year}} 7{July {year}} 8{August {year}} 9{September {year}} 10{October {year}} 11{November {year}} 12{December {year}} other{{month} {year}}}'**
  String galleryMonthLabel(String month, String year);

  /// No description provided for @galleryEndOfFeed.
  ///
  /// In en, this message translates to:
  /// **'That\'s every memory 💕 — go make some new ones together'**
  String get galleryEndOfFeed;

  /// Count of moments posted today
  ///
  /// In en, this message translates to:
  /// **'{count} moments today'**
  String galleryTodayMomentsCount(int count);

  /// Start date label
  ///
  /// In en, this message translates to:
  /// **'Since {date}'**
  String homeCounterStartFrom(String date);

  /// Login screen button entering guest counter mode
  ///
  /// In en, this message translates to:
  /// **'Try without signing in'**
  String get guestTryWithoutLogin;

  /// Divider label between sign-in and guest button on login
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get guestLoginDivider;

  /// Eyebrow badge on the guest counter screen
  ///
  /// In en, this message translates to:
  /// **'Trial mode'**
  String get guestModeBadge;

  /// Page title on the guest counter screen
  ///
  /// In en, this message translates to:
  /// **'Love day counter'**
  String get guestCounterTitle;

  /// Page subtitle on the guest counter screen
  ///
  /// In en, this message translates to:
  /// **'Enter the day you started to see how long you\'ve been together.'**
  String get guestCounterSubtitle;

  /// Title of the empty state card before picking a date
  ///
  /// In en, this message translates to:
  /// **'Start counting your love days'**
  String get guestEmptyTitle;

  /// Body of the empty state card before picking a date
  ///
  /// In en, this message translates to:
  /// **'Pick your anniversary date to see how long you\'ve been together.'**
  String get guestEmptyBody;

  /// Button to open the date picker in empty state
  ///
  /// In en, this message translates to:
  /// **'Pick anniversary date'**
  String get guestPickDate;

  /// Button to reopen the date picker once a date is set
  ///
  /// In en, this message translates to:
  /// **'Change anniversary date'**
  String get guestChangeDate;

  /// Counter card subtitle showing the guest start date
  ///
  /// In en, this message translates to:
  /// **'Since {date}'**
  String guestCounterStartFrom(String date);

  /// Title of the conversion CTA card on the guest screen
  ///
  /// In en, this message translates to:
  /// **'Want to keep memories together?'**
  String get guestCtaTitle;

  /// Body of the conversion CTA card on the guest screen
  ///
  /// In en, this message translates to:
  /// **'Sign in to pair up & share photos together.'**
  String get guestCtaBody;

  /// CTA button returning to the login screen
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get guestCtaSignIn;

  /// CTA button opening the register screen
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get guestCtaRegister;

  /// Streak chip — active couple with no streak yet (shame-free invite)
  ///
  /// In en, this message translates to:
  /// **'Start a streak together'**
  String get streakChipNoStreak;

  /// Streak chip — after a reset, positive restart framing
  ///
  /// In en, this message translates to:
  /// **'Let\'s start a new streak 🌱'**
  String get streakChipRestart;

  /// No description provided for @streakChipActiveToday.
  ///
  /// In en, this message translates to:
  /// **'{n}-day streak · done for today'**
  String streakChipActiveToday(int n);

  /// No description provided for @streakChipInProgress.
  ///
  /// In en, this message translates to:
  /// **'{n}-day streak · today\'s your turn 🌸'**
  String streakChipInProgress(int n);

  /// No description provided for @streakChipAtRisk.
  ///
  /// In en, this message translates to:
  /// **'Your {n}-day streak is waiting 🫶'**
  String streakChipAtRisk(int n);

  /// No description provided for @streakSheetUnit.
  ///
  /// In en, this message translates to:
  /// **'days connected in a row'**
  String get streakSheetUnit;

  /// No description provided for @streakSheetNoStreakTitle.
  ///
  /// In en, this message translates to:
  /// **'Light your first spark'**
  String get streakSheetNoStreakTitle;

  /// No description provided for @streakSheetNoStreakBody.
  ///
  /// In en, this message translates to:
  /// **'Each day you both answer the question, your streak grows. Let\'s begin 💞'**
  String get streakSheetNoStreakBody;

  /// No description provided for @streakSheetActiveTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re keeping the spark alive 💞'**
  String get streakSheetActiveTitle;

  /// No description provided for @streakSheetActiveBody.
  ///
  /// In en, this message translates to:
  /// **'All done today! See you at tomorrow\'s question.'**
  String get streakSheetActiveBody;

  /// No description provided for @streakSheetInProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Your streak\'s still glowing 🌸'**
  String get streakSheetInProgressTitle;

  /// No description provided for @streakSheetInProgressBody.
  ///
  /// In en, this message translates to:
  /// **'Answer today\'s question to keep your {n}-day streak going 💞'**
  String streakSheetInProgressBody(int n);

  /// No description provided for @streakSheetAtRiskTitle.
  ///
  /// In en, this message translates to:
  /// **'One soft day left 🫶'**
  String get streakSheetAtRiskTitle;

  /// No description provided for @streakSheetAtRiskBody.
  ///
  /// In en, this message translates to:
  /// **'You missed a beat yesterday — totally okay! Answer today and your {n}-day streak picks right back up.'**
  String streakSheetAtRiskBody(int n);

  /// No description provided for @streakSheetRestartBody.
  ///
  /// In en, this message translates to:
  /// **'The old streak wrapped up, but every new day\'s a fresh start. Let\'s light it again 🌱'**
  String get streakSheetRestartBody;

  /// No description provided for @streakSheetRecord.
  ///
  /// In en, this message translates to:
  /// **'Your record: {m} days 🌟'**
  String streakSheetRecord(int m);

  /// No description provided for @streakNextMilestone.
  ///
  /// In en, this message translates to:
  /// **'{n} days to your {m}-day milestone 🎉'**
  String streakNextMilestone(int n, int m);

  /// No description provided for @streakCtaAnswerNow.
  ///
  /// In en, this message translates to:
  /// **'Answer now'**
  String get streakCtaAnswerNow;

  /// No description provided for @streakCtaKeepGoing.
  ///
  /// In en, this message translates to:
  /// **'Keep it going'**
  String get streakCtaKeepGoing;

  /// No description provided for @streakMilestone3Title.
  ///
  /// In en, this message translates to:
  /// **'3 days already! 🌸'**
  String get streakMilestone3Title;

  /// No description provided for @streakMilestone3Body.
  ///
  /// In en, this message translates to:
  /// **'What a sweet start. You two are doing great 💞'**
  String get streakMilestone3Body;

  /// No description provided for @streakMilestone7Title.
  ///
  /// In en, this message translates to:
  /// **'A whole week! ✨'**
  String get streakMilestone7Title;

  /// No description provided for @streakMilestone7Body.
  ///
  /// In en, this message translates to:
  /// **'7 days without missing a beat. So proud of you both!'**
  String get streakMilestone7Body;

  /// No description provided for @streakMilestone30Title.
  ///
  /// In en, this message translates to:
  /// **'30 days, every single day! 🔥'**
  String get streakMilestone30Title;

  /// No description provided for @streakMilestone30Body.
  ///
  /// In en, this message translates to:
  /// **'A month of keeping it lit — this is your ritual now 💞'**
  String get streakMilestone30Body;

  /// No description provided for @streakMilestone100Title.
  ///
  /// In en, this message translates to:
  /// **'100 days! 💯'**
  String get streakMilestone100Title;

  /// No description provided for @streakMilestone100Body.
  ///
  /// In en, this message translates to:
  /// **'A hundred days answering together, growing together. Few couples make it this far 🌟'**
  String get streakMilestone100Body;

  /// No description provided for @streakMilestone365Title.
  ///
  /// In en, this message translates to:
  /// **'A full year! 👑'**
  String get streakMilestone365Title;

  /// No description provided for @streakMilestone365Body.
  ///
  /// In en, this message translates to:
  /// **'365 days of never missing your connection. This is your love story 💞👑'**
  String get streakMilestone365Body;

  /// No description provided for @streakJournalSummary.
  ///
  /// In en, this message translates to:
  /// **'{n}-day streak · longest {m}'**
  String streakJournalSummary(int n, int m);

  /// No description provided for @streakJournalSummaryNone.
  ///
  /// In en, this message translates to:
  /// **'Answer together each day to start a streak 🌸'**
  String get streakJournalSummaryNone;

  /// forgotPasswordLink
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPasswordLink;

  /// forgotPasswordBadge
  ///
  /// In en, this message translates to:
  /// **'RECOVER ACCESS'**
  String get forgotPasswordBadge;

  /// forgotPasswordTitle
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get forgotPasswordTitle;

  /// forgotPasswordSubtitle
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we\'ll send you a link to reset your password.'**
  String get forgotPasswordSubtitle;

  /// forgotPasswordEmailHeading
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get forgotPasswordEmailHeading;

  /// forgotPasswordSendBtn
  ///
  /// In en, this message translates to:
  /// **'Send reset email'**
  String get forgotPasswordSendBtn;

  /// forgotPasswordBackToLogin
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get forgotPasswordBackToLogin;

  /// forgotPasswordSentTitle
  ///
  /// In en, this message translates to:
  /// **'Check your inbox'**
  String get forgotPasswordSentTitle;

  /// forgotPasswordSentBody
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent a password reset link to {email}. Open the email and tap the link to reset it. Don\'t forget to check your spam folder.'**
  String forgotPasswordSentBody(String email);

  /// forgotPasswordResendLink
  ///
  /// In en, this message translates to:
  /// **'Didn\'t get it? Resend'**
  String get forgotPasswordResendLink;

  /// forgotPasswordNetworkError
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send the email. Check your connection and try again.'**
  String get forgotPasswordNetworkError;

  /// forgotPasswordLocalFallback
  ///
  /// In en, this message translates to:
  /// **'This feature needs an internet connection. Please connect and try again.'**
  String get forgotPasswordLocalFallback;

  /// verifyEmailBadge
  ///
  /// In en, this message translates to:
  /// **'VERIFY EMAIL'**
  String get verifyEmailBadge;

  /// verifyEmailTitle
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get verifyEmailTitle;

  /// verifyEmailSubtitle
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent a verification link to {email}.'**
  String verifyEmailSubtitle(String email);

  /// verifyEmailBody
  ///
  /// In en, this message translates to:
  /// **'Open the email, tap the verification link, then come back here and tap \"I\'ve verified\".'**
  String get verifyEmailBody;

  /// verifyEmailCheckBtn
  ///
  /// In en, this message translates to:
  /// **'I\'ve verified'**
  String get verifyEmailCheckBtn;

  /// verifyEmailResend
  ///
  /// In en, this message translates to:
  /// **'Resend email'**
  String get verifyEmailResend;

  /// verifyEmailResendCountdown
  ///
  /// In en, this message translates to:
  /// **'Resend in {time}'**
  String verifyEmailResendCountdown(String time);

  /// verifyEmailNotYet
  ///
  /// In en, this message translates to:
  /// **'Not verified yet — please check your inbox and try again.'**
  String get verifyEmailNotYet;

  /// verifyEmailSuccess
  ///
  /// In en, this message translates to:
  /// **'Verified! Taking you in...'**
  String get verifyEmailSuccess;

  /// verifyEmailResendError
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t resend the email. Check your connection and try again.'**
  String get verifyEmailResendError;

  /// No description provided for @setupWaitingCoupleCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Share this code to connect'**
  String get setupWaitingCoupleCodeTitle;

  /// No description provided for @setupCoupleCodeDesc.
  ///
  /// In en, this message translates to:
  /// **'This is your couple\'s pairing code. Either of you can use it to reconnect.'**
  String get setupCoupleCodeDesc;

  /// No description provided for @setupCoupleCodeRejoinHint.
  ///
  /// In en, this message translates to:
  /// **'Save this code — you can use it to rejoin your space at any time.'**
  String get setupCoupleCodeRejoinHint;

  /// No description provided for @galleryNeedsCoupleToUpload.
  ///
  /// In en, this message translates to:
  /// **'Connect with your partner first before sharing photos 💞'**
  String get galleryNeedsCoupleToUpload;

  /// No description provided for @notifCenterTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifCenterTitle;

  /// No description provided for @notifCenterBadge.
  ///
  /// In en, this message translates to:
  /// **'WHAT\'S NEW'**
  String get notifCenterBadge;

  /// No description provided for @notifCenterEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get notifCenterEmptyTitle;

  /// No description provided for @notifCenterEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Activity from the two of you will appear here.'**
  String get notifCenterEmptyBody;

  /// No description provided for @notifGroupToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get notifGroupToday;

  /// No description provided for @notifGroupEarlier.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get notifGroupEarlier;

  /// No description provided for @notifUnreadCount.
  ///
  /// In en, this message translates to:
  /// **'{count} unread'**
  String notifUnreadCount(int count);

  /// No description provided for @notifAllCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up 💛'**
  String get notifAllCaughtUp;

  /// No description provided for @notifMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get notifMarkAllRead;

  /// No description provided for @notifClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get notifClearAll;

  /// No description provided for @notifClearAllConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear all notifications?'**
  String get notifClearAllConfirmTitle;

  /// No description provided for @notifClearAllConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'You won\'t be able to see these again.'**
  String get notifClearAllConfirmBody;

  /// No description provided for @notifDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get notifDismiss;

  /// No description provided for @notifGeneric.
  ///
  /// In en, this message translates to:
  /// **'You have a new notification'**
  String get notifGeneric;

  /// No description provided for @notifPhotoPosted.
  ///
  /// In en, this message translates to:
  /// **'{name} shared a new photo'**
  String notifPhotoPosted(String name);

  /// No description provided for @notifPhotoReaction.
  ///
  /// In en, this message translates to:
  /// **'{name} reacted {emoji} to your photo'**
  String notifPhotoReaction(String name, String emoji);

  /// No description provided for @notifPartnerJoined.
  ///
  /// In en, this message translates to:
  /// **'{name} paired up with you'**
  String notifPartnerJoined(String name);

  /// No description provided for @notifPartnerLeft.
  ///
  /// In en, this message translates to:
  /// **'{name} left your shared space'**
  String notifPartnerLeft(String name);

  /// No description provided for @notifLoveNote.
  ///
  /// In en, this message translates to:
  /// **'{name} left you a love note'**
  String notifLoveNote(String name);

  /// No description provided for @notifDailyQuestion.
  ///
  /// In en, this message translates to:
  /// **'{name} answered today\'s question'**
  String notifDailyQuestion(String name);

  /// No description provided for @notifChatMessage.
  ///
  /// In en, this message translates to:
  /// **'{name} sent you a message 💬'**
  String notifChatMessage(String name);

  /// No description provided for @forceUpdateBadge.
  ///
  /// In en, this message translates to:
  /// **'UPDATE'**
  String get forceUpdateBadge;

  /// No description provided for @forceUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'Time to update'**
  String get forceUpdateTitle;

  /// No description provided for @forceUpdateBody.
  ///
  /// In en, this message translates to:
  /// **'The version you\'re on is out of date. Update to the latest to keep making memories with your other half.'**
  String get forceUpdateBody;

  /// No description provided for @forceUpdateButton.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get forceUpdateButton;

  /// No description provided for @counterBgBadge.
  ///
  /// In en, this message translates to:
  /// **'BACKGROUND'**
  String get counterBgBadge;

  /// No description provided for @counterBgTitle.
  ///
  /// In en, this message translates to:
  /// **'Counter background'**
  String get counterBgTitle;

  /// No description provided for @counterBgSubtitleAll.
  ///
  /// In en, this message translates to:
  /// **'Pick which photos can back the day-counter card. Leave empty to cycle through them all.'**
  String get counterBgSubtitleAll;

  /// No description provided for @counterBgSubtitleCount.
  ///
  /// In en, this message translates to:
  /// **'{count} photos picked for the counter background.'**
  String counterBgSubtitleCount(int count);

  /// No description provided for @counterBgCoverLabel.
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get counterBgCoverLabel;

  /// No description provided for @counterBgEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No photos yet'**
  String get counterBgEmptyTitle;

  /// No description provided for @counterBgEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add some memories to your gallery first.'**
  String get counterBgEmptyBody;

  /// No description provided for @settingsCounterBgTitle.
  ///
  /// In en, this message translates to:
  /// **'Counter background'**
  String get settingsCounterBgTitle;

  /// No description provided for @settingsCounterBgSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose which photos show on the counter'**
  String get settingsCounterBgSubtitle;

  /// No description provided for @counterBgSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get counterBgSave;

  /// No description provided for @counterBgSavedMsg.
  ///
  /// In en, this message translates to:
  /// **'Counter background saved 💕'**
  String get counterBgSavedMsg;

  /// No description provided for @counterBgDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get counterBgDiscardTitle;

  /// No description provided for @counterBgDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Leave without saving?'**
  String get counterBgDiscardBody;

  /// No description provided for @counterBgDiscardLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get counterBgDiscardLeave;

  /// No description provided for @journeyTrailTitle.
  ///
  /// In en, this message translates to:
  /// **'Our journey'**
  String get journeyTrailTitle;

  /// No description provided for @milestoneTrailNext.
  ///
  /// In en, this message translates to:
  /// **'{days} days to {label}'**
  String milestoneTrailNext(int days, String label);

  /// No description provided for @milestoneTrailAllDone.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached every milestone 🎉'**
  String get milestoneTrailAllDone;

  /// No description provided for @profileAchievementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your badges'**
  String get profileAchievementsTitle;

  /// No description provided for @badgeStreakLabel.
  ///
  /// In en, this message translates to:
  /// **'day streak'**
  String get badgeStreakLabel;

  /// No description provided for @badgeRecordLabel.
  ///
  /// In en, this message translates to:
  /// **'record'**
  String get badgeRecordLabel;

  /// No description provided for @badgeMemoriesLabel.
  ///
  /// In en, this message translates to:
  /// **'memories'**
  String get badgeMemoriesLabel;

  /// No description provided for @badgeJournalLabel.
  ///
  /// In en, this message translates to:
  /// **'journal'**
  String get badgeJournalLabel;

  /// No description provided for @loveTreeBadge.
  ///
  /// In en, this message translates to:
  /// **'LOVE TREE'**
  String get loveTreeBadge;

  /// No description provided for @loveTreeStage0.
  ///
  /// In en, this message translates to:
  /// **'Tiny seed'**
  String get loveTreeStage0;

  /// No description provided for @loveTreeStage1.
  ///
  /// In en, this message translates to:
  /// **'Sprout'**
  String get loveTreeStage1;

  /// No description provided for @loveTreeStage2.
  ///
  /// In en, this message translates to:
  /// **'Young tree'**
  String get loveTreeStage2;

  /// No description provided for @loveTreeStage3.
  ///
  /// In en, this message translates to:
  /// **'Flourishing tree'**
  String get loveTreeStage3;

  /// No description provided for @loveTreeStage4.
  ///
  /// In en, this message translates to:
  /// **'In full bloom'**
  String get loveTreeStage4;

  /// No description provided for @loveTreeFlowerCount.
  ///
  /// In en, this message translates to:
  /// **'{count} flowers bloomed'**
  String loveTreeFlowerCount(int count);

  /// No description provided for @loveTreeFlowerCountZero.
  ///
  /// In en, this message translates to:
  /// **'No flowers yet — let\'s grow it together'**
  String get loveTreeFlowerCountZero;

  /// No description provided for @loveTreeSeedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your journey starts right here 🌱'**
  String get loveTreeSeedSubtitle;

  /// No description provided for @loveTreeBloomSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your tree is in full bloom ✨'**
  String get loveTreeBloomSubtitle;

  /// No description provided for @loveTreeNewBloomBanner.
  ///
  /// In en, this message translates to:
  /// **'Your tree just bloomed {count} new flowers 🌸'**
  String loveTreeNewBloomBanner(int count);

  /// No description provided for @loveTreeNewBloomBannerOne.
  ///
  /// In en, this message translates to:
  /// **'Your tree just bloomed a new flower 🌸'**
  String get loveTreeNewBloomBannerOne;

  /// No description provided for @loveTreeNurtureTitle.
  ///
  /// In en, this message translates to:
  /// **'Grow it together'**
  String get loveTreeNurtureTitle;

  /// No description provided for @loveTreeNurtureStreakTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep your daily streak'**
  String get loveTreeNurtureStreakTitle;

  /// No description provided for @loveTreeNurtureStreakBody.
  ///
  /// In en, this message translates to:
  /// **'Answer daily so your streak lives on'**
  String get loveTreeNurtureStreakBody;

  /// No description provided for @loveTreeNurturePhotoTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a memory'**
  String get loveTreeNurturePhotoTitle;

  /// No description provided for @loveTreeNurturePhotoBody.
  ///
  /// In en, this message translates to:
  /// **'Every photo is a new flower'**
  String get loveTreeNurturePhotoBody;

  /// No description provided for @loveTreeNurtureTalkTitle.
  ///
  /// In en, this message translates to:
  /// **'Talk together today'**
  String get loveTreeNurtureTalkTitle;

  /// No description provided for @loveTreeNurtureTalkBody.
  ///
  /// In en, this message translates to:
  /// **'Small moments grow the tree'**
  String get loveTreeNurtureTalkBody;

  /// No description provided for @loveTreeMilestonesTitle.
  ///
  /// In en, this message translates to:
  /// **'Milestones'**
  String get loveTreeMilestonesTitle;

  /// No description provided for @loveTreeMilestoneDays.
  ///
  /// In en, this message translates to:
  /// **'{count} days together'**
  String loveTreeMilestoneDays(int count);

  /// No description provided for @loveTreeMilestoneStreak.
  ///
  /// In en, this message translates to:
  /// **'{count}-day streak'**
  String loveTreeMilestoneStreak(int count);

  /// No description provided for @loveTreeMilestonePhotos.
  ///
  /// In en, this message translates to:
  /// **'{count} memories'**
  String loveTreeMilestonePhotos(int count);

  /// No description provided for @loveTreeMilestoneBloomed.
  ///
  /// In en, this message translates to:
  /// **'bloomed'**
  String get loveTreeMilestoneBloomed;

  /// No description provided for @loveTreeMilestoneDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} days to go'**
  String loveTreeMilestoneDaysLeft(int count);

  /// No description provided for @loveTreeMilestoneStreakLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} streak days to go'**
  String loveTreeMilestoneStreakLeft(int count);

  /// No description provided for @loveTreeMilestonePhotosLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} photos to go'**
  String loveTreeMilestonePhotosLeft(int count);

  /// No description provided for @loveTreeMilestoneAllDone.
  ///
  /// In en, this message translates to:
  /// **'all done 🌟'**
  String get loveTreeMilestoneAllDone;

  /// No description provided for @loveTreeWaitingTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting for both of you'**
  String get loveTreeWaitingTitle;

  /// No description provided for @loveTreeWaitingBody.
  ///
  /// In en, this message translates to:
  /// **'The tree grows when you\'re both here. Invite your partner 💌'**
  String get loveTreeWaitingBody;

  /// No description provided for @loveTreeWaitingCta.
  ///
  /// In en, this message translates to:
  /// **'Invite partner'**
  String get loveTreeWaitingCta;

  /// No description provided for @loveTreeNoCoupleBody.
  ///
  /// In en, this message translates to:
  /// **'Connect with your partner to start growing 🌱'**
  String get loveTreeNoCoupleBody;
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

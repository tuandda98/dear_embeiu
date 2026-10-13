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

  /// Stats line of the love-tree share card when the couple's anniversary is today (replaces '0 days together')
  ///
  /// In en, this message translates to:
  /// **'Our first day together'**
  String get loveTreeShareFirstDay;

  /// Share-sheet text for the love tree while no flower has bloomed yet (replaces 'has bloomed 0 flowers')
  ///
  /// In en, this message translates to:
  /// **'Our love tree just sprouted 🌱💞 — grow yours together on Dear Embeiu.'**
  String get loveTreeShareMessageSeed;

  /// Pill beside the partner's sleep times when their night was recorded in another time zone than this phone's
  ///
  /// In en, this message translates to:
  /// **'Their time'**
  String get sleepTheirClock;

  /// Sleep calendar cell suffix for a night logged by hand (screen reader)
  ///
  /// In en, this message translates to:
  /// **'(logged by hand)'**
  String get sleepManualSemantics;

  /// SnackBar when saving today's mood failed (the pick is rolled back)
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your mood, please try again'**
  String get moodSaveFailed;

  /// Settings → Account row and dialog title: an Apple/Google account adds a password so it can sign in with email elsewhere (audit AU1)
  ///
  /// In en, this message translates to:
  /// **'Set a password'**
  String get setPasswordTitle;

  /// Subtitle of the Settings 'Set a password' row
  ///
  /// In en, this message translates to:
  /// **'To sign in with your email on another phone'**
  String get setPasswordSubtitle;

  /// Set-password dialog body. email = the account's email, may be Apple's hidden relay address
  ///
  /// In en, this message translates to:
  /// **'Once set, you can sign in with {email} and this password, on iPhone or Android.'**
  String setPasswordBody(String email);

  /// Set-password dialog: Apple/Google may show their sheet first when the session is old. provider = 'Apple' or 'Google'
  ///
  /// In en, this message translates to:
  /// **'{provider} may ask you to confirm it\'s you.'**
  String setPasswordConfirmNote(String provider);

  /// SnackBar after the password was added; has a Copy action for the email
  ///
  /// In en, this message translates to:
  /// **'Password set. On another phone, sign in with {email}.'**
  String setPasswordDone(String email);

  /// Set password: the account got a password meanwhile (provider-already-linked)
  ///
  /// In en, this message translates to:
  /// **'This account already has a password.'**
  String get setPasswordAlreadySet;

  /// Set password: another account already signs in with this email
  ///
  /// In en, this message translates to:
  /// **'This email belongs to another account, so the password wasn\'t set.'**
  String get setPasswordEmailTaken;

  /// Set password: the Google confirmation picked another Google account (user-mismatch)
  ///
  /// In en, this message translates to:
  /// **'That\'s a different Google account. Pick the one you use for Dear Embeiu, then try again.'**
  String get setPasswordWrongGoogleAccount;

  /// Set password: any other error
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t set the password. Please try again.'**
  String get setPasswordFailed;

  /// Set password: this device's Apple ID isn't the account's. Usually iOS said so before the Apple sheet, the user stays signed in (BUG-27); rarely the sheet itself signed another Apple ID in and the app signed out
  ///
  /// In en, this message translates to:
  /// **'This device is using a different Apple ID. To set a password, open the app on a device that uses this account\'s Apple ID.'**
  String get setPasswordAppleIdMismatch;

  /// Tooltip of the eye button that reveals a password field
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// Tooltip of the eye button that hides a password field again
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// Profile badge label under the care-notes count
  ///
  /// In en, this message translates to:
  /// **'care notes'**
  String get badgeCareLabel;

  /// Eyebrow chip on the care-notes timeline screen.
  ///
  /// In en, this message translates to:
  /// **'CARE NOTES'**
  String get careTimelineBadge;

  /// Link next to the recent care notes that opens the full timeline.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get careTimelineSeeAll;

  /// Day header for care notes sent yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get careTimelineYesterday;

  /// Empty state title on the care timeline (also the profile tile subtitle when the count is zero).
  ///
  /// In en, this message translates to:
  /// **'No care notes yet'**
  String get careTimelineEmptyTitle;

  /// Empty state body on the care timeline.
  ///
  /// In en, this message translates to:
  /// **'Every little note the two of you send lands here, in order.'**
  String get careTimelineEmptyBody;

  /// Empty state button opening the care-note composer.
  ///
  /// In en, this message translates to:
  /// **'Send the first care note'**
  String get careTimelineEmptyCta;

  /// Error state on the care timeline.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the timeline.'**
  String get careTimelineLoadError;

  /// No description provided for @aiQuestionsTitle.
  ///
  /// In en, this message translates to:
  /// **'AI-personalised questions'**
  String get aiQuestionsTitle;

  /// No description provided for @aiQuestionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Uses the last 30 days of both your answers to write a question just for the two of you. The data is only used to create questions, never for training. Turn it off any time.'**
  String get aiQuestionsSubtitle;

  /// No description provided for @aiQuestionsDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn on personalised questions?'**
  String get aiQuestionsDialogTitle;

  /// No description provided for @aiQuestionsDialogBody.
  ///
  /// In en, this message translates to:
  /// **'This applies to both of you: your partner will see the AI-written question too. We only read the last 30 days of answers to create it — nothing is used for training, and you can turn it off any time. AI questions start from tomorrow\'s question.'**
  String get aiQuestionsDialogBody;

  /// No description provided for @aiQuestionsDialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get aiQuestionsDialogConfirm;

  /// No description provided for @introSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get introSkip;

  /// No description provided for @introNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get introNext;

  /// No description provided for @introStart.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get introStart;

  /// No description provided for @introSlide1Badge.
  ///
  /// In en, this message translates to:
  /// **'LOVE COUNTER'**
  String get introSlide1Badge;

  /// No description provided for @introSlide1Title.
  ///
  /// In en, this message translates to:
  /// **'Count every day together'**
  String get introSlide1Title;

  /// No description provided for @introSlide1Body.
  ///
  /// In en, this message translates to:
  /// **'See how long you have been together, reach every milestone, and watch your love tree grow day by day.'**
  String get introSlide1Body;

  /// No description provided for @introSlide2Badge.
  ///
  /// In en, this message translates to:
  /// **'EVERY DAY'**
  String get introSlide2Badge;

  /// No description provided for @introSlide2Title.
  ///
  /// In en, this message translates to:
  /// **'Memories & a question a day'**
  String get introSlide2Title;

  /// No description provided for @introSlide2Body.
  ///
  /// In en, this message translates to:
  /// **'A shared photo library, a daily question for both of you, your connection streak, and a chat corner just for the two of you.'**
  String get introSlide2Body;

  /// No description provided for @introSlide3Badge.
  ///
  /// In en, this message translates to:
  /// **'IT TAKES TWO'**
  String get introSlide3Badge;

  /// No description provided for @introSlide3Title.
  ///
  /// In en, this message translates to:
  /// **'It takes both of you'**
  String get introSlide3Title;

  /// No description provided for @introSlide3Body.
  ///
  /// In en, this message translates to:
  /// **'Dear Embeiu is a space for two. You create an invite code, your partner downloads the app (iOS/Android) and enters the code — that\'s it.'**
  String get introSlide3Body;

  /// No description provided for @featureTourBadge.
  ///
  /// In en, this message translates to:
  /// **'WHAT\'S NEW'**
  String get featureTourBadge;

  /// Feature tour sheet title, e.g. 'Version 1.6.0'
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String featureTourVersionTitle(String version);

  /// No description provided for @featureTourGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get featureTourGotIt;

  /// No description provided for @featureTourSettingsTile.
  ///
  /// In en, this message translates to:
  /// **'What\'s new'**
  String get featureTourSettingsTile;

  /// No description provided for @featureTourSettingsTileSub.
  ///
  /// In en, this message translates to:
  /// **'Take another look at the latest features'**
  String get featureTourSettingsTileSub;

  /// No description provided for @featureTourCareTitle.
  ///
  /// In en, this message translates to:
  /// **'Send a little care'**
  String get featureTourCareTitle;

  /// No description provided for @featureTourCareBody.
  ///
  /// In en, this message translates to:
  /// **'Write a short message and your partner gets a notification right away.'**
  String get featureTourCareBody;

  /// No description provided for @featureTourQuestionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Fresher daily questions'**
  String get featureTourQuestionsTitle;

  /// No description provided for @featureTourQuestionsBody.
  ///
  /// In en, this message translates to:
  /// **'Questions that follow the week, the month and your mood, a way to look back at old answers, and an optional AI personalisation you can turn on in Settings.'**
  String get featureTourQuestionsBody;

  /// No description provided for @featureTourInviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Easier to invite your partner'**
  String get featureTourInviteTitle;

  /// No description provided for @featureTourInviteBody.
  ///
  /// In en, this message translates to:
  /// **'Share a download link together with your invite code, with step-by-step guidance.'**
  String get featureTourInviteBody;

  /// No description provided for @homeWaitingBadge.
  ///
  /// In en, this message translates to:
  /// **'WAITING FOR THEM'**
  String get homeWaitingBadge;

  /// No description provided for @homeWaitingStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Send the invite'**
  String get homeWaitingStep1Title;

  /// No description provided for @homeWaitingStep1Desc.
  ///
  /// In en, this message translates to:
  /// **'Send the code in a message, or let them scan the QR code if you\'re together.'**
  String get homeWaitingStep1Desc;

  /// No description provided for @homeWaitingStep1Cta.
  ///
  /// In en, this message translates to:
  /// **'Send it to them 💌'**
  String get homeWaitingStep1Cta;

  /// No description provided for @homeWaitingStep1Copy.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get homeWaitingStep1Copy;

  /// No description provided for @homeWaitingStep2Title.
  ///
  /// In en, this message translates to:
  /// **'They install the app and sign up'**
  String get homeWaitingStep2Title;

  /// No description provided for @homeWaitingStep2Desc.
  ///
  /// In en, this message translates to:
  /// **'They need to install Dear Embeiu (iOS/Android), sign up, then pick <Join with code>.'**
  String get homeWaitingStep2Desc;

  /// No description provided for @homeWaitingStep3Title.
  ///
  /// In en, this message translates to:
  /// **'Entering the code is all it takes'**
  String get homeWaitingStep3Title;

  /// No description provided for @homeWaitingStep3Desc.
  ///
  /// In en, this message translates to:
  /// **'Once you are paired the app switches over by itself and you get a notification.'**
  String get homeWaitingStep3Desc;

  /// No description provided for @homeWaitingMeanwhileTitle.
  ///
  /// In en, this message translates to:
  /// **'While you wait, you can already:'**
  String get homeWaitingMeanwhileTitle;

  /// No description provided for @homeWaitingMeanwhileItem1.
  ///
  /// In en, this message translates to:
  /// **'Set your anniversary date'**
  String get homeWaitingMeanwhileItem1;

  /// No description provided for @homeWaitingMeanwhileItem2.
  ///
  /// In en, this message translates to:
  /// **'Add memories'**
  String get homeWaitingMeanwhileItem2;

  /// No description provided for @homeWaitingMeanwhileItem3.
  ///
  /// In en, this message translates to:
  /// **'Answer today\'s question'**
  String get homeWaitingMeanwhileItem3;

  /// No description provided for @homeWaitingMeanwhileFooter.
  ///
  /// In en, this message translates to:
  /// **'They will see all of it when they join.'**
  String get homeWaitingMeanwhileFooter;

  /// No description provided for @inviteFollowUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Your partner hasn\'t joined yet 💌'**
  String get inviteFollowUpTitle;

  /// Invite follow-up body. Since pairing-funnel PF10 it fires at the +20 hour mark; the key keeps its old 24h name.
  ///
  /// In en, this message translates to:
  /// **'Send the invite again — it only takes 10 seconds'**
  String get inviteFollowUpBody24h;

  /// No description provided for @inviteFollowUpBody72h.
  ///
  /// In en, this message translates to:
  /// **'Our memories are waiting for them. Remind them to download the app'**
  String get inviteFollowUpBody72h;

  /// Pill next to Copy / Share (and on the Home waiting card) that opens the invite QR sheet.
  ///
  /// In en, this message translates to:
  /// **'QR code'**
  String get inviteQrBtn;

  /// No description provided for @inviteQrTitle.
  ///
  /// In en, this message translates to:
  /// **'Let them scan this code'**
  String get inviteQrTitle;

  /// No description provided for @inviteQrBody.
  ///
  /// In en, this message translates to:
  /// **'They open their Camera and point it here to get Dear Embeiu, with your invite code ready.'**
  String get inviteQrBody;

  /// No description provided for @inviteQrFallback.
  ///
  /// In en, this message translates to:
  /// **'Can\'t scan? Read this code out for them to type in.'**
  String get inviteQrFallback;

  /// No description provided for @inviteQrDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get inviteQrDone;

  /// Screen reader label of the invite QR image.
  ///
  /// In en, this message translates to:
  /// **'Invite QR code, code {code}'**
  String inviteQrSemantics(String code);

  /// Setup sheet shown when the clipboard holds an invite link from the get page.
  ///
  /// In en, this message translates to:
  /// **'Use the code from your invite?'**
  String get clipboardInviteTitle;

  /// No description provided for @clipboardInviteBody.
  ///
  /// In en, this message translates to:
  /// **'The invite link you opened has this code. Pair up to join your partner\'s space.'**
  String get clipboardInviteBody;

  /// No description provided for @clipboardInviteJoin.
  ///
  /// In en, this message translates to:
  /// **'Pair up now'**
  String get clipboardInviteJoin;

  /// No description provided for @clipboardInviteSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get clipboardInviteSkip;

  /// Local nudge 2 hours after creating the couple, only while the invite hasn't been sent yet.
  ///
  /// In en, this message translates to:
  /// **'Send your partner the invite 💌'**
  String get inviteFollowUpTitle2h;

  /// No description provided for @inviteFollowUpBody2h.
  ///
  /// In en, this message translates to:
  /// **'Together right now? Let them scan the QR code. Apart? Send it in a message. It takes about 10 seconds.'**
  String get inviteFollowUpBody2h;

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
  /// **'Couldn\'t save your couple info. Please try again.'**
  String get setupErrorSaveCouple;

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
  /// **'Couldn\'t pair up. Please try again.'**
  String get setupErrorJoinCouple;

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

  /// No description provided for @chatStatusSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get chatStatusSent;

  /// No description provided for @chatStatusDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get chatStatusDelivered;

  /// No description provided for @chatStatusRead.
  ///
  /// In en, this message translates to:
  /// **'Seen'**
  String get chatStatusRead;

  /// No description provided for @lunarSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Lunar calendar'**
  String get lunarSectionTitle;

  /// No description provided for @lunarDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Lunar {month}/{day}'**
  String lunarDateLabel(int month, int day);

  /// No description provided for @lunarTodayLabel.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get lunarTodayLabel;

  /// No description provided for @lunarNextNewMoon.
  ///
  /// In en, this message translates to:
  /// **'Next 1st'**
  String get lunarNextNewMoon;

  /// No description provided for @lunarNextFullMoon.
  ///
  /// In en, this message translates to:
  /// **'Next full moon'**
  String get lunarNextFullMoon;

  /// No description provided for @lunarReminderToggle.
  ///
  /// In en, this message translates to:
  /// **'Lunar-day reminder'**
  String get lunarReminderToggle;

  /// No description provided for @lunarReminderToggleSub.
  ///
  /// In en, this message translates to:
  /// **'On your chosen days & times'**
  String get lunarReminderToggleSub;

  /// No description provided for @lunarNewMoonNotifTitle.
  ///
  /// In en, this message translates to:
  /// **'First day of the lunar month 🌙'**
  String get lunarNewMoonNotifTitle;

  /// No description provided for @lunarNewMoonNotifBody.
  ///
  /// In en, this message translates to:
  /// **'Today is the first day of the lunar month.'**
  String get lunarNewMoonNotifBody;

  /// No description provided for @lunarFullMoonNotifTitle.
  ///
  /// In en, this message translates to:
  /// **'Full moon day 🌕'**
  String get lunarFullMoonNotifTitle;

  /// No description provided for @lunarFullMoonNotifBody.
  ///
  /// In en, this message translates to:
  /// **'Today is the full moon (15th lunar day).'**
  String get lunarFullMoonNotifBody;

  /// No description provided for @lunarOtherDayNotifTitle.
  ///
  /// In en, this message translates to:
  /// **'Lunar day {day} 🌙'**
  String lunarOtherDayNotifTitle(int day);

  /// No description provided for @lunarOtherDayNotifBody.
  ///
  /// In en, this message translates to:
  /// **'Today is lunar day {day}.'**
  String lunarOtherDayNotifBody(int day);

  /// No description provided for @lunarCalendarBadge.
  ///
  /// In en, this message translates to:
  /// **'LUNAR CALENDAR'**
  String get lunarCalendarBadge;

  /// No description provided for @lunarOpenCalendar.
  ///
  /// In en, this message translates to:
  /// **'Open lunar calendar'**
  String get lunarOpenCalendar;

  /// No description provided for @lunarRemindDaysLabel.
  ///
  /// In en, this message translates to:
  /// **'Reminder days (lunar)'**
  String get lunarRemindDaysLabel;

  /// No description provided for @lunarRemindTimesLabel.
  ///
  /// In en, this message translates to:
  /// **'Reminder times'**
  String get lunarRemindTimesLabel;

  /// No description provided for @lunarAddTime.
  ///
  /// In en, this message translates to:
  /// **'Add time'**
  String get lunarAddTime;

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

  /// No description provided for @milestoneNextLabel.
  ///
  /// In en, this message translates to:
  /// **'Milestone: {label}'**
  String milestoneNextLabel(String label);

  /// No description provided for @milestoneDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day left} other{{count} days left}}'**
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
  /// **'{count, plural, =1{1 day until your next anniversary} other{{count} days until your next anniversary}}'**
  String daysUntilNextAnniversary(int count);

  /// No description provided for @addMemoryCta.
  ///
  /// In en, this message translates to:
  /// **'Add a memory'**
  String get addMemoryCta;

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

  /// No description provided for @dailyQuestionSubmitError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send your answer. Please try again.'**
  String get dailyQuestionSubmitError;

  /// Short label inside the celebratory pill shown when both members reacted
  ///
  /// In en, this message translates to:
  /// **'You both reacted'**
  String get reactionBothShort;

  /// Nudge shown when only the current user reacted, inviting the named partner to react too
  ///
  /// In en, this message translates to:
  /// **'Waiting for {name} to react…'**
  String reactionWaitingPartner(String name);

  /// Generic nudge when only the current user reacted and the partner has no name yet
  ///
  /// In en, this message translates to:
  /// **'Waiting for your partner to react…'**
  String get reactionWaitingPartnerGeneric;

  /// Generic word for the partner when their name is not set yet
  ///
  /// In en, this message translates to:
  /// **'Your partner'**
  String get reactionPartnerFallback;

  /// No description provided for @moodCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s mood'**
  String get moodCardTitle;

  /// No description provided for @moodMatched.
  ///
  /// In en, this message translates to:
  /// **'You both feel the same today 💞'**
  String get moodMatched;

  /// No description provided for @moodShareCta.
  ///
  /// In en, this message translates to:
  /// **'Share your mood'**
  String get moodShareCta;

  /// No description provided for @moodUpdateCta.
  ///
  /// In en, this message translates to:
  /// **'Update mood'**
  String get moodUpdateCta;

  /// No description provided for @moodNotSharedYou.
  ///
  /// In en, this message translates to:
  /// **'Tap to share'**
  String get moodNotSharedYou;

  /// Partner side of the mood card when they haven't shared today
  ///
  /// In en, this message translates to:
  /// **'{name} hasn\'t shared today'**
  String moodPartnerEmpty(String name);

  /// No description provided for @moodSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'How are you today?'**
  String get moodSheetTitle;

  /// No description provided for @moodNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Add a few words (optional)'**
  String get moodNoteHint;

  /// No description provided for @moodSaveCta.
  ///
  /// In en, this message translates to:
  /// **'Save mood'**
  String get moodSaveCta;

  /// No description provided for @moodHappy.
  ///
  /// In en, this message translates to:
  /// **'Happy'**
  String get moodHappy;

  /// No description provided for @moodLoved.
  ///
  /// In en, this message translates to:
  /// **'Loved'**
  String get moodLoved;

  /// No description provided for @moodMissing.
  ///
  /// In en, this message translates to:
  /// **'Missing you'**
  String get moodMissing;

  /// No description provided for @moodCalm.
  ///
  /// In en, this message translates to:
  /// **'Calm'**
  String get moodCalm;

  /// No description provided for @moodMeh.
  ///
  /// In en, this message translates to:
  /// **'Meh'**
  String get moodMeh;

  /// No description provided for @moodTired.
  ///
  /// In en, this message translates to:
  /// **'Tired'**
  String get moodTired;

  /// No description provided for @moodSad.
  ///
  /// In en, this message translates to:
  /// **'Sad'**
  String get moodSad;

  /// No description provided for @moodStressed.
  ///
  /// In en, this message translates to:
  /// **'Stressed'**
  String get moodStressed;

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

  /// No description provided for @dailyQuestionSent.
  ///
  /// In en, this message translates to:
  /// **'Your answer was sent 💞'**
  String get dailyQuestionSent;

  /// No description provided for @journalBadge.
  ///
  /// In en, this message translates to:
  /// **'QUESTION JOURNAL'**
  String get journalBadge;

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

  /// No description provided for @milestoneReached.
  ///
  /// In en, this message translates to:
  /// **'You just reached a beautiful milestone ✨'**
  String get milestoneReached;

  /// No description provided for @onlyDaysUntilMilestone.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Only 1 day until your next milestone.} other{Only {count} days until your next milestone.}}'**
  String onlyDaysUntilMilestone(int count);

  /// No description provided for @nextMilestonePrefix.
  ///
  /// In en, this message translates to:
  /// **'Next: {label}'**
  String nextMilestonePrefix(String label);

  /// No description provided for @daysCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
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
  /// **'{count, plural, =1{1 moment} other{{count} moments}}'**
  String momentsCount(int count);

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
  /// **'Couldn\'t open the camera. Try again, or turn on camera access for the app in your phone\'s Settings.'**
  String get cameraUnavailable;

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
  /// **'{count, plural, =1{1 moment · Swipe to expand post frame} other{{count} moments · Swipe to expand post frame}}'**
  String compactCaption(int count);

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
  /// **'{count, plural, =1{Added 1 photo!} other{Added {count} photos!}}'**
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

  /// No description provided for @photoOptionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Photo options'**
  String get photoOptionsTitle;

  /// No description provided for @replacePhotoAction.
  ///
  /// In en, this message translates to:
  /// **'Replace photo'**
  String get replacePhotoAction;

  /// No description provided for @galleryReplacePhotoTooltip.
  ///
  /// In en, this message translates to:
  /// **'Replace photo'**
  String get galleryReplacePhotoTooltip;

  /// No description provided for @replacingPhoto.
  ///
  /// In en, this message translates to:
  /// **'Updating photo...'**
  String get replacingPhoto;

  /// No description provided for @photoUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Photo updated'**
  String get photoUpdatedSuccess;

  /// No description provided for @photoUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Could not update photo right now.'**
  String get photoUpdateError;

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

  /// No description provided for @yourInviteCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Your account invite code'**
  String get yourInviteCodeLabel;

  /// No description provided for @editOurStoryBtn.
  ///
  /// In en, this message translates to:
  /// **'Edit our story'**
  String get editOurStoryBtn;

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
  /// **'Local data on this device has been cleared. Shared data in the cloud is preserved.'**
  String get localDataClearedMsg;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

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
  /// **'I want to keep our memories together on Dear Embeiu 💞\nEnter this invite code to pair with me: {code}\nGet the app & enter the code at: https://dearembeiu.com/get?code={code}'**
  String inviteShareMessage(String code);

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

  /// No description provided for @dailyQuestionReminderAddTime.
  ///
  /// In en, this message translates to:
  /// **'Add a time'**
  String get dailyQuestionReminderAddTime;

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

  /// No description provided for @dailyQuestionReminderNotifBodyAlt1.
  ///
  /// In en, this message translates to:
  /// **'There\'s a new question for the two of you — answer yours first 💞'**
  String get dailyQuestionReminderNotifBodyAlt1;

  /// No description provided for @dailyQuestionReminderNotifBodyAlt2.
  ///
  /// In en, this message translates to:
  /// **'A little question is waiting for you both, come answer it 🌸'**
  String get dailyQuestionReminderNotifBodyAlt2;

  /// No description provided for @dqPartnerOnlyNudgeTitle.
  ///
  /// In en, this message translates to:
  /// **'Just your partner left to answer 💌'**
  String get dqPartnerOnlyNudgeTitle;

  /// No description provided for @dailyQuestionReminderEndOfDayHint.
  ///
  /// In en, this message translates to:
  /// **'If the question is still unfinished at the end of the day, you\'ll also be nudged at 21:00 — plus 22:00 and 23:00 if you haven\'t answered yet.'**
  String get dailyQuestionReminderEndOfDayHint;

  /// No description provided for @dqEndOfDayNudgeTitle.
  ///
  /// In en, this message translates to:
  /// **'The day is winding down 🌙'**
  String get dqEndOfDayNudgeTitle;

  /// No description provided for @dqEndOfDayNudgeBody.
  ///
  /// In en, this message translates to:
  /// **'Today\'s question is still waiting — answer it before the day ends.'**
  String get dqEndOfDayNudgeBody;

  /// No description provided for @dqEndOfDayNudgePartnerBody.
  ///
  /// In en, this message translates to:
  /// **'Your partner hasn\'t answered today\'s question yet — give them a nudge.'**
  String get dqEndOfDayNudgePartnerBody;

  /// No description provided for @dqStreakWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Your streak is about to break! 🔥'**
  String get dqStreakWarningTitle;

  /// No description provided for @dqStreakWarningBody.
  ///
  /// In en, this message translates to:
  /// **'The day\'s almost over. Answer today\'s question to keep your {days}-day streak!'**
  String dqStreakWarningBody(int days);

  /// No description provided for @dqStreakWarningStartBody.
  ///
  /// In en, this message translates to:
  /// **'The day\'s almost over! Answer today\'s question to start a new streak.'**
  String get dqStreakWarningStartBody;

  /// No description provided for @dqStreakWarningFinalTitle.
  ///
  /// In en, this message translates to:
  /// **'Less than an hour left! ⏳'**
  String get dqStreakWarningFinalTitle;

  /// No description provided for @dqStreakWarningFinalBody.
  ///
  /// In en, this message translates to:
  /// **'Answer now so your {days}-day streak doesn\'t break 🔥'**
  String dqStreakWarningFinalBody(int days);

  /// No description provided for @dqStreakWarningFinalStartBody.
  ///
  /// In en, this message translates to:
  /// **'Answer now to start a new streak before the day ends 🌱'**
  String get dqStreakWarningFinalStartBody;

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
  /// **'{count, plural, =1{1 year} other{{count} years}}'**
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

  /// No description provided for @languageSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search languages'**
  String get languageSearchHint;

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

  /// No description provided for @customRemindersNotifyPartnerLabel.
  ///
  /// In en, this message translates to:
  /// **'Also remind my partner'**
  String get customRemindersNotifyPartnerLabel;

  /// No description provided for @customRemindersNotifyPartnerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your partner gets this reminder at the same time too'**
  String get customRemindersNotifyPartnerSubtitle;

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

  /// No description provided for @customRemindersUndoLabel.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get customRemindersUndoLabel;

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
  /// **'Email sign-in isn\'t available right now. Please try again later.'**
  String get authConfigNotFound;

  /// authEmailAlreadyUsed
  ///
  /// In en, this message translates to:
  /// **'This email is already in use.'**
  String get authEmailAlreadyUsed;

  /// authEmailPasswordNotEnabled
  ///
  /// In en, this message translates to:
  /// **'Email sign-in isn\'t available right now. Please try again later.'**
  String get authEmailPasswordNotEnabled;

  /// authFirebaseAuthGeneric
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t verify your account. Please try again.'**
  String get authFirebaseAuthGeneric;

  /// Sign in with Apple button label (iOS only, pairing-funnel PF2)
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// Label in the divider between the email form and the Apple/Google buttons
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get authOrDivider;

  /// Generic Sign in with Apple error
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sign in with Apple. Please try again.'**
  String get appleSignInFailed;

  /// Apple or Google sign-in returned an email that already belongs to another account (password, Apple or Google); provider-neutral (PF6)
  ///
  /// In en, this message translates to:
  /// **'This email already has an account. Sign in the way you did before.'**
  String get appleEmailHasPasswordAccount;

  /// Extra line in the delete-account dialog for Apple accounts, warning that the Apple sheet comes next
  ///
  /// In en, this message translates to:
  /// **'Apple will then show a sign-in sheet to confirm it\'s you.'**
  String get deleteAccountAppleNote;

  /// Body of the re-auth dialog for Apple accounts (no password field)
  ///
  /// In en, this message translates to:
  /// **'For your security, confirm with Apple again to permanently delete your account.'**
  String get deleteAccountReauthBodyApple;

  /// Sign in with Google button label (pairing-funnel PF15)
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// Generic Google sign-in error
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sign in with Google. Please try again.'**
  String get googleSignInFailed;

  /// Implied-consent line under the Apple/Google buttons, followed by a space, the privacyPolicyLabel link and a period
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our'**
  String get socialConsentPrefix;

  /// Body of the re-auth dialog for Google accounts (no password field); 'Delete permanently' is deleteAccountConfirmBtn
  ///
  /// In en, this message translates to:
  /// **'Tap Delete permanently to try again. If it still fails, sign in with Google again, then delete.'**
  String get deleteAccountReauthBodyGoogle;

  /// Deleting an Apple account, but the Apple sheet signed in with a different Apple ID (PF18); the user has been signed out
  ///
  /// In en, this message translates to:
  /// **'This device is using a different Apple ID. To delete the account, open the app on a device that uses this account\'s Apple ID.'**
  String get deleteAccountAppleIdMismatch;

  /// authFirebaseUserCreateFailed
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create your account. Please try again.'**
  String get authFirebaseUserCreateFailed;

  /// authFirestoreGeneric
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sync your account data. Please try again.'**
  String get authFirestoreGeneric;

  /// authFirestorePermissionDenied
  ///
  /// In en, this message translates to:
  /// **'The server didn\'t accept your account info. Please try again in a few minutes.'**
  String get authFirestorePermissionDenied;

  /// authFirestoreUnavailable
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach the server right now. It might be a network hiccup, so try again in a few minutes.'**
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
  /// **'Your connection seems unstable. Check it and try again.'**
  String get authNetworkError;

  /// authSessionNotReady
  ///
  /// In en, this message translates to:
  /// **'Your session isn\'t ready yet. Please sign in again.'**
  String get authSessionNotReady;

  /// authSessionUnavailable
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sign you in. Please try again.'**
  String get authSessionUnavailable;

  /// authTooManyRequests
  ///
  /// In en, this message translates to:
  /// **'Too many sign-in attempts — please try again in a few minutes.'**
  String get authTooManyRequests;

  /// Sign-in error: FirebaseAuth user-disabled
  ///
  /// In en, this message translates to:
  /// **'This account has been disabled, so you can\'t sign in.'**
  String get authUserDisabled;

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
  /// **'Can\'t reach the server right now. It might be a network hiccup, so try again in a few minutes.'**
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
  /// **'Couldn\'t upload your couple photo. Try changing it again later.'**
  String get couplePhotoUploadGeneric;

  /// couplePhotoUploadPermission
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t upload your couple photo. Your couple info is saved, so just try changing the photo again later.'**
  String get couplePhotoUploadPermission;

  /// couplePhotoUploadSessionInvalid
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t upload your couple photo because your session expired. Sign in again, then change the photo.'**
  String get couplePhotoUploadSessionInvalid;

  /// couplePhotoUploadUnavailable
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t upload your couple photo. The network or server is acting up. Please try again later.'**
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
  /// **'Your session has expired. Please sign in again.'**
  String get coupleSessionInvalid;

  /// coupleSessionNotReadyRelogin
  ///
  /// In en, this message translates to:
  /// **'Your session isn\'t ready yet. Please sign out and back in.'**
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

  /// leavingCouple
  ///
  /// In en, this message translates to:
  /// **'Leaving the couple...'**
  String get leavingCouple;

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
  /// **'This photo couldn\'t be found on the server.'**
  String get photoFileNotFoundStorage;

  /// photoFirebaseUnavailable
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach the server right now. It might be a network hiccup, so try again in a few minutes.'**
  String get photoFirebaseUnavailable;

  /// photoNotFoundToPost
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t find the photo to post.'**
  String get photoNotFoundToPost;

  /// photoStorageUnauthorized
  ///
  /// In en, this message translates to:
  /// **'You can\'t do that with this photo right now. Try signing out and back in.'**
  String get photoStorageUnauthorized;

  /// photoSyncGeneric
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sync photos right now.'**
  String get photoSyncGeneric;

  /// photoSyncPermissionDenied
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to sync photos yet. Try signing out and back in.'**
  String get photoSyncPermissionDenied;

  /// photoSyncSessionExpired
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please sign in again.'**
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
  /// **'{years, plural, =1{1 year} other{{years} years}}, {months, plural, =1{1 month} other{{months} months}}, {days, plural, =1{1 day} other{{days} days}}'**
  String counterDuration(int years, int months, int days);

  /// Error loading couple info
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your couple info. Please try again.'**
  String get coupleLoadError;

  /// Error syncing couple info
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sync your couple info. Please try again.'**
  String get coupleSyncError;

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
  /// **'{count, plural, =1{1 moment today} other{{count} moments today}}'**
  String galleryTodayMomentsCount(int count);

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

  /// Home-screen widget, empty state (guest / no couple / signed out). One line under the app-name chip; widget is 158pt wide, max 3 lines.
  ///
  /// In en, this message translates to:
  /// **'Tap to start counting your days together'**
  String get widgetEmptyTap;

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
  /// **'Sign in with email'**
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

  /// Streak sheet title when the couple had a streak before and it reset
  ///
  /// In en, this message translates to:
  /// **'Light the spark again'**
  String get streakSheetRestartTitle;

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
  /// **'{m, plural, =1{Your record: 1 day 🌟} other{Your record: {m} days 🌟}}'**
  String streakSheetRecord(int m);

  /// No description provided for @streakNextMilestone.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 day to your {m}-day milestone 🎉} other{{n} days to your {m}-day milestone 🎉}}'**
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

  /// No description provided for @notifDailyQuestionBoth.
  ///
  /// In en, this message translates to:
  /// **'You and {name} both answered today\'s question 💞'**
  String notifDailyQuestionBoth(String name);

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
  /// **'{count, plural, =1{1 photo picked for the counter background.} other{{count} photos picked for the counter background.}}'**
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

  /// No description provided for @settingsChatBgTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat background'**
  String get settingsChatBgTitle;

  /// No description provided for @settingsChatBgSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a photo to back your conversation'**
  String get settingsChatBgSubtitle;

  /// No description provided for @chatBgBadge.
  ///
  /// In en, this message translates to:
  /// **'CHAT BACKGROUND'**
  String get chatBgBadge;

  /// No description provided for @chatBgTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat background'**
  String get chatBgTitle;

  /// No description provided for @chatBgSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick one photo to back your conversation, or keep the default gradient.'**
  String get chatBgSubtitle;

  /// No description provided for @chatBgFilterHint.
  ///
  /// In en, this message translates to:
  /// **'Only portrait, high-resolution photos are shown — they fill the screen without cropping or blurring.'**
  String get chatBgFilterHint;

  /// No description provided for @chatBgNoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get chatBgNoneLabel;

  /// No description provided for @chatBgMeasuring.
  ///
  /// In en, this message translates to:
  /// **'Filtering photos…'**
  String get chatBgMeasuring;

  /// No description provided for @chatBgNoneValidTitle.
  ///
  /// In en, this message translates to:
  /// **'No suitable photos yet'**
  String get chatBgNoneValidTitle;

  /// No description provided for @chatBgNoneValidBody.
  ///
  /// In en, this message translates to:
  /// **'Add a tall, sharp photo to your gallery — landscape or low-resolution photos can\'t be used as a chat background.'**
  String get chatBgNoneValidBody;

  /// No description provided for @chatBgSavedMsg.
  ///
  /// In en, this message translates to:
  /// **'Chat background saved 💕'**
  String get chatBgSavedMsg;

  /// No description provided for @journeyTrailTitle.
  ///
  /// In en, this message translates to:
  /// **'Our journey'**
  String get journeyTrailTitle;

  /// No description provided for @milestoneTrailNext.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day to {label}} other{{days} days to {label}}}'**
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

  /// No description provided for @profileRecordsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your records'**
  String get profileRecordsTitle;

  /// No description provided for @profileRecordLongestStreak.
  ///
  /// In en, this message translates to:
  /// **'Longest streak'**
  String get profileRecordLongestStreak;

  /// No description provided for @profileRecordDaysTogether.
  ///
  /// In en, this message translates to:
  /// **'Days together'**
  String get profileRecordDaysTogether;

  /// No description provided for @profileRecordTotalMemories.
  ///
  /// In en, this message translates to:
  /// **'Total memories'**
  String get profileRecordTotalMemories;

  /// No description provided for @profileRecordJournalEntries.
  ///
  /// In en, this message translates to:
  /// **'Questions answered'**
  String get profileRecordJournalEntries;

  /// No description provided for @profileRecordStreakMilestones.
  ///
  /// In en, this message translates to:
  /// **'Streak milestones'**
  String get profileRecordStreakMilestones;

  /// Journal entry count value, e.g. '5 answered'
  ///
  /// In en, this message translates to:
  /// **'{count} answered'**
  String profileJournalCountLabel(String count);

  /// No description provided for @profileMemoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Our memories'**
  String get profileMemoriesTitle;

  /// Total memories subtitle in the memories sheet
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 memory} other{{count} memories}}'**
  String profileMemoriesCountLabel(int count);

  /// Motivation toward the next photo-count milestone
  ///
  /// In en, this message translates to:
  /// **'{count} more to reach {milestone}'**
  String profileMemoriesNextLabel(String count, String milestone);

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

  /// No description provided for @loveTreeFlowerCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 flower bloomed} other{{count} flowers bloomed}}'**
  String loveTreeFlowerCount(int count);

  /// No description provided for @loveTreeSeedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your journey starts right here 🌱'**
  String get loveTreeSeedSubtitle;

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

  /// No description provided for @loveTreeMilestoneDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day together} other{{count} days together}}'**
  String loveTreeMilestoneDays(int count);

  /// No description provided for @loveTreeMilestoneStreak.
  ///
  /// In en, this message translates to:
  /// **'{count}-day streak'**
  String loveTreeMilestoneStreak(int count);

  /// No description provided for @loveTreeMilestonePhotos.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 memory} other{{count} memories}}'**
  String loveTreeMilestonePhotos(int count);

  /// No description provided for @loveTreeMilestoneDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day to go} other{{count} days to go}}'**
  String loveTreeMilestoneDaysLeft(int count);

  /// No description provided for @loveTreeMilestoneStreakLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 streak day to go} other{{count} streak days to go}}'**
  String loveTreeMilestoneStreakLeft(int count);

  /// No description provided for @loveTreeMilestonePhotosLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 photo to go} other{{count} photos to go}}'**
  String loveTreeMilestonePhotosLeft(int count);

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

  /// No description provided for @loveTreeCoachTooltip.
  ///
  /// In en, this message translates to:
  /// **'Tap to see this moment 🌸'**
  String get loveTreeCoachTooltip;

  /// No description provided for @loveTreeMomentDaysTitle.
  ///
  /// In en, this message translates to:
  /// **'{count} days together'**
  String loveTreeMomentDaysTitle(int count);

  /// No description provided for @loveTreeMomentPhotosTitle.
  ///
  /// In en, this message translates to:
  /// **'Memory #{count}'**
  String loveTreeMomentPhotosTitle(int count);

  /// No description provided for @loveTreeMomentStreakTitle.
  ///
  /// In en, this message translates to:
  /// **'{count}-day streak record'**
  String loveTreeMomentStreakTitle(int count);

  /// No description provided for @loveTreeMomentBloomedOn.
  ///
  /// In en, this message translates to:
  /// **'Bloomed on {date}'**
  String loveTreeMomentBloomedOn(String date);

  /// No description provided for @loveTreeMomentPhotoTakenOn.
  ///
  /// In en, this message translates to:
  /// **'Added on {date}'**
  String loveTreeMomentPhotoTakenOn(String date);

  /// No description provided for @loveTreeMomentDaysCopy.
  ///
  /// In en, this message translates to:
  /// **'Every day together is one more petal in bloom 🌸'**
  String get loveTreeMomentDaysCopy;

  /// No description provided for @loveTreeMomentPhotosCopy.
  ///
  /// In en, this message translates to:
  /// **'A moment the two of you chose to keep 💞'**
  String get loveTreeMomentPhotosCopy;

  /// No description provided for @loveTreeMomentStreakCopy.
  ///
  /// In en, this message translates to:
  /// **'The record you two once kept together. Start a new streak to beat it 🔥'**
  String get loveTreeMomentStreakCopy;

  /// No description provided for @loveTreeMomentViewInGallery.
  ///
  /// In en, this message translates to:
  /// **'View in Gallery'**
  String get loveTreeMomentViewInGallery;

  /// No description provided for @loveTreeLockedDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day to go before this blooms 🌱} other{{count} days to go before this blooms 🌱}}'**
  String loveTreeLockedDays(int count);

  /// No description provided for @loveTreeLockedPhotos.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 memory to go before this blooms 🌱} other{{count} memories to go before this blooms 🌱}}'**
  String loveTreeLockedPhotos(int count);

  /// No description provided for @loveTreeLockedStreak.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 streak day to go before this blooms 🌱} other{{count} streak days to go before this blooms 🌱}}'**
  String loveTreeLockedStreak(int count);

  /// No description provided for @loveTreeLockedPhotosCta.
  ///
  /// In en, this message translates to:
  /// **'Add a memory'**
  String get loveTreeLockedPhotosCta;

  /// No description provided for @loveTreeLockedStreakCta.
  ///
  /// In en, this message translates to:
  /// **'Answer today'**
  String get loveTreeLockedStreakCta;

  /// No description provided for @loveTreeShareButton.
  ///
  /// In en, this message translates to:
  /// **'Share our tree'**
  String get loveTreeShareButton;

  /// No description provided for @loveTreeShareStats.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day together} other{{days} days together}} · {flowers, plural, =1{1 flower in bloom} other{{flowers} flowers in bloom}}'**
  String loveTreeShareStats(int days, int flowers);

  /// No description provided for @loveTreeShareTagline.
  ///
  /// In en, this message translates to:
  /// **'The tree we grew together 🌳'**
  String get loveTreeShareTagline;

  /// No description provided for @loveTreeShareTaglineSeed.
  ///
  /// In en, this message translates to:
  /// **'Our tree just sprouted 🌱'**
  String get loveTreeShareTaglineSeed;

  /// No description provided for @loveTreeShareMessage.
  ///
  /// In en, this message translates to:
  /// **'Our love tree has bloomed {flowers, plural, =1{1 flower} other{{flowers} flowers}} after {days, plural, =1{1 day} other{{days} days}} 🌳💞 — grow yours together on Dear Embeiu.'**
  String loveTreeShareMessage(int flowers, int days);

  /// No description provided for @partnerReminderNotifBody.
  ///
  /// In en, this message translates to:
  /// **'A reminder from your partner 💌'**
  String get partnerReminderNotifBody;

  /// Notification center title when the partner reacts to your daily-question answer.
  ///
  /// In en, this message translates to:
  /// **'{name} reacted {emoji} to your answer'**
  String notifAnswerReaction(String name, String emoji);

  /// Hint under a revealed partner answer inviting a reaction.
  ///
  /// In en, this message translates to:
  /// **'React to your partner\'s answer'**
  String get answerReactionHint;

  /// Tooltip/a11y label for the answer reaction heart button.
  ///
  /// In en, this message translates to:
  /// **'Add a reaction'**
  String get answerReactionAddTooltip;

  /// Tooltip/a11y label to remove your answer reaction.
  ///
  /// In en, this message translates to:
  /// **'Remove reaction'**
  String get answerReactionRemoveTooltip;

  /// Shown when writing an answer reaction failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send — tap to retry'**
  String get answerReactionErrorRetry;

  /// Eyebrow chip on the send-a-care-note screen.
  ///
  /// In en, this message translates to:
  /// **'CARE NOTE'**
  String get careMessageBadge;

  /// Profile menu entry opening the care-note composer.
  ///
  /// In en, this message translates to:
  /// **'Send a care note'**
  String get careMessageEntryTitle;

  /// Section title above the ready-made care-note chips.
  ///
  /// In en, this message translates to:
  /// **'Quick picks'**
  String get careMessageQuickPicksTitle;

  /// Label of the care-note title field.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get careMessageTitleLabel;

  /// Hint of the care-note title field.
  ///
  /// In en, this message translates to:
  /// **'e.g. Missing you'**
  String get careMessageTitleHint;

  /// Label of the care-note body field.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get careMessageBodyLabel;

  /// Hint of the care-note body field.
  ///
  /// In en, this message translates to:
  /// **'Write something warm...'**
  String get careMessageBodyHint;

  /// Primary button that sends the care note.
  ///
  /// In en, this message translates to:
  /// **'Send to your love 💌'**
  String get careMessageSendCta;

  /// aiQuestionsSaveFailed
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save that, please try again'**
  String get aiQuestionsSaveFailed;

  /// dailyQuestionPreparing
  ///
  /// In en, this message translates to:
  /// **'Getting today\'s question ready…'**
  String get dailyQuestionPreparing;

  /// Toast when the care note write timed out offline and is queued
  ///
  /// In en, this message translates to:
  /// **'Slow network — your note will be sent as soon as you\'re back online 💌'**
  String get careMessageQueuedToast;

  /// Snackbar after a care note was sent.
  ///
  /// In en, this message translates to:
  /// **'Sent 💌'**
  String get careMessageSentToast;

  /// Snackbar when sending a care note failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send. Please try again.'**
  String get careMessageErrorToast;

  /// Shown when the user has no active couple yet.
  ///
  /// In en, this message translates to:
  /// **'Pair up first to send a care note.'**
  String get careMessageNeedCouple;

  /// Section title above the recent care notes list.
  ///
  /// In en, this message translates to:
  /// **'Recently sent'**
  String get careMessageRecentTitle;

  /// Author label on a care note you sent.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get careMessageFromMe;

  /// Author label on a care note your partner sent.
  ///
  /// In en, this message translates to:
  /// **'Your love'**
  String get careMessageFromPartner;

  /// Quick-pick care note title 1.
  ///
  /// In en, this message translates to:
  /// **'Missing you 💕'**
  String get careQuick1Title;

  /// Quick-pick care note body 1.
  ///
  /// In en, this message translates to:
  /// **'Just thinking about you. How is your day going?'**
  String get careQuick1Body;

  /// Quick-pick care note title 2.
  ///
  /// In en, this message translates to:
  /// **'Drink some water 💧'**
  String get careQuick2Title;

  /// Quick-pick care note body 2.
  ///
  /// In en, this message translates to:
  /// **'Remember to stay hydrated today, okay?'**
  String get careQuick2Body;

  /// Quick-pick care note title 3.
  ///
  /// In en, this message translates to:
  /// **'Have you eaten? 🍚'**
  String get careQuick3Title;

  /// Quick-pick care note body 3.
  ///
  /// In en, this message translates to:
  /// **'Please eat on time today, no skipping meals.'**
  String get careQuick3Body;

  /// Quick-pick care note title 4.
  ///
  /// In en, this message translates to:
  /// **'Sleep early tonight 🌙'**
  String get careQuick4Title;

  /// Quick-pick care note body 4.
  ///
  /// In en, this message translates to:
  /// **'It is getting late, get some rest. Sweet dreams!'**
  String get careQuick4Body;

  /// Quick-pick care note title 5.
  ///
  /// In en, this message translates to:
  /// **'Love you so much ❤️'**
  String get careQuick5Title;

  /// Quick-pick care note body 5.
  ///
  /// In en, this message translates to:
  /// **'Just wanted to say I love you so much today.'**
  String get careQuick5Body;

  /// Quick-pick care note title 6.
  ///
  /// In en, this message translates to:
  /// **'You\'ve got this 💪'**
  String get careQuick6Title;

  /// Quick-pick care note body 6.
  ///
  /// In en, this message translates to:
  /// **'Today looks tough, but you\'ve got this. I am right here.'**
  String get careQuick6Body;

  /// Notification center title for a care note from the partner.
  ///
  /// In en, this message translates to:
  /// **'{name} sent you a care note'**
  String notifCareMessage(String name);

  /// Name of the rock-paper-scissors mini game (feature rps-game).
  ///
  /// In en, this message translates to:
  /// **'Rock Paper Scissors'**
  String get rpsGameTitle;

  /// Uppercase eyebrow chip naming the rock-paper-scissors screen.
  ///
  /// In en, this message translates to:
  /// **'ROCK PAPER SCISSORS'**
  String get rpsGameBadge;

  /// Rock-paper-scissors hand: rock.
  ///
  /// In en, this message translates to:
  /// **'Rock'**
  String get rpsChoiceRock;

  /// Rock-paper-scissors hand: paper.
  ///
  /// In en, this message translates to:
  /// **'Paper'**
  String get rpsChoicePaper;

  /// Rock-paper-scissors hand: scissors.
  ///
  /// In en, this message translates to:
  /// **'Scissors'**
  String get rpsChoiceScissors;

  /// Rock-paper-scissors: the player didn't pick before the timer ran out (history + result). Legacy — rounds before the 2026-09-14 no-skip rule; new rounds never produce it.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get rpsChoiceNone;

  /// Rock-paper-scissors result headline when the current user won.
  ///
  /// In en, this message translates to:
  /// **'You win 🎉'**
  String get rpsResultWin;

  /// Rock-paper-scissors result headline when the partner won.
  ///
  /// In en, this message translates to:
  /// **'Your person wins 😝'**
  String get rpsResultLose;

  /// Rock-paper-scissors result headline for a draw.
  ///
  /// In en, this message translates to:
  /// **'It\'s a draw 🤝'**
  String get rpsResultDraw;

  /// Rock-paper-scissors: invite sent, the partner hasn't opened the game yet.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your person…'**
  String get rpsWaitingPartner;

  /// Rock-paper-scissors: the user has picked a hand and is waiting for the partner.
  ///
  /// In en, this message translates to:
  /// **'You\'ve thrown ✓ · Waiting for your person…'**
  String get rpsChosenWaiting;

  /// Rock-paper-scissors: the invite went unanswered for 10 minutes.
  ///
  /// In en, this message translates to:
  /// **'This invite has expired'**
  String get rpsExpired;

  /// Rock-paper-scissors: the inviter withdrew the invite.
  ///
  /// In en, this message translates to:
  /// **'Your person cancelled the invite'**
  String get rpsCancelled;

  /// Notification center title for a rock-paper-scissors invite from the partner.
  ///
  /// In en, this message translates to:
  /// **'{name} challenged you to rock-paper-scissors!'**
  String notifRpsInvite(String name);

  /// Notification center title when a rock-paper-scissors game finished.
  ///
  /// In en, this message translates to:
  /// **'Your rock-paper-scissors game with {name} is over'**
  String notifRpsResult(String name);

  /// Uppercase eyebrow chip on the rock-paper-scissors history screen.
  ///
  /// In en, this message translates to:
  /// **'MATCH HISTORY'**
  String get rpsHistoryBadge;

  /// Home card subtitle when no game is open.
  ///
  /// In en, this message translates to:
  /// **'Challenge your person to a round'**
  String get rpsEntryIdleSubtitle;

  /// Home card score line for the current week (wins – draws – losses).
  ///
  /// In en, this message translates to:
  /// **'This week {win} – {draw} – {loss}'**
  String rpsEntryWeekScore(String win, String draw, String loss);

  /// Home card title when the partner has an open invite.
  ///
  /// In en, this message translates to:
  /// **'You\'re challenged!'**
  String get rpsEntryInvitedTitle;

  /// Home card subtitle when the partner has an open invite.
  ///
  /// In en, this message translates to:
  /// **'Hop in — they\'re waiting'**
  String get rpsEntryInvitedSubtitle;

  /// Home card subtitle while my own invite is pending.
  ///
  /// In en, this message translates to:
  /// **'Invite stays open for 10 minutes'**
  String get rpsEntryPendingSubtitle;

  /// Home card CTA (idle).
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get rpsEntryCtaPlay;

  /// Home card CTA when the partner invited me.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get rpsEntryCtaJoin;

  /// Home card CTA while my invite is pending.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get rpsEntryCtaOpen;

  /// Score triple (wins – draws – losses) with en dashes.
  ///
  /// In en, this message translates to:
  /// **'{win} – {draw} – {loss}'**
  String rpsScoreFormat(String win, String draw, String loss);

  /// Accessibility label for the score triple.
  ///
  /// In en, this message translates to:
  /// **'Score: you {win}, draw {draw}, your person {loss}'**
  String rpsScoreSemantics(String win, String draw, String loss);

  /// Accessibility label for a hand button.
  ///
  /// In en, this message translates to:
  /// **'Pick {choice}'**
  String rpsChoiceSemantics(String choice);

  /// One-line rules reminder under the three hand buttons.
  ///
  /// In en, this message translates to:
  /// **'Scissors cut Paper · Paper wraps Rock · Rock breaks Scissors'**
  String get rpsRulesHint;

  /// Rule line shown on the result screen.
  ///
  /// In en, this message translates to:
  /// **'Scissors cut Paper'**
  String get rpsRuleScissorsPaper;

  /// Rule line shown on the result screen.
  ///
  /// In en, this message translates to:
  /// **'Paper wraps Rock'**
  String get rpsRulePaperRock;

  /// Rule line shown on the result screen.
  ///
  /// In en, this message translates to:
  /// **'Rock breaks Scissors'**
  String get rpsRuleRockScissors;

  /// Label under my avatar / my card.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get rpsMeLabel;

  /// Label under the partner's avatar / card.
  ///
  /// In en, this message translates to:
  /// **'Your person'**
  String get rpsPartnerLabel;

  /// The small 'vs' pill between the two players.
  ///
  /// In en, this message translates to:
  /// **'vs'**
  String get rpsVs;

  /// Waiting screen body for the inviter. Neutral on purpose (Tester RPS-21): the CF may skip the push (partner still on the previous result screen), so never claim they were notified.
  ///
  /// In en, this message translates to:
  /// **'Invite sent. Waiting for your person…'**
  String get rpsWaitingBody;

  /// Waiting screen body for the invitee.
  ///
  /// In en, this message translates to:
  /// **'Connecting to your person… The round starts once you\'re both here.'**
  String get rpsWaitingBodyInvitee;

  /// Waiting screen: re-send the invite push.
  ///
  /// In en, this message translates to:
  /// **'Nudge again'**
  String get rpsNudgeCta;

  /// Waiting screen nudge button while on cooldown.
  ///
  /// In en, this message translates to:
  /// **'Nudge again ({seconds}s)'**
  String rpsNudgeCooldown(String seconds);

  /// Toast after re-sending the invite.
  ///
  /// In en, this message translates to:
  /// **'Nudged your person again 🔔'**
  String get rpsNudgeSentToast;

  /// Waiting screen: creator withdraws the invite.
  ///
  /// In en, this message translates to:
  /// **'Cancel invite'**
  String get rpsCancelCta;

  /// Tertiary close button on the game screen.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get rpsCloseCta;

  /// Toast after the creator cancelled the invite.
  ///
  /// In en, this message translates to:
  /// **'Invite cancelled'**
  String get rpsCancelledToast;

  /// Prompt under the countdown ring.
  ///
  /// In en, this message translates to:
  /// **'Pick now!'**
  String get rpsCountdownPrompt;

  /// Micro-caps unit under the countdown number.
  ///
  /// In en, this message translates to:
  /// **'SEC'**
  String get rpsCountdownUnit;

  /// Accessibility live label for the countdown.
  ///
  /// In en, this message translates to:
  /// **'{seconds, plural, =1{1 second left} other{{seconds} seconds left}}'**
  String rpsCountdownSemantics(int seconds);

  /// Caption while the server settles the round.
  ///
  /// In en, this message translates to:
  /// **'Revealing…'**
  String get rpsResolving;

  /// Caption when settling takes more than 6 seconds.
  ///
  /// In en, this message translates to:
  /// **'Connection is a bit slow…'**
  String get rpsResolvingSlow;

  /// Button to re-read the game when settling is slow.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get rpsReloadCta;

  /// Offline strip above the hand buttons.
  ///
  /// In en, this message translates to:
  /// **'Offline — your pick will go through once you\'re back online'**
  String get rpsOfflineHint;

  /// Result subtitle for a draw.
  ///
  /// In en, this message translates to:
  /// **'Both picked {choice}'**
  String rpsResultDrawSub(String choice);

  /// Result subtitle when the partner skipped. Legacy — rounds before the 2026-09-14 no-skip rule; new rounds never produce it.
  ///
  /// In en, this message translates to:
  /// **'Your person didn\'t pick in time'**
  String get rpsResultTimeoutPartner;

  /// Result subtitle when I skipped. Legacy — rounds before the 2026-09-14 no-skip rule; new rounds never produce it.
  ///
  /// In en, this message translates to:
  /// **'You didn\'t pick in time'**
  String get rpsResultTimeoutMe;

  /// Result subtitle when both skipped. Legacy — rounds before the 2026-09-14 no-skip rule; new rounds never produce it.
  ///
  /// In en, this message translates to:
  /// **'Both skipped — this round is a draw'**
  String get rpsResultTimeoutBoth;

  /// Result screen primary CTA.
  ///
  /// In en, this message translates to:
  /// **'Play again'**
  String get rpsRematchCta;

  /// Result screen secondary CTA.
  ///
  /// In en, this message translates to:
  /// **'View history'**
  String get rpsHistoryCta;

  /// Toast when the partner created a rematch while I'm on the result screen.
  ///
  /// In en, this message translates to:
  /// **'Your person wants a rematch!'**
  String get rpsRematchToast;

  /// Accessibility summary of the result.
  ///
  /// In en, this message translates to:
  /// **'{title}. You picked {mine}, your person picked {theirs}.'**
  String rpsResultSemantics(String title, String mine, String theirs);

  /// Body of the expired-invite state.
  ///
  /// In en, this message translates to:
  /// **'This invite expired after 10 minutes. Start a new round!'**
  String get rpsExpiredBody;

  /// Body of the cancelled-invite state.
  ///
  /// In en, this message translates to:
  /// **'No worries — you two can play another round any time.'**
  String get rpsCancelledBody;

  /// CTA on the expired/cancelled states.
  ///
  /// In en, this message translates to:
  /// **'Challenge again'**
  String get rpsInviteAgainCta;

  /// Error state title on the game screen.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the round'**
  String get rpsErrorTitle;

  /// Error state body on the game screen.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get rpsErrorBody;

  /// Shown when there is no partner to play with.
  ///
  /// In en, this message translates to:
  /// **'You need your person in the app to play.'**
  String get rpsNeedCouple;

  /// Scoreboard column header (mine).
  ///
  /// In en, this message translates to:
  /// **'ME'**
  String get rpsScoreMe;

  /// Scoreboard column header (draws).
  ///
  /// In en, this message translates to:
  /// **'DRAW'**
  String get rpsScoreDraw;

  /// Scoreboard column header (partner).
  ///
  /// In en, this message translates to:
  /// **'THEM'**
  String get rpsScorePartner;

  /// Scoreboard footer: total rounds.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 round played} other{{count} rounds played}}'**
  String rpsHistoryTotal(int count);

  /// Scoreboard footer: my current win streak (hidden at 0).
  ///
  /// In en, this message translates to:
  /// **'Win streak: {count}'**
  String rpsHistoryWinStreak(String count);

  /// History row outcome pill.
  ///
  /// In en, this message translates to:
  /// **'You won'**
  String get rpsOutcomeWin;

  /// History row outcome pill.
  ///
  /// In en, this message translates to:
  /// **'They won'**
  String get rpsOutcomeLoss;

  /// History row outcome pill.
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get rpsOutcomeDraw;

  /// History row outcome pill when a hand was missing. Legacy — rounds before the 2026-09-14 no-skip rule; new rounds never produce it.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get rpsOutcomeSkipped;

  /// Accessibility label for a history row.
  ///
  /// In en, this message translates to:
  /// **'{time}: you {mine}, your person {theirs}, {outcome}'**
  String rpsHistoryRowSemantics(
    String time,
    String mine,
    String theirs,
    String outcome,
  );

  /// History empty state title.
  ///
  /// In en, this message translates to:
  /// **'No rounds yet'**
  String get rpsHistoryEmptyTitle;

  /// History empty state body.
  ///
  /// In en, this message translates to:
  /// **'Every round you two play lands here — draws included.'**
  String get rpsHistoryEmptyBody;

  /// History empty state CTA.
  ///
  /// In en, this message translates to:
  /// **'Challenge your person'**
  String get rpsHistoryEmptyCta;

  /// Feature tour entry title (build 23).
  ///
  /// In en, this message translates to:
  /// **'Rock-paper-scissors together'**
  String get featureTourRpsTitle;

  /// Feature tour entry body (build 23).
  ///
  /// In en, this message translates to:
  /// **'Send a challenge, count it down together and throw. No skipping — whoever hasn\'t thrown gets a nudge, and the reveal waits for both of you. History and score live on your Profile.'**
  String get featureTourRpsBody;

  /// Feature tour entry (build 25).
  ///
  /// In en, this message translates to:
  /// **'Our sleep'**
  String get featureTourSleepTitle;

  /// Feature tour entry (build 25).
  ///
  /// In en, this message translates to:
  /// **'A moon calendar for every night: the fuller the moon, the better you slept. Share with each other and every morning you\'ll see how long your partner slept.'**
  String get featureTourSleepBody;

  /// Feature tour entry (build 25).
  ///
  /// In en, this message translates to:
  /// **'Today\'s constellation'**
  String get featureTourSkyTitle;

  /// Feature tour entry (build 25).
  ///
  /// In en, this message translates to:
  /// **'The Love Tree now has a night sky. Each of you has 3 stars: answer the question, pick a mood, send a message. Light all 6 and the heart is complete.'**
  String get featureTourSkyBody;

  /// Play screen caption once the 5s beat is over and nobody has thrown (no time limit).
  ///
  /// In en, this message translates to:
  /// **'Go on, throw! No skipping here 😄'**
  String get rpsOpenPrompt;

  /// Screen-reader label of the ring once the 5s beat is over.
  ///
  /// In en, this message translates to:
  /// **'No time limit — throw when you\'re ready'**
  String get rpsOpenRingSemantics;

  /// Play screen banner + Home card title: the partner has thrown, I have not (never says which hand).
  ///
  /// In en, this message translates to:
  /// **'Your person has thrown!'**
  String get rpsPartnerMovedTitle;

  /// Play screen banner body under rpsPartnerMovedTitle.
  ///
  /// In en, this message translates to:
  /// **'Your move — pick a hand below'**
  String get rpsPartnerMovedBody;

  /// Play screen: I have thrown, ask the partner (push) to throw too.
  ///
  /// In en, this message translates to:
  /// **'Nudge your person'**
  String get rpsMoveNudgeCta;

  /// Play screen nudge button during its 60s cooldown.
  ///
  /// In en, this message translates to:
  /// **'Nudged · again in {seconds}s'**
  String rpsMoveNudgeCooldown(String seconds);

  /// Snackbar after the move nudge was sent.
  ///
  /// In en, this message translates to:
  /// **'Nudged your person 🔔'**
  String get rpsMoveNudgeSentToast;

  /// Snackbar when the server refused the move nudge because of the cooldown.
  ///
  /// In en, this message translates to:
  /// **'You just nudged — try again in {seconds}s'**
  String rpsMoveNudgeTooSoon(String seconds);

  /// Snackbar when the move nudge failed (network / other error).
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send the nudge — try again'**
  String get rpsMoveNudgeFailed;

  /// Play screen hint under the nudge button: leaving is fine, the result is pushed.
  ///
  /// In en, this message translates to:
  /// **'Feel free to step away — we\'ll tell you the result'**
  String get rpsChosenLeaveHint;

  /// Home card subtitle when the partner has thrown and I have not.
  ///
  /// In en, this message translates to:
  /// **'Your turn — go ahead 😄'**
  String get rpsEntryMyTurnSubtitle;

  /// Home card title: a started round where nobody has thrown yet.
  ///
  /// In en, this message translates to:
  /// **'Round in progress'**
  String get rpsEntryUnplayedTitle;

  /// Home card subtitle for rpsEntryUnplayedTitle.
  ///
  /// In en, this message translates to:
  /// **'No one\'s thrown — go first'**
  String get rpsEntryUnplayedSubtitle;

  /// Home card title: I have thrown, the partner has not.
  ///
  /// In en, this message translates to:
  /// **'Waiting for their move'**
  String get rpsEntryAwaitingTitle;

  /// Home card subtitle for rpsEntryAwaitingTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'ve thrown · we\'ll tell you'**
  String get rpsEntryAwaitingSubtitle;

  /// Home card CTA to open a started round and throw.
  ///
  /// In en, this message translates to:
  /// **'Throw'**
  String get rpsEntryCtaThrow;

  /// Notification center title: the partner threw in rock-paper-scissors and it is my move.
  ///
  /// In en, this message translates to:
  /// **'{name} has thrown — your move!'**
  String notifRpsMoved(String name);

  /// Sleep: Home card title
  ///
  /// In en, this message translates to:
  /// **'Last night'**
  String get sleepCardTitle;

  /// Sleep screen header chip
  ///
  /// In en, this message translates to:
  /// **'SLEEP'**
  String get sleepBadge;

  /// Sleep: label for my own data
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get sleepYou;

  /// Sleep: hour unit after a big number (7g 15p)
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get sleepUnitHour;

  /// Sleep: minute unit after a big number
  ///
  /// In en, this message translates to:
  /// **'m'**
  String get sleepUnitMinute;

  /// Sleep: compact duration
  ///
  /// In en, this message translates to:
  /// **'{h}h {m}m'**
  String sleepDurationShort(int h, int m);

  /// Sleep: compact duration under one hour
  ///
  /// In en, this message translates to:
  /// **'{m}m'**
  String sleepMinutesShort(int m);

  /// Sleep: spelled-out duration (screen readers, edit total)
  ///
  /// In en, this message translates to:
  /// **'{h} hr {m} min'**
  String sleepDurationLong(int h, int m);

  /// Sleep: overlap of both sleeps
  ///
  /// In en, this message translates to:
  /// **'Asleep together {duration}'**
  String sleepTogether(String duration);

  /// Sleep: who fell asleep first, shown when 10+ min apart
  ///
  /// In en, this message translates to:
  /// **'{name} fell asleep {duration} earlier'**
  String sleepWentFirst(String name, String duration);

  /// Sleep card footer when the two sleeps did not overlap
  ///
  /// In en, this message translates to:
  /// **'You didn\'t sleep at the same time last night'**
  String get sleepNoOverlap;

  /// Sleep card before tracking is on
  ///
  /// In en, this message translates to:
  /// **'Let your phone log your sleep and see each morning how your person slept.'**
  String get sleepSetupPitch;

  /// Sleep card CTA opening the setup sheet
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get sleepEnableCta;

  /// Sleep card: hide for 30 days
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get sleepHide;

  /// Sleep: no night found for me
  ///
  /// In en, this message translates to:
  /// **'Not recorded'**
  String get sleepNotRecorded;

  /// Sleep: link opening the edit sheet to log a night by hand
  ///
  /// In en, this message translates to:
  /// **'Log it'**
  String get sleepLogManually;

  /// Sleep card: partner does not share
  ///
  /// In en, this message translates to:
  /// **'Not shared'**
  String get sleepPartnerNotShared;

  /// Sleep screen: partner does not share
  ///
  /// In en, this message translates to:
  /// **'{name} isn\'t sharing sleep'**
  String sleepPartnerNotSharedLong(String name);

  /// Sleep: partner shares but has no night
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get sleepNoData;

  /// Sleep: Android usage access lost
  ///
  /// In en, this message translates to:
  /// **'Permission needed'**
  String get sleepNeedsPermission;

  /// Sleep: open the permission settings
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get sleepOpenSettings;

  /// Sleep screen banner when Android usage access is off
  ///
  /// In en, this message translates to:
  /// **'The app can\'t see when your screen turns on or off, so it can\'t log your sleep. Turn it back on in Settings → Usage access.'**
  String get sleepPermissionBanner;

  /// Sleep screen segmented: both people
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get sleepViewBoth;

  /// Sleep calendar arrow (screen reader)
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get sleepPrevMonth;

  /// Sleep calendar arrow (screen reader)
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get sleepNextMonth;

  /// Sleep night detail title, d1 = day of the evening, d2 = wake date (10/10)
  ///
  /// In en, this message translates to:
  /// **'Night of {d1} → {d2}'**
  String sleepNightTitle(String d1, String d2);

  /// Sleep: number of short wake-ups
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Woke up once} other{Woke up {count} times}}'**
  String sleepAwakenings(int count);

  /// Sleep: no wake-up
  ///
  /// In en, this message translates to:
  /// **'Slept straight through'**
  String get sleepNoAwakenings;

  /// Sleep label: night edited by its owner (everyone sees it)
  ///
  /// In en, this message translates to:
  /// **'Edited'**
  String get sleepSourceEdited;

  /// Sleep label: night logged by hand (everyone sees it)
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get sleepSourceManual;

  /// Sleep source name
  ///
  /// In en, this message translates to:
  /// **'Apple Health'**
  String get sleepSourceHealth;

  /// Sleep source name on Android
  ///
  /// In en, this message translates to:
  /// **'Phone (automatic)'**
  String get sleepSourcePhone;

  /// Sleep source name: motion fallback (phone lying still)
  ///
  /// In en, this message translates to:
  /// **'Phone motion'**
  String get sleepSourceMotion;

  /// Sleep settings row
  ///
  /// In en, this message translates to:
  /// **'Source: {source}'**
  String sleepSourceRow(String source);

  /// Sleep stats section title for the current month
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get sleepMonthSection;

  /// Sleep stats unit after the average
  ///
  /// In en, this message translates to:
  /// **'/night'**
  String get sleepPerNight;

  /// Sleep stats: average bed and wake time
  ///
  /// In en, this message translates to:
  /// **'Bed ~{bed} · Up ~{wake}'**
  String sleepAvgTimes(String bed, String wake);

  /// Sleep stats: nights of 8 hours or more
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 full night} other{{count} full nights}}'**
  String sleepFullNights(int count);

  /// Sleep stats: nights with data
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{of 1 night} other{of {count} nights}}'**
  String sleepOfNights(int count);

  /// Sleep stats: nights with 7h+ overlap
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 night asleep together 7h+} other{{count} nights asleep together 7h+}}'**
  String sleepTogetherNights(int count);

  /// Sleep stats: average overlap
  ///
  /// In en, this message translates to:
  /// **'avg. {duration} a night'**
  String sleepTogetherAvg(String duration);

  /// Sleep settings switch
  ///
  /// In en, this message translates to:
  /// **'Share with your person'**
  String get sleepShareToggle;

  /// Sleep settings switch subtitle
  ///
  /// In en, this message translates to:
  /// **'When off, only you can see it.'**
  String get sleepShareToggleSub;

  /// Sleep settings row + explainer sheet title
  ///
  /// In en, this message translates to:
  /// **'How is sleep worked out?'**
  String get sleepHowItWorks;

  /// Sleep settings: color picker title
  ///
  /// In en, this message translates to:
  /// **'Your moon color'**
  String get sleepMyColor;

  /// Sleep color picker subtitle
  ///
  /// In en, this message translates to:
  /// **'{name} uses {color}. Colors too close to it ({blocked}) are locked.'**
  String sleepMyColorSub(String name, String color, String blocked);

  /// Sleep color picker subtitle when nothing else is locked
  ///
  /// In en, this message translates to:
  /// **'{name} uses {color}.'**
  String sleepMyColorSubNoBlock(String name, String color);

  /// Sleep color picker subtitle without partner data
  ///
  /// In en, this message translates to:
  /// **'This color marks your sleep everywhere.'**
  String get sleepMyColorSolo;

  /// Sleep color picker: swatch used by the partner (screen reader)
  ///
  /// In en, this message translates to:
  /// **'{name}\'s color'**
  String sleepColorTakenSemantics(String name);

  /// Sleep color picker: locked swatch (screen reader)
  ///
  /// In en, this message translates to:
  /// **'Too close to {name}\'s color'**
  String sleepColorTooClose(String name);

  /// Sleep color picker when both picked clashing colors
  ///
  /// In en, this message translates to:
  /// **'Your color matched your person\'s, so {color} shows for now.'**
  String sleepColorAutoChanged(String color);

  /// Sleep color name
  ///
  /// In en, this message translates to:
  /// **'Pink'**
  String get sleepColorRose;

  /// Sleep color name
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get sleepColorPurple;

  /// Sleep color name
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get sleepColorBlue;

  /// Sleep color name
  ///
  /// In en, this message translates to:
  /// **'Teal'**
  String get sleepColorTeal;

  /// Sleep color name
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get sleepColorOrange;

  /// Sleep color name
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get sleepColorGreen;

  /// Sleep color name
  ///
  /// In en, this message translates to:
  /// **'Magenta'**
  String get sleepColorMagenta;

  /// Sleep color name
  ///
  /// In en, this message translates to:
  /// **'Amber'**
  String get sleepColorAmber;

  /// Sleep moon legend
  ///
  /// In en, this message translates to:
  /// **'<5h'**
  String get sleepLegend0;

  /// Sleep moon legend
  ///
  /// In en, this message translates to:
  /// **'5–6h'**
  String get sleepLegend1;

  /// Sleep moon legend
  ///
  /// In en, this message translates to:
  /// **'6–7h'**
  String get sleepLegend2;

  /// Sleep moon legend
  ///
  /// In en, this message translates to:
  /// **'7–8h'**
  String get sleepLegend3;

  /// Sleep moon legend
  ///
  /// In en, this message translates to:
  /// **'8h+'**
  String get sleepLegend4;

  /// Sleep calendar legend line
  ///
  /// In en, this message translates to:
  /// **'The fuller the moon, the fuller the sleep'**
  String get sleepMoonTagline;

  /// Sleep calendar legend (both view)
  ///
  /// In en, this message translates to:
  /// **'Left moon: you'**
  String get sleepMoonLeft;

  /// Sleep calendar legend (both view)
  ///
  /// In en, this message translates to:
  /// **'Right moon: {name}'**
  String sleepMoonRight(String name);

  /// Sleep calendar legend: the heart
  ///
  /// In en, this message translates to:
  /// **'Asleep together 7h+'**
  String get sleepMoonTogether;

  /// Sleep moon phase, under 5 hours
  ///
  /// In en, this message translates to:
  /// **'Thin crescent'**
  String get sleepPhase0;

  /// Sleep moon phase, 5–6 hours
  ///
  /// In en, this message translates to:
  /// **'Crescent'**
  String get sleepPhase1;

  /// Sleep moon phase, 6–7 hours
  ///
  /// In en, this message translates to:
  /// **'Half moon'**
  String get sleepPhase2;

  /// Sleep moon phase, 7–8 hours
  ///
  /// In en, this message translates to:
  /// **'Gibbous moon'**
  String get sleepPhase3;

  /// Sleep moon phase, 8 hours or more
  ///
  /// In en, this message translates to:
  /// **'Full moon'**
  String get sleepPhase4;

  /// Sleep calendar cell (screen reader)
  ///
  /// In en, this message translates to:
  /// **'{day}: {summary}'**
  String sleepDaySemantics(String day, String summary);

  /// Sleep calendar cell part (screen reader)
  ///
  /// In en, this message translates to:
  /// **'{name} slept {duration}, {phase}'**
  String sleepSemanticsSlept(String name, String duration, String phase);

  /// Sleep calendar cell part (screen reader)
  ///
  /// In en, this message translates to:
  /// **'{name}: no data'**
  String sleepSemanticsNoData(String name);

  /// Sleep calendar cell suffix for edited/manual nights (screen reader)
  ///
  /// In en, this message translates to:
  /// **'(edited)'**
  String get sleepEditedSemantics;

  /// Sleep night detail footer
  ///
  /// In en, this message translates to:
  /// **'You didn\'t sleep at the same time this night'**
  String get sleepNoOverlapNight;

  /// Sleep night detail: my night is empty
  ///
  /// In en, this message translates to:
  /// **'Tap edit to log it yourself'**
  String get sleepManualHint;

  /// Sleep night detail: partner night is empty
  ///
  /// In en, this message translates to:
  /// **'Nothing logged this night'**
  String get sleepPartnerNightEmpty;

  /// Sleep night detail: edit window closed
  ///
  /// In en, this message translates to:
  /// **'Older than 7 days, so it can no longer be edited'**
  String get sleepEditLocked;

  /// Sleep edit button (screen reader)
  ///
  /// In en, this message translates to:
  /// **'Edit this night\'s sleep'**
  String get sleepEditButton;

  /// Sleep setup step 1 title
  ///
  /// In en, this message translates to:
  /// **'Let your phone log your sleep'**
  String get sleepSetupTitle;

  /// Sleep setup step 1 body (Android)
  ///
  /// In en, this message translates to:
  /// **'Each morning the app checks when your phone sat untouched longest overnight. It never reads messages, photos or any other content.'**
  String get sleepSetupBodyAndroid;

  /// Sleep setup step 1 body (iOS)
  ///
  /// In en, this message translates to:
  /// **'The app reads the sleep your iPhone or Apple Watch saved in Health. Read only, nothing gets written.'**
  String get sleepSetupBodyIos;

  /// Sleep setup step 1 body when no automatic source exists
  ///
  /// In en, this message translates to:
  /// **'This phone can\'t log sleep on its own. You can still log it by hand in a few seconds.'**
  String get sleepSetupUnsupported;

  /// Sleep setup check line
  ///
  /// In en, this message translates to:
  /// **'Nothing to do each day'**
  String get sleepSetupPoint1;

  /// Sleep setup check line
  ///
  /// In en, this message translates to:
  /// **'Fix it if the app guesses wrong'**
  String get sleepSetupPoint2;

  /// Sleep setup check line
  ///
  /// In en, this message translates to:
  /// **'Shared only if you want'**
  String get sleepSetupPoint3;

  /// Sleep setup hint (Android)
  ///
  /// In en, this message translates to:
  /// **'The app opens Settings → Usage access. Turn on Dear Embeiu, then come back here.'**
  String get sleepSetupHintAndroid;

  /// Sleep setup hint (iOS)
  ///
  /// In en, this message translates to:
  /// **'Your iPhone will ask to read Sleep in Health. No data yet? Turn on Sleep Schedule in Health.'**
  String get sleepSetupHintIos;

  /// Sleep setup: back from Settings without granting access
  ///
  /// In en, this message translates to:
  /// **'Dear Embeiu isn\'t turned on in the list yet. Try again.'**
  String get sleepPermissionStillOff;

  /// Sleep setup primary button
  ///
  /// In en, this message translates to:
  /// **'Allow access'**
  String get sleepGrantCta;

  /// Sleep setup secondary button
  ///
  /// In en, this message translates to:
  /// **'I\'ll log it myself'**
  String get sleepManualCta;

  /// Sleep setup step 2 title
  ///
  /// In en, this message translates to:
  /// **'Let {name} see your sleep?'**
  String sleepShareAskTitle(String name);

  /// Sleep setup step 2 body
  ///
  /// In en, this message translates to:
  /// **'They\'ll see when you fall asleep and wake up, and each time you wake in the night. You can turn this off anytime.'**
  String get sleepShareAskBody;

  /// Sleep setup step 2 preview caption (uppercase)
  ///
  /// In en, this message translates to:
  /// **'{name} WILL SEE'**
  String sleepShareAskPreview(String name);

  /// Sleep setup step 2 under the preview
  ///
  /// In en, this message translates to:
  /// **'Only bedtime, wake-up time and night wake-ups, in the time zone you slept in. Nights you edit or log by hand get a label.'**
  String get sleepShareAskOnly;

  /// Sleep setup step 2 primary button
  ///
  /// In en, this message translates to:
  /// **'Share with them'**
  String get sleepShareAskCta;

  /// Sleep setup step 2 secondary button
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get sleepLater;

  /// Sleep setup step 2 link
  ///
  /// In en, this message translates to:
  /// **'Back to step 1'**
  String get sleepBackToStep1;

  /// Sleep edit tile + time picker title
  ///
  /// In en, this message translates to:
  /// **'Bedtime'**
  String get sleepEditBedTitle;

  /// Sleep edit tile + time picker title
  ///
  /// In en, this message translates to:
  /// **'Wake up'**
  String get sleepEditWakeTitle;

  /// Sleep edit live total
  ///
  /// In en, this message translates to:
  /// **'Total: {duration}'**
  String sleepEditTotal(String duration);

  /// Sleep edit validation error
  ///
  /// In en, this message translates to:
  /// **'Sleep must be 1 to 16 hours'**
  String get sleepEditInvalid;

  /// Sleep edit delete button
  ///
  /// In en, this message translates to:
  /// **'Delete this night'**
  String get sleepDeleteNight;

  /// Sleep edit sheet subtitle (existing night)
  ///
  /// In en, this message translates to:
  /// **'Fix it if the app got it wrong.'**
  String get sleepEditSubtitle;

  /// Sleep edit sheet subtitle (empty night)
  ///
  /// In en, this message translates to:
  /// **'Log when you fell asleep and woke up.'**
  String get sleepManualSubtitle;

  /// Sleep edit sheet note (R4)
  ///
  /// In en, this message translates to:
  /// **'Once saved, this night shows an “Edited” label (your person sees it too) and the app won\'t overwrite it.'**
  String get sleepEditNote;

  /// Sleep edit sheet note for a hand-logged night (R4)
  ///
  /// In en, this message translates to:
  /// **'Once saved, this night shows a “Manual” label, and your person sees it too.'**
  String get sleepManualNote;

  /// Sleep time picker subtitle
  ///
  /// In en, this message translates to:
  /// **'Scroll to pick the hour and minute'**
  String get sleepPickerSubtitle;

  /// Sleep edit save error
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save, please try again'**
  String get sleepSaveFailed;

  /// Sleep: partner nights failed to load
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your person\'s sleep'**
  String get sleepLoadFailed;

  /// Sleep explainer paragraph (Android)
  ///
  /// In en, this message translates to:
  /// **'The app counts the longest stretch your phone sits untouched overnight as sleep, between 6 pm and 2 pm the next day, lasting 3 to 16 hours. A stretch that ends before 1 am, like charging in the evening, only counts when nothing that night lasts past 1 am.'**
  String get sleepHowBody1;

  /// Sleep explainer paragraph (iOS)
  ///
  /// In en, this message translates to:
  /// **'The app takes the longest sleep your iPhone or Apple Watch saved in Health between 6 pm and 2 pm the next day. Sleep under 3 hours or over 16 hours doesn\'t count. Sleep that ends before 1 am only counts when nothing that night lasts past 1 am.'**
  String get sleepHowBody1Ios;

  /// Sleep explainer paragraph (Android)
  ///
  /// In en, this message translates to:
  /// **'Picking up your phone for under 5 minutes counts as waking up, not as the end of your sleep.'**
  String get sleepHowBody2;

  /// Sleep explainer paragraph
  ///
  /// In en, this message translates to:
  /// **'It\'s an estimate: watching a movie in bed or leaving your phone elsewhere can skew it. You can fix it within 7 days, and your person will see an “Edited” label.'**
  String get sleepHowBody3;

  /// Sleep explainer paragraph (Android)
  ///
  /// In en, this message translates to:
  /// **'The app reads no content on your phone, only when the screen turns on or off.'**
  String get sleepHowBody4;

  /// Sleep explainer paragraph (iOS)
  ///
  /// In en, this message translates to:
  /// **'The app only reads Sleep in Health, nothing else.'**
  String get sleepHowBody4Ios;

  /// Sleep explainer paragraph (iOS): Sleep Schedule / time in bed
  ///
  /// In en, this message translates to:
  /// **'Your iPhone can log time in bed by itself: open Health → Browse → Sleep → Sleep Schedule, set a bedtime and turn on tracking time in bed with iPhone. Some iPhones on iOS 18 or later no longer offer this.'**
  String get sleepHowIphoneInBed;

  /// Sleep explainer paragraph: motion fallback (both platforms)
  ///
  /// In en, this message translates to:
  /// **'If you let the app see motion, nights with nothing recorded are guessed from when your phone lay still. It is only a guess: a phone left on the desk all morning may be counted as sleep, and you can fix it by hand. Raw motion data stays on your phone; your person only sees sleep and wake times if you turn sharing on.'**
  String get sleepHowMotion;

  /// Sleep explainer close button
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get sleepGotIt;

  /// Sleep screen banner (iOS, no Health data). Text between * is rendered bold.
  ///
  /// In en, this message translates to:
  /// **'Set a *Sleep Schedule* in Health (Browse → Sleep) so your iPhone logs time in bed, if it offers that option.'**
  String get sleepIosHealthHint;

  /// Sleep screen tip for users set up before the motion fallback existed. Text between * is rendered bold.
  ///
  /// In en, this message translates to:
  /// **'Allow *motion* so nights with nothing recorded can still be guessed from when your phone lay still.'**
  String get sleepMotionHint;

  /// Button on the motion tip: shows the motion permission prompt
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get sleepMotionAllow;

  /// Sleep banner close button (screen reader)
  ///
  /// In en, this message translates to:
  /// **'Dismiss tip'**
  String get sleepHintDismiss;

  /// Time picker sheet default title
  ///
  /// In en, this message translates to:
  /// **'Pick a reminder time'**
  String get timePickerDefaultTitle;

  /// Time picker sheet default subtitle
  ///
  /// In en, this message translates to:
  /// **'Scroll to pick the hour and minute'**
  String get timePickerDefaultSubtitle;

  /// Time picker sheet confirm button
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get timePickerConfirm;

  /// Sleep: compact duration with no leftover minutes
  ///
  /// In en, this message translates to:
  /// **'{h}h'**
  String sleepHoursShort(int h);

  /// Sleep: spelled-out duration with no leftover minutes
  ///
  /// In en, this message translates to:
  /// **'{h} hr'**
  String sleepHoursLong(int h);

  /// Love tree v3: title above the 6-star heart
  ///
  /// In en, this message translates to:
  /// **'Today\'s constellation'**
  String get loveTreeSkyTitle;

  /// Love tree v3: what the constellation means
  ///
  /// In en, this message translates to:
  /// **'Every little thing we do for each other today lights a star. When both halves glow, the heart is complete.'**
  String get loveTreeSkyExplain;

  /// Love tree v3 legend
  ///
  /// In en, this message translates to:
  /// **'Left half: You'**
  String get loveTreeLeftHalf;

  /// Love tree v3 legend
  ///
  /// In en, this message translates to:
  /// **'Right half: {name}'**
  String loveTreeRightHalf(String name);

  /// Love tree v3: label next to a star
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get loveTreeStarQuestion;

  /// Love tree v3: label next to a star
  ///
  /// In en, this message translates to:
  /// **'Mood'**
  String get loveTreeStarMood;

  /// Love tree v3: label next to a star
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get loveTreeStarMessage;

  /// Love tree v3: hint under the constellation
  ///
  /// In en, this message translates to:
  /// **'Tap a star to see more'**
  String get loveTreeTapStar;

  /// Love tree v3: all six stars lit
  ///
  /// In en, this message translates to:
  /// **'Today\'s heart is complete'**
  String get loveTreeHeartFull;

  /// Love tree v3: one of the three small things
  ///
  /// In en, this message translates to:
  /// **'Answer today\'s question'**
  String get loveTreeTaskQuestion;

  /// Love tree v3: one of the three small things
  ///
  /// In en, this message translates to:
  /// **'Share your mood'**
  String get loveTreeTaskMood;

  /// Love tree v3: one of the three small things
  ///
  /// In en, this message translates to:
  /// **'Send each other a message'**
  String get loveTreeTaskMessage;

  /// Love tree v3 star detail
  ///
  /// In en, this message translates to:
  /// **'{name} answered at {time}'**
  String loveTreeStarAnsweredAt(String name, String time);

  /// Love tree v3 star detail: mood picked + time
  ///
  /// In en, this message translates to:
  /// **'{mood} · {time}'**
  String loveTreeStarMoodAt(String mood, String time);

  /// Love tree v3 star detail
  ///
  /// In en, this message translates to:
  /// **'{name} messaged at {time}'**
  String loveTreeStarMessagedAt(String name, String time);

  /// Love tree v3 star detail when the time is unknown
  ///
  /// In en, this message translates to:
  /// **'Done for today'**
  String get loveTreeStarDone;

  /// Love tree v3 star detail
  ///
  /// In en, this message translates to:
  /// **'Today\'s question isn\'t answered yet'**
  String get loveTreeStarNoAnswer;

  /// Love tree v3 star detail
  ///
  /// In en, this message translates to:
  /// **'No mood shared yet today'**
  String get loveTreeStarNoMood;

  /// Love tree v3 star detail
  ///
  /// In en, this message translates to:
  /// **'No message yet today'**
  String get loveTreeStarNoMessage;

  /// Love tree v3: act on my unlit star
  ///
  /// In en, this message translates to:
  /// **'Answer now'**
  String get loveTreeActAnswer;

  /// Love tree v3: act on my unlit star
  ///
  /// In en, this message translates to:
  /// **'Share now'**
  String get loveTreeActMood;

  /// Love tree v3: act on my unlit star
  ///
  /// In en, this message translates to:
  /// **'Message now'**
  String get loveTreeActMessage;

  /// Love tree v3: partner's unlit star opens the care message screen
  ///
  /// In en, this message translates to:
  /// **'Send some care'**
  String get loveTreeNudge;

  /// Love tree v3: close the star detail (screen reader)
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get loveTreeClosePanel;

  /// Love tree v3: star button (screen reader)
  ///
  /// In en, this message translates to:
  /// **'{name} · {task} · {state}'**
  String loveTreeStarSemantics(String name, String task, String state);

  /// Love tree v3: star state (screen reader)
  ///
  /// In en, this message translates to:
  /// **'lit'**
  String get loveTreeStarLit;

  /// Love tree v3: star state (screen reader)
  ///
  /// In en, this message translates to:
  /// **'not lit yet'**
  String get loveTreeStarUnlit;

  /// Love tree v3: under the flower count
  ///
  /// In en, this message translates to:
  /// **'Each flower is one of our milestones. Tap one to look back.'**
  String get loveTreeFlowersExplain;

  /// Love tree v3: flower kind chip
  ///
  /// In en, this message translates to:
  /// **'Days together'**
  String get loveTreeKindDays;

  /// Love tree v3: flower kind chip
  ///
  /// In en, this message translates to:
  /// **'Question streak'**
  String get loveTreeKindStreak;

  /// Love tree v3: flower kind chip
  ///
  /// In en, this message translates to:
  /// **'Photo memories'**
  String get loveTreeKindPhotos;

  /// Love tree v3: next milestone card caption
  ///
  /// In en, this message translates to:
  /// **'NEXT FLOWER'**
  String get loveTreeNextFlower;

  /// Love tree v3: next milestone progress
  ///
  /// In en, this message translates to:
  /// **'{current}/{target} days together'**
  String loveTreeNextProgressDays(int current, int target);

  /// Love tree v3: next milestone progress
  ///
  /// In en, this message translates to:
  /// **'{current}/{target} streak days'**
  String loveTreeNextProgressStreak(int current, int target);

  /// Love tree v3: next milestone progress
  ///
  /// In en, this message translates to:
  /// **'{target, plural, =1{{current}/{target} photo} other{{current}/{target} photos}}'**
  String loveTreeNextProgressPhotos(int current, int target);

  /// Love tree v3: section title
  ///
  /// In en, this message translates to:
  /// **'Little things today'**
  String get loveTreeTodayTasks;

  /// Love tree v3: task done by that person
  ///
  /// In en, this message translates to:
  /// **'{name} ✓'**
  String loveTreeTaskDone(String name);

  /// Love tree v3: task not done yet by that person
  ///
  /// In en, this message translates to:
  /// **'{name} · not yet'**
  String loveTreeTaskPending(String name);

  /// Love tree v3: task row button
  ///
  /// In en, this message translates to:
  /// **'Do it now'**
  String get loveTreeDoNow;

  /// Love tree v3: section title above the milestone chips
  ///
  /// In en, this message translates to:
  /// **'Bloomed milestones'**
  String get loveTreeBloomedTitle;

  /// Love tree v3: collapse the milestone chips
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get loveTreeShowLess;

  /// Home: Love Tree entry pill (screen reader)
  ///
  /// In en, this message translates to:
  /// **'Today\'s constellation: {lit} of 6 stars. Opens the Love Tree'**
  String homeConstellationSemantics(int lit);
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

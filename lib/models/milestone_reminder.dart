/// The curated set of automatic "milestone & anniversary" reminders (v2, Dv4).
///
/// Each value is a milestone the user can individually turn on or off. The
/// enum name is also the Hive key suffix used to persist its on/off state, so
/// renaming a value is a breaking change for already-stored settings.
enum MilestoneType {
  /// Every 100 days together (recurring cadence: 100, 200, 300…).
  every100,

  /// One-shot at 520 days ("I love you").
  d520,

  /// One-shot at 1000 days.
  d1000,

  /// One-shot at 1314 days ("forever love").
  d1314,

  /// One-shot at 6 calendar months together.
  halfYear,

  /// Yearly anniversary (recurring).
  yearly,

  /// Gentle nudge after 7 photo-free days (recurring nudge).
  inactivity,
}

/// Whether a milestone can ever be "passed" (one-shot day-count / half-year) or
/// is recurring and so never expires.
extension MilestoneTypeX on MilestoneType {
  /// Day offset from the anniversary for fixed day-count milestones.
  /// Returns `null` for non day-count milestones (every100/halfYear/yearly/
  /// inactivity), which are computed differently.
  int? get fixedDayOffset {
    switch (this) {
      case MilestoneType.d520:
        return 520;
      case MilestoneType.d1000:
        return 1000;
      case MilestoneType.d1314:
        return 1314;
      case MilestoneType.every100:
      case MilestoneType.halfYear:
      case MilestoneType.yearly:
      case MilestoneType.inactivity:
        return null;
    }
  }

  /// True for one-shot milestones that can move into a "Passed" state.
  bool get isOneShot {
    switch (this) {
      case MilestoneType.d520:
      case MilestoneType.d1000:
      case MilestoneType.d1314:
      case MilestoneType.halfYear:
        return true;
      case MilestoneType.every100:
      case MilestoneType.yearly:
      case MilestoneType.inactivity:
        return false;
    }
  }
}

/// The fixed display order on the customization screen (Dv4 / design decision 5).
const List<MilestoneType> kMilestoneOrder = <MilestoneType>[
  MilestoneType.every100,
  MilestoneType.d520,
  MilestoneType.d1000,
  MilestoneType.d1314,
  MilestoneType.halfYear,
  MilestoneType.yearly,
  MilestoneType.inactivity,
];

/// Default on/off state the first time the user opens the feature (Dv4).
const Map<MilestoneType, bool> kMilestoneDefaults = <MilestoneType, bool>{
  MilestoneType.every100: true,
  MilestoneType.d520: false,
  MilestoneType.d1000: true,
  MilestoneType.d1314: false,
  MilestoneType.halfYear: true,
  MilestoneType.yearly: true,
  MilestoneType.inactivity: true,
};

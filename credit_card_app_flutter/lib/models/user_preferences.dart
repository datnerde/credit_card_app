import 'point_type.dart';

enum Language {
  english('English'),
  chinese('Chinese'),
  bilingual('Bilingual');

  const Language(this.displayName);
  final String displayName;
}

class UserPreferences {
  PointType preferredPointSystem;
  double alertThreshold;
  Language language;
  bool notificationsEnabled;
  bool autoUpdateSpending;
  bool useApplePay;

  UserPreferences({
    this.preferredPointSystem = PointType.membershipRewards,
    this.alertThreshold = 0.85,
    this.language = Language.english,
    this.notificationsEnabled = true,
    this.autoUpdateSpending = false,
    this.useApplePay = false,
  });

  Map<String, dynamic> toJson() => {
        'preferredPointSystem': preferredPointSystem.name,
        'alertThreshold': alertThreshold,
        'language': language.name,
        'notificationsEnabled': notificationsEnabled,
        'autoUpdateSpending': autoUpdateSpending,
        'useApplePay': useApplePay,
      };

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      preferredPointSystem: PointType.values.firstWhere(
        (e) => e.name == json['preferredPointSystem'],
        orElse: () => PointType.membershipRewards,
      ),
      alertThreshold: (json['alertThreshold'] as num?)?.toDouble() ?? 0.85,
      language: Language.values.firstWhere(
        (e) => e.name == json['language'],
        orElse: () => Language.english,
      ),
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      autoUpdateSpending: json['autoUpdateSpending'] as bool? ?? false,
      useApplePay: json['useApplePay'] as bool? ?? false,
    );
  }
}

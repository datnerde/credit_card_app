import '../models/credit_card.dart';
import '../models/spending_category.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final List<AppNotification> _pending = [];

  void checkLimits(List<CreditCard> cards) {
    for (final card in cards) {
      for (final limit in card.spendingLimits) {
        if (limit.isLimitReached) {
          _pending.add(AppNotification(
            title: 'Limit Reached',
            body: '${card.name} has reached its limit for ${limit.category.displayName}.',
            type: NotificationType.limitReached,
          ));
        } else if (limit.isWarningThreshold) {
          final pct = (limit.usagePercentage * 100).toInt();
          _pending.add(AppNotification(
            title: 'Spending Warning',
            body: '${card.name} is at $pct% for ${limit.category.displayName}.',
            type: NotificationType.limitWarning,
          ));
        }
      }

      final bonus = card.quarterlyBonus;
      if (bonus != null && bonus.usagePercentage >= 0.9 && !bonus.isLimitReached) {
        _pending.add(AppNotification(
          title: 'Quarterly Bonus Alert',
          body: 'Q${bonus.quarter} bonus on ${card.name} is almost maxed out!',
          type: NotificationType.quarterlyBonus,
        ));
      }
    }
  }

  List<AppNotification> consumePending() {
    final result = List<AppNotification>.from(_pending);
    _pending.clear();
    return result;
  }
}

enum NotificationType { limitReached, limitWarning, quarterlyBonus, dailySummary }

class AppNotification {
  final String title;
  final String body;
  final NotificationType type;
  final DateTime timestamp;

  AppNotification({
    required this.title,
    required this.body,
    required this.type,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

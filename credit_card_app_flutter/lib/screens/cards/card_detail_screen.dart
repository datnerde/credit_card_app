import 'package:flutter/material.dart';
import '../../models/credit_card.dart';
import '../../utils/theme.dart';
import '../../utils/extensions.dart';
import '../../widgets/credit_card_visual.dart';
import '../../widgets/reward_category_chip.dart';

class CardDetailScreen extends StatelessWidget {
  final CreditCard card;

  const CardDetailScreen({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(card.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card visual
            Center(
              child: CreditCardVisual(
                cardType: card.cardType,
                cardName: card.name,
                size: CardSize.large,
              ),
            ),
            const SizedBox(height: 28),
            // Rewards section
            Text('Rewards', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: card.rewardCategories
                  .where((r) => r.isActive)
                  .map((r) => RewardCategoryChip(reward: r))
                  .toList(),
            ),
            // Quarterly bonus
            if (card.quarterlyBonus != null) ...[
              const SizedBox(height: 24),
              Text('Quarterly Bonus', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              _buildQuarterlyBonus(context, card.quarterlyBonus!),
            ],
            // Spending limits
            if (card.spendingLimits.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('Spending Limits', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              ...card.spendingLimits.map((l) => _buildSpendingLimit(context, l)),
            ],
            // Card info
            const SizedBox(height: 24),
            Text('Card Info', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _buildInfoRow('Type', card.cardType.displayName),
            _buildInfoRow('Status', card.isActive ? 'Active' : 'Inactive'),
            _buildInfoRow('Added', card.createdAt.fullDate),
            _buildInfoRow('Categories', '${card.rewardCategories.length}'),
          ],
        ),
      ),
    );
  }

  Widget _buildQuarterlyBonus(BuildContext context, QuarterlyBonus bonus) {
    final progress = bonus.usagePercentage;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Q${bonus.quarter} ${bonus.year}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('${bonus.multiplier.toStringAsFixed(0)}x ${bonus.category.displayName}',
                  style: TextStyle(color: bonus.pointType.color)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: AppTheme.surfaceLight,
              valueColor: AlwaysStoppedAnimation(
                progress >= 1.0 ? AppTheme.error : progress >= 0.85 ? AppTheme.warning : AppTheme.accent,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(bonus.currentSpending.toCurrency(), style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              Text('of ${bonus.limit.toCurrency()}', style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary)),
            ],
          ),
          if (bonus.remainingAmount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('\$${bonus.remainingAmount.toStringAsFixed(0)} remaining',
                  style: const TextStyle(fontSize: 12, color: AppTheme.success)),
            ),
        ],
      ),
    );
  }

  Widget _buildSpendingLimit(BuildContext context, SpendingLimit limit) {
    final progress = limit.usagePercentage;
    final color = limit.isLimitReached
        ? AppTheme.error
        : limit.isWarningThreshold
            ? AppTheme.warning
            : AppTheme.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(limit.category.icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(limit.category.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('${(progress * 100).toStringAsFixed(0)}%', style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: AppTheme.surfaceLight,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(limit.currentSpending.toCurrency(), style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              Text('of ${limit.limit.toCurrency()} (${limit.resetType.displayName})',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}

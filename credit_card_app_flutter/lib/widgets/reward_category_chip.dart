import 'package:flutter/material.dart';
import '../models/credit_card.dart';
import '../utils/theme.dart';

class RewardCategoryChip extends StatelessWidget {
  final RewardCategory reward;

  const RewardCategoryChip({super.key, required this.reward});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: reward.pointType.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(reward.category.icon, size: 16, color: reward.pointType.color),
          const SizedBox(width: 6),
          Text(
            '${reward.multiplier.toStringAsFixed(reward.multiplier == reward.multiplier.roundToDouble() ? 0 : 1)}x',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: reward.pointType.color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            reward.category.displayName,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

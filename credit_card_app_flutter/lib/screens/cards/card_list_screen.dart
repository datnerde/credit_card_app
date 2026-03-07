import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/card_list_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/credit_card_visual.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/reward_category_chip.dart';
import 'card_detail_screen.dart';
import 'add_card_screen.dart';

class CardListScreen extends StatelessWidget {
  const CardListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CardListProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('My Cards'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_rounded),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddCardScreen()),
                ),
              ),
            ],
          ),
          body: provider.cards.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.credit_card_off,
                  title: 'No Cards Yet',
                  message: 'Add your credit cards to get personalized reward recommendations.',
                  buttonText: 'Add Card',
                  onButtonPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddCardScreen()),
                  ),
                )
              : _buildCardList(context, provider),
        );
      },
    );
  }

  Widget _buildCardList(BuildContext context, CardListProvider provider) {
    final cards = provider.filteredCards;
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            onChanged: provider.setSearchText,
            decoration: const InputDecoration(
              hintText: 'Search cards...',
              prefixIcon: Icon(Icons.search, color: AppTheme.textTertiary),
            ),
          ),
        ),
        // Stats row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              Text('${provider.totalCards} cards', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(width: 12),
              Text('${provider.activeCards} active',
                  style: TextStyle(fontSize: 12, color: AppTheme.success)),
            ],
          ),
        ),
        // Card carousel
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: cards.length + 1, // +1 for add card
            itemBuilder: (context, index) {
              if (index == cards.length) {
                return _buildAddCardPlaceholder(context);
              }
              final card = cards[index];
              final isSelected = provider.selectedCard?.id == card.id;
              return GestureDetector(
                onTap: () => provider.selectCard(card),
                onLongPress: () => _showCardMenu(context, provider, card),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  decoration: isSelected
                      ? BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppTheme.accent, width: 2),
                        )
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: CreditCardVisual(
                      cardType: card.cardType,
                      cardName: card.name,
                      size: CardSize.standard,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Selected card details
        if (provider.selectedCard != null)
          Expanded(child: _buildSelectedCardDetails(context, provider)),
      ],
    );
  }

  Widget _buildAddCardPlaceholder(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddCardScreen())),
      child: Container(
        width: 200,
        height: 126,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.textTertiary, width: 1.5, strokeAlign: BorderSide.strokeAlignInside),
          color: AppTheme.surfaceDark.withValues(alpha: 0.5),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, size: 32, color: AppTheme.textTertiary),
            SizedBox(height: 4),
            Text('Add Card', style: TextStyle(color: AppTheme.textTertiary, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedCardDetails(BuildContext context, CardListProvider provider) {
    final card = provider.selectedCard!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(card.name, style: Theme.of(context).textTheme.titleLarge),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CardDetailScreen(card: card)),
                ),
                child: const Text('Details'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Reward categories
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
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.star_rounded, color: AppTheme.warning, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Q${card.quarterlyBonus!.quarter} Bonus: ${card.quarterlyBonus!.multiplier.toStringAsFixed(0)}x ${card.quarterlyBonus!.category.displayName}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Text(
                    '\$${card.quarterlyBonus!.remainingAmount.toStringAsFixed(0)} left',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showCardMenu(BuildContext context, CardListProvider provider, dynamic card) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => AddCardScreen(editCard: card),
                ));
              },
            ),
            ListTile(
              leading: Icon(card.isActive ? Icons.visibility_off : Icons.visibility),
              title: Text(card.isActive ? 'Deactivate' : 'Activate'),
              onTap: () {
                provider.toggleCardActive(card.id);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppTheme.error),
              title: const Text('Delete', style: TextStyle(color: AppTheme.error)),
              onTap: () {
                provider.deleteCard(card.id);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

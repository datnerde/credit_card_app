import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/credit_card.dart';
import '../../models/card_type.dart';
import '../../models/spending_category.dart';
import '../../providers/add_card_provider.dart';
import '../../providers/card_list_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/credit_card_visual.dart';

class AddCardScreen extends StatefulWidget {
  final CreditCard? editCard;

  const AddCardScreen({super.key, this.editCard});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  @override
  void initState() {
    super.initState();
    final provider = context.read<AddCardProvider>();
    if (widget.editCard != null) {
      provider.loadCard(widget.editCard!);
    } else {
      provider.resetForm();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AddCardProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(provider.isEditing ? 'Edit Card' : 'Add Card'),
            actions: [
              TextButton(
                onPressed: () => _saveCard(context, provider),
                child: const Text('Save'),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card preview
                if (provider.selectedCardType != CardType.custom)
                  Center(
                    child: CreditCardVisual(
                      cardType: provider.selectedCardType,
                      cardName: provider.cardName.isEmpty ? provider.selectedCardType.displayName : provider.cardName,
                      size: CardSize.standard,
                    ),
                  ),
                const SizedBox(height: 24),

                // Card type picker
                Text('Card Type', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButton<CardType>(
                    value: provider.selectedCardType,
                    isExpanded: true,
                    dropdownColor: AppTheme.surfaceDark,
                    underline: const SizedBox(),
                    items: CardType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Row(
                          children: [
                            if (type != CardType.custom)
                              CreditCardVisual(
                                cardType: type,
                                cardName: type.displayName,
                                size: CardSize.mini,
                              ),
                            if (type != CardType.custom)
                              const SizedBox(width: 12),
                            Expanded(child: Text(type.displayName, overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (type) {
                      if (type != null) provider.loadDefaultsForCardType(type);
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Card name
                Text('Card Name', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                TextField(
                  controller: TextEditingController(text: provider.cardName)
                    ..selection = TextSelection.fromPosition(
                        TextPosition(offset: provider.cardName.length)),
                  onChanged: (v) => provider.cardName = v,
                  decoration: const InputDecoration(hintText: 'e.g., My Amex Gold'),
                ),
                const SizedBox(height: 24),

                // Reward categories
                Text('Reward Categories', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (provider.rewardCategories.isNotEmpty)
                  ...provider.rewardCategories.map((r) => _buildRewardRow(context, provider, r)),

                // Add category button
                TextButton.icon(
                  onPressed: () => _showCategoryPicker(context, provider),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Category'),
                ),

                // Validation errors
                if (provider.validationErrors.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      children: provider.validationErrors.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(e, style: const TextStyle(color: AppTheme.error, fontSize: 13)),
                      )).toList(),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRewardRow(BuildContext context, AddCardProvider provider, RewardCategory reward) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(reward.category.icon, size: 20, color: reward.pointType.color),
          const SizedBox(width: 10),
          Expanded(child: Text(reward.category.displayName, style: const TextStyle(fontSize: 14))),
          SizedBox(
            width: 60,
            child: TextField(
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              controller: TextEditingController(text: reward.multiplier.toString()),
              onChanged: (v) {
                final val = double.tryParse(v);
                if (val != null) provider.updateMultiplier(reward.category, val);
              },
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                suffixText: 'x',
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: AppTheme.textTertiary),
            onPressed: () => provider.toggleCategory(reward.category),
          ),
        ],
      ),
    );
  }

  void _showCategoryPicker(BuildContext context, AddCardProvider provider) {
    final existing = provider.rewardCategories.map((r) => r.category).toSet();
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
            const Text('Select Category', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 16),
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 2.5,
                ),
                itemCount: SpendingCategory.values.length,
                itemBuilder: (_, i) {
                  final cat = SpendingCategory.values[i];
                  final isAdded = existing.contains(cat);
                  return GestureDetector(
                    onTap: isAdded ? null : () {
                      provider.toggleCategory(cat);
                      Navigator.pop(context);
                    },
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isAdded ? AppTheme.surfaceLight : AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isAdded ? AppTheme.textTertiary : AppTheme.accent.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        cat.displayName,
                        style: TextStyle(
                          fontSize: 11,
                          color: isAdded ? AppTheme.textTertiary : AppTheme.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveCard(BuildContext context, AddCardProvider provider) {
    if (!provider.isFormValid) {
      setState(() {});
      return;
    }

    final card = provider.buildCard();
    final cardListProvider = context.read<CardListProvider>();

    if (provider.isEditing) {
      cardListProvider.updateCard(card);
    } else {
      cardListProvider.addCard(card);
    }

    provider.resetForm();
    Navigator.pop(context);
  }
}

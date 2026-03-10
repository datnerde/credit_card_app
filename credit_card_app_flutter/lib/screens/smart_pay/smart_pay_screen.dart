import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/smart_pay_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/category_picker.dart';
import '../../widgets/credit_card_visual.dart';

class SmartPayScreen extends StatelessWidget {
  const SmartPayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SmartPayProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Smart Pay'),
            actions: [
              if (provider.state != PaymentFlowState.idle)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: provider.reset,
                ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildBody(context, provider),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, SmartPayProvider provider) {
    switch (provider.state) {
      case PaymentFlowState.idle:
        return _buildIdleState(context, provider);
      case PaymentFlowState.analyzing:
        return _buildAnalyzingState();
      case PaymentFlowState.recommendationReady:
        return _buildRecommendationState(context, provider);
      case PaymentFlowState.acknowledged:
      case PaymentFlowState.paymentComplete:
        return _buildCompleteState(context, provider);
      case PaymentFlowState.processingPayment:
        return _buildAnalyzingState();
      case PaymentFlowState.paymentFailed:
        return _buildFailedState(context, provider);
    }
  }

  Widget _buildIdleState(BuildContext context, SmartPayProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          'What are you\nspending on?',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Tap a category to find your best card instantly.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 32),
        CategoryPicker(
          onCategorySelected: provider.selectCategory,
          selectedCategory: provider.detectedCategory,
        ),
        const SizedBox(height: 32),
        // Optional search bar
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(14),
          ),
          child: TextField(
            onChanged: provider.setPurchaseDescription,
            onSubmitted: (_) {
              if (provider.canAnalyze) provider.analyzePurchase();
            },
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Or type what you\'re buying...',
              prefixIcon: const Icon(Icons.search, color: AppTheme.textTertiary),
              suffixIcon: provider.canAnalyze
                  ? IconButton(
                      icon: const Icon(Icons.arrow_forward_rounded, color: AppTheme.accent),
                      onPressed: provider.analyzePurchase,
                    )
                  : null,
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyzingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.only(top: 100),
        child: Column(
          children: [
            CircularProgressIndicator(color: AppTheme.accent),
            SizedBox(height: 24),
            Text('Finding your best card...', style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationState(BuildContext context, SmartPayProvider provider) {
    final rec = provider.recommendedCard;
    if (rec == null) {
      return Center(
        child: Column(
          children: [
            const SizedBox(height: 60),
            const Icon(Icons.info_outline, size: 48, color: AppTheme.textTertiary),
            const SizedBox(height: 16),
            Text(provider.reasoning, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: provider.reset, child: const Text('Try Again')),
          ],
        ),
      );
    }

    return Column(
      children: [
        const SizedBox(height: 20),
        Text('Best Card', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 16),
        // Primary recommendation
        if (rec.cardType != null)
          Center(
            child: CreditCardVisual(
              cardType: rec.cardType!,
              cardName: rec.cardName,
              size: CardSize.large,
            ),
          ),
        const SizedBox(height: 20),
        // Reasoning
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            provider.reasoning,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        // Warnings
        if (provider.warnings.isNotEmpty) ...[
          const SizedBox(height: 12),
          for (final warning in provider.warnings)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
              ),
              child: Text(warning, style: const TextStyle(color: AppTheme.warning, fontSize: 13)),
            ),
        ],
        const SizedBox(height: 20),
        // Secondary recommendation
        if (provider.secondaryCard != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                if (provider.secondaryCard!.cardType != null)
                  CreditCardVisual(
                    cardType: provider.secondaryCard!.cardType!,
                    cardName: provider.secondaryCard!.cardName,
                    size: CardSize.mini,
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Backup Option', style: TextStyle(fontSize: 11, color: AppTheme.textTertiary)),
                      Text(
                        provider.secondaryCard!.cardName,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      Text(
                        '${provider.secondaryCard!.multiplier.toStringAsFixed(0)}x ${provider.secondaryCard!.pointType.shortName}',
                        style: TextStyle(fontSize: 12, color: provider.secondaryCard!.pointType.color),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        // Action buttons
        if (provider.useApplePay) ...[
          // Amount input for Apple Pay mode
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TextField(
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (v) => provider.setPurchaseAmount(double.tryParse(v)),
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18),
              decoration: const InputDecoration(
                hintText: 'Amount',
                prefixText: '\$ ',
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: provider.acknowledge,
              icon: const Icon(Icons.apple),
              label: const Text('Pay with Apple Pay'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            ),
          ),
        ] else
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: provider.acknowledge,
              child: const Text('Got it!'),
            ),
          ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: provider.reset,
            child: const Text('New Search'),
          ),
        ),
      ],
    );
  }

  Widget _buildCompleteState(BuildContext context, SmartPayProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: AppTheme.success, size: 40),
            ),
            const SizedBox(height: 24),
            Text(
              provider.useApplePay ? 'Payment Complete!' : 'Got it!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            if (provider.recommendedCard != null)
              Text(
                'Use your ${provider.recommendedCard!.cardName}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: provider.reset,
              child: const Text('New Recommendation'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFailedState(BuildContext context, SmartPayProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
            const SizedBox(height: 16),
            Text('Something went wrong', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: provider.reset, child: const Text('Try Again')),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/card_type.dart';

enum CardSize { mini, standard, large }

class CreditCardVisual extends StatelessWidget {
  final CardType cardType;
  final String cardName;
  final CardSize size;

  const CreditCardVisual({
    super.key,
    required this.cardType,
    required this.cardName,
    this.size = CardSize.standard,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = cardType.cardGradient;
    final dimensions = _getDimensions();

    return Container(
      width: dimensions.width,
      height: dimensions.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size == CardSize.mini ? 8 : 16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient.colors,
        ),
        boxShadow: size != CardSize.mini
            ? [
                BoxShadow(
                  color: gradient.colors.first.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.all(size == CardSize.mini ? 8 : size == CardSize.standard ? 14 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Chip icon
            if (size != CardSize.mini)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: size == CardSize.large ? 40 : 28,
                    height: size == CardSize.large ? 28 : 20,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  if (size == CardSize.large)
                    Icon(Icons.contactless, color: gradient.textColor.withValues(alpha: 0.6), size: 24),
                ],
              ),
            const Spacer(),
            // Card name + network
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    cardName,
                    style: TextStyle(
                      color: gradient.textColor,
                      fontSize: size == CardSize.mini ? 8 : size == CardSize.standard ? 12 : 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (cardType.networkLabel.isNotEmpty)
                  Text(
                    cardType.networkLabel,
                    style: TextStyle(
                      color: gradient.textColor.withValues(alpha: 0.7),
                      fontSize: size == CardSize.mini ? 6 : size == CardSize.standard ? 9 : 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Size _getDimensions() {
    switch (size) {
      case CardSize.mini:
        return const Size(80, 50);
      case CardSize.standard:
        return const Size(200, 126);
      case CardSize.large:
        return const Size(340, 214);
    }
  }
}

import 'package:flutter/material.dart';
import 'credit_card.dart';
import 'spending_category.dart';
import 'point_type.dart';

class CardGradient {
  final List<Color> colors;
  final String logoSymbol;
  final Color textColor;

  const CardGradient({
    required this.colors,
    this.logoSymbol = 'card',
    this.textColor = Colors.white,
  });
}

enum CardType {
  amexGold('Amex Gold'),
  amexPlatinum('Amex Platinum'),
  amexBlueCashPreferred('Amex Blue Cash Preferred'),
  chaseFreedom('Chase Freedom'),
  chaseFreedomFlex('Chase Freedom Flex'),
  chaseFreedomUnlimited('Chase Freedom Unlimited'),
  chaseSapphirePreferred('Chase Sapphire Preferred'),
  chaseSapphireReserve('Chase Sapphire Reserve'),
  citiDoubleCash('Citi Double Cash'),
  capitalOneSavorOne('Capital One SavorOne'),
  capitalOneVentureX('Capital One Venture X'),
  discoverIt('Discover It'),
  robinhoodGold('Robinhood Gold Card'),
  paypalCashback('PayPal Cashback Mastercard'),
  biltMastercard('Bilt Mastercard'),
  wellsFargoActiveCash('Wells Fargo Active Cash'),
  custom('Custom');

  const CardType(this.displayName);

  final String displayName;

  String get networkLabel {
    switch (this) {
      case amexGold:
      case amexPlatinum:
      case amexBlueCashPreferred:
        return 'AMEX';
      case chaseFreedom:
      case chaseFreedomFlex:
      case chaseFreedomUnlimited:
      case chaseSapphirePreferred:
      case chaseSapphireReserve:
        return 'VISA';
      case citiDoubleCash:
        return 'MASTERCARD';
      case capitalOneSavorOne:
      case capitalOneVentureX:
        return 'VISA';
      case discoverIt:
        return 'DISCOVER';
      case robinhoodGold:
        return 'VISA';
      case paypalCashback:
      case biltMastercard:
        return 'MASTERCARD';
      case wellsFargoActiveCash:
        return 'VISA';
      case custom:
        return '';
    }
  }

  CardGradient get cardGradient {
    switch (this) {
      case amexGold:
        return const CardGradient(colors: [Color(0xFFD4A843), Color(0xFFB8860B)]);
      case amexPlatinum:
        return const CardGradient(colors: [Color(0xFF8C8C8C), Color(0xFFC0C0C0)]);
      case amexBlueCashPreferred:
        return const CardGradient(colors: [Color(0xFF1A73E8), Color(0xFF4FC3F7)]);
      case chaseFreedom:
        return const CardGradient(colors: [Color(0xFF004A8F), Color(0xFF0073CF)]);
      case chaseFreedomFlex:
        return const CardGradient(colors: [Color(0xFF0056A3), Color(0xFF3B9FE3)]);
      case chaseFreedomUnlimited:
        return const CardGradient(colors: [Color(0xFF004080), Color(0xFF0068C9)]);
      case chaseSapphirePreferred:
        return const CardGradient(colors: [Color(0xFF1B2A4A), Color(0xFF2C4070)]);
      case chaseSapphireReserve:
        return const CardGradient(colors: [Color(0xFF0D1B2A), Color(0xFF1B3A5C)]);
      case citiDoubleCash:
        return const CardGradient(colors: [Color(0xFF003DA5), Color(0xFF0066CC)]);
      case capitalOneSavorOne:
        return const CardGradient(colors: [Color(0xFFD03027), Color(0xFFE85040)]);
      case capitalOneVentureX:
        return const CardGradient(colors: [Color(0xFF1A1A2E), Color(0xFF2D2D44)]);
      case discoverIt:
        return const CardGradient(colors: [Color(0xFFFF6B00), Color(0xFFFF9500)]);
      case robinhoodGold:
        return CardGradient(
          colors: const [Color(0xFF00C805), Color(0xFF7BE87B)],
          textColor: Colors.grey[900]!,
        );
      case paypalCashback:
        return const CardGradient(colors: [Color(0xFF003087), Color(0xFF009CDE)]);
      case biltMastercard:
        return const CardGradient(colors: [Color(0xFF0A2E4D), Color(0xFF1A5276)]);
      case wellsFargoActiveCash:
        return const CardGradient(colors: [Color(0xFFCD1409), Color(0xFFE8382D)]);
      case custom:
        return const CardGradient(colors: [Color(0xFF6C757D), Color(0xFF495057)]);
    }
  }

  List<RewardCategory> get defaultRewards {
    switch (this) {
      case amexGold:
        return [
          RewardCategory(category: SpendingCategory.groceries, multiplier: 4.0, pointType: PointType.membershipRewards),
          RewardCategory(category: SpendingCategory.dining, multiplier: 4.0, pointType: PointType.membershipRewards),
          RewardCategory(category: SpendingCategory.restaurants, multiplier: 4.0, pointType: PointType.membershipRewards),
          RewardCategory(category: SpendingCategory.airfare, multiplier: 3.0, pointType: PointType.membershipRewards),
          RewardCategory(category: SpendingCategory.travel, multiplier: 3.0, pointType: PointType.membershipRewards),
          RewardCategory(category: SpendingCategory.general, multiplier: 1.0, pointType: PointType.membershipRewards),
        ];
      case amexPlatinum:
        return [
          RewardCategory(category: SpendingCategory.airfare, multiplier: 5.0, pointType: PointType.membershipRewards),
          RewardCategory(category: SpendingCategory.hotels, multiplier: 5.0, pointType: PointType.membershipRewards),
          RewardCategory(category: SpendingCategory.travel, multiplier: 5.0, pointType: PointType.membershipRewards),
          RewardCategory(category: SpendingCategory.general, multiplier: 1.0, pointType: PointType.membershipRewards),
        ];
      case amexBlueCashPreferred:
        return [
          RewardCategory(category: SpendingCategory.groceries, multiplier: 6.0, pointType: PointType.cashBack),
          RewardCategory(category: SpendingCategory.streaming, multiplier: 6.0, pointType: PointType.cashBack),
          RewardCategory(category: SpendingCategory.gas, multiplier: 3.0, pointType: PointType.cashBack),
          RewardCategory(category: SpendingCategory.transit, multiplier: 3.0, pointType: PointType.cashBack),
          RewardCategory(category: SpendingCategory.general, multiplier: 1.0, pointType: PointType.cashBack),
        ];
      case chaseFreedom:
        return [
          RewardCategory(category: SpendingCategory.general, multiplier: 1.5, pointType: PointType.ultimateRewards),
        ];
      case chaseFreedomFlex:
        return [
          RewardCategory(category: SpendingCategory.dining, multiplier: 3.0, pointType: PointType.ultimateRewards),
          RewardCategory(category: SpendingCategory.restaurants, multiplier: 3.0, pointType: PointType.ultimateRewards),
          RewardCategory(category: SpendingCategory.drugstores, multiplier: 3.0, pointType: PointType.ultimateRewards),
          RewardCategory(category: SpendingCategory.general, multiplier: 1.0, pointType: PointType.ultimateRewards),
        ];
      case chaseFreedomUnlimited:
        return [
          RewardCategory(category: SpendingCategory.dining, multiplier: 3.0, pointType: PointType.ultimateRewards),
          RewardCategory(category: SpendingCategory.restaurants, multiplier: 3.0, pointType: PointType.ultimateRewards),
          RewardCategory(category: SpendingCategory.drugstores, multiplier: 3.0, pointType: PointType.ultimateRewards),
          RewardCategory(category: SpendingCategory.general, multiplier: 1.5, pointType: PointType.ultimateRewards),
        ];
      case chaseSapphirePreferred:
        return [
          RewardCategory(category: SpendingCategory.dining, multiplier: 3.0, pointType: PointType.ultimateRewards),
          RewardCategory(category: SpendingCategory.restaurants, multiplier: 3.0, pointType: PointType.ultimateRewards),
          RewardCategory(category: SpendingCategory.streaming, multiplier: 3.0, pointType: PointType.ultimateRewards),
          RewardCategory(category: SpendingCategory.online, multiplier: 3.0, pointType: PointType.ultimateRewards),
          RewardCategory(category: SpendingCategory.travel, multiplier: 2.0, pointType: PointType.ultimateRewards),
          RewardCategory(category: SpendingCategory.general, multiplier: 1.0, pointType: PointType.ultimateRewards),
        ];
      case chaseSapphireReserve:
        return [
          RewardCategory(category: SpendingCategory.hotels, multiplier: 10.0, pointType: PointType.ultimateRewards),
          RewardCategory(category: SpendingCategory.airfare, multiplier: 5.0, pointType: PointType.ultimateRewards),
          RewardCategory(category: SpendingCategory.dining, multiplier: 3.0, pointType: PointType.ultimateRewards),
          RewardCategory(category: SpendingCategory.restaurants, multiplier: 3.0, pointType: PointType.ultimateRewards),
          RewardCategory(category: SpendingCategory.travel, multiplier: 3.0, pointType: PointType.ultimateRewards),
          RewardCategory(category: SpendingCategory.general, multiplier: 1.0, pointType: PointType.ultimateRewards),
        ];
      case citiDoubleCash:
        return [
          RewardCategory(category: SpendingCategory.general, multiplier: 2.0, pointType: PointType.thankYouPoints),
        ];
      case capitalOneSavorOne:
        return [
          RewardCategory(category: SpendingCategory.dining, multiplier: 3.0, pointType: PointType.cashBack),
          RewardCategory(category: SpendingCategory.restaurants, multiplier: 3.0, pointType: PointType.cashBack),
          RewardCategory(category: SpendingCategory.entertainment, multiplier: 3.0, pointType: PointType.cashBack),
          RewardCategory(category: SpendingCategory.groceries, multiplier: 3.0, pointType: PointType.cashBack),
          RewardCategory(category: SpendingCategory.streaming, multiplier: 3.0, pointType: PointType.cashBack),
          RewardCategory(category: SpendingCategory.hotels, multiplier: 5.0, pointType: PointType.cashBack),
          RewardCategory(category: SpendingCategory.general, multiplier: 1.0, pointType: PointType.cashBack),
        ];
      case capitalOneVentureX:
        return [
          RewardCategory(category: SpendingCategory.hotels, multiplier: 10.0, pointType: PointType.ventureXMiles),
          RewardCategory(category: SpendingCategory.airfare, multiplier: 5.0, pointType: PointType.ventureXMiles),
          RewardCategory(category: SpendingCategory.travel, multiplier: 5.0, pointType: PointType.ventureXMiles),
          RewardCategory(category: SpendingCategory.general, multiplier: 2.0, pointType: PointType.ventureXMiles),
        ];
      case discoverIt:
        return [
          RewardCategory(category: SpendingCategory.general, multiplier: 1.0, pointType: PointType.discoverCashback),
        ];
      case robinhoodGold:
        return [
          RewardCategory(category: SpendingCategory.general, multiplier: 3.0, pointType: PointType.cashBack),
          RewardCategory(category: SpendingCategory.dining, multiplier: 3.0, pointType: PointType.cashBack),
          RewardCategory(category: SpendingCategory.groceries, multiplier: 3.0, pointType: PointType.cashBack),
          RewardCategory(category: SpendingCategory.travel, multiplier: 3.0, pointType: PointType.cashBack),
          RewardCategory(category: SpendingCategory.gas, multiplier: 3.0, pointType: PointType.cashBack),
          RewardCategory(category: SpendingCategory.online, multiplier: 3.0, pointType: PointType.cashBack),
        ];
      case paypalCashback:
        return [
          RewardCategory(category: SpendingCategory.paypal, multiplier: 3.0, pointType: PointType.cashBack),
          RewardCategory(category: SpendingCategory.online, multiplier: 3.0, pointType: PointType.cashBack),
          RewardCategory(category: SpendingCategory.general, multiplier: 2.0, pointType: PointType.cashBack),
        ];
      case biltMastercard:
        return [
          RewardCategory(category: SpendingCategory.dining, multiplier: 3.0, pointType: PointType.biltRewards),
          RewardCategory(category: SpendingCategory.restaurants, multiplier: 3.0, pointType: PointType.biltRewards),
          RewardCategory(category: SpendingCategory.travel, multiplier: 2.0, pointType: PointType.biltRewards),
          RewardCategory(category: SpendingCategory.airfare, multiplier: 2.0, pointType: PointType.biltRewards),
          RewardCategory(category: SpendingCategory.hotels, multiplier: 2.0, pointType: PointType.biltRewards),
          RewardCategory(category: SpendingCategory.rent, multiplier: 1.0, pointType: PointType.biltRewards),
          RewardCategory(category: SpendingCategory.general, multiplier: 1.0, pointType: PointType.biltRewards),
        ];
      case wellsFargoActiveCash:
        return [
          RewardCategory(category: SpendingCategory.general, multiplier: 2.0, pointType: PointType.cashBack),
        ];
      case custom:
        return [];
    }
  }
}

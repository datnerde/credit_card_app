import 'package:flutter/material.dart';

enum PointType {
  membershipRewards('MR', 'Membership Rewards (MR)', Color(0xFFD4A843)),
  ultimateRewards('UR', 'Ultimate Rewards (UR)', Color(0xFF1A73E8)),
  thankYouPoints('TYP', 'ThankYou Points (TYP)', Color(0xFF9C27B0)),
  cashBack('Cash Back', 'Cash Back', Color(0xFF4CAF50)),
  capitalOneMiles('Capital One Miles', 'Capital One Miles', Color(0xFFFF9800)),
  discoverCashback('Discover Cash Back', 'Discover Cash Back', Color(0xFFF44336)),
  biltRewards('Bilt Rewards', 'Bilt Rewards', Color(0xFF009688)),
  ventureXMiles('Venture X Miles', 'Venture X Miles', Color(0xFFFF9800));

  const PointType(this.shortName, this.displayName, this.color);

  final String shortName;
  final String displayName;
  final Color color;
}

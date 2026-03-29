import 'package:intl/intl.dart';

extension DoubleFormatting on double {
  String toCurrency() => NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(this);
  String toCompactCurrency() => NumberFormat.compactCurrency(symbol: '\$').format(this);
  String toMultiplier() => '${toStringAsFixed(this == this.roundToDouble() ? 0 : 1)}x';
  String toPercent() => '${(this * 100).toStringAsFixed(0)}%';
}

extension StringFormatting on String {
  String get titleCase => split(' ').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
  String truncate(int maxLength) => length <= maxLength ? this : '${substring(0, maxLength)}...';
}

extension DateTimeFormatting on DateTime {
  String get shortDate => DateFormat.MMMd().format(this);
  String get fullDate => DateFormat.yMMMd().format(this);
  int get currentQuarter => ((month - 1) ~/ 3) + 1;
}

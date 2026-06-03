class BalanceInfo {
  final String currency;
  final String totalBalance;

  BalanceInfo({required this.currency, required this.totalBalance});

  factory BalanceInfo.fromJson(Map<String, dynamic> json) {
    return BalanceInfo(
      currency: json['currency'] as String? ?? 'CNY',
      totalBalance: json['total_balance'] as String? ?? '0.00',
    );
  }

  String get symbol {
    switch (currency.toUpperCase()) {
      case 'CNY': return '\u{00A5}';
      case 'USD': return '\$';
      case 'EUR': return '\u{20AC}';
      default: return currency;
    }
  }

  String get displayText => '$symbol $totalBalance';
}

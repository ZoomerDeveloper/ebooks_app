class AppConfig {
  final bool paymentsEnabled;
  final String? subscriptionAmountRub;

  AppConfig({required this.paymentsEnabled, this.subscriptionAmountRub});

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      paymentsEnabled: json['payments_enabled'] ?? false,
      subscriptionAmountRub: json['subscription_amount_rub'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'payments_enabled': paymentsEnabled,
      'subscription_amount_rub': subscriptionAmountRub,
    };
  }
}

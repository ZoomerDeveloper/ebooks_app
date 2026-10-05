class SubscriptionPlan {
  final String planId;
  final double amountRub;
  final int months;
  final String title;

  SubscriptionPlan({
    required this.planId,
    required this.amountRub,
    required this.months,
    required this.title,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    final amountRaw = json['amount_rub'];
    final amount = amountRaw is num
        ? amountRaw.toDouble()
        : double.tryParse(amountRaw?.toString() ?? '0') ?? 0;

    return SubscriptionPlan(
      planId: json['plan_id'] as String,
      amountRub: amount,
      months: (json['months'] as num).toInt(),
      title: json['title'] as String,
    );
  }
}

class AppConfig {
  final bool paymentsEnabled;
  final List<SubscriptionPlan> subscriptionPlans;

  AppConfig({
    required this.paymentsEnabled,
    required this.subscriptionPlans,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    final plansRaw = json['subscription_plans'];
    final List<SubscriptionPlan> plans;
    if (plansRaw is List && plansRaw.isNotEmpty) {
      plans = plansRaw
          .whereType<Map<String, dynamic>>()
          .map(SubscriptionPlan.fromJson)
          .toList();
    } else {
      plans = const [];
    }
    return AppConfig(
      paymentsEnabled: json['payments_enabled'] ?? false,
      subscriptionPlans: plans,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'payments_enabled': paymentsEnabled,
      'subscription_plans': subscriptionPlans
          .map(
            (plan) => {
              'plan_id': plan.planId,
              'amount_rub': plan.amountRub,
              'months': plan.months,
              'title': plan.title,
            },
          )
          .toList(),
    };
  }
}

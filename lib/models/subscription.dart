class Subscription {
  final bool hasSubscription;
  final String status;
  final DateTime? expiresAt;

  Subscription({
    required this.hasSubscription,
    required this.status,
    this.expiresAt,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      hasSubscription: json['has_subscription'] ?? false,
      status: json['status'] ?? 'inactive',
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'has_subscription': hasSubscription,
      'status': status,
      'expires_at': expiresAt?.toIso8601String(),
    };
  }
}

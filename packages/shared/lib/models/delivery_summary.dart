class DeliverySummary {
  final String orderId;
  final String courierId;
  final double basePayout;
  final double tip;
  final double? overridePayout;
  final double rating;
  final DateTime completedAt;

  const DeliverySummary({
    required this.orderId,
    required this.courierId,
    required this.basePayout,
    required this.tip,
    required this.overridePayout,
    required this.rating,
    required this.completedAt,
  });

  double get finalPayout => overridePayout ?? (basePayout + tip);
}

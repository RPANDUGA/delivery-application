class CourierTask {
  final String id;
  final String orderId;
  final String pickupAddress;
  final String dropoffAddress;
  final double payout;
  final int etaMinutes;

  const CourierTask({
    required this.id,
    required this.orderId,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.payout,
    required this.etaMinutes,
  });
}

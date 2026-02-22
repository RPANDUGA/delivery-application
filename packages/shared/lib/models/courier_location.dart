class CourierLocation {
  final String orderId;
  final double latitude;
  final double longitude;
  final DateTime updatedAt;

  const CourierLocation({
    required this.orderId,
    required this.latitude,
    required this.longitude,
    required this.updatedAt,
  });
}

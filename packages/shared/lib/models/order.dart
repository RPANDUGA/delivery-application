enum OrderStatus {
  pending,
  accepted,
  preparing,
  enRoute,
  delivered,
  cancelled,
}

class OrderLine {
  final String itemId;
  final String name;
  final int quantity;
  final double price;

  const OrderLine({
    required this.itemId,
    required this.name,
    required this.quantity,
    required this.price,
  });
}

class Order {
  final String id;
  final String restaurantId;
  final String customerId;
  final List<OrderLine> lines;
  final double total;
  final OrderStatus status;
  final DateTime createdAt;

  const Order({
    required this.id,
    required this.restaurantId,
    required this.customerId,
    required this.lines,
    required this.total,
    required this.status,
    required this.createdAt,
  });
}

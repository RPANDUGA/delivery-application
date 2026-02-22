import 'dart:async';

import 'package:shared/shared.dart';

class MockDataRepository implements DataRepository {
  final List<Restaurant> _restaurants = const [
    Restaurant(
      id: 'r1',
      name: 'Harvest & Hearth',
      cuisine: 'Farm-to-table',
      rating: 4.7,
      etaMinutes: 28,
      heroImage: 'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?auto=format&fit=crop&w=800&q=60',
    ),
    Restaurant(
      id: 'r2',
      name: 'Nori House',
      cuisine: 'Japanese',
      rating: 4.5,
      etaMinutes: 32,
      heroImage: 'https://images.unsplash.com/photo-1553621042-f6e147245754?auto=format&fit=crop&w=800&q=60',
    ),
    Restaurant(
      id: 'r3',
      name: 'Cinder Pizza Co.',
      cuisine: 'Wood-fired pizza',
      rating: 4.8,
      etaMinutes: 24,
      heroImage: 'https://images.unsplash.com/photo-1542281286-9e0a16bb7366?auto=format&fit=crop&w=800&q=60',
    ),
  ];

  final List<Order> _orders = [
    Order(
      id: '1012',
      restaurantId: 'r1',
      customerId: 'c1',
      lines: const [
        OrderLine(itemId: 'm1', name: 'Roasted Veggie Bowl', quantity: 1, price: 14.5),
        OrderLine(itemId: 'm2', name: 'Citrus Mint Tea', quantity: 2, price: 3.5),
      ],
      total: 21.5,
      status: OrderStatus.enRoute,
      createdAt: DateTime(2026, 2, 8, 12, 30),
    ),
    Order(
      id: '1013',
      restaurantId: 'r2',
      customerId: 'c1',
      lines: const [
        OrderLine(itemId: 'm3', name: 'Salmon Donburi', quantity: 1, price: 16.0),
      ],
      total: 18.0,
      status: OrderStatus.preparing,
      createdAt: DateTime(2026, 2, 8, 12, 45),
    ),
  ];

  final List<CourierTask> _tasks = const [
    CourierTask(
      id: 't1',
      orderId: '1012',
      pickupAddress: '81 Market St',
      dropoffAddress: '200 Pine Ave',
      payout: 8.5,
      etaMinutes: 14,
    ),
    CourierTask(
      id: 't2',
      orderId: '1014',
      pickupAddress: '12 Union Square',
      dropoffAddress: '955 Lakeview Dr',
      payout: 10.25,
      etaMinutes: 20,
    ),
  ];

  final List<CourierLocation> _courierPath = [
    CourierLocation(
      orderId: '1012',
      latitude: 37.7879,
      longitude: -122.4074,
      updatedAt: DateTime(2026, 2, 8, 12, 40),
    ),
    CourierLocation(
      orderId: '1012',
      latitude: 37.7896,
      longitude: -122.4028,
      updatedAt: DateTime(2026, 2, 8, 12, 44),
    ),
    CourierLocation(
      orderId: '1012',
      latitude: 37.7908,
      longitude: -122.3992,
      updatedAt: DateTime(2026, 2, 8, 12, 48),
    ),
    CourierLocation(
      orderId: '1012',
      latitude: 37.7921,
      longitude: -122.3965,
      updatedAt: DateTime(2026, 2, 8, 12, 52),
    ),
  ];

  final List<DeliverySummary> _deliveries = [
    DeliverySummary(
      orderId: '1010',
      courierId: 'courier-1',
      basePayout: 7.75,
      tip: 0.0,
      overridePayout: null,
      rating: 4.0,
      completedAt: DateTime(2026, 2, 7, 18, 20),
    ),
    DeliverySummary(
      orderId: '1011',
      courierId: 'courier-1',
      basePayout: 9.5,
      tip: 2.0,
      overridePayout: null,
      rating: 5.0,
      completedAt: DateTime(2026, 2, 8, 11, 10),
    ),
  ];

  final Map<String, StreamController<CourierLocation?>> _locationControllers =
      {};
  final Map<String, Timer> _locationTimers = {};

  @override
  Stream<List<Restaurant>> watchRestaurants() => Stream.value(_restaurants);

  @override
  Stream<List<Order>> watchOrdersForCustomer(String customerId) =>
      Stream.value(_orders.where((o) => o.customerId == customerId).toList());

  @override
  Stream<List<Order>> watchOrdersForRestaurant(String restaurantId) =>
      Stream.value(_orders.where((o) => o.restaurantId == restaurantId).toList());

  @override
  Stream<List<CourierTask>> watchAvailableCourierTasks() => Stream.value(_tasks);

  @override
  Stream<CourierLocation?> watchCourierLocation(String orderId) {
    if (!_locationControllers.containsKey(orderId)) {
      _locationControllers[orderId] =
          StreamController<CourierLocation?>.broadcast();
      _locationControllers[orderId]!.add(null);

      if (orderId == '1012') {
        _locationTimers[orderId] ??=
            Timer.periodic(const Duration(seconds: 3), (timer) {
          final index = timer.tick % _courierPath.length;
          final step = _courierPath[index];
          _locationControllers[orderId]!.add(CourierLocation(
            orderId: step.orderId,
            latitude: step.latitude,
            longitude: step.longitude,
            updatedAt: DateTime.now(),
          ));
        });
      }
    }

    return _locationControllers[orderId]!.stream;
  }

  @override
  Stream<Order?> watchOrder(String orderId) {
    return Stream.periodic(const Duration(seconds: 3), (_) {
      final order = _orders.where((o) => o.id == orderId).toList();
      return order.isEmpty ? null : order.first;
    });
  }

  @override
  Stream<DeliverySummary?> watchDeliverySummary(String orderId) {
    final summary =
        _deliveries.where((d) => d.orderId == orderId).toList();
    return Stream.value(summary.isEmpty ? null : summary.first);
  }

  @override
  Stream<List<DeliverySummary>> watchDeliveryHistory(String courierId) {
    return Stream.value(
        _deliveries.where((d) => d.courierId == courierId).toList());
  }

  @override
  Stream<List<DeliverySummary>> watchAllDeliveries() {
    return Stream.value(_deliveries);
  }

  @override
  Stream<bool> watchIsAdmin(String userId) {
    return Stream.value(userId == 'admin');
  }

  @override
  Future<void> createOrder(Order order) async {
    _orders.add(order);
  }

  @override
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index == -1) return;
    final order = _orders[index];
    _orders[index] = Order(
      id: order.id,
      restaurantId: order.restaurantId,
      customerId: order.customerId,
      lines: order.lines,
      total: order.total,
      status: status,
      createdAt: order.createdAt,
    );
  }

  @override
  Future<void> updateCourierLocation(
      String orderId, double lat, double lng) async {
    final controller = _locationControllers.putIfAbsent(
      orderId,
      () => StreamController<CourierLocation?>.broadcast(),
    );
    controller.add(CourierLocation(
      orderId: orderId,
      latitude: lat,
      longitude: lng,
      updatedAt: DateTime.now(),
    ));
  }

  @override
  Future<void> updateDeliverySummary(DeliverySummary summary) async {
    _deliveries.removeWhere((d) => d.orderId == summary.orderId);
    _deliveries.add(summary);
  }
}

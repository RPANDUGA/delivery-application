import 'package:shared/shared.dart';

abstract class DataRepository {
  Stream<List<Restaurant>> watchRestaurants();
  Stream<List<Order>> watchOrdersForCustomer(String customerId);
  Stream<List<Order>> watchOrdersForRestaurant(String restaurantId);
  Stream<List<CourierTask>> watchAvailableCourierTasks();
  Stream<CourierLocation?> watchCourierLocation(String orderId);
  Stream<Order?> watchOrder(String orderId);
  Stream<DeliverySummary?> watchDeliverySummary(String orderId);
  Stream<List<DeliverySummary>> watchDeliveryHistory(String courierId);
  Stream<List<DeliverySummary>> watchAllDeliveries();
  Stream<bool> watchIsAdmin(String userId);

  Future<void> createOrder(Order order);
  Future<void> updateOrderStatus(String orderId, OrderStatus status);
  Future<void> updateCourierLocation(String orderId, double lat, double lng);
  Future<void> updateDeliverySummary(DeliverySummary summary);
}

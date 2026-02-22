import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:shared/shared.dart';

import 'repositories.dart';

class FirebaseDataRepository implements DataRepository {
  FirebaseDataRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Stream<List<Restaurant>> watchRestaurants() {
    return _firestore.collection('restaurants').snapshots().map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => Restaurant(
                  id: doc.id,
                  name: doc['name'] as String,
                  cuisine: doc['cuisine'] as String,
                  rating: (doc['rating'] as num).toDouble(),
                  etaMinutes: doc['etaMinutes'] as int,
                  heroImage: doc['heroImage'] as String,
                ),
              )
              .toList(),
        );
  }

  @override
  Stream<List<Order>> watchOrdersForCustomer(String customerId) {
    return _firestore
        .collection('orders')
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map(_mapOrders);
  }

  @override
  Stream<List<Order>> watchOrdersForRestaurant(String restaurantId) {
    return _firestore
        .collection('orders')
        .where('restaurantId', isEqualTo: restaurantId)
        .snapshots()
        .map(_mapOrders);
  }

  @override
  Stream<List<CourierTask>> watchAvailableCourierTasks() {
    return _firestore
        .collection('courierTasks')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => CourierTask(
                  id: doc.id,
                  orderId: doc['orderId'] as String,
                  pickupAddress: doc['pickupAddress'] as String,
                  dropoffAddress: doc['dropoffAddress'] as String,
                  payout: (doc['payout'] as num).toDouble(),
                  etaMinutes: doc['etaMinutes'] as int,
                ),
              )
              .toList(),
        );
  }

  @override
  Stream<CourierLocation?> watchCourierLocation(String orderId) {
    return _firestore
        .collection('courierLocations')
        .doc(orderId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      final data = doc.data()!;
      return CourierLocation(
        orderId: orderId,
        latitude: (data['lat'] as num).toDouble(),
        longitude: (data['lng'] as num).toDouble(),
        updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      );
    });
  }

  @override
  Stream<Order?> watchOrder(String orderId) {
    return _firestore
        .collection('orders')
        .doc(orderId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      final data = doc.data()!;
      return _mapOrderFromDoc(doc.id, data);
    });
  }

  @override
  Stream<DeliverySummary?> watchDeliverySummary(String orderId) {
    return _firestore
        .collection('courierDeliveries')
        .doc(orderId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      final data = doc.data()!;
      return DeliverySummary(
        orderId: doc.id,
        courierId: data['courierId'] as String,
        basePayout: (data['basePayout'] as num).toDouble(),
        tip: (data['tip'] as num).toDouble(),
        overridePayout: data['overridePayout'] == null
            ? null
            : (data['overridePayout'] as num).toDouble(),
        rating: (data['rating'] as num).toDouble(),
        completedAt: (data['completedAt'] as Timestamp).toDate(),
      );
    });
  }

  @override
  Stream<List<DeliverySummary>> watchDeliveryHistory(String courierId) {
    return _firestore
        .collection('courierDeliveries')
        .where('courierId', isEqualTo: courierId)
        .orderBy('completedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => DeliverySummary(
                  orderId: doc.id,
                  courierId: doc['courierId'] as String,
                  basePayout: (doc['basePayout'] as num).toDouble(),
                  tip: (doc['tip'] as num).toDouble(),
                  overridePayout: doc['overridePayout'] == null
                      ? null
                      : (doc['overridePayout'] as num).toDouble(),
                  rating: (doc['rating'] as num).toDouble(),
                  completedAt: (doc['completedAt'] as Timestamp).toDate(),
                ),
              )
              .toList(),
        );
  }

  @override
  Stream<List<DeliverySummary>> watchAllDeliveries() {
    return _firestore
        .collection('courierDeliveries')
        .orderBy('completedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => DeliverySummary(
                  orderId: doc.id,
                  courierId: doc['courierId'] as String,
                  basePayout: (doc['basePayout'] as num).toDouble(),
                  tip: (doc['tip'] as num).toDouble(),
                  overridePayout: doc['overridePayout'] == null
                      ? null
                      : (doc['overridePayout'] as num).toDouble(),
                  rating: (doc['rating'] as num).toDouble(),
                  completedAt: (doc['completedAt'] as Timestamp).toDate(),
                ),
              )
              .toList(),
        );
  }

  @override
  Stream<bool> watchIsAdmin(String userId) {
    return fb.FirebaseAuth.instance.idTokenChanges().asyncMap((user) async {
      if (user == null || user.uid != userId) return false;
      final token = await user.getIdTokenResult(true);
      return token.claims?['admin'] == true;
    }).distinct();
  }

  @override
  Future<void> createOrder(Order order) async {
    await _firestore.collection('orders').add({
      'restaurantId': order.restaurantId,
      'customerId': order.customerId,
      'total': order.total,
      'status': order.status.name,
      'createdAt': order.createdAt,
      'lines': order.lines
          .map(
            (line) => {
              'itemId': line.itemId,
              'name': line.name,
              'quantity': line.quantity,
              'price': line.price,
            },
          )
          .toList(),
    });
  }

  @override
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    await _firestore.collection('orders').doc(orderId).update({
      'status': status.name,
    });
  }

  @override
  Future<void> updateCourierLocation(
      String orderId, double lat, double lng) async {
    await _firestore.collection('courierLocations').doc(orderId).set({
      'lat': lat,
      'lng': lng,
      'updatedAt': Timestamp.now(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> updateDeliverySummary(DeliverySummary summary) async {
    await _firestore.collection('courierDeliveries').doc(summary.orderId).set({
      'courierId': summary.courierId,
      'basePayout': summary.basePayout,
      'tip': summary.tip,
      'overridePayout': summary.overridePayout,
      'rating': summary.rating,
      'completedAt': summary.completedAt,
    }, SetOptions(merge: true));
  }

  List<Order> _mapOrders(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs
        .map((doc) => _mapOrderFromDoc(doc.id, doc.data()))
        .toList();
  }

  Order _mapOrderFromDoc(String id, Map<String, dynamic> data) {
    return Order(
      id: id,
      restaurantId: data['restaurantId'] as String,
      customerId: data['customerId'] as String,
      total: (data['total'] as num).toDouble(),
      status: OrderStatus.values.firstWhere(
        (value) => value.name == data['status'],
        orElse: () => OrderStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lines: (data['lines'] as List<dynamic>)
          .map(
            (line) => OrderLine(
              itemId: line['itemId'] as String,
              name: line['name'] as String,
              quantity: line['quantity'] as int,
              price: (line['price'] as num).toDouble(),
            ),
          )
          .toList(),
    );
  }
}

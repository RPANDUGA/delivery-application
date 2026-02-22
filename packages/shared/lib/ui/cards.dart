import 'package:flutter/material.dart';
import '../models/models.dart';

class RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;

  const RestaurantCard({
    super.key,
    required this.restaurant,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  restaurant.heroImage,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Center(
                    child: Icon(Icons.restaurant, color: Colors.grey.shade600),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(restaurant.name,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              '${restaurant.cuisine} • ${restaurant.rating.toStringAsFixed(1)} ★ • ${restaurant.etaMinutes} min',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class OrderStatusCard extends StatelessWidget {
  final Order order;

  const OrderStatusCard({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order #${order.id}',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text('Status: ${order.status.name}'),
            const SizedBox(height: 6),
            Text('Total: \$${order.total.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }
}

class CourierTaskCard extends StatelessWidget {
  final CourierTask task;

  const CourierTaskCard({
    super.key,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pickup: ${task.pickupAddress}',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text('Dropoff: ${task.dropoffAddress}'),
            const SizedBox(height: 6),
            Text('Payout: \$${task.payout.toStringAsFixed(2)} • ETA ${task.etaMinutes}m'),
          ],
        ),
      ),
    );
  }
}

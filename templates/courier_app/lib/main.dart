import 'dart:async';
import 'dart:math';

import 'package:shared/shared.dart';
import 'package:data/data.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'background_location_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bootstrap = await _initBootstrap();
  runApp(CourierApp(bootstrap: bootstrap));
}

Future<_Bootstrap> _initBootstrap() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await BackgroundLocationService.configure();
    return _Bootstrap(
      dataRepository: FirebaseDataRepository(),
      authRepository: FirebaseAuthRepository(),
    );
  } catch (error) {
    await BackgroundLocationService.configure();
    return _Bootstrap(
      dataRepository: MockDataRepository(),
      authRepository: MockAuthRepository(),
    );
  }
}

class _Bootstrap {
  final DataRepository dataRepository;
  final AuthRepository authRepository;

  const _Bootstrap({
    required this.dataRepository,
    required this.authRepository,
  });
}

class CourierApp extends StatelessWidget {
  final _Bootstrap bootstrap;

  const CourierApp({super.key, required this.bootstrap});

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      auth: bootstrap.authRepository,
      child: RepositoryScope(
        repository: bootstrap.dataRepository,
        child: ActiveDeliveryScope(
          state: ActiveDeliveryState(),
          child: MaterialApp(
            title: 'Foodly Courier',
            theme: AppTheme.light(),
            home: const AuthGate(),
          ),
        ),
      ),
    );
  }
}

class ActiveDeliveryState extends ChangeNotifier {
  String? activeOrderId;

  Future<void> setActiveOrder(String orderId) async {
    activeOrderId = orderId;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('activeOrderId', orderId);
  }

  Future<void> clearActiveOrder() async {
    activeOrderId = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('activeOrderId');
  }
}

class ActiveDeliveryScope extends InheritedNotifier<ActiveDeliveryState> {
  const ActiveDeliveryScope({
    super.key,
    required ActiveDeliveryState state,
    required Widget child,
  }) : super(notifier: state, child: child);

  static ActiveDeliveryState of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<ActiveDeliveryScope>();
    assert(scope != null, 'ActiveDeliveryScope not found in context');
    return scope!.notifier!;
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    return StreamBuilder<AuthUser?>(
      stream: auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data == null) {
          return const AuthScreen();
        }
        return const CourierShell();
      },
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isSignIn = true;

  void _toggle() {
    setState(() => _isSignIn = !_isSignIn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              _isSignIn ? 'Courier sign in' : 'Create courier account',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 16),
            Text(
              _isSignIn
                  ? 'Access your delivery tasks and earnings.'
                  : 'Join the fleet and start delivering.',
            ),
            const SizedBox(height: 24),
            _isSignIn
                ? SignInForm(onSwitch: _toggle)
                : SignUpForm(onSwitch: _toggle),
          ],
        ),
      ),
    );
  }
}

class SignInForm extends StatefulWidget {
  final VoidCallback onSwitch;

  const SignInForm({super.key, required this.onSwitch});

  @override
  State<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<SignInForm> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthScope.of(context)
          .signInWithEmail(_email.text.trim(), _password.text.trim());
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _password,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password'),
        ),
        const SizedBox(height: 16),
        if (_error != null)
          Text(_error!, style: const TextStyle(color: Colors.red)),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Sign in'),
          ),
        ),
        TextButton(
          onPressed: widget.onSwitch,
          child: const Text('Need an account? Sign up'),
        ),
      ],
    );
  }
}

class SignUpForm extends StatefulWidget {
  final VoidCallback onSwitch;

  const SignUpForm({super.key, required this.onSwitch});

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthScope.of(context)
          .signUpWithEmail(_email.text.trim(), _password.text.trim());
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _password,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password'),
        ),
        const SizedBox(height: 16),
        if (_error != null)
          Text(_error!, style: const TextStyle(color: Colors.red)),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create account'),
          ),
        ),
        TextButton(
          onPressed: widget.onSwitch,
          child: const Text('Have an account? Sign in'),
        ),
      ],
    );
  }
}

class CourierShell extends StatefulWidget {
  const CourierShell({super.key});

  @override
  State<CourierShell> createState() => _CourierShellState();
}

class _CourierShellState extends State<CourierShell> {
  int _index = 0;

  final _screens = const [
    TasksScreen(),
    ActiveDeliveryScreen(),
    EarningsScreen(),
    DeliveryHistoryScreen(),
    CourierProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Courier Ops'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.tune))
        ],
      ),
      body: _screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.local_shipping_outlined), label: 'Tasks'),
          NavigationDestination(icon: Icon(Icons.navigation_outlined), label: 'Active'),
          NavigationDestination(icon: Icon(Icons.payments_outlined), label: 'Earnings'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    final activeState = ActiveDeliveryScope.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionHeader(title: 'Available deliveries'),
        const SizedBox(height: 12),
        StreamBuilder<List<CourierTask>>(
          stream: repo.watchAvailableCourierTasks(),
          builder: (context, snapshot) {
            final tasks = snapshot.data ?? [];
            return Column(
              children: tasks
                  .map((task) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                CourierTaskCard(task: task),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: () async {
                                    await activeState.setActiveOrder(task.orderId);
                                    await repo.updateOrderStatus(
                                      task.orderId,
                                      OrderStatus.enRoute,
                                    );
                                  },
                                  child: const Text('Accept delivery'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class ActiveDeliveryScreen extends StatefulWidget {
  const ActiveDeliveryScreen({super.key});

  @override
  State<ActiveDeliveryScreen> createState() => _ActiveDeliveryScreenState();
}

class _ActiveDeliveryScreenState extends State<ActiveDeliveryScreen> {
  Timer? _timer;
  StreamSubscription<Order?>? _orderSub;
  StreamSubscription<CourierLocation?>? _locationSub;
  int _step = 0;
  bool _sharing = false;
  bool _liveSharing = false;
  String? _listeningOrderId;
  bool _autoCompleted = false;
  final List<LatLng> _gpsPath = [];

  final List<LatLng> _path = const [
    LatLng(37.7879, -122.4074),
    LatLng(37.7896, -122.4028),
    LatLng(37.7908, -122.3992),
    LatLng(37.7921, -122.3965),
  ];
  static const LatLng _pickup = LatLng(37.7879, -122.4074);
  static const LatLng _dropoff = LatLng(37.7921, -122.3965);

  void _toggleSharing() {
    if (_sharing) {
      _timer?.cancel();
      setState(() => _sharing = false);
      return;
    }

    final repo = RepositoryScope.of(context);
    final orderId = ActiveDeliveryScope.of(context).activeOrderId ?? '1012';
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      final point = _path[_step % _path.length];
      _step += 1;
      _gpsPath.add(point);
      repo.updateCourierLocation(orderId, point.latitude, point.longitude);
    });
    setState(() => _sharing = true);
  }

  Future<void> _toggleLiveSharing() async {
    if (_liveSharing) {
      await BackgroundLocationService.stop();
      setState(() => _liveSharing = false);
      return;
    }

    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    final orderId = ActiveDeliveryScope.of(context).activeOrderId ?? '1012';
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    _gpsPath.add(LatLng(position.latitude, position.longitude));
    await BackgroundLocationService.start(orderId);
    setState(() => _liveSharing = true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final activeOrderId = ActiveDeliveryScope.of(context).activeOrderId;
    if (activeOrderId == _listeningOrderId) return;

    _orderSub?.cancel();
    _locationSub?.cancel();
    _listeningOrderId = activeOrderId;
    _autoCompleted = false;

    if (activeOrderId == null) {
      _gpsPath.clear();
      return;
    }

    final repo = RepositoryScope.of(context);
    _orderSub = repo.watchOrder(activeOrderId).listen((order) async {
      if (!mounted || order == null) return;
      if (order.status == OrderStatus.delivered && !_autoCompleted) {
        _autoCompleted = true;
        final routeKm = _computePathKm(_gpsPath);
        await _stopSharing();
        await _upsertDeliverySummary(order, routeKm);
        await ActiveDeliveryScope.of(context).clearActiveOrder();
        _gpsPath.clear();
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DeliverySummaryScreen(orderId: order.id),
          ),
        );
      }
    });

    _locationSub =
        repo.watchCourierLocation(activeOrderId).listen((location) {
      if (location == null) return;
      final point = LatLng(location.latitude, location.longitude);
      if (_gpsPath.isEmpty) {
        _gpsPath.add(point);
        return;
      }
      final last = _gpsPath.last;
      if (_haversineKm(last, point) > 0.01) {
        _gpsPath.add(point);
      }
    });
  }

  Future<void> _stopSharing() async {
    _timer?.cancel();
    if (_liveSharing) {
      await BackgroundLocationService.stop();
    }
    setState(() {
      _sharing = false;
      _liveSharing = false;
    });
  }

  Future<void> _upsertDeliverySummary(Order order, double routeKm) async {
    final repo = RepositoryScope.of(context);
    final courierId = AuthScope.of(context).currentUser()?.uid ?? 'courier-1';
    final basePayout = _estimatePayout(
      pickup: _pickup,
      dropoff: _dropoff,
      orderTotal: order.total,
      routeKm: routeKm,
    );
    final summary = DeliverySummary(
      orderId: order.id,
      courierId: courierId,
      basePayout: basePayout,
      tip: 0.0,
      overridePayout: null,
      rating: 4.5,
      completedAt: DateTime.now(),
    );
    await repo.updateDeliverySummary(summary);
  }

  Future<void> _completeDelivery(String orderId) async {
    final repo = RepositoryScope.of(context);
    final order = await repo.watchOrder(orderId).first;
    await repo.updateOrderStatus(orderId, OrderStatus.delivered);
    final routeKm = _computePathKm(_gpsPath);
    await _stopSharing();
    if (order != null) {
      await _upsertDeliverySummary(order, routeKm);
    }
    await ActiveDeliveryScope.of(context).clearActiveOrder();
    _gpsPath.clear();
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DeliverySummaryScreen(orderId: orderId),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _orderSub?.cancel();
    _locationSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeState = ActiveDeliveryScope.of(context);
    final orderId = activeState.activeOrderId;

    if (orderId == null) {
      return Center(
        child: Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.local_shipping_outlined, size: 42),
                SizedBox(height: 12),
                Text('No active delivery yet. Accept a task to begin.'),
              ],
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ActiveDeliveryMap(orderId: orderId),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.navigation, size: 42),
                const SizedBox(height: 12),
                Text('Head to pickup for order #$orderId.'),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _toggleSharing,
                    child: Text(_sharing ? 'Stop sharing location' : 'Start sharing location'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _toggleLiveSharing,
                    child: Text(_liveSharing
                        ? 'Stop live GPS'
                        : 'Start live GPS (foreground)'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _completeDelivery(orderId),
                    child: const Text('Complete delivery'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ActiveDeliveryMap extends StatelessWidget {
  final String orderId;

  const ActiveDeliveryMap({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    const pickup = LatLng(37.7879, -122.4074);
    const dropoff = LatLng(37.7921, -122.3965);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          height: 260,
          child: StreamBuilder<CourierLocation?>(
            stream: repo.watchCourierLocation(orderId),
            builder: (context, snapshot) {
              final courier = snapshot.data;
              final center = courier == null
                  ? pickup
                  : LatLng(courier.latitude, courier.longitude);
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: 14,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.fooddelivery.courier',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: pickup,
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.storefront, color: Colors.green),
                        ),
                        Marker(
                          point: dropoff,
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.home, color: Colors.blue),
                        ),
                        if (courier != null)
                          Marker(
                            point: LatLng(courier.latitude, courier.longitude),
                            width: 40,
                            height: 40,
                            child: const Icon(Icons.delivery_dining,
                                color: Colors.deepOrange),
                          ),
                      ],
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: const [pickup, dropoff],
                          color: Colors.black87,
                          strokeWidth: 3,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class DeliverySummaryScreen extends StatefulWidget {
  final String orderId;

  const DeliverySummaryScreen({super.key, required this.orderId});

  @override
  State<DeliverySummaryScreen> createState() => _DeliverySummaryScreenState();
}

class _DeliverySummaryScreenState extends State<DeliverySummaryScreen> {
  double? _rating;
  bool _saving = false;
  final _tipController = TextEditingController();
  final _overrideController = TextEditingController();
  bool _isAdmin = false;
  StreamSubscription<bool>? _adminSub;

  void _ensureAdminSubscription(DataRepository repo) {
    final userId = AuthScope.of(context).currentUser()?.uid;
    if (userId == null || _adminSub != null) return;
    _adminSub = repo.watchIsAdmin(userId).listen((isAdmin) {
      if (!mounted) return;
      setState(() => _isAdmin = isAdmin);
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    _ensureAdminSubscription(repo);
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery Complete')),
      body: StreamBuilder<DeliverySummary?>(
        stream: repo.watchDeliverySummary(widget.orderId),
        builder: (context, snapshot) {
          final summary = snapshot.data;
          final basePayout = summary?.basePayout ?? 8.50;
          final tipSeed = summary?.tip ?? 0.0;
          final overrideSeed = summary?.overridePayout;
          final rating = _rating ?? summary?.rating ?? 4.5;
          final tip = _parseAmount(_tipController.text) ?? tipSeed;
          final override = _isAdmin
              ? _parseAmount(_overrideController.text) ?? overrideSeed
              : overrideSeed;
          final computedPayout = override ?? (basePayout + tip);
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
              const SizedBox(height: 12),
              Text('Order #${widget.orderId} delivered',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              const Text('Nice work! Your delivery is complete.'),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Earnings',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text('\$${basePayout.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 24)),
                      const SizedBox(height: 12),
                      const Text('Customer rating'),
                      const SizedBox(height: 6),
                      Row(
                        children: List.generate(5, (index) {
                          final filled = rating >= index + 1;
                          return Icon(
                            filled ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                          );
                        }),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: List.generate(5, (index) {
                          final value = (index + 1).toDouble();
                          final selected = (rating - value).abs() < 0.1;
                          return ChoiceChip(
                            label: Text('${index + 1}★'),
                            selected: selected,
                            onSelected: (_) => setState(() => _rating = value),
                          );
                        }),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _tipController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Tip (optional)',
                          prefixText: '\\$',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _overrideController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Override payout (admin)',
                          prefixText: '\\$',
                        ),
                        enabled: _isAdmin,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      Text('Final payout: \\$${computedPayout.toStringAsFixed(2)}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving
                      ? null
                      : () async {
                          setState(() => _saving = true);
                          final courierId =
                              AuthScope.of(context).currentUser()?.uid ??
                                  'courier-1';
                          await repo.updateDeliverySummary(
                            DeliverySummary(
                              orderId: widget.orderId,
                              courierId: courierId,
                              basePayout: basePayout,
                              tip: tip,
                              overridePayout: override,
                              rating: rating,
                              completedAt:
                                  summary?.completedAt ?? DateTime.now(),
                            ),
                          );
                          if (!mounted) return;
                          setState(() => _saving = false);
                          Navigator.of(context).pop();
                        },
                  child: Text(_saving ? 'Saving...' : 'Save summary'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _adminSub?.cancel();
    _tipController.dispose();
    _overrideController.dispose();
    super.dispose();
  }
}


class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    final courierId = AuthScope.of(context).currentUser()?.uid ?? 'courier-1';
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Earnings', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        StreamBuilder<List<DeliverySummary>>(
          stream: repo.watchDeliveryHistory(courierId),
          builder: (context, snapshot) {
            final history = snapshot.data ?? [];
            final todayTotal = history
                .where((item) => _isSameDay(item.completedAt, now))
                .fold<double>(0, (sum, item) => sum + item.finalPayout);
            final weekTotal = history
                .where((item) => !item.completedAt.isBefore(startOfWeek))
                .fold<double>(0, (sum, item) => sum + item.finalPayout);

            return Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Today'),
                        Text('\$${todayTotal.toStringAsFixed(2)}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('This week'),
                        Text('\$${weekTotal.toStringAsFixed(2)}'),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

double _estimatePayout({
  required LatLng pickup,
  required LatLng dropoff,
  required double orderTotal,
  required double routeKm,
}) {
  const base = 3.0;
  const perKm = 1.4;
  const orderPercent = 0.08;
  final km = routeKm > 0 ? routeKm : _haversineKm(pickup, dropoff);
  return base + (km * perKm) + (orderTotal * orderPercent);
}

double _haversineKm(LatLng a, LatLng b) {
  const earthRadiusKm = 6371.0;
  final dLat = _degToRad(b.latitude - a.latitude);
  final dLon = _degToRad(b.longitude - a.longitude);
  final lat1 = _degToRad(a.latitude);
  final lat2 = _degToRad(b.latitude);

  final h = pow(sin(dLat / 2), 2) +
      cos(lat1) * cos(lat2) * pow(sin(dLon / 2), 2);
  return 2 * earthRadiusKm * asin(sqrt(h));
}

double _degToRad(double deg) => deg * (pi / 180);

double _computePathKm(List<LatLng> points) {
  if (points.length < 2) return 0;
  var total = 0.0;
  for (var i = 1; i < points.length; i += 1) {
    total += _haversineKm(points[i - 1], points[i]);
  }
  return total;
}

double? _parseAmount(String input) {
  final normalized = input.trim().replaceAll(',', '');
  if (normalized.isEmpty) return null;
  return double.tryParse(normalized);
}

class DeliveryHistoryScreen extends StatelessWidget {
  const DeliveryHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    final courierId = AuthScope.of(context).currentUser()?.uid ?? 'courier-1';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Delivery history', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        StreamBuilder<List<DeliverySummary>>(
          stream: repo.watchDeliveryHistory(courierId),
          builder: (context, snapshot) {
            final history = snapshot.data ?? [];
            if (history.isEmpty) {
              return const Text('No completed deliveries yet.');
            }
            return Column(
              children: history
                  .map(
                    (summary) => Card(
                      child: ListTile(
                        title: Text('Order #${summary.orderId}'),
                        subtitle: Text(
                          '${summary.completedAt.toLocal()}'.split('.').first,
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('\$${summary.finalPayout.toStringAsFixed(2)}'),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(5, (index) {
                                final filled = summary.rating >= index + 1;
                                return Icon(
                                  filled ? Icons.star : Icons.star_border,
                                  size: 16,
                                  color: Colors.amber,
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class CourierProfileScreen extends StatelessWidget {
  const CourierProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Courier profile', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        const ListTile(
          leading: CircleAvatar(child: Icon(Icons.person)),
          title: Text('Alex Rider'),
          subtitle: Text('4.9 rating • 1,284 deliveries'),
        ),
        const Divider(),
        const ListTile(
          leading: Icon(Icons.directions_bike_outlined),
          title: Text('Vehicle'),
          subtitle: Text('Bike • Blue Trek FX2'),
        ),
        const ListTile(
          leading: Icon(Icons.schedule),
          title: Text('Availability'),
          subtitle: Text('Mon–Fri, 11am–9pm'),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => AuthScope.of(context).signOut(),
            child: const Text('Sign out'),
          ),
        ),
      ],
    );
  }
}

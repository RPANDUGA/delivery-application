import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import 'package:data/data.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bootstrap = await _initBootstrap();
  runApp(CustomerApp(bootstrap: bootstrap));
}

Future<_Bootstrap> _initBootstrap() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return _Bootstrap(
      dataRepository: FirebaseDataRepository(),
      authRepository: FirebaseAuthRepository(),
    );
  } catch (error) {
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

class CustomerApp extends StatelessWidget {
  final _Bootstrap bootstrap;

  const CustomerApp({super.key, required this.bootstrap});

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      auth: bootstrap.authRepository,
      child: RepositoryScope(
        repository: bootstrap.dataRepository,
        child: MaterialApp(
          title: 'Foodly Customer',
          theme: AppTheme.light(),
          home: const AuthGate(),
        ),
      ),
    );
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
        return const CustomerShell();
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
              _isSignIn ? 'Welcome back' : 'Create your account',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 16),
            Text(
              _isSignIn
                  ? 'Sign in to keep ordering your favorites.'
                  : 'Sign up to discover new restaurants nearby.',
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

class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int _index = 0;

  final _screens = const [
    HomeScreen(),
    OrdersScreen(),
    CartScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Foodly'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none))
        ],
      ),
      body: _screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Orders'),
          NavigationDestination(icon: Icon(Icons.shopping_bag_outlined), label: 'Cart'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Good afternoon, Ramesh',
            style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(
            hintText: 'Search restaurants or dishes',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const SectionHeader(title: 'Top picks for you', actionLabel: 'See all'),
        const SizedBox(height: 12),
        StreamBuilder<List<Restaurant>>(
          stream: repo.watchRestaurants(),
          builder: (context, snapshot) {
            final restaurants = snapshot.data ?? [];
            return Column(
              children: restaurants
                  .map((restaurant) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: RestaurantCard(restaurant: restaurant),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionHeader(title: 'Active orders'),
        const SizedBox(height: 12),
        StreamBuilder<List<Order>>(
          stream: repo.watchOrdersForCustomer('c1'),
          builder: (context, snapshot) {
            final orders = snapshot.data ?? [];
            if (orders.isEmpty) {
              return const Text('No active orders yet.');
            }
            return Column(
              children: [
                OrderTrackingMap(orderId: orders.first.id),
                const SizedBox(height: 12),
                ...orders.map((order) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: OrderStatusCard(order: order),
                    )),
              ],
            );
          },
        ),
      ],
    );
  }
}

class OrderTrackingMap extends StatelessWidget {
  final String orderId;

  const OrderTrackingMap({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    const pickup = LatLng(37.7879, -122.4074);
    const dropoff = LatLng(37.7921, -122.3965);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Live tracking', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
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
                          userAgentPackageName: 'com.fooddelivery.customer',
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
          ],
        ),
      ),
    );
  }
}

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Your cart is ready for checkout.'),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Account', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        const ListTile(
          leading: CircleAvatar(child: Icon(Icons.person)),
          title: Text('Ramesh S.'),
          subtitle: Text('ramesh@email.com'),
        ),
        const Divider(),
        const ListTile(
          leading: Icon(Icons.location_on_outlined),
          title: Text('Delivery address'),
          subtitle: Text('200 Pine Ave, San Francisco'),
        ),
        const ListTile(
          leading: Icon(Icons.payment_outlined),
          title: Text('Payment methods'),
          subtitle: Text('Visa •••• 1024'),
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

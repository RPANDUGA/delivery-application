import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import 'package:data/data.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bootstrap = await _initBootstrap();
  runApp(RestaurantAdminApp(bootstrap: bootstrap));
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

class RestaurantAdminApp extends StatelessWidget {
  final _Bootstrap bootstrap;

  const RestaurantAdminApp({super.key, required this.bootstrap});

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      auth: bootstrap.authRepository,
      child: RepositoryScope(
        repository: bootstrap.dataRepository,
        child: MaterialApp(
          title: 'Foodly Restaurant',
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
        return const RestaurantShell();
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
              _isSignIn ? 'Restaurant sign in' : 'Create restaurant account',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 16),
            Text(
              _isSignIn
                  ? 'Manage orders and menu updates.'
                  : 'Onboard your kitchen and accept orders.',
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

class RestaurantShell extends StatefulWidget {
  const RestaurantShell({super.key});

  @override
  State<RestaurantShell> createState() => _RestaurantShellState();
}

class _RestaurantShellState extends State<RestaurantShell> {
  int _index = 0;

  final _screens = const [
    RestaurantOrdersScreen(),
    MenuScreen(),
    AnalyticsScreen(),
    PayoutsScreen(),
    RestaurantSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Admin'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.settings_outlined))
        ],
      ),
      body: _screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Orders'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: 'Menu'),
          NavigationDestination(icon: Icon(Icons.analytics_outlined), label: 'Analytics'),
          NavigationDestination(icon: Icon(Icons.payments_outlined), label: 'Payouts'),
          NavigationDestination(icon: Icon(Icons.storefront_outlined), label: 'Settings'),
        ],
      ),
    );
  }
}

class RestaurantOrdersScreen extends StatelessWidget {
  const RestaurantOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionHeader(title: 'Incoming orders'),
        const SizedBox(height: 12),
        StreamBuilder<List<Order>>(
          stream: repo.watchOrdersForRestaurant('r1'),
          builder: (context, snapshot) {
            final orders = snapshot.data ?? [];
            return Column(
              children: orders
                  .map((order) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: OrderStatusCard(order: order),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Menu items', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.ramen_dining),
            title: const Text('Roasted Veggie Bowl'),
            subtitle: const Text('In stock • \$14.50'),
            trailing: IconButton(onPressed: () {}, icon: const Icon(Icons.edit)),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.ramen_dining),
            title: const Text('Smoked Tofu Bento'),
            subtitle: const Text('Low stock • \$12.00'),
            trailing: IconButton(onPressed: () {}, icon: const Icon(Icons.edit)),
          ),
        ),
      ],
    );
  }
}

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Today', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Total sales'),
                SizedBox(height: 6),
                Text('\$1,284.00', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.timelapse),
            title: const Text('Average prep time'),
            trailing: const Text('18 min'),
          ),
        ),
      ],
    );
  }
}

class PayoutsScreen extends StatefulWidget {
  const PayoutsScreen({super.key});

  @override
  State<PayoutsScreen> createState() => _PayoutsScreenState();
}

class _PayoutsScreenState extends State<PayoutsScreen> {
  final Map<String, TextEditingController> _overrideControllers = {};

  @override
  void dispose() {
    for (final controller in _overrideControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    final userId = AuthScope.of(context).currentUser()?.uid;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Courier payouts', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        if (userId == null)
          const Text('Sign in as an admin to manage payouts.')
        else
          StreamBuilder<bool>(
            stream: repo.watchIsAdmin(userId),
            builder: (context, adminSnapshot) {
              if (adminSnapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(),
                );
              }
              if (adminSnapshot.data != true) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Admin access required.'),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AdminAccessScreen()),
                      ),
                      child: const Text('Request admin access'),
                    ),
                  ],
                );
              }
              return StreamBuilder<List<DeliverySummary>>(
                stream: repo.watchAllDeliveries(),
                builder: (context, snapshot) {
                  final deliveries = snapshot.data ?? [];
                  if (deliveries.isEmpty) {
                    return const Text('No courier deliveries yet.');
                  }
                  return Column(
                    children: deliveries.map((delivery) {
                      final controller = _overrideControllers.putIfAbsent(
                        delivery.orderId,
                        () => TextEditingController(
                          text: delivery.overridePayout?.toStringAsFixed(2) ?? '',
                        ),
                      );
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Order #${delivery.orderId}',
                                  style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 6),
                              Text('Courier: ${delivery.courierId}'),
                              Text('Base: \$${delivery.basePayout.toStringAsFixed(2)}'),
                              Text('Tip: \$${delivery.tip.toStringAsFixed(2)}'),
                              Text('Final: \$${delivery.finalPayout.toStringAsFixed(2)}'),
                              const SizedBox(height: 8),
                              TextField(
                                controller: controller,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Override payout',
                                  prefixText: '\$',
                                ),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final value = _parseAmount(controller.text);
                                    await repo.updateDeliverySummary(
                                      DeliverySummary(
                                        orderId: delivery.orderId,
                                        courierId: delivery.courierId,
                                        basePayout: delivery.basePayout,
                                        tip: delivery.tip,
                                        overridePayout: value,
                                        rating: delivery.rating,
                                        completedAt: delivery.completedAt,
                                      ),
                                    );
                                  },
                                  child: const Text('Save override'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              );
            },
          ),
      ],
    );
  }
}

class RestaurantSettingsScreen extends StatelessWidget {
  const RestaurantSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Store settings', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        const ListTile(
          leading: Icon(Icons.storefront_outlined),
          title: Text('Hours'),
          subtitle: Text('Open • 11:00 AM – 10:00 PM'),
        ),
        const ListTile(
          leading: Icon(Icons.pin_drop_outlined),
          title: Text('Pickup location'),
          subtitle: Text('81 Market St'),
        ),
        ListTile(
          leading: const Icon(Icons.admin_panel_settings_outlined),
          title: const Text('Admin access'),
          subtitle: const Text('View or request admin role'),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AdminAccessScreen()),
          ),
        ),
        const ListTile(
          leading: Icon(Icons.support_agent_outlined),
          title: Text('Support'),
          subtitle: Text('Help center & onboarding'),
        ),
      ],
    );
  }
}

class AdminAccessScreen extends StatelessWidget {
  const AdminAccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    final userId = AuthScope.of(context).currentUser()?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Access')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: userId == null
            ? const Text('Sign in to view admin status.')
            : StreamBuilder<bool>(
                stream: repo.watchIsAdmin(userId),
                builder: (context, snapshot) {
                  final isAdmin = snapshot.data == true;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('User ID: $userId'),
                      const SizedBox(height: 8),
                      Text(isAdmin ? 'Status: Admin' : 'Status: Standard user'),
                      const SizedBox(height: 16),
                      const Text(
                        'To request admin access, contact your system owner and '
                        'run the admin claim script with your UID.',
                      ),
                      const SizedBox(height: 12),
                      SelectableText(
                        'cd scripts/seed\n'
                        'npm run set-admin -- <YOUR_UID>',
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}

double? _parseAmount(String input) {
  final normalized = input.trim().replaceAll(',', '');
  if (normalized.isEmpty) return null;
  return double.tryParse(normalized);
}

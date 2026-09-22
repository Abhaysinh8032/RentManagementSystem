import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

//import '../../admin/presentation/admin_pending_users_screen.dart';
import '../../admin/presentation/admin_properties_screen.dart';
import '../../admin/presentation/admin_rental_requests_screen.dart';
import '../../admin/presentation/admin_users_screen.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../property/presentation/property_list_screen.dart';
import '../../rental/presentation/my_rentals_screen.dart';

/// This is now the real role-based landing screen: a bottom-nav shell that
/// shows property browsing + "My Rentals" for CUSTOMER, or the three admin
/// work queues for ADMIN. Kept the name `HomeScreen` and the '/home' route
/// stable, exactly as planned when this was still a placeholder.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;
    final loginResult = state is SignInSuccess ? state.result : null;
    final isAdmin = loginResult?.role == 'ADMIN';
    final isPending = loginResult?.status == 'PENDING_APPROVAL';

    final tabs = isAdmin
//        ? const [AdminPendingUsersScreen(), AdminPropertiesScreen(), AdminRentalRequestsScreen()]
        ? const [AdminUsersScreen(), AdminPropertiesScreen(), AdminRentalRequestsScreen()]
        : const [PropertyListScreen(), MyRentalsScreen()];

    final navItems = isAdmin
        ? const [
            BottomNavigationBarItem(icon: Icon(Icons.how_to_reg_outlined), label: 'Users'),
            BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: 'Properties'),
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), label: 'Requests'),
          ]
        : const [
            BottomNavigationBarItem(icon: Icon(Icons.chair_alt_outlined), label: 'Properties'),
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), label: 'My Rentals'),
          ];

    // Clamp in case the tab count differs between roles and _tabIndex is stale
    // from a previous build (defensive - shouldn't normally happen since role
    // doesn't change without a fresh login).
    final safeIndex = _tabIndex < tabs.length ? _tabIndex : 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'Admin' : 'Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Profile',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!isAdmin && isPending)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.amber.shade100,
              child: const Row(
                children: [
                  Icon(Icons.hourglass_top, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your account is awaiting admin approval. You can browse, but requesting a rental needs approval first.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(child: IndexedStack(index: safeIndex, children: tabs)),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: safeIndex,
        onTap: (i) => setState(() => _tabIndex = i),
        type: BottomNavigationBarType.fixed,
        items: navItems,
      ),
    );
  }
}

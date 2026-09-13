import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../profile/presentation/profile_screen.dart';

/// Named `HomeScreen` deliberately, not `DashboardScreen` or `PropertyListScreen`:
/// it's a generic authenticated landing spot for sprint 1. Once role-based content
/// exists, this becomes the screen that shows a property browse list for CUSTOMER
/// and a revenue dashboard for ADMIN - keeping the route name stable now avoids
/// renaming '/home' everywhere later.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;
    final loginResult = state is SignInSuccess ? state.result : null;
    final isPending = loginResult?.status == 'PENDING_APPROVAL';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
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
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome${loginResult != null ? ', ${loginResult.name}' : ''}!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (isPending)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.hourglass_top, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your account is awaiting admin approval. Some features are locked until then.',
                      ),
                    ),
                  ],
                ),
              )
            else
              Text(
                'Browse and request properties from here.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
              ),
          ],
        ),
      ),
    );
  }
}

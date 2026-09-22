import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/navigation/route_observer.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../data/admin_user_model.dart';
import '../data/admin_user_repository.dart';

/// Was AdminPendingUsersScreen - renamed and extended with a Pending/All
/// toggle. Previously `listAll()` existed on the repository but nothing in
/// the UI ever called it, so admins had no way to see approved/blocked users
/// at all. This is the fix for that gap.
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

enum _UserFilter { pending, all }

class _AdminUsersScreenState extends State<AdminUsersScreen> with RouteAware {
  late final AdminUserRepository _repository;
  late Future<List<AdminUserModel>> _future;
  _UserFilter _filter = _UserFilter.pending;
  int? _actioningUserId;

  @override
  void initState() {
    super.initState();
    _repository = AdminUserRepository(apiClient: context.read<ApiClient>());
    _future = _repository.listPending();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    appRouteObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() => _refresh();

  Future<void> _refresh() async {
    setState(() => _future = _filter == _UserFilter.pending ? _repository.listPending() : _repository.listAll());
    await _future;
  }

  void _setFilter(_UserFilter filter) {
    setState(() => _filter = filter);
    _refresh();
  }

  Future<void> _decide(AdminUserModel user, bool approve) async {
    setState(() => _actioningUserId = user.id);
    try {
      await _repository.decideApproval(user.id, approve);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(approve ? '${user.name} approved' : '${user.name} rejected')),
      );
      _refresh();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: Colors.red.shade600));
    } finally {
      if (mounted) setState(() => _actioningUserId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('Pending'),
                selected: _filter == _UserFilter.pending,
                onSelected: (_) => _setFilter(_UserFilter.pending),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('All Users'),
                selected: _filter == _UserFilter.all,
                onSelected: (_) => _setFilter(_UserFilter.all),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: FutureBuilder<List<AdminUserModel>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  final message = snapshot.error is ApiException ? (snapshot.error as ApiException).message : 'Failed to load';
                  return Center(child: Text(message));
                }
                final users = snapshot.data ?? [];
                if (users.isEmpty) {
                  return LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: constraints.maxHeight,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.how_to_reg_outlined, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text(
                                _filter == _UserFilter.pending ? 'No users awaiting approval' : 'No users found',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final isActioning = _actioningUserId == user.id;
                    final isPending = user.status == 'PENDING_APPROVAL';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            CircleAvatar(child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?')),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(user.email, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                  if (user.phone != null) Text(user.phone!, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 6,
                                    children: [
                                      _Tag(label: user.role, color: user.role == 'ADMIN' ? Colors.indigo : Colors.blueGrey),
                                      _Tag(label: user.status.replaceAll('_', ' '), color: _statusColor(user.status)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (isPending)
                              if (isActioning)
                                const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              else
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () => _decide(user, false),
                                      icon: Icon(Icons.close, color: Colors.red.shade600),
                                      tooltip: 'Reject',
                                    ),
                                    IconButton(
                                      onPressed: () => _decide(user, true),
                                      icon: Icon(Icons.check, color: Colors.green.shade600),
                                      tooltip: 'Approve',
                                    ),
                                  ],
                                ),
                            // APPROVED/BLOCKED users have no action here - the backend only
                            // allows a decision while status is PENDING_APPROVAL. Re-blocking
                            // an approved user or unblocking a blocked one isn't supported
                            // server-side yet; flag if you want that added.
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'APPROVED':
        return Colors.green;
      case 'BLOCKED':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}

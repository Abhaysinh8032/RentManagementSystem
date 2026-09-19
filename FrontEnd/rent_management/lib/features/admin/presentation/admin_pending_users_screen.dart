import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../data/admin_user_model.dart';
import '../data/admin_user_repository.dart';

class AdminPendingUsersScreen extends StatefulWidget {
  const AdminPendingUsersScreen({super.key});

  @override
  State<AdminPendingUsersScreen> createState() => _AdminPendingUsersScreenState();
}

class _AdminPendingUsersScreenState extends State<AdminPendingUsersScreen> {
  late final AdminUserRepository _repository;
  late Future<List<AdminUserModel>> _future;
  int? _actioningUserId;

  @override
  void initState() {
    super.initState();
    _repository = AdminUserRepository(apiClient: context.read<ApiClient>());
    _future = _repository.listPending();
  }

  Future<void> _refresh() async {
    setState(() => _future = _repository.listPending());
    await _future;
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
    return RefreshIndicator(
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
                        Text('No users awaiting approval', style: TextStyle(color: Colors.grey.shade600)),
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
                          ],
                        ),
                      ),
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
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../rental/data/rental_model.dart';
import '../../rental/data/rental_repository.dart';
import '../../rental/presentation/rental_detail_screen.dart';

class AdminRentalRequestsScreen extends StatefulWidget {
  const AdminRentalRequestsScreen({super.key});

  @override
  State<AdminRentalRequestsScreen> createState() => _AdminRentalRequestsScreenState();
}

class _AdminRentalRequestsScreenState extends State<AdminRentalRequestsScreen> {
  static const _statusFilters = ['ALL', 'PENDING', 'APPROVED', 'RETURN_REQUESTED', 'RETURNED', 'REJECTED'];

  late final RentalRepository _repository;
  late Future<List<RentalRequestModel>> _future;
  String _selectedFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _repository = RentalRepository(apiClient: context.read<ApiClient>());
    _future = _repository.listAllForAdmin();
  }

  Future<void> _refresh() async {
    setState(() => _future = _repository.listAllForAdmin(status: _selectedFilter == 'ALL' ? null : _selectedFilter));
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            children: _statusFilters.map((filter) {
              final selected = filter == _selectedFilter;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(filter.replaceAll('_', ' ')),
                  selected: selected,
                  onSelected: (_) {
                    setState(() => _selectedFilter = filter);
                    _refresh();
                  },
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: FutureBuilder<List<RentalRequestModel>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  final message = snapshot.error is ApiException ? (snapshot.error as ApiException).message : 'Failed to load';
                  return Center(child: Text(message));
                }
                final rentals = snapshot.data ?? [];
                if (rentals.isEmpty) {
                  return LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: constraints.maxHeight,
                        child: Center(
                          child: Text('No rental requests here', style: TextStyle(color: Colors.grey.shade600)),
                        ),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: rentals.length,
                  itemBuilder: (context, index) {
                    final rental = rentals[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(rental.propertyName ?? 'Property #${rental.propertyId}'),
                        subtitle: Text('${rental.userName ?? 'User #${rental.userId}'} • Qty ${rental.quantity}'),
                        trailing: Text(rental.status.replaceAll('_', ' '), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => RentalDetailScreen(rentalRequestId: rental.id, isAdmin: true)),
                          );
                          _refresh();
                        },
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
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../data/rental_model.dart';
import '../data/rental_repository.dart';
import 'rental_detail_screen.dart';

class MyRentalsScreen extends StatefulWidget {
  const MyRentalsScreen({super.key});

  @override
  State<MyRentalsScreen> createState() => _MyRentalsScreenState();
}

class _MyRentalsScreenState extends State<MyRentalsScreen> {
  late final RentalRepository _repository;
  late Future<List<RentalRequestModel>> _future;

  @override
  void initState() {
    super.initState();
    _repository = RentalRepository(apiClient: context.read<ApiClient>());
    _future = _repository.listMine();
  }

  Future<void> _refresh() async {
    setState(() => _future = _repository.listMine());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text('No rental requests yet', style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
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
                  subtitle: Text('Qty ${rental.quantity} • ${_formatDate(rental.startDate)} - ${_formatDate(rental.endDate)}'),
                  trailing: Text(rental.status.replaceAll('_', ' '), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => RentalDetailScreen(rentalRequestId: rental.id, isAdmin: false)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

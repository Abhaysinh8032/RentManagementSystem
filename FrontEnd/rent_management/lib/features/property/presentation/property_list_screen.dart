import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/navigation/route_observer.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../data/property_model.dart';
import '../data/property_repository.dart';
import 'property_detail_screen.dart';
import 'property_image.dart';

class PropertyListScreen extends StatefulWidget {
  const PropertyListScreen({super.key});

  @override
  State<PropertyListScreen> createState() => _PropertyListScreenState();
}

class _PropertyListScreenState extends State<PropertyListScreen> with RouteAware {
  late final PropertyRepository _repository;
  late Future<List<PropertyModel>> _future;

  @override
  void initState() {
    super.initState();
    _repository = PropertyRepository(apiClient: context.read<ApiClient>());
    _future = _repository.listActive();
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

  // Fires when a screen pushed on top of this one (e.g. property detail) is
  // popped and this tab becomes visible again - not just on manual pull-to-refresh.
  @override
  void didPopNext() => _refresh();

  Future<void> _refresh() async {
    setState(() => _future = _repository.listActive());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<PropertyModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final message = snapshot.error is ApiException ? (snapshot.error as ApiException).message : 'Failed to load properties';
            return _ErrorState(message: message, onRetry: _refresh);
          }
          final properties = snapshot.data ?? [];
          if (properties.isEmpty) {
            return const _EmptyState();
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: properties.length,
            itemBuilder: (context, index) => _PropertyCard(property: properties[index]),
          );
        },
      ),
    );
  }
}

class _PropertyCard extends StatelessWidget {
  final PropertyModel property;
  const _PropertyCard({required this.property});

  @override
  Widget build(BuildContext context) {
    final outOfStock = property.availableQuantity <= 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PropertyDetailScreen(propertyId: property.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PropertyImage(imageUrl: property.imageUrl, size: 64),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(property.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    if (property.category != null) ...[
                      const SizedBox(height: 2),
                      Text(property.category!, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      '₹${property.pricePerUnitPerDay.toStringAsFixed(0)}/unit/day  •  Deposit ₹${property.depositPerUnit.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      outOfStock ? 'Out of stock' : '${property.availableQuantity} available',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: outOfStock ? Colors.red.shade600 : Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: constraints.maxHeight,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text('No properties available yet', style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: constraints.maxHeight,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 40, color: Colors.red.shade400),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(message, textAlign: TextAlign.center),
                ),
                const SizedBox(height: 12),
                OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

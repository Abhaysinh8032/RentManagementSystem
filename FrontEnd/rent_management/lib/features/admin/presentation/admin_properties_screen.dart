import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../property/data/property_model.dart';
import '../../property/data/property_repository.dart';
import 'admin_property_form_screen.dart';

class AdminPropertiesScreen extends StatefulWidget {
  const AdminPropertiesScreen({super.key});

  @override
  State<AdminPropertiesScreen> createState() => _AdminPropertiesScreenState();
}

class _AdminPropertiesScreenState extends State<AdminPropertiesScreen> {
  late final PropertyRepository _repository;
  late Future<List<PropertyModel>> _future;

  @override
  void initState() {
    super.initState();
    _repository = PropertyRepository(apiClient: context.read<ApiClient>());
    _future = _repository.listAllForAdmin();
  }

  Future<void> _refresh() async {
    setState(() => _future = _repository.listAllForAdmin());
    await _future;
  }

  Future<void> _openForm({PropertyModel? existing}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AdminPropertyFormScreen(existing: existing)),
    );
    if (saved == true) _refresh();
  }

  Future<void> _toggleActive(PropertyModel property) async {
    try {
      await _repository.setActive(property.id, !property.active);
      _refresh();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: Colors.red.shade600));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<PropertyModel>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              final message = snapshot.error is ApiException ? (snapshot.error as ApiException).message : 'Failed to load';
              return Center(child: Text(message));
            }
            final properties = snapshot.data ?? [];
            if (properties.isEmpty) {
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
                          Text('No properties yet - tap + to add one', style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: properties.length,
              itemBuilder: (context, index) {
                final property = properties[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    onTap: () => _openForm(existing: property),
                    title: Text(property.name),
                    subtitle: Text('${property.availableQuantity}/${property.totalQuantity} available • ₹${property.pricePerUnitPerDay.toStringAsFixed(0)}/day'),
                    trailing: Switch(
                      value: property.active,
                      onChanged: (_) => _toggleActive(property),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

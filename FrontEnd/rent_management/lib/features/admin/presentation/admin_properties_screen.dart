import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/navigation/route_observer.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../property/data/property_model.dart';
import '../../property/data/property_repository.dart';
import '../../property/presentation/property_image.dart';
import 'admin_property_form_screen.dart';

class AdminPropertiesScreen extends StatefulWidget {
  const AdminPropertiesScreen({super.key});

  @override
  State<AdminPropertiesScreen> createState() => _AdminPropertiesScreenState();
}

class _AdminPropertiesScreenState extends State<AdminPropertiesScreen> with RouteAware {
  late final PropertyRepository _repository;

  // Switched from a FutureBuilder-driven `_future` to holding the list
  // directly in state. That's what makes the toggle fix possible: a
  // FutureBuilder only ever shows what the LAST completed fetch returned, so
  // flipping a switch always had to wait for a full round-trip + re-fetch
  // before anything visibly changed. Holding the list locally means we can
  // flip one item's `active` field the instant the switch is tapped.
  List<PropertyModel>? _properties;
  bool _loading = true;
  String? _errorMessage;
  final Set<int> _togglingIds = {};

  @override
  void initState() {
    super.initState();
    _repository = PropertyRepository(apiClient: context.read<ApiClient>());
    _load();
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
  void didPopNext() => _load();

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final list = await _repository.listAllForAdmin();
      if (!mounted) return;
      setState(() {
        _properties = list;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _openForm({PropertyModel? existing}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AdminPropertyFormScreen(existing: existing)),
    );
    if (saved == true) _load();
  }

  Future<void> _toggleActive(PropertyModel property) async {
    final properties = _properties;
    if (properties == null) return;

    final index = properties.indexWhere((p) => p.id == property.id);
    if (index == -1) return;

    final previous = properties[index];
    final optimistic = previous.copyWith(active: !previous.active);

    // Flip instantly - this is the actual fix. Don't wait for the network
    // before the switch visually moves.
    setState(() {
      properties[index] = optimistic;
      _togglingIds.add(property.id);
    });

    try {
      final confirmed = await _repository.setActive(property.id, optimistic.active);
      if (!mounted) return;
      final i = properties.indexWhere((p) => p.id == property.id);
      if (i != -1) setState(() => properties[i] = confirmed);
    } on ApiException catch (e) {
      if (!mounted) return;
      // Roll back - don't leave the switch showing a state the server rejected.
      final i = properties.indexWhere((p) => p.id == property.id);
      if (i != -1) setState(() => properties[i] = previous);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: Colors.red.shade600));
    } finally {
      if (mounted) setState(() => _togglingIds.remove(property.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: Builder(
          builder: (context) {
            if (_loading && _properties == null) {
              return const Center(child: CircularProgressIndicator());
            }
            if (_errorMessage != null && _properties == null) {
              return Center(child: Text(_errorMessage!));
            }
            final properties = _properties ?? [];
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
                final isToggling = _togglingIds.contains(property.id);
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    onTap: () => _openForm(existing: property),
                    leading: PropertyImage(imageUrl: property.coverImageUrl, size: 48),
                    title: Text(property.name),
                    subtitle: Text('${property.availableQuantity}/${property.totalQuantity} available • ₹${property.pricePerUnitPerDay.toStringAsFixed(0)}/day'),
                    trailing: isToggling
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: Padding(
                              padding: EdgeInsets.all(2.0),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : Switch(
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

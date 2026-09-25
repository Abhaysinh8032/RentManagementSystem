import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../rental/presentation/create_rental_request_screen.dart';
import '../data/property_model.dart';
import '../data/property_repository.dart';
import 'property_image_gallery.dart';

class PropertyDetailScreen extends StatefulWidget {
  final int propertyId;
  const PropertyDetailScreen({super.key, required this.propertyId});

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  late final PropertyRepository _repository;
  late Future<PropertyModel> _future;

  @override
  void initState() {
    super.initState();
    _repository = PropertyRepository(apiClient: context.read<ApiClient>());
    _future = _repository.getById(widget.propertyId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Property Detail')),
      body: FutureBuilder<PropertyModel>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final message = snapshot.error is ApiException ? (snapshot.error as ApiException).message : 'Failed to load property';
            return Center(child: Text(message));
          }

          final property = snapshot.data!;
          final outOfStock = property.availableQuantity <= 0;

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PropertyImageGallery(
                  imageUrls: property.imageUrls,
                  height: 200,
                  borderRadius: BorderRadius.circular(12),
 //                 iconSize: 72,
                ),
                const SizedBox(height: 20),
                Text(property.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                if (property.category != null) ...[
                  const SizedBox(height: 4),
                  Text(property.category!, style: TextStyle(color: Colors.grey.shade600)),
                ],
                const SizedBox(height: 16),
                if (property.description != null) ...[
                  Text(property.description!, style: const TextStyle(fontSize: 15)),
                  const SizedBox(height: 16),
                ],
                _InfoRow(label: 'Price', value: '₹${property.pricePerUnitPerDay.toStringAsFixed(0)} / unit / day'),
                _InfoRow(label: 'Security deposit', value: '₹${property.depositPerUnit.toStringAsFixed(0)} / unit'),
                _InfoRow(
                  label: 'Availability',
                  value: outOfStock ? 'Out of stock' : '${property.availableQuantity} of ${property.totalQuantity} available',
                  valueColor: outOfStock ? Colors.red.shade600 : Colors.green.shade700,
                ),
                const Spacer(),
                FilledButton(
                  onPressed: outOfStock
                      ? null
                      : () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => CreateRentalRequestScreen(property: property)),
                          ),
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: Text(outOfStock ? 'Out of Stock' : 'Request to Rent'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: valueColor)),
        ],
      ),
    );
  }
}

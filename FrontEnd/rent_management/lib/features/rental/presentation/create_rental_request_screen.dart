import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../property/data/property_model.dart';
import '../data/rental_repository.dart';
import 'rental_detail_screen.dart';

class CreateRentalRequestScreen extends StatefulWidget {
  final PropertyModel property;
  const CreateRentalRequestScreen({super.key, required this.property});

  @override
  State<CreateRentalRequestScreen> createState() => _CreateRentalRequestScreenState();
}

class _CreateRentalRequestScreenState extends State<CreateRentalRequestScreen> {
  late final RentalRepository _repository;
  int _quantity = 1;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _repository = RentalRepository(apiClient: context.read<ApiClient>());
  }

  int get _days {
    if (_startDate == null || _endDate == null) return 0;
    final diff = _endDate!.difference(_startDate!).inDays;
    return diff < 1 ? 1 : diff;
  }

  double get _estimatedRent => widget.property.pricePerUnitPerDay * _quantity * _days;
  double get _estimatedDeposit => widget.property.depositPerUnit * _quantity;

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        // keep end date valid if it's now before/equal to the new start date
        if (_endDate != null && !_endDate!.isAfter(_startDate!)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    if (_startDate == null) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate!.add(const Duration(days: 1)),
      firstDate: _startDate!.add(const Duration(days: 1)),
      lastDate: _startDate!.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Future<void> _submit() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both start and end dates')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final rental = await _repository.createRequest(
        propertyId: widget.property.id,
        quantity: _quantity,
        startDate: _startDate!,
        endDate: _endDate!,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => RentalDetailScreen(rentalRequestId: rental.id, isAdmin: false)),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: Colors.red.shade600));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _formatDate(DateTime? d) => d == null ? 'Select date' : '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final property = widget.property;

    return Scaffold(
      appBar: AppBar(title: Text('Request ${property.name}')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Quantity', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton.outlined(
                  onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                  icon: const Icon(Icons.remove),
                ),
                Expanded(
                  child: Text('$_quantity', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                IconButton.outlined(
                  onPressed: _quantity < property.availableQuantity ? () => setState(() => _quantity++) : null,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            Text('${property.availableQuantity} available', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            const SizedBox(height: 20),
            Text('Rental period', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickStartDate,
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(_formatDate(_startDate)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _startDate == null ? null : _pickEndDate,
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(_formatDate(_endDate)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_startDate != null && _endDate != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$_days day(s)', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _EstimateRow(label: 'Estimated rent', value: _estimatedRent),
                    _EstimateRow(label: 'Security deposit', value: _estimatedDeposit),
                    const Divider(),
                    _EstimateRow(label: 'Total', value: _estimatedRent + _estimatedDeposit, bold: true),
                    const SizedBox(height: 6),
                    Text(
                      'Final bills are generated by the server on submit - this is an estimate.',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            const Spacer(),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              child: _submitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Submit Request'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EstimateRow extends StatelessWidget {
  final String label;
  final double value;
  final bool bold;
  const _EstimateRow({required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text('₹${value.toStringAsFixed(0)}', style: style),
        ],
      ),
    );
  }
}

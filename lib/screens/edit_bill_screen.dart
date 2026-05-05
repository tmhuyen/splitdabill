import 'package:flutter/material.dart';
import '../models/index.dart';
import '../services/index.dart';
import '../utils/currency_utils.dart';

class EditBillScreen extends StatefulWidget {
  final String eventId;
  final String billId;

  const EditBillScreen({
    super.key,
    required this.eventId,
    required this.billId,
  });

  @override
  State<EditBillScreen> createState() => _EditBillScreenState();
}

class _EditBillScreenState extends State<EditBillScreen> {
  final _dbService = DatabaseService();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  late Event event;
  late Bill bill;

  @override
  void initState() {
    super.initState();
    event = _dbService.getEvent(widget.eventId)!;
    bill = event.bills.firstWhere((item) => item.id == widget.billId);
    _titleController.text = bill.title;
    _amountController.text = bill.totalAmount.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a bill name')),
      );
      return;
    }

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount must be greater than zero')),
      );
      return;
    }

    bill.title = title;
    bill.totalAmount = amount;
    bill.splits = BillCalculationService.rebuildBillSplits(
      amount,
      event.memberIds,
    );
    event.updatedAt = DateTime.now();

    await _dbService.updateEvent(event);

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Bill')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Update bill details',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Bill name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Total amount',
                  prefixText: '${CurrencyUtils.symbol(event.currencyCode)} ',
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

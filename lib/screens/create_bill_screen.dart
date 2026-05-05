import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/index.dart';
import '../services/index.dart';
import '../utils/currency_utils.dart';
import 'package:uuid/uuid.dart';

class CreateBillScreen extends StatefulWidget {
  final String eventId;

  const CreateBillScreen({Key? key, required this.eventId}) : super(key: key);

  @override
  State<CreateBillScreen> createState() => _CreateBillScreenState();
}

class _CreateBillScreenState extends State<CreateBillScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _dbService = DatabaseService();
  final _ocrService = OCRService();

  late Event event;
  String _selectedPayerId = '';
  String _selectedCategory = 'General';
  late List<Person> members;

  bool get _hasPeople => members.isNotEmpty;

  final _categories = [
    'General',
    'Food',
    'Transport',
    'Hotel',
    'Entertainment',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    event = _dbService.getEvent(widget.eventId)!;
    members = event.memberIds
        .map((id) => _dbService.getPerson(id))
        .whereType<Person>()
        .toList();

    if (members.isNotEmpty) {
      _selectedPayerId = members[0].id;
    }
  }

  void _scanReceipt() async {
    if (kIsWeb) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Receipt OCR is not supported on web. Use Android or iOS build.'),
        ),
      );
      return;
    }

    final text = await _ocrService.extractTextFromImage();
    if (text.isEmpty) return;

    final amount =
        OCRService.extractAmount(text, currencyCode: event.currencyCode);
    if (amount != null) {
      _amountController.text = amount.toStringAsFixed(2);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Detected ${CurrencyUtils.formatAmount(amount, event.currencyCode)} from receipt'),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Could not detect a reliable total amount.')),
      );
    }
  }

  void _createBill() {
    if (!_hasPeople) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('You cannot add a bill before adding people.')),
      );
      return;
    }

    if (_titleController.text.isEmpty || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill all fields')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount must be > 0')),
      );
      return;
    }

    // Even split by default
    final splits = BillCalculationService.calculateEvenSplit(
      amount,
      event.memberIds,
    );

    final bill = Bill(
      id: const Uuid().v4(),
      title: _titleController.text,
      description: '',
      totalAmount: amount,
      date: DateTime.now(),
      payerId: _selectedPayerId,
      splits: splits.entries
          .map((e) => SplitEntry(personId: e.key, amount: e.value))
          .toList(),
      category: _selectedCategory,
    );

    event.bills.add(bill);
    _dbService.updateEvent(event);

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bill created')),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Bill')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bill Details',
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Bill Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: '${CurrencyUtils.symbol(event.currencyCode)} ',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedCategory = val!),
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedPayerId,
                onTap: _hasPeople
                    ? null
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'You cannot add a bill before adding people.'),
                          ),
                        );
                      },
                items: members
                    .map((p) =>
                        DropdownMenuItem(value: p.id, child: Text(p.name)))
                    .toList(),
                onChanged: _hasPeople
                    ? (val) => setState(() => _selectedPayerId = val!)
                    : null,
                decoration: const InputDecoration(labelText: 'Paid By'),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _hasPeople ? _scanReceipt : null,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Scan Receipt'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _hasPeople ? _createBill : null,
                  child: const Text('Create Bill'),
                ),
              ),
              if (!_hasPeople) ...[
                const SizedBox(height: 16),
                const Text(
                  'Add people to this event before creating a bill.',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

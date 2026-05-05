import 'package:flutter/material.dart';
import '../models/index.dart';
import '../services/index.dart';
import '../theme/app_colors.dart';
import '../utils/currency_utils.dart';
import 'edit_bill_screen.dart';

enum SplitMode { even, manual }

class SplitBillScreen extends StatefulWidget {
  final String eventId;
  final String billId;

  const SplitBillScreen({
    Key? key,
    required this.eventId,
    required this.billId,
  }) : super(key: key);

  @override
  State<SplitBillScreen> createState() => _SplitBillScreenState();
}

class _SplitBillScreenState extends State<SplitBillScreen> {
  final _dbService = DatabaseService();
  final _controllers = <String, TextEditingController>{};
  final _editedPersonIds = <String>{};

  late Event event;
  late Bill bill;
  late List<Person> members;
  SplitMode _mode = SplitMode.even;
  bool _isInternalUpdate = false;
  String? _activePersonId;

  @override
  void initState() {
    super.initState();
    _loadCurrentBillState();
  }

  void _disposeControllers() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
  }

  void _loadCurrentBillState() {
    _disposeControllers();

    event = _dbService.getEvent(widget.eventId)!;
    bill = event.bills.firstWhere((b) => b.id == widget.billId);
    members = event.memberIds
        .map((id) => _dbService.getPerson(id))
        .whereType<Person>()
        .toList();

    _editedPersonIds.clear();
    _activePersonId = null;
    _isInternalUpdate = false;

    final initialAmounts = _initialAmounts();
    _mode = _looksEven(initialAmounts) ? SplitMode.even : SplitMode.manual;

    for (final person in members) {
      final controller = TextEditingController(
        text: _formatAmount(initialAmounts[person.id] ?? 0),
      );
      controller.addListener(() => _handleAmountChanged(person.id));
      _controllers[person.id] = controller;
    }

    if (mounted) {
      setState(() {});
    }
  }

  Map<String, double> _initialAmounts() {
    if (bill.splits.isNotEmpty) {
      return {
        for (final split in bill.splits) split.personId: split.amount,
      };
    }

    return BillCalculationService.calculateEvenSplit(
      bill.totalAmount,
      event.memberIds,
    );
  }

  bool _looksEven(Map<String, double> amounts) {
    if (amounts.isEmpty || members.isEmpty) return true;
    final target = bill.totalAmount / members.length;
    return amounts.values.every((value) => (value - target).abs() <= 0.01);
  }

  String _formatAmount(double value) {
    return value.toStringAsFixed(2);
  }

  double _parseAmount(String text) {
    return double.tryParse(text.trim()) ?? 0;
  }

  Map<String, double> _readAmounts() {
    return {
      for (final person in members)
        person.id: _parseAmount(_controllers[person.id]?.text ?? '0'),
    };
  }

  void _setControllerAmount(String personId, double amount) {
    final controller = _controllers[personId];
    if (controller == null) return;
    final text = _formatAmount(amount);
    if (controller.text == text) return;
    _isInternalUpdate = true;
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _isInternalUpdate = false;
  }

  void _handleAmountChanged(String personId) {
    if (_isInternalUpdate) return;

    _activePersonId = personId;
    _editedPersonIds.add(personId);

    final amounts = _readAmounts();
    final currentValue = amounts[personId] ?? 0;
    final otherTotal = amounts.entries
        .where((entry) => entry.key != personId)
        .fold(0.0, (sum, entry) => sum + entry.value);
    final maxAllowed =
        (bill.totalAmount - otherTotal).clamp(0.0, bill.totalAmount);

    if (currentValue > maxAllowed + 0.01) {
      _setControllerAmount(personId, maxAllowed);
    }

    _refreshDerivedState();
  }

  void _setMode(SplitMode mode) {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      _refreshDerivedState();
    });
  }

  void _refreshDerivedState() {
    final amounts = _readAmounts();

    if (_mode == SplitMode.even) {
      final updated = BillCalculationService.rebalanceEvenSplit(
        totalAmount: bill.totalAmount,
        personIds: event.memberIds,
        currentAmounts: amounts,
        editedPersonIds: _editedPersonIds,
      );

      _isInternalUpdate = true;
      for (final person in members) {
        final amount = updated[person.id] ?? 0;
        _setControllerAmount(person.id, amount);
      }
      _isInternalUpdate = false;
    } else {
      final assignedTotal =
          amounts.values.fold(0.0, (sum, value) => sum + value);
      final remaining = bill.totalAmount - assignedTotal;

      if (remaining < -0.01 && _activePersonId != null) {
        final otherTotal = amounts.entries
            .where((entry) => entry.key != _activePersonId)
            .fold(0.0, (sum, entry) => sum + entry.value);
        final maxAllowed =
            (bill.totalAmount - otherTotal).clamp(0.0, bill.totalAmount);
        _setControllerAmount(_activePersonId!, maxAllowed);
      }
    }

    _persistCurrentState();

    if (mounted) {
      setState(() {});
    }
  }

  void _persistCurrentState() {
    final amounts = _readAmounts();
    bill.splits = BillCalculationService.buildSplitEntriesFromAmounts(amounts);
    event.updatedAt = DateTime.now();
    _dbService.updateEvent(event);
  }

  void _fillEvenSplit() {
    _editedPersonIds.clear();
    _mode = SplitMode.even;
    final evenAmounts = BillCalculationService.calculateEvenSplit(
      bill.totalAmount,
      event.memberIds,
    );

    _isInternalUpdate = true;
    for (final person in members) {
      _setControllerAmount(person.id, evenAmounts[person.id] ?? 0);
    }
    _isInternalUpdate = false;

    _persistCurrentState();
    setState(() {});
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  Future<void> _editBill() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EditBillScreen(eventId: widget.eventId, billId: bill.id),
      ),
    );

    if (updated == true && mounted) {
      _loadCurrentBillState();
    }
  }

  @override
  Widget build(BuildContext context) {
    final amounts = _readAmounts();
    final assignedTotal = amounts.values.fold(0.0, (sum, value) => sum + value);
    final remaining = bill.totalAmount - assignedTotal;
    final allEdited =
        _editedPersonIds.length == members.length && members.isNotEmpty;
    final overflow = remaining < -0.01;
    final locked = remaining.abs() <= 0.01;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Split Bill'),
        actions: [
          IconButton(
            tooltip: 'Edit bill',
            icon: const Icon(Icons.edit_outlined),
            onPressed: _editBill,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bill.title,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total: ${CurrencyUtils.formatAmount(bill.totalAmount, event.currencyCode)}',
                          ),
                          Text(
                            'Remaining: ${CurrencyUtils.formatAmount(remaining.clamp(0, bill.totalAmount), event.currencyCode)}',
                            style: TextStyle(
                              color: overflow ||
                                      allEdited && remaining.abs() > 0.01
                                  ? AppColors.error
                                  : locked
                                      ? AppColors.success
                                      : AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                      if (overflow)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'Split total cannot exceed the bill total.',
                            style: TextStyle(color: AppColors.error),
                          ),
                        )
                      else if (allEdited && remaining.abs() > 0.01)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'All participants are edited. Total still does not match the bill.',
                            style: TextStyle(color: AppColors.error),
                          ),
                        )
                      else if (locked)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'Bill is fully allocated. Auto-adjustment is locked until you change a value.',
                            style: TextStyle(color: AppColors.success),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _editBill,
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Bill'),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Even Split'),
                      selected: _mode == SplitMode.even,
                      onSelected: (_) => _setMode(SplitMode.even),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Manual'),
                      selected: _mode == SplitMode.manual,
                      onSelected: (_) => _setMode(SplitMode.manual),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_mode == SplitMode.even)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _fillEvenSplit,
                    child: const Text('Rebalance Evenly'),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                'Split Amount',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final person = members[index];
                  final edited = _editedPersonIds.contains(person.id);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(child: Text(person.name)),
                              if (edited)
                                const Padding(
                                  padding: EdgeInsets.only(left: 6),
                                  child: Icon(Icons.edit, size: 16),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 128,
                          child: TextField(
                            controller: _controllers[person.id],
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                              prefixText:
                                  '${CurrencyUtils.symbol(event.currencyCode)} ',
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

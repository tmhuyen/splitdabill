import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/index.dart';
import '../providers/data_providers.dart';
import '../services/index.dart';
import '../theme/app_colors.dart';
import '../utils/currency_utils.dart';
import 'add_people_screen.dart';
import 'create_bill_screen.dart';
import 'edit_event_screen.dart';
import 'settlement_screen.dart';
import 'split_bill_screen.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;

  const EventDetailScreen({Key? key, required this.eventId}) : super(key: key);

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final _dbService = DatabaseService();
  late Event event;

  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  void _loadEvent() {
    event = _dbService.getEvent(widget.eventId)!;
    setState(() {});
  }

  Future<void> _deleteBill(Bill bill) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete bill?'),
          content: Text('Remove "${bill.title}" from this event?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    event.bills.removeWhere((item) => item.id == bill.id);
    event.updatedAt = DateTime.now();
    await _dbService.updateEvent(event);
    if (mounted) {
      context.read<EventProvider>().refreshEvents();
    }

    if (!mounted) return;
    _loadEvent();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bill deleted')),
    );
  }

  Future<void> _editEvent() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditEventScreen(eventId: widget.eventId),
      ),
    );

    if (updated == true && mounted) {
      _loadEvent();
    }
  }

  Future<void> _deleteEvent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete event?'),
          content: const Text(
            'This will delete the event, its bills, and any unused participants.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await context.read<EventProvider>().deleteEvent(widget.eventId);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(event.title),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Edit event',
            icon: const Icon(Icons.edit_outlined),
            onPressed: _editEvent,
          ),
          IconButton(
            tooltip: 'Delete event',
            icon: const Icon(Icons.delete_outline),
            onPressed: _deleteEvent,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event summary
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Amount',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            CurrencyUtils.formatAmount(
                                event.totalAmount, event.currencyCode),
                            style: Theme.of(context)
                                .textTheme
                                .displayMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${event.billCount} bills • ${event.memberCount} people',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Quick actions
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AddPeopleScreen(eventId: widget.eventId),
                          ),
                        ).then((_) => _loadEvent());
                      },
                      icon: const Icon(Icons.person_add),
                      label: const Text('Add People'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (event.memberCount == 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'You cannot add a bill before adding people.'),
                            ),
                          );
                          return;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CreateBillScreen(eventId: widget.eventId),
                          ),
                        ).then((_) => _loadEvent());
                      },
                      icon: const Icon(Icons.receipt),
                      label: const Text('Add Bill'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _editEvent,
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Event'),
                ),
              ),
              const SizedBox(height: 20),

              // Bills section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Bills',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (event.bills.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      'No bills yet',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: event.bills.length,
                  itemBuilder: (context, index) {
                    final bill = event.bills[index];
                    return BillTile(
                      bill: bill,
                      currencyCode: event.currencyCode,
                      onDelete: () => _deleteBill(bill),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SplitBillScreen(
                              eventId: widget.eventId,
                              billId: bill.id,
                            ),
                          ),
                        ).then((_) => _loadEvent());
                      },
                    );
                  },
                ),
              const SizedBox(height: 32),

              // Settlement button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            SettlementScreen(eventId: widget.eventId),
                      ),
                    );
                  },
                  icon: const Icon(Icons.calculate),
                  label: const Text('View Settlement'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BillTile extends StatelessWidget {
  final Bill bill;
  final String currencyCode;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const BillTile({
    Key? key,
    required this.bill,
    required this.currencyCode,
    required this.onDelete,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dbService = DatabaseService();
    final payer = dbService.getPerson(bill.payerId);

    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bill.title,
                        style: Theme.of(context).textTheme.labelLarge),
                    Text(
                      '${bill.category} • Paid by ${payer?.name ?? 'Unknown'}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyUtils.formatAmount(bill.totalAmount, currencyCode),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Text(
                    '${bill.splits.length} split',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              IconButton(
                tooltip: 'Delete bill',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                color: AppColors.error,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

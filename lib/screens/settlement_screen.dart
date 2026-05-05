import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import '../models/index.dart';
import '../services/index.dart';
import '../theme/app_colors.dart';
import '../utils/currency_utils.dart';

class SettlementScreen extends StatefulWidget {
  final String eventId;

  const SettlementScreen({Key? key, required this.eventId}) : super(key: key);

  @override
  State<SettlementScreen> createState() => _SettlementScreenState();
}

class _SettlementScreenState extends State<SettlementScreen> {
  final _dbService = DatabaseService();
  late Event event;
  late List<DebtTransaction> debts;
  late Map<String, Person> peopleMap;

  @override
  void initState() {
    super.initState();
    event = _dbService.getEvent(widget.eventId)!;

    peopleMap = {};
    for (var memberId in event.memberIds) {
      final person = _dbService.getPerson(memberId);
      if (person != null) {
        peopleMap[memberId] = person;
      }
    }

    debts = DebtSimplificationService.simplifyDebts(event, peopleMap);
  }

  void _markAsPaid(int index) {
    debts.removeAt(index);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Marked as paid')),
    );
  }

  Future<void> _exportToExcel() async {
    final path = await ExcelExportService.exportEventToExcel(event, peopleMap);
    if (path != null) {
      await OpenFilex.open(path);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exported to $path'),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () => OpenFilex.open(path),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settlement'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportToExcel,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (debts.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 80,
                          color: AppColors.success,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'All settled!',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppColors.success,
                                  ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settlement Plan',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: debts.length,
                      itemBuilder: (context, index) {
                        final debt = debts[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${debt.fromName} → ${debt.toName}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge,
                                      ),
                                      Text(
                                        CurrencyUtils.formatAmount(
                                            debt.amount, event.currencyCode),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.check),
                                  onPressed: () => _markAsPaid(index),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

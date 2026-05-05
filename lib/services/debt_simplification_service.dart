import '../models/index.dart';

class DebtSimplificationService {
  /// Simplify debts to minimal transactions
  static List<DebtTransaction> simplifyDebts(
    Event event,
    Map<String, Person> peopleMap,
  ) {
    // Calculate net balance for each person
    final balances = _calculateNetBalances(event);

    // Separate debtors and creditors
    final debtors = <String, double>{};
    final creditors = <String, double>{};

    for (var entry in balances.entries) {
      if (entry.value < 0) {
        debtors[entry.key] = entry.value.abs();
      } else if (entry.value > 0) {
        creditors[entry.key] = entry.value;
      }
    }

    // Match debtors with creditors
    final transactions = <DebtTransaction>[];
    final debtorsList = debtors.entries.toList();
    final creditorsList = creditors.entries.toList();

    int debtorIdx = 0;
    int creditorIdx = 0;

    while (
        debtorIdx < debtorsList.length && creditorIdx < creditorsList.length) {
      final debtor = debtorsList[debtorIdx];
      final creditor = creditorsList[creditorIdx];

      final amount =
          (debtor.value < creditor.value) ? debtor.value : creditor.value;

      transactions.add(
        DebtTransaction(
          from: debtor.key,
          to: creditor.key,
          amount: amount,
          fromName: peopleMap[debtor.key]?.name ?? debtor.key,
          toName: peopleMap[creditor.key]?.name ?? creditor.key,
        ),
      );

      debtors[debtor.key] = debtor.value - amount;
      creditors[creditor.key] = creditor.value - amount;

      if (debtors[debtor.key]! <= 0.01) debtorIdx++;
      if (creditors[creditor.key]! <= 0.01) creditorIdx++;
    }

    return transactions;
  }

  /// Calculate net balance per person
  static Map<String, double> _calculateNetBalances(Event event) {
    final balances = <String, double>{};

    // Initialize all members
    for (var memberId in event.memberIds) {
      balances[memberId] = 0;
    }

    // Process all bills
    for (var bill in event.bills) {
      // Payer receives money
      balances[bill.payerId] = (balances[bill.payerId] ?? 0) + bill.totalAmount;

      // Each person owes their split
      for (var split in bill.splits) {
        if (split.personId != bill.payerId) {
          balances[split.personId] =
              (balances[split.personId] ?? 0) - split.amount;
        }
      }
    }

    return balances;
  }
}

class DebtTransaction {
  final String from;
  final String to;
  final double amount;
  final String fromName;
  final String toName;

  DebtTransaction({
    required this.from,
    required this.to,
    required this.amount,
    required this.fromName,
    required this.toName,
  });

  @override
  String toString() => '$fromName owes $toName \$$amount';
}

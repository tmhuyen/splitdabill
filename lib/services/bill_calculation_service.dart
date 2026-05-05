import '../models/index.dart';

class BillCalculationService {
  /// Calculate even split
  static Map<String, double> calculateEvenSplit(
    double totalAmount,
    List<String> personIds,
  ) {
    if (personIds.isEmpty) return {};

    final amountPerPerson = totalAmount / personIds.length;
    return {
      for (var id in personIds) id: amountPerPerson,
    };
  }

  /// Calculate split from custom amounts
  static Map<String, double> calculateCustomSplit(
    List<SplitEntry> splits,
  ) {
    return {
      for (var split in splits) split.personId: split.amount,
    };
  }

  /// Build split entries from a person->amount map.
  static List<SplitEntry> buildSplitEntriesFromAmounts(
    Map<String, double> amounts, {
    double epsilon = 0.01,
  }) {
    return amounts.entries
        .where((entry) => entry.value > epsilon)
        .map(
          (entry) => SplitEntry(
            personId: entry.key,
            amount: entry.value,
          ),
        )
        .toList();
  }

  /// Rebuild bill splits as an even split for the supplied members.
  static List<SplitEntry> rebuildBillSplits(
    double totalAmount,
    List<String> memberIds,
  ) {
    final splitAmounts = calculateEvenSplit(totalAmount, memberIds);
    return buildSplitEntriesFromAmounts(splitAmounts);
  }

  /// Rebalance an even split so that unedited participants share the remainder.
  static Map<String, double> rebalanceEvenSplit({
    required double totalAmount,
    required List<String> personIds,
    required Map<String, double> currentAmounts,
    required Set<String> editedPersonIds,
    double epsilon = 0.01,
  }) {
    final updatedAmounts = <String, double>{
      for (final personId in personIds) personId: currentAmounts[personId] ?? 0,
    };

    if (personIds.isEmpty) return updatedAmounts;

    final remainingPeople = personIds
        .where((personId) => !editedPersonIds.contains(personId))
        .toList();

    final assignedTotal =
        updatedAmounts.values.fold(0.0, (sum, value) => sum + value);
    final remainingAmount = totalAmount - assignedTotal;

    if (remainingPeople.isEmpty || remainingAmount.abs() <= epsilon) {
      return updatedAmounts;
    }

    final share = remainingAmount / remainingPeople.length;
    for (final personId in remainingPeople) {
      updatedAmounts[personId] = share < 0 ? 0 : share;
    }

    return updatedAmounts;
  }

  /// Get remaining amount after splits
  static double getRemainingAmount(
    double totalAmount,
    List<SplitEntry> splits,
  ) {
    final totalSplit = splits.fold(0.0, (sum, split) => sum + split.amount);
    return totalAmount - totalSplit;
  }

  /// Calculate who owes what to the payer
  static Map<String, double> calculateDebts(
    Bill bill,
    Map<String, Person> peopleMap,
  ) {
    final debts = <String, double>{};

    for (var split in bill.splits) {
      if (split.personId != bill.payerId) {
        debts[split.personId] = split.amount;
      }
    }

    return debts;
  }

  /// Get bill summary for event
  static BillSummary getBillSummary(Event event) {
    double totalSpent = 0;
    final personSpending = <String, double>{};
    final personOwing = <String, double>{};

    for (var bill in event.bills) {
      totalSpent += bill.totalAmount;

      // Person paid this amount
      personSpending[bill.payerId] =
          (personSpending[bill.payerId] ?? 0) + bill.totalAmount;

      // Calculate who owes what
      for (var split in bill.splits) {
        if (split.personId != bill.payerId) {
          personOwing[split.personId] =
              (personOwing[split.personId] ?? 0) + split.amount;
        }
      }
    }

    return BillSummary(
      totalSpent: totalSpent,
      personSpending: personSpending,
      personOwing: personOwing,
    );
  }
}

class BillSummary {
  final double totalSpent;
  final Map<String, double> personSpending;
  final Map<String, double> personOwing;

  BillSummary({
    required this.totalSpent,
    required this.personSpending,
    required this.personOwing,
  });
}

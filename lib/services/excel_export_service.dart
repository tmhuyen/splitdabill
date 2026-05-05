import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import '../models/index.dart';
import 'debt_simplification_service.dart';
import '../utils/currency_utils.dart';
import 'excel_save_helper_stub.dart'
    if (dart.library.io) 'excel_save_helper_io.dart'
    if (dart.library.html) 'excel_save_helper_web.dart';

class ExcelExportService {
  /// Export event to Excel file
  static Future<String?> exportEventToExcel(
    Event event,
    Map<String, Person> peopleMap,
  ) async {
    try {
      final excel = Excel.createExcel();
      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      // Create sheets
      _createEventSummarySheet(excel, event, peopleMap);
      _createBillsSheet(excel, event, peopleMap);
      _createDebtsSheet(excel, event, peopleMap);

      // Save file
      final safeTitle = event.title.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = '${safeTitle}_$timestamp.xlsx';
      final bytes = excel.encode();
      if (bytes == null) return null;

      return saveExcelBytes(bytes, fileName);
    } catch (e) {
      return null;
    }
  }

  static void _createEventSummarySheet(
    Excel excel,
    Event event,
    Map<String, Person> peopleMap,
  ) {
    final sheet = excel['Summary'];

    // Headers
    sheet.appendRow(['Event Summary']);
    sheet.appendRow(['Event Name', event.title]);
    sheet.appendRow(['Description', event.description]);
    sheet.appendRow(['Date', event.createdAt.toString().split(' ')[0]]);
    sheet.appendRow(['']);
    sheet.appendRow([
      'Total Amount',
      CurrencyUtils.formatAmount(event.totalAmount, event.currencyCode)
    ]);
    sheet.appendRow(['Bills Count', event.billCount.toString()]);
    sheet.appendRow(['Members', event.memberCount.toString()]);
  }

  static void _createBillsSheet(
    Excel excel,
    Event event,
    Map<String, Person> peopleMap,
  ) {
    final sheet = excel['Bills'];

    // Headers
    final memberNames = event.memberIds.map((memberId) {
      final person = peopleMap[memberId];
      return person?.name.isNotEmpty == true ? person!.name : memberId;
    }).toList();

    sheet.appendRow([
      'Bill',
      'Amount',
      'Paid By',
      'Date',
      'Total Split',
      'Remaining',
      ...memberNames,
    ]);

    // Bills
    for (var bill in event.bills) {
      final payerName = peopleMap[bill.payerId]?.name ?? 'Unknown';
      final splitByMember = <String, double>{
        for (final split in bill.splits) split.personId: split.amount,
      };

      sheet.appendRow([
        bill.title,
        CurrencyUtils.formatAmount(bill.totalAmount, event.currencyCode),
        payerName,
        bill.date.toString().split(' ')[0],
        CurrencyUtils.formatAmount(bill.totalSplit, event.currencyCode),
        CurrencyUtils.formatAmount(bill.remaining, event.currencyCode),
        ...event.memberIds.map((memberId) {
          final amount = splitByMember[memberId];
          if (amount == null || amount == 0) return '';
          return CurrencyUtils.formatAmount(amount, event.currencyCode);
        }),
      ]);
    }
  }

  static void _createDebtsSheet(
    Excel excel,
    Event event,
    Map<String, Person> peopleMap,
  ) {
    final sheet = excel['Settlement'];

    // Headers
    sheet.appendRow(['Who Pays', 'To Whom', 'Amount']);

    // Debts
    final debts = DebtSimplificationService.simplifyDebts(event, peopleMap);
    for (var debt in debts) {
      sheet.appendRow([
        debt.fromName,
        debt.toName,
        CurrencyUtils.formatAmount(debt.amount, event.currencyCode),
      ]);
    }
  }
}

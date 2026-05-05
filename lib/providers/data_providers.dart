import 'package:flutter/material.dart';
import '../models/index.dart';
import '../services/database_service.dart';

class PeopleProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  List<Person> _people = [];

  List<Person> get people => _people;

  void loadPeople() {
    _people = _dbService.getAllPeople();
    notifyListeners();
  }

  void addPerson(Person person) {
    _dbService.addPerson(person);
    loadPeople();
  }

  void removePerson(String id) {
    _dbService.deletePerson(id);
    loadPeople();
  }

  void updatePerson(Person person) {
    _dbService.updatePerson(person);
    loadPeople();
  }

  Person? getPerson(String id) => _dbService.getPerson(id);
}

class BillProvider extends ChangeNotifier {
  List<Bill> _bills = [];

  List<Bill> get bills => _bills;

  void loadBillsForEvent(Event event) {
    _bills = List<Bill>.from(event.bills);
    notifyListeners();
  }

  Future<void> addBillToEvent(Event event, Bill bill) async {
    event.bills.add(bill);
    event.updatedAt = DateTime.now();
    await DatabaseService().updateEvent(event);
    loadBillsForEvent(event);
  }

  Future<void> updateBillInEvent(Event event, Bill bill) async {
    final index = event.bills.indexWhere((item) => item.id == bill.id);
    if (index == -1) return;

    event.bills[index] = bill;
    event.updatedAt = DateTime.now();
    await DatabaseService().updateEvent(event);
    loadBillsForEvent(event);
  }

  Future<void> removeBillFromEvent(Event event, String billId) async {
    event.bills.removeWhere((b) => b.id == billId);
    event.updatedAt = DateTime.now();
    await DatabaseService().updateEvent(event);
    loadBillsForEvent(event);
  }

  Future<void> deleteBillFromEvent(Event event, String billId) async {
    await removeBillFromEvent(event, billId);
  }
}

class TransactionProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  List<Transaction> _transactions = [];

  List<Transaction> get transactions => _transactions;

  void loadTransactions() {
    _transactions = _dbService.getAllTransactions();
    notifyListeners();
  }

  void addTransaction(Transaction transaction) {
    _dbService.addTransaction(transaction);
    loadTransactions();
  }

  void markAsPaid(String transactionId) {
    final transaction = _dbService.getTransaction(transactionId);
    if (transaction != null) {
      transaction.isPaid = true;
      _dbService.updateTransaction(transaction);
      loadTransactions();
    }
  }
}

class EventProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  List<Event> _events = [];

  EventProvider() {
    refreshEvents();
  }

  List<Event> get events => _events;

  void _loadEvents() {
    _events = _dbService.getAllEvents();
    notifyListeners();
  }

  Future<void> addEvent(Event event) async {
    await _dbService.createEvent(event);
    _loadEvents();
  }

  Future<void> updateEvent(Event event) async {
    await _dbService.updateEvent(event);
    _loadEvents();
  }

  Future<void> deleteEvent(String eventId) async {
    await _dbService.deleteEventCascade(eventId);
    _loadEvents();
  }

  void refreshEvents() {
    _loadEvents();
  }
}

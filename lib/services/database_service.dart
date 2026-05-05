import 'package:hive_flutter/hive_flutter.dart';
import '../models/index.dart';

class DatabaseService {
  late Box<Event> _eventsBox;
  late Box<Person> _peopleBox;
  late Box<Transaction> _transactionsBox;

  DatabaseService() {
    _eventsBox = Hive.box<Event>('events');
    _peopleBox = Hive.box<Person>('people');
    _transactionsBox = Hive.box<Transaction>('transactions');
  }

  // Events
  Future<void> createEvent(Event event) async {
    await _eventsBox.put(event.id, event);
  }

  Event? getEvent(String id) => _eventsBox.get(id);

  List<Event> getAllEvents() => _eventsBox.values.toList();

  Future<void> updateEvent(Event event) async {
    await event.save();
  }

  Future<void> deleteEvent(String id) async {
    await _eventsBox.delete(id);
  }

  Future<void> deleteEventCascade(String id) async {
    final event = _eventsBox.get(id);
    if (event == null) return;

    final relatedPersonIds = event.memberIds.toSet();
    await _eventsBox.delete(id);

    for (final personId in relatedPersonIds) {
      final stillUsed = _eventsBox.values.any(
        (otherEvent) => otherEvent.memberIds.contains(personId),
      );
      if (!stillUsed) {
        await _peopleBox.delete(personId);
      }
    }
  }

  // People
  Future<void> addPerson(Person person) async {
    await _peopleBox.put(person.id, person);
  }

  Person? getPerson(String id) => _peopleBox.get(id);

  List<Person> getAllPeople() => _peopleBox.values.toList();

  Future<void> updatePerson(Person person) async {
    await person.save();
  }

  Future<void> deletePerson(String id) async {
    await _peopleBox.delete(id);
  }

  Future<void> removePersonFromAllEvents(String personId) async {
    for (final event in _eventsBox.values) {
      if (!event.memberIds.contains(personId)) continue;

      event.memberIds.remove(personId);
      for (final bill in event.bills) {
        bill.splits.removeWhere((split) => split.personId == personId);
      }
      event.updatedAt = DateTime.now();
      await event.save();
    }
  }

  // Transactions
  Future<void> addTransaction(Transaction transaction) async {
    await _transactionsBox.put(transaction.id, transaction);
  }

  Transaction? getTransaction(String id) => _transactionsBox.get(id);

  List<Transaction> getAllTransactions() => _transactionsBox.values.toList();

  List<Transaction> getEventTransactions(String eventId) {
    // Transactions are global; filter by event manually
    return _transactionsBox.values.toList();
  }

  Future<void> updateTransaction(Transaction transaction) async {
    await transaction.save();
  }

  Future<void> deleteTransaction(String id) async {
    await _transactionsBox.delete(id);
  }

  // Clear all
  Future<void> clearAll() async {
    await _eventsBox.clear();
    await _peopleBox.clear();
    await _transactionsBox.clear();
  }
}

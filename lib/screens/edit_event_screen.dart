import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/index.dart';
import '../providers/data_providers.dart';
import '../services/index.dart';

class EditEventScreen extends StatefulWidget {
  final String eventId;

  const EditEventScreen({super.key, required this.eventId});

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final _dbService = DatabaseService();
  final _titleController = TextEditingController();
  final _newMemberNameController = TextEditingController();
  final _newMemberEmailController = TextEditingController();
  final Map<String, TextEditingController> _nameControllers = {};
  final Map<String, TextEditingController> _emailControllers = {};
  final List<Person> _pendingMembers = [];
  final Set<String> _removedMemberIds = {};

  late Event event;
  List<Person> members = [];

  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  void _loadEvent() {
    event = _dbService.getEvent(widget.eventId)!;
    _titleController.text = event.title;
    members = event.memberIds
        .map((id) => _dbService.getPerson(id))
        .whereType<Person>()
        .toList();

    for (final controller in _nameControllers.values) {
      controller.dispose();
    }
    for (final controller in _emailControllers.values) {
      controller.dispose();
    }
    _nameControllers.clear();
    _emailControllers.clear();

    for (final member in members) {
      _nameControllers[member.id] = TextEditingController(text: member.name);
      _emailControllers[member.id] = TextEditingController(text: member.email);
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _newMemberNameController.dispose();
    _newMemberEmailController.dispose();
    for (final controller in _nameControllers.values) {
      controller.dispose();
    }
    for (final controller in _emailControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addPendingMember() {
    final name = _newMemberNameController.text.trim();
    final email = _newMemberEmailController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a participant name')),
      );
      return;
    }

    final member = Person(
      id: const Uuid().v4(),
      name: name,
      email: email,
    );

    setState(() {
      _pendingMembers.add(member);
      _newMemberNameController.clear();
      _newMemberEmailController.clear();
    });
  }

  void _removeExistingMember(String personId) {
    setState(() {
      _removedMemberIds.add(personId);
      members.removeWhere((member) => member.id == personId);
    });
  }

  void _removePendingMember(String personId) {
    setState(() {
      _pendingMembers.removeWhere((member) => member.id == personId);
    });
  }

  bool _personUsedElsewhere(String personId) {
    return _dbService.getAllEvents().any(
          (otherEvent) =>
              otherEvent.id != event.id &&
              otherEvent.memberIds.contains(personId),
        );
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter an event name')),
      );
      return;
    }

    event.title = title;
    event.updatedAt = DateTime.now();

    final updatedMemberIds = <String>[];

    for (final member in members) {
      final name = _nameControllers[member.id]?.text.trim() ?? member.name;
      final email = _emailControllers[member.id]?.text.trim() ?? member.email;

      member.name = name.isEmpty ? member.name : name;
      member.email = email;
      await _dbService.updatePerson(member);
      updatedMemberIds.add(member.id);
    }

    for (final pendingMember in _pendingMembers) {
      await _dbService.addPerson(pendingMember);
      updatedMemberIds.add(pendingMember.id);
    }

    event.memberIds = updatedMemberIds;

    for (final bill in event.bills) {
      bill.splits = BillCalculationService.rebuildBillSplits(
        bill.totalAmount,
        event.memberIds,
      );
    }

    await _dbService.updateEvent(event);

    for (final removedId in _removedMemberIds) {
      if (!_personUsedElsewhere(removedId)) {
        await _dbService.deletePerson(removedId);
      }
    }

    if (!mounted) return;
    context.read<EventProvider>().refreshEvents();
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Event')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Event details',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Event name'),
              ),
              const SizedBox(height: 24),
              Text(
                'Rename participants',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 12),
              if (members.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('No participants yet.'),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final member = members[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            TextField(
                              controller: _nameControllers[member.id],
                              decoration: const InputDecoration(
                                labelText: 'Name',
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _emailControllers[member.id],
                              decoration: const InputDecoration(
                                labelText: 'Email',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () =>
                                    _removeExistingMember(member.id),
                                icon: const Icon(Icons.remove_circle_outline),
                                label: const Text('Remove'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 8),
              Text(
                'Add participant',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _newMemberNameController,
                decoration:
                    const InputDecoration(labelText: 'New participant name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _newMemberEmailController,
                decoration:
                    const InputDecoration(labelText: 'New participant email'),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _addPendingMember,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add participant'),
                ),
              ),
              if (_pendingMembers.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Pending participants',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _pendingMembers.length,
                  itemBuilder: (context, index) {
                    final member = _pendingMembers[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(member.name),
                        subtitle:
                            member.email.isEmpty ? null : Text(member.email),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _removePendingMember(member.id),
                        ),
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('Save Event'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

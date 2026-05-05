import 'package:flutter/material.dart';
import '../models/index.dart';
import '../services/index.dart';
import 'package:uuid/uuid.dart';

class AddPeopleScreen extends StatefulWidget {
  final String eventId;

  const AddPeopleScreen({Key? key, required this.eventId}) : super(key: key);

  @override
  State<AddPeopleScreen> createState() => _AddPeopleScreenState();
}

class _AddPeopleScreenState extends State<AddPeopleScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _dbService = DatabaseService();
  late Event event;
  List<Person> members = [];

  @override
  void initState() {
    super.initState();
    event = _dbService.getEvent(widget.eventId)!;
    _loadMembers();
  }

  void _loadMembers() {
    members = event.memberIds
        .map((id) => _dbService.getPerson(id))
        .whereType<Person>()
        .toList();
    setState(() {});
  }

  void _addPerson() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter name')),
      );
      return;
    }

    final person = Person(
      id: const Uuid().v4(),
      name: _nameController.text,
      email: _emailController.text,
    );

    _dbService.addPerson(person);
    event.memberIds.add(person.id);
    _dbService.updateEvent(event);

    _nameController.clear();
    _emailController.clear();
    _loadMembers();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Person added')),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Members')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add Members',
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                decoration:
                    const InputDecoration(labelText: 'Email (optional)'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _addPerson,
                  child: const Text('Add Person'),
                ),
              ),
              const SizedBox(height: 32),
              Text('Members', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final person = members[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(person.name,
                                  style:
                                      Theme.of(context).textTheme.labelLarge),
                              if (person.email.isNotEmpty)
                                Text(person.email,
                                    style:
                                        Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              event.memberIds.remove(person.id);
                              _dbService.updateEvent(event);
                              _dbService.deletePerson(person.id);
                              _loadMembers();
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

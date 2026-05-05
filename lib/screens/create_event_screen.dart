import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/index.dart';
import '../providers/data_providers.dart';
import '../utils/currency_utils.dart';
import 'package:uuid/uuid.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({Key? key}) : super(key: key);

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _currencyCode = 'USD';

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _createEvent() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter event title')),
      );
      return;
    }

    final event = Event(
      id: const Uuid().v4(),
      title: _titleController.text,
      description: _descriptionController.text,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      memberIds: [],
      bills: [],
      currencyCode: _currencyCode,
    );

    context.read<EventProvider>().addEvent(event).then((_) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event created!')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Event'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Event Details',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Event Title',
                  hintText: 'e.g., Weekend Trip',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'e.g., Vacation in Hawaii',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _currencyCode,
                decoration: const InputDecoration(
                  labelText: 'Currency',
                ),
                items: CurrencyUtils.supportedCodes
                    .map(
                      (code) => DropdownMenuItem(
                        value: code,
                        child: Text('${CurrencyUtils.symbol(code)} ($code)'),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _currencyCode = value);
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _createEvent,
                  child: const Text('Create Event'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

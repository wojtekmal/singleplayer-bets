import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../bet_model.dart';
import '../database_helper.dart';
import '../notification_service.dart';

class AddEditBetScreen extends StatefulWidget {
  final VoidCallback onSave;

  const AddEditBetScreen({Key? key, required this.onSave}) : super(key: key);

  @override
  _AddEditBetScreenState createState() => _AddEditBetScreenState();
}

class _AddEditBetScreenState extends State<AddEditBetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _probabilityController = TextEditingController();
  DateTime _resolveDate = DateTime.now().add(const Duration(days: 7));

  void _presentDatePicker() {
    showDatePicker(
      context: context,
      initialDate: _resolveDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    ).then((pickedDate) {
      if (pickedDate == null) {
        return;
      }
      setState(() {
        _resolveDate = pickedDate;
      });
    });
  }

  Future<void> _submitData() async {
    if (_formKey.currentState!.validate()) {
      final newBet = Bet(
        content: _contentController.text,
        description: _descriptionController.text,
        probability: double.parse(_probabilityController.text) / 100.0,
        createdDate: DateTime.now(),
        resolveDate: _resolveDate,
      );

      final dbHelper = DatabaseHelper();
      final id = await dbHelper.insertBet(newBet);
      
      final notificationService = NotificationService();
      await notificationService.scheduleBetNotifications(newBet.copyWith(id: id));


      widget.onSave();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Bet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _submitData,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(labelText: 'Bet Content'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the bet content.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description / Justification'),
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _probabilityController,
                decoration: const InputDecoration(labelText: 'Probability (0-100)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a probability.';
                  }
                  final n = num.tryParse(value);
                  if (n == null) {
                    return 'Please enter a valid number.';
                  }
                  if (n < 0 || n > 100) {
                    return 'Probability must be between 0 and 100.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Resolve on: ${DateFormat.yMMMd().format(_resolveDate)}',
                    ),
                  ),
                  TextButton(
                    onPressed: _presentDatePicker,
                    child: const Text('Choose Date'),
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

// Helper extension to add a copyWith method to the Bet model
extension BetCopyWith on Bet {
  Bet copyWith({int? id}) {
    return Bet(
      id: id ?? this.id,
      content: content,
      description: description,
      probability: probability,
      createdDate: createdDate,
      resolveDate: resolveDate,
      resolvedStatus: resolvedStatus,
    );
  }
}
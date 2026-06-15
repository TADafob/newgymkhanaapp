import 'package:flutter/material.dart';
import 'package:nrbgymkhana/core/utils/appcolors.dart';

class ReportIssueForm extends StatefulWidget {
  final String bookingId;
  final Function(String) onSubmit;

  const ReportIssueForm({
    super.key,
    required this.bookingId,
    required this.onSubmit,
  });

  @override
  State<ReportIssueForm> createState() => _ReportIssueFormState();
}

class _ReportIssueFormState extends State<ReportIssueForm> {
  final _formKey = GlobalKey<FormState>();
  late String _subject;
  late String _description;
  String _priority = 'Medium';


  final List<String> _priorities = ['Low', 'Medium', 'High', 'Urgent'];
  

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final String subject = 'Booking issue,  Booking Id: ${widget.bookingId}';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
      ),
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Report Issue',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: Navigator.of(context).pop,
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Priority selector
                Row(
                  children: [
                    Text(
                      'Priority: ',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _priority,
                      onChanged: (value) {
                        setState(() {
                          _priority = value!;
                        });
                      },
                      items: _priorities.map((priority) {
                        return DropdownMenuItem(
                          value: priority,
                          child: Text(priority),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Subject field
                TextFormField(
                  initialValue: subject,
                  decoration: InputDecoration(
                    labelText: 'Subject',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppKolors.secondary
                      )
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a subject';
                    }
                    return null;
                  },
                  onSaved: (value) => _subject = value!,
                ),
                
                const SizedBox(height: 16),
                
                // Description field
                TextFormField(
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please describe the issue';
                    }
                    return null;
                  },
                  onSaved: (value) => _description = value!,
                ),
                
                const SizedBox(height: 24),
                
                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        widget.onSubmit('$_priority: $_subject - $_description');
                        Navigator.of(context).pop();
                      }
                    },
                    icon: const Icon(Icons.send_rounded, color: AppKolors.blackness),
                    label: const Text('Submit Report', style: TextStyle(color: AppKolors.blackness),),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
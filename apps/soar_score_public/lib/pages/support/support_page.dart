import 'package:flutter/material.dart';

/// Support request form (`/support`, plan/ui/public-site/support.md).
class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  static const String title = 'Support';

  static const List<String> userTypes = [
    'Contest Director',
    'Pilot',
    'Participant',
  ];

  static const Map<String, String> requestTypes = {
    'Public site issue': 'Contests not displaying, site errors, etc.',
    'Contest Management': 'Questions about running contests, admin, etc.',
    'Online Score Entry':
        'Trouble entering scores or questions about online scoring.',
    'Feature Request':
        'New features are always coming. Help shape the application!',
    'User Account Inquiry': 'Trouble registering, accessing the site, etc.',
    'General Inquiry':
        "Questions or comments that don't fall into another category.",
    'Emergency Contest Issue':
        'A critical issue around running a contest or entering scores.',
  };

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  final _formKey = GlobalKey<FormState>();
  String? _userType;
  String? _requestType;
  bool _submitted = false;

  String? _required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Required' : null;

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    // TODO(#220): send the request to the support channel; no captcha yet.
    setState(() => _submitted = true);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return _submitted
        ? const Center(
            child: Text('Thank you. Your support request has been received.'),
          )
        : Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(SupportPage.title, style: text.headlineSmall),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: _required,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: _required,
                ),
                DropdownButtonFormField<String>(
                  initialValue: _userType,
                  decoration: const InputDecoration(labelText: 'User type'),
                  items: [
                    for (final type in SupportPage.userTypes)
                      DropdownMenuItem(value: type, child: Text(type)),
                  ],
                  onChanged: (value) => _userType = value,
                ),
                DropdownButtonFormField<String>(
                  initialValue: _requestType,
                  decoration: const InputDecoration(labelText: 'Request type'),
                  isExpanded: true,
                  items: [
                    for (final entry in SupportPage.requestTypes.entries)
                      DropdownMenuItem(
                        value: entry.key,
                        child: Text('${entry.key} - ${entry.value}'),
                      ),
                  ],
                  validator: _required,
                  onChanged: (value) => _requestType = value,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Message'),
                  maxLength: 2000,
                  maxLines: 6,
                  validator: _required,
                ),
                FilledButton(onPressed: _submit, child: const Text('Submit')),
              ],
            ),
          );
  }
}

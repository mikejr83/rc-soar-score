import 'package:flutter/material.dart';

import 'docs_placeholder_page.dart';

/// User account help (`/docs/user-accounts`).
class UserAccountsPage extends StatelessWidget {
  const UserAccountsPage({super.key});

  static const String title = 'User Accounts';

  @override
  Widget build(BuildContext context) {
    return const DocsPlaceholderPage(
      title: title,
      sections: ['Do I need an account?', 'Registering and signing in'],
    );
  }
}

import 'package:flutter/material.dart';

/// How the entry points to the New Contest wizard read: `Create contest`
/// until a draft is underway, then `Continue configuration`.
abstract final class CreateContestEntry {
  static String label(bool hasDraft) =>
      hasDraft ? 'Continue configuration' : 'Create contest';

  static IconData icon(bool hasDraft) => hasDraft ? Icons.edit_note : Icons.add;
}

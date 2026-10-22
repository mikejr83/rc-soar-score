import 'package:flutter/material.dart';

/// A titled group of fields: an elevated card on wide screens, a plain headed
/// group on phones and at large text sizes.
class EditorSectionCard extends StatelessWidget {
  const EditorSectionCard({
    required this.title,
    required this.child,
    this.optional = false,
    this.plain = false,
    super.key,
  });

  final String title;
  final Widget child;

  /// Marks the section as one the director may leave empty.
  final bool optional;

  /// Draw a headed group without the card.
  final bool plain;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final heading = Semantics(
      header: true,
      child: Text.rich(
        TextSpan(
          text: title,
          children: [
            if (optional)
              TextSpan(
                text: '  Optional',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        style: theme.textTheme.titleLarge,
      ),
    );
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [heading, const SizedBox(height: 16), child],
    );
    if (plain) {
      return Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        padding: const EdgeInsets.only(top: 16),
        child: content,
      );
    }
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(padding: const EdgeInsets.all(20), child: content),
    );
  }
}

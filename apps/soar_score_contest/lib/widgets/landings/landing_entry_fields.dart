import 'package:flutter/material.dart';

/// The text controllers of one entry row in the landing table form.
class LandingEntryFields {
  LandingEntryFields({String key = '', String label = '', String points = ''})
    : key = TextEditingController(text: key),
      label = TextEditingController(text: label),
      points = TextEditingController(text: points);

  final TextEditingController key;
  final TextEditingController label;
  final TextEditingController points;

  void dispose() {
    key.dispose();
    label.dispose();
    points.dispose();
  }
}

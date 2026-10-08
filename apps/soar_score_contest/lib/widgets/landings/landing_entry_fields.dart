import 'package:flutter/material.dart';

/// The text controllers of one entry row in the landing table form.
class LandingEntryFields {
  LandingEntryFields({String label = '', String points = ''})
    : label = TextEditingController(text: label),
      points = TextEditingController(text: points);

  final TextEditingController label;
  final TextEditingController points;

  void dispose() {
    label.dispose();
    points.dispose();
  }
}

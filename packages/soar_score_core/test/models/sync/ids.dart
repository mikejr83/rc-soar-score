import 'package:soar_score_core/soar_score_core.dart';

/// An identifier shaped like the examples: `019c0000-0000-7000-8000-…NN`.
Id exampleId(int n) =>
    Id.parse('019c0000-0000-7000-8000-${n.toRadixString(16).padLeft(12, '0')}');

final DateTime t0 = DateTime.utc(2026, 10, 17, 15, 10);

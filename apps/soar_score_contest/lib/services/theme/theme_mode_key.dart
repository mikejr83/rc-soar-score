import 'package:flutter/material.dart';
import 'package:soar_score_ui_storage/soar_score_ui_storage.dart';

/// The chosen theme: light, dark, or follow the device (the default).
final LocalUiKey<ThemeMode> themeModeKey = LocalUiKey<ThemeMode>(
  name: 'theme_mode',
  defaultValue: ThemeMode.system,
  encode: (mode) => mode.name,
  decode: (data) => ThemeMode.values.byName(data as String),
);

import 'package:flutter/widgets.dart';
import 'package:soar_score_api/soar_score_api.dart';

/// Provides [ApiClient] to the widget subtree via InheritedWidget.
class ApiClientInherited extends InheritedWidget {
  const ApiClientInherited({
    super.key,
    required this.client,
    required super.child,
  });

  final ApiClient client;

  @override
  bool updateShouldNotify(ApiClientInherited oldWidget) =>
      client != oldWidget.client;
}

extension ApiClientContext on BuildContext {
  /// Look up the [ApiClient] from the nearest [ApiClientInherited].
  ApiClient get apiClient {
    final inherited = dependOnInheritedWidgetOfExactType<ApiClientInherited>();
    assert(inherited != null, 'ApiClientInherited not found in widget tree');
    return inherited!.client;
  }
}

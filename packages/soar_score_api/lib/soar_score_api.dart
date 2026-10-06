/// Soar Score API client: shared HTTP transport, JSON DTOs, and typed API
/// errors (pure Dart).
///
/// This library is the public API of the package; consumers should import
/// only `package:soar_score_api/soar_score_api.dart`.
library;

export 'client/api_client.dart';
export 'dto/contest_list_dto.dart';
export 'dto/health_dto.dart';
export 'errors/api_exception.dart';
export 'errors/api_http_error.dart';
export 'errors/api_network_error.dart';

/// Soar Score API client: shared HTTP transport, JSON DTOs, and typed API
/// errors (pure Dart).
///
/// This library is the public API of the package; consumers should import
/// only `package:soar_score_api/soar_score_api.dart`.
library;

export 'client/api_client.dart';
export 'dto/add_participation_request.dart';
export 'dto/add_team_member_request.dart';
export 'dto/api_error_dto.dart';
export 'dto/contest_action_request.dart';
export 'dto/create_contest_request.dart';
export 'dto/create_landing_table_request.dart';
export 'dto/create_participant_request.dart';
export 'dto/create_role_request.dart';
export 'dto/create_team_request.dart';
export 'dto/draw_matrix_request.dart';
export 'dto/enter_score_request.dart';
export 'dto/health_dto.dart';
export 'dto/late_add_request.dart';
export 'dto/move_assignment_request.dart';
export 'dto/redraw_matrix_request.dart';
export 'dto/rename_role_request.dart';
export 'dto/save_configuration_request.dart';
export 'dto/update_contest_request.dart';
export 'dto/update_participant_request.dart';
export 'dto/update_participation_request.dart';
export 'dto/update_team_request.dart';
export 'errors/api_exception.dart';
export 'errors/api_http_error.dart';
export 'errors/api_network_error.dart';

export 'package:soar_score_core/services/calculated_flight.dart';
export 'package:soar_score_core/services/contest_results.dart';
export 'package:soar_score_core/services/contest_scores.dart';
export 'package:soar_score_core/services/landing_entry_input.dart';
export 'package:soar_score_core/services/landing_table_view.dart';
export 'package:soar_score_core/services/round_flight_result.dart';
export 'package:soar_score_core/services/round_results.dart';
export 'package:soar_score_core/services/score_entry_result.dart';

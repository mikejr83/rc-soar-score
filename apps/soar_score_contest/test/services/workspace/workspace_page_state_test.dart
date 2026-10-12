import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/services/workspace/workspace_page_state.dart';

import '../../support/matrix_test_support.dart';

ApiHttpError _http(int status) => ApiHttpError(
  'failed',
  statusCode: status,
  body: '',
  requestUri: Uri.parse('http://localhost/x'),
);

void main() {
  test('neither loaded nor failed is loading', () {
    expect(WorkspacePageState.of(idValid: true), const WorkspaceLoading());
  });

  test('an id that does not parse is not found, whatever else is known', () {
    expect(
      WorkspacePageState.of(idValid: false, error: _http(500)),
      const WorkspaceNotFound(),
    );
  });

  test('a 404 is not found', () {
    expect(
      WorkspacePageState.of(idValid: true, error: _http(404)),
      const WorkspaceNotFound(),
    );
  });

  test('every other failure is a load failure', () {
    final server = _http(500);
    expect(
      WorkspacePageState.of(idValid: true, error: server),
      WorkspaceLoadFailed(server),
    );
    final network = ApiNetworkError(
      'down',
      requestUri: Uri.parse('http://localhost/x'),
    );
    expect(
      WorkspacePageState.of(idValid: true, error: network),
      WorkspaceLoadFailed(network),
    );
    final other = StateError('No API client is available.');
    expect(
      WorkspacePageState.of(idValid: true, error: other),
      WorkspaceLoadFailed(other),
    );
  });

  test('a loaded contest wins over a failed reload', () {
    expect(
      WorkspacePageState.of(
        idValid: true,
        contest: matrixContest(),
        error: _http(500),
      ),
      const WorkspaceReady(),
    );
  });

  test('a stale change is carried on the ready state', () {
    final state = WorkspacePageState.of(
      idValid: true,
      contest: matrixContest(),
      stale: true,
    );
    expect(state, const WorkspaceReady(stale: true));
    expect((state as WorkspaceReady).unavailable, isFalse);
  });

  test('no local copy is ever produced yet', () {
    expect(const WorkspaceReady().unavailable, isFalse);
    expect(WorkspaceReady(localCopyAt: DateTime.utc(2026)).unavailable, isTrue);
  });
}

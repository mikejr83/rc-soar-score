import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'handler_test_support.dart';

final _account = Id.parse('019c0000-0000-7000-8000-000000000001');
final _id = Id.parse('019c0000-0000-7000-8000-00000000c101');

/// The harness has no invitation secret and a repository without link tables,
/// like the embedded instance on a Windows installation.
void main() {
  late HandlerHarness api;

  setUp(() => api = HandlerHarness(_account));

  for (final (method, path) in [
    ('GET', '/account/participations'),
    ('GET', '/account/link-candidates'),
    ('POST', '/account/link-candidates/${_id.value}/confirm'),
    ('POST', '/account/link-candidates/${_id.value}/decline'),
    ('GET', '/account/links'),
    ('POST', '/account/links/${_id.value}/end'),
  ]) {
    test('$method $path answers 409 backend_only on an installation', () async {
      final response = await api.send(method, path);

      expect(response.statusCode, 409);
      expect((await api.errorOf(response))['code'], 'backend_only');
    });
  }
}

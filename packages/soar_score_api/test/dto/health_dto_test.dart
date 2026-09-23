import 'package:soar_score_api/soar_score_api.dart';
import 'package:test/test.dart';

void main() {
  group('HealthDto', () {
    test('fromJson decodes the server health payload shape', () {
      final json = <String, dynamic>{
        'name': 'soar_score_server',
        'displayName': 'Soar Score API Server',
        'version': '0.1.0',
      };

      final health = HealthDto.fromJson(json);

      expect(health.name, 'soar_score_server');
      expect(health.displayName, 'Soar Score API Server');
      expect(health.version, '0.1.0');
    });

    test('toJson encodes back to the same shape', () {
      final health = const HealthDto(
        name: 'soar_score_server',
        displayName: 'Soar Score API Server',
        version: '0.1.0',
      );

      expect(health.toJson(), <String, dynamic>{
        'name': 'soar_score_server',
        'displayName': 'Soar Score API Server',
        'version': '0.1.0',
      });
    });

    test('fromJson/toJson round-trips an arbitrary payload', () {
      final original = const HealthDto(
        name: 'soar_score_api_handlers',
        displayName: 'Embedded Soar Score API',
        version: '9.9.9',
      );

      final copy = HealthDto.fromJson(original.toJson());

      expect(copy, original);
      expect(copy.hashCode, original.hashCode);
    });

    test('is equal to another instance with the same fields', () {
      final a = const HealthDto(name: 'a', displayName: 'A', version: '1.0.0');
      final b = const HealthDto(name: 'a', displayName: 'A', version: '1.0.0');
      final other = const HealthDto(
        name: 'b',
        displayName: 'A',
        version: '1.0.0',
      );

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a == other, isFalse);
    });
  });
}

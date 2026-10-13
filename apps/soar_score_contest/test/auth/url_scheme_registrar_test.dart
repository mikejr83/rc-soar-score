import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/auth/registry_store.dart';
import 'package:soar_score_contest/auth/url_scheme_registrar.dart';

class _FakeRegistry implements RegistryStore {
  final Map<String, String> values = {};
  int writes = 0;

  @override
  String? getString(String keyPath, String name) => values['$keyPath|$name'];

  @override
  void setString(String keyPath, String name, String value) {
    writes++;
    values['$keyPath|$name'] = value;
  }
}

const _schemeKey = r'Software\Classes\com.soarscore.contest';
const _commandKey =
    r'Software\Classes\com.soarscore.contest\shell\open\command';

UrlSchemeRegistrar _registrar(_FakeRegistry store, String exe) =>
    UrlSchemeRegistrar(
      store: store,
      scheme: 'com.soarscore.contest',
      executablePath: exe,
    );

void main() {
  const exe = r'C:\Apps\RC Soar Score\soar_score_contest.exe';

  test('registers the scheme when nothing is registered', () {
    final store = _FakeRegistry();

    expect(_registrar(store, exe).ensureRegistered(), isTrue);

    expect(store.values['$_schemeKey|URL Protocol'], '');
    expect(store.values['$_schemeKey|'], 'URL:RC Soar Score');
    expect(store.values['$_commandKey|'], '"$exe" "%1"');
  });

  test('does nothing when it already points at this executable', () {
    final store = _FakeRegistry();
    _registrar(store, exe).ensureRegistered();
    final writes = store.writes;

    expect(_registrar(store, exe).ensureRegistered(), isFalse);

    expect(store.writes, writes);
  });

  test('takes the scheme over from another copy of the app', () {
    final store = _FakeRegistry();
    _registrar(store, r'D:\old\soar_score_contest.exe').ensureRegistered();

    expect(_registrar(store, exe).ensureRegistered(), isTrue);

    expect(store.values['$_commandKey|'], '"$exe" "%1"');
  });

  test('rewrites a registration that lacks the URL Protocol marker', () {
    final store = _FakeRegistry()..values['$_commandKey|'] = '"$exe" "%1"';

    expect(_registrar(store, exe).ensureRegistered(), isTrue);

    expect(store.values['$_schemeKey|URL Protocol'], '');
  });
}

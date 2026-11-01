// Generates the third-party licence data for the public site's /open-source
// page (#687) from the lockfiles, not by hand.
//
// Run from anywhere (the script finds the repository root itself), after
// `dart pub get` (or `melos bootstrap`) so the pub cache holds the locked
// package versions, and after `npm ci` in apps/soar_score_web so
// node_modules holds the licence texts of the npm packages:
//
//   dart scripts/generate_licences.dart                  write the JSON
//   dart scripts/generate_licences.dart --check          fail if it is stale
//   dart scripts/generate_licences.dart --product contest-app \
//       --notices THIRD_PARTY_NOTICES.txt                plain-text notices
//   ... --product contest-app --json FILE                that product's data
//                                                        (bundle as an asset)
//
// With --product only that product's inputs are read: the Dart apps need the
// pub cache (`dart pub get`), only the public site needs node_modules.
//
// Wrappers: scripts/generate-licences.sh and scripts/generate-licences.ps1.
// It needs only the Dart SDK (no pub packages). Output is deterministic: no
// timestamps, sorted entries, LF line endings.
//
// Fails on any package whose licence cannot be identified. Add it to
// scripts/licence-overrides.json instead of guessing.

import 'dart:convert';
import 'dart:io';

const _outRelative = 'apps/soar_score_web/src/content/licences.json';
const _webRelative = 'apps/soar_score_web';

/// The shipped products, each with the root of its dependency graph.
const _products = <_Product>[
  _Product(
    id: 'contest-app',
    name: 'Contest administration app',
    summary:
        'The contest app for directors (web, and the Windows build with the '
        'offline database and the GliderScore import helpers).',
    dartRoot: 'soar_score_contest',
    flutter: true,
    fonts: true,
    windowsHelpers: true,
  ),
  _Product(
    id: 'self-scoring',
    name: 'Self-scoring app',
    summary: 'The participant self-scoring web app.',
    dartRoot: 'soar_score_self_score',
    flutter: true,
    fonts: true,
  ),
  _Product(
    id: 'server',
    name: 'API server',
    summary: 'The Dart server behind api.rcsoarscore.com.',
    dartRoot: 'soar_score_server',
  ),
  _Product(
    id: 'public-site',
    name: 'Public site',
    summary: 'This site (Next.js), including the published results pages.',
    npm: true,
    fonts: true,
  ),
];

class _Product {
  const _Product({
    required this.id,
    required this.name,
    required this.summary,
    this.dartRoot,
    this.flutter = false,
    this.npm = false,
    this.fonts = false,
    this.windowsHelpers = false,
  });
  final String id;
  final String name;
  final String summary;
  final String? dartRoot;
  final bool flutter;
  final bool npm;
  final bool fonts;
  final bool windowsHelpers;
}

late final Directory _root;
final _texts = <String>[];
final _textIndex = <String, int>{};

int _addText(String text) {
  final t = text.replaceAll('\r\n', '\n').trimRight();
  return _textIndex.putIfAbsent(t, () {
    _texts.add(t);
    return _texts.length - 1;
  });
}

Never _fail(String message) {
  stderr.writeln('generate_licences: $message');
  exit(1);
}

String _read(String relative) {
  final f = File('${_root.path}/$relative');
  if (!f.existsSync()) _fail('missing file $relative');
  return f.readAsStringSync();
}

String _licenceText(String name) => _read('scripts/licence-texts/$name');

/// FNV-1a (64 bit) of the LF-normalised file, as 16 hex digits. The vitest
/// staleness test recomputes the same value.
String _fingerprint(String relative) {
  final bytes = utf8.encode(_read(relative).replaceAll('\r\n', '\n'));
  var h = 0xcbf29ce484222325;
  for (final b in bytes) {
    h ^= b;
    h = (h * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
  }
  // Dart ints are signed 64 bit; print the two halves as unsigned.
  String half(int v) => (v & 0xFFFFFFFF).toRadixString(16).padLeft(8, '0');
  return '${half(h >> 32)}${half(h)}';
}

String _pubCache() {
  final env = Platform.environment;
  if (env['PUB_CACHE'] != null) return env['PUB_CACHE']!;
  if (Platform.isWindows) return '${env['LOCALAPPDATA']}\\Pub\\Cache';
  return '${env['HOME']}/.pub-cache';
}

/// Names a licence from its text, or null when it is not one we recognise.
String? _identify(String raw) {
  final t = raw.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  bool has(String s) => t.contains(s);
  if (has('apache license') && has('version 2.0')) return 'Apache-2.0';
  if (has('mozilla public license') && has('version 2.0')) return 'MPL-2.0';
  if (has('gnu lesser general public license')) {
    return has('version 3') ? 'LGPL-3.0' : 'LGPL-2.1';
  }
  if (has('gnu affero general public license')) return 'AGPL-3.0';
  if (has('gnu general public license')) {
    return has('version 3') ? 'GPL-3.0' : 'GPL-2.0';
  }
  if (has('sil open font license')) return 'OFL-1.1';
  if (has('redistribution and use in source and binary forms')) {
    return has('neither the name') ? 'BSD-3-Clause' : 'BSD-2-Clause';
  }
  if (has('permission is hereby granted, free of charge')) return 'MIT';
  if (has('permission to use, copy, modify, and/or distribute this software')) {
    return 'ISC';
  }
  if (has('free and unencumbered software released into the public domain')) {
    return 'Unlicense';
  }
  if (has(
    'permission to use, copy, modify, and/or distribute this software for any purpose',
  )) {
    return '0BSD';
  }
  return null;
}

final _licenceFileName = RegExp(
  r'^(licen[cs]e|copying|unlicense)([-_.].*)?$',
  caseSensitive: false,
);

/// All licence files at the top of [dir], sorted by name.
List<File> _licenceFiles(Directory dir) {
  if (!dir.existsSync()) return const [];
  final files =
      dir
          .listSync(followLinks: false)
          .whereType<File>()
          .where((f) => _licenceFileName.hasMatch(f.uri.pathSegments.last))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  return files;
}

String? _pubspecField(String pubspec, String field) {
  final m = RegExp(
    '^$field:\\s*(\\S.*?)\\s*\$',
    multiLine: true,
  ).firstMatch(pubspec);
  if (m == null) return null;
  var v = m.group(1)!;
  if ((v.startsWith('"') && v.endsWith('"')) ||
      (v.startsWith("'") && v.endsWith("'"))) {
    v = v.substring(1, v.length - 1);
  }
  return v.startsWith('http') ? v : null;
}

Map<String, dynamic> _overrides = {};

Map<String, dynamic> _entry({
  required String name,
  required String version,
  required String license,
  required String homepage,
  required String source,
  required List<int> texts,
  String? note,
  bool direct = false,
}) => {
  'name': name,
  'version': version,
  'license': license,
  'homepage': homepage,
  'source': source,
  if (direct) 'direct': true,
  if (note != null) 'note': note,
  'texts': texts,
};

// ---------------------------------------------------------------- Dart

Map<String, dynamic> _loadPubGraph() {
  final result = Process.runSync('dart', [
    'pub',
    'deps',
    '--json',
    '-C',
    _root.path,
  ], runInShell: Platform.isWindows);
  if (result.exitCode != 0) {
    _fail('dart pub deps failed:\n${result.stderr}');
  }
  final out = result.stdout as String;
  final start = out.indexOf('{');
  return jsonDecode(out.substring(start)) as Map<String, dynamic>;
}

List<Map<String, dynamic>> _dartEntries(
  Map<String, dynamic> graph,
  _Product product,
) {
  final byName = {
    for (final p in (graph['packages'] as List).cast<Map<String, dynamic>>())
      p['name'] as String: p,
  };
  final root = byName[product.dartRoot];
  if (root == null) _fail('no package ${product.dartRoot} in the workspace');

  // Reachable production packages: a workspace member contributes only its
  // direct (non-dev) dependencies; a hosted package lists its own.
  final seen = <String>{};
  final queue = <String>[product.dartRoot!];
  while (queue.isNotEmpty) {
    final name = queue.removeLast();
    if (!seen.add(name)) continue;
    final p = byName[name]!;
    final deps =
        (p['source'] == 'root' ? p['directDependencies'] : p['dependencies'])
            as List;
    for (final d in deps.cast<String>()) {
      if (byName.containsKey(d)) queue.add(d);
    }
  }
  final direct = <String>{
    for (final d in (root['directDependencies'] as List).cast<String>()) d,
  };

  final cache = '${_pubCache()}/hosted/pub.dev';
  final dartOverrides = (_overrides['dart'] as Map).cast<String, dynamic>();
  final entries = <Map<String, dynamic>>[];
  for (final name in seen.toList()..sort()) {
    final p = byName[name]!;
    final source = p['source'] as String;
    if (source == 'root') continue; // our own packages (AGPL-3.0)
    if (source == 'sdk') continue; // Flutter SDK, listed once
    if (source != 'hosted') _fail('$name: unsupported source "$source"');
    final version = p['version'] as String;
    final dir = Directory('$cache/$name-$version');
    if (!dir.existsSync()) {
      _fail(
        '$name $version is not in the pub cache ($cache); run dart pub get',
      );
    }
    final pubspec = File('${dir.path}/pubspec.yaml').readAsStringSync();
    final homepage =
        _pubspecField(pubspec, 'homepage') ??
        _pubspecField(pubspec, 'repository') ??
        'https://pub.dev/packages/$name';
    final override = dartOverrides[name] as Map<String, dynamic>?;
    final texts = <int>[];
    final licences = <String>[];
    if (override != null && override['textFiles'] != null) {
      for (final f in (override['textFiles'] as List).cast<String>()) {
        texts.add(_addText(_licenceText(f)));
      }
      licences.add(override['license'] as String);
    } else {
      final files = _licenceFiles(dir);
      if (files.isEmpty) {
        _fail(
          '$name $version has no licence file; add it to scripts/licence-overrides.json',
        );
      }
      for (final f in files) {
        final text = f.readAsStringSync();
        final id = override?['license'] as String? ?? _identify(text);
        if (id == null) {
          _fail(
            '$name $version: cannot identify the licence in ${f.uri.pathSegments.last}; add it to scripts/licence-overrides.json',
          );
        }
        if (!licences.contains(id)) licences.add(id);
        texts.add(_addText(text));
      }
    }
    entries.add(
      _entry(
        name: name,
        version: version,
        license: licences.join(' AND '),
        homepage: homepage,
        source: 'dart',
        texts: texts,
        direct: direct.contains(name),
      ),
    );
  }
  return entries;
}

// ----------------------------------------------------------------- npm

List<Map<String, dynamic>> _npmEntries() {
  final lock = jsonDecode(
    _read('$_webRelative/package-lock.json'),
  ) as Map<String, dynamic>;
  final packages = (lock['packages'] as Map)
      .cast<String, Map<String, dynamic>>();
  final rootDeps = <String>{
    ...((packages['']?['dependencies'] as Map?)?.keys.cast<String>() ??
        const []),
  };
  final npmOverrides = (_overrides['npm'] as Map).cast<String, dynamic>();
  final patterns = (_overrides['npmPatterns'] as Map).cast<String, dynamic>();
  final platform = (_overrides['npmSkipPlatform'] as Map)
      .cast<String, dynamic>();
  final excluded = (platform['excludeNameContains'] as List).cast<String>();
  bool applies(Map<String, dynamic> p, String name) {
    if (excluded.any(name.contains)) return false;
    for (final key in ['os', 'cpu', 'libc']) {
      final want = platform[key] as String;
      final list = (p[key] as List?)?.cast<String>();
      if (list == null) continue;
      final negated = list.where((e) => e.startsWith('!')).toList();
      if (negated.isNotEmpty) {
        if (negated.contains('!$want')) return false;
      } else if (!list.contains(want)) {
        return false;
      }
    }
    return true;
  }

  final entries = <Map<String, dynamic>>[];
  final names = <String, String>{}; // name -> key, for textFrom
  for (final e in packages.entries) {
    if (e.key.isEmpty) continue;
    final p = e.value;
    final name = e.key.substring(
      e.key.lastIndexOf('node_modules/') + 'node_modules/'.length,
    );
    if (p['dev'] == true || !applies(p, name)) continue;
    names.putIfAbsent(name, () => e.key);
  }

  for (final e in packages.entries) {
    if (e.key.isEmpty) continue;
    final p = e.value;
    final name = e.key.substring(
      e.key.lastIndexOf('node_modules/') + 'node_modules/'.length,
    );
    if (p['dev'] == true || !applies(p, name)) continue;
    final version = p['version'] as String;
    var override = npmOverrides[name] as Map<String, dynamic>?;
    for (final pe in patterns.entries) {
      if (override == null && name.startsWith(pe.key)) {
        override = (pe.value as Map).cast<String, dynamic>();
      }
    }
    final texts = <int>[];
    final note = override?['note'] as String?;
    var license = override?['license'] as String? ?? p['license'] as String?;
    final dirPath = '${_root.path}/$_webRelative/${e.key}';
    if (override != null && override['textFiles'] != null) {
      for (final f in (override['textFiles'] as List).cast<String>()) {
        texts.add(_addText(_licenceText(f)));
      }
    } else {
      final from = override?['textFrom'] as String?;
      final key = from == null ? e.key : names[from];
      if (key == null) _fail('$name: textFrom "$from" is not in the lockfile');
      final files = _licenceFiles(
        Directory('${_root.path}/$_webRelative/$key'),
      );
      if (files.isEmpty) {
        _fail(
          '$name $version has no licence file in node_modules (is npm ci done? $dirPath); add it to scripts/licence-overrides.json',
        );
      }
      for (final f in files) {
        texts.add(_addText(f.readAsStringSync()));
        license ??= _identify(f.readAsStringSync());
      }
    }
    if (license == null) {
      _fail(
        '$name $version: cannot identify the licence; add it to scripts/licence-overrides.json',
      );
    }
    entries.add(
      _entry(
        name: name,
        version: version,
        license: license,
        homepage: 'https://www.npmjs.com/package/$name/v/$version',
        source: 'npm',
        texts: texts,
        note: note,
        direct: rootDeps.contains(name),
      ),
    );
  }
  entries.sort(_byName);
  return entries;
}

int _byName(Map<String, dynamic> a, Map<String, dynamic> b) {
  final c = (a['name'] as String).compareTo(b['name'] as String);
  return c != 0
      ? c
      : (a['version'] as String).compareTo(b['version'] as String);
}

// ------------------------------------------------------ bundled assets

Map<String, dynamic> _asset({
  required String name,
  required String version,
  required String license,
  required String homepage,
  required List<String> files,
  String? note,
}) => _entry(
  name: name,
  version: version,
  license: license,
  homepage: homepage,
  source: 'bundled',
  texts: [for (final f in files) _addText(_read(f))],
  note: note,
);

List<Map<String, dynamic>> _fontEntries() {
  const fonts = 'packages/soar_score_ui/assets/fonts';
  return [
    _asset(
      name: 'Archivo (font)',
      version: '',
      license: 'OFL-1.1',
      homepage: 'https://github.com/Omnibus-Type/Archivo',
      files: ['$fonts/archivo/OFL.txt'],
    ),
    _asset(
      name: 'League Spartan (font)',
      version: '',
      license: 'OFL-1.1',
      homepage: 'https://github.com/theleagueof/league-spartan',
      files: ['$fonts/league_spartan/OFL.txt'],
    ),
    _asset(
      name: 'Saira Stencil One (font)',
      version: '',
      license: 'OFL-1.1',
      homepage: 'https://github.com/Omnibus-Type/Saira',
      files: ['$fonts/saira_stencil_one/OFL.txt'],
    ),
  ];
}

List<Map<String, dynamic>> _flutterEntries() => [
  _entry(
    name: 'Flutter framework and engine',
    version: '',
    license: 'BSD-3-Clause',
    homepage: 'https://github.com/flutter/flutter',
    source: 'bundled',
    texts: [_addText(_licenceText('Flutter.txt'))],
    note:
        'Includes the packages flutter, flutter_localizations, '
        'flutter_web_plugins and sky_engine. The engine bundles further '
        'components (Skia, HarfBuzz, ICU, FreeType and others) under their '
        'own permissive licences, listed in the Flutter repository.',
  ),
  _entry(
    name: 'Dart SDK and runtime',
    version: '',
    license: 'BSD-3-Clause',
    homepage: 'https://github.com/dart-lang/sdk',
    source: 'bundled',
    texts: [_addText(_licenceText('Dart-SDK.txt'))],
  ),
];

List<Map<String, dynamic>> _windowsEntries() {
  const gs = 'tools/gs_importer';
  const sourceNote =
      'Source: the MinGW32 (MSYS2) build of mdbtools from '
      'https://github.com/lsgunth/mdbtools-win, pinned to commit '
      'cefdd6d277b77a36f2073106c71ec84c65bece2d. Upstream: '
      'https://github.com/mdbtools/mdbtools. Windows build only. '
      'Full notice: tools/gs_importer/NOTICE.txt in the repository.';
  return [
    _asset(
      name: 'mdbtools utilities (mdb-json.exe, mdb-tables.exe)',
      version: '',
      license: 'GPL-2.0',
      homepage: 'https://github.com/mdbtools/mdbtools',
      files: ['$gs/COPYING'],
      note: sourceNote,
    ),
    _asset(
      name: 'mdbtools library (libmdb-3.dll)',
      version: '',
      license: 'LGPL-2.0',
      homepage: 'https://github.com/mdbtools/mdbtools',
      files: ['$gs/COPYING.LIB'],
      note: sourceNote,
    ),
    _asset(
      name: 'libiconv (libiconv-2.dll)',
      version: '',
      license: 'LGPL-2.1',
      homepage: 'https://www.gnu.org/software/libiconv/',
      files: ['$gs/LGPL-2.1.txt'],
      note: sourceNote,
    ),
    _asset(
      name: 'GCC runtime (libgcc_s_dw2-1.dll)',
      version: '',
      license: 'GPL-3.0 WITH GCC-exception-3.1',
      homepage: 'https://gcc.gnu.org/',
      files: ['$gs/GPL-3.0.txt', '$gs/GCC-exception-3.1.txt'],
      note:
          'The GCC Runtime Library Exception lets this DLL accompany the app. $sourceNote',
    ),
    _asset(
      name: 'winpthreads (libwinpthread-1.dll)',
      version: '',
      license: 'MIT',
      homepage: 'https://www.mingw-w64.org/',
      files: ['$gs/winpthreads-COPYING.txt'],
      note: 'MinGW-w64 winpthreads. $sourceNote',
    ),
    _entry(
      name: 'OpenSSL (libssl-3-x64.dll, libcrypto-3-x64.dll)',
      version: '3',
      license: 'Apache-2.0',
      homepage: 'https://www.openssl.org/',
      source: 'bundled',
      texts: [_addText(_licenceText('Apache-2.0.txt'))],
      note:
          'Bundled with the sign-in plugin (auth0_flutter) next to the '
          'Windows executable. Copyright The OpenSSL Project Authors.',
    ),
    _entry(
      name: 'cpp-httplib',
      version: '',
      license: 'MIT',
      homepage: 'https://github.com/yhirose/cpp-httplib',
      source: 'bundled',
      texts: [_addText(_licenceText('cpp-httplib.txt'))],
      note:
          'Linked into the Windows app by the sign-in plugin (auth0_flutter, '
          'native dependencies from vcpkg).',
    ),
    _entry(
      name: 'nlohmann/json',
      version: '',
      license: 'MIT',
      homepage: 'https://github.com/nlohmann/json',
      source: 'bundled',
      texts: [_addText(_licenceText('nlohmann-json.txt'))],
      note:
          'Linked into the Windows app by the sign-in plugin (auth0_flutter, '
          'native dependencies from vcpkg).',
    ),
  ];
}

// -------------------------------------------------------------- output

/// Builds the data for every product, or only for [only]. A single product
/// reads just what it needs: the npm lockfile and node_modules only for the
/// public site, the pub cache only for the Dart apps.
Map<String, dynamic> _build({String? only}) {
  _overrides = jsonDecode(
    _read('scripts/licence-overrides.json'),
  ) as Map<String, dynamic>;
  final selected = [
    for (final p in _products)
      if (only == null || p.id == only) p,
  ];
  if (selected.isEmpty) {
    _fail('unknown product "$only" (${_products.map((p) => p.id).join(', ')})');
  }
  final graph = selected.any((p) => p.dartRoot != null)
      ? _loadPubGraph()
      : const <String, dynamic>{};
  final products = <Map<String, dynamic>>[];
  for (final product in selected) {
    final entries = <Map<String, dynamic>>[
      if (product.dartRoot != null) ..._dartEntries(graph, product),
      if (product.npm) ..._npmEntries(),
      if (product.flutter) ..._flutterEntries(),
      if (product.fonts) ..._fontEntries(),
      if (product.windowsHelpers) ..._windowsEntries(),
    ];
    // Package entries first (by name), bundled components after.
    entries.sort((a, b) {
      final ab = a['source'] == 'bundled' ? 1 : 0;
      final bb = b['source'] == 'bundled' ? 1 : 0;
      return ab != bb ? ab - bb : _byName(a, b);
    });
    products.add({
      'id': product.id,
      'name': product.name,
      'summary': product.summary,
      'entries': entries,
    });
  }
  if (only != null) {
    return {'schema': 1, 'products': products, 'texts': _texts};
  }
  return {
    'schema': 1,
    'inputs': {
      'pubspec.lock': _fingerprint('pubspec.lock'),
      'apps/soar_score_web/package-lock.json': _fingerprint(
        '$_webRelative/package-lock.json',
      ),
      'scripts/licence-overrides.json': _fingerprint(
        'scripts/licence-overrides.json',
      ),
    },
    'products': products,
    'texts': _texts,
  };
}

String _notices(Map<String, dynamic> data, String productId) {
  final product = (data['products'] as List)
      .cast<Map<String, dynamic>>()
      .firstWhere(
        (p) => p['id'] == productId,
        orElse: () => _fail(
          'unknown product "$productId" (${_products.map((p) => p.id).join(', ')})',
        ),
      );
  final texts = (data['texts'] as List).cast<String>();
  final b = StringBuffer()
    ..writeln('Third-party notices: ${product['name']}')
    ..writeln(
      'RC Soar Score is licensed under the GNU AGPL-3.0; source: '
      'https://github.com/mikejr83/rc-soar-score',
    )
    ..writeln('This file lists the open source components it includes.')
    ..writeln();
  for (final e in (product['entries'] as List).cast<Map<String, dynamic>>()) {
    final version = (e['version'] as String).isEmpty ? '' : ' ${e['version']}';
    b
      ..writeln('=' * 72)
      ..writeln('${e['name']}$version')
      ..writeln('License: ${e['license']}')
      ..writeln('Home: ${e['homepage']}');
    if (e['note'] != null) b.writeln(e['note']);
    for (final i in (e['texts'] as List).cast<int>()) {
      b
        ..writeln()
        ..writeln(texts[i]);
    }
    b.writeln();
  }
  return b.toString();
}

void main(List<String> args) {
  _root = Directory.fromUri(Platform.script.resolve('..'));
  String? notices;
  String? product;
  String? jsonOut;
  var check = false;
  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--check':
        check = true;
      case '--notices':
        notices = args[++i];
      case '--product':
        product = args[++i];
      case '--json':
        jsonOut = args[++i];
      default:
        _fail('unknown argument ${args[i]}');
    }
  }
  if (product != null && notices == null && jsonOut == null) {
    _fail('--product <id> needs --notices <file> and/or --json <file>');
  }
  if (product == null && (notices != null || jsonOut != null)) {
    _fail('--notices and --json need --product <id>');
  }

  final data = _build(only: product);
  final json = '${const JsonEncoder.withIndent('  ').convert(data)}\n';
  final out = File('${_root.path}/$_outRelative');

  if (product != null) {
    if (notices != null) {
      File(notices).writeAsStringSync(_notices(data, product));
      stdout.writeln('wrote $notices');
    }
    if (jsonOut != null) {
      File(jsonOut).writeAsStringSync(json);
      stdout.writeln('wrote $jsonOut');
    }
    return;
  }
  if (check) {
    final current = out.existsSync()
        ? out.readAsStringSync().replaceAll('\r\n', '\n')
        : '';
    if (current != json) {
      stderr.writeln(
        '$_outRelative is stale. Run scripts/generate-licences.sh '
        '(or .ps1) and commit the result.',
      );
      exit(1);
    }
    stdout.writeln('$_outRelative is up to date');
    return;
  }
  out.parent.createSync(recursive: true);
  out.writeAsStringSync(json);
  var count = 0;
  for (final p in (data['products'] as List).cast<Map<String, dynamic>>()) {
    final n = (p['entries'] as List).length;
    count += n;
    stdout.writeln('${p['id']}: $n entries');
  }
  stdout.writeln(
    'wrote $_outRelative ($count entries, ${_texts.length} texts)',
  );
}

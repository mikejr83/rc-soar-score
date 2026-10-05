import 'package:drift/drift.dart' show Variable;
import 'package:soar_score_core/soar_score_core.dart' as core;

import 'table_mapper.dart';

/// Stores one entity type: how its model becomes a row and back.
///
/// The unit of work and the replicated-change applier find the store by
/// entity type, so a new entity type needs only its store registered.
class EntityStore<T extends Object> {
  EntityStore({
    required this.entityType,
    required TableMapper mapper,
    required T Function(Map<String, Object?> json) decode,
    required Map<String, Object?> Function(T entity) encode,
    this.hasRevision = true,
  }) : _mapper = mapper,
       _decode = decode,
       _encode = encode;

  /// The name used in `MutationRecord.entity_type`.
  final String entityType;

  /// Whether the entity carries a row `revision` the unit of work bumps.
  final bool hasRevision;

  final TableMapper _mapper;
  final T Function(Map<String, Object?> json) _decode;
  final Map<String, Object?> Function(T entity) _encode;

  T decode(Map<String, Object?> json) => _decode(json);

  Map<String, Object?> encode(T entity) => _encode(entity);

  Future<Map<String, Object?>?> findJson(core.Id id) => _mapper.find(id);

  Future<T?> find(core.Id id) async {
    final json = await _mapper.find(id);
    return json == null ? null : _decode(json);
  }

  Future<List<T>> all({String? orderBy}) async => [
    for (final json in await _mapper.all(orderBy: orderBy)) _decode(json),
  ];

  /// The entities whose [column] equals [value], in [orderBy] order.
  ///
  /// [column] is a column name from the schema, never user input.
  Future<List<T>> whereId(
    String column,
    core.Id value, {
    String? orderBy,
  }) async => [
    for (final json in await _mapper.where('$column = ?', [
      Variable<String>(value.value),
    ], orderBy: orderBy))
      _decode(json),
  ];

  Future<void> upsertJson(Map<String, Object?> json) => _mapper.upsert(json);

  Future<bool> remove(core.Id id) => _mapper.remove(id);

  /// Removes every entity whose [column] equals [value]; returns how many.
  Future<int> removeWhereId(String column, core.Id value) =>
      _mapper.removeWhere(column, value);
}

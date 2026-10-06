import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'package:shelf/shelf.dart';

/// Reads the JSON object in the body of [request] and builds a request DTO
/// from it with [fromJson].
///
/// Every way the body can be wrong (not JSON, not an object, a missing or
/// mistyped field, an invalid id or date) is an [ArgumentError], which the
/// error middleware answers with 400.
Future<T> readJsonBody<T>(
  Request request,
  T Function(Map<String, dynamic> json) fromJson,
) async {
  final Object? decoded;
  try {
    decoded = jsonDecode(await request.readAsString());
  } on FormatException {
    throw ArgumentError('The request body is not valid JSON.');
  }
  if (decoded is! Map<String, dynamic>) {
    throw ArgumentError('The request body must be a JSON object.');
  }
  try {
    return fromJson(decoded);
  } on CheckedFromJsonException catch (e) {
    throw ArgumentError('Invalid "${e.key}": ${e.message}');
  } on ArgumentError catch (e) {
    throw ArgumentError('Invalid request body: ${e.message}');
  } on FormatException catch (e) {
    throw ArgumentError('Invalid request body: ${e.message}');
  } on TypeError {
    throw ArgumentError('The request body has a field of the wrong type.');
  }
}

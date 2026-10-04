import 'package:json_annotation/json_annotation.dart';

import '../id.dart';
import 'protected_credential.dart';
import 'scoring_uuid.dart';
import 'utc_timestamp.dart';

/// Serializes an [Id] as its canonical string.
class IdConverter implements JsonConverter<Id, String> {
  const IdConverter();

  @override
  Id fromJson(String json) => Id.parse(json);

  @override
  String toJson(Id object) => object.value;
}

/// Serializes a [ProtectedCredential] as its protected string.
class ProtectedCredentialConverter
    implements JsonConverter<ProtectedCredential, String> {
  const ProtectedCredentialConverter();

  @override
  ProtectedCredential fromJson(String json) => ProtectedCredential(json);

  @override
  String toJson(ProtectedCredential object) => object.value;
}

/// Serializes a [ScoringUuid] as its canonical string.
class ScoringUuidConverter implements JsonConverter<ScoringUuid, String> {
  const ScoringUuidConverter();

  @override
  ScoringUuid fromJson(String json) => ScoringUuid.parse(json);

  @override
  String toJson(ScoringUuid object) => object.value;
}

/// Serializes a [DateTime] as UTC ISO 8601, rejecting non-UTC input.
class UtcTimestampConverter implements JsonConverter<DateTime, String> {
  const UtcTimestampConverter();

  @override
  DateTime fromJson(String json) => parseUtcTimestamp(json);

  @override
  String toJson(DateTime object) => formatUtcTimestamp(object);
}

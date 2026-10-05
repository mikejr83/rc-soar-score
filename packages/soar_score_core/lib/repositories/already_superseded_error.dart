import '../models/id.dart';

/// A matrix assignment was moved a second time.
///
/// An assignment is superseded exactly once; a later move starts from the
/// assignment that superseded it.
class AlreadySupersededError extends Error {
  AlreadySupersededError({required this.assignmentId});

  final Id assignmentId;

  @override
  String toString() =>
      'AlreadySupersededError: assignment ${assignmentId.value} was already '
      'moved';
}

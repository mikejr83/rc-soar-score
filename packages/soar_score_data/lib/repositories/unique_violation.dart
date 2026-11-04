/// Whether [error] is a broken unique rule on either backend.
bool isUniqueViolation(Object error) {
  final text = '$error'.toLowerCase();
  return text.contains('unique constraint') ||
      text.contains('duplicate key') ||
      text.contains('23505');
}

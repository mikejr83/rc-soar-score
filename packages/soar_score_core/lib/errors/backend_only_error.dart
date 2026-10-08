/// A request needs data that only the hosted backend keeps.
///
/// Accounts, publications and the like never exist on an installation, so the
/// embedded server answers this instead of reading a table it does not have.
class BackendOnlyError extends Error {
  BackendOnlyError(this.entityType);

  final String entityType;

  @override
  String toString() =>
      'BackendOnlyError: $entityType is only available on the hosted server';
}

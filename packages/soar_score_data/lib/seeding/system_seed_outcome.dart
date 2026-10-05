/// What a `SystemDataSeeder` run did.
enum SystemSeedOutcome {
  /// The shipped data was checked and anything missing was installed.
  installed,

  /// The stored system-data position was at or above the shipped sequence, so
  /// nothing was read or written.
  upToDate,
}

---
name: code-review
description: Perform code reviews following Dart, Flutter, Shelf, and Drift engineering practices. Use when reviewing pull requests, examining code changes, or providing feedback on code quality. Covers async safety, UI performance, database efficiency, and API design.
---

# Flutter, Shelf & Drift Code Review Guidelines

Follow these guidelines when reviewing code for Dart, Flutter, Shelf, and Drift projects.

## Review Checklist

### Identifying Problems

Look for these issues in code changes:

- **Async & Concurrency**: Uncaught futures, missing `await`, and `BuildContext` usage across async gaps without checking `mounted`.
- **Resource Management**: Controllers (`TextEditingController`, `ScrollController`, animation controllers) or stream subscriptions not disposed in `dispose()`.
- **Performance & Rebuilds**: Missing `const` constructors, heavy computations on the UI thread, or unoptimized lists (e.g., using `ListView` instead of `ListView.builder` for dynamic datasets).
- **Drift & Database**: Inefficient queries, missing indices, improper transaction usage for multi-table writes, or misuse of reactive `.watch()` streams causing excessive UI updates.
- **Shelf Handlers**: Unhandled exceptions in route handlers, missing input validation, or lack of proper middleware for error handling, CORS, and logging.
- **Security & Storage**: Unencrypted sensitive local data, improper token handling, or unvalidated request parameters.

### Design Assessment

- Do Flutter widget boundaries and state management approaches align with the project architecture?
- Are Shelf route handlers decoupled cleanly from business logic and data access?
- Are Drift DAOs and tables properly structured and separated from service layers?

### Test Coverage

Every PR should have appropriate test coverage:

- **Unit tests**: For business logic, view models/providers, and Drift queries/DAOs (using in-memory SQLite instances).
- **Widget tests**: For component behavior, user interactions, and state changes.
- **Integration tests**: For critical user paths, end-to-end API requests, and database workflows.

### Long-Term Impact

Flag for senior engineer review when changes involve:

- Drift database schema migrations and table modifications.
- Shelf API contract changes or breaking version updates.
- Introduction of new global state management patterns or heavy packages.
- Performance-critical rendering or database query hot paths.

## Feedback Guidelines

### Tone

- Be polite and empathetic.
- Provide actionable suggestions, not vague criticism.
- Phrase as questions when uncertain: "Have you considered...?"

### Approval

- Approve when only minor issues remain.
- Don't block PRs for stylistic preferences.
- Remember: the goal is risk reduction, not perfect code.

## Common Patterns to Flag

### Flutter: BuildContext Across Async Gaps

```dart
// Bad: Using context after an asynchronous gap without checking mounted
Future<void> _submitData() async {
  final data = await apiService.fetchData();
  Navigator.of(context).pop(data); // Risk if widget unmounted during fetch
}

// Good: Check mounted before using context
Future<void> _submitData() async {
  final data = await apiService.fetchData();
  if (!mounted) return;
  Navigator.of(context).pop(data);
}
```

### Drift: Transactions & Reactive Queries

```dart
// Bad: Executing independent writes without a transaction
await db.into(db.todos).insert(todoCompanion);
await db.into(db.auditLogs).insert(logCompanion);

// Good: Wrap multi-step mutations in a transaction
await db.transaction(() async {
  await db.into(db.todos).insert(todoCompanion);
  await db.into(db.auditLogs).insert(logCompanion);
});
```

### Shelf: Route Handler Error Handling

```dart
// Bad: Uncaught exceptions crashing the handler
Response _handler(Request request) {
  final data = jsonDecode(request.readAsString()); // Can throw format exception
  return Response.ok(jsonEncode(process(data)));
}

// Good: Proper parsing with error catching and validation
Future<Response> _handler(Request request) async {
  try {
    final body = await request.readAsString();
    final data = jsonDecode(body) as Map<String, dynamic>;
    return Response.ok(jsonEncode(process(data)), headers: {'Content-Type': 'application/json'});
  } on FormatException {
    return Response.badRequest(body: 'Invalid JSON payload');
  }
}
```

## References

- [Flutter Best Practices](https://docs.flutter.dev/perf/best-practices)
- [Drift Documentation](https://drift.simonbinder.eu/)
- [Shelf Package](https://pub.dev/packages/shelf)
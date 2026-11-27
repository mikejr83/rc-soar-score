import 'package:soar_score_core/models/id.dart';

/// [Id] for apps that depend on the API package alone (the self-scoring app),
/// to build the ids the [ApiClient] takes from the strings of its own models.
/// Exporting [Id] itself would make every `soar_score_core` import that only
/// uses it redundant, so it goes by this name.
typedef ApiId = Id;

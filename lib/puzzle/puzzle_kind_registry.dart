import 'puzzle_kind.dart';

/// Process-wide registry mapping `PuzzleKind.id` to its implementation.
///
/// The engine resolves [PuzzleKind] by id rather than importing concrete
/// modules so `lib/engine/` stays puzzle-agnostic. Registration happens
/// at app startup (see `lib/main.dart`).
class PuzzleKindRegistry {
  PuzzleKindRegistry();

  final Map<String, PuzzleKind> _byId = {};

  void register(PuzzleKind kind) {
    if (_byId.containsKey(kind.id)) {
      throw StateError(
        'PuzzleKind "${kind.id}" is already registered. '
        'Each kind id must be registered exactly once.',
      );
    }
    _byId[kind.id] = kind;
  }

  PuzzleKind? get(String id) => _byId[id];

  List<PuzzleKind> all() => List.unmodifiable(_byId.values);
}

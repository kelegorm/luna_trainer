import 'package:flutter/material.dart';

import 'app.dart';
import 'puzzle/puzzle_kind_registry.dart';
import 'puzzles/tango/tango_puzzle_kind.dart';

/// Single app-level registry of [PuzzleKind] implementations. v1 only
/// registers Tango; second kinds plug in here without engine changes.
final puzzleKindRegistry = PuzzleKindRegistry()
  ..register(const TangoPuzzleKind());

void main() {
  runApp(const LunaTrainerApp());
}

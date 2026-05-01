import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luna_traineer/engine/domain/heuristic.dart';
import 'package:luna_traineer/puzzle/puzzle_kind.dart';
import 'package:luna_traineer/puzzle/puzzle_kind_registry.dart';
import 'package:luna_traineer/puzzles/tango/tango_puzzle_kind.dart';

class _FakeSolver extends Solver {
  const _FakeSolver();
  @override
  List<Deduction> availableDeductions(Position p) => const [];
}

class _FakeGenerator extends LevelGenerator {
  const _FakeGenerator();
}

class _FakePuzzleKind extends PuzzleKind {
  const _FakePuzzleKind(this.id);

  @override
  final String id;

  @override
  List<HeuristicDescriptor> get heuristics => const [];

  @override
  Solver get solver => const _FakeSolver();

  @override
  LevelGenerator get generator => const _FakeGenerator();

  @override
  Widget renderBoard(Position position, void Function(Move move) onMove) {
    throw UnimplementedError();
  }

  @override
  Widget renderHintField(Position position, Deduction deduction) {
    throw UnimplementedError();
  }
}

void main() {
  group('PuzzleKindRegistry', () {
    test('all() is empty before any registration', () {
      final registry = PuzzleKindRegistry();
      expect(registry.all(), isEmpty);
      expect(registry.get('tango'), isNull);
    });

    test('register/get round-trip returns the same instance', () {
      final registry = PuzzleKindRegistry();
      const tango = TangoPuzzleKind();

      registry.register(tango);

      expect(registry.get('tango'), same(tango));
      expect(registry.all(), [tango]);
    });

    test('duplicate id raises StateError with a useful message', () {
      final registry = PuzzleKindRegistry()
        ..register(const TangoPuzzleKind());

      expect(
        () => registry.register(const _FakePuzzleKind('tango')),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('tango'),
          ),
        ),
      );
    });

    test('all() is unmodifiable', () {
      final registry = PuzzleKindRegistry()
        ..register(const TangoPuzzleKind());

      expect(
        () => registry.all().add(const _FakePuzzleKind('queens')),
        throwsUnsupportedError,
      );
    });
  });

  group('TangoPuzzleKind stub', () {
    test('exposes id "tango" and the MVP heuristic catalog (R2)', () {
      const kind = TangoPuzzleKind();

      expect(kind.id, 'tango');
      expect(kind.heuristics, isNotEmpty);

      final tagIds = kind.heuristics.map((h) => h.heuristic.tagId).toSet();
      expect(
        tagIds,
        containsAll(<String>{
          'PairCompletion',
          'TrioAvoidance',
          'ParityFill',
          'SignPropagation',
          'AdvancedMidLineInference',
          'ChainExtension',
          'Composite(unknown)',
        }),
      );
    });

    test('Composite(unknown) is not eligible for drill (R10)', () {
      const kind = TangoPuzzleKind();
      final composite = kind.heuristics.singleWhere(
        (h) => h.heuristic == const Heuristic('tango', 'Composite(unknown)'),
      );

      expect(composite.eligibleForDrill, isFalse);
    });

    test('solver is wired (U5); generator is still a stub until U6', () {
      const kind = TangoPuzzleKind();
      // U5 landed: solver now returns a list (empty for an unknown
      // Position subtype) instead of throwing.
      expect(
        kind.solver.availableDeductions(const _DummyPosition()),
        isEmpty,
      );
      // Generator is still a stub; U6 will replace it.
      expect(kind.generator, isNotNull);
    });
  });
}

class _DummyPosition extends Position {
  const _DummyPosition();
}

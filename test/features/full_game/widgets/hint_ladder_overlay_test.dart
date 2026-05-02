import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luna_traineer/engine/domain/heuristic.dart';
import 'package:luna_traineer/features/full_game/bloc/full_game_bloc.dart';
import 'package:luna_traineer/features/full_game/widgets/hint_ladder_overlay.dart';
import 'package:luna_traineer/puzzles/tango/domain/tango_constraint.dart';
import 'package:luna_traineer/puzzles/tango/domain/tango_mark.dart';
import 'package:luna_traineer/puzzles/tango/domain/tango_position.dart';
import 'package:luna_traineer/puzzles/tango/solver/tango_deduction.dart';
import 'package:luna_traineer/puzzles/tango/widgets/tango_hint_field.dart';

/// Test-only Cubit that stands in for FullGameBloc — we only need the
/// state stream for HintLadderOverlay's BlocBuilder. Using Cubit here
/// avoids fabricating a full FullGameBloc with all its dependencies.
class _FakeFullGameCubit extends Cubit<FullGameState>
    implements FullGameBloc {
  _FakeFullGameCubit(super.initial);

  @override
  // ignore: must_call_super
  void noSuchMethod(Invocation invocation) {}
}

Widget _host(_FakeFullGameCubit cubit) => MaterialApp(
      home: Scaffold(
        body: BlocProvider<FullGameBloc>.value(
          value: cubit,
          child: const HintLadderOverlay(),
        ),
      ),
    );

FullGameState _stateWithHint(TangoDeduction deduction, {int step = 1}) {
  return FullGameState(
    status: FullGameStatus.playing,
    position: TangoPosition.empty(),
    hintOverlayOpen: true,
    hintStep: step,
    suggestedDeduction: deduction,
  );
}

void main() {
  group('HintLadderOverlay step 1 — technique label (R33)', () {
    testWidgets('uses HeuristicDescriptor.displayName for catalog tags',
        (tester) async {
      final cubit = _FakeFullGameCubit(
        _stateWithHint(
          const TangoDeduction(
            heuristic: Heuristic('tango', 'ParityFill'),
            forcedCells: [CellAddress(0, 0)],
            forcedMark: TangoMark.sun,
          ),
        ),
      );

      await tester.pumpWidget(_host(cubit));
      await tester.pump();

      expect(find.text('Technique: Баланс линии'), findsOneWidget);
      expect(find.text('Technique: ParityFill'), findsNothing);

      await cubit.close();
    });

    testWidgets('uses displayName for AdvancedMidLineInference sub-tags (R30)',
        (tester) async {
      final cubit = _FakeFullGameCubit(
        _stateWithHint(
          const TangoDeduction(
            heuristic:
                Heuristic('tango', 'AdvancedMidLineInference/edge_1_5'),
            forcedCells: [CellAddress(2, 3)],
            forcedMark: TangoMark.moon,
          ),
        ),
      );

      await tester.pumpWidget(_host(cubit));
      await tester.pump();

      expect(find.text('Technique: Краевая ловушка 1–5'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('falls back to tagId for uncatalogued heuristics',
        (tester) async {
      final cubit = _FakeFullGameCubit(
        _stateWithHint(
          const TangoDeduction(
            heuristic: Heuristic('tango', 'UncataloguedXYZ'),
            forcedCells: [CellAddress(0, 0)],
            forcedMark: TangoMark.sun,
          ),
        ),
      );

      await tester.pumpWidget(_host(cubit));
      await tester.pump();

      expect(find.text('Technique: UncataloguedXYZ'), findsOneWidget);

      await cubit.close();
    });
  });

  group('HintLadderOverlay step 2 — preconditions board (R26)', () {
    testWidgets('renders TangoHintField via PuzzleKind.renderHintField',
        (tester) async {
      final cubit = _FakeFullGameCubit(
        _stateWithHint(
          const TangoDeduction(
            heuristic: Heuristic('tango', 'TrioAvoidance'),
            forcedCells: [CellAddress(1, 1)],
            forcedMark: TangoMark.sun,
          ),
          step: 2,
        ),
      );

      await tester.pumpWidget(_host(cubit));
      await tester.pump();

      expect(find.byType(TangoHintField), findsOneWidget);

      await cubit.close();
    });
  });
}

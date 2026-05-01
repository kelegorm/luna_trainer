/// Тип события для drill-flow (R29). В Phase C пишется только
/// `production`; recognition-варианты добавляются в Phase D (U12) без
/// миграции.
enum MoveEventKind {
  production,
  recognitionHit,
  recognitionCorrectReject,
  recognitionFalseAlarm,
}

extension MoveEventKindWire on MoveEventKind {
  /// Стабильное wire-представление для `move_events.event_kind`.
  String get wire => switch (this) {
        MoveEventKind.production => 'production',
        MoveEventKind.recognitionHit => 'recognition_hit',
        MoveEventKind.recognitionCorrectReject => 'recognition_correct_reject',
        MoveEventKind.recognitionFalseAlarm => 'recognition_false_alarm',
      };
}

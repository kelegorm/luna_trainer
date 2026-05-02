import '../domain/tango_mark.dart';

/// Pure input-cycle helper for Tango cell taps.
///
/// Tapping a cell rotates its mark `empty → sun → moon → empty` (R26
/// via U10). Kept as a top-level function (not a stateful widget) so
/// the same rule is reusable from drill widgets, hint overlays, and
/// widget tests without instantiating UI.
TangoMark? nextTangoMark(TangoMark? current) {
  switch (current) {
    case null:
      return TangoMark.sun;
    case TangoMark.sun:
      return TangoMark.moon;
    case TangoMark.moon:
      return null;
  }
}

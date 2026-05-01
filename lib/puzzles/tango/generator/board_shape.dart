import '../domain/tango_constraint.dart';
import '../domain/tango_position.dart';

/// Kind tag identifying the shape variant.
enum BoardShapeKind { full6x6, fragment2x4, fragment3x3, singleRow, singleCol }

/// Geometry mask describing which cells of the canonical 6×6 grid are
/// gameplay-active for a given puzzle / drill fragment.
///
/// Inactive cells are always `null` in [TangoPosition.cells]; the
/// generator never fills them and the shape-aware legality / uniqueness
/// checks ignore them entirely.
///
/// The mask is expressed in the global 6×6 coordinate system so the same
/// `TangoPosition` shape can flow through solver / renderer without
/// branching on shape kind.
class BoardShape {
  BoardShape._({
    required this.kind,
    required this.activeCells,
    required this.activeLines,
    required this.fullLines,
  }) : activeCellSet = Set.unmodifiable(activeCells);

  /// Full 6×6 board: all cells active, all four rules apply.
  factory BoardShape.full6x6() {
    final cells = <CellAddress>[
      for (var r = 0; r < kTangoBoardSize; r++)
        for (var c = 0; c < kTangoBoardSize; c++) CellAddress(r, c),
    ];
    final lines = <List<CellAddress>>[
      for (var r = 0; r < kTangoBoardSize; r++)
        [for (var c = 0; c < kTangoBoardSize; c++) CellAddress(r, c)],
      for (var c = 0; c < kTangoBoardSize; c++)
        [for (var r = 0; r < kTangoBoardSize; r++) CellAddress(r, c)],
    ];
    return BoardShape._(
      kind: BoardShapeKind.full6x6,
      activeCells: List.unmodifiable(cells),
      activeLines: List.unmodifiable(lines.map(List<CellAddress>.unmodifiable)),
      fullLines: List.unmodifiable(lines.map(List<CellAddress>.unmodifiable)),
    );
  }

  /// 2×4 sub-grid anchored at rows 0..1, cols 0..3. Anti-triple + sign
  /// constraints apply on partial lines that lie entirely within active
  /// cells. No count balance (lines aren't full-length 6).
  factory BoardShape.fragment2x4() {
    return _rectFragment(BoardShapeKind.fragment2x4, rows: 2, cols: 4);
  }

  /// 3×3 sub-grid anchored at rows 0..2, cols 0..2.
  factory BoardShape.fragment3x3() {
    return _rectFragment(BoardShapeKind.fragment3x3, rows: 3, cols: 3);
  }

  /// One full row (row 0). All four rules apply on that row.
  factory BoardShape.singleRow() {
    final row = [for (var c = 0; c < kTangoBoardSize; c++) CellAddress(0, c)];
    return BoardShape._(
      kind: BoardShapeKind.singleRow,
      activeCells: List.unmodifiable(row),
      activeLines: List.unmodifiable([List<CellAddress>.unmodifiable(row)]),
      fullLines: List.unmodifiable([List<CellAddress>.unmodifiable(row)]),
    );
  }

  /// One full column (col 0).
  factory BoardShape.singleCol() {
    final col = [for (var r = 0; r < kTangoBoardSize; r++) CellAddress(r, 0)];
    return BoardShape._(
      kind: BoardShapeKind.singleCol,
      activeCells: List.unmodifiable(col),
      activeLines: List.unmodifiable([List<CellAddress>.unmodifiable(col)]),
      fullLines: List.unmodifiable([List<CellAddress>.unmodifiable(col)]),
    );
  }

  static BoardShape _rectFragment(
    BoardShapeKind kind, {
    required int rows,
    required int cols,
  }) {
    final cells = <CellAddress>[
      for (var r = 0; r < rows; r++)
        for (var c = 0; c < cols; c++) CellAddress(r, c),
    ];
    // Active "lines" we still scan for anti-triple — partial rows/cols
    // entirely inside the active rectangle. They are NOT [fullLines] so
    // count-balance does not fire on them.
    final lines = <List<CellAddress>>[
      for (var r = 0; r < rows; r++)
        [for (var c = 0; c < cols; c++) CellAddress(r, c)],
      for (var c = 0; c < cols; c++)
        [for (var r = 0; r < rows; r++) CellAddress(r, c)],
    ];
    return BoardShape._(
      kind: kind,
      activeCells: List.unmodifiable(cells),
      activeLines: List.unmodifiable(lines.map(List<CellAddress>.unmodifiable)),
      fullLines: const [],
    );
  }

  /// Tag identifying which factory produced this shape.
  final BoardShapeKind kind;

  /// Cells that are gameplay-active. Inactive cells must be `null` in
  /// every [TangoPosition] threaded through this shape.
  final List<CellAddress> activeCells;

  /// Lines on which anti-triple is checked. May be partial — for the
  /// 2×4 fragment, rows are 4-cells long.
  final List<List<CellAddress>> activeLines;

  /// Subset of [activeLines] that are full-length (== [kTangoBoardSize])
  /// and on which count-balance is enforced. Empty for fragments.
  final List<List<CellAddress>> fullLines;

  /// Quick membership test for active cells.
  bool isActive(int row, int col) =>
      activeCellSet.contains(CellAddress(row, col));

  /// Set view onto [activeCells] for fast lookups; cached at
  /// construction time so hot paths don't re-allocate it on every call.
  final Set<CellAddress> activeCellSet;
}

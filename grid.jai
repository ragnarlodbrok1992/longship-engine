#load "line.jai";

LINE_SPACING :: 1.0;
LINE_SPACING_START :: -10.0;
NUMBER_OF_LINES :: 21;
GRID_STRETCH :: 10;

Grid_Type :: enum u8 {
  X_PLANE :: 0;
  Y_PLANE;
  Z_PLANE;
}

Grid :: struct {
  type           : Grid_Type;
  lines          : [..]Line;
  parallel_lines : [..]Line;
}

populate_lines :: (grid: *Grid, gt: *Grid_Type) {

}

populate_parallel_lines :: (grid: *Grid, gt: *Grid_Type) {

}

create_grid :: (grid_type: Grid_Type) -> *Grid {
  new_grid := New(Grid);

  new_grid.type = grid_type;

  return new_grid;
}

render_grid :: (grid: *Grid) {

}


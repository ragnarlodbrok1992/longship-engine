#load "line.jai";

LINE_SPACING :: 1.0;
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


create_grid :: (grid_type: Grid_Type) -> *Grid {
  new_grid := New(Grid);

  new_grid.type = grid_type;

  return new_grid;
}

render_grid :: (grid: *Grid) {

}


#load "line.jai";

LINE_SPACING := 1.0;

Grid_Type :: enum u8 {
  X_PLANE :: 0;
  Y_PLANE;
  Z_PLANE;
}

Grid :: struct {
  type           :: Grid_Type;
  lines          :: [..]Line;
  parallel_lines :: [..]Line;
}


create_grid :: (grid: *Grid) {

}

render_grid :: (grid: *Grid) {

}


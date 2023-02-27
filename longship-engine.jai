#import "Basic";
#import "Window_Creation";
#import "Input";

Simp :: #import "Simp";


// Engine internal variables
QUIT := false;

WINDOW_TITLE_BAR : string = "Longship Engine";
WINDOW_WIDTH : s16 = 1024;
WINDOW_HEIGHT : s16 = 768;

// TODO ragnar: create a grid of isotiles
ISO_TILESET_WIDTH := 1000;
ISO_TILESET_HEIGHT := 1000;
ISO_TILE_WIDTH := 20;
ISO_TILE_HEIGHT := 20;
ISO_TILESET_X := 0;
ISO_TILESET_Y := 0;

// Define structs
Color :: struct {
  r: u8;
  g: u8;
  b: u8;
  a: u8;
}

Point :: struct {
  x: int;
  y: int;
}

PointF :: struct {
  x: float;
  y: float;
}

Line :: struct {
  start: Point;
  end: Point;
}

IsoTile :: struct {
  id: int;
  
  // DEBUG stuff
  nw: Point;
  ne: Point;
  se: Point;
  sw: Point;
}

// Define some colors
BLACK : Color = .{0, 0, 0, 255};
RED : Color = .{255, 0, 0, 255};
GREEN : Color = .{0, 255, 0, 255};
BLUE : Color = .{0, 0, 255, 255};
KHAKI : Color = .{240, 230, 140, 255};
DARK_KHAKI : Color = .{189, 183, 107, 255};

// Define functions
populate_iso_tile :: (iso_tile: *IsoTile) {
  iso_tile.nw = .{69, 69};
  iso_tile.ne = .{420, 69};
  iso_tile.se = .{420, 420};
  iso_tile.sw = .{69, 420};
}

main :: () {
  // Welcoming messages
  print("Hello, longship-engine!\n");

  // DEBUG prints
  print("BLACK: %\n", BLACK);

  // DEBUG stack variables
  // debug_iso_tile: *IsoTile;
  debug_iso_tile := New(IsoTile); // TODO ragnar: check what is going here - heap allocation?
  // This is allocated on heap with alloc - check what should I do with maybe context allocator?

  print("IsoTile: %\n", <<debug_iso_tile);
  populate_iso_tile(debug_iso_tile); 
  print("IsoTile: %\n", <<debug_iso_tile);

  // Getting command line arguments
  args := get_command_line_arguments();
  if (args.count > 1) {
    for args {
      if (it_index == 0) continue;
      // TODO ragnar: add switch for program arguments
      // TODO ragnar: add struct for program control variables
      print("Additional argument: %\n", it);
    }
  }

  // Engine initialization
  MAIN_ENGINE_WINDOW := create_window(WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_TITLE_BAR);
  Simp.set_render_target(MAIN_ENGINE_WINDOW);

  // Main SIMP loop
  while !QUIT {
    reset_temporary_storage();

    Simp.clear_render_target(.0, .0, .0, 1);

    update_window_events();

    // Check input events
    for events_this_frame {
      if it.type == .QUIT then QUIT = true;

      if it.type == .KEYBOARD {
        if it.key_pressed == 0 continue;

        if it.key_code == .ESCAPE {
          QUIT = true;
        }
      }
    }
    // End of checking input events
    
    // Render something for debug purposes

    // Swapping buffers - goes after rendering
    Simp.swap_buffers(MAIN_ENGINE_WINDOW);

    memory_visualizer_per_frame_update();
  }
}

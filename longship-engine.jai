#import "Basic";
#import "Window_Creation";
#import "Input";

Simp :: #import "Simp";


// Engine internal variables
QUIT := false;

WINDOW_TITLE_BAR : string = "Longship Engine";
WINDOW_WIDTH : s16 = 800;
WINDOW_HEIGHT : s16 = 600;


main :: () {
  // Welcoming messages
  print("Hello, longship-engine!\n");

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
    
    Simp.swap_buffers(MAIN_ENGINE_WINDOW);

    memory_visualizer_per_frame_update();
  }
}

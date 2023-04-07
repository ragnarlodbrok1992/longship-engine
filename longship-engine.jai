// Basic JAI import
#import "Basic";

// Global JAI imports
#import "Window_Creation";
#import "Input";
#import "Math";
#import "SDL";
#import "GL";
Simp :: #import "Simp";

// Local engine loads
#load "variables.jai";
#load "camera.jai";
#load "iso_tile.jai";
#load "cube.jai";
#load "triangle.jai";
#load "line.jai";
#load "shaders.jai";
#load "util_prints.jai";

// Engine variables
QUIT := false;
MAIN_ENGINE_WINDOW : *void;
CONTROL_CAMERA : bool = true;


main :: () {
  print("Longship engine - CUBE test.\n");
  
  // Debug prints - import path
  // DEBUG - filepath?
  print("Filepath: %\n", #filepath);

  // Some start stuff
  #if OS == .WINDOWS {
    win32 :: #import "Windows";
    win32.SetProcessDPIAware();
  }

  // Getting command line arguments
  args := get_command_line_arguments();
  if (args.count > 1) {
    for args {
      if (it_index == 0) continue;
      // @TODO ragnar: add switch for program arguments
      // @TODO ragnar: add struct for program control variables
      print("Additional argument: %\n", it);
    }
  }

  // Engine initialization
  SDL_Init(SDL_INIT_VIDEO);

  MAIN_ENGINE_WINDOW := SDL_CreateWindow(WINDOW_TITLE_BAR, SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, xx WINDOW_WIDTH, xx WINDOW_HEIGHT, SDL_WINDOW_OPENGL|SDL_WINDOW_RESIZABLE);
  print("Main engine window: %, type_of: %\n", MAIN_ENGINE_WINDOW, type_of(MAIN_ENGINE_WINDOW));
  if MAIN_ENGINE_WINDOW == null {
    print("Could not create window: %\n", to_string(SDL_GetError()));
    return;
  }

  SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, xx SDL_GL_CONTEXT_PROFILE_CORE);

  gl_context := SDL_GL_CreateContext(MAIN_ENGINE_WINDOW);

  if !gl_context {
    print("Could not create OpenGL context: %\n", to_string(SDL_GetError()));
    return;
  }

  gl_load(*gl, SDL_GL_GetProcAddress);
  using gl;
  
  print("GL Vendor = %\n", to_string(glGetString(GL_VENDOR)));
  print("GL Version = %\n", to_string(glGetString(GL_VERSION)));

  // Setting up OpenGL
  glEnable(GL_DEPTH_TEST);

  // Setup simp stuff for getting rect?
  Simp.set_render_target(MAIN_ENGINE_WINDOW);

  // @TODO: initializing fonts I think we should be doing here
  // use function get_font_at_size

  // Defering stuff
  defer SDL_DestroyWindow(MAIN_ENGINE_WINDOW);
  defer SDL_Quit();

  // Time variables
  delta_time := 0.01667; // Assuming 60 FPS

  // Create vao for lines and cube
  vao : GLuint;
  glGenVertexArrays(1, *vao);
  glBindVertexArray(vao);

  // Create shader program
  program_id := load_shaders();

  // Get uniform location
  view_projection_matrix_id := glGetUniformLocation(program_id, "u_view_projection");

  // Create camera
  flying_camera : Camera;
  space_pushed := false;
  mouse_delta : Vector2;

  flying_camera.position = xyz (1, 1.3, 2.3);
  flying_camera.euler_angles.x = 0 * PI / 180.0;
  flying_camera.euler_angles.y = 0 * PI / 180.0;

  // Create test cube
  test_cube := New(Cube);

  // Create test triangle buffers
  create_buffers(test_cube);

  // Create lines (x y and z axis)
  // @TODO ragnar - moving code to grid.jai
  x_lines          := New([21]Line);
  x_lines_parallel := New([21]Line);
  y_lines          := New([21]Line);
  y_lines_parallel := New([21]Line);
  z_lines          := New([21]Line);
  z_lines_parallel := New([21]Line);
  
  x_line_debug := New(Line);
  populate_line(x_line_debug, .{-100.0, 5.0, 0.0}, .{100.0, 5.0, 0.0}, X_LINE_COLOR, X_LINE_COLOR);
  x_line_debug_z_plus := New(Line);
  populate_line(x_line_debug_z_plus, .{-100.0, 5.0, 10.0}, .{100.0, 5.0, 10.0}, X_LINE_COLOR, X_LINE_COLOR);
  x_line_debug_z_minus := New(Line);
  populate_line(x_line_debug_z_minus, .{-100.0, 5.0, -5.0}, .{100.0, 5.0, -5.0}, X_LINE_COLOR, X_LINE_COLOR);

  x_lines_view : []Line;
  x_lines_parallel_view : []Line;
  y_lines_view : []Line;
  y_lines_parallel_view : []Line;
  z_lines_view : []Line;
  z_lines_parallel_view : []Line;

  x_lines_view = <<x_lines;
  x_lines_parallel_view = <<x_lines_parallel;
  y_lines_view = <<y_lines;
  y_lines_parallel_view = <<y_lines_parallel;
  z_lines_view = <<z_lines;
  z_lines_parallel_view = <<z_lines_parallel;

  line_spacing := 1.0;

  // X plane lines
  line_spacing_start := -10.0;
  for line, i: x_lines_view {
    populate_line(*x_lines_view[i], .{-10.0, 0.0, line_spacing_start}, .{10.0, 0.0, line_spacing_start}, X_LINE_COLOR, X_LINE_COLOR);
    line_spacing_start += line_spacing;
  }

  line_spacing_start = -10.0;
  for line, i: x_lines_parallel_view {
    populate_line(*x_lines_parallel_view[i], .{line_spacing_start, 0.0, -10.0}, .{line_spacing_start, 0.0, 10.0}, X_LINE_COLOR, X_LINE_COLOR);
    line_spacing_start += line_spacing;
  }

  // Y plane lines
  line_spacing_start = -10.0;
  for line, i: y_lines_view {
    populate_line(*y_lines_view[i], .{line_spacing_start, -10.0, 0.0}, .{line_spacing_start, 10.0, 0.0}, Y_LINE_COLOR, Y_LINE_COLOR);
    line_spacing_start += line_spacing;
  }

  line_spacing_start = -10.0;
  for line, i: y_lines_parallel_view {
    populate_line(*y_lines_parallel_view[i], .{-10.0, line_spacing_start, 0.0}, .{10.0, line_spacing_start, 0.0}, Y_LINE_COLOR, Y_LINE_COLOR);
    line_spacing_start += line_spacing;
  }

  // Z plane lines
  line_spacing_start = -10.0;
  for line, i: z_lines_view {
    populate_line(*z_lines_view[i], .{0.0, line_spacing_start, -10.0}, .{0.0, line_spacing_start, 10.0}, Z_LINE_COLOR, Z_LINE_COLOR);
    line_spacing_start += line_spacing;
  }

  line_spacing_start = -10.0;
  for line, i: z_lines_parallel_view {
    populate_line(*z_lines_parallel_view[i], .{0.0, -10.0, line_spacing_start}, .{0.0, 10.0, line_spacing_start}, Z_LINE_COLOR, Z_LINE_COLOR);
    line_spacing_start += line_spacing;
  }

  // Create test iso tiles
  test_iso_tiles_array := New([..]IsoTile);

  id := 0;
  for i: 0..ISO_TILESET_WIDTH - 1 {
    for j: 0..ISO_TILESET_HEIGHT - 1 {
      // print("Adding array with indexes: i - % j - %\n", i, j);
      iso_tile := New(IsoTile);
      populate_iso_tile(iso_tile,
                        id,
                        .{i / 100.0, j / 100.0, 0.8},
                        .{1.0, 1.0, 1.0},
                        .{cast(float)ISO_TILESET_X + i * ISO_TILE_WIDTH , 0.0, cast(float)ISO_TILESET_Z + j * ISO_TILE_HEIGHT});
      id += 1;

      array_add(test_iso_tiles_array, iso_tile);
    }
  }
  
  while !QUIT {
    frame_start := current_time_monotonic();

    event : SDL_Event;
    while SDL_PollEvent(*event) {
      if event.type == {
        case SDL_QUIT;
          QUIT = true;
        case SDL_WINDOWEVENT;
          if event.window.event == SDL_WINDOWEVENT_SIZE_CHANGED {
            WINDOW_WIDTH = event.window.data1;
            WINDOW_HEIGHT = event.window.data2;
          }
        case SDL_MOUSEMOTION;
          if space_pushed {
            mouse_delta_x = event.motion.xrel;
            mouse_delta_y = event.motion.yrel;
          }
        case SDL_KEYUP;
          if event.key.keysym.sym == SDLK_ESCAPE QUIT = true;

          if event.key.keysym.sym == SDLK_a then flying_camera.move_input_keyboard.x = 0.0;
          if event.key.keysym.sym == SDLK_d then flying_camera.move_input_keyboard.x = 0.0;
          if event.key.keysym.sym == SDLK_s then flying_camera.move_input_keyboard.y = 0.0;
          if event.key.keysym.sym == SDLK_w then flying_camera.move_input_keyboard.y = 0.0;
          if event.key.keysym.sym == SDLK_q then flying_camera.move_input_keyboard.z = 0.0;
          if event.key.keysym.sym == SDLK_e then flying_camera.move_input_keyboard.z = 0.0;

          if event.key.keysym.sym == SDLK_SPACE {
            space_pushed = false;
            mouse_delta_x = 0;
            mouse_delta_y = 0;
          }

        case SDL_KEYDOWN;
          if event.key.keysym.sym == SDLK_a then flying_camera.move_input_keyboard.x = -1.0;
          if event.key.keysym.sym == SDLK_d then flying_camera.move_input_keyboard.x = 1.0;
          if event.key.keysym.sym == SDLK_s then flying_camera.move_input_keyboard.y = -1.0;
          if event.key.keysym.sym == SDLK_w then flying_camera.move_input_keyboard.y = 1.0;
          if event.key.keysym.sym == SDLK_q then flying_camera.move_input_keyboard.z = -1.0;
          if event.key.keysym.sym == SDLK_e then flying_camera.move_input_keyboard.z = 1.0;

          if event.key.keysym.sym == SDLK_SPACE space_pushed = true;
      }

    }
    // Mouse
    mouse_delta = xy(xx mouse_delta_x, xx mouse_delta_y);

    // Beggining of simulation/rendering loop
    glViewport(0, 0, xx WINDOW_WIDTH, xx WINDOW_HEIGHT);

    // Shader program
    glUseProgram(program_id);

    // MVP matrix
    // put view_projection_matrix from flying_camera here
    flying_camera.mouse_delta_input = mouse_delta;
    update_flying_camera(*flying_camera, CONTROL_CAMERA, delta_time);

    glUniformMatrix4fv(view_projection_matrix_id, 1, GL_TRUE, xx *flying_camera.view_projection_matrix.coef[0][0]);

    // Clear screen
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    // Render test triangle
    for line, i: x_lines_parallel_view {
      draw_line(*x_lines_parallel_view[i]);
    }
    for line, i: y_lines_view {
      draw_line(*y_lines_view[i]);
    }
    for line, i: y_lines_parallel_view {
      draw_line(*y_lines_parallel_view[i]);
    }
    for line, i: x_lines_view {
      draw_line(*x_lines_view[i]);
    }
    for line, i: z_lines_view {
      draw_line(*z_lines_view[i]);
    }
    for line, i: z_lines_parallel_view {
      draw_line(*z_lines_parallel_view[i]);
    }

    // Test cube render
    render_cube(test_cube);

    // Rendering iso tiles
    for iso_tile: <<test_iso_tiles_array {
      render_iso_tile(*iso_tile);
    }

    // Swap window - end of drawing stuff
    SDL_GL_SwapWindow(MAIN_ENGINE_WINDOW);

    // Time stuff
    frame_end := current_time_monotonic();
    delta_time = cast(float) to_float64_seconds(frame_end - frame_start);
  }
  // Deleting stuff
  glDeleteProgram(program_id);
  glDeleteVertexArrays(1, *vao);
}

#import "Basic";

#import "Window_Creation";
#import "Input";
#import "Math";
#import "SDL";
#import "GL";

// Shaders - for now here
vertex_shader :: #string GLSL
  #version 330 core
  layout(location = 0) in vec3 vertexPosition_modelspace;

  void main() {
      gl_Position.xyz = vertexPosition_modelspace;
      gl_Position.w = 1.0; 
  }
GLSL

fragment_shader :: #string GLSL
  #version 330 core

  in vec3 fragmentColor;

  out vec3 color;

  void main() {
    color = fragmentColor;
  }
GLSL

// Engine internal variables
QUIT := false;

WINDOW_TITLE_BAR : *u8 = "Longship Engine";
WINDOW_WIDTH : s32 = 1024;
WINDOW_HEIGHT : s32 = 768;

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
  nw: PointF;
  ne: PointF;
  se: PointF;
  sw: PointF;
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

draw_iso_tile :: (iso_tile: *IsoTile) {
  v1 : Vector2 = .{iso_tile.nw.x, iso_tile.nw.y};
  v2 : Vector2 = .{iso_tile.ne.x, iso_tile.ne.y};
  v3 : Vector2 = .{iso_tile.se.x, iso_tile.se.y};
  v4 : Vector2 = .{iso_tile.sw.x, iso_tile.sw.y};

  // TODO ragnar: draw iso_tile in opengl

}

draw_line :: (start: PointF, end: PointF) {
  // TODO ragnar: untested for now
}

main :: () {
  // Welcoming messages
  print("Hello, longship-engine!\n");

  // DEBUG prints
  print("%\n", vertex_shader);
  print("====================\n");
  print("%\n", fragment_shader);

  // DEBUG variables
  debug_iso_tile := New(IsoTile); // TODO ragnar: check what is going here - heap allocation?
  // This is allocated on heap with alloc - check what should I do with maybe context allocator?
  g_vertex_buffer_data: [9]GLfloat;  
  /*
  {
    -1.0f, -1.0f, 0.0f,
    1.0f, -1.0f, 0.0f,
    0.0f, 1.0f, 0.0f
  };
  */

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
  SDL_Init(SDL_INIT_VIDEO);

  MAIN_ENGINE_WINDOW := SDL_CreateWindow(WINDOW_TITLE_BAR, SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, xx WINDOW_WIDTH, xx WINDOW_HEIGHT, SDL_WINDOW_OPENGL|SDL_WINDOW_RESIZABLE);
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

  // Defering stuff
  defer SDL_DestroyWindow(MAIN_ENGINE_WINDOW);
  defer SDL_Quit();

  // Create VAO
  vertex_array_id : GLuint;
  glGenVertexArrays(1, *vertex_array_id);
  glBindVertexArray(vertex_array_id);

  // Main LongshipEngine loop
  while !QUIT {
    // Check input events

    event : SDL_Event;
    while SDL_PollEvent(*event) {
      if event.type == {
        case SDL_QUIT;
          QUIT = true;
        case SDL_KEYUP;
          if event.key.keysym.sym == SDLK_ESCAPE QUIT = true;
        case SDL_WINDOWEVENT;
          if event.window.event == SDL_WINDOWEVENT_SIZE_CHANGED {
            WINDOW_WIDTH = event.window.data1;
            WINDOW_HEIGHT = event.window.data2;
          }
      }
    }

    // End of checking input events
    // Rendering shit

    glViewport(0, 0, xx WINDOW_WIDTH, xx WINDOW_HEIGHT);
    glClear(GL_COLOR_BUFFER_BIT);

    SDL_GL_SwapWindow(MAIN_ENGINE_WINDOW);
  }
}

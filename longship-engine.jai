#import "Basic";

// #import "Window_Creation";
#import "Input";
#import "Math";
#import "SDL";
#import "GL";

// Shaders - for now here
VERTEX_SHADER :: #string GLSL
  #version 330 core
  layout(location = 0) in vec3 vertexPosition_modelspace;
  layout(location = 1) in vec3 vertexColor;

  out vec3 fragmentColor;

  void main() {
      gl_Position.xyz = vertexPosition_modelspace;
      gl_Position.w = 1.0; 

      fragmentColor = vertexColor;
  }
GLSL

FRAGMENT_SHADER :: #string GLSL
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

load_shaders :: () -> GLuint {
  // Right now loading shaders from local strings
  program_id : GLuint;
  shader_program : GLuint;
  vertex_shader_id : GLuint;
  fragment_shader_id : GLuint;
  result_vertex : GLint;
  result_fragment : GLint;
  result_program : GLint;
  info_log_length_vertex : s32;
  info_log_length_fragment : s32;
  info_log_length_program : s32;

  shader_program = glCreateProgram();
  vertex_shader_id = glCreateShader(GL_VERTEX_SHADER);
  fragment_shader_id = glCreateShader(GL_FRAGMENT_SHADER);

  glShaderSource(vertex_shader_id, 1, *to_c_string(VERTEX_SHADER), null);
  glCompileShader(vertex_shader_id);

  glGetShaderiv(vertex_shader_id, GL_COMPILE_STATUS, *result_vertex);
  glGetShaderiv(vertex_shader_id, GL_INFO_LOG_LENGTH, *info_log_length_vertex);

  // TODO ragnar: add checking for errors
  if (info_log_length_vertex > 0) {
    vertex_shader_error_log : [512]u8;
    glGetShaderInfoLog(vertex_shader_id, cast(u32)info_log_length_vertex, null, cast(*GLchar) *vertex_shader_error_log);
    print("%\n", cast(string) vertex_shader_error_log);
  }

  glShaderSource(fragment_shader_id, 1, *to_c_string(FRAGMENT_SHADER), null);
  glCompileShader(fragment_shader_id);

  glGetShaderiv(fragment_shader_id, GL_COMPILE_STATUS, *result_fragment);
  glGetShaderiv(fragment_shader_id, GL_INFO_LOG_LENGTH, *info_log_length_fragment);

  // TODO ragnar: add checking for errors
  if (info_log_length_fragment > 0) {
    fragment_shader_error_log : [512]u8;
    glGetShaderInfoLog(fragment_shader_id, cast(u32)info_log_length_fragment, null, cast(*GLchar) *fragment_shader_error_log);
    print("%\n", cast(string) fragment_shader_error_log);
  }

  // Creating and attaching compiled shaders to program
  program_id = glCreateProgram();
  glAttachShader(program_id, vertex_shader_id);
  glAttachShader(program_id, fragment_shader_id);
  glLinkProgram(program_id);

  glGetProgramiv(program_id, GL_LINK_STATUS, *result_program);
  glGetProgramiv(program_id, GL_INFO_LOG_LENGTH, *info_log_length_program);

  // TODO ragnar: add checking for errors
  if (info_log_length_program > 0) {
    program_error_log : string;
    glGetProgramInfoLog(program_id, cast(u32)info_log_length_fragment, null, to_c_string(program_error_log));
    print("%\n", program_error_log);
  }

  // Now we can detach and delete shaders
  glDetachShader(program_id, vertex_shader_id);
  glDetachShader(program_id, fragment_shader_id);

  glDeleteShader(vertex_shader_id);
  glDeleteShader(fragment_shader_id);

  return program_id;
}

main :: () {
  // Welcoming messages
  print("Hello, longship-engine!\n");

  // DEBUG prints
  print("%\n", VERTEX_SHADER);
  print("====================\n");
  print("%\n", FRAGMENT_SHADER);

  // DEBUG variables
  debug_iso_tile := New(IsoTile); // TODO ragnar: check what is going here - heap allocation?
  // This is allocated on heap with alloc - check what should I do with maybe context allocator?

  // Buffer data
  g_vertex_buffer_data := GLfloat.[-1.0, -1.0, 0.0, 1.0, -1.0, 0.0, 0.0, 1.0, 0.0];
  g_color_buffer_data := GLfloat.[1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0];

  // IsoTile
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

  // Create VB - vertex buffer for triangle
  vertex_buffer_vertices : GLuint;
  glGenBuffers(1, *vertex_buffer_vertices);
  glBindBuffer(GL_ARRAY_BUFFER, vertex_buffer_vertices);
  glBufferData(GL_ARRAY_BUFFER, size_of(type_of(g_vertex_buffer_data)), *g_vertex_buffer_data, GL_STATIC_DRAW);

  // Create VB - vertex buffer for triangle color
  vertex_buffer_colors : GLuint;
  glGenBuffers(1, *vertex_buffer_colors);
  glBindBuffer(GL_ARRAY_BUFFER, vertex_buffer_colors);
  glBufferData(GL_ARRAY_BUFFER, size_of(type_of(g_color_buffer_data)), *g_color_buffer_data, GL_STATIC_DRAW);
  
  // Loading shaders
  program_id := load_shaders();

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
    // Rendering shit
    glViewport(0, 0, xx WINDOW_WIDTH, xx WINDOW_HEIGHT);

    // Shader program
    glUseProgram(program_id);

    // End of checking input events
    glClear(GL_COLOR_BUFFER_BIT);

    // OpenGL shit
    glEnableVertexAttribArray(0);
    glEnableVertexAttribArray(1);

    glBindBuffer(GL_ARRAY_BUFFER, vertex_buffer_vertices);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, cast(*void)0);
    glBindBuffer(GL_ARRAY_BUFFER, vertex_buffer_colors);
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, cast(*void)0);

    // Drawing is here
    glDrawArrays(GL_TRIANGLES, 0, 3);

    glDisableVertexAttribArray(0);
    glDisableVertexAttribArray(1);

    SDL_GL_SwapWindow(MAIN_ENGINE_WINDOW);
  }

  // Delete OpenGL stuff
  glDeleteProgram(program_id);
  glDeleteVertexArrays(1, *vertex_array_id);
}

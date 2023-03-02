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

OGLColor :: struct {
  r: GLfloat;
  g: GLfloat;
  b: GLfloat;
}

OGLPoint :: struct {
  x: GLfloat;
  y: GLfloat;
  z: GLfloat; // Sticking to one plane for now
}
  
IsoTile :: struct {
  id: int;

  // OpenGL stuff
  nw: OGLPoint;
  ne: OGLPoint;
  se: OGLPoint;
  sw: OGLPoint;

  // Colors - one color for each point to keep things simple for now
  color_nw: OGLColor;
  color_ne: OGLColor;
  color_se: OGLColor;
  color_sw: OGLColor;

  // OpenGL Buffers - ids
  vertex_buffer_vertices_0 : GLuint;
  vertex_buffer_colors_0: GLuint;
  vertex_buffer_vertices_1 : GLuint;
  vertex_buffer_colors_1: GLuint;

  // OpenGL Buffers - containers
  vertex_buffer_vertices_data_0 : [9]GLfloat;
  vertex_buffer_color_data_0 : [9]GLfloat;
  vertex_buffer_vertices_data_1 : [9]GLfloat;
  vertex_buffer_color_data_1 : [9]GLfloat;
}

create_iso_tile_buffers :: (iso_tile: *IsoTile) {
  // Create VB - vertex buffer for vertices
  glGenBuffers(1, *iso_tile.vertex_buffer_vertices_0);
  glBindBuffer(GL_ARRAY_BUFFER, iso_tile.vertex_buffer_vertices_0);
  glBufferData(GL_ARRAY_BUFFER, size_of(type_of(iso_tile.vertex_buffer_vertices_data_0)), *iso_tile.vertex_buffer_vertices_data_0, GL_STATIC_DRAW);

  glGenBuffers(1, *iso_tile.vertex_buffer_vertices_1);
  glBindBuffer(GL_ARRAY_BUFFER, iso_tile.vertex_buffer_vertices_1);
  glBufferData(GL_ARRAY_BUFFER, size_of(type_of(iso_tile.vertex_buffer_vertices_data_1)), *iso_tile.vertex_buffer_vertices_data_1, GL_STATIC_DRAW);

  // Create VB - vertex buffer for colors
  glGenBuffers(1, *iso_tile.vertex_buffer_colors_0);
  glBindBuffer(GL_ARRAY_BUFFER, iso_tile.vertex_buffer_colors_0);
  glBufferData(GL_ARRAY_BUFFER, size_of(type_of(iso_tile.vertex_buffer_color_data_0)), *iso_tile.vertex_buffer_color_data_0, GL_STATIC_DRAW);

  glGenBuffers(1, *iso_tile.vertex_buffer_colors_1);
  glBindBuffer(GL_ARRAY_BUFFER, iso_tile.vertex_buffer_colors_1);
  glBufferData(GL_ARRAY_BUFFER, size_of(type_of(iso_tile.vertex_buffer_color_data_1)), *iso_tile.vertex_buffer_color_data_1, GL_STATIC_DRAW);

  print("Buffers _0 - vertices: %, colors: %\n", iso_tile.vertex_buffer_vertices_0, iso_tile.vertex_buffer_colors_0);
  print("Buffers _1 - vertices: %, colors: %\n", iso_tile.vertex_buffer_vertices_1, iso_tile.vertex_buffer_colors_1);
}

populate_iso_tile :: (iso_tile: *IsoTile) {
  // TODO ragnar: parametrize, rn hardcoded
  iso_tile.id = 0;

  // @hardcore
  iso_tile.nw = .{0, 0.5, 0};
  iso_tile.ne = .{0.5, 0, 0};
  iso_tile.se = .{0, -0.5, 0};
  iso_tile.sw = .{-0.5, 0, 0};

  // @hardcode
  iso_tile.color_nw = .{1.0, 0, 0};
  iso_tile.color_ne = .{0, 1.0, 0};
  iso_tile.color_se = .{1.0, 0, 0};
  iso_tile.color_sw = .{0, 0, 1.0};

  // Doing stuff by hand becuase why the fuck not
  iso_tile.vertex_buffer_vertices_data_0[0] = iso_tile.nw.x;
  iso_tile.vertex_buffer_vertices_data_0[1] = iso_tile.nw.y;
  iso_tile.vertex_buffer_vertices_data_0[2] = iso_tile.nw.z;

  iso_tile.vertex_buffer_vertices_data_0[3] = iso_tile.ne.x;
  iso_tile.vertex_buffer_vertices_data_0[4] = iso_tile.ne.y;
  iso_tile.vertex_buffer_vertices_data_0[5] = iso_tile.ne.z;

  iso_tile.vertex_buffer_vertices_data_0[6] = iso_tile.se.x;
  iso_tile.vertex_buffer_vertices_data_0[7] = iso_tile.se.y;
  iso_tile.vertex_buffer_vertices_data_0[8] = iso_tile.se.z;

  iso_tile.vertex_buffer_vertices_data_1[0] = iso_tile.se.x;
  iso_tile.vertex_buffer_vertices_data_1[1] = iso_tile.se.y;
  iso_tile.vertex_buffer_vertices_data_1[2] = iso_tile.se.z;

  iso_tile.vertex_buffer_vertices_data_1[3] = iso_tile.sw.x;
  iso_tile.vertex_buffer_vertices_data_1[4] = iso_tile.sw.y;
  iso_tile.vertex_buffer_vertices_data_1[5] = iso_tile.sw.z;

  iso_tile.vertex_buffer_vertices_data_1[6] = iso_tile.nw.x;
  iso_tile.vertex_buffer_vertices_data_1[7] = iso_tile.nw.y;
  iso_tile.vertex_buffer_vertices_data_1[8] = iso_tile.nw.z;


  iso_tile.vertex_buffer_color_data_0[0] = iso_tile.color_nw.r;
  iso_tile.vertex_buffer_color_data_0[1] = iso_tile.color_nw.g;
  iso_tile.vertex_buffer_color_data_0[2] = iso_tile.color_nw.b;

  iso_tile.vertex_buffer_color_data_0[3] = iso_tile.color_ne.r;
  iso_tile.vertex_buffer_color_data_0[4] = iso_tile.color_ne.g;
  iso_tile.vertex_buffer_color_data_0[5] = iso_tile.color_ne.b;

  iso_tile.vertex_buffer_color_data_0[6] = iso_tile.color_se.r;
  iso_tile.vertex_buffer_color_data_0[7] = iso_tile.color_se.g;
  iso_tile.vertex_buffer_color_data_0[8] = iso_tile.color_se.b;

  iso_tile.vertex_buffer_color_data_1[0] = iso_tile.color_se.r;
  iso_tile.vertex_buffer_color_data_1[1] = iso_tile.color_se.g;
  iso_tile.vertex_buffer_color_data_1[2] = iso_tile.color_se.b;

  iso_tile.vertex_buffer_color_data_1[3] = iso_tile.color_sw.r;
  iso_tile.vertex_buffer_color_data_1[4] = iso_tile.color_sw.g;
  iso_tile.vertex_buffer_color_data_1[5] = iso_tile.color_sw.b;

  iso_tile.vertex_buffer_color_data_1[6] = iso_tile.color_nw.r;
  iso_tile.vertex_buffer_color_data_1[7] = iso_tile.color_nw.g;
  iso_tile.vertex_buffer_color_data_1[8] = iso_tile.color_nw.b;

  // In the end - create buffers
  create_iso_tile_buffers(iso_tile);

}

render_iso_tile :: (iso_tile: *IsoTile) {
  // Enabling attrib arrays
  glEnableVertexAttribArray(0);
  glEnableVertexAttribArray(1);

  // Binding buffers - vertices
  glBindBuffer(GL_ARRAY_BUFFER, iso_tile.vertex_buffer_vertices_0);
  glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, cast(*void)0);

  // Binding buffers - colors
  glBindBuffer(GL_ARRAY_BUFFER, iso_tile.vertex_buffer_colors_0);
  glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, cast(*void)0);

  // Draw arrays call - first triangle
  glDrawArrays(GL_TRIANGLES, 0, 3);

  // Bind buffers - vertices - now with offset
  glBindBuffer(GL_ARRAY_BUFFER, iso_tile.vertex_buffer_vertices_1);
  glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, cast(*void)0);

  // Bind buffers - colors - now with offset
  glBindBuffer(GL_ARRAY_BUFFER, iso_tile.vertex_buffer_colors_1);
  glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, cast(*void)0);

  // Draw arrays call - second triangle
  glDrawArrays(GL_TRIANGLES, 0, 3);

  // Disabling attrib arrays
  glDisableVertexAttribArray(0);
  glDisableVertexAttribArray(1);
}

// Define some colors
BLACK : OGLColor = .{0, 0, 0};
RED : OGLColor = .{1.0, 0, 0};
GREEN : OGLColor = .{0, 1.0, 0};
BLUE : OGLColor = .{0, 0, 1.0};
KHAKI : OGLColor = .{0.941, 0.901, 0.549};
DARK_KHAKI : OGLColor = .{0.741, 0.7176, 0.419};

load_shaders :: () -> GLuint {
  // Right now loading shaders from local strings
  // No error path if something goes wrong
  // Just prints

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

  // DEBUG variables - those are creating with OpenGL initialized
  // so it must be done after gl_load
  debug_iso_tile := New(IsoTile);
  populate_iso_tile(debug_iso_tile);

  // Create VAO - one per program for now - all isotiles will go there
  vertex_array_id : GLuint;
  glGenVertexArrays(1, *vertex_array_id);
  glBindVertexArray(vertex_array_id);

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

    // Render iso tile
    render_iso_tile(debug_iso_tile);

    SDL_GL_SwapWindow(MAIN_ENGINE_WINDOW);
  }

  // Delete OpenGL stuff
  glDeleteProgram(program_id);
  glDeleteVertexArrays(1, *vertex_array_id);
}

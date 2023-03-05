#import "Basic";

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
  
  uniform mat4 MVP;

  void main() {
      gl_Position = MVP * vec4(vertexPosition_modelspace, 1);

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

// @TODO ragnar: create a grid of isotiles
ISO_TILESET_WIDTH := 1000;
ISO_TILESET_HEIGHT := 1000;
ISO_TILE_WIDTH := 200;
ISO_TILE_HEIGHT := 200;
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
  // Final version - only 4 points required
  // @improvement we will just offset second triangle
  // and be fine about it
  vertex_buffer_vertices : GLuint;
  vertex_buffer_colors : GLuint;

  // OpenGL Buffers - containers
  // Final version - only 4 points required
  // @improvement we will just offset second triangle
  // and be fine about it
  vertex_buffer_vertices_data : [12]GLfloat;
  vertex_buffer_colors_data : [12]GLfloat;
}

create_iso_tile_buffers :: (iso_tile: *IsoTile) {
  // Create VB - vertex buffer for vertices
  // glGenBuffers(1, *iso_tile.vertex_buffer_vertices_0);
  // glBindBuffer(GL_ARRAY_BUFFER, iso_tile.vertex_buffer_vertices_0);
  // glBufferData(GL_ARRAY_BUFFER, size_of(type_of(iso_tile.vertex_buffer_vertices_data_0)), *iso_tile.vertex_buffer_vertices_data_0, GL_STATIC_DRAW);

  // glGenBuffers(1, *iso_tile.vertex_buffer_vertices_1);
  // glBindBuffer(GL_ARRAY_BUFFER, iso_tile.vertex_buffer_vertices_1);
  // glBufferData(GL_ARRAY_BUFFER, size_of(type_of(iso_tile.vertex_buffer_vertices_data_1)), *iso_tile.vertex_buffer_vertices_data_1, GL_STATIC_DRAW);

  // REAL BUFFERS
  glGenBuffers(1, *iso_tile.vertex_buffer_vertices);
  glBindBuffer(GL_ARRAY_BUFFER, iso_tile.vertex_buffer_vertices);
  glBufferData(GL_ARRAY_BUFFER, size_of(type_of(iso_tile.vertex_buffer_vertices_data)), *iso_tile.vertex_buffer_vertices_data, GL_STATIC_DRAW);

  // Create VB - vertex buffer for colors
  // glGenBuffers(1, *iso_tile.vertex_buffer_colors_0);
  // glBindBuffer(GL_ARRAY_BUFFER, iso_tile.vertex_buffer_colors_0);
  // glBufferData(GL_ARRAY_BUFFER, size_of(type_of(iso_tile.vertex_buffer_color_data_0)), *iso_tile.vertex_buffer_color_data_0, GL_STATIC_DRAW);

  // glGenBuffers(1, *iso_tile.vertex_buffer_colors_1);
  // glBindBuffer(GL_ARRAY_BUFFER, iso_tile.vertex_buffer_colors_1);
  // glBufferData(GL_ARRAY_BUFFER, size_of(type_of(iso_tile.vertex_buffer_color_data_1)), *iso_tile.vertex_buffer_color_data_1, GL_STATIC_DRAW);

  // REAL BUFFERS
  glGenBuffers(1, *iso_tile.vertex_buffer_colors);
  glBindBuffer(GL_ARRAY_BUFFER, iso_tile.vertex_buffer_colors);
  glBufferData(GL_ARRAY_BUFFER, size_of(type_of(iso_tile.vertex_buffer_colors_data)), *iso_tile.vertex_buffer_colors_data, GL_STATIC_DRAW);

  // print("Buffers _0 - vertices: %, colors: %\n", iso_tile.vertex_buffer_vertices_0, iso_tile.vertex_buffer_colors_0);
  // print("Buffers _1 - vertices: %, colors: %\n", iso_tile.vertex_buffer_vertices_1, iso_tile.vertex_buffer_colors_1);

  print("Buffers - vertices: %, colors: %\n", iso_tile.vertex_buffer_vertices, iso_tile.vertex_buffer_colors);
}

populate_iso_tile :: (iso_tile: *IsoTile) {
  // @TODO ragnar: parametrize, rn hardcoded
  iso_tile.id = 0;

  // @hardcore
  iso_tile.nw = .{cast(float) -ISO_TILE_WIDTH, cast(float)  ISO_TILE_HEIGHT, 0};
  iso_tile.ne = .{cast(float)  ISO_TILE_WIDTH, cast(float)  ISO_TILE_HEIGHT, 0};
  iso_tile.se = .{cast(float)  ISO_TILE_WIDTH, cast(float) -ISO_TILE_HEIGHT, 0};
  iso_tile.sw = .{cast(float) -ISO_TILE_WIDTH, cast(float) -ISO_TILE_HEIGHT, 0};

  // iso_tile.nw = .{0, 0, 0};
  // iso_tile.ne = .{100, 0, 0};
  // iso_tile.se = .{100, 100, 0};
  // iso_tile.sw = .{0, 100, 0};

  // @hardcode
  iso_tile.color_nw = .{1.0,   0,   0};
  iso_tile.color_ne = .{  0, 1.0,   0};
  iso_tile.color_se = .{1.0,   0,   0};
  iso_tile.color_sw = .{  0,   0, 1.0};

  // Putting vertices and color data in correct order
  iso_tile.vertex_buffer_vertices_data[0]  = iso_tile.nw.x;
  iso_tile.vertex_buffer_vertices_data[1]  = iso_tile.nw.y;
  iso_tile.vertex_buffer_vertices_data[2]  = iso_tile.nw.z;
  iso_tile.vertex_buffer_vertices_data[3]  = iso_tile.sw.x;
  iso_tile.vertex_buffer_vertices_data[4]  = iso_tile.sw.y;
  iso_tile.vertex_buffer_vertices_data[5]  = iso_tile.sw.z;
  iso_tile.vertex_buffer_vertices_data[6]  = iso_tile.ne.x;
  iso_tile.vertex_buffer_vertices_data[7]  = iso_tile.ne.y;
  iso_tile.vertex_buffer_vertices_data[8]  = iso_tile.ne.z;
  iso_tile.vertex_buffer_vertices_data[9]  = iso_tile.se.x;
  iso_tile.vertex_buffer_vertices_data[10] = iso_tile.se.y;
  iso_tile.vertex_buffer_vertices_data[11] = iso_tile.se.z;

  iso_tile.vertex_buffer_colors_data[0]  = iso_tile.color_nw.r;
  iso_tile.vertex_buffer_colors_data[1]  = iso_tile.color_nw.g;
  iso_tile.vertex_buffer_colors_data[2]  = iso_tile.color_nw.b;
  iso_tile.vertex_buffer_colors_data[3]  = iso_tile.color_sw.r;
  iso_tile.vertex_buffer_colors_data[4]  = iso_tile.color_sw.g;
  iso_tile.vertex_buffer_colors_data[5]  = iso_tile.color_sw.b;
  iso_tile.vertex_buffer_colors_data[6]  = iso_tile.color_ne.r;
  iso_tile.vertex_buffer_colors_data[7]  = iso_tile.color_ne.g;
  iso_tile.vertex_buffer_colors_data[8]  = iso_tile.color_ne.b;
  iso_tile.vertex_buffer_colors_data[9]  = iso_tile.color_se.r;
  iso_tile.vertex_buffer_colors_data[10] = iso_tile.color_se.g;
  iso_tile.vertex_buffer_colors_data[11] = iso_tile.color_se.b;

  // In the end - create buffers
  create_iso_tile_buffers(iso_tile);

}

modify_vertex_buffer :: (iso_tile: *IsoTile) {
  glBindBuffer(GL_ARRAY_BUFFER, iso_tile.vertex_buffer_vertices);
  // glBufferSubData(GL_ARRAY_BUFFER, size_of(type_of(iso_tile.vertex_buffer_vertices_data)), *iso_tile.vertex_buffer_vertices_data, GL_STATIC_DRAW);
  glBufferSubData(GL_ARRAY_BUFFER, 2 * size_of(GLfloat), size_of(GLfloat), *iso_tile.vertex_buffer_vertices_data[2]);
  print("Buffer vertices data: %\n", iso_tile.vertex_buffer_vertices_data);
}

move_corner_up_or_down :: (iso_tile: *IsoTile, adding: GLfloat) {
  // iso_tile.nw.z += adding;
  iso_tile.vertex_buffer_vertices_data[2] += adding;

  // Calling creating buffers
  // create_iso_tile_buffers(iso_tile);
  // @TODO: how to modify current buffer?
  modify_vertex_buffer(iso_tile);
}

render_iso_tile :: (iso_tile: *IsoTile) {
  // Enabling attrib arrays
  glEnableVertexAttribArray(0);
  glEnableVertexAttribArray(1);

  // Binding buffers - REAL vertices
  glBindBuffer(GL_ARRAY_BUFFER, iso_tile.vertex_buffer_vertices);
  glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, cast(*void)0);

  // Binding buffers - REAL colors
  glBindBuffer(GL_ARRAY_BUFFER, iso_tile.vertex_buffer_colors);
  glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, cast(*void)0);

  // Draw arrays call - first triangle
  glDrawArrays(GL_TRIANGLES, 0, 3);


  // Bind buffers - vertices - now with offset
  glBindBuffer(GL_ARRAY_BUFFER, iso_tile.vertex_buffer_vertices);
  glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, cast(*void)(3 * size_of(GLfloat)));

  // Bind buffers - colors - now with offset
  glBindBuffer(GL_ARRAY_BUFFER, iso_tile.vertex_buffer_colors);
  glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, cast(*void)(3 * size_of(GLfloat)));

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

  // @TODO ragnar: add checking for errors
  if (info_log_length_vertex > 0) {
    vertex_shader_error_log : [512]u8;
    glGetShaderInfoLog(vertex_shader_id, cast(u32)info_log_length_vertex, null, cast(*GLchar) *vertex_shader_error_log);
    print("%\n", cast(string) vertex_shader_error_log);
  }

  glShaderSource(fragment_shader_id, 1, *to_c_string(FRAGMENT_SHADER), null);
  glCompileShader(fragment_shader_id);

  glGetShaderiv(fragment_shader_id, GL_COMPILE_STATUS, *result_fragment);
  glGetShaderiv(fragment_shader_id, GL_INFO_LOG_LENGTH, *info_log_length_fragment);

  // @TODO ragnar: add checking for errors
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

  // @TODO ragnar: add checking for errors
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
      // @TODO ragnar: add switch for program arguments
      // @TODO ragnar: add struct for program control variables
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
  
  // DEBUG prints
  print("GLfloat size_of: %\n", size_of(GLfloat));

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

  // Getting MatrixID for MVP
  matrix_id := glGetUniformLocation(program_id, "MVP");

  // Some variables for OPM
  opm_left   := cast(float) -(WINDOW_WIDTH / 2);
  opm_right  := cast(float)  WINDOW_WIDTH / 2;
  opm_bottom := cast(float)  WINDOW_HEIGHT / 2;
  opm_top    := cast(float) -(WINDOW_HEIGHT / 2);
  opm_near   := 0.0;
  opm_far    := 10000.0;

  // Variables for view matrix
  // viewpoint : Vector3 = .{10.0, 10.0, 10.0};
  // look_at : Vector3 = .{0.0, 0.0, 0.0};
  reference_up_vector : Vector3 = .{0.0, 1.0, 0.0};

  // DEBUG
  viewpoint_x := 0.0;
  viewpoint_y := 0.0;
  viewpoint_z := 0.0;

  look_at_x := 0.0;
  look_at_y := 0.0;
  look_at_z := 0.0;

  translate_x := 0.0;
  translate_y := 0.0;
  translate_z := 0.0;

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
        case SDL_KEYDOWN;
          shift_modifier := -1;
          print("DEBUG: event.key.keysym.mod %\n", event.key.keysym.mod);
          if event.key.keysym.mod == KMOD_LSHIFT then shift_modifier = 1;
          if event.key.keysym.mod == KMOD_RSHIFT then shift_modifier = 1;

          print("Shift modifier: %\n", shift_modifier);

          // @TODO add shift modifier
          // when pressing key with shift we get KMOD_LSHIFT

          // print("DEBUG: event.key.keysym     %\n", event.key.keysym);
          // print("DEBUG: event.key.keysym.sym %\n", event.key.keysym.sym);

          if event.key.keysym.sym == SDLK_a {
            // print("Pressing a.\n"); 
            // viewpoint_x += 0.01 * shift_modifier;
            // look_at_x += 0.01 * shift_modifier;
            translate_x += 0.1 * shift_modifier;
          }
          if event.key.keysym.sym == SDLK_w {
            // print("Pressing w.\n");
            // opm_top += 0.1 * shift_modifier;
            look_at_y += 0.1 * shift_modifier;
          }
          if event.key.keysym.sym == SDLK_s {
            // print("Pressing s.\n");
            // viewpoint_y += 0.01 * shift_modifier;
            // look_at_y += 0.01 * shift_modifier;
            translate_y += 0.1 * shift_modifier;
          }
          if event.key.keysym.sym == SDLK_d {
            // print("Pressing d.\n");
            // viewpoint_z += 0.01 * shift_modifier;
            // look_at_z += 0.01 * shift_modifier;
            translate_z += 0.1 * shift_modifier;
          }
          if event.key.keysym.sym == SDLK_q {
            // print("Pressing q.\n");
            // opm_near += 0.1 * shift_modifier;
            look_at_x += 0.1 * shift_modifier;
          }
          if event.key.keysym.sym == SDLK_e {
            // print("Pressing e.\n");
            // opm_far += 0.1 * shift_modifier;
            look_at_z += 0.1 * shift_modifier;
          }
          if event.key.keysym.sym == SDLK_f {
            print("Pressing f.\n");
            // move_corner_up_or_down(debug_iso_tile, 0.1 * shift_modifier);
          }

          // @TODO ragnar: add some control to camera to see how it works

          // PRINT OPM VALUES
          // print("OPM: left: %, right: %,\ntop: %, bottom %,\nnear: %, far: %\n",
          //    opm_left, opm_right, opm_top, opm_bottom, opm_near, opm_far);

          print("Viewpoint: x %, y %, z %\n", viewpoint_x, viewpoint_y, viewpoint_z);
          print("Look_at: x %, y %, z %\n", look_at_x, look_at_y, look_at_z);
          print("Translate: x %, y %, z %\n", translate_x, translate_y, translate_z);

        case SDL_WINDOWEVENT;
          if event.window.event == SDL_WINDOWEVENT_SIZE_CHANGED {
            WINDOW_WIDTH = event.window.data1;
            WINDOW_HEIGHT = event.window.data2;
          }
      }
    }

    // Create orhographic projection matrix
    // @TODO ragnar: create a compass of what is where (X, Y, Z) axis

    // @IDEA go for MVP matrix that is pushed into UniformMatrix4fv
    // but lets try this orthographic_projection_matrix

    // DEBUG changing viewpoint by hand
    viewpoint : Vector3 = .{viewpoint_x, viewpoint_y, viewpoint_z};
    look_at : Vector3 = .{look_at_x, look_at_y, look_at_z};

    // @DEBUG lets play with something different than ortographics projection
    // fov_vertical := 0.785398;
    // op_projection_matrix := make_projection_matrix(fov_vertical, (cast(float) WINDOW_WIDTH / cast(float) WINDOW_HEIGHT), 0.1, 100.0);
    op_projection_matrix := orthographic_projection_matrix(opm_left, opm_right, opm_bottom, opm_top, opm_near, opm_far);

    // @NOTE 1 - viewpoint, 2 - look_at, 3 - reference_up_vector 
    // @NOTE leaving this as-is - we only want to move iso tiles
    op_view_matrix := make_look_at_matrix(viewpoint, look_at, reference_up_vector, false); // x_is_foward set to false
    // @NOTE: idk what is forward
    // MODEL mat4 idendity matrix
    op_model_matrix := Matrix4_Identity;
    op_model_matrix._41 = translate_x;
    op_model_matrix._42 = translate_y;
    op_model_matrix._43 = translate_z;
    // print("OP model matrix: %\n", op_model_matrix);

    // @TODO build translation, rotation and scale matrices
    

    // print("Op model matrix %\n", op_model_matrix);
    // mvp_matrix := op_projection_matrix * op_view_matrix * op_model_matrix;
    mvp_matrix := op_projection_matrix * op_model_matrix * op_view_matrix;
    // mvp_matrix := op_model_matrix * op_view_matrix * op_projection_matrix;
    // mvp_matrix := op_model_matrix * op_projection_matrix;
    // mvp_matrix := op_projection_matrix * op_model_matrix;
    
    // print("Ortographic projection matrix: %\n", op_matrix);

    // Rendering shit
    glViewport(0, 0, xx WINDOW_WIDTH, xx WINDOW_HEIGHT);

    // Shader program
    glUseProgram(program_id);

    // Set up camera
    glUniformMatrix4fv(matrix_id, 1, GL_FALSE, xx *mvp_matrix);

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
